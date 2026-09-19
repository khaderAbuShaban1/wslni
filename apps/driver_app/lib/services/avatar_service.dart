part of '../main.dart';

class _AvatarService {
  final _api = ApiClient();

  /// Uploads the photo and returns its stored path.
  Future<String> upload(File image) async {
    final client = _createHttpClient();
    try {
      final request = await client.postUrl(
        Uri.parse('${_api.baseUrl}/me/avatar'),
      );
      await _api._authorize(request);
      final boundary = '----wslni-${DateTime.now().microsecondsSinceEpoch}';
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.contentType = ContentType(
        'multipart',
        'form-data',
        parameters: {'boundary': boundary},
      );
      request.add(
        utf8.encode(
          '--$boundary\r\n'
          'Content-Disposition: form-data; name="avatar"; filename="${_filename(image)}"\r\n'
          'Content-Type: ${_contentType(image)}\r\n\r\n',
        ),
      );
      await request.addStream(image.openRead());
      request.add(utf8.encode('\r\n--$boundary--\r\n'));

      final response = await request.close();
      final decoded = _api._decode(
        await response.transform(utf8.decoder).join(),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          _api._message(decoded),
          response.statusCode,
          decoded,
        );
      }
      return decoded['avatar_path'].toString();
    } finally {
      client.close();
    }
  }

  Future<void> remove() => _api.delete('me/avatar');

  String _filename(File file) =>
      file.uri.pathSegments.isEmpty ? 'avatar.jpg' : file.uri.pathSegments.last;

  String _contentType(File file) {
    final path = file.path.toLowerCase();
    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
