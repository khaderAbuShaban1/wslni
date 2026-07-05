import 'dart:io';

import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/app_logo.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/premium_card.dart';
import 'customer_shell.dart';
import 'otp_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _signup = false;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (_signup) {
        await _authService.register(
          name: _name.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          password: _password.text,
          passwordConfirmation: _confirm.text,
        );
        if (!mounted) return;
        _showMessage('تم إرسال رمز التحقق إلى بريدك');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(email: _email.text.trim()),
          ),
        );
        return;
      }

      final user = await _authService.login(
        email: _email.text.trim(),
        password: _password.text,
      );
      _openHome(user);
    } on ApiException catch (error) {
      if (error.statusCode == 403 && error.body['requires_otp'] == true) {
        final email = error.body['email']?.toString() ?? _email.text.trim();
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(email: email),
          ),
        );
        return;
      }
      _showMessage(error.message);
    } on SocketException {
      _showMessage(
        'تعذر الاتصال بالخادم. تأكد أن Laravel يعمل على المنفذ 8000.',
      );
    } catch (_) {
      _showMessage('حدث خطأ غير متوقع.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openHome(AppUser user) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => CustomerShell(user: user)),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 10),
            const AppLogo(size: 58),
            const SizedBox(height: 28),
            Text(
              _signup ? 'إنشاء حساب جديد' : 'تسجيل الدخول',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              _signup
                  ? 'أنشئ حسابك وابدأ طلب الرحلات بدون خرائط.'
                  : 'أدخل بريدك وكلمة المرور للمتابعة.',
              style: const TextStyle(color: mutedText, height: 1.5),
            ),
            const SizedBox(height: 28),
            PremiumCard(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_signup) ...[
                      CustomTextField(
                        controller: _name,
                        label: 'الاسم الكامل',
                        icon: Icons.person_outline_rounded,
                        validator: requiredField,
                      ),
                      const SizedBox(height: 12),
                    ],
                    CustomTextField(
                      controller: _email,
                      label: 'البريد الإلكتروني',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: emailValidator,
                    ),
                    if (_signup) ...[
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _phone,
                        label: 'رقم الجوال',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: requiredField,
                      ),
                    ],
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _password,
                      label: 'كلمة المرور',
                      icon: Icons.lock_outline_rounded,
                      obscureText: true,
                      validator: requiredField,
                    ),
                    if (_signup) ...[
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _confirm,
                        label: 'تأكيد كلمة المرور',
                        icon: Icons.lock_reset_rounded,
                        obscureText: true,
                        validator: (value) {
                          if (value != _password.text) {
                            return 'كلمتا المرور غير متطابقتين';
                          }
                          return requiredField(value);
                        },
                      ),
                    ],
                    const SizedBox(height: 20),
                    CustomButton(
                      label: _loading
                          ? 'جاري التنفيذ...'
                          : _signup
                          ? 'إنشاء الحساب'
                          : 'دخول',
                      icon: _signup
                          ? Icons.person_add_alt_rounded
                          : Icons.login_rounded,
                      onPressed: _loading ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: TextButton(
                onPressed: _loading
                    ? null
                    : () => setState(() => _signup = !_signup),
                child: Text(
                  _signup
                      ? 'عندك حساب؟ تسجيل الدخول'
                      : 'ما عندك حساب؟ إنشاء حساب جديد',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
