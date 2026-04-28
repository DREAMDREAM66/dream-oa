import 'package:flutter/material.dart';
import 'package:oa_fontend/models/constants/app_colors.dart';

/// 操作按钮（保存/提交等）
class ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSecondary;
  final bool isLoading;
  final VoidCallback onTap;

  const ActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isSecondary,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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

/// 操作按钮组（保存 + 提交）
class ActionButtonGroup extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onSave;
  final VoidCallback onSubmit;

  const ActionButtonGroup({
    super.key,
    required this.isLoading,
    required this.onSave,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ActionButton(
            label: '保存',
            icon: Icons.bookmark_border,
            isSecondary: true,
            isLoading: isLoading,
            onTap: onSave,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: ActionButton(
            label: '提交',
            icon: Icons.send,
            isSecondary: false,
            isLoading: isLoading,
            onTap: onSubmit,
          ),
        ),
      ],
    );
  }
}
