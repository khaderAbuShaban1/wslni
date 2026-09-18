import 'dart:async';
import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_model.dart';
import '../models/wallet_model.dart';
import '../services/api_client.dart';
import '../services/wallet_service.dart';
import '../utils/constants.dart';
import '../utils/firebase_runtime.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/premium_card.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({required this.user, this.showBack = true, super.key});

  final AppUser user;
  final bool showBack;

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _walletService = WalletService();
  StreamSubscription<DatabaseEvent>? _depositsSub;
  StreamSubscription<DatabaseEvent>? _withdrawalsSub;

  WalletSummary? _wallet;
  Object? _loadError;
  int _loadRequest = 0;

  @override
  void initState() {
    super.initState();
    _reload();
    _listenToDeposits();
  }

  @override
  void dispose() {
    _depositsSub?.cancel();
    _withdrawalsSub?.cancel();
    super.dispose();
  }

  void _listenToDeposits() {
    if (!FirebaseRuntime.isReady) return;
    final uid = widget.user.id;
    if (uid == 0) return;
    _depositsSub = FirebaseDatabase.instance
        .ref('users/$uid/deposits')
        .onValue
        .skip(1)
        .listen((_) => _reload());
    _withdrawalsSub = FirebaseDatabase.instance
        .ref('users/$uid/withdrawals')
        .onValue
        .skip(1)
        .listen((_) => _reload());
  }

  Future<void> _reload() async {
    final request = ++_loadRequest;
    if (_wallet == null && _loadError != null) {
      setState(() => _loadError = null);
    }
    try {
      final wallet = await _walletService.getWallet();
      // A deposit and a withdrawal update can land together; only the newest
      // response may win, or an older one could overwrite fresher data.
      if (!mounted || request != _loadRequest) return;
      setState(() {
        _wallet = wallet;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted || request != _loadRequest) return;
      // With data already shown, a failed background refresh keeps it rather
      // than replacing the whole wallet with an error.
      setState(() => _loadError = error);
    }
  }

  Future<void> _openAddBalance(WalletSummary wallet) async {
    if (wallet.paymentAccounts.isEmpty) {
      _message('لا توجد طرق دفع متاحة حاليًا.');
      return;
    }

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddBalanceSheet(accounts: wallet.paymentAccounts),
    );

    if (submitted == true) {
      _message('تم إرسال إشعار الدفع وبانتظار مراجعة الإدارة.');
      _reload();
    }
  }

  Future<void> _openWithdrawal(WalletSummary wallet) async {
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _WithdrawalSheet(balance: wallet.balance),
    );

    if (submitted == true) {
      _message('تم إرسال طلب السحب وبانتظار مراجعة الإدارة.');
      _reload();
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'المحفظة',
      showBack: widget.showBack,
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    final wallet = _wallet;
    // The spinner is only for the very first load. Later refreshes keep the
    // last wallet on screen and swap it in place when the new data arrives.
    if (wallet == null) {
      if (_loadError != null) return _WalletErrorCard(onRetry: _reload);
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'رصيدك الحالي',
                style: TextStyle(color: mutedText, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(
                '${wallet.balance.toStringAsFixed(2)} ₪',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: emerald,
                ),
              ),
              const SizedBox(height: 18),
              CustomButton(
                label: 'إضافة رصيد',
                icon: Icons.add_card_rounded,
                onPressed: () => _openAddBalance(wallet),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: wallet.balance <= 0
                    ? null
                    : () => _openWithdrawal(wallet),
                icon: const Icon(Icons.savings_outlined),
                label: const Text('سحب الرصيد'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _SectionTitle(
          title: 'سجل الحركات',
          subtitle: 'كل ما دخل محفظتك وخرج منها، والرصيد بعد كل حركة.',
        ),
        const SizedBox(height: 10),
        _MovementList(movements: wallet.movements),
        const SizedBox(height: 18),
        _SectionTitle(
          title: 'طرق الدفع المتاحة',
          subtitle: 'اختر إحدى هذه الحسابات عند شحن المحفظة.',
        ),
        const SizedBox(height: 10),
        if (wallet.paymentAccounts.isEmpty)
          const _EmptyWalletMessage(
            icon: Icons.account_balance_outlined,
            title: 'لا توجد طرق دفع',
            message: 'ستظهر هنا الحسابات التي يضيفها الأدمن.',
          )
        else
          ...wallet.paymentAccounts.map(_PaymentAccountCard.new),
        const SizedBox(height: 18),
        _SectionTitle(
          title: 'آخر طلبات الشحن',
          subtitle: 'الإيداعات المعتمدة تضيف الرصيد تلقائيًا.',
        ),
        const SizedBox(height: 10),
        _RecordList(
          records: wallet.deposits.map(_Record.fromDeposit).toList(),
          allTitle: 'جميع طلبات الشحن',
          empty: const _EmptyWalletMessage(
            icon: Icons.receipt_long_outlined,
            title: 'لا توجد إشعارات دفع',
            message: 'بعد رفع إشعار الدفع سيظهر الطلب هنا.',
          ),
        ),
        const SizedBox(height: 18),
        _SectionTitle(
          title: 'سجل السحب',
          subtitle: 'المبلغ يُحجز عند الطلب، ويعود لمحفظتك إذا رُفض.',
        ),
        const SizedBox(height: 10),
        _RecordList(
          records: wallet.withdrawals.map(_Record.fromWithdrawal).toList(),
          allTitle: 'جميع طلبات السحب',
          empty: const _EmptyWalletMessage(
            icon: Icons.savings_outlined,
            title: 'لا توجد طلبات سحب',
            message: 'عند طلب سحب رصيدك سيظهر هنا مع حالته.',
          ),
        ),
      ],
    );
  }
}

