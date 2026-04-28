import 'package:package_info_plus/package_info_plus.dart';
import 'package:open_filex/open_filex.dart' as open_file;
import 'package:path_provider/path_provider.dart';
import '../models/app_version.dart';
import 'dio_client.dart';
import 'package:permission_handler/permission_handler.dart';

/// App 更新检测与下载服务
class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._internal();
  factory AppUpdateService() => _instance;
  AppUpdateService._internal();

  /// 当前 App 版本信息
  PackageInfo? _packageInfo;

  /// 版本检测 URL（公开 JSON 文件）
  static const _versionCheckUrl = 'https://updateoa.ecnkey.com/version.json';

  /// 初始化，获取本地版本信息
  Future<void> init() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }

  /// 获取当前版本号（versionCode）
  int get currentVersionCode {
    // Android 的 versionCode 是 buildNumber
    return int.tryParse(_packageInfo?.buildNumber ?? '0') ?? 0;
  }

  /// 获取当前版本名称（versionName）
  String get currentVersionName {
    return _packageInfo?.version ?? '0.0.0';
  }

  /// 从服务端检测新版本
  Future<AppVersionInfo?> checkForUpdate() async {
    try {
      final response = await dioClient.dio.get(_versionCheckUrl);
      if (response.statusCode == 200) {
        return AppVersionInfo.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 下载 APK 并触发安装
  Future<bool> downloadAndInstall(
    AppVersionInfo versionInfo, {
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      // 检查安装权限（Android 8+ 需要）
      if (await Permission.requestInstallPackages.status.isDenied) {
        final result = await Permission.requestInstallPackages.request();
        if (!result.isGranted) {
          return false;
        }
      }

      // 下载到临时目录（固定文件名，每次覆盖）
      final tempDir = await getTemporaryDirectory();
      const fileName = 'oa_update.apk';
      final filePath = '${tempDir.path}/$fileName';

      await dioClient.dio.download(
        versionInfo.downloadUrl,
        filePath,
        onReceiveProgress: onProgress,
      );

      // 打开安装界面
      final result = await open_file.OpenFilex.open(filePath);
      return result.type == open_file.ResultType.done;
    } catch (e) {
      return false;
    }
  }
}

/// 全局实例
final appUpdateService = AppUpdateService();
