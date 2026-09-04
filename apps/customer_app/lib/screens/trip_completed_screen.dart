import 'package:flutter/material.dart';

import '../models/ride_model.dart';
import '../services/api_client.dart';
import '../services/realtime_ride_service.dart';
import '../utils/constants.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/custom_button.dart';
import '../widgets/premium_card.dart';

class TripCompletedScreen extends StatefulWidget {
  const TripCompletedScreen({required this.draft, super.key});

  final RideDraft draft;

  @override
  State<TripCompletedScreen> createState() => _TripCompletedScreenState();
}

class _TripCompletedScreenState extends State<TripCompletedScreen> {
  int _rating = 5;
  final _comment = TextEditingController();
  final _api = ApiClient();
  final _realtime = RealtimeRideService();
  bool _saving = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _api.post('rides/${widget.draft.id}/rating', {
        'customer_id': widget.draft.customerId,
        'rating': _rating,
        'comment': _comment.text.trim().isEmpty ? null : _comment.text.trim(),
      });
      await _realtime.markRated(widget.draft.id, _rating, _comment.text.trim());
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: AppScaffold(
        showBack: true,
        title: 'اكتملت الرحلة',
        child: Column(
          children: [
            PremiumCard(
              child: Column(
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'وصلت بالسلامة',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.draft.destination,
                    style: const TextStyle(color: mutedText),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (index) => IconButton(
                        onPressed: () => setState(() => _rating = index + 1),
                        icon: Icon(
                          index < _rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: const Color(0xFFF59E0B),
                          size: 34,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _comment,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'تعليق اختياري',
                      prefixIcon: Icon(Icons.chat_bubble_outline),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: _saving ? 'جاري حفظ التقييم...' : 'إرسال التقييم',
              icon: Icons.star_rounded,
              onPressed: _saving ? null : _submitRating,
            ),
          ],
        ),
      ),
    );
  }
}
