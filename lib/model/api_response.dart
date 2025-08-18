class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final ApiPagination? pagination;
  final List<ApiError>? errors;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.pagination,
    this.errors,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic)? fromJsonT) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null ? fromJsonT(json['data']) : json['data'],
      pagination: json['pagination'] != null ? ApiPagination.fromJson(json['pagination']) : null,
      errors: json['errors'] != null 
          ? (json['errors'] as List).map((e) => ApiError.fromJson(e)).toList()
          : null,
    );
  }
}

class ApiPagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  ApiPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory ApiPagination.fromJson(Map<String, dynamic> json) {
    return ApiPagination(
      page: json['page'],
      limit: json['limit'],
      total: json['total'],
      totalPages: json['totalPages'],
      hasNext: json['hasNext'],
      hasPrev: json['hasPrev'],
    );
  }
}

class ApiError {
  final String field;
  final String message;
  final dynamic value;

  ApiError({
    required this.field,
    required this.message,
    this.value,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      field: json['field'],
      message: json['message'],
      value: json['value'],
    );
  }
}
