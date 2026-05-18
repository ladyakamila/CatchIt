import 'report_image_model.dart';

class ReportModel {
  final String id;
  final String userId;
  final String? categoryId;
  final String title;
  final String? description;
  final String status;
  final String? address;
  final DateTime? createdAt;
  final List<ReportImageModel> images;

  ReportModel({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.title,
    this.description,
    required this.status,
    this.address,
    this.createdAt,
    this.images = const [],
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    final rawImages = json['report_images'];
    List<ReportImageModel> images = [];
    if (rawImages != null && rawImages is List) {
      images =
          rawImages
              .map((e) => ReportImageModel.fromJson(e as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    }

    return ReportModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'menunggu',
      address: json['address'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      images: images,
    );
  }

  String? get thumbnailUrl {
    if (images.isEmpty) return null;
    return images.first.imageUrl;
  }
}
