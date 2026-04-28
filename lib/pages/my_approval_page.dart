import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oa_fontend/models/constants/approval_enums.dart';
import 'package:oa_fontend/models/approval.dart';
import 'package:oa_fontend/models/constants/app_colors.dart';
import 'package:oa_fontend/utils/api_client.dart';
import 'package:oa_fontend/pages/widgets/approval_widgets.dart';

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
    if (!mounted) return;
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

  void _navigateToDetail(ApprovalProcessDetailResponse item) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => ApprovalDetailPage(item: item)),
    );
    // 如果审批操作成功，刷新列表
    if (result == true) {
      _loadPendingApprovals();
    }
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
            child: ApprovalFilterChip(
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
        StatusBadge(status: item.status, statusText: item.statusText),
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
              InfoItem(icon: Icons.person_outline, text: item.applicantName),
              const SizedBox(height: 4),
              InfoItem(
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

/// 审批详情页
class ApprovalDetailPage extends StatefulWidget {
  final ApprovalProcessDetailResponse item;

  const ApprovalDetailPage({super.key, required this.item});

  @override
  State<ApprovalDetailPage> createState() => _ApprovalDetailPageState();
}

class _ApprovalDetailPageState extends State<ApprovalDetailPage> {
  bool _isSubmitting = false;

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
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _showApprovalBottomSheet(ApprovalAction.reject),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.red.shade200),
              ),
            ),
            child: const Text(
              '拒绝',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _showApprovalBottomSheet(ApprovalAction.approve),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '通过',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  void _showApprovalBottomSheet(ApprovalAction action) {
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ApprovalBottomSheet(
        action: action,
        commentController: commentController,
        onSubmit: () => _handleApprovalSubmit(
          action: action,
          comment: commentController.text.trim(),
        ),
        isSubmitting: _isSubmitting,
      ),
    );
  }

  Future<void> _handleApprovalSubmit({
    required ApprovalAction action,
    required String comment,
  }) async {
    if (_isSubmitting) return;

    // 获取当前节点ID
    final currentNode = widget.item.nodes.firstWhere(
      (node) =>
          node.status == NodeStatus.pending ||
          node.status == NodeStatus.inProgress,
      orElse: () => widget.item.nodes.last,
    );

    setState(() => _isSubmitting = true);

    final request = ApprovalActionRequest(
      processInstanceId: widget.item.processInstanceId,
      nodeInstanceId: currentNode.nodeInstanceId,
      action: action,
      comment: comment.isEmpty ? null : comment,
    );

    final response = await apiClient.processApproval(request);

    if (!mounted) return;

    Navigator.pop(context); // 关闭底部弹窗
    setState(() => _isSubmitting = false);

    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(action == ApprovalAction.approve ? '审批通过成功' : '审批已拒绝'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // 返回列表页，刷新数据
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? '操作失败'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
              widget.item.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            DetailRow(label: '申请人', value: widget.item.applicantName),
            const SizedBox(height: 8),
            DetailRow(
              label: '部门',
              value: widget.item.applicantDepartment ?? '-',
            ),
            const SizedBox(height: 8),
            DetailRow(label: '状态', value: widget.item.statusText),
            const SizedBox(height: 8),
            DetailRow(
              label: '申请时间',
              value: _formatDateTime(widget.item.createdAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection() {
    if (widget.item.content == null || widget.item.content!.isEmpty) {
      return const SizedBox.shrink();
    }

    Map<String, dynamic>? contentMap;
    try {
      contentMap = json.decode(widget.item.content!) as Map<String, dynamic>;
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
              Text(widget.item.content!),
            ],
          ),
        ),
      );
    }
    final content = deserializeApprovalContent(
      widget.item.categoryCode,
      contentMap,
    );
    if (content == null) {
      return const SizedBox.shrink();
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
            ...content.contentRows.map((row) {
              final displayValue = _formatContentValue(row.$2);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: DetailRow(label: row.$1, value: displayValue),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatContentValue(dynamic value) {
    if (value == null) return '-';
    if (value is DateTime) return _formatDateTime(value);
    return value.toString();
  }

  Widget _buildNodeSection() {
    if (widget.item.nodes.isEmpty) return const SizedBox.shrink();

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
            ...widget.item.nodes.asMap().entries.map((entry) {
              final index = entry.key;
              final node = entry.value;
              return NodeCard(
                node: node,
                isFirst: index == 0,
                isLast: index == widget.item.nodes.length - 1,
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

/// 审批底部弹窗
class _ApprovalBottomSheet extends StatelessWidget {
  final ApprovalAction action;
  final TextEditingController commentController;
  final VoidCallback onSubmit;
  final bool isSubmitting;

  const _ApprovalBottomSheet({
    required this.action,
    required this.commentController,
    required this.onSubmit,
    required this.isSubmitting,
  });

  @override
  Widget build(BuildContext context) {
    final isApprove = action == ApprovalAction.approve;
    final actionColor = isApprove ? AppColors.primary : Colors.red;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 顶部指示条
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // 标题
              Text(
                isApprove ? '通过审批' : '拒绝审批',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // 审批意见输入框
              TextField(
                controller: commentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: '请输入审批意见（选填）',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: actionColor),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),
              // 提交按钮
              ElevatedButton(
                onPressed: isSubmitting ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: actionColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: actionColor.withAlpha(128),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        '确认${isApprove ? "通过" : "拒绝"}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
