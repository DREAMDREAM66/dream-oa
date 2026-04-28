import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oa_fontend/models/constants/approval_enums.dart';

/// 草稿抽象接口
abstract interface class Draft {
  CategoryCode get categoryCode;
  Map<String, dynamic> toJson();
}

/// 请假草稿
class LeaveDraft implements Draft {
  final DateTime? startDate;
  final DateTime? startTime;
  final DateTime? endDate;
  final DateTime? endTime;
  final LeaveType? leaveType;
  final String reason;

  LeaveDraft({
    this.startDate,
    this.startTime,
    this.endDate,
    this.endTime,
    this.leaveType,
    this.reason = '',
  });

  @override
  CategoryCode get categoryCode => CategoryCode.leave;

  @override
  Map<String, dynamic> toJson() => {
    'startDate': startDate?.toIso8601String(),
    'startTime': startTime?.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'leaveType': leaveType?.value,
    'reason': reason,
  };

  factory LeaveDraft.fromJson(Map<String, dynamic> json) {
    return LeaveDraft(
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      leaveType: json['leaveType'] != null ? LeaveType.fromInt(json['leaveType']) : null,
      reason: json['reason'] ?? '',
    );
  }
}

/// 加班草稿
class OvertimeDraft implements Draft {
  final DateTime? startDate;
  final DateTime? startTime;
  final DateTime? endDate;
  final DateTime? endTime;
  final String reason;

  OvertimeDraft({
    this.startDate,
    this.startTime,
    this.endDate,
    this.endTime,
    this.reason = '',
  });

  @override
  CategoryCode get categoryCode => CategoryCode.overtime;

  @override
  Map<String, dynamic> toJson() => {
    'startDate': startDate?.toIso8601String(),
    'startTime': startTime?.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'reason': reason,
  };

  factory OvertimeDraft.fromJson(Map<String, dynamic> json) {
    return OvertimeDraft(
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      reason: json['reason'] ?? '',
    );
  }
}

/// 草稿反序列化函数类型
typedef DraftDeserializer = Draft Function(Map<String, dynamic> json);

/// 草稿管理器
class DraftManager {
  static final DraftManager _instance = DraftManager._internal();
  factory DraftManager() => _instance;
  DraftManager._internal();

  static const String _keyPrefix = 'draft_';

  // 注册的草稿反序列化器
  final Map<CategoryCode, DraftDeserializer> _deserializers = {};

  /// 注册草稿类型的反序列化器
  void registerDeserializer(CategoryCode code, DraftDeserializer deserializer) {
    _deserializers[code] = deserializer;
  }

  String _keyFor(CategoryCode code) => '$_keyPrefix${code.value}';

  /// 保存草稿
  Future<void> saveDraft(Draft draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFor(draft.categoryCode), json.encode(draft.toJson()));
  }

  /// 加载草稿
  Future<T?> loadDraft<T extends Draft>(CategoryCode code) async {
    final deserializer = _deserializers[code];
    if (deserializer == null) return null;

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_keyFor(code));
    if (saved == null) return null;

    return deserializer(json.decode(saved)) as T;
  }

  /// 清除草稿
  Future<void> clearDraft(CategoryCode code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFor(code));
  }

  /// 清除所有草稿
  Future<void> clearAllDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    for (final code in CategoryCode.values) {
      await prefs.remove(_keyFor(code));
    }
  }
}

final draftManager = DraftManager();

// ─── 初始化 ────────────────────────────────────────────────────────

void setupDraftManager() {
  draftManager.registerDeserializer(CategoryCode.leave, (json) => LeaveDraft.fromJson(json));
  draftManager.registerDeserializer(CategoryCode.overtime, (json) => OvertimeDraft.fromJson(json));
  // 以后新增：
  // draftManager.registerDeserializer(CategoryCode.reimbursement, (json) => ReimbursementDraft.fromJson(json));
}
