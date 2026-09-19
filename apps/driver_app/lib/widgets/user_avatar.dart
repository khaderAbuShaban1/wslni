part of '../main.dart';

/// The API sends storage paths (e.g. `avatars/7-x.jpg`) rather than full URLs,
/// so photos load from whichever server address this build talks to.
String? _mediaUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  final base = ApiClient().baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
  return '$base/storage/$path';
}

String? _nonEmpty(Object? value) {
  final text = value?.toString();
  return text == null || text.isEmpty ? null : text;
}

/// A profile photo that falls back to the name's first letter when the user
/// has no photo or it fails to load.
class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.name,
    this.path,
    this.radius = 24,
    this.fallbackColor,
  });

  final String name;
  final String? path;
  final double radius;
  final Color? fallbackColor;

  @override
  Widget build(BuildContext context) {
    final url = _mediaUrl(path);
    final size = radius * 2;
    final trimmed = name.trim();
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: fallbackColor ?? _emerald.withValues(alpha: .16),
      child: Text(
        trimmed.isEmpty ? '?' : trimmed.characters.first,
        style: TextStyle(
          color: _dark,
          fontWeight: FontWeight.w900,
          fontSize: radius * .8,
        ),
      ),
    );

    return ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: url == null
            ? fallback
            : Image.network(
                url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                // Decode at display size so a list of avatars stays light.
                cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                    .round(),
                errorBuilder: (_, _, _) => fallback,
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : fallback,
              ),
      ),
    );
  }
}
