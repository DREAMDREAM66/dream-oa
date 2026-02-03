import 'package:intl/intl.dart';
import './constants/checkin_enums.dart';

class CheckinRecordDto {
  final CheckinType checkinType;
  final double longitude;
  final double latitude;
  final CheckinStatus status;
  final DateTime checkinTime;

  CheckinRecordDto({
    required this.checkinType,
    required this.longitude,
    required this.latitude,
    required this.status,
    required this.checkinTime,
  });

  factory CheckinRecordDto.fromJson(Map<String, dynamic> json) {
    return CheckinRecordDto(
      checkinType: CheckinType.values.firstWhere(
        (e) => e.value == json['checkinType'],
        orElse: () => CheckinType.workStart,
      ),
      longitude: (json['longitude'] as num).toDouble(),
      latitude: (json['latitude'] as num).toDouble(),
      status: CheckinStatus.fromInt(json['status']),
      checkinTime: DateTime.parse(json['checkinTime']),
    );
  }

  String get formattedCheckinTime {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(checkinTime);
  }
}
