import 'dart:async';
// import 'dart:developer' as dev;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:oa_fontend/models/constants/text_style.dart';
import '../models/constants/app_colors.dart';
import '../utils/checkin_utils.dart';
import '../models/location.dart';
import '../models/response.dart';
import '../utils/user_manager.dart';
import '../utils/api_client.dart';
import '../utils/location_service.dart';
import '../models/constants/checkin_enums.dart';
import '../models/checkin.dart';
import 'package:flutter_calendar_carousel/flutter_calendar_carousel.dart'
    show CalendarCarousel;

class CheckInPage extends StatefulWidget {
  const CheckInPage({super.key});

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<QuQResponse<LocationModel>> _locationFuture;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // 初始化控制器，设置两个选项卡
    _tabController = TabController(length: 2, vsync: this);
    _locationFuture = apiClient.getLocation();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        // _updateCurrentTime();
        setState(() {});
      }
    });
  }

  void _refreshLocationData() {
    setState(() {
      _locationFuture = apiClient.getLocation();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: const Text('考勤打卡'),
        centerTitle: true,
        backgroundColor: AppColors.mainBackground,
        foregroundColor: AppColors.primary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: '打卡'),
            Tab(text: '考勤统计'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          CheckInFormPage(
            locationFuture: _locationFuture,
            onRefresh: _refreshLocationData,
          ),
          const AttendanceStatisticsPage(),
        ],
      ),
    );
  }
}

class CheckInFormPage extends StatefulWidget {
  final Future<QuQResponse<LocationModel>> locationFuture;
  final VoidCallback onRefresh;

  const CheckInFormPage({
    super.key,
    required this.locationFuture,
    required this.onRefresh,
  });

  @override
  State<CheckInFormPage> createState() => _CheckInFormPageState();
}

class _CheckInFormPageState extends State<CheckInFormPage> {
  final LocationService _locationService = LocationService();
  Position? _currentPosition;
  bool _isLoading = false;
  bool _isInRange = false;
  CheckinRecordDto? _workStartRecord;
  CheckinRecordDto? _workEndRecord;
  late Future<Position?> _posFuture;

  int? _serverTimestamp;
  int? _timeDiff;
  @override
  void initState() {
    super.initState();
    _fetchServerTime();
    _fetchTodayCheckinRecord();
    _posFuture = _locationService.getCurLocation();
    // _fetchLocation();
  }

  Future<void> _fetchServerTime() async {
    final response = await apiClient.getServerTime();
    if (response.success && response.data != null) {
      setState(() {
        _serverTimestamp = response.data!['timestamp'] as int;
        _timeDiff = DateTime.now().millisecondsSinceEpoch - _serverTimestamp!;
      });
    }
  }

