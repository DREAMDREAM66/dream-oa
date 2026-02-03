class LocationModel {
  final int id;
  final String name;
  final String description;
  final double centerLongitude;
  final double centerLatitude;
  final double radius;
  final int bufferRadius;
  final int locationType;
  final String? polygonVertices;
  final String validTimeStart;
  final String validTimeEnd;
  final String workdays;
  final String workTimeStart;
  final String workTimeEnd;
  final double? distanceFromUser;
  final bool? isInRange;
  final int attendanceRuleId;
  final bool allowFlexible;
  final int flexibleBeforeMinutes;
  final int flexibleAfterMinutes;
  final bool allowRemoteCheckin;
  final int maxRemoteCheckinDaysPerMonth;

  LocationModel({
    required this.id,
    required this.name,
    required this.description,
    required this.centerLongitude,
    required this.centerLatitude,
    required this.radius,
    required this.bufferRadius,
    required this.locationType,
    this.polygonVertices,
    required this.validTimeStart,
    required this.validTimeEnd,
    required this.workdays,
    required this.workTimeStart,
    required this.workTimeEnd,
    this.distanceFromUser,
    this.isInRange,
    required this.attendanceRuleId,
    required this.allowFlexible,
    required this.flexibleBeforeMinutes,
    required this.flexibleAfterMinutes,
    required this.allowRemoteCheckin,
    required this.maxRemoteCheckinDaysPerMonth,
  });

  // 从JSON转换为模型
  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      centerLongitude: (json['centerLongitude'] ?? 0.0).toDouble(),
      centerLatitude: (json['centerLatitude'] ?? 0.0).toDouble(),
      radius: (json['radius'] ?? 0.0).toDouble(),
      bufferRadius: (json['bufferRadius'] ?? 10),
      locationType: json['locationType'] ?? 0,
      polygonVertices: json['polygonVertices'],
      validTimeStart: json['validTimeStart'] ?? '',
      validTimeEnd: json['validTimeEnd'] ?? '',
      workdays: json['workdays'] ?? '',
      workTimeStart: json['workTimeStart'] ?? '',
      workTimeEnd: json['workTimeEnd'] ?? '',
      distanceFromUser: json['distanceFromUser'],
      isInRange: json['isInRange'],
      attendanceRuleId: json['attendanceRuleId'] ?? 0,
      allowFlexible: json['allowFlexible'] ?? false,
      flexibleBeforeMinutes: json['flexibleBeforeMinutes'] ?? 0,
      flexibleAfterMinutes: json['flexibleAfterMinutes'] ?? 0,
      allowRemoteCheckin: json['allowRemoteCheckin'] ?? false,
      maxRemoteCheckinDaysPerMonth: json['maxRemoteCheckinDaysPerMonth'] ?? 0,
    );
  }

  // 模型转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'centerLongitude': centerLongitude,
      'centerLatitude': centerLatitude,
      'radius': radius,
      'locationType': locationType,
      'polygonVertices': polygonVertices,
      'validTimeStart': validTimeStart,
      'validTimeEnd': validTimeEnd,
      'workdays': workdays,
      'workTimeStart': workTimeStart,
      'workTimeEnd': workTimeEnd,
      'distanceFromUser': distanceFromUser,
      'isInRange': isInRange,
      'attendanceRuleId': attendanceRuleId,
      'allowFlexible': allowFlexible,
      'flexibleBeforeMinutes': flexibleBeforeMinutes,
      'flexibleAfterMinutes': flexibleAfterMinutes,
      'allowRemoteCheckin': allowRemoteCheckin,
      'maxRemoteCheckinDaysPerMonth': maxRemoteCheckinDaysPerMonth,
    };
  }
}
