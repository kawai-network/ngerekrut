import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import 'api_client.dart';
import '../supabase_log_service.dart';

class CloudflareKvApiClient implements ApiClient {
  final Dio _dio;
  final String _accountId;
  final String _namespaceId;

  CloudflareKvApiClient({
    required String accountId,
    required String namespaceId,
    required String apiToken,
    Dio? dio,
  }) : _accountId = accountId,
       _namespaceId = namespaceId,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: 'https://api.cloudflare.com/client/v4',
               connectTimeout: const Duration(seconds: 10),
               receiveTimeout: const Duration(seconds: 20),
               headers: {'authorization': 'Bearer $apiToken'},
             ),
           );

  String get _namespaceBase =>
      '/accounts/$_accountId/storage/kv/namespaces/$_namespaceId';

  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(path);
      return _unwrapEnvelope(response.data ?? const {});
    } on DioException catch (e) {
      unawaited(
        SupabaseLogService.instance.reportError(
          eventType: 'cloudflare_kv_get_failed',
          error: ApiException.fromDio(e),
          stackTrace: e.stackTrace,
          metadata: _dioErrorMetadata(method: 'GET', path: path, error: e),
        ),
      );
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? data}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: data);
      return _unwrapEnvelope(response.data ?? const {});
    } on DioException catch (e) {
      unawaited(
        SupabaseLogService.instance.reportError(
          eventType: 'cloudflare_kv_post_failed',
          error: ApiException.fromDio(e),
          stackTrace: e.stackTrace,
          metadata: _dioErrorMetadata(
            method: 'POST',
            path: path,
            error: e,
            requestBody: data,
          ),
        ),
      );
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<List<ApiListItem>> list({
    required String prefix,
    int limit = 100,
    String? cursor,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_namespaceBase/keys',
        queryParameters: {
          'prefix': prefix,
          'limit': limit,
          if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        },
      );

      final data = response.data ?? const {};
      final result = data['result'] as List<dynamic>? ?? const [];
      return result
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => ApiListItem(
              name: item['name'] as String,
              metadata: item['metadata'] as Map<String, dynamic>?,
            ),
          )
          .toList();
    } on DioException catch (e) {
      unawaited(
        SupabaseLogService.instance.reportError(
          eventType: 'cloudflare_kv_list_failed',
          error: ApiException.fromDio(e),
          stackTrace: e.stackTrace,
          metadata: _dioErrorMetadata(
            method: 'GET',
            path: '$_namespaceBase/keys',
            error: e,
            requestBody: {'prefix': prefix, 'limit': limit, 'cursor': cursor},
          ),
        ),
      );
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getJsonValue(String key) async {
    try {
      final response = await _dio.get<String>(
        '$_namespaceBase/values/${Uri.encodeComponent(key)}',
        options: Options(responseType: ResponseType.plain),
      );
      final body = response.data;
      if (body == null || body.isEmpty) {
        throw const ApiException('Cloudflare KV returned empty value');
      }
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw const ApiException('Cloudflare KV value is not a JSON object');
    } on DioException catch (e) {
      unawaited(
        SupabaseLogService.instance.reportError(
          eventType: 'cloudflare_kv_value_failed',
          error: ApiException.fromDio(e),
          stackTrace: e.stackTrace,
          metadata: _dioErrorMetadata(
            method: 'GET',
            path: '$_namespaceBase/values/${Uri.encodeComponent(key)}',
            error: e,
          ),
        ),
      );
      throw ApiException.fromDio(e);
    } on FormatException catch (e) {
      throw ApiException('Failed to parse Cloudflare KV JSON: $e');
    }
  }

  Map<String, dynamic> _dioErrorMetadata({
    required String method,
    required String path,
    required DioException error,
    Object? requestBody,
  }) {
    return {
      'provider': 'cloudflare_kv',
      'method': method,
      'path': path,
      'status_code': error.response?.statusCode,
      'dio_type': error.type.name,
      'request_body': requestBody,
      'response_data': error.response?.data,
    };
  }

  Map<String, dynamic> _unwrapEnvelope(Map<String, dynamic> data) {
    final success = data['success'];
    if (success == false) {
      final errors = data['errors'];
      if (errors is List && errors.isNotEmpty) {
        final first = errors.first;
        if (first is Map<String, dynamic>) {
          final message = first['message'];
          if (message is String && message.isNotEmpty) {
            throw ApiException(message);
          }
        }
      }
      throw const ApiException('Cloudflare API request failed');
    }
    final result = data['result'];
    if (result is Map<String, dynamic>) {
      return result;
    }
    return data;
  }
}
