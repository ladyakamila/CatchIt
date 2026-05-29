import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../models/category_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/report_provider.dart';
import '../../widgets/image_grid_picker.dart';
import '../../widgets/loading_overlay.dart';

class ReportCreateScreen extends ConsumerStatefulWidget {
  const ReportCreateScreen({super.key});

  @override
  ConsumerState<ReportCreateScreen> createState() => _ReportCreateScreenState();
}

class _ReportCreateScreenState extends ConsumerState<ReportCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  
  String? _selectedCategoryId; 
  final List<XFile> _images = [];
  bool _isLoading = false;
  String _loadingMessage = '';

  String? _selectedRoom;

  // Daftar Lokasi Ruangan Internal Sekolah (Bebas typo & ringkas)
  final List<String> _schoolRooms = [
    'Ruang Teori / Kelas',
    'Laboratorium',
    'Perpustakaan',
    'Aula',
    'Ruang Guru / Tata Usaha',
    'Kantin Sekolah',
    'Toilet Siswa / Guru',
    'Lapangan Olahraga',
    'Masjid',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_images.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maksimal 5 foto'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: kIsWeb ? ImageSource.gallery : ImageSource.gallery,
      imageQuality: 85,
    );
    if (file != null) {
      setState(() => _images.add(file));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih kategori terlebih dahulu'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }
    if (_selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih lokasi ruangan terlebih dahulu'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Menyimpan laporan...';
    });

    await ref
        .read(reportNotifierProvider.notifier)
        .createReport(
          categoryId: _selectedCategoryId!, 
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          address: _selectedRoom!, 
          imageFiles: _images,
          onProgress: (msg) {
            if (mounted) setState(() => _loadingMessage = msg);
          },
          onSuccess: () {
            if (mounted) {
              ref.invalidate(userReportsProvider);
              context.go('/home');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Laporan berhasil dikirim!'),
                  backgroundColor: AppTheme.secondary,
                ),
              );
            }
          },
          onError: (err) {
            if (mounted) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Gagal: $err'),
                  backgroundColor: AppTheme.danger,
                ),
              );
            }
          },
        );

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return LoadingOverlay(
      isLoading: _isLoading,
      message: _loadingMessage,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Buat Laporan'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: _isLoading ? null : () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel(context, 'Kategori Kerusakan'),
                  const SizedBox(height: 8),
                  
                  categoriesAsync.when(
                    data: (cats) {
                      // --- DI SINI PROSES FILTER KATEGORI NYA ---
                      // Menyaring list kategori dari Supabase agar HANYA menampilkan 5 Kategori Sekolah saja
                      final filteredCats = cats.where((cat) {
                        return cat.name == 'Fasilitas Kelas & Belajar' ||
                               cat.name == 'Kelistrikan & Lampu' ||
                               cat.name == 'Sarana Kebersihan & Air' ||
                               cat.name == 'Elektronik & Jaringan' ||
                               cat.name == 'Gedung & Infrastruktur';
                      }).toList();

                      return _CategoryDropdown(
                        categories: filteredCats, // Memasukkan hasil filter ke Dropdown
                        selectedId: _selectedCategoryId,
                        onChanged: (id) =>
                            setState(() => _selectedCategoryId = id),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text(
                      'Gagal memuat kategori: $e',
                      style: const TextStyle(color: AppTheme.danger),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  _buildSectionLabel(context, 'Judul Laporan'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleCtrl,
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    decoration: const InputDecoration(
                      hintText: 'Contoh: AC Bocor atau Plafon Retak',
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Judul wajib diisi' : null,
                  ),
                  const SizedBox(height: 20),
                  _buildSectionLabel(context, 'Deskripsi Laporan'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 4,
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    decoration: const InputDecoration(
                      hintText: 'Jelaskan kerusakan secara detail...',
                      alignLabelWithHint: true,
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Deskripsi wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  
                  _buildSectionLabel(context, 'Lokasi Ruangan / Area'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedRoom,
                    isExpanded: true,
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    dropdownColor: Theme.of(context).cardColor,
                    decoration: const InputDecoration(
                      hintText: 'Pilih lokasi ruangan kerusakan',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    items: _schoolRooms.map((String room) {
                      return DropdownMenuItem<String>(
                        value: room,
                        child: Text(
                          room,
                          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedRoom = value);
                    },
                    validator: (v) => (v == null) ? 'Lokasi area wajib dipilih' : null,
                  ),
                  
                  const SizedBox(height: 20),
                  _buildSectionLabel(context, 'Foto Kerusakan (maks. 5)'),
                  const SizedBox(height: 8),
                  ImageGridPicker(
                    images: _images,
                    onAddTap: _pickImage,
                    onRemoveTap: (i) => setState(() => _images.removeAt(i)),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: const Text('Kirim Laporan'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final List<CategoryModel> categories;
  final String? selectedId;
  final void Function(String?) onChanged;

  const _CategoryDropdown({
    required this.categories,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedId,
      isExpanded: true,
      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
      dropdownColor: Theme.of(context).cardColor,
      decoration: const InputDecoration(hintText: 'Pilih kategori'),
      items: categories.map((cat) {
        return DropdownMenuItem(
          value: cat.id, 
          child: Text(
            cat.name, 
            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}