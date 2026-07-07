part of '../main.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _api = ApiClient();
  final _loginKey = GlobalKey<FormState>();
  final _registerKey = GlobalKey<FormState>();
  final _otpKey = GlobalKey<FormState>();

  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _license = TextEditingController();
  final _vehicleType = TextEditingController();
  final _vehiclePlate = TextEditingController();
  final _otp = TextEditingController();

  bool _register = false;
  bool _otpMode = false;
  bool _loading = false;
  String? _pendingEmail;

  @override
  void dispose() {
    _loginEmail.dispose();
    _loginPassword.dispose();
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _license.dispose();
    _vehicleType.dispose();
    _vehiclePlate.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_loginKey.currentState!.validate()) return;
    await _run(() async {
      final result = await _api.post('auth/login', {
        'email': _loginEmail.text.trim(),
        'password': _loginPassword.text,
      });
      final user = DriverUser.fromJson(result['user'] as Map<String, dynamic>);
      if (user.id == 0) throw ApiException('بيانات السائق غير صحيحة.', 422, {});
      _openHome(user);
    });
  }

  Future<void> _registerDriver() async {
    if (!_registerKey.currentState!.validate()) return;
    await _run(() async {
      await _api.post('auth/driver/register', {
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'password': _password.text,
        'password_confirmation': _confirmPassword.text,
        'license_number': _license.text.trim(),
        'vehicle_type': _vehicleType.text.trim(),
        'vehicle_plate': _vehiclePlate.text.trim(),
      });
      setState(() {
        _pendingEmail = _email.text.trim();
        _otpMode = true;
      });
      _show('تم إرسال رمز التحقق إلى البريد الإلكتروني');
    });
  }

  Future<void> _verifyOtp() async {
    if (!_otpKey.currentState!.validate()) return;
    await _run(() async {
      final result = await _api.post('auth/verify-otp', {
        'email': _pendingEmail,
        'otp': _otp.text.trim(),
      });
      _openHome(DriverUser.fromJson(result['user'] as Map<String, dynamic>));
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
    } on ApiException catch (error) {
      if (error.statusCode == 403 && error.body['requires_otp'] == true) {
        setState(() {
          _pendingEmail = error.body['email']?.toString() ?? _loginEmail.text;
          _otpMode = true;
          _register = false;
        });
      }
      _show(error.message);
    } on SocketException {
      _show('تعذر الاتصال بالخادم. تأكد أن Laravel يعمل على المنفذ 8000.');
    } catch (_) {
      _show('حدث خطأ غير متوقع.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openHome(DriverUser user) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => DriverHomePage(user: user)),
    );
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.local_taxi, size: 56),
            const SizedBox(height: 12),
            Text(
              _otpMode
                  ? 'تحقق من البريد'
                  : _register
                  ? 'إنشاء حساب سائق'
                  : 'تسجيل دخول السائق',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            if (_otpMode)
              _OtpForm(
                formKey: _otpKey,
                email: _pendingEmail ?? '',
                otp: _otp,
                loading: _loading,
                onVerify: _verifyOtp,
                onBack: () => setState(() => _otpMode = false),
              )
            else if (_register)
              _RegisterForm(
                formKey: _registerKey,
                name: _name,
                email: _email,
                phone: _phone,
                password: _password,
                confirmPassword: _confirmPassword,
                license: _license,
                vehicleType: _vehicleType,
                vehiclePlate: _vehiclePlate,
                loading: _loading,
                onSubmit: _registerDriver,
              )
            else
              _LoginForm(
                formKey: _loginKey,
                email: _loginEmail,
                password: _loginPassword,
                loading: _loading,
                onSubmit: _login,
              ),
            const SizedBox(height: 12),
            if (!_otpMode)
              TextButton(
                onPressed: _loading
                    ? null
                    : () => setState(() => _register = !_register),
                child: Text(
                  _register
                      ? 'عندك حساب؟ تسجيل الدخول'
                      : 'ما عندك حساب؟ إنشاء حساب جديد',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.email,
    required this.password,
    required this.loading,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController email;
  final TextEditingController password;
  final bool loading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          _Field(
            controller: email,
            label: 'البريد الإلكتروني',
            icon: Icons.email_outlined,
          ),
          const SizedBox(height: 12),
          _Field(
            controller: password,
            label: 'كلمة المرور',
            icon: Icons.lock_outline,
            obscure: true,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: loading ? null : onSubmit,
            icon: const Icon(Icons.login),
            label: const Text('تسجيل الدخول'),
          ),
        ],
      ),
    );
  }
}

class _RegisterForm extends StatelessWidget {
  const _RegisterForm({
    required this.formKey,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.confirmPassword,
    required this.license,
    required this.vehicleType,
    required this.vehiclePlate,
    required this.loading,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController phone;
  final TextEditingController password;
  final TextEditingController confirmPassword;
  final TextEditingController license;
  final TextEditingController vehicleType;
  final TextEditingController vehiclePlate;
  final bool loading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          _Field(
            controller: name,
            label: 'الاسم الكامل',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 10),
          _Field(
            controller: email,
            label: 'البريد الإلكتروني',
            icon: Icons.email_outlined,
          ),
          const SizedBox(height: 10),
          _Field(
            controller: phone,
            label: 'رقم الجوال',
            icon: Icons.phone_outlined,
          ),
          const SizedBox(height: 10),
          _Field(
            controller: license,
            label: 'رقم الرخصة',
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 10),
          _Field(
            controller: vehicleType,
            label: 'نوع السيارة',
            icon: Icons.directions_car_outlined,
          ),
          const SizedBox(height: 10),
          _Field(
            controller: vehiclePlate,
            label: 'رقم السيارة',
            icon: Icons.pin_outlined,
          ),
          const SizedBox(height: 10),
          _Field(
            controller: password,
            label: 'كلمة المرور',
            icon: Icons.lock_outline,
            obscure: true,
          ),
          const SizedBox(height: 10),
          _Field(
            controller: confirmPassword,
            label: 'تأكيد كلمة المرور',
            icon: Icons.lock_reset,
            obscure: true,
            validator: (value) {
              if (value != password.text) return 'كلمتا المرور غير متطابقتين';
              return _required(value);
            },
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: loading ? null : onSubmit,
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('إنشاء حساب سائق'),
          ),
        ],
      ),
    );
  }
}

class _OtpForm extends StatelessWidget {
  const _OtpForm({
    required this.formKey,
    required this.email,
    required this.otp,
    required this.loading,
    required this.onVerify,
    required this.onBack,
  });

  final GlobalKey<FormState> formKey;
  final String email;
  final TextEditingController otp;
  final bool loading;
  final VoidCallback onVerify;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          Text('تم إرسال الرمز إلى $email'),
          const SizedBox(height: 12),
          _Field(
            controller: otp,
            label: 'رمز التحقق',
            icon: Icons.verified_outlined,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: loading ? null : onVerify,
            icon: const Icon(Icons.check),
            label: const Text('تحقق'),
          ),
          TextButton(
            onPressed: loading ? null : onBack,
            child: const Text('رجوع'),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(prefixIcon: Icon(icon), labelText: label),
      validator: validator ?? _required,
    );
  }
}

String? _required(String? value) {
  if (value == null || value.trim().isEmpty) return 'هذا الحقل مطلوب';
  return null;
}
