part of '../main.dart';

enum _ResetStep { email, code, password }

/// Email → 6-digit code → new password.
class _ForgotPasswordPage extends StatefulWidget {
  const _ForgotPasswordPage({this.email = ''});

  final String email;

  @override
  State<_ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<_ForgotPasswordPage> {
  final _api = ApiClient();
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.email);
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  _ResetStep _step = _ResetStep.email;
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
      _show(error.message);
    } on SocketException {
      _show('تعذر الاتصال بالخادم. تحقق من الاتصال وحاول مجددًا.');
    } catch (_) {
      _show('حدث خطأ غير متوقع.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    await _run(() async {
      final result = await _api.post('auth/forgot-password', {
        'email': _email.text.trim(),
      });
      _show(result['message']?.toString() ?? '');
      _code.clear();
      if (!mounted) return;
      setState(() => _step = _ResetStep.code);
      _startResendCooldown();
    });
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;
    await _run(() async {
      final result = await _api.post('auth/forgot-password/verify', {
        'email': _email.text.trim(),
        'code': _code.text.trim(),
      });
      _resetToken = result['reset_token'].toString();
      if (mounted) setState(() => _step = _ResetStep.password);
    });
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    await _run(() async {
      final result = await _api.post('auth/reset-password', {
        'email': _email.text.trim(),
        'reset_token': _resetToken,
        'password': _password.text,
        'password_confirmation': _confirm.text,
      });
      _show(result['message']?.toString() ?? '');
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _show(String message) {
    if (!mounted || message.isEmpty) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final (title, subtitle) = switch (_step) {
      _ResetStep.email => (
        'نسيت كلمة المرور؟',
        'أدخل بريدك الإلكتروني وسنرسل لك رمز تحقق لإعادة تعيين كلمة المرور.',
      ),
      _ResetStep.code => (
        'أدخل رمز التحقق',
        'أرسلنا رمزًا من 6 أرقام إلى ${_email.text.trim()}. ينتهي خلال 10 دقائق.',
      ),
      _ResetStep.password => (
        'كلمة مرور جديدة',
        'اختر كلمة مرور جديدة من 8 أحرف على الأقل.',
      ),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('استعادة الحساب')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 6,
                      decoration: BoxDecoration(
                        color: i <= _step.index ? _emerald : _line,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  if (i < 2) const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 22),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(color: _muted, height: 1.5)),
            const SizedBox(height: 22),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _fields(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _fields() {
    switch (_step) {
      case _ResetStep.email:
        return [
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.email_outlined),
              labelText: 'البريد الإلكتروني',
            ),
            validator: (value) =>
                RegExp(
                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                ).hasMatch(value?.trim() ?? '')
                ? null
                : 'أدخل بريدًا إلكترونيًا صحيحًا',
            onFieldSubmitted: (_) => _sendCode(),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _loading ? null : _sendCode,
            icon: const Icon(Icons.send_rounded),
            label: Text(_loading ? 'جاري الإرسال...' : 'إرسال رمز التحقق'),
          ),
        ];
      case _ResetStep.code:
        return [
          TextFormField(
            controller: _code,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 8,
            ),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.pin_outlined),
              labelText: 'رمز التحقق',
            ),
            validator: (value) => RegExp(r'^\d{6}$').hasMatch(value ?? '')
                ? null
                : 'أدخل الرمز المكوّن من 6 أرقام',
            onFieldSubmitted: (_) => _verifyCode(),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loading ? null : _verifyCode,
            icon: const Icon(Icons.verified_rounded),
            label: Text(_loading ? 'جاري التحقق...' : 'تحقق من الرمز'),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _loading
                    ? null
                    : () => setState(() => _step = _ResetStep.email),
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
      case _ResetStep.password:
        return [
          _Field(
            controller: _password,
            label: 'كلمة المرور الجديدة',
            icon: Icons.lock_outline,
            obscure: true,
            validator: (value) => (value ?? '').length < 8
                ? 'كلمة المرور يجب أن تكون 8 أحرف على الأقل'
                : null,
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _confirm,
            label: 'تأكيد كلمة المرور',
            icon: Icons.lock_reset,
            obscure: true,
            validator: (value) =>
                value != _password.text ? 'كلمتا المرور غير متطابقتين' : null,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _loading ? null : _resetPassword,
            icon: const Icon(Icons.check_rounded),
            label: Text(_loading ? 'جاري الحفظ...' : 'حفظ كلمة المرور'),
          ),
        ];
    }
  }
}
