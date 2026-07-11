import 'dart:io';

import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/premium_card.dart';
import 'customer_shell.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({required this.email, super.key});

  final String email;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _authService = AuthService();
  final _otp = TextEditingController();
  bool _loading = false;
  bool _resending = false;

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_otp.text.trim().length != 6) {
      _message('اكتب رمز التحقق المكون من 6 أرقام');
      return;
    }

    setState(() => _loading = true);
    try {
      final user = await _authService.verifyOtp(
        email: widget.email,
        otp: _otp.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => CustomerShell(user: user)),
        (route) => false,
      );
    } on ApiException catch (error) {
      _message(error.message);
    } on SocketException {
      _message('تعذر الاتصال بالخادم. تأكد أن Laravel يعمل على المنفذ 8000.');
    } catch (_) {
      _message('حدث خطأ غير متوقع.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await _authService.resendOtp(widget.email);
      _message('تم إرسال رمز تحقق جديد');
    } on ApiException catch (error) {
      _message(error.message);
    } on SocketException {
      _message('تعذر الاتصال بالخادم. تأكد أن Laravel يعمل على المنفذ 8000.');
    } catch (_) {
      _message('حدث خطأ غير متوقع.');
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'تحقق من البريد',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PremiumCard(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.mark_email_read_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'أدخل رمز التحقق',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: mutedText),
                ),
                const SizedBox(height: 18),
                CustomTextField(
                  controller: _otp,
                  label: '',
                  hintText: '000000',
                  icon: Icons.verified_outlined,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 18),
                CustomButton(
                  label: _loading ? 'جاري التحقق...' : 'تأكيد الرمز',
                  icon: Icons.verified_rounded,
                  onPressed: _loading ? null : _verify,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _resending ? null : _resend,
                  child: Text(
                    _resending ? 'جاري الإرسال...' : 'إعادة إرسال الرمز',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
