// import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import './constants/checkin_enums.dart';

class CheckinRecordDto {
  final CheckinType checkinType;
  final double longitude;
  final double latitude;
  final CheckinStatus status;
  final DateTime checkinTime;
  final bool isInRange;
  final String dateStr;

  CheckinRecordDto({
    required this.checkinType,
    required this.longitude,
    required this.latitude,
    required this.status,
    required this.checkinTime,
    required this.isInRange,
    required this.dateStr,
  });

  factory CheckinRecordDto.fromJson(Map<String, dynamic> json) {
    final DateTime time = DateTime.parse(json['checkinTime']);
    final String dateStr = DateFormat('yyyy-MM-dd').format(time);
    return CheckinRecordDto(
      checkinType: CheckinType.values.firstWhere(
        (e) => e.value == json['checkinType'],
        orElse: () => CheckinType.workStart,
      ),
      longitude: (json['longitude'] as num).toDouble(),
      latitude: (json['latitude'] as num).toDouble(),
      status: CheckinStatus.fromInt(json['status']),
      checkinTime: DateTime.parse(json['checkinTime']),
      isInRange: json['isInRange'],
      dateStr: dateStr,
    );
  }

  bool get isAbnormal => status != CheckinStatus.normal;

  String get checkinTypeText =>
      checkinType == CheckinType.workStart ? '上班' : '下班';

  String get statusText {
    if (status == CheckinStatus.late) return '迟到';
    if (status == CheckinStatus.leaveEarly) return '早退';
    if (status == CheckinStatus.normal) return '正常';
    return '异常';
  }

  String get formattedCheckinTime {
    final time = checkinTime.toLocal();
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(time);
  }

  String get formattedCheckinDayTime {
    // final time = checkinTime.toLocal();
    return DateFormat('HH:mm:ss').format(checkinTime);
  }
}

class HolidayDetail {
  final String name;
  final String? desc;
  final String date;
  final String type;
  final String originalDayType;

  HolidayDetail({
    required this.name,
    this.desc,
    required this.date,
    required this.type,
    required this.originalDayType,
  });

  factory HolidayDetail.fromJson(Map<String, dynamic> json) {
    // if (json == null) {
    //   return HolidayDetail(
    //     name: '',
    //     desc: '',
    //     date: '',
    //     type: '',
    //     originalDayType: '',
    //   );
    // }
    return HolidayDetail(
      name: json['name'] ?? '',
      desc: json['desc'],
      date: json['date'] ?? '',
      type: json['type'] ?? '',
      originalDayType: json['originalDayType'] ?? '',
    );
  }
}

class Holidays {
  final int year;
  final int month;
  final List<HolidayDetail> holidaysDetail;

  Holidays({
    required this.year,
    required this.month,
    required this.holidaysDetail,
  });

  factory Holidays.fromJson(Map<String, dynamic> json) {
    final List<dynamic> detailList = json['holidaysDetail'] ?? [];
    final List<HolidayDetail> holidays = detailList
        .map((item) => HolidayDetail.fromJson(item))
        .toList();
    return Holidays(
      year: json['year'] ?? 0,
      month: json['month'] ?? 0,
      holidaysDetail: holidays,
    );
  }
}

class MonthlyAttendance {
  final int shouldAttendDays;
  final int actualAttendDays;
  final int totalCount;
  final int normalCount;
  final int lateCount;
  final int leaveEarlyCount;
  final int abnormalCount;
  final int rejectedCount;
  final List<CheckinRecordDto> records;
  final Holidays holidays;

  MonthlyAttendance({
    required this.shouldAttendDays,
    required this.actualAttendDays,
    required this.totalCount,
    required this.normalCount,
    required this.lateCount,
    required this.leaveEarlyCount,
    required this.abnormalCount,
    required this.rejectedCount,
    required this.records,
    required this.holidays,
  });

  factory MonthlyAttendance.fromJson(Map<String, dynamic> json) {
    final List<dynamic> recordsJson = json['records'];
    final List<CheckinRecordDto> records = recordsJson
        .map((r) => CheckinRecordDto.fromJson(r))
        .toList();

    final Holidays holidays = Holidays.fromJson(json['holidays']);

    return MonthlyAttendance(
      shouldAttendDays: json['shouldAttendDays'],
      actualAttendDays: json['actualAttendDays'],
      totalCount: json['totalCount'],
      normalCount: json['normalCount'],
      lateCount: json['lateCount'],
      leaveEarlyCount: json['leaveEarlyCount'],
      abnormalCount: json['abnormalCount'],
      rejectedCount: json['rejectedCount'],
      records: records,
      holidays: holidays,
    );
  }
}
