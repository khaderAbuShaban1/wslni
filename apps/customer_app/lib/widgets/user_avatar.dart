import 'package:flutter/material.dart';

import '../utils/media_url.dart';

/// A profile photo that falls back to the name's first letter when the user
/// has no photo or it fails to load.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    required this.name,
    this.path,
    this.radius = 24,
    super.key,
  });

  final String name;
  final String? path;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = mediaUrl(path);
    final size = radius * 2;
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: scheme.primary.withValues(alpha: .15),
      child: Text(
        _initial,
        style: TextStyle(
          color: scheme.primary,
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

  String get _initial {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed.characters.first;
  }
}
