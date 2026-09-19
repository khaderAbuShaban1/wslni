import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/premium_card.dart';

enum _Step { email, code, password }

/// Email → 6-digit code → new password.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({this.email = '', super.key});

  final String email;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.email);
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  _Step _step = _Step.email;
  bool _loading = false;
  String _resetToken = '';
  int _resendIn = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendIn = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _resendIn--);
      if (_resendIn <= 0) timer.cancel();
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
    } on ApiException catch (error) {
      _message(error.message);
    } on SocketException {
      _message('تعذر الاتصال بالخادم. تحقق من الاتصال وحاول مجددًا.');
    } catch (_) {
      _message('حدث خطأ غير متوقع.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    await _run(() async {
      final message = await _auth.requestPasswordReset(_email.text.trim());
      if (!mounted) return;
      _message(message);
      _code.clear();
      setState(() => _step = _Step.code);
      _startResendCooldown();
    });
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;
    await _run(() async {
      _resetToken = await _auth.verifyResetCode(
        email: _email.text.trim(),
        code: _code.text.trim(),
      );
      if (mounted) setState(() => _step = _Step.password);
    });
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    await _run(() async {
      final message = await _auth.resetPassword(
        email: _email.text.trim(),
        resetToken: _resetToken,
        password: _password.text,
        passwordConfirmation: _confirm.text,
      );
      if (!mounted) return;
      _message(message);
      Navigator.of(context).pop();
    });
  }

  void _message(String text) {
    if (!mounted || text.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final (title, subtitle) = switch (_step) {
      _Step.email => (
        'نسيت كلمة المرور؟',
        'أدخل بريدك الإلكتروني وسنرسل لك رمز تحقق لإعادة تعيين كلمة المرور.',
      ),
      _Step.code => (
        'أدخل رمز التحقق',
        'أرسلنا رمزًا من 6 أرقام إلى ${_email.text.trim()}. ينتهي خلال 10 دقائق.',
      ),
      _Step.password => (
        'كلمة مرور جديدة',
        'اختر كلمة مرور جديدة من 8 أحرف على الأقل.',
      ),
    };

    return AppScaffold(
      title: 'استعادة الحساب',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepIndicator(current: _step.index),
          const SizedBox(height: 22),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: mutedText, height: 1.5)),
          const SizedBox(height: 22),
          PremiumCard(
            child: Form(
              key: _formKey,
              child: Column(children: _fields()),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _fields() {
    switch (_step) {
      case _Step.email:
        return [
          CustomTextField(
            controller: _email,
            label: 'البريد الإلكتروني',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: emailValidator,
            onSubmitted: (_) => _sendCode(),
          ),
          const SizedBox(height: 18),
          CustomButton(
            label: _loading ? 'جاري الإرسال...' : 'إرسال رمز التحقق',
            icon: Icons.send_rounded,
            onPressed: _loading ? null : _sendCode,
          ),
        ];
      case _Step.code:
        return [
          CustomTextField(
            controller: _code,
            label: 'رمز التحقق',
            icon: Icons.pin_outlined,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 8,
            ),
            validator: (value) => RegExp(r'^\d{6}$').hasMatch(value ?? '')
                ? null
                : 'أدخل الرمز المكوّن من 6 أرقام',
            onSubmitted: (_) => _verifyCode(),
          ),
          const SizedBox(height: 12),
          CustomButton(
            label: _loading ? 'جاري التحقق...' : 'تحقق من الرمز',
            icon: Icons.verified_rounded,
            onPressed: _loading ? null : _verifyCode,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _loading
                    ? null
                    : () => setState(() => _step = _Step.email),
                child: const Text('تغيير البريد'),
              ),
              TextButton(
                onPressed: _loading || _resendIn > 0 ? null : _sendCode,
                child: Text(
                  _resendIn > 0
                      ? 'إعادة الإرسال بعد $_resendIn ث'
                      : 'إعادة إرسال الرمز',
                ),
              ),
            ],
          ),
        ];
      case _Step.password:
        return [
          CustomTextField(
            controller: _password,
            label: 'كلمة المرور الجديدة',
            icon: Icons.lock_outline_rounded,
            obscureText: true,
            validator: (value) => (value ?? '').length < 8
                ? 'كلمة المرور يجب أن تكون 8 أحرف على الأقل'
                : null,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _confirm,
            label: 'تأكيد كلمة المرور',
            icon: Icons.lock_reset_rounded,
            obscureText: true,
            validator: (value) =>
                value != _password.text ? 'كلمتا المرور غير متطابقتين' : null,
            onSubmitted: (_) => _resetPassword(),
          ),
          const SizedBox(height: 18),
          CustomButton(
            label: _loading ? 'جاري الحفظ...' : 'حفظ كلمة المرور',
            icon: Icons.check_rounded,
            onPressed: _loading ? null : _resetPassword,
          ),
        ];
    }
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 6,
              decoration: BoxDecoration(
                color: i <= current ? emerald : scheme.outlineVariant,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          if (i < 2) const SizedBox(width: 8),
        ],
      ],
    );
  }
}
