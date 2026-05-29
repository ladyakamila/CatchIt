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
  final _addressCtrl = TextEditingController();
  String? _selectedCategoryId;
  final List<XFile> _images = [];
  bool _isLoading = false;
  String _loadingMessage = '';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
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
          address: _addressCtrl.text.trim(),
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
        backgroundColor: AppTheme.background,
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
                  _buildSectionLabel('Kategori'),
                  const SizedBox(height: 8),
                  categoriesAsync.when(
                    data: (cats) => _CategoryDropdown(
                      categories: cats,
                      selectedId: _selectedCategoryId,
                      onChanged: (id) =>
                          setState(() => _selectedCategoryId = id),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text(
                      'Gagal memuat kategori: $e',
                      style: const TextStyle(color: AppTheme.danger),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionLabel('Judul Laporan'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Contoh: Jalan berlubang depan pasar',
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Judul wajib diisi' : null,
                  ),
                  const SizedBox(height: 20),
                  _buildSectionLabel('Deskripsi'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Jelaskan kerusakan secara detail...',
                      alignLabelWithHint: true,
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Deskripsi wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  _buildSectionLabel('Alamat / Lokasi'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _addressCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Masukkan alamat lengkap lokasi kerusakan',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Alamat wajib diisi' : null,
                  ),
                  const SizedBox(height: 20),
                  _buildSectionLabel('Foto Kerusakan (maks. 5)'),
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

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
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
      decoration: const InputDecoration(hintText: 'Pilih kategori'),
      items: categories.map((cat) {
        return DropdownMenuItem(value: cat.id, child: Text(cat.name));
      }).toList(),
      onChanged: onChanged,
    );
  }
}
