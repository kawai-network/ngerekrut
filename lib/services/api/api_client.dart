abstract class ApiClient {
  Future<Map<String, dynamic>> getJson(String path);

  Future<Map<String, dynamic>> postJson(
    String path, {
    Object? data,
  });

  Future<List<ApiListItem>> list({
    required String prefix,
    int limit = 100,
    String? cursor,
  });

  Future<Map<String, dynamic>> getJsonValue(String key);
}

class ApiListItem {
  final String name;
  final Map<String, dynamic>? metadata;

  const ApiListItem({
    required this.name,
    this.metadata,
  });
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  factory ApiException.fromDio(Object error) {
    try {
      final dynamic e = error;
      final response = e.response;
      final statusCode = response?.statusCode as int?;
      final data = response?.data;

      if (data is Map<String, dynamic>) {
        final message = data['error'] ?? data['message'];
        if (message is String && message.isNotEmpty) {
          return ApiException(message, statusCode: statusCode);
        }
      }

      final message = e.message;
      if (message is String && message.isNotEmpty) {
        return ApiException(message, statusCode: statusCode);
      }
    } catch (_) {
      // Fall through to generic error below.
    }

    return const ApiException('Request to recruiter API failed');
  }

  @override
  String toString() => message;
}
