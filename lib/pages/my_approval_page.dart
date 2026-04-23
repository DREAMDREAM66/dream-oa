import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oa_fontend/models/constants/approval_enums.dart';
import 'package:oa_fontend/models/approval.dart';
import 'package:oa_fontend/models/constants/app_colors.dart';
import 'package:oa_fontend/utils/api_client.dart';

/// 审批类型筛选
enum ApprovalFilter {
  all('全部', null),
  leave('请假', CategoryCode.leave),
  reimbursement('报销', CategoryCode.reimbursement),
  overtime('加班', CategoryCode.overtime);

  final String label;
  final CategoryCode? tag; // 用于匹配标题关键词
  const ApprovalFilter(this.label, this.tag);
}

/// 待审批列表页
class MyApprovalPage extends StatefulWidget {
  const MyApprovalPage({super.key});

  @override
  State<MyApprovalPage> createState() => _MyApprovalPageState();
}

class _MyApprovalPageState extends State<MyApprovalPage> {
  List<ApprovalProcessDetailResponse> _pendingList = [];
  bool _isLoading = true;
  String? _errorMessage;
  ApprovalFilter _currentFilter = ApprovalFilter.all;

  @override
  void initState() {
    super.initState();
    _loadPendingApprovals();
  }

  Future<void> _loadPendingApprovals() async {
    setState(() => _isLoading = true);

    final response = await apiClient.getMyPendingApprovals();

    setState(() {
      _isLoading = false;
      if (response.success && response.data != null) {
        _pendingList = response.data!;
      } else {
        _errorMessage = response.message ?? '获取待审批列表失败';
      }
    });
  }