class _AddBalanceSheet extends StatefulWidget {
  const _AddBalanceSheet({required this.accounts});

  final List<WalletPaymentAccount> accounts;

  @override
  State<_AddBalanceSheet> createState() => _AddBalanceSheetState();
}

class _AddBalanceSheetState extends State<_AddBalanceSheet> {
  final _walletService = WalletService();
  final _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  final _note = TextEditingController();

  WalletPaymentAccount? _selected;
  File? _receipt;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.accounts.first;
  }

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) return;
    setState(() => _receipt = File(image.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final selected = _selected;
    final receipt = _receipt;
    if (selected == null) {
      _message('اختر طريقة الدفع أولًا.');
      return;
    }
    if (receipt == null) {
      _message('أرفق صورة إشعار الدفع.');
      return;
    }

    setState(() => _submitting = true);
    try {
      await _walletService.submitDeposit(
        paymentAccountId: selected.id,
        amount: _amount.text.trim(),
        referenceNumber: _reference.text,
        note: _note.text,
        receipt: receipt,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      _message(error.message);
    } on SocketException {
      _message('تعذر الاتصال بالخادم. تأكد أن Laravel يعمل على المنفذ 8000.');
    } catch (_) {
      _message('حدث خطأ غير متوقع أثناء إرسال الإشعار.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: borderGray,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'إضافة رصيد',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'اختر طريقة الدفع أولًا، ثم حوّل المبلغ وارفع صورة إشعار الدفع.',
                style: TextStyle(color: mutedText, height: 1.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'طرق الدفع',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              ...widget.accounts.map(
                (account) => _SelectablePaymentAccount(
                  account: account,
                  selected: _selected?.id == account.id,
                  onTap: () => setState(() => _selected = account),
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _amount,
                label: 'المبلغ',
                icon: Icons.payments_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');
                  if (amount == null || amount < 1) {
                    return 'أدخل مبلغًا صحيحًا.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _reference,
                label: 'رقم العملية / المرجع',
                icon: Icons.tag_rounded,
                hintText: 'اختياري',
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _note,
                label: 'ملاحظة',
                icon: Icons.notes_rounded,
                hintText: 'اختياري',
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  foregroundColor: darkText,
                  side: const BorderSide(color: borderGray),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: _submitting ? null : _pickReceipt,
                icon: const Icon(Icons.upload_file_rounded),
                label: Text(
                  _receipt == null
                      ? 'إرفاق إشعار الدفع'
                      : 'تم اختيار: ${_receipt!.uri.pathSegments.last}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 18),
              CustomButton(
                label: _submitting ? 'جاري الإرسال...' : 'إرسال طلب الشحن',
                icon: Icons.check_circle_outline_rounded,
                onPressed: _submitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentAccountCard extends StatelessWidget {
  const _PaymentAccountCard(this.account);

  final WalletPaymentAccount account;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: 16,
      child: _PaymentAccountDetails(account: account, showInvoiceAction: true),
    );
  }
}

class _SelectablePaymentAccount extends StatelessWidget {
  const _SelectablePaymentAccount({
    required this.account,
    required this.selected,
    required this.onTap,
  });

  final WalletPaymentAccount account;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? emerald : borderGray,
            width: 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? emerald : mutedText,
            ),
            const SizedBox(width: 12),
            Expanded(child: _PaymentAccountDetails(account: account)),
          ],
        ),
      ),
    );
  }
}

class _PaymentAccountDetails extends StatelessWidget {
  const _PaymentAccountDetails({
    required this.account,
    this.showInvoiceAction = false,
  });

  final WalletPaymentAccount account;
  final bool showInvoiceAction;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('صاحب الحساب', account.accountHolderName),
      if (account.accountNumber != null) ('رقم الحساب', account.accountNumber!),
      if (account.phoneNumber != null) ('رقم الجوال', account.phoneNumber!),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: .15),
              child: Icon(
                account.type == 'bank'
                    ? Icons.account_balance_rounded
                    : Icons.account_balance_wallet_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    account.typeLabel,
                    style: const TextStyle(color: mutedText, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...rows.map(
          (row) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 92,
                  child: Text(row.$1, style: const TextStyle(color: mutedText)),
                ),
                Expanded(
                  child: SelectableText(
                    row.$2,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (account.instructions != null) ...[
          const SizedBox(height: 4),
          Text(
            account.instructions!,
            style: const TextStyle(color: mutedText, height: 1.45),
          ),
        ],
        if (showInvoiceAction) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: darkText,
              side: const BorderSide(color: borderGray),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => _openPaymentAccountInvoice(context, account),
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('استخراج فاتورة'),
          ),
        ],
      ],
    );
  }
}

void _openPaymentAccountInvoice(
  BuildContext context,
  WalletPaymentAccount account,
) {
  showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _PaymentAccountInvoiceSheet(account: account),
  );
}

