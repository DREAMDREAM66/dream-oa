enum CategoryCode {
  leave(1), // 请假
  overtime(2), // 加班
  purchase(3), // 采购
  reimbursement(4); // 报销

  final int value;
  const CategoryCode(this.value);
}

enum ApprovalAction {
  submit(0), // 提交申请
  approve(1), // 批准
  reject(2), // 拒绝
  cancel(3), // 撤回
  delegate(4); // 委托

  final int value;
  const ApprovalAction(this.value);
}

enum ApprovalNodeType {
  single(1), // 单签
  allSign(2), // 会签
  anySign(3); // 或签

  final int value;
  const ApprovalNodeType(this.value);
}

enum ProcessStatus {
  pending(1), // 审批中
  approved(2), // 已通过
  rejected(3), // 已拒绝
  cancelled(4); //已撤回

  final int value;
  const ProcessStatus(this.value);
}

enum NodeStatus {
  pending(1), // 待审批
  inProgress(2), // 审批中
  approved(3), // 已通过
  rejected(4), // 已拒绝
  skipped(5); // 已跳过

  final int value;
  const NodeStatus(this.value);
}

enum LeaveType {
  annual(0), // 年假
  sick(1), // 病假
  compensatory(2), // 调休
  personal(3); // 事假

  final int value;
  const LeaveType(this.value);
}
