import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Fungsi utama untuk mendapatkan alamat teks secara otomatis
  static Future<String> getAutoDetectedLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Cek apakah layanan GPS di HP aktif
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Layanan lokasi (GPS) di HP Anda dinonaktifkan.');
    }

    // 2. Cek izin akses lokasi dari user
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Izin akses lokasi ditolak.');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Izin lokasi ditolak permanen, silakan aktifkan di pengaturan HP.');
    }

    // 3. Ambil koordinat GPS saat ini (Latitude & Longitude)
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    try {
      // 4. Mengubah koordinat menjadi alamat teks (Reverse Geocoding)
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Menyusun alamat rapi: Nama Jalan, Kelurahan, Kecamatan, Kota
        String street = place.street ?? '';
        String subLocality = place.subLocality ?? ''; // Kelurahan
        String locality = place.locality ?? ''; // Kecamatan
        String subAdministrativeArea = place.subAdministrativeArea ?? ''; // Kota/Kabupaten

        return '$street, $subLocality, $locality, $subAdministrativeArea';
      }
      
      return 'Lokasi terdeteksi di koordinat: ${position.latitude}, ${position.longitude}';
    } catch (e) {
      // Jika internet putus/geocoding gagal, minimal kembalikan koordinatnya
      return 'Koordinat: ${position.latitude}, ${position.longitude}';
    }
  }
}