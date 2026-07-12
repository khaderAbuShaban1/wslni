part of '../main.dart';

class _EarningsPage extends StatelessWidget {
  _EarningsPage({required this.user});

  final DriverUser user;
  final RealtimeDriverService _realtime = RealtimeDriverService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RideRequestItem>>(
      stream: _realtime.watchDriverRides(user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SkeletonList();
        }
        final completed = (snapshot.data ?? const <RideRequestItem>[])
            .where(
              (ride) =>
                  ride.status == RideStatuses.tripCompleted ||
                  ride.status == RideStatuses.rated,
            )
            .toList();
        final gross = completed.fold<double>(
          0,
          (sum, ride) => sum + _amount(ride.actualFare),
        );
        final commission = completed.fold<double>(
          0,
          (sum, ride) => sum + _amount(ride.platformFee),
        );
        final net = gross - commission;

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _emerald.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: _emerald,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'أرباحي',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const Text(
                      'ملخص الرحلات المكتملة',
                      style: TextStyle(color: _muted),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            _NetEarningsCard(net: net),
            const SizedBox(height: 12),
            _WithdrawalPanel(user: user),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    icon: Icons.payments_outlined,
                    label: 'إجمالي الأجرة',
                    value: '${gross.toStringAsFixed(2)} ش',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.percent_rounded,
                    label: 'عمولة التطبيق',
                    value: '${commission.toStringAsFixed(2)} ش',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.route_rounded,
                    label: 'الرحلات',
                    value: completed.length.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'تفاصيل الأرباح',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            if (completed.isEmpty)
              const _EmptyStateCard(
                icon: Icons.payments_outlined,
                title: 'لا توجد أرباح بعد',
                message: 'بعد إكمال الرحلات ستظهر أرباحك هنا مباشرة.',
              )
            else
              for (final ride in completed) ...[
                _TripEarningCard(ride: ride),
                const SizedBox(height: 10),
              ],
          ],
        );
      },
    );
  }

  double _amount(String value) => double.tryParse(value) ?? 0;
}

class _WithdrawalPanel extends StatefulWidget {
  const _WithdrawalPanel({required this.user});
  final DriverUser user;

  @override
  State<_WithdrawalPanel> createState() => _WithdrawalPanelState();
}

class _WithdrawalPanelState extends State<_WithdrawalPanel> {
  final _api = ApiClient();
  final _realtime = RealtimeDriverService();
  double? _balance;
  bool _loading = true;
  List<Map<String, dynamic>> _withdrawals = const [];
  StreamSubscription<List<Map<String, dynamic>>>? _withdrawalSubscription;

