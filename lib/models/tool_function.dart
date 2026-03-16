class ToolFunctionModel {
  final String functionKey; // 功能标识（check_in/affairs/leave等）
  final String title; // 功能名称
  final String iconName; // 图标名称（后端返回图标字符串，如"access_time"）
  final bool isEnabled; // 是否有权限
  final String? routePath; // 路由路径（可选，前端映射）

  ToolFunctionModel({
    required this.functionKey,
    required this.title,
    required this.iconName,
    required this.isEnabled,
    this.routePath,
  });

  factory ToolFunctionModel.fromJson(Map<String, dynamic> json) {
    return ToolFunctionModel(
      functionKey: json['functionKey'] ?? '',
      title: json['title'] ?? '',
      iconName: json['iconName'] ?? '',
      isEnabled: json['isEnabled'] ?? false,
      routePath: json['routePath'],
    );
  }
}