class _PaymentAccountInvoiceSheet extends StatelessWidget {
  const _PaymentAccountInvoiceSheet({required this.account});

  final WalletPaymentAccount account;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('رقم الفاتورة', account.invoiceNumber),
      ('طريقة الدفع', account.name),
      ('النوع', account.typeLabel),
      ('صاحب الحساب', account.accountHolderName),
      if (account.accountNumber != null)
        ('رقم الحساب / IBAN', account.accountNumber!),
      if (account.phoneNumber != null)
        ('رقم الجوال / المحفظة', account.phoneNumber!),
      if (account.instructions != null) ('التعليمات', account.instructions!),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: borderGray,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'فاتورة طريقة دفع',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'يمكنك نسخ بيانات الفاتورة وإرسالها أو حفظها خارج التطبيق.',
              style: TextStyle(color: mutedText, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: lightGray,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderGray),
              ),
              child: Column(
                children: rows
                    .map(
                      (row) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 116,
                              child: Text(
                                row.$1,
                                style: const TextStyle(color: mutedText),
                              ),
                            ),
                            Expanded(
                              child: SelectableText(
                                row.$2,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            CustomButton(
              label: 'نسخ الفاتورة',
              icon: Icons.copy_rounded,
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: account.invoiceText),
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم نسخ الفاتورة.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(color: mutedText)),
      ],
    );
  }
}

class _WalletErrorCard extends StatelessWidget {
  const _WalletErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _EmptyWalletMessage(
      icon: Icons.wifi_off_rounded,
      title: 'تعذر تحميل المحفظة',
      message: 'تأكد أن Laravel يعمل وأن الهاتف متصل بنفس الشبكة.',
      action: OutlinedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('إعادة المحاولة'),
      ),
    );
  }
}

