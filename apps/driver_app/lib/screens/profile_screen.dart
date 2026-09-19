part of '../main.dart';

class _DriverProfilePage extends StatefulWidget {
  const _DriverProfilePage({
    required this.user,
    required this.onSignOut,
    required this.onUserChanged,
  });
  final DriverUser user;
  final VoidCallback onSignOut;
  final ValueChanged<DriverUser> onUserChanged;

  @override
  State<_DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<_DriverProfilePage> {
  final _api = ApiClient();
  final _avatars = _AvatarService();
  final _picker = ImagePicker();
  bool _loading = true;
  bool _photoBusy = false;
  String? _error;
  _RatingSummary _summary = const _RatingSummary();
  List<_CustomerRating> _ratings = const [];

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  Future<void> _onPhotoTap() async {
    if (_photoBusy) return;
    if (widget.user.avatarPath == null) return _uploadPhoto();

    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('تغيير الصورة'),
              onTap: () => Navigator.pop(context, 'change'),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline_rounded,
                color: Colors.red.shade700,
              ),
              title: Text(
                'حذف الصورة',
                style: TextStyle(color: Colors.red.shade700),
              ),
              onTap: () => Navigator.pop(context, 'remove'),
            ),
          ],
        ),
      ),
    );
    if (action == 'change') await _uploadPhoto();
    if (action == 'remove') await _removePhoto();
  }

  Future<void> _uploadPhoto() async {
    // Downscaled on the phone: every customer who sees this photo downloads it.
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 720,
      maxHeight: 720,
      imageQuality: 85,
    );
    if (image == null || !mounted) return;

    setState(() => _photoBusy = true);
    try {
      final path = await _avatars.upload(File(image.path));
      widget.onUserChanged(widget.user.copyWith(avatarPath: path));
      _message('تم تحديث الصورة الشخصية');
    } on ApiException catch (error) {
      _message(error.message);
    } catch (_) {
      _message('تعذر رفع الصورة. تحقق من الاتصال وحاول مجددًا.');
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<void> _removePhoto() async {
    setState(() => _photoBusy = true);
    try {
      await _avatars.remove();
      widget.onUserChanged(widget.user.copyWith(clearAvatar: true));
      _message('تم حذف الصورة الشخصية');
    } catch (_) {
      _message('تعذر حذف الصورة. حاول مجددًا.');
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<void> _loadRatings() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.get('drivers/${widget.user.id}/ratings');
      if (!mounted) return;
      final rows = data['ratings'];
      setState(() {
        _summary = _RatingSummary.fromMap(
          data['summary'] is Map ? data['summary'] as Map : const {},
        );
        _ratings = rows is List
            ? rows.whereType<Map>().map(_CustomerRating.fromMap).toList()
            : const [];
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'تعذر تحميل التقييمات. اسحب للتحديث وحاول مجددًا.';
        });
      }
    }
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

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final previewRatings = _ratings.take(3).toList();
    return RefreshIndicator(
      onRefresh: _loadRatings,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
        children: [
          _IdentityCard(
            user: widget.user,
            summary: _summary,
            photoBusy: _photoBusy,
            onPickPhoto: _onPhotoTap,
          ),
          const SizedBox(height: 14),

          // Vehicle info
          const _SectionTitle(
            title: 'بيانات المركبة',
            icon: Icons.directions_car_filled_rounded,
          ),
          const SizedBox(height: 9),
          _VehicleInfoCard(user: widget.user),

          const SizedBox(height: 22),

          // Actions
          _ProfileMenuTile(
            icon: Icons.edit_rounded,
            label: 'تعديل البيانات الشخصية',
            onTap: () async {
              final updated = await Navigator.of(context).push<DriverUser>(
                MaterialPageRoute(
                  builder: (_) => _EditProfilePage(user: widget.user),
                ),
              );
              if (updated != null) {
                widget.onUserChanged(updated);
                _message('تم تحديث البيانات بنجاح.');
              }
            },
          ),
          const SizedBox(height: 10),
          _ProfileMenuTile(
            icon: Icons.lock_outline_rounded,
            label: 'تغيير كلمة المرور',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _ChangePasswordPage()),
            ),
          ),
          const SizedBox(height: 10),
          _ProfileMenuTile(
            icon: Icons.support_agent_rounded,
            label: 'الدعم',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _DriverSupportPage()),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _confirmSignOut,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('تسجيل الخروج'),
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.error,
                side: BorderSide(color: scheme.error),
              ),
            ),
          ),

          const SizedBox(height: 22),

          // Ratings — preview (max 3)
          _SectionTitle(
            title: 'تقييمات الزبائن',
            icon: Icons.star_rounded,
            trailing: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    '${_summary.count} تقييم',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
          ),
          const SizedBox(height: 9),
          if (_error != null)
            _RatingsMessage(
              icon: Icons.wifi_off_rounded,
              message: _error!,
              action: _loadRatings,
            )
          else if (_loading)
            const _RatingsSkeleton()
          else if (_ratings.isEmpty)
            const _RatingsMessage(
              icon: Icons.rate_review_outlined,
              message:
                  'لا توجد تقييمات بعد. ستظهر هنا بعد إكمال الزبون لتقييم رحلته.',
            )
          else ...[
            _RatingOverview(summary: _summary),
            const SizedBox(height: 10),
            for (final rating in previewRatings) ...[
              _CustomerRatingCard(rating: rating),
              const SizedBox(height: 10),
            ],
            if (_ratings.length > 3)
              Center(
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          _AllRatingsPage(ratings: _ratings, summary: _summary),
                    ),
                  ),
                  icon: const Icon(Icons.expand_more_rounded),
                  label: Text('عرض جميع التقييمات (${_ratings.length})'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Identity Card (top of profile)
// ---------------------------------------------------------------------------

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.user,
    required this.summary,
    required this.photoBusy,
    required this.onPickPhoto,
  });
  final DriverUser user;
  final _RatingSummary summary;
  final bool photoBusy;
  final VoidCallback onPickPhoto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [Color(0xFFFFE38A), Color(0xFFF2B82E)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF0B72E).withValues(alpha: .30),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onPickPhoto,
                child: Stack(
                  children: [
                    _UserAvatar(
                      name: user.name,
                      path: user.avatarPath,
                      radius: 33,
                      fallbackColor: const Color(0xFFF3C455),
                    ),
                    if (photoBusy)
                      const Positioned.fill(
                        child: ClipOval(
                          child: ColoredBox(
                            color: Color(0x66000000),
                            child: Center(
                              child: SizedBox.square(
                                dimension: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .15),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 14,
                          color: _dark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        color: _dark,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.phone,
                      style: TextStyle(color: _dark.withValues(alpha: .66)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .45),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, color: _success, size: 17),
                    SizedBox(width: 4),
                    Text(
                      'سائق',
                      style: TextStyle(
                        color: _success,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: _dark.withValues(alpha: .14)),
          const SizedBox(height: 15),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: _dark, size: 22),
              const SizedBox(width: 6),
              Text(
                summary.displayAverage,
                style: const TextStyle(
                  color: _dark,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'من تقييمات الزبائن',
                style: TextStyle(color: _dark.withValues(alpha: .66)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile menu tile
// ---------------------------------------------------------------------------

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outlineVariant;
    return Material(
      borderRadius: BorderRadius.circular(23),
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(23),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: outline),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _emerald.withValues(alpha: .16),
                child: Icon(icon, color: _emerald),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              const Icon(Icons.chevron_left_rounded, color: _muted),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Edit profile page
// ---------------------------------------------------------------------------

class _EditProfilePage extends StatefulWidget {
  const _EditProfilePage({required this.user});
  final DriverUser user;

  @override
  State<_EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<_EditProfilePage> {
  final _api = ApiClient();
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user.name);
  late final _phone = TextEditingController(text: widget.user.phone);
  late final _vehicleType = TextEditingController(
    text: widget.user.vehicleType,
  );
  late final _vehiclePlate = TextEditingController(
    text: widget.user.vehiclePlate,
  );
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _vehicleType.dispose();
    _vehiclePlate.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final result = await _api.patch('drivers/me', {
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'vehicle_type': _vehicleType.text.trim(),
        'vehicle_plate': _vehiclePlate.text.trim(),
      });
      final userData = result['user'];
      if (!mounted) return;
      if (userData is Map<String, dynamic>) {
        Navigator.of(context).pop(DriverUser.fromJson(userData));
      } else {
        Navigator.of(context).pop(
          widget.user.copyWith(
            name: _name.text.trim(),
            phone: _phone.text.trim(),
            vehicleType: _vehicleType.text.trim(),
            vehiclePlate: _vehiclePlate.text.trim(),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) _message(e.message);
    } catch (_) {
      if (mounted) _message('تعذر حفظ التعديلات. تأكد من اتصال الخادم.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outlineVariant;
    return Scaffold(
      appBar: AppBar(title: const Text('تعديل البيانات')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(23),
                border: Border.all(color: outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SectionTitle(
                    title: 'البيانات الشخصية',
                    icon: Icons.person_rounded,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'الاسم',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'الاسم مطلوب' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phone,
                    decoration: const InputDecoration(
                      labelText: 'رقم الهاتف',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    initialValue: widget.user.email,
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    enabled: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(23),
                border: Border.all(color: outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SectionTitle(
                    title: 'بيانات المركبة',
                    icon: Icons.directions_car_filled_rounded,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _vehicleType,
                    decoration: const InputDecoration(
                      labelText: 'نوع المركبة',
                      prefixIcon: Icon(Icons.directions_car_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _vehiclePlate,
                    decoration: const InputDecoration(
                      labelText: 'رقم اللوحة',
                      prefixIcon: Icon(Icons.pin_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_saving ? 'جاري الحفظ...' : 'حفظ التعديلات'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Change password page
// ---------------------------------------------------------------------------

class _ChangePasswordPage extends StatefulWidget {
  const _ChangePasswordPage();

  @override
  State<_ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<_ChangePasswordPage> {
  final _api = ApiClient();
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _newPass = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  bool _showCurrent = false;
  bool _showNew = false;

  @override
  void dispose() {
    _current.dispose();
    _newPass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _api.post('auth/change-password', {
        'current_password': _current.text,
        'password': _newPass.text,
        'password_confirmation': _confirm.text,
      });
      _current.clear();
      _newPass.clear();
      _confirm.clear();
      if (mounted) {
        _message('تم تغيير كلمة المرور بنجاح.');
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) _message(e.message);
    } catch (_) {
      if (mounted) _message('تعذر تغيير كلمة المرور. تأكد من اتصال الخادم.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outlineVariant;
    return Scaffold(
      appBar: AppBar(title: const Text('تغيير كلمة المرور')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(23),
                border: Border.all(color: outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'استخدم كلمة مرور قوية من 8 أحرف أو أكثر.',
                    style: TextStyle(color: _muted),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _current,
                    obscureText: !_showCurrent,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور الحالية',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showCurrent
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                        ),
                        onPressed: () =>
                            setState(() => _showCurrent = !_showCurrent),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.isEmpty
                        ? 'أدخل كلمة المرور الحالية'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _newPass,
                    obscureText: !_showNew,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور الجديدة',
                      prefixIcon: const Icon(Icons.password_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showNew
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                        ),
                        onPressed: () => setState(() => _showNew = !_showNew),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) => v != null && v.length >= 8
                        ? null
                        : 'أدخل 8 أحرف على الأقل',
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _confirm,
                    obscureText: !_showNew,
                    decoration: const InputDecoration(
                      labelText: 'تأكيد كلمة المرور الجديدة',
                      prefixIcon: Icon(Icons.lock_reset_rounded),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == _newPass.text
                        ? (v == null || v.isEmpty
                              ? 'أدخل تأكيد كلمة المرور'
                              : null)
                        : 'كلمتا المرور غير متطابقتين',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.key_rounded),
                label: Text(_saving ? 'جاري الحفظ...' : 'تغيير كلمة المرور'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// All ratings page
// ---------------------------------------------------------------------------

class _AllRatingsPage extends StatelessWidget {
  const _AllRatingsPage({required this.ratings, required this.summary});
  final List<_CustomerRating> ratings;
  final _RatingSummary summary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('جميع التقييمات')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
        children: [
          _RatingOverview(summary: summary),
          const SizedBox(height: 14),
          for (final rating in ratings) ...[
            _CustomerRatingCard(rating: rating),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _VehicleInfoCard extends StatelessWidget {
  const _VehicleInfoCard({required this.user});
  final DriverUser user;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outlineVariant;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: outline),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.directions_car_rounded,
            label: 'المركبة',
            value: user.vehicleType.isEmpty ? 'غير مضافة' : user.vehicleType,
          ),
          Divider(height: 1, indent: 18, endIndent: 18, color: outline),
          _InfoRow(
            icon: Icons.pin_rounded,
            label: 'رقم اللوحة',
            value: user.vehiclePlate.isEmpty ? 'غير مضاف' : user.vehiclePlate,
          ),
          Divider(height: 1, indent: 18, endIndent: 18, color: outline),
          _InfoRow(
            icon: Icons.email_outlined,
            label: 'البريد الإلكتروني',
            value: user.email,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: CircleAvatar(
      backgroundColor: _emerald.withValues(alpha: .16),
      child: Icon(icon, color: _emerald),
    ),
    title: Text(label),
    subtitle: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon, this.trailing});
  final String title;
  final IconData icon;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: _emerald, size: 21),
      const SizedBox(width: 7),
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
      ),
      const Spacer(),
      ?trailing,
    ],
  );
}

class _RatingOverview extends StatelessWidget {
  const _RatingOverview({required this.summary});
  final _RatingSummary summary;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainerHigh : const Color(0xFFFFF8E6),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: isDark ? scheme.outlineVariant : const Color(0xFFF1D486),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                summary.displayAverage,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Text('/ 5', style: TextStyle(color: scheme.onSurfaceVariant)),
              const Spacer(),
              _StarRow(value: summary.average.round()),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: summary.count == 0
                  ? 0
                  : summary.fiveStarCount / summary.count,
              minHeight: 8,
              color: scheme.primary,
              backgroundColor: isDark
                  ? scheme.surfaceContainerHighest
                  : const Color(0xFFF4DF9B),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              '${summary.fiveStarCount} تقييم بخمس نجوم من أصل ${summary.count}',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerRatingCard extends StatelessWidget {
  const _CustomerRatingCard({required this.rating});
  final _CustomerRating rating;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _UserAvatar(
            name: rating.customerName,
            path: rating.customerAvatar,
            radius: 22,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        rating.customerName,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    _StarRow(value: rating.value),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  rating.comment.isEmpty
                      ? 'قيّم رحلتك بدون تعليق'
                      : '"${rating.comment}"',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'رحلة #${rating.rideId}',
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.value});
  final int value;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(
      5,
      (index) => Icon(
        index < value ? Icons.star_rounded : Icons.star_outline_rounded,
        color: const Color(0xFFF0B72E),
        size: 17,
      ),
    ),
  );
}

class _RatingsMessage extends StatelessWidget {
  const _RatingsMessage({
    required this.icon,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String message;
  final VoidCallback? action;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(23),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Column(
      children: [
        Icon(icon, color: _muted, size: 32),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, height: 1.5),
        ),
        if (action != null) ...[
          const SizedBox(height: 8),
          TextButton(onPressed: action, child: const Text('إعادة المحاولة')),
        ],
      ],
    ),
  );
}

class _RatingsSkeleton extends StatelessWidget {
  const _RatingsSkeleton();
  @override
  Widget build(BuildContext context) => Container(
    height: 125,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(23),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: const Center(child: CircularProgressIndicator()),
  );
}

class _RatingSummary {
  const _RatingSummary({
    this.average = 0,
    this.count = 0,
    this.fiveStarCount = 0,
  });
  final double average;
  final int count;
  final int fiveStarCount;
  String get displayAverage => count == 0 ? '—' : average.toStringAsFixed(1);
  factory _RatingSummary.fromMap(Map map) => _RatingSummary(
    average: double.tryParse(map['average']?.toString() ?? '') ?? 0,
    count: int.tryParse(map['count']?.toString() ?? '') ?? 0,
    fiveStarCount: int.tryParse(map['five_star_count']?.toString() ?? '') ?? 0,
  );
}

class _CustomerRating {
  const _CustomerRating({
    required this.rideId,
    required this.customerName,
    required this.value,
    required this.comment,
    required this.pickup,
    required this.dropoff,
    this.customerAvatar,
  });
  final int rideId;
  final String customerName;
  final String? customerAvatar;
  final int value;
  final String comment;
  final String pickup;
  final String dropoff;
  factory _CustomerRating.fromMap(Map map) => _CustomerRating(
    rideId: int.tryParse(map['ride_id']?.toString() ?? '') ?? 0,
    customerName: map['customer_name']?.toString() ?? 'زبون',
    value: int.tryParse(map['rating']?.toString() ?? '') ?? 0,
    comment: map['comment']?.toString() ?? '',
    pickup: map['pickup_address']?.toString() ?? '',
    dropoff: map['dropoff_address']?.toString() ?? '',
    customerAvatar: _nonEmpty(map['customer_avatar']),
  );
}
