import 'dart:convert';
import 'dart:io';

const _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

String _resolveBaseUrl(String? baseUrl) {
  if (baseUrl != null && baseUrl.isNotEmpty) return baseUrl;
  if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
  return 'http://10.0.0.11:8000/api';
}

HttpClient _createHttpClient() {
  return HttpClient()..connectionTimeout = const Duration(seconds: 8);
}

class ApiException implements Exception {
  ApiException(this.message, this.statusCode, this.body);

  final String message;
  final int statusCode;
  final Map<String, dynamic> body;
}

class ApiClient {
  ApiClient({String? baseUrl}) : baseUrl = _resolveBaseUrl(baseUrl);

  final String baseUrl;

  Future<Map<String, dynamic>> get(String path) async {
    final client = _createHttpClient();
    final uri = Uri.parse('$baseUrl/$path');
    final request = await client.getUrl(uri);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');

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
    final uri = Uri.parse('$baseUrl/$path');
    final request = await client.getUrl(uri);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');

    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    client.close();

    final decoded = text.isEmpty ? null : jsonDecode(text);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{};
      throw ApiException(_message(body), response.statusCode, body);
    }
    if (decoded is List) return decoded;
    return const [];
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) {
    return _send('POST', path, body);
  }

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) {
    return _send('PATCH', path, body);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path,
    Map<String, dynamic> body,
  ) async {
    final client = _createHttpClient();
    final uri = Uri.parse('$baseUrl/$path');
    final request = method == 'PATCH'
        ? await client.patchUrl(uri)
        : await client.postUrl(uri);
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

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, String> fields,
    required String fileField,
    required File file,
  }) async {
    final client = _createHttpClient();
    final uri = Uri.parse('$baseUrl/$path');
    final request = await client.postUrl(uri);
    final boundary = '----wslni-${DateTime.now().microsecondsSinceEpoch}';
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.headers.contentType = ContentType(
      'multipart',
      'form-data',
      parameters: {'boundary': boundary},
    );

    for (final entry in fields.entries) {
      request.add(
        utf8.encode(
          '--$boundary\r\n'
          'Content-Disposition: form-data; name="${entry.key}"\r\n\r\n'
          '${entry.value}\r\n',
        ),
      );
    }

    final filename = file.uri.pathSegments.isEmpty
        ? 'receipt.jpg'
        : file.uri.pathSegments.last;
    request.add(
      utf8.encode(
        '--$boundary\r\n'
        'Content-Disposition: form-data; name="$fileField"; filename="$filename"\r\n'
        'Content-Type: ${_fileContentType(file)}\r\n\r\n',
      ),
    );
    await request.addStream(file.openRead());
    request.add(utf8.encode('\r\n--$boundary--\r\n'));

    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    client.close();
    final decoded = _decode(text);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_message(decoded), response.statusCode, decoded);
    }
    return decoded;
  }

  String _fileContentType(File file) {
    final path = file.path.toLowerCase();
    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
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
