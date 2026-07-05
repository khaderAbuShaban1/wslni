import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../widgets/app_logo.dart';
import '../widgets/custom_button.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  final _items = const [
    _OnboardingItem(
      icon: Icons.search_rounded,
      title: 'اختار وجهتك بسهولة',
      subtitle: 'واجهة نظيفة تركز على العنوان والوجهة بدون أي خرائط أو تشتيت.',
    ),
    _OnboardingItem(
      icon: Icons.local_taxi_rounded,
      title: 'السائقون يقدمون عروضهم',
      subtitle: 'قارن الأسعار واختر الرحلة المناسبة لك بتجربة راقية.',
    ),
    _OnboardingItem(
      icon: Icons.verified_user_rounded,
      title: 'رحلة آمنة وواضحة',
      subtitle: 'تابع تقدم الرحلة، ادفع، وقيّم السائق من شاشات بسيطة ومريحة.',
    ),
  ];

  void _openAuth() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _next() {
    if (_page == _items.length - 1) {
      _openAuth();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  const AppLogo(size: 44),
                  const SizedBox(width: 10),
                  Text(
                    'وصلني',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  TextButton(onPressed: _openAuth, child: const Text('تخطي')),
                ],
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _items.length,
                  onPageChanged: (value) => setState(() => _page = value),
                  itemBuilder: (_, index) =>
                      _OnboardingPanel(item: _items[index]),
                ),
              ),
              Row(
                children: [
                  Row(
                    children: List.generate(
                      _items.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: _page == index ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsetsDirectional.only(end: 7),
                        decoration: BoxDecoration(
                          color: _page == index ? emerald : borderGray,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  CustomButton(
                    label: _page == _items.length - 1 ? 'ابدأ الآن' : 'التالي',
                    icon: Icons.arrow_back_rounded,
                    onPressed: _next,
                    width: 150,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingItem {
  const _OnboardingItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

class _OnboardingPanel extends StatelessWidget {
  const _OnboardingPanel({required this.item});

  final _OnboardingItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            color: lightGray,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Icon(item.icon, size: 92, color: emerald),
        ),
        const SizedBox(height: 38),
        Text(
          item.title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          item.subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: mutedText, height: 1.65),
        ),
      ],
    );
  }
}
