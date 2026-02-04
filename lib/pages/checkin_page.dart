import 'dart:async';
// import 'dart:developer' as dev;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../models/constants/app_colors.dart';
import '../utils/checkin_utils.dart';
import '../models/location.dart';
import '../models/response.dart';
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

  // void _updateCurrentTime() {
  //   final now = DateTime.now();
  //   _currentTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
  // }

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
        // backgroundColor: const Color(0xFF99DE9F),
        centerTitle: true,
        backgroundColor: AppColors.mainBackground,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
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
  // String? _errorMsg;
  // static const _themeColor = Color(0xFF99DE9F);

  int? _serverTimestamp;
  int? _timeDiff;
  bool _timeErr = false;

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
        _timeErr = false;
      });
    } else {
      setState(() {
        _timeErr = true;
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
              backgroundColor: Colors.orange,
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
    // _posFuture = _locationService.getCurLocation();
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
              child: const Text("取消", style: TextStyle(color: Colors.grey)),
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
              backgroundColor: Colors.green,
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
    return SingleChildScrollView(
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
                          color: Colors.orange,
                          size: 40,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "获取定位失败，请检查定位权限和服务",
                          style: TextStyle(color: Colors.orange),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchLocation,
                          child: const Text("重新定位"),
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
                  return Column(
                    children: [
                      Text(
                        "打卡点:${locationData.name} | 当前距离:$distance米 | 精度:${position.accuracy} | 实际范围:$actual",
                        style: TextStyle(
                          color: _isInRange ? AppColors.secondary : Colors.red,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isInRange ? "已进入打卡范围" : "超出打卡范围",
                        style: TextStyle(
                          color: _isInRange ? AppColors.secondary : Colors.red,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _fetchLocation,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(80, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          '重新定位',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Column(
                        children: [
                          CheckInCard(
                            title: '上班',
                            targetTime: locationData.workTimeStart,
                            type: CheckinType.workStart,
                            onCheckIn: () =>
                                _handleCheckin(CheckinType.workStart),
                            isLoading: _isLoading,
                            isShowBtn: true,
                            checkinRecord: _workStartRecord,
                            serverTimestamp: _serverTimestamp,
                            timeDiff: _timeDiff,
                          ),
                          const SizedBox(height: 20),
                          CheckInCard(
                            title: '下班',
                            targetTime: locationData.workTimeEnd,
                            type: CheckinType.workEnd,
                            onCheckIn: () =>
                                _handleCheckin(CheckinType.workEnd),
                            isLoading: _isLoading,
                            isShowBtn: _workStartRecord != null,
                            checkinRecord: _workEndRecord,
                            serverTimestamp: _serverTimestamp,
                            timeDiff: _timeDiff,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
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
    _formattedTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(currentTime);
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
    return Text(
      "$_formattedTime $_weekday",
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}

class CheckInCard extends StatelessWidget {
  final String title;
  final String targetTime;
  final CheckinType type;
  final VoidCallback onCheckIn;
  final bool isLoading;
  final bool isShowBtn;
  final CheckinRecordDto? checkinRecord;
  final int? serverTimestamp;
  final int? timeDiff;

  const CheckInCard({
    super.key,
    required this.title,
    required this.targetTime,
    required this.type,
    required this.onCheckIn,
    required this.isLoading,
    required this.isShowBtn,
    this.checkinRecord,
    this.serverTimestamp,
    this.timeDiff,
  });

  DateTime _parseTimeString(String timeStr) {
    final parts = timeStr.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  Color _getButtonColor() {
    DateTime now;
    if (serverTimestamp != null && timeDiff != null) {
      final realServerTime = DateTime.now().millisecondsSinceEpoch - timeDiff!;
      now = DateTime.fromMillisecondsSinceEpoch(realServerTime);
    } else {
      now = DateTime.now();
    }
    final targetDateTime = _parseTimeString(targetTime);
    final isAfterTarget = now.isAfter(targetDateTime);
    if (type == CheckinType.workStart) {
      return isAfterTarget ? Colors.orange : AppColors.primary;
    }
    return isAfterTarget ? AppColors.primary : Colors.orange;
  }

  String _getStatusText() {
    if (checkinRecord != null) {
      return checkinRecord!.status.desc;
    }
    final targetDateTime = _parseTimeString(targetTime);
    final now = DateTime.now();
    final isAfterTarget = now.isAfter(targetDateTime);
    final formattedTarget = DateFormat('HH:mm').format(targetDateTime);
    if (type == CheckinType.workStart) {
      return isAfterTarget
          ? '打卡截止时间：$formattedTarget（已超时）'
          : '打卡截止时间：$formattedTarget（可打卡）';
    }
    return isAfterTarget
        ? '打卡开始时间：$formattedTarget（可打卡）'
        : '打卡开始时间：$formattedTarget（未到时间）';
  }

  Color _getTextColor(Color buttonColor) {
    if (checkinRecord != null) {
      return checkinRecord!.status.color;
    }
    return buttonColor;
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = _getButtonColor();
    final statusText = _getStatusText();
    final isChecked = checkinRecord != null;
    final formattedTarget = DateFormat(
      'HH:mm',
    ).format(_parseTimeString(targetTime));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              statusText,
              style: TextStyle(fontSize: 14, color: _getTextColor(buttonColor)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (!isChecked && isShowBtn)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                onPressed: isLoading ? null : onCheckIn,
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        '$title打卡',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            if (isChecked)
              Column(
                children: [
                  Text(
                    '打卡时间: ${checkinRecord!.formattedCheckinDayTime}',
                    style: TextStyle(
                      fontSize: 14,
                      color: checkinRecord!.status.color,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '打卡时间要求:$formattedTarget',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            else
              const Text(
                '今日尚未打卡',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}

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
                  child: Text(
                    '当日无打卡记录',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
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
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              record.formattedCheckinDayTime,
                              style: TextStyle(
                                fontSize: 14,
                                color: record.isAbnormal
                                    ? Colors.red
                                    : Colors.black87,
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
                                const Text(
                                  '状态: ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  record.statusText,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: record.isAbnormal
                                        ? Colors.red
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Text(
                                  '打卡范围: ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  record.isInRange ? '在范围内' : '超出范围',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: record.isInRange
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${record.longitude.toStringAsFixed(6)}, ${record.latitude.toStringAsFixed(6)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
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
                color: Colors.black87,
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
                    Colors.orange,
                  ),
                  _buildStatItem(
                    '正常次数',
                    _monthlyData!.normalCount.toString(),
                    Colors.green,
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
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
                color: Colors.grey,
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
