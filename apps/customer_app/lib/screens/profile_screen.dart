import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../services/profile_service.dart';
import '../utils/constants.dart';
import '../utils/theme_mode_controller.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/premium_card.dart';
import 'support_screen.dart';
import 'security_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    required this.user,
    required this.onUserChanged,
    required this.onSignOut,
    this.showBack = true,
    super.key,
  });

  final AppUser user;
  final ValueChanged<AppUser> onUserChanged;
  final VoidCallback onSignOut;
  final bool showBack;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileService = ProfileService();
  final _picker = ImagePicker();
  final _name = TextEditingController();
  final _phone = TextEditingController();

  String? _photoPath;
  bool _saving = false;
  bool _notifications = true;

  @override
  void initState() {
    super.initState();
    _name.text = widget.user.name;
    _phone.text = widget.user.phone;
    _loadPrefs();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  String _key(String key) => 'customer_${widget.user.id}_$key';

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _photoPath = prefs.getString(_key('photo'));
      _notifications = prefs.getBool(_key('notifications')) ?? true;
    });
  }

  Future<void> _pickPhoto() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (image == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key('photo'), image.path);
    if (!mounted) return;
    setState(() => _photoPath = image.path);
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      final updated = await _profileService.updateProfile(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
      );
      widget.onUserChanged(updated);
      _message('تم حفظ التعديلات');
    } catch (_) {
      widget.onUserChanged(
        widget.user.copyWith(
          name: _name.text.trim(),
          phone: _phone.text.trim(),
        ),
      );
      _message('تم تحديث الواجهة، تعذر حفظها على الخادم الآن');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(key), value);
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج من هذا الجهاز؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) widget.onSignOut();
  }

  @override
  Widget build(BuildContext context) {
    final file = _photoPath == null ? null : File(_photoPath!);
    final hasPhoto = file != null && file.existsSync();
    final initial = widget.user.name.trim().isEmpty
        ? 'ز'
        : widget.user.name.trim().substring(0, 1);

    return AppScaffold(
      title: 'الملف والإعدادات',
      showBack: widget.showBack,
      child: Column(
        children: [
          PremiumCard(
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 46,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      backgroundImage: hasPhoto ? FileImage(file) : null,
                      child: hasPhoto
                          ? null
                          : Text(
                              initial,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: emerald,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                    ),
                    PositionedDirectional(
                      bottom: 0,
                      end: 0,
                      child: GestureDetector(
                        onTap: _pickPhoto,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: emerald,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                CustomTextField(
                  controller: _name,
                  label: 'الاسم',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _phone,
                  label: 'رقم الجوال',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: TextEditingController(text: widget.user.email),
                  label: 'البريد الإلكتروني',
                  icon: Icons.email_outlined,
                  enabled: false,
                ),
                const SizedBox(height: 18),
                CustomButton(
                  label: _saving ? 'جاري الحفظ...' : 'حفظ الملف',
                  icon: Icons.save_outlined,
                  onPressed: _saving ? null : _saveProfile,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SettingsSwitchTile(
            icon: Icons.dark_mode_outlined,
            title: 'الوضع الداكن',
            subtitle: 'مظهر مريح للعين في الإضاءة المنخفضة',
            value: Theme.of(context).brightness == Brightness.dark,
            onChanged: setDarkMode,
          ),
          _SettingsSwitchTile(
            icon: Icons.notifications_active_outlined,
            title: 'إشعارات الرحلات',
            subtitle: 'العروض، وصول السائق، وتحديثات الرحلة',
            value: _notifications,
            onChanged: (value) {
              setState(() => _notifications = value);
              _saveBool('notifications', value);
            },
          ),
          _SettingsActionTile(
            icon: Icons.security_rounded,
            title: 'الأمان',
            subtitle: 'تغيير كلمة المرور وحماية حسابك',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SecurityScreen(
                  user: widget.user,
                ),
              ),
            ),
          ),
          _SettingsActionTile(
            icon: Icons.support_agent_rounded,
            title: 'الدعم',
            subtitle: 'مساعدة سريعة عند الحاجة',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SupportScreen())),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _confirmSignOut,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('تسجيل الخروج'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: SwitchListTile(
        secondary: CircleAvatar(
          radius: 27,
          backgroundColor: scheme.primary.withValues(alpha: .15),
          child: Icon(icon, color: scheme.primary, size: 27),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(subtitle),
        value: value,
        activeThumbColor: scheme.primary,
        onChanged: onChanged,
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 27,
              backgroundColor: scheme.primary.withValues(alpha: .15),
              child: Icon(icon, color: scheme.primary, size: 27),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}
