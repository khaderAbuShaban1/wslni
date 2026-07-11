import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.title,
    required this.child,
    this.showBack = true,
    this.trailing,
    super.key,
  });

  final String title;
  final Widget child;
  final bool showBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 32),
              children: [
                Row(
                  children: [
                    if (showBack)
                      IconButton.filledTonal(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_forward_rounded),
                      ),
                    if (showBack) const SizedBox(width: 10),
                    Expanded(
                      child: Text(title, style: theme.textTheme.headlineSmall),
                    ),
                    ?trailing,
                  ],
                ),
                const SizedBox(height: 22),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
