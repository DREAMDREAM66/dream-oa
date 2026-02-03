import 'dart:convert';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class CheckinUtils {
  static Future<String> getDevInfoJson() async {
    final devInfoPlugin = DeviceInfoPlugin();
    String devModel;
    String os;

    if (Platform.isAndroid) {
      final androidInfo = await devInfoPlugin.androidInfo;
      devModel = androidInfo.model;
      os = "Android ${androidInfo.version.release}";
    } else {
      final iosInfo = await devInfoPlugin.iosInfo;
      devModel = iosInfo.model;
      os = "IOS ${iosInfo.systemVersion}";
    }
    final devInfoMap = {
      "deviceModel": devModel,
      "os": os,
      "client": "朝夕 - built with Flutter",
    };
    return const JsonEncoder().convert(devInfoMap);
  }
}

class GeoCalculator {
  static const double earthRadius = 6371000.0;

  static double _degressToRadius(double degress) {
    return degress * pi / 180.0;
  }

  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _degressToRadius(lat2 - lat1);
    final dLon = _degressToRadius(lon2 - lon1);
    final a =
        pow(sin(dLat / 2), 2) +
        cos(_degressToRadius(lat1)) *
            cos(_degressToRadius(lat2)) *
            pow(sin(dLon / 2), 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }
}
