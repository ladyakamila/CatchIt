import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/report_model.dart';
import 'auth_provider.dart';

final userReportsProvider = FutureProvider<List<ReportModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from('reports')
      .select(
        '*, report_images(id, report_id, image_url, storage_path, order_index)',
      )
      .eq('user_id', user.id)
      .order('created_at', ascending: false);

  return (data as List)
      .map((e) => ReportModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

class ReportNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> createReport({
    required String categoryId,
    required String title,
    required String description,
    required String address,
    required List<dynamic> imageFiles,
    required void Function(String) onProgress,
    required void Function() onSuccess,
    required void Function(String) onError,
  }) async {
    state = const AsyncValue.loading();
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      onError('Sesi tidak ditemukan, silakan login kembali.');
      state = const AsyncValue.data(null);
      return;
    }

    try {
      onProgress('Menyimpan laporan...');
      final reportData = await client
          .from('reports')
          .insert({
            'user_id': user.id,
            'category_id': categoryId,
            'title': title,
            'description': description,
            'status': 'menunggu',
            'address': address,
          })
          .select()
          .single();

      final reportId = reportData['id'] as String;

      for (int i = 0; i < imageFiles.length; i++) {
        onProgress('Mengunggah foto ${i + 1} dari ${imageFiles.length}...');
        final file = imageFiles[i];
        final bytes = await file.readAsBytes();
        final extension = file.path.split('.').last.toLowerCase();
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_$i.$extension';
        final path = '${user.id}/$reportId/$fileName';

        await client.storage
            .from('report-images')
            .uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(
                contentType: extension == 'png' ? 'image/png' : 'image/jpeg',
              ),
            );

        final imageUrl = client.storage
            .from('report-images')
            .getPublicUrl(path);

        await client.from('report_images').insert({
          'report_id': reportId,
          'image_url': imageUrl,
          'storage_path': path,
          'order_index': i,
        });
      }

      state = const AsyncValue.data(null);
      onSuccess();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      onError(e.toString());
    }
  }
}

final reportNotifierProvider = AsyncNotifierProvider<ReportNotifier, void>(
  ReportNotifier.new,
);
