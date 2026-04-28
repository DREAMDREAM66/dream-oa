import 'package:flutter/material.dart';
import 'package:oa_fontend/models/constants/app_colors.dart';

/// 日期选择器
class DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onSelected;

  const DatePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return _PickerField(
      label: label,
      icon: Icons.calendar_today,
      displayText: value == null
          ? null
          : '${value!.year}-${_addZero(value!.month)}-${_addZero(value!.day)}',
      onTap: () => _selectDate(context),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime.now(),
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
    }
  }

  String _addZero(int num) => num.toString().padLeft(2, '0');
}

/// 时间选择器
class TimePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onSelected;

  const TimePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return _PickerField(
      label: label,
      icon: Icons.access_time,
      displayText: value == null
          ? null
          : '${_addZero(value!.hour)}:${_addZero(value!.minute)}',
      onTap: () => _selectTime(context),
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value ?? DateTime.now()),
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
      onSelected(
        DateTime(now.year, now.month, now.day, picked.hour, picked.minute),
      );
    }
  }

  String _addZero(int num) => num.toString().padLeft(2, '0');
}

/// 日期时间范围选择器（组合起始/结束日期和时间）
class DateTimeRangeField extends StatelessWidget {
  final String startDateLabel;
  final String startTimeLabel;
  final String endDateLabel;
  final String endTimeLabel;
  final DateTime? startDate;
  final DateTime? startTime;
  final DateTime? endDate;
  final DateTime? endTime;
  final void Function(DateTime? date, DateTime? time) onStartChanged;
  final void Function(DateTime? date, DateTime? time) onEndChanged;

  const DateTimeRangeField({
    super.key,
    required this.startDateLabel,
    required this.startTimeLabel,
    required this.endDateLabel,
    required this.endTimeLabel,
    required this.startDate,
    required this.startTime,
    required this.endDate,
    required this.endTime,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: '开始时间'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DatePickerField(
                label: startDateLabel,
                value: startDate,
                onSelected: (date) => onStartChanged(date, startTime),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TimePickerField(
                label: startTimeLabel,
                value: startTime,
                onSelected: (time) => onStartChanged(startDate, time),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _SectionLabel(label: '结束时间'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DatePickerField(
                label: endDateLabel,
                value: endDate,
                onSelected: (date) => onEndChanged(date, endTime),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TimePickerField(
                label: endTimeLabel,
                value: endTime,
                onSelected: (time) => onEndChanged(endDate, time),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 原因/备注输入框
class ReasonField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const ReasonField({
    super.key,
    required this.controller,
    this.hint = '请输入请假原因...',
    this.maxLines = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.neuBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.neuDivider, width: 1),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14, color: AppColors.neuTextPrimary),
        decoration: InputDecoration(
          hintText: hint,
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
}

// ─── 内部共用组件 ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        color: AppColors.neuTextSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? displayText;
  final VoidCallback onTap;

  const _PickerField({
    required this.label,
    required this.icon,
    required this.displayText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = displayText != null;
    return GestureDetector(
      onTap: onTap,
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
              icon,
              size: 16,
              color: hasValue ? AppColors.primary : AppColors.neuTextSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                displayText ?? label,
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
}
