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
  final String? reporterName;
  final String? reporterAvatar;
  final String? categoryName;
  final String? categoryIcon;
  final String? assignedToName;
  final int? voteCount;
  final int? commentCount;
  final String? coverImageUrl;
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
    this.reporterName,
    this.reporterAvatar,
    this.categoryName,
    this.categoryIcon,
    this.assignedToName,
    this.voteCount,
    this.commentCount,
    this.coverImageUrl,
    this.images = const [],
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    final rawImages = json['report_images'];
    List<ReportImageModel> images = [];
    if (rawImages != null && rawImages is List && rawImages.isNotEmpty) {
      images =
          rawImages
              .map((e) => ReportImageModel.fromJson(e as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    } else if (json['cover_image_url'] != null) {
      images = [
        ReportImageModel(
          id: 'cover',
          reportId: json['id'] as String,
          imageUrl: json['cover_image_url'] as String,
          orderIndex: 0,
        )
      ];
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
      reporterName: json['reporter_name'] as String?,
      reporterAvatar: json['reporter_avatar'] as String?,
      categoryName: json['category_name'] as String?,
      categoryIcon: json['category_icon'] as String?,
      assignedToName: json['assigned_to_name'] as String?,
      voteCount: json['vote_count'] as int?,
      commentCount: json['comment_count'] as int?,
      coverImageUrl: json['cover_image_url'] as String?,
      images: images,
    );
  }

  String? get thumbnailUrl {
    if (images.isEmpty) return null;
    return images.first.imageUrl;
  }
}