class _EmptyWalletMessage extends StatelessWidget {
  const _EmptyWalletMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: .15),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 25,
            ),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: mutedText, height: 1.5),
          ),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    );
  }
}

class _WithdrawalSheet extends StatefulWidget {
  const _WithdrawalSheet({required this.balance});

  final double balance;

  @override
  State<_WithdrawalSheet> createState() => _WithdrawalSheetState();
}

class _WithdrawalSheetState extends State<_WithdrawalSheet> {
  final _walletService = WalletService();
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _accountName = TextEditingController();
  final _accountNumber = TextEditingController();

  String _method = 'mobile_wallet';
  bool _submitting = false;

  @override
  void dispose() {
    _amount.dispose();
    _accountName.dispose();
    _accountNumber.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      await _walletService.requestWithdrawal(
        amount: _amount.text.trim(),
        method: _method,
        accountName: _accountName.text.trim(),
        accountNumber: _accountNumber.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      _message(error.message);
    } on SocketException {
      _message('تعذر الاتصال بالخادم. حاول مرة أخرى.');
    } catch (_) {
      _message('حدث خطأ غير متوقع أثناء إرسال الطلب.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: borderGray,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'سحب الرصيد',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'المتاح للسحب: ${widget.balance.toStringAsFixed(2)} ₪. '
                'يُحجز المبلغ فور الطلب، ويُعاد إلى محفظتك إذا رُفض.',
                style: const TextStyle(color: mutedText, height: 1.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'طريقة التحويل',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
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
                selected: {_method},
                onSelectionChanged: (value) =>
                    setState(() => _method = value.first),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _amount,
                label: 'المبلغ',
                icon: Icons.payments_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');
                  if (amount == null || amount <= 0) {
                    return 'أدخل مبلغًا صحيحًا.';
                  }
                  if (amount > widget.balance) {
                    return 'المبلغ أكبر من رصيدك المتاح.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _accountName,
                label: 'اسم صاحب الحساب',
                icon: Icons.person_outline_rounded,
                validator: (value) =>
                    (value?.trim().isEmpty ?? true) ? 'الاسم مطلوب.' : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _accountNumber,
                label: 'رقم الحساب أو الجوال',
                icon: Icons.numbers_rounded,
                validator: (value) =>
                    (value?.trim().isEmpty ?? true) ? 'الرقم مطلوب.' : null,
              ),
              const SizedBox(height: 18),
              CustomButton(
                label: _submitting ? 'جاري الإرسال...' : 'إرسال طلب السحب',
                icon: Icons.send_rounded,
                onPressed: _submitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One row of wallet history, so deposits and withdrawals share one card.
class _Record {
  const _Record({
    required this.amount,
    required this.subtitle,
    required this.label,
    required this.outcome,
    this.createdAt,
  });

  factory _Record.fromDeposit(WalletDeposit deposit) => _Record(
    amount: deposit.amount,
    subtitle: [
      deposit.paymentAccountName,
      if (deposit.referenceNumber != null) 'مرجع: ${deposit.referenceNumber}',
    ].join(' · '),
    label: deposit.statusLabel,
    outcome: _outcome(deposit.status, success: 'approved'),
    createdAt: deposit.createdAt,
  );

  factory _Record.fromWithdrawal(CustomerWithdrawal withdrawal) => _Record(
    amount: withdrawal.amount,
    subtitle: '${withdrawal.methodLabel} · ${withdrawal.accountNumber}',
    label: withdrawal.statusLabel,
    outcome: _outcome(withdrawal.status, success: 'paid'),
    createdAt: withdrawal.createdAt,
  );

  final double amount;
  final String subtitle;
  final String label;
  final _Outcome outcome;
  final DateTime? createdAt;

  static _Outcome _outcome(String status, {required String success}) {
    if (status == success) return _Outcome.done;
    if (status == 'rejected') return _Outcome.rejected;
    return _Outcome.pending;
  }
}

enum _Outcome { pending, done, rejected }

/// Matches the driver app's withdrawal card: tinted by status.
class _StatusRecordCard extends StatelessWidget {
  const _StatusRecordCard({required this.record});

  final _Record record;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (record.outcome) {
      _Outcome.done => (successColor, Icons.check_circle_rounded),
      _Outcome.rejected => (errorColor, Icons.cancel_rounded),
      _Outcome.pending => (warningColor, Icons.schedule_rounded),
    };
    final date = record.createdAt?.toLocal();

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
                  '${record.amount.toStringAsFixed(2)} ₪',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  record.subtitle,
                  style: const TextStyle(color: mutedText, fontSize: 12),
                ),
                if (date != null)
                  Text(
                    '${date.year}-${_two(date.month)}-${_two(date.day)} '
                    '${_two(date.hour)}:${_two(date.minute)}',
                    style: const TextStyle(color: mutedText, fontSize: 11),
                  ),
              ],
            ),
          ),
          Text(
            record.label,
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

  static String _two(int value) => value.toString().padLeft(2, '0');
}

/// The latest few records, with the rest one tap away — as in the driver app.
class _RecordList extends StatelessWidget {
  const _RecordList({
    required this.records,
    required this.allTitle,
    required this.empty,
  });

  final List<_Record> records;
  final String allTitle;
  final Widget empty;

  static const _preview = 3;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return empty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final record in records.take(_preview)) ...[
          _StatusRecordCard(record: record),
          const SizedBox(height: 8),
        ],
        if (records.length > _preview)
          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      _AllRecordsPage(title: allTitle, records: records),
                ),
              ),
              icon: const Icon(Icons.expand_more_rounded),
              label: Text('عرض جميع الطلبات (${records.length})'),
            ),
          ),
      ],
    );
  }
}

