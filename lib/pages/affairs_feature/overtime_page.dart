import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:oa_fontend/models/constants/app_colors.dart';
import 'package:oa_fontend/models/constants/text_style.dart';
import 'package:oa_fontend/models/constants/approval_enums.dart';
import 'package:oa_fontend/models/approval.dart';
import 'package:oa_fontend/utils/draft_manager.dart';
import 'package:oa_fontend/utils/api_client.dart';
import 'package:oa_fontend/pages/affairs_feature/widget/datetime_picker.dart';
import 'package:oa_fontend/pages/affairs_feature/widget/common_card.dart';
import 'package:oa_fontend/pages/affairs_feature/widget/user_info_card.dart';
import 'package:oa_fontend/pages/affairs_feature/widget/action_button.dart';
import 'feature_page.dart';

class OvertimePage extends FeaturePage {
  const OvertimePage({
    super.key,
    required super.title,
    required super.functionKey,
  });

  @override
  Widget buildContent(BuildContext context) {
    return const OvertimePageContent();
  }
}

class OvertimePageContent extends StatefulWidget {
  const OvertimePageContent({super.key});

  @override
  State<OvertimePageContent> createState() => _OvertimePageContentState();
}

class _OvertimePageContentState extends State<OvertimePageContent> {
  final _reasonController = TextEditingController();

  DateTime? _startDate;
  DateTime? _startTime;
  DateTime? _endDate;
  DateTime? _endTime;

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
    final draft = await draftManager.loadDraft<OvertimeDraft>(
      CategoryCode.overtime,
    );
    if (draft != null && mounted) {
      setState(() {
        _startDate = draft.startDate;
        _startTime = draft.startTime;
        _endDate = draft.endDate;
        _endTime = draft.endTime;
        _reasonController.text = draft.reason;
      });
    }
  }

  Future<void> _saveDraft() async {
    final draft = OvertimeDraft(
      startDate: _startDate,
      startTime: _startTime,
      endDate: _endDate,
      endTime: _endTime,
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
    if (_reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('请填写加班原因', style: AppTextStyle.warning),
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

    // 构建 OvertimeRequest
    final overtimeRequest = OvertimeRequest(
      startTime: startDateTime,
      endTime: endDateTime,
      reason: _reasonController.text,
    );

    // 序列化为 JSON 放入 content
    final overtimeRequestJson = json.encode(overtimeRequest.toJson());

    // 构建 SubmitApprovalRequest
    final submitRequest = SubmitApprovalRequest(
      processCode: CategoryCode.overtime,
      title: '加班申请',
      content: overtimeRequestJson,
    );

    // 调用 API 提交
    final response = await apiClient.submitApproval(submitRequest);

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
    });

    if (response.success) {
      await draftManager.clearDraft(CategoryCode.overtime);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('申请提交成功'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('申请提交失败：${response.message}'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                    const UserInfoCard(),
                    const SizedBox(height: 20),
                    _buildOvertimeFormCard(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              child: ActionButtonGroup(
                isLoading: _isSubmitting,
                onSave: _saveDraft,
                onSubmit: _submitForm,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 加班表单卡片 ───────────────────────────────────────────────────────

  Widget _buildOvertimeFormCard() {
    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('加班信息'),
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
            firstDate: DateTime.now().subtract(const Duration(days: 365)),
          ),

          const SizedBox(height: 20),

          // 加班原因
          Text(
            '加班原因',
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
}