  Future<void> _fetchTodayCheckinRecord() async {
    try {
      final result = await apiClient.getCheckinStatus();
      if (result.success) {
        setState(() {
          _workStartRecord = null;
          _workEndRecord = null;
        });
        if (result.data != null && result.data!.isNotEmpty) {
          for (final record in result.data!) {
            setState(() {
              if (record.checkinType == CheckinType.workStart) {
                _workStartRecord = record;
              } else if (record.checkinType == CheckinType.workEnd) {
                _workEndRecord = record;
              }
            });
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? '获取打卡记录失败'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取打卡记录异常：$e'), backgroundColor: Colors.red),
        );
      }
    } finally {} //////
  }

  void _fetchLocation() {
    setState(() {
      _posFuture = _locationService.getCurLocation();
    });
  }

  Future<void> _handleCheckin(CheckinType checkinType) async {
    if (_isLoading) return;
    if (!_isInRange) {
      final bool? confirm = await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('提示'),
          content: const Text('当前超出打卡范围，是否继续?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("取消", style: TextStyle(color: AppColors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('确认', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirm != true) return; //因为confirm有可能null，所以不用!comfirm
    }
    try {
      setState(() => _isLoading = true);
      if (_currentPosition == null) throw Exception("获取定位失败，请检查定位服务和权限");
      final result = await apiClient.performCheckin(
        checkinType,
        _currentPosition!,
      );
      if (result.success) {
        if (result.data != null) {
          setState(() {
            if (checkinType == CheckinType.workStart) {
              _workStartRecord = result.data;
            } else if (checkinType == CheckinType.workEnd) {
              _workEndRecord = result.data;
            }
          });
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? "OK"),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        throw Exception(result.message ?? "打卡失败，服务器返回异常");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          CurrentTimeWidget(
            serverTimestamp: _serverTimestamp,
            timeDiff: _timeDiff,
          ),
          const SizedBox(height: 20),
          FutureBuilder<QuQResponse<LocationModel>>(
            future: widget.locationFuture,
            builder: (context, locaSnapshot) {
              if (locaSnapshot.connectionState == ConnectionState.waiting) {
                return const Column(
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text('正在加载...'),
                  ],
                );
              }
              if (locaSnapshot.hasError ||
                  !locaSnapshot.hasData ||
                  !locaSnapshot.data!.success) {
                String errorMsg = locaSnapshot.hasData
                    ? locaSnapshot.data!.message ?? '未知错误'
                    : '加载失败：${locaSnapshot.error ?? '未知错误'}';
                return Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      errorMsg,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: widget.onRefresh,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text(
                        '重新加载',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                );
              }
              final locationData = locaSnapshot.data!.data!;
              return FutureBuilder<Position?>(
                future: _posFuture,
                builder: (context, posSnapshot) {
                  if (posSnapshot.connectionState == ConnectionState.waiting) {
                    return const Column(
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 15),
                        Text('正在定位...'),
                      ],
                    );
                  }
                  if (!posSnapshot.hasData || posSnapshot.data == null) {
                    return Column(
                      children: [
                        const Icon(
                          Icons.location_off,
                          color: AppColors.warning,
                          size: 40,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "获取定位失败，请检查定位权限和服务",
                          style: TextStyle(color: AppColors.warning),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchLocation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          child: const Text(
                            '重新定位',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    );
                  }
                  final position = posSnapshot.data!;
                  _currentPosition = position;
                  final distance = GeoCalculator.calculateDistance(
                    locationData.centerLatitude,
                    locationData.centerLongitude,
                    position.latitude,
                    position.longitude,
                  );
                  final actual =
                      locationData.radius +
                      min(position.accuracy * 0.5, locationData.bufferRadius) -
                      1;
                  _isInRange = distance <= actual;
                  // 判断打卡状态
                  final hasWorkStart = _workStartRecord != null;
                  final hasWorkEnd = _workEndRecord != null;
                  final canCheckInWorkStart = !hasWorkStart;
                  final canCheckInWorkEnd = hasWorkStart && !hasWorkEnd;
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            _buildCheckInButton(
                              canCheckInWorkStart: canCheckInWorkStart,
                              canCheckInWorkEnd: canCheckInWorkEnd,
                              hasWorkStart: hasWorkStart,
                              hasWorkEnd: hasWorkEnd,
                              locationData: locationData,
                              isInRange: _isInRange,
                            ),
                            const SizedBox(height: 24),
                            _buildCheckInStatusText(
                              canCheckInWorkStart: canCheckInWorkStart,
                              canCheckInWorkEnd: canCheckInWorkEnd,
                              hasWorkStart: hasWorkStart,
                              hasWorkEnd: hasWorkEnd,
                              workStartRecord: _workStartRecord,
                              workEndRecord: _workEndRecord,
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        _buildInfoCard(
                          locationData,
                          _isInRange,
                          _fetchLocation,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInButton({
    required bool canCheckInWorkStart,
    required bool canCheckInWorkEnd,
    required bool hasWorkStart,
    required bool hasWorkEnd,
    required LocationModel locationData,
    required bool isInRange,
  }) {
    String buttonText;
    CheckinType? checkinType;
    Color buttonColor = AppColors.primary;
    bool showButton = true;

    if (canCheckInWorkStart) {
      buttonText = '上班打卡';
      checkinType = CheckinType.workStart;
    } else if (canCheckInWorkEnd) {
      buttonText = '下班打卡';
      checkinType = CheckinType.workEnd;
    } else if (hasWorkStart && hasWorkEnd) {
      buttonText = '今日已打卡';
      showButton = false;
    } else {
      buttonText = '等待打卡';
      showButton = false;
    }
    if (!isInRange && showButton) {
      buttonColor = AppColors.warning;
    }
    if (!showButton) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.success.withAlpha(220),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.success.withAlpha(76),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check, color: Colors.white, size: 32),
            const SizedBox(height: 2),
            Text(
              buttonText,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    return GestureDetector(
      onTap: _isLoading
          ? null
          : () {
              if (checkinType != null) {
                _handleCheckin(checkinType);
              }
            },
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: buttonColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: buttonColor.withAlpha(100),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _isLoading
            ? const Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.touch_app, color: Colors.white, size: 32),
                  const SizedBox(height: 2),
                  Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCheckInStatusText({
    required bool canCheckInWorkStart,
    required bool canCheckInWorkEnd,
    required bool hasWorkStart,
    required bool hasWorkEnd,
    CheckinRecordDto? workStartRecord,
    CheckinRecordDto? workEndRecord,
  }) {
    Widget content;
    if (hasWorkStart && hasWorkEnd) {
      final workStartTime = DateFormat(
        'HH:mm:ss',
      ).format(workStartRecord!.checkinTime);
      final workEndTime = DateFormat(
        'HH:mm:ss',
      ).format(workEndRecord!.checkinTime);
      content = Column(
        children: [
          const Text(
            '今日考勤已完成',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.lightPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '上班卡 - $workStartTime',
            style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          ),
          Text(
            '下班卡 - $workEndTime',
            style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          ),
        ],
      );
    } else if (hasWorkStart) {
      final workStartTime = DateFormat(
        'HH:mm:ss',
      ).format(workStartRecord!.checkinTime);
      content = Column(
        children: [
          Text(
            '上班卡 - $workStartTime',
            style: const TextStyle(fontSize: 14, color: AppColors.lightPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            canCheckInWorkEnd ? '等待下班打卡...' : '',
            style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          ),
        ],
      );
    } else {
      content = Text(
        canCheckInWorkStart ? '点击上方按钮进行上班打卡' : '',
        style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
      );
    }
    return SizedBox(
      height: 80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [content, const Spacer()],
      ),
    );
  }

  Widget _buildInfoCard(
    LocationModel locationData,
    bool isInRange,
    VoidCallback onFetchLoca,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _isInRange
                  ? AppColors.lightPrimary.withAlpha(25)
                  : AppColors.warning.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _isInRange
                ? const Icon(
                    Icons.check_circle,
                    color: AppColors.lightPrimary,
                    size: 20,
                  )
                : const Icon(
                    Icons.location_off,
                    color: AppColors.warning,
                    size: 20,
                  ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userManager.username ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isInRange ? '已进入考勤范围' : '在考勤范围外',
                style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onFetchLoca,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(80, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('刷新定位', style: AppTextStyle.primaryTips),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CurrentTimeWidget extends StatefulWidget {
  final int? serverTimestamp;
  final int? timeDiff;
  const CurrentTimeWidget({super.key, this.serverTimestamp, this.timeDiff});

  @override
  State<CurrentTimeWidget> createState() => _CurrentTimeWidgetState();
}

class _CurrentTimeWidgetState extends State<CurrentTimeWidget> {
  late String _formattedDate;
  late String _formattedTime;
  late String _weekday;
  late Timer _timer;

  static const List<String> weekdayCN = [
    '',
    '周一',
    '周二',
    '周三',
    '周四',
    '周五',
    '周六',
    '周日',
  ];

  @override
  void initState() {
    super.initState();
    // _fetchServerTime();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _updateTime();
      }
    });
  }

  void _updateTime() {
    DateTime currentTime;
    if (widget.serverTimestamp != null && widget.timeDiff != null) {
      final realServerTime =
          DateTime.now().millisecondsSinceEpoch - widget.timeDiff!;
      currentTime = DateTime.fromMillisecondsSinceEpoch(realServerTime);
    } else {
      currentTime = DateTime.now();
    }
    _formattedDate = '${currentTime.month}月${currentTime.day}日';
    _formattedTime = DateFormat('HH:mm:ss').format(currentTime);
    _weekday = weekdayCN[currentTime.weekday];
    setState(() {});
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "$_formattedDate $_weekday",
          style: const TextStyle(fontSize: 16, color: Color(0xFF9CA3AF)),
        ),
        const SizedBox(height: 4),
        Text(
          _formattedTime,
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

//-----------------------------------------------------
// 打卡记录

class AttendanceStatisticsPage extends StatefulWidget {
  const AttendanceStatisticsPage({super.key});

  @override
  State<AttendanceStatisticsPage> createState() =>
      _AttendanceStatisticsPageState();
}

class _AttendanceStatisticsPageState extends State<AttendanceStatisticsPage> {
  // List<Event> events =[Event(icon: Icons.local_airport_outlined)]
  DateTime _currentDate = DateTime.now();
  bool _isSelected = false;
  MonthlyAttendance? _monthlyData;
  bool _isLoading = false;
  String _errorMsg = '';
  Map<String, List<CheckinRecordDto>> _dateRecordsMap = {};
  final _weekendTextStyle = const TextStyle(
    color: Colors.pinkAccent,
    fontWeight: FontWeight.normal,
    fontSize: 14,
  );
  final Map<String, HolidayDetail> _holidayMap = {};

  final _daysTextStyle = const TextStyle(
    color: Colors.black,
    fontWeight: FontWeight.normal,
    fontSize: 14,
  );

  final _todayTextStyle = const TextStyle(
    color: AppColors.primary,
    fontWeight: FontWeight.bold,
  );

  final _selectedDayTextStyle = const TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.normal,
  );

  @override
  void initState() {
    super.initState();
    _fetchMonthlyCheckinData();
  }

  DateTime _getMonthFirstDay() {
    return DateTime(_currentDate.year, _currentDate.month, 1);
  }

  DateTime _getMonthLastDay() {
    return DateTime(_currentDate.year, _currentDate.month + 1, 0);
  }

  Future<void> _fetchMonthlyCheckinData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMsg = '';
        _dateRecordsMap.clear();
        _monthlyData = null;
        _holidayMap.clear();
      });
      final result = await apiClient.getMonthlyCheckin(
        _getMonthFirstDay(),
        _getMonthLastDay(),
      );
      setState(() {
        if (result.success) {
          _monthlyData = result.data;
          if (result.data != null) {
            _buildDateRecordsMap(result.data!.records);
            final Holidays holidays = result.data!.holidays;
            for (final detail in holidays.holidaysDetail) {
              _holidayMap[detail.date] = detail;
            }
          }
        } else {
          _errorMsg = result.message ?? '未知故障';
        }
      });
    } catch (e) {
      setState(() {
        _errorMsg = '请求异常:$e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _buildDateRecordsMap(List<CheckinRecordDto> records) {
    Map<String, List<CheckinRecordDto>> map = {};
    for (var record in records) {
      if (!map.containsKey(record.dateStr)) {
        map[record.dateStr] = [];
      }
      map[record.dateStr]!.add(record);
    }
    setState(() {
      _dateRecordsMap = map;
    });
  }

  bool _hasAbnormalRecord(String dateStr) {
    final List<CheckinRecordDto>? records = _dateRecordsMap[dateStr];
    if (records == null || records.isEmpty) return false;
    return records.any((r) => r.isAbnormal);
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildAttendanceStatistics() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMsg.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          _errorMsg,
          style: const TextStyle(color: Colors.red, fontSize: 14),
        ),
      );
    }

    if (_monthlyData == null) {
      return const Padding(padding: EdgeInsets.all(20), child: Text('暂无考勤数据'));
    }

    if (_isSelected) {
      final String dateStr = _formatDate(_currentDate);
      final List<CheckinRecordDto>? dayRecords = _dateRecordsMap[dateStr];

      return Card(
        elevation: 2,
        color: AppColors.mainBackground,
        margin: const EdgeInsets.symmetric(horizontal: 0),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_currentDate.month}月${_currentDate.day}日 考勤详情',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (dayRecords == null || dayRecords.isEmpty)
                const Center(
                  child: Text('当日无打卡记录', style: AppTextStyle.middleTips),
                )
              else ...[
                ...dayRecords.map(
                  (record) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 4,
                      childAspectRatio: 2,
                      // padding: const EdgeInsets.all(4),
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              record.checkinTypeText,
                              style: AppTextStyle.tips,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              record.formattedCheckinDayTime,
                              style: TextStyle(
                                fontSize: 14,
                                color: record.isAbnormal
                                    ? Colors.red
                                    : AppColors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                const Text('状态: ', style: AppTextStyle.tips),
                                Text(
                                  record.statusText,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: record.isAbnormal
                                        ? Colors.red
                                        : AppColors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Text('打卡范围: ', style: AppTextStyle.tips),
                                Text(
                                  record.isInRange ? '在范围内' : '超出范围',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: record.isInRange
                                        ? AppColors.success
                                        : AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${record.longitude.toStringAsFixed(6)}, ${record.latitude.toStringAsFixed(6)}',
                              style: AppTextStyle.tips,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Card(
      color: AppColors.mainBackground,
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '月度考勤概览',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.transparent,
                // borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem(
                    '迟到次数',
                    _monthlyData!.lateCount.toString(),
                    Colors.red,
                  ),
                  _buildStatItem(
                    '早退次数',
                    _monthlyData!.leaveEarlyCount.toString(),
                    AppColors.warning,
                  ),
                  _buildStatItem(
                    '正常次数',
                    _monthlyData!.normalCount.toString(),
                    AppColors.success,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, [Color? color]) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            color: color ?? AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(title, style: AppTextStyle.tips),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Card(
            color: AppColors.mainBackground,
            elevation: 0,
            child: CalendarCarousel(
              scrollDirection: Axis.vertical,
              showOnlyCurrentMonthDate: true,
              showWeekDays: true,
              weekdayTextStyle: const TextStyle(
                color: AppColors.grey,
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
              daysTextStyle: _daysTextStyle,
              weekendTextStyle: _weekendTextStyle,
              todayTextStyle: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
              todayBorderColor: AppColors.primary,
              selectedDayButtonColor: AppColors.primary,
              selectedDayBorderColor: AppColors.primary,
              selectedDayTextStyle: const TextStyle(color: Colors.white),
              todayButtonColor: Color(0xFFCBF7ED),
              height: 360,
              locale: 'zh_CN',
              selectedDateTime: _isSelected ? _currentDate : null,
              customDayBuilder:
                  (
                    isSelectable,
                    index,
                    isSelectedDay,
                    isToday,
                    isPrevMonthDay,
                    textStyle,
                    isNextMonthDay,
                    isThisMonthDay,
                    day,
                  ) {
                    final dateStr = _formatDate(day);

                    final holiday = _holidayMap[dateStr];
                    // final hasRecords = _dateRecordsMap.containsKey(dateStr);
                    final isAbnormal = _hasAbnormalRecord(dateStr);
                    final needRedDot = isAbnormal;
                    // final needRedDot = isAbnormal || !hasRecords;

                    // 核心诉求，holiday和abnormal(needRedDot)各自有各自画，同时有同时画
                    TextStyle? holidayTextStyle;
                    Icon? topLeftIcon;
                    if (holiday != null) {
                      if (holiday.type == 'holiday') {
                        topLeftIcon = const Icon(
                          Icons.grass,
                          size: 12,
                          color: AppColors.primary,
                        );
                        holidayTextStyle = _weekendTextStyle;
                      } else {
                        topLeftIcon = const Icon(
                          Icons.work,
                          size: 12,
                          color: AppColors.primary,
                        );
                        holidayTextStyle = _daysTextStyle;
                      }
                    }
                    final Icon? topRightIcon = needRedDot
                        ? const Icon(Icons.circle, size: 8, color: Colors.red)
                        : null;
                    if (topLeftIcon == null && topRightIcon == null) {
                      return null;
                    }

                    return _buildDayWithIcon(
                      day,
                      now,
                      isSelectedDay,
                      topLeftIcon,
                      topRightIcon,
                      customTextStyle: holidayTextStyle,
                    );
                  },
              onDayPressed: (DateTime date, _) {
                setState(() {
                  if (_currentDate.day == date.day && _isSelected) {
                    _isSelected = false;
                    // 显示总考勤统计
                  } else {
                    _isSelected = true;
                    _currentDate = date;
                    // 显示selectedDate考勤信息
                  }
                });
              },
              onCalendarChanged: (DateTime date) {
                setState(() {
                  _currentDate = date;
                  _isSelected = false;
                });
                _fetchMonthlyCheckinData();
              },
            ),
          ),
          const SizedBox(height: 20),
          _buildAttendanceStatistics(),
        ],
      ),
    );
  }

  Widget _buildDayWithIcon(
    DateTime day,
    DateTime now,
    bool isSelectedDay,
    Icon? topLeftIcon,
    Icon? topRightIcon, {
    TextStyle? customTextStyle,
  }) {
    final targetTextStyle = isSelectedDay
        ? _selectedDayTextStyle
        : (customTextStyle ??
              (_isSameDay(day, now) ? _todayTextStyle : _daysTextStyle));

    final List<Widget> stackChildren = [
      Text('${day.day}', style: targetTextStyle),
    ];
    if (topLeftIcon != null) {
      stackChildren.add(Positioned(top: 2, left: 2, child: topLeftIcon));
    }
    if (topRightIcon != null) {
      stackChildren.add(Positioned(top: 2, right: 2, child: topRightIcon));
    }
    return SizedBox.expand(
      child: Stack(alignment: Alignment.center, children: stackChildren),
    );
  }
}
