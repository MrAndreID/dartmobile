/// The response envelope returned by the goapi service.
///
/// Every endpoint wraps its payload in `{code, description, data}`. This model
/// decodes that envelope and exposes the inner [data] for feature-level parsing.
class ApiResponse {
  const ApiResponse({
    required this.code,
    required this.description,
    required this.data,
  });

  final String code;
  final String description;
  final Object? data;

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      code: json['code']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      data: json['data'],
    );
  }

  /// goapi uses zero-padded HTTP status codes, e.g. `0200`, `0201`.
  bool get isSuccess {
    final numeric = int.tryParse(code) ?? 0;
    return numeric >= 200 && numeric < 300;
  }

  /// The `data` field cast to a JSON object, or null when it is not a map.
  Map<String, dynamic>? get dataAsMap =>
      data is Map<String, dynamic> ? data as Map<String, dynamic> : null;
}
