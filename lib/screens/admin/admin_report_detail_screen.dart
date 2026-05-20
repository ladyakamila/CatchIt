import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/report_model.dart';
import '../../models/report_image_model.dart';
import '../../providers/report_provider.dart';
import '../../widgets/status_badge.dart';

class AdminReportDetailScreen extends ConsumerStatefulWidget {
  final ReportModel report;

  const AdminReportDetailScreen({super.key, required this.report});

  @override
  ConsumerState<AdminReportDetailScreen> createState() =>
      _AdminReportDetailScreenState();
}

class _AdminReportDetailScreenState
    extends ConsumerState<AdminReportDetailScreen> {
  late String _selectedStatus;
  bool _isSavingStatus = false;
  bool _isUploading = false;
  String _uploadProgress = '';

  final List<dynamic> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.report.status;
  }

  Future<void> _updateStatus() async {
    setState(() {
      _isSavingStatus = true;
    });
    try {
      await ref
          .read(reportNotifierProvider.notifier)
          .updateReportStatus(widget.report.id, _selectedStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status berhasil diperbarui'),
            backgroundColor: AppTheme.secondary,
          ),
        );
        // Actually, we could refresh data by popping, or simply call setState.
        // For accurate detail viewing, forcing a refresh of the page or just updating local state:
        // Because report model is passed via extra, it won't refresh automatically unless we fetch again.
        // I will just pop() or we can let the user pull to refresh if we had implemented a fetch report by id.
        // I'll pop to previous screen to trigger refresh there, or we can stay. Let's stay and tell user they might need to pull-to-refresh list.
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal update status: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingStatus = false;
        });
      }
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          if (kIsWeb) {
            _selectedImages.addAll(images);
          } else {
            _selectedImages.addAll(images.map((e) => File(e.path)));
          }
          if (_selectedImages.length > 5) {
            _selectedImages.removeRange(5, _selectedImages.length);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Maksimal 5 foto perbaikan'),
                backgroundColor: AppTheme.danger,
              ),
            );
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih foto: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _uploadRepairPhotos() async {
    if (_selectedImages.isEmpty) return;
    setState(() {
      _isUploading = true;
      _uploadProgress = 'Memulai unggahan...';
    });

    await ref
        .read(reportNotifierProvider.notifier)
        .uploadRepairPhoto(
          reportId: widget.report.id,
          imageFiles: _selectedImages,
          onProgress: (progress) {
            if (mounted) {
              setState(() {
                _uploadProgress = progress;
              });
            }
          },
          onSuccess: () {
            if (mounted) {
              setState(() {
                _isUploading = false;
                _selectedImages.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Foto perbaikan berhasil diunggah'),
                  backgroundColor: AppTheme.secondary,
                ),
              );
              // Pop to trigger list refresh, because gallery wouldn't update unless we re-fetch the report.
            }
          },
          onError: (err) {
            if (mounted) {
              setState(() {
                _isUploading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(err), backgroundColor: AppTheme.danger),
              );
            }
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final dateStr = report.createdAt != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(report.createdAt!)
        : '-';

    final damagePhotos = report.images
        .where((e) => e.orderIndex < 100)
        .toList();
    final repairPhotos = report.images
        .where((e) => e.orderIndex >= 100)
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Detail Laporan')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(report, dateStr, damagePhotos),
                const SizedBox(height: 24),


                if (repairPhotos.isNotEmpty) ...[
                  const Text(
                    'Foto Hasil Perbaikan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildImageGallery(repairPhotos),
                  const SizedBox(height: 24),
                ],

                _buildStatusActionPanel(),
                const SizedBox(height: 24),

                if (_selectedStatus == 'selesai' || report.status == 'selesai')
                  _buildRepairUploadPanel(),

                const SizedBox(height: 48),
              ],
            ),
          ),

          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.5),
              alignment: Alignment.center,
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(_uploadProgress, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ReportModel report, String dateStr, List<dynamic> damagePhotos) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                report.categoryName ?? '-',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              StatusBadge(
                status: _selectedStatus == report.status
                    ? report.status
                    : _selectedStatus,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            report.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Deskripsi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            report.description ?? 'Tidak ada deskripsi',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          if (damagePhotos.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildImageGallery(damagePhotos),
          ],
          const SizedBox(height: 16),
          const Divider(color: AppTheme.border),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.person_outline,
            'Pelapor',
            report.reporterName ?? 'Warga',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.location_on_outlined,
            'Lokasi',
            report.address ?? '-',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.access_time, 'Waktu', dateStr),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageGallery(List<dynamic> photos) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final photo = photos[index];
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => Scaffold(
                    backgroundColor: Colors.black,
                    appBar: AppBar(
                      backgroundColor: Colors.black,
                      iconTheme: const IconThemeData(color: Colors.white),
                    ),
                    body: Center(
                      child: InteractiveViewer(
                        panEnabled: true,
                        minScale: 0.5,
                        maxScale: 4,
                        child: Hero(
                          tag: 'photo_${photo.id}',
                          child: Image.network(
                            photo.imageUrl,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
            child: Hero(
              tag: 'photo_${photo.id}',
              child: Container(
                width: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppTheme.border,
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.network(photo.imageUrl, fit: BoxFit.cover),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusActionPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aksi Admin',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const Text('Ubah Status Laporan'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'menunggu', child: Text('Menunggu')),
              DropdownMenuItem(value: 'diproses', child: Text('Diproses')),
              DropdownMenuItem(value: 'selesai', child: Text('Selesai')),
              DropdownMenuItem(value: 'ditolak', child: Text('Ditolak')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedStatus = val);
              }
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isSavingStatus ? null : _updateStatus,
            child: _isSavingStatus
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Simpan Status'),
          ),
        ],
      ),
    );
  }

  Widget _buildRepairUploadPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload Foto Perbaikan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Maksimal 5 foto hasil perbaikan untuk laporan ini.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          if (_selectedImages.isNotEmpty) _buildSelectedImagesGrid(),
          if (_selectedImages.length < 5) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Pilih Foto'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
          if (_selectedImages.isNotEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadRepairPhotos,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Upload Foto Perbaikan'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedImagesGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _selectedImages.length,
      itemBuilder: (context, index) {
        final image = _selectedImages[index];
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: kIsWeb
                  ? Image.network(
                      (image as XFile).path,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  : Image.file(
                      image as File,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removeImage(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
