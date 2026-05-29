class CategoryModel {
  final String id;
  final String name;
  final String? iconName;
  final bool isActive;

  CategoryModel({
    required this.id,
    required this.name,
    this.iconName,
    required this.isActive,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      iconName: json['icon_name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon_name': iconName,
      'is_active': isActive,
    };
  }
}
