import './constants/approval_enums.dart';

class SubmitApprovalRequest {
  final CategoryCode processCode;
  final String title;
  final String content;

  SubmitApprovalRequest({
    required this.processCode,
    required this.title,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
        'processCode': processCode.value,
        'title': title,
        'content': content,
      };
}

class ApprovalActionRequest {
  final String processInstanceId;
  final String nodeInstanceId;
  final ApprovalAction action;
  final String? comment;
  final int? delegateToUserId;

  ApprovalActionRequest({
    required this.processInstanceId,
    required this.nodeInstanceId,
    required this.action,
    this.comment,
    this.delegateToUserId,
  });
}

class ApproverDetailResponse {
  final int approverId;
  final String approverName;
  final String? approverTitle;
  final NodeStatus status;
  final String? comment;
  final DateTime? actionAt;

  ApproverDetailResponse({
    required this.approverId,
    required this.approverName,
    this.approverTitle,
    required this.status,
    this.comment,
    this.actionAt,
  });

  factory ApproverDetailResponse.fromJson(Map<String, dynamic> json) {
    final DateTime time = DateTime.parse(json['actionAt']);
    return ApproverDetailResponse(
      approverId: json['approverId'] ?? 0,
      approverName: json['approverName'] ?? '',
      approverTitle: json['approverTitle'],
      status: json['status'] ?? '',
      comment: json['comment'],
      actionAt: time,
    );
  }
}

class NodeInstanceDetailResponse {
  final String nodeInstanceId;
  final int nodeOrder;
  final String nodeName;
  final ApprovalNodeType nodeType;
  final NodeStatus status;
  final String statusText;
  final DateTime? activateAt;
  final DateTime? completedAt;
  final List<ApproverDetailResponse> approvers;

  NodeInstanceDetailResponse({
    required this.nodeInstanceId,
    required this.nodeOrder,
    required this.nodeName,
    required this.nodeType,
    required this.status,
    required this.statusText,
    this.activateAt,
    this.completedAt,
    required this.approvers,
  });

  factory NodeInstanceDetailResponse.fromJson(Map<String, dynamic> json) {
    final DateTime aAt = DateTime.parse(json['activateAt']);
    final DateTime cAt = DateTime.parse(json['completedAt']);
    final List<dynamic> dataList = json['approvers'] ?? [];
    final List<ApproverDetailResponse> approversList = dataList
        .map((a) => ApproverDetailResponse.fromJson(a))
        .toList();
    return NodeInstanceDetailResponse(
      nodeInstanceId: json['nodeInstanceId'] ?? '',
      nodeOrder: json['nodeOrder'] ?? 0,
      nodeName: json['nodeName'] ?? '',
      nodeType: json['nodeType'] ?? '',
      status: json['status'] ?? '',
      statusText: json['statusText'] ?? '',
      activateAt: aAt,
      completedAt: cAt,
      approvers: approversList,
    );
  }
}

class ApprovalProcessDetailResponse {
  final String processInstanceId;
  final String title;
  final String? content;
  final ProcessStatus status;
  final String statusText;
  final String applicantName;
  final String? applicantDepartment;
  final DateTime createdAt;
  final DateTime? completedAt;
  final List<NodeInstanceDetailResponse> nodes;

  ApprovalProcessDetailResponse({
    required this.processInstanceId,
    required this.title,
    this.content,
    required this.status,
    required this.statusText,
    required this.applicantName,
    this.applicantDepartment,
    required this.createdAt,
    this.completedAt,
    required this.nodes,
  });

  factory ApprovalProcessDetailResponse.fromJson(Map<String, dynamic> json) {
    final createdTime = DateTime.parse(json['createdAt']);
    final completedTime = DateTime.parse(json['completedAt']);
    final List<dynamic> dataList = json['nodes'] ?? [];
    final List<NodeInstanceDetailResponse> nodesList = dataList
        .map((a) => NodeInstanceDetailResponse.fromJson(a))
        .toList();
    return ApprovalProcessDetailResponse(
      processInstanceId: json['processInstanceId'] ?? '',
      title: json['title'] ?? '',
      status: json['status'] ?? '',
      statusText: json['statusText'] ?? '',
      applicantName: json['applicantName'] ?? '',
      applicantDepartment: json['applicantDepartment'],
      createdAt: createdTime,
      completedAt: completedTime,
      nodes: nodesList,
    );
  }
}

// -----------------------------------------
// 请假

class LeaveRequest {
  final DateTime startTime;
  final DateTime endTime;
  final String reason;
  final LeaveType type;

  LeaveRequest({
    required this.startTime,
    required this.endTime,
    required this.reason,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'reason': reason,
        'type': type.value,
      };
}