  List<ApprovalProcessDetailResponse> get _filteredList {
    if (_currentFilter == ApprovalFilter.all) return _pendingList;
    return _pendingList.where((item) {
      return item.categoryCode == _currentFilter.tag;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: const Text('审批'),
        centerTitle: true,
        backgroundColor: AppColors.mainBackground,
        foregroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          _FilterChips(
            currentFilter: _currentFilter,
            onFilterChanged: (filter) {
              setState(() => _currentFilter = filter);
            },
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPendingApprovals,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('重新加载', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    final list = _filteredList;
    if (list.isEmpty) {
      return const Center(
        child: Text('暂无待审批项', style: TextStyle(color: Colors.grey)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingApprovals,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final item = list[index];
          return _ApprovalListItem(
            item: item,
            index: index,
            onTap: () => _navigateToDetail(item),
          );
        },
      ),
    );
  }

  void _navigateToDetail(ApprovalProcessDetailResponse item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ApprovalDetailPage(item: item)),
    );
  }
}

/// 筛选胶囊按钮栏
class _FilterChips extends StatelessWidget {
  final ApprovalFilter currentFilter;
  final ValueChanged<ApprovalFilter> onFilterChanged;

  const _FilterChips({
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: ApprovalFilter.values.map((filter) {
          final isSelected = filter == currentFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _FilterChip(
              label: filter.label,
              isSelected: isSelected,
              color: _getFilterColor(filter),
              onTap: () => onFilterChanged(filter),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getFilterColor(ApprovalFilter filter) {
    switch (filter) {
      case ApprovalFilter.all:
        return AppColors.primary;
      case ApprovalFilter.leave:
        return Colors.blue;
      case ApprovalFilter.reimbursement:
        return Colors.green;
      case ApprovalFilter.overtime:
        return Colors.orange;
    }
  }
}

/// 单个筛选胶囊
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      // 自动在状态前后之间画动画
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

/// 列表项卡片
class _ApprovalListItem extends StatelessWidget {
  final ApprovalProcessDetailResponse item;
  final int index;
  final VoidCallback onTap;

  const _ApprovalListItem({
    required this.item,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildContent(),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final (icon, iconBg) = _getTypeIconAndColor();
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBg.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconBg, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            item.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        _StatusBadge(status: item.status, statusText: item.statusText),
      ],
    );
  }

  Widget _buildContent() {
    final String time = DateFormat('MM-dd HH:mm').format(item.createdAt);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoItem(icon: Icons.person_outline, text: item.applicantName),
              const SizedBox(height: 4),
              _InfoItem(
                icon: Icons.business_outlined,
                text: item.applicantDepartment ?? '-',
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              time,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '查看详情',
                  style: TextStyle(color: AppColors.primary, fontSize: 13),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  (IconData, Color) _getTypeIconAndColor() {
    final title = item.categoryCode;
    if (title == CategoryCode.leave) {
      return (Icons.calendar_today, Colors.blue);
    } else if (title == CategoryCode.reimbursement) {
      return (Icons.payment, Colors.green);
    } else if (title == CategoryCode.overtime) {
      return (Icons.schedule, Colors.orange);
    }
    return (Icons.description, AppColors.primary);
  }
}

/// 信息行
class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoItem({required this.icon, required this.text});

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
class _StatusBadge extends StatelessWidget {
  final ProcessStatus status;
  final String statusText;

  const _StatusBadge({required this.status, required this.statusText});

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

/// 审批详情页
class ApprovalDetailPage extends StatelessWidget {
  final ApprovalProcessDetailResponse item;

  const ApprovalDetailPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '审批详情',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildContentSection(),
            const SizedBox(height: 16),
            _buildNodeSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _DetailRow(label: '申请人', value: item.applicantName),
            const SizedBox(height: 8),
            _DetailRow(label: '部门', value: item.applicantDepartment ?? '-'),
            const SizedBox(height: 8),
            _DetailRow(label: '状态', value: item.statusText),
            const SizedBox(height: 8),
            _DetailRow(label: '申请时间', value: _formatDateTime(item.createdAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection() {
    if (item.content == null || item.content!.isEmpty) {
      return const SizedBox.shrink();
    }

    Map<String, dynamic>? contentMap;
    try {
      contentMap = json.decode(item.content!) as Map<String, dynamic>;
    } catch (_) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '申请内容',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(item.content!),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '申请内容',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...contentMap.entries.map((entry) {
              final displayValue = _formatContentValue(entry.key, entry.value);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _DetailRow(
                  label: _getContentLabel(entry.key),
                  value: displayValue,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatContentValue(String key, dynamic value) {
    if (value == null) return '-';

    if (key.contains('Time')) {
      try {
        final dateTime = DateTime.parse(value.toString());
        return _formatDateTime(dateTime);
      } catch (_) {
        return value.toString();
      }
    }

    if (key == 'type') {
      if (value is int) {
        return LeaveType.values
            .firstWhere(
              (e) => e.value == value,
              orElse: () => LeaveType.personal,
            )
            .desc;
      }
    }

    return value.toString();
  }

  String _getContentLabel(String key) {
    const labels = {
      'startTime': '开始时间',
      'endTime': '结束时间',
      'reason': '原因',
      'type': '请假类型',
    };
    return labels[key] ?? key;
  }

  Widget _buildNodeSection() {
    if (item.nodes.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '审批节点',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            // ...展开列表
            ...item.nodes.asMap().entries.map((entry) {
              final index = entry.key;
              final node = entry.value;
              return _NodeCard(
                node: node,
                isFirst: index == 0,
                isLast: index == item.nodes.length - 1,
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

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

class _NodeCard extends StatelessWidget {
  final NodeInstanceDetailResponse node;
  final bool isFirst;
  final bool isLast;

  const _NodeCard({
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
          // 圆点
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
              _NodeStatusBadge(
                status: node.status,
                statusText: node.statusText,
              ),
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
                  _NodeInfoRow(
                    label: '激活',
                    value: _formatDateTime(node.activateAt!),
                  ),
                if (node.completedAt != null)
                  _NodeInfoRow(
                    label: '完成',
                    value: _formatDateTime(node.completedAt!),
                  ),
              ],
            ),
          ],
          if (node.approvers.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: node.approvers
                  .map(
                    (approver) => Container(
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
                  )
                  .toList(), // map返回迭代器Iterable，所以需要toList转为List<Widget>
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
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _NodeInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _NodeInfoRow({required this.label, required this.value});

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

class _NodeStatusBadge extends StatelessWidget {
  final NodeStatus status;
  final String statusText;

  const _NodeStatusBadge({required this.status, required this.statusText});

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
