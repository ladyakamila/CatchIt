class ReportImageModel {
  final String id;
  final String reportId;
  final String imageUrl;
  final String? storagePath;
  final int orderIndex;

  ReportImageModel({
    required this.id,
    required this.reportId,
    required this.imageUrl,
    this.storagePath,
    required this.orderIndex,
  });

  factory ReportImageModel.fromJson(Map<String, dynamic> json) {
    return ReportImageModel(
      id: json['id'] as String,
      reportId: json['report_id'] as String,
      imageUrl: json['image_url'] as String,
      storagePath: json['storage_path'] as String?,
      orderIndex: json['order_index'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'report_id': reportId,
      'image_url': imageUrl,
      'storage_path': storagePath,
      'order_index': orderIndex,
    };
  }
}
