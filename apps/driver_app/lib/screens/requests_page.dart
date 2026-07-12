part of '../main.dart';

class RequestsPage extends StatefulWidget {
  const RequestsPage({required this.user, super.key});

  final DriverUser user;

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  final _api = ApiClient();
  final _realtime = RealtimeDriverService();
  late Stream<List<RideRequestItem>> _rideStream;

  @override
  void initState() {
    super.initState();
    _rideStream = _realtime.watchOpenRides();
  }

  Future<bool> _sendOffer(
    RideRequestItem ride,
    String price,
    String notes,
  ) async {
    if (price.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('اكتب سعر العرض أولًا')));
      return false;
    }
    try {
      final result = await _api.post('rides/${ride.id}/offers', {
        'driver_id': widget.user.id,
        'price': price,
        'notes': notes.isEmpty ? null : notes,
      });
      final offer = result['offer'];
      final offerMap = offer is Map ? offer : const {};
      await _realtime.sendOffer(
        ride: ride,
        driver: widget.user,
        offerId: int.tryParse(offerMap['id']?.toString() ?? '') ?? 0,
        price: price,
        notes: notes,
      );
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إرسال عرضك للزبون')));
      return true;
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
      return false;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر إرسال العرض. حاول مرة أخرى.')),
        );
      }
      return false;
    }
  }

  void _openOfferSheet(RideRequestItem ride) {
    final price = TextEditingController();
    final notes = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(
          18,
          18,
          18,
          MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'قدّم عرض سعر',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            _RouteSummaryBox(ride: ride),
            const SizedBox(height: 12),
            _CompetitorOffersPanel(ride: ride),
            const SizedBox(height: 12),
            TextField(
              controller: price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.payments_outlined),
                labelText: 'السعر',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: notes,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.notes),
                labelText: 'ملاحظات اختيارية',
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _emerald,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: () async {
                final sent = await _sendOffer(
                  ride,
                  price.text.trim(),
                  notes.text.trim(),
                );
                if (sent && context.mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.send),
              label: const Text('إرسال العرض'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RideRequestItem>>(
      stream: _rideStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SkeletonList();
        }
        if (snapshot.hasError) {
          return const _EmptyStateCard(
            icon: Icons.cloud_off_outlined,
            title: 'انقطع الاتصال المباشر',
            message: 'تحقق من اتصال Firebase ثم أعد فتح التطبيق.',
          );
        }
        return _RequestsList(
          rides: snapshot.data ?? const <RideRequestItem>[],
          onOffer: _openOfferSheet,
        );
      },
    );
  }
}

class _RequestsList extends StatelessWidget {
  const _RequestsList({required this.rides, required this.onOffer});

  final List<RideRequestItem> rides;
  final void Function(RideRequestItem ride) onOffer;

  @override
  Widget build(BuildContext context) {
    if (rides.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: const _EmptyStateCard(
            icon: Icons.local_taxi_outlined,
            title: 'لا توجد طلبات حاليًا',
            message: 'عندما يرسل الزبائن طلبات جديدة ستظهر هنا فورًا.',
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: rides.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Text(
            'طلبات الزبائن',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          );
        }
        final ride = rides[index - 1];
        return _RideRequestCard(ride: ride, onOffer: () => onOffer(ride));
      },
    );
  }
}