class _AllRecordsPage extends StatelessWidget {
  const _AllRecordsPage({required this.title, required this.records});

  final String title;
  final List<_Record> records;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
        itemCount: records.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _StatusRecordCard(record: records[i]),
      ),
    );
  }
}

/// The latest balance changes, with the full statement one tap away.
class _MovementList extends StatelessWidget {
  const _MovementList({required this.movements});

  final List<WalletMovement> movements;

  static const _preview = 5;

  @override
  Widget build(BuildContext context) {
    if (movements.isEmpty) {
      return const _EmptyWalletMessage(
        icon: Icons.swap_vert_rounded,
        title: 'لا توجد حركات بعد',
        message: 'أي شحن أو دفع أو سحب من محفظتك سيظهر هنا.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final movement in movements.take(_preview)) ...[
          _MovementTile(movement: movement),
          const SizedBox(height: 8),
        ],
        if (movements.length > _preview)
          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _AllMovementsPage(movements: movements),
                ),
              ),
              icon: const Icon(Icons.expand_more_rounded),
              label: Text('عرض كل الحركات (${movements.length})'),
            ),
          ),
      ],
    );
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({required this.movement});

  final WalletMovement movement;

  @override
  Widget build(BuildContext context) {
    final incoming = movement.isIncoming;
    final color = incoming ? successColor : errorColor;
    final date = movement.createdAt?.toLocal();
    final sign = incoming ? '+' : '−';
    final lines = [
      if (movement.detail != null) movement.detail!,
      if (date != null)
        '${date.year}-${_two(date.month)}-${_two(date.day)} '
            '${_two(date.hour)}:${_two(date.minute)}',
    ];

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
            child: Icon(
              incoming
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: color,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.label,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                for (final line in lines)
                  Text(
                    line,
                    style: const TextStyle(color: mutedText, fontSize: 12),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign${movement.amount.abs().toStringAsFixed(2)} ₪',
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
              if (movement.balanceAfter != null)
                Text(
                  'الرصيد ${movement.balanceAfter!.toStringAsFixed(2)} ₪',
                  style: const TextStyle(color: mutedText, fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}

class _AllMovementsPage extends StatelessWidget {
  const _AllMovementsPage({required this.movements});

  final List<WalletMovement> movements;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سجل الحركات')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
        itemCount: movements.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _MovementTile(movement: movements[i]),
      ),
    );
  }
}
