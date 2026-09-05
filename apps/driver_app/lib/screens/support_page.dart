part of '../main.dart';

class _DriverSupportPage extends StatelessWidget {
  const _DriverSupportPage();

  static final _supportCallUri = Uri(scheme: 'tel', path: '0599480926');
  static final _supportWhatsAppUri = Uri.https('wa.me', '/970599480926', {
    'text': 'مرحبًا، أنا سائق في تطبيق وصلني وأحتاج مساعدة.',
  });

  Future<void> _open(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح التطبيق المطلوب على هذا الجهاز.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('الدعم')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: _emerald.withValues(alpha: .16),
                        child: const Icon(
                          Icons.support_agent_rounded,
                          size: 34,
                          color: _emerald,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'كيف نقدر نساعدك؟',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'لأي مشكلة في الرحلات أو الأرباح أو الحساب، تواصل معنا مباشرة.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _muted, height: 1.5),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _open(context, _supportCallUri),
                          icon: const Icon(Icons.call_rounded),
                          label: const Text('اتصال بالدعم'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _open(context, _supportWhatsAppUri),
                          icon: const Icon(Icons.chat_rounded),
                          label: const Text('مراسلة الدعم عبر واتساب'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
