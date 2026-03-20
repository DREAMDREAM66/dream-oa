import 'package:flutter/material.dart';
import 'package:oa_fontend/models/constants/app_colors.dart';
import 'package:oa_fontend/models/constants/text_style.dart';
import 'package:oa_fontend/utils/user_manager.dart';
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
            colorScheme: ColorScheme.light(primary: AppColors.primary),
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
            colorScheme: ColorScheme.light(primary: AppColors.primary),
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
        const SnackBar(content: Text('请选择完整时间段', style: AppTextStyle.warning)),
      );
      return;
    }
    if (_reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写所有必填项', style: AppTextStyle.warning)),
      );
      return;
    }
    setState(() {
      _isSubmitting = true;
    });

    // TODO: 调用后端接口提交请假申请及保存数据
    final bool isSuccess = true; // 后端业务码
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      if (isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('申请提交成功'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('申请提交失败'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserInfoCard(),
          const SizedBox(height: 20),
          _buildLeaveForm(),
          const SizedBox(height: 30),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '申请人信息',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.business,
            label: '部门',
            value: userManager.department ?? '未知部门',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.person,
            label: '姓名',
            value: userManager.username ?? '未知用户',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.work,
            label: '职位',
            value: userManager.title ?? '未知职位',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label: ', style: AppTextStyle.middleTips),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '请假信息',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateTimeRow(
                  label: '开始日期',
                  value: _startDate,
                  icon: Icons.calendar_today,
                  onTap: () => _selectDate(_startDate, (date) {
                    setState(() => _startDate = date);
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateTimeRow(
                  label: '开始时间',
                  value: _startTime,
                  icon: Icons.access_time,
                  onTap: () => _selectTime(_startTime, (time) {
                    setState(() => _startTime = time);
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateTimeRow(
                  label: '结束日期',
                  value: _endDate,
                  icon: Icons.calendar_today,
                  onTap: () => _selectDate(_endDate, (date) {
                    setState(() => _endDate = date);
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateTimeRow(
                  label: '结束时间',
                  value: _endTime,
                  icon: Icons.access_time,
                  onTap: () => _selectTime(_endTime, (time) {
                    setState(() => _endTime = time);
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            '请假原因',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: '请输入请假原因...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeRow({
    required String label,
    required DateTime? value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value == null
                    ? label
                    : _formatDateTime(value, icon == Icons.calendar_today),
                style: TextStyle(
                  fontSize: 14,
                  color: value == null ? Colors.grey : Colors.black,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime, bool isDate) {
    if (isDate) {
      return '${dateTime.year}-${_addZero(dateTime.month)}-${_addZero(dateTime.day)}';
    } else {
      return '${_addZero(dateTime.hour)}:${_addZero(dateTime.minute)}';
    }
  }

  String _addZero(int num) {
    return num.toString().padLeft(2, '0');
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    '提交',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
          ),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitForm, // 以后换成保存
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    '保存',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
          ),
        ],
      ),
    );
  }
}
