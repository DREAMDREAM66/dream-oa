import 'package:geolocator/geolocator.dart';
import 'dart:developer' as dev;

class LocationService {
  Future<bool> requestLocationPer() async {
    bool serviceEnable;
    LocationPermission permission;

    serviceEnable = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnable) {
      dev.log('定位失败：定位服务未开启', name: 'LocationService');
      return false;
    }
    permission = await Geolocator.checkPermission();
    dev.log('当前权限状态：$permission', name: 'LocationService');
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      dev.log('请求权限后状态：$permission', name: 'LocationService');
      if (permission == LocationPermission.denied) {
        dev.log('定位失败：用户拒绝定位权限', name: 'LocationService');
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      dev.log('定位失败：用户永久拒绝定位权限，需手动开启', name: 'LocationService');
      return false;
    }
    return true;
  }

  Future<Position?> getCurLocation({
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async {
    try {
      final hasPermission = await requestLocationPer();
      if (!hasPermission) {
        dev.log('定位失败：权限不足', name: 'LocationService');
        return null;
      }
      // 指定使用Android原生LocationManager

      dev.log('开始获取高精度定位，超时时间 10 秒', name: 'LocationService');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        forceAndroidLocationManager: true,
        timeLimit: const Duration(seconds: 10),
      );
      dev.log(
        '定位成功：经度=${position.longitude}, 纬度=${position.latitude}',
        name: 'LocationService',
      );
      return position;
    } catch (e, stackTrace) {
      dev.log(
        '定位抛出异常：$e',
        name: 'LocationService',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
