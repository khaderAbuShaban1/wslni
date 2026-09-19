import '../services/api_client.dart';

/// The API sends storage paths (e.g. `avatars/7-x.jpg`) rather than full URLs,
/// so photos load from whichever server address this build talks to.
String? mediaUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  final base = ApiClient().baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
  return '$base/storage/$path';
}
