part of '../main.dart';

class ActiveRidePage extends StatefulWidget {
  const ActiveRidePage({
    required this.ride,
    required this.user,
    required this.onReleased,
    super.key,
  });

  final RideRequestItem ride;
  final DriverUser user;
  final VoidCallback onReleased;

  @override
  State<ActiveRidePage> createState() => _ActiveRidePageState();
}

class _ActiveRidePageState extends State<ActiveRidePage> {
  final _api = ApiClient();
  final _realtime = RealtimeDriverService();
  late RideRequestItem _ride;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _ride = widget.ride;
  }

  @override
  void didUpdateWidget(covariant ActiveRidePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_updating) _ride = widget.ride;
  }

  String get _nextStatus {
    return switch (_ride.status) {
      RideStatuses.driverConfirmed => RideStatuses.driverOnTheWay,
      RideStatuses.driverOnTheWay => RideStatuses.driverArrived,
      RideStatuses.driverArrived => RideStatuses.tripStarted,
      RideStatuses.tripStarted => RideStatuses.tripCompleted,
      _ => '',
    };
  }

  String get _nextActionLabel {
    return switch (_ride.status) {
      RideStatuses.driverConfirmed => 'بدء التوجه إلى الزبون',
      RideStatuses.driverOnTheWay => 'وصلت إلى موقع الزبون',
      RideStatuses.driverArrived => 'بدء الرحلة',
      RideStatuses.tripStarted => 'إنهاء الرحلة',
      _ => 'تحديث الحالة',
    };
  }

  IconData get _nextActionIcon {
    return switch (_ride.status) {
      RideStatuses.driverConfirmed => Icons.directions_car_outlined,
      RideStatuses.driverOnTheWay => Icons.location_on_outlined,
      RideStatuses.driverArrived => Icons.play_arrow_rounded,
      RideStatuses.tripStarted => Icons.check_circle_outline_rounded,
      _ => Icons.sync,
    };
  }

  Future<void> _updateStatus(String status) async {
    if (_updating) return;
    setState(() => _updating = true);

    try {
      final result = await _api.patch('rides/${_ride.id}', {
        'driver_id': widget.user.id,
        'status': status,
      });
      final rawRide = result['ride'];
      final updatedRide = rawRide is Map<String, dynamic>
          ? RideRequestItem.fromJson(rawRide)
          : _ride;

      var realtimeSynced = true;
      try {
        await _realtime.updateRideStatus(
          rideId: _ride.id,
          status: status,
          actualFare: updatedRide.actualFare,
          platformFee: updatedRide.platformFee,
        );
      } catch (_) {
        realtimeSynced = false;
      }

      if (!mounted) return;
      if (status == RideStatuses.tripCompleted ||
          status == RideStatuses.cancelled) {
        _showMessage(
          status == RideStatuses.tripCompleted
              ? 'تم إنهاء الرحلة بنجاح.'
              : 'تم إلغاء الرحلة.',
        );
        widget.onReleased();
        return;
      }

      setState(() => _ride = updatedRide);
      _showMessage(
        realtimeSynced
            ? 'تم تحديث حالة الرحلة.'
            : 'تم تحديث الرحلة على الخادم، وستتم مزامنتها تلقائيًا.',
      );
    } on ApiException catch (error) {
      if (mounted) {
        _showMessage(error.message);
      }
    } catch (_) {
      if (mounted) {
        _showMessage('تعذر تحديث الرحلة. تحقق من الاتصال وحاول مجددًا.');
      }
    } finally {
      if (mounted) {
        setState(() => _updating = false);
      }
    }
  }

  Future<void> _respondToSelection(bool accepted) async {
    if (_updating) return;
    setState(() => _updating = true);
    try {
      final result = await _api.patch('rides/${_ride.id}/driver-confirmation', {
        'driver_id': widget.user.id,
        'accepted': accepted,
      });
      final rawRide = result['ride'];
      final updated = rawRide is Map<String, dynamic>
          ? RideRequestItem.fromJson(rawRide)
          : _ride;
      await _realtime.respondToSelection(
        rideId: _ride.id,
        driverId: widget.user.id,
        accepted: accepted,
      );
      if (!mounted) return;
      if (!accepted) {
        widget.onReleased();
        return;
      }
      setState(() => _ride = updated);
      _showMessage('تم تأكيد الرحلة.');
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _confirmCancellation() async {
    if (_updating) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء الطلب؟'),
        content: const Text(
          'سيتم إبلاغ الزبون وإغلاق الرحلة، وبعدها ستتمكن من استقبال طلبات جديدة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('العودة'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد الإلغاء'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _updateStatus(RideStatuses.cancelled);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('الرحلة النشطة'),
          actions: const [
            Padding(
              padding: EdgeInsetsDirectional.only(end: 16),
              child: Icon(Icons.lock_outline_rounded, color: _emerald),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            children: [
              _ActiveStatusBanner(ride: _ride),
              const SizedBox(height: 12),
              _ActiveRideSection(
                title: 'معلومات الزبون',
                icon: Icons.person_outline_rounded,
                child: Column(
                  children: [
                    _ActiveInfoRow(label: 'الاسم', value: _ride.customerName),
                    const Divider(height: 20),
                    _ActiveInfoRow(
                      label: 'رقم الهاتف',
                      value: _ride.customerPhone.isEmpty
                          ? 'غير متوفر'
                          : _ride.customerPhone,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _ActiveRideSection(
                title: 'مسار الرحلة',
                icon: Icons.route_outlined,
                child: _RouteSummaryBox(ride: _ride),
              ),
              if (_ride.actualFare.isNotEmpty || _ride.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                _ActiveRideSection(
                  title: 'تفاصيل الطلب',
                  icon: Icons.receipt_long_outlined,
                  child: Column(
                    children: [
                      if (_ride.actualFare.isNotEmpty)
                        _ActiveInfoRow(
                          label: 'السعر المتفق عليه',
                          value: '${_ride.actualFare} شيكل',
                        ),
                      if (_ride.actualFare.isNotEmpty && _ride.notes.isNotEmpty)
                        const Divider(height: 20),
                      if (_ride.notes.isNotEmpty)
                        _ActiveInfoRow(label: 'ملاحظات', value: _ride.notes),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _RideProgress(status: _ride.status),
              const SizedBox(height: 18),
              if (_ride.status == RideStatuses.driverSelected) ...[
                FilledButton.icon(
                  onPressed: _updating ? null : () => _respondToSelection(true),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('تأكيد الرحلة'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _updating
                      ? null
                      : () => _respondToSelection(false),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('رفض الرحلة'),
                ),
              ] else ...[
                FilledButton.icon(
                  onPressed: _updating || _nextStatus.isEmpty
                      ? null
                      : () => _updateStatus(_nextStatus),
                  icon: _updating
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Icon(_nextActionIcon),
                  label: Text(_updating ? 'جاري التحديث...' : _nextActionLabel),
                ),
              ],
              const SizedBox(height: 10),
              if (_ride.status != RideStatuses.driverSelected)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade200),
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  onPressed: _updating ? null : _confirmCancellation,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('إلغاء الطلب'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveStatusBanner extends StatelessWidget {
  const _ActiveStatusBanner({required this.ride});

  final RideRequestItem ride;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: .28),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_taxi_rounded, color: _emerald, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ride.statusLabel,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'لن تظهر لك طلبات أخرى حتى تنهي هذه الرحلة أو تلغيها.',
                  style: TextStyle(color: _muted, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveRideSection extends StatelessWidget {
  const _ActiveRideSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: _emerald, size: 21),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ActiveInfoRow extends StatelessWidget {
  const _ActiveInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _RideProgress extends StatelessWidget {
  const _RideProgress({required this.status});

  final String status;

  int get _currentStep {
    return switch (status) {
      RideStatuses.driverConfirmed => 0,
      RideStatuses.driverOnTheWay => 1,
      RideStatuses.driverArrived => 2,
      RideStatuses.tripStarted => 3,
      _ => 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    const labels = ['تأكيد', 'في الطريق', 'الوصول', 'بدء الرحلة'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++) ...[
            Expanded(
              child: Column(
                children: [
                  Icon(
                    index <= _currentStep
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: index <= _currentStep ? _emerald : _muted,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: index <= _currentStep ? _dark : _muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (index < labels.length - 1)
              Container(
                width: 18,
                height: 2,
                color: index < _currentStep ? _emerald : _line,
              ),
          ],
        ],
      ),
    );
  }
}
