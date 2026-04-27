import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oa_fontend/models/constants/app_colors.dart';
import 'package:oa_fontend/models/constants/approval_enums.dart';
import 'package:oa_fontend/models/approval.dart';

/// 信息行
class InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const InfoItem({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// 状态标签
class StatusBadge extends StatelessWidget {
  final ProcessStatus status;
  final String statusText;

  const StatusBadge({
    super.key,
    required this.status,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    final (bgColor, textColor) = _getStatusColors();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: textColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(statusText, style: TextStyle(color: textColor, fontSize: 12)),
        ],
      ),
    );
  }

  (Color, Color) _getStatusColors() {
    switch (status) {
      case ProcessStatus.pending:
        return (Colors.orange, Colors.orange.shade700);
      case ProcessStatus.approved:
        return (Colors.green, Colors.green.shade700);
      case ProcessStatus.rejected:
        return (Colors.red, Colors.red.shade700);
      case ProcessStatus.cancelled:
        return (Colors.grey, Colors.grey.shade700);
    }
  }
}

/// 节点状态标签
class NodeStatusBadge extends StatelessWidget {
  final NodeStatus status;
  final String statusText;

  const NodeStatusBadge({
    super.key,
    required this.status,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    final (bgColor, textColor) = _getStatusColors();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(statusText, style: TextStyle(color: textColor, fontSize: 11)),
    );
  }

  (Color, Color) _getStatusColors() {
    switch (status) {
      case NodeStatus.pending:
        return (Colors.grey, Colors.grey.shade700);
      case NodeStatus.inProgress:
        return (Colors.blue, Colors.blue.shade700);
      case NodeStatus.approved:
        return (Colors.green, Colors.green.shade700);
      case NodeStatus.rejected:
        return (Colors.red, Colors.red.shade700);
      case NodeStatus.skipped:
        return (Colors.grey, Colors.grey.shade600);
    }
  }
}

/// 节点信息行
class NodeInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const NodeInfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.grey, fontSize: 11),
        ),
        Text(value, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

/// 详情行
class DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const DetailRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value),
      ],
    );
  }
}

/// 筛选胶囊
class ApprovalFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const ApprovalFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      // 自动绘制前后状态切换的动画
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withAlpha(25),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

/// 节点卡片
class NodeCard extends StatelessWidget {
  final NodeInstanceDetailResponse node;
  final bool isFirst;
  final bool isLast;

  const NodeCard({
    super.key,
    required this.node,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTimeline(),
          const SizedBox(width: 10),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final (dotColor, isCompleted) = _getNodeStatus();

    return SizedBox(
      width: 20,
      child: Column(
        children: [
          // 上半段连接线
          Expanded(
            child: Container(
              width: 1.5,
              color: isFirst
                  ? Colors.transparent
                  : (isCompleted ? AppColors.primary : Colors.grey.shade300),
            ),
          ),
          // 小图标
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isCompleted ? dotColor : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: dotColor, width: 1.5),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : Icon(Icons.access_time, size: 10, color: dotColor),
            ),
          ),
          // 下半段连接线
          Expanded(
            child: Container(
              width: 1.5,
              color: isLast
                  ? Colors.transparent
                  : (isCompleted ? AppColors.primary : Colors.grey.shade300),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                node.nodeName,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              NodeStatusBadge(status: node.status, statusText: node.statusText),
            ],
          ),
          // if判断如果套了多个组件，要...展开
          if (node.activateAt != null || node.completedAt != null) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 2,
              children: [
                if (node.activateAt != null)
                  NodeInfoRow(
                    label: '激活',
                    value: _formatDateTime(node.activateAt!),
                  ),
                if (node.completedAt != null)
                  NodeInfoRow(
                    label: '完成',
                    value: _formatDateTime(node.completedAt!),
                  ),
              ],
            ),
          ],
          if (node.approvers.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...node.approvers.map(
              (approver) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(13),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        approver.approverName,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                    if (approver.comment != null &&
                        approver.comment!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '"${approver.comment}"',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  (Color, bool) _getNodeStatus() {
    switch (node.status) {
      case NodeStatus.approved:
      case NodeStatus.skipped:
        return (AppColors.primary, true);
      case NodeStatus.pending:
      case NodeStatus.inProgress:
        return (Colors.grey, false);
      case NodeStatus.rejected:
        return (Colors.red, true);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }
}
