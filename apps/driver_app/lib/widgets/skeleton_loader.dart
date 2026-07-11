part of '../main.dart';

class _SkeletonList extends StatefulWidget {
  const _SkeletonList();

  @override
  State<_SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<_SkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final color = Color.lerp(
          scheme.surfaceContainerLow,
          scheme.surfaceContainerHighest,
          _controller.value,
        )!;
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: 3,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (_, _) => Container(
            height: 150,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        );
      },
    );
  }
}
