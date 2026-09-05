import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../utils/validators.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/premium_card.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({required this.user, super.key});
  final AppUser user;

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final _authService = AuthService();
  final _passwordForm = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmation = TextEditingController();
  bool _changingPassword = false;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_passwordForm.currentState!.validate()) return;
    setState(() => _changingPassword = true);
    try {
      await _authService.changePassword(
        userId: widget.user.id,
        currentPassword: _currentPassword.text,
        password: _newPassword.text,
        passwordConfirmation: _confirmation.text,
      );
      _currentPassword.clear();
      _newPassword.clear();
      _confirmation.clear();
      _message('تم تغيير كلمة المرور بنجاح.');
    } on ApiException catch (error) {
      _message(error.message);
    } catch (_) {
      _message('تعذر تغيير كلمة المرور. تأكد من اتصال الخادم.');
    } finally {
      if (mounted) setState(() => _changingPassword = false);
    }
  }

  void _message(String value) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'الأمان',
      child: PremiumCard(
        child: Form(
          key: _passwordForm,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('تغيير كلمة المرور', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text('استخدم كلمة مرور قوية من 8 أحرف أو أكثر.'),
              const SizedBox(height: 18),
              CustomTextField(controller: _currentPassword, label: 'كلمة المرور الحالية', icon: Icons.lock_outline_rounded, obscureText: true, validator: requiredField),
              const SizedBox(height: 12),
              CustomTextField(controller: _newPassword, label: 'كلمة المرور الجديدة', icon: Icons.password_rounded, obscureText: true, validator: (value) => value != null && value.length >= 8 ? null : 'أدخل 8 أحرف على الأقل'),
              const SizedBox(height: 12),
              CustomTextField(controller: _confirmation, label: 'تأكيد كلمة المرور الجديدة', icon: Icons.lock_reset_rounded, obscureText: true, validator: (value) => value == _newPassword.text ? requiredField(value) : 'كلمتا المرور غير متطابقتين'),
              const SizedBox(height: 18),
              CustomButton(label: _changingPassword ? 'جاري الحفظ...' : 'تغيير كلمة المرور', icon: Icons.key_rounded, onPressed: _changingPassword ? null : _changePassword),
            ],
          ),
        ),
      ),
    );
  }
}
