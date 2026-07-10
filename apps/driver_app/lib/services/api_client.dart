part of '../main.dart';

const _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

String _resolveBaseUrl(String? baseUrl) {
  if (baseUrl != null && baseUrl.isNotEmpty) return baseUrl;
  if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
  return 'http://10.0.0.11:8000/api';
}

HttpClient _createHttpClient() {
  return HttpClient()..connectionTimeout = const Duration(seconds: 8);
}

class ApiClient {
  ApiClient({String? baseUrl}) : baseUrl = _resolveBaseUrl(baseUrl);

  final String baseUrl;

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final client = _createHttpClient();
    final request = await client.postUrl(Uri.parse('$baseUrl/$path'));
    request.headers.contentType = ContentType.json;
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.write(jsonEncode(body));
    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    client.close();
    final decoded = _decode(text);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_message(decoded), response.statusCode, decoded);
    }

    return decoded;
  }

  Future<List<dynamic>> getList(String path) async {
    final client = _createHttpClient();
    final request = await client.getUrl(Uri.parse('$baseUrl/$path'));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    client.close();

    final decoded = jsonDecode(text);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('تعذر تحميل البيانات.', response.statusCode, {});
    }
    if (decoded is List) return decoded;
    return [];
  }

  Map<String, dynamic> _decode(String text) {
    if (text.isEmpty) return {};
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      return {'message': 'وصل رد غير متوقع من الخادم.'};
    }
    return {'message': 'وصل رد غير متوقع من الخادم.'};
  }

  String _message(Map<String, dynamic> decoded) {
    final errors = decoded['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
    }
    return decoded['message']?.toString() ?? 'حدث خطأ غير متوقع.';
  }
}

class ApiException implements Exception {
  ApiException(this.message, this.statusCode, this.body);

  final String message;
  final int statusCode;
  final Map<String, dynamic> body;
}
