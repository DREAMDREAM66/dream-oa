import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oa_fontend/models/constants/approval_enums.dart';
import 'package:oa_fontend/models/approval.dart';
import 'package:oa_fontend/models/constants/app_colors.dart';
import 'package:oa_fontend/utils/api_client.dart';
import 'package:oa_fontend/pages/widgets/approval_widgets.dart';

/// 申请状态筛选
enum ApplicationFilter {
  all('全部', null),
  pending('审批中', ProcessStatus.pending),
  approved('已通过', ProcessStatus.approved),
  rejected('已拒绝', ProcessStatus.rejected);

  final String label;
  final ProcessStatus? status;
  const ApplicationFilter(this.label, this.status);
}

/// 我的申请列表页
class MyApplicationPage extends StatefulWidget {
  const MyApplicationPage({super.key});

  @override
  State<MyApplicationPage> createState() => _MyApplicationPageState();
}

class _MyApplicationPageState extends State<MyApplicationPage> {
  List<ApprovalProcessDetailResponse> _applicationList = [];
  bool _isLoading = true;
  String? _errorMessage;
  ApplicationFilter _currentFilter = ApplicationFilter.all;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() => _isLoading = true);

    final response = await apiClient.getMyApplications();

    setState(() {
      _isLoading = false;
      if (response.success && response.data != null) {
        _applicationList = response.data!;
      } else {
        _errorMessage = response.message ?? '获取我的申请列表失败';
      }
    });
  }

  List<ApprovalProcessDetailResponse> get _filteredList {
    if (_currentFilter == ApplicationFilter.all) return _applicationList;
    return _applicationList.where((item) {
      return item.status == _currentFilter.status;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: const Text('我的申请'),
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
              onPressed: _loadApplications,
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
        child: Text('暂无申请记录', style: TextStyle(color: Colors.grey)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApplications,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final item = list[index];
          return _ApplicationListItem(
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
      MaterialPageRoute(
        builder: (context) => ApplicationDetailPage(item: item),
      ),
    );
  }
}

/// 筛选胶囊按钮栏
class _FilterChips extends StatelessWidget {
  final ApplicationFilter currentFilter;
  final ValueChanged<ApplicationFilter> onFilterChanged;

  const _FilterChips({
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: ApplicationFilter.values.map((filter) {
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

  Color _getFilterColor(ApplicationFilter filter) {
    switch (filter) {
      case ApplicationFilter.all:
        return AppColors.primary;
      case ApplicationFilter.pending:
        return Colors.orange;
      case ApplicationFilter.approved:
        return Colors.green;
      case ApplicationFilter.rejected:
        return Colors.red;
    }
  }
}

/// 列表项卡片
class _ApplicationListItem extends StatelessWidget {
  final ApprovalProcessDetailResponse item;
  final int index;
  final VoidCallback onTap;

  const _ApplicationListItem({
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

/// 申请详情页
class ApplicationDetailPage extends StatelessWidget {
  final ApprovalProcessDetailResponse item;

  const ApplicationDetailPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '申请详情',
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
            DetailRow(label: '申请人', value: item.applicantName),
            const SizedBox(height: 8),
            DetailRow(
              label: '部门',
              value: item.applicantDepartment ?? '-',
            ),
            const SizedBox(height: 8),
            DetailRow(label: '状态', value: item.statusText),
            const SizedBox(height: 8),
            DetailRow(
              label: '申请时间',
              value: _formatDateTime(item.createdAt),
            ),
            if (item.completedAt != null) ...[
              const SizedBox(height: 8),
              DetailRow(
                label: '完成时间',
                value: _formatDateTime(item.completedAt!),
              ),
            ],
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
    final content = deserializeApprovalContent(
      item.categoryCode,
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
            ...item.nodes.asMap().entries.map((entry) {
              final index = entry.key;
              final node = entry.value;
              return NodeCard(
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
