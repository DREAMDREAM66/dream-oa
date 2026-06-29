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

class CorrectCheckinPage extends FeaturePage {
  const CorrectCheckinPage({
    super.key,
    required super.title,
    required super.functionKey,
  });

  @override
  Widget buildContent(BuildContext context) {
    return const CorrectCheckinPageContent();
  }
}

class CorrectCheckinPageContent extends StatefulWidget {
  const CorrectCheckinPageContent({super.key});

  @override
  State<CorrectCheckinPageContent> createState() => _CorrectCheckinPageContentState();
}

class _CorrectCheckinPageContentState extends State<CorrectCheckinPageContent> {
  final _reasonController = TextEditingController();

  DateTime? _checkinDate;
  DateTime? _checkinTime;

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
    final draft = await draftManager.loadDraft<CorrectCheckinDraft>(
      CategoryCode.correctCheckin,
    );
    if (draft != null && mounted) {
      setState(() {
        _checkinDate = draft.checkinDate;
        _checkinTime = draft.checkinTime;
        _reasonController.text = draft.reason;
      });
    }
  }

  Future<void> _saveDraft() async {
    final draft = CorrectCheckinDraft(
      checkinDate: _checkinDate,
      checkinTime: _checkinTime,
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

  void _onDateChanged(DateTime? date) {
    setState(() {
      _checkinDate = date;
    });
  }

  void _onTimeChanged(DateTime? time) {
    setState(() {
      _checkinTime = time;
    });
  }

  Future<void> _submitForm() async {
    if (_checkinDate == null || _checkinTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('请选择补卡日期和时间', style: AppTextStyle.warning),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }
    if (_reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('请填写补卡原因', style: AppTextStyle.warning),
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
    final checkinDateTime = DateTime(
      _checkinDate!.year,
      _checkinDate!.month,
      _checkinDate!.day,
      _checkinTime!.hour,
      _checkinTime!.minute,
    );

    // 构建 CorrectCheckinRequest
    final correctCheckinRequest = CorrectCheckinRequest(
      checkinTime: checkinDateTime,
      reason: _reasonController.text,
    );

    // 序列化为 JSON 放入 content
    final correctCheckinRequestJson = json.encode(correctCheckinRequest.toJson());

    // 构建 SubmitApprovalRequest
    final submitRequest = SubmitApprovalRequest(
      processCode: CategoryCode.correctCheckin,
      title: '补卡申请',
      content: correctCheckinRequestJson,
    );

    // 调用 API 提交
    final response = await apiClient.submitApproval(submitRequest);

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
    });

    if (response.success) {
      await draftManager.clearDraft(CategoryCode.correctCheckin);
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
                    _buildCorrectCheckinFormCard(),
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

  // ─── 补卡表单卡片 ───────────────────────────────────────────────────────

  Widget _buildCorrectCheckinFormCard() {
    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('补卡信息'),
          const SizedBox(height: 20),

          // 补卡日期
          Text(
            '补卡日期',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.neuTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          DatePickerField(
            label: '请选择补卡日期',
            value: _checkinDate,
            onSelected: _onDateChanged,
            firstDate: DateTime.now().subtract(const Duration(days: 365)),
          ),
          const SizedBox(height: 20),

          // 补卡时间
          Text(
            '补卡时间',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.neuTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TimePickerField(
            label: '请选择补卡时间',
            value: _checkinTime,
            onSelected: _onTimeChanged,
          ),

          const SizedBox(height: 20),

          // 补卡原因
          Text(
            '补卡原因',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.neuTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ReasonField(
            controller: _reasonController,
            hint: '请输入补卡原因...',
          ),
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