import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:oa_fontend/models/constants/app_colors.dart';
import 'package:oa_fontend/models/constants/text_style.dart';
import 'package:oa_fontend/models/constants/approval_enums.dart';
import 'package:oa_fontend/models/approval.dart';
import 'package:oa_fontend/utils/user_manager.dart';
import 'package:oa_fontend/utils/draft_manager.dart';
import 'package:oa_fontend/utils/api_client.dart';
import 'package:oa_fontend/widgets/datetime_picker.dart';
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
  void initState() {
    super.initState();
    _loadDraft();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadDraft() async {
    final draft = await draftManager.loadDraft<LeaveDraft>(CategoryCode.leave);
    if (draft != null && mounted) {
      setState(() {
        _startDate = draft.startDate;
        _startTime = draft.startTime;
        _endDate = draft.endDate;
        _endTime = draft.endTime;
        _leaveType = draft.leaveType;
        _reasonController.text = draft.reason;
      });
    }
  }

  Future<void> _saveDraft() async {
    final draft = LeaveDraft(
      startDate: _startDate,
      startTime: _startTime,
      endDate: _endDate,
      endTime: _endTime,
      leaveType: _leaveType,
      reason: _reasonController.text,
    );
    await draftManager.saveDraft(draft);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('草稿已保存'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _onStartChanged(DateTime? date, DateTime? time) {
    setState(() {
      if (date != null) _startDate = date;
      if (time != null) _startTime = time;
    });
  }

  void _onEndChanged(DateTime? date, DateTime? time) {
    setState(() {
      if (date != null) _endDate = date;
      if (time != null) _endTime = time;
    });
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
      type: _leaveType!,
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

    if (!mounted) return;
    setState(() { _isSubmitting = false; });

    if (response.success) {
      await draftManager.clearDraft(CategoryCode.leave);
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

  // ─── 卡片 ────────────────────────────────────────────────────────

  Widget _buildCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  // ─── 个人信息卡片 ────────────────────────────────────────────────────────

  Widget _buildUserInfoCard() {
    return _buildCard(
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
    return _buildCard(
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

          // 日期时间范围
          DateTimeRangeField(
            startDateLabel: '开始日期',
            startTimeLabel: '开始时间',
            endDateLabel: '结束日期',
            endTimeLabel: '结束时间',
            startDate: _startDate,
            startTime: _startTime,
            endDate: _endDate,
            endTime: _endTime,
            onStartChanged: _onStartChanged,
            onEndChanged: _onEndChanged,
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
          ReasonField(controller: _reasonController),
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
    final hasValue = _leaveType != null;
    return GestureDetector(
      onTap: _selectLeaveType,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: hasValue
              ? AppColors.primary.withAlpha(15)
              : AppColors.neuBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasValue
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
              color: hasValue ? AppColors.primary : AppColors.neuTextSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _leaveType == null ? '请选择请假类型' : _getLeaveTypeName(_leaveType!),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                  color: hasValue
                      ? AppColors.primary
                      : AppColors.neuTextSecondary,
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: hasValue ? AppColors.primary : AppColors.neuTextSecondary,
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

  // ─── 操作按钮 ────────────────────────────────────────────────────────

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildButton(
            label: '保存',
            icon: Icons.bookmark_border,
            isSecondary: true,
            isLoading: _isSubmitting,
            onTap: _saveDraft,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildButton(
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

  Widget _buildButton({
    required String label,
    required IconData icon,
    required bool isSecondary,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    final baseColor = isSecondary ? Colors.white : AppColors.primary;
    final textColor = isSecondary ? AppColors.neuTextPrimary : Colors.white;
    final iconColor = isSecondary ? AppColors.primary : Colors.white;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      // Stack可以让组件叠起来
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Container(
            height: 54,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(12),
              border: isSecondary
                  ? Border.all(color: AppColors.neuDivider)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: isSecondary
                      ? Colors.black.withAlpha(8)
                      : AppColors.primary.withAlpha(80),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Row(
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
          if (isLoading)
            // 不拦截点击，只是视觉
            IgnorePointer(
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(80),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