  @override
  void initState() {
    super.initState();
    _load();
    _withdrawalSubscription = _realtime.watchWithdrawals(widget.user.id).listen(
      (rows) {
        if (mounted) {
          setState(() {
            _withdrawals = rows;
            if (rows.isNotEmpty) {
              _balance =
                  double.tryParse(
                    rows.first['wallet_balance']?.toString() ?? '',
                  ) ??
                  _balance;
            }
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _withdrawalSubscription?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await _api.get('drivers/${widget.user.id}/withdrawals');
      if (mounted) {
        setState(() {
          _balance =
              double.tryParse(data['wallet_balance']?.toString() ?? '') ?? 0;
          final rows = data['withdrawals'];
          _withdrawals = rows is List
              ? rows.whereType<Map<String, dynamic>>().toList()
              : const [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openWithdrawal() async {
    final amount = TextEditingController();
    final accountName = TextEditingController(text: widget.user.name);
    final accountNumber = TextEditingController();
    var method = 'mobile_wallet';
    final submitted = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'سحب الأرباح',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'المتاح: ${(_balance ?? 0).toStringAsFixed(2)} شيكل',
                style: const TextStyle(color: _muted),
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'mobile_wallet',
                    label: Text('محفظة جوال'),
                    icon: Icon(Icons.phone_android),
                  ),
                  ButtonSegment(
                    value: 'bank',
                    label: Text('حساب بنكي'),
                    icon: Icon(Icons.account_balance_outlined),
                  ),
                ],
                selected: {method},
                onSelectionChanged: (value) =>
                    setSheetState(() => method = value.first),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'المبلغ',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: accountName,
                decoration: const InputDecoration(
                  labelText: 'اسم صاحب الحساب',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: accountNumber,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'رقم الحساب أو الجوال',
                  prefixIcon: Icon(Icons.numbers),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, {
                  'amount': amount.text.trim(),
                  'method': method,
                  'account_name': accountName.text.trim(),
                  'account_number': accountNumber.text.trim(),
                }),
                icon: const Icon(Icons.send_rounded),
                label: const Text('إرسال طلب السحب'),
              ),
            ],
          ),
        ),
      ),
    );
    if (submitted == null) return;
    try {
      final result = await _api.post(
        'drivers/${widget.user.id}/withdrawals',
        submitted,
      );
      if (!mounted) return;
      setState(() {
        _balance =
            double.tryParse(result['wallet_balance']?.toString() ?? '') ??
            _balance;
        final withdrawal = result['withdrawal'];
        if (withdrawal is Map<String, dynamic>) {
          _withdrawals = [withdrawal, ..._withdrawals];
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال طلب السحب للمراجعة.')),
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.savings_outlined, color: _emerald),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'الرصيد المتاح للسحب',
                      style: TextStyle(color: _muted),
                    ),
                    Text(
                      _loading
                          ? 'جاري التحميل...'
                          : '${(_balance ?? 0).toStringAsFixed(2)} شيكل',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: _loading || (_balance ?? 0) < 10
                    ? null
                    : _openWithdrawal,
                child: const Text('سحب'),
              ),
            ],
          ),
        ),
        if (_withdrawals.isNotEmpty) ...[
          const SizedBox(height: 18),
          const Text(
            'طلبات السحب',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          for (final withdrawal in _withdrawals) ...[
            _WithdrawalStatusCard(withdrawal: withdrawal),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

class _WithdrawalStatusCard extends StatelessWidget {
  const _WithdrawalStatusCard({required this.withdrawal});

  final Map<String, dynamic> withdrawal;

  @override
  Widget build(BuildContext context) {
    final status = withdrawal['status']?.toString() ?? 'pending';
    final (label, color, icon) = switch (status) {
      'paid' => ('تم التحويل', _success, Icons.check_circle_rounded),
      'rejected' => ('مرفوض — أُعيد المبلغ', _error, Icons.cancel_rounded),
      _ => (
        'بانتظار المراجعة',
        const Color(0xFFD99C18),
        Icons.schedule_rounded,
      ),
    };
    final method = withdrawal['method']?.toString() == 'bank'
        ? 'حساب بنكي'
        : 'محفظة جوال';
    final amount = double.tryParse(withdrawal['amount']?.toString() ?? '') ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: .14),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${amount.toStringAsFixed(2)} شيكل',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  '$method · ${withdrawal['account_number'] ?? ''}',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _NetEarningsCard extends StatelessWidget {
  const _NetEarningsCard({required this.net});

  final double net;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [Color(0xFFF2C230), Color(0xFFE2A91E)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _emerald.withValues(alpha: .25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .28),
              borderRadius: BorderRadius.circular(19),
            ),
            child: const Icon(Icons.trending_up_rounded, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'صافي الأرباح',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  '${net.toStringAsFixed(2)} شيكل',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: _dark,
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _emerald, size: 22),
          const SizedBox(height: 14),
          Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripEarningCard extends StatelessWidget {
  const _TripEarningCard({required this.ride});

  final RideRequestItem ride;

  @override
  Widget build(BuildContext context) {
    final fare = double.tryParse(ride.actualFare) ?? 0;
    final fee = double.tryParse(ride.platformFee) ?? 0;
    final net = fare - fee;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _emerald.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.local_taxi_rounded, color: _emerald),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ride.customerName,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${ride.pickup} ← ${ride.dropoff}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 13),
                ),
                if (fee > 0) ...[
                  const SizedBox(height: 3),
                  Text(
                    'الأجرة ${fare.toStringAsFixed(2)} - العمولة ${fee.toStringAsFixed(2)}',
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${net.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: _success,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text('شيكل', style: TextStyle(color: _muted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
