/// App 版本更新信息
class AppVersionInfo {
  /// 版本名称，如 "1.0.1"
  final String versionName;

  /// 版本号（整型），用于对比大小
  final int versionCode;

  /// APK 下载地址
  final String downloadUrl;

  /// 更新说明
  final String? updateContent;

  /// 是否强制更新
  final bool isForceUpdate;

  AppVersionInfo({
    required this.versionName,
    required this.versionCode,
    required this.downloadUrl,
    this.updateContent,
    this.isForceUpdate = false,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    return AppVersionInfo(
      versionName: json['versionName'] ?? '',
      versionCode: json['versionCode'] ?? 0,
      downloadUrl: json['downloadUrl'] ?? '',
      updateContent: json['updateContent'],
      isForceUpdate: json['isForceUpdate'] ?? false,
    );
  }
}
