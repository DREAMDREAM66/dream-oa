import 'dart:async';
// import 'dart:developer' as dev;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:oa_fontend/utils/checkin_utils.dart';
import '../models/location.dart';
import '../models/response.dart';
import '../utils/api_client.dart';
import '../utils/location_service.dart';
import '../models/constants/checkin_enums.dart';
import '../models/checkin.dart';

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
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF99DE9F),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF99DE9F),
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
  String? _errorMsg;

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
                backgroundColor: const Color(0xFF99DE9F),
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
                    CircularProgressIndicator(color: Color(0xFF99DE9F)),
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
                        backgroundColor: const Color(0xFF99DE9F),
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
                        CircularProgressIndicator(color: Color(0xFF99DE9F)),
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
                          color: _isInRange ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isInRange ? "已进入打卡范围" : "超出打卡范围",
                        style: TextStyle(
                          color: _isInRange ? Colors.green : Colors.red,
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
                            color: Color(0xFF99DE9F),
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
  late Timer _timer;

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
      _formattedTime,
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
      return isAfterTarget ? Colors.orange : const Color(0xFF99DE9F);
    }
    return isAfterTarget ? const Color(0xFF99DE9F) : Colors.orange;
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
            if (!isChecked)
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
                    '打卡时间:${checkinRecord!.formattedCheckinTime}',
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

class AttendanceStatisticsPage extends StatelessWidget {
  const AttendanceStatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    '2026年1月考勤统计',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      StatItem(title: '应打卡', value: '22天'),
                      StatItem(title: '已打卡', value: '18天'),
                      StatItem(title: '迟到', value: '2次'),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      StatItem(title: '早退', value: '0次'),
                      StatItem(title: '旷工', value: '0天'),
                      StatItem(title: '请假', value: '2天'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '考勤明细',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          AttendanceItem(
            date: '2026-01-22',
            checkInTime: '08:55',
            checkOutTime: '18:05',
            status: '正常',
          ),
          AttendanceItem(
            date: '2026-01-21',
            checkInTime: '09:10',
            checkOutTime: '18:00',
            status: '迟到',
          ),
          AttendanceItem(
            date: '2026-01-20',
            checkInTime: '未打卡',
            checkOutTime: '未打卡',
            status: '旷工',
          ),
        ],
      ),
    );
  }
}

class StatItem extends StatelessWidget {
  final String title;
  final String value;

  const StatItem({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, color: Color(0xFF99DE9F)),
        ),
        const SizedBox(height: 4),
        Text(title),
      ],
    );
  }
}

class AttendanceItem extends StatelessWidget {
  final String date;
  final String checkInTime;
  final String checkOutTime;
  final String status;

  const AttendanceItem({
    super.key,
    required this.date,
    required this.checkInTime,
    required this.checkOutTime,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(date),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('上班：$checkInTime  下班：$checkOutTime'),
              const SizedBox(height: 4),
              Text(
                status,
                style: TextStyle(
                  color: status == '正常' ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
