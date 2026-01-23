class QuQResponse<T> {
  final bool success;
  final T? data;
  final String? message;

  QuQResponse({required this.success, this.data, this.message});

  factory QuQResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    return QuQResponse<T>(
      success: json['success'] ?? false,
      data: json['data'] == null ? null : fromJsonT(json['data']),
      message: json['message'] ?? '',
    );
  }
}
