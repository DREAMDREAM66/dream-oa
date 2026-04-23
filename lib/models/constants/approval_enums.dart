enum CategoryCode {
  leave(1), // 请假
  overtime(2), // 加班
  purchase(3), // 采购
  reimbursement(4); // 报销

  final int value;
  const CategoryCode(this.value);

  static CategoryCode fromInt(int value) {
    return CategoryCode.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CategoryCode.leave,
    );
  }
}

enum ApprovalAction {
  submit(0), // 提交申请
  approve(1), // 批准
  reject(2), // 拒绝
  cancel(3), // 撤回
  delegate(4); // 委托

  final int value;
  const ApprovalAction(this.value);

  static ApprovalAction fromInt(int value) {
    return ApprovalAction.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ApprovalAction.submit,
    );
  }
}

enum ApprovalNodeType {
  single(1), // 单签
  allSign(2), // 会签
  anySign(3); // 或签

  final int value;
  const ApprovalNodeType(this.value);

  static ApprovalNodeType fromInt(int value) {
    return ApprovalNodeType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ApprovalNodeType.single,
    );
  }
}

enum ProcessStatus {
  pending(1), // 审批中
  approved(2), // 已通过
  rejected(3), // 已拒绝
  cancelled(4); //已撤回

  final int value;
  const ProcessStatus(this.value);

  static ProcessStatus fromInt(int value) {
    return ProcessStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ProcessStatus.pending,
    );
  }
}

enum NodeStatus {
  pending(1), // 待审批
  inProgress(2), // 审批中
  approved(3), // 已通过
  rejected(4), // 已拒绝
  skipped(5); // 已跳过

  final int value;
  const NodeStatus(this.value);

  static NodeStatus fromInt(int value) {
    return NodeStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NodeStatus.pending,
    );
  }
}

enum LeaveType {
  annual(0), // 年假
  sick(1), // 病假
  compensatory(2), // 调休
  personal(3); // 事假

  final int value;
  const LeaveType(this.value);

  static LeaveType fromInt(int value) {
    return LeaveType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => LeaveType.annual,
    );
  }

  String get desc {
    switch (this) {
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
}
