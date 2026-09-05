part of '../main.dart';

class _DriverProfilePage extends StatefulWidget {
  const _DriverProfilePage({required this.user, required this.onSignOut});
  final DriverUser user;
  final VoidCallback onSignOut;

  @override
  State<_DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<_DriverProfilePage> {
  final _api = ApiClient();
  bool _loading = true;
  String? _error;
  _RatingSummary _summary = const _RatingSummary();
  List<_CustomerRating> _ratings = const [];

  @override
  void initState() {
    super.initState();
    _loadRatings();
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _loadRatings,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
        children: [
          _IdentityCard(user: widget.user, summary: _summary),
          const SizedBox(height: 14),
          const _SectionTitle(
            title: 'بيانات المركبة',
            icon: Icons.directions_car_filled_rounded,
          ),
          const SizedBox(height: 9),
          _VehicleInfoCard(user: widget.user),
          const SizedBox(height: 22),
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
            for (final rating in _ratings) ...[
              _CustomerRatingCard(rating: rating),
              const SizedBox(height: 10),
            ],
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _DriverSupportPage()),
            ),
            icon: const Icon(Icons.support_agent_rounded),
            label: const Text('الدعم'),
          ),
          const SizedBox(height: 10),
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

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.user, required this.summary});
  final DriverUser user;
  final _RatingSummary summary;

  @override
  Widget build(BuildContext context) {
    final initial = user.name.trim().isEmpty ? 'س' : user.name.trim()[0];
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
              CircleAvatar(
                radius: 33,
                backgroundColor: const Color(0xFFF3C455),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: _dark,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                  ),
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF8E6),
      borderRadius: BorderRadius.circular(23),
      border: Border.all(color: const Color(0xFFF1D486)),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Text(
              summary.displayAverage,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: _dark,
              ),
            ),
            const SizedBox(width: 8),
            const Text('/ 5', style: TextStyle(color: _muted)),
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
            color: const Color(0xFFF0B72E),
            backgroundColor: const Color(0xFFF4DF9B),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            '${summary.fiveStarCount} تقييم بخمس نجوم من أصل ${summary.count}',
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}

class _CustomerRatingCard extends StatelessWidget {
  const _CustomerRatingCard({required this.rating});
  final _CustomerRating rating;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = rating.customerName.isEmpty ? 'ز' : rating.customerName[0];
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
          CircleAvatar(
            radius: 22,
            backgroundColor: _emerald.withValues(alpha: .16),
            child: Text(
              initial,
              style: const TextStyle(color: _dark, fontWeight: FontWeight.w900),
            ),
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
                      : '“${rating.comment}”',
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
  });
  final int rideId;
  final String customerName;
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
  );
}
