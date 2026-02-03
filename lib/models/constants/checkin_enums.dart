import 'package:flutter/material.dart';

enum CheckinType {
  workStart(1), // 上班
  workEnd(2), // 下班
  goOut(3), // 外出（预留）
  returnBack(4), // 返回（预留）
  supplement(5); // 补卡（预留）

  final int value;
  const CheckinType(this.value);
}

enum LocationSource {
  gps(1), // GPS定位
  wifi(2), // WiFi定位
  cellular(3), // 基站定位
  hybrid(4), // 混合定位
  manual(5); // 手动选择（预留）

  final int value;
  const LocationSource(this.value);
}

enum CheckinStatus {
  pending(1), // 待审核
  normal(2), // 正常
  late(3), // 迟到
  leaveEarly(4), // 早退
  abnormal(5), // 异常
  rejected(6); // 已驳回

  final int value;
  const CheckinStatus(this.value);

  static CheckinStatus fromInt(int value) {
    return CheckinStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CheckinStatus.abnormal,
    );
  }

  String get desc {
    switch (this) {
      case CheckinStatus.pending:
        return "待审核";
      case CheckinStatus.normal:
        return "打卡正常";
      case CheckinStatus.late:
        return "打卡迟到";
      case CheckinStatus.leaveEarly:
        return "打卡早退";
      case CheckinStatus.abnormal:
        return "打卡异常";
      case CheckinStatus.rejected:
        return "打卡已驳回";
    }
  }

  Color get color {
    switch (this) {
      case CheckinStatus.normal:
        return Colors.green; // 正常-绿色
      case CheckinStatus.pending:
        return Colors.blue; // 待审核-蓝色
      case CheckinStatus.late:
      case CheckinStatus.leaveEarly:
        return Colors.orange; // 迟到/早退-橙色
      case CheckinStatus.abnormal:
      case CheckinStatus.rejected:
        return Colors.red; // 异常/驳回-红色
    }
  }
}
