import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:oa_fontend/models/constants/app_colors.dart';
import 'package:oa_fontend/models/constants/text_style.dart';
import 'package:oa_fontend/models/constants/approval_enums.dart';
import 'package:oa_fontend/models/approval.dart';
import 'package:oa_fontend/utils/user_manager.dart';
import 'package:oa_fontend/utils/api_client.dart';
import 'feature_page.dart';

class LeavePage extends FeaturePage {
  const LeavePage({
    super.key,
    required super.title,
    required super.functionKey,
  });

  @override
  Widget buildContent(BuildContext context) {
    return const LeavePageContent();
  }
}

class LeavePageContent extends StatefulWidget {
  const LeavePageContent({super.key});

  @override
  State<LeavePageContent> createState() => _LeavePageContentState();
}

class _LeavePageContentState extends State<LeavePageContent> {
  final _reasonController = TextEditingController();

  DateTime? _startDate;
  DateTime? _startTime;
  DateTime? _endDate;
  DateTime? _endTime;
  LeaveType? _leaveType;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(
    DateTime? currentDate,
    Function(DateTime) onSelected,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onSelected(picked);
      setState(() {});
    }
  }

  Future<void> _selectTime(
    DateTime? currentTime,
    Function(DateTime) onSelected,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(currentTime ?? DateTime.now()),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final now = DateTime.now();
      final selectedDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        picked.hour,
        picked.minute,
      );
      onSelected(selectedDateTime);
      setState(() {});
    }
  }

  Future<void> _submitForm() async {
    if (_startDate == null ||
        _startTime == null ||
        _endDate == null ||
        _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('请选择完整时间段', style: AppTextStyle.warning),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }
    if (_leaveType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('请选择请假类型', style: AppTextStyle.warning),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }
    if (_reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('请填写请假原因', style: AppTextStyle.warning),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }
    setState(() {
      _isSubmitting = true;
    });

    // 合并日期和时间
    final startDateTime = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );
    final endDateTime = DateTime(
      _endDate!.year,
      _endDate!.month,
      _endDate!.day,
      _endTime!.hour,
      _endTime!.minute,
    );

    // 构建 LeaveRequest
    final leaveRequest = LeaveRequest(
      startTime: startDateTime,
      endTime: endDateTime,
      reason: _reasonController.text,
      type: _leaveType!, // 已在前面验证不为 null
    );

    // 序列化为 JSON 放入 content
    final leaveRequestJson = json.encode(leaveRequest.toJson());

    // 构建 SubmitApprovalRequest
    final submitRequest = SubmitApprovalRequest(
      processCode: CategoryCode.leave,
      title: '请假申请',
      content: leaveRequestJson,
    );

    // 调用 API 提交
    final response = await apiClient.submitApproval(submitRequest);

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('申请提交成功'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('申请提交失败：${response.message}'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.neuBackground,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    _buildUserInfoCard(),
                    const SizedBox(height: 20),
                    _buildLeaveFormCard(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              child: _buildActionButtons(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Neumorphic(新拟物化)卡片 ───────────────────────────────────────────────────────

  Widget _buildNeuCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.neuBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          // 左上角白色阴影，模拟凸起表面
          BoxShadow(
            color: Colors.white,
            offset: const Offset(-4, -4),
            blurRadius: 8,
          ),
          // 右下角深色阴影，模拟立体深度
          BoxShadow(
            color: Colors.black.withAlpha(20),
            offset: const Offset(4, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: child,
    );
  }

  // ─── 个人信息卡片 ────────────────────────────────────────────────────────

  Widget _buildUserInfoCard() {
    return _buildNeuCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              userManager.username ?? '未知用户',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.neuTextPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                userManager.title ?? '未知职位',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.neuTextSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF0D9488)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  userManager.department ?? '未知部门',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 请假表单卡片 ───────────────────────────────────────────────────────

  Widget _buildLeaveFormCard() {
    return _buildNeuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('请假信息'),
          const SizedBox(height: 20),

          // 请假类型
          Text(
            '请假类型',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.neuTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _buildLeaveTypePicker(),
          const SizedBox(height: 20),

          // 开始时间
          Text(
            '开始时间',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.neuTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDatePicker(
                  '开始日期',
                  _startDate,
                  Icons.calendar_today,
                  () => _selectDate(
                    _startDate,
                    (d) => setState(() => _startDate = d),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTimePicker(
                  '开始时间',
                  _startTime,
                  Icons.access_time,
                  () => _selectTime(
                    _startTime,
                    (t) => setState(() => _startTime = t),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 结束时间
          Text(
            '结束时间',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.neuTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDatePicker(
                  '结束日期',
                  _endDate,
                  Icons.calendar_today,
                  () => _selectDate(
                    _endDate,
                    (d) => setState(() => _endDate = d),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTimePicker(
                  '结束时间',
                  _endTime,
                  Icons.access_time,
                  () => _selectTime(
                    _endTime,
                    (t) => setState(() => _endTime = t),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 请假原因
          Text(
            '请假原因',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.neuTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _buildReasonField(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.neuTextSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildDatePicker(
    String label,
    DateTime? value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return _buildNeuInk(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: value != null
              ? AppColors.primary.withAlpha(15)
              : AppColors.neuBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value != null
                ? AppColors.primary.withAlpha(60)
                : AppColors.neuDivider,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: value != null
                  ? AppColors.primary
                  : AppColors.neuTextSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value == null
                    ? label
                    : '${value.year}-${_addZero(value.month)}-${_addZero(value.day)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: value != null
                      ? FontWeight.w600
                      : FontWeight.normal,
                  color: value != null
                      ? AppColors.primary
                      : AppColors.neuTextSecondary,
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: value != null
                  ? AppColors.primary
                  : AppColors.neuTextSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(
    String label,
    DateTime? value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return _buildNeuInk(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: value != null
              ? AppColors.primary.withAlpha(15)
              : AppColors.neuBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value != null
                ? AppColors.primary.withAlpha(60)
                : AppColors.neuDivider,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: value != null
                  ? AppColors.primary
                  : AppColors.neuTextSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value == null
                    ? label
                    : '${_addZero(value.hour)}:${_addZero(value.minute)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: value != null
                      ? FontWeight.w600
                      : FontWeight.normal,
                  color: value != null
                      ? AppColors.primary
                      : AppColors.neuTextSecondary,
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: value != null
                  ? AppColors.primary
                  : AppColors.neuTextSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.neuBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.neuDivider, width: 1),
      ),
      child: TextField(
        controller: _reasonController,
        maxLines: 4,
        style: const TextStyle(fontSize: 14, color: AppColors.neuTextPrimary),
        decoration: InputDecoration(
          hintText: '请输入请假原因...',
          hintStyle: TextStyle(
            color: AppColors.neuTextSecondary.withAlpha(150),
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }

  Future<void> _selectLeaveType() async {
    final selected = await showDialog<LeaveType>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择请假类型'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: LeaveType.values.map((type) {
            return ListTile(
              title: Text(_getLeaveTypeName(type)),
              trailing: _leaveType == type
                  ? Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.pop(context, type),
            );
          }).toList(),
        ),
      ),
    );
    if (selected != null) {
      setState(() => _leaveType = selected);
    }
  }

  Widget _buildLeaveTypePicker() {
    return _buildNeuInk(
      onTap: _selectLeaveType,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: _leaveType != null
              ? AppColors.primary.withAlpha(15)
              : AppColors.neuBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _leaveType != null
                ? AppColors.primary.withAlpha(60)
                : AppColors.neuDivider,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.category_outlined,
              size: 16,
              color: _leaveType != null
                  ? AppColors.primary
                  : AppColors.neuTextSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _leaveType == null ? '请选择请假类型' : _getLeaveTypeName(_leaveType!),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: _leaveType != null
                      ? FontWeight.w600
                      : FontWeight.normal,
                  color: _leaveType != null
                      ? AppColors.primary
                      : AppColors.neuTextSecondary,
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: _leaveType != null
                  ? AppColors.primary
                  : AppColors.neuTextSecondary,
            ),
          ],
        ),
      ),
    );
  }

  String _getLeaveTypeName(LeaveType type) {
    switch (type) {
      case LeaveType.annual:
        return '年假';
      case LeaveType.sick:
        return '病假';
      case LeaveType.compensatory:
        return '调休';
      case LeaveType.personal:
        return '事假';
    }
  }

  Widget _buildNeuInk({required Widget child, required VoidCallback onTap}) {
    return GestureDetector(onTap: onTap, child: child);
  }

  // ─── 操作按钮 ────────────────────────────────────────────────────────

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildNeuButton(
            label: '保存',
            icon: Icons.bookmark_border,
            isSecondary: true,
            isLoading: _isSubmitting,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildNeuButton(
            label: '提交',
            icon: Icons.send,
            isSecondary: false,
            isLoading: _isSubmitting,
            onTap: _submitForm,
          ),
        ),
      ],
    );
  }

  Widget _buildNeuButton({
    required String label,
    required IconData icon,
    required bool isSecondary,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    final baseColor = isSecondary ? const Color(0xFFF1F5F9) : AppColors.primary;
    final textColor = isSecondary ? AppColors.neuTextPrimary : Colors.white;
    final iconColor = isSecondary ? AppColors.primary : Colors.white;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSecondary
              ? [
                  BoxShadow(
                    color: Colors.white,
                    offset: const Offset(-3, -3),
                    blurRadius: 6,
                  ),
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    offset: const Offset(3, 3),
                    blurRadius: 8,
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(80),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(textColor),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 18, color: iconColor),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  String _addZero(int num) => num.toString().padLeft(2, '0');
}
