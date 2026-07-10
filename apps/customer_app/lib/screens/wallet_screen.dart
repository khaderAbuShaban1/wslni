import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_model.dart';
import '../models/wallet_model.dart';
import '../services/api_client.dart';
import '../services/wallet_service.dart';
import '../utils/constants.dart';
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

  late Future<WalletSummary> _walletFuture;

  @override
  void initState() {
    super.initState();
    _walletFuture = _walletService.getWallet(widget.user.id);
  }

  void _reload() {
    setState(() {
      _walletFuture = _walletService.getWallet(widget.user.id);
    });
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddBalanceSheet(
        userId: widget.user.id,
        accounts: wallet.paymentAccounts,
      ),
    );

    if (submitted == true) {
      _message('تم إرسال إشعار الدفع وبانتظار مراجعة الإدارة.');
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
      trailing: IconButton(
        tooltip: 'تحديث',
        onPressed: _reload,
        icon: const Icon(Icons.refresh_rounded),
      ),
      child: FutureBuilder<WalletSummary>(
        future: _walletFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError) {
            return _WalletErrorCard(onRetry: _reload);
          }

          final wallet =
              snapshot.data ??
              WalletSummary(
                balance: widget.user.walletBalance,
                paymentAccounts: const [],
                deposits: const [],
              );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PremiumCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'رصيدك الحالي',
                      style: TextStyle(
                        color: mutedText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${wallet.balance.toStringAsFixed(2)} ₪',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
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
                  ],
                ),
              ),
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
              if (wallet.deposits.isEmpty)
                const _EmptyWalletMessage(
                  icon: Icons.receipt_long_outlined,
                  title: 'لا توجد إشعارات دفع',
                  message: 'بعد رفع إشعار الدفع سيظهر الطلب هنا.',
                )
              else
                ...wallet.deposits.map(_DepositTile.new),
            ],
          );
        },
      ),
    );
  }
}

class _AddBalanceSheet extends StatefulWidget {
  const _AddBalanceSheet({required this.userId, required this.accounts});

  final int userId;
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
        userId: widget.userId,
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
          color: selected ? const Color(0xFFEFFDF5) : Colors.white,
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
              backgroundColor: lightGray,
              child: Icon(
                account.type == 'bank'
                    ? Icons.account_balance_rounded
                    : Icons.account_balance_wallet_rounded,
                color: darkText,
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
    backgroundColor: Colors.white,
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

class _DepositTile extends StatelessWidget {
  const _DepositTile(this.deposit);

  final WalletDeposit deposit;

  @override
  Widget build(BuildContext context) {
    final color = switch (deposit.status) {
      'approved' => emerald,
      'rejected' => Colors.redAccent,
      _ => Colors.orange,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderGray),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(Icons.receipt_long_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${deposit.amount.toStringAsFixed(2)} ₪',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  deposit.paymentAccountName,
                  style: const TextStyle(color: mutedText),
                ),
                if (deposit.referenceNumber != null)
                  Text(
                    'مرجع: ${deposit.referenceNumber}',
                    style: const TextStyle(color: mutedText, fontSize: 12),
                  ),
              ],
            ),
          ),
          Text(
            deposit.statusLabel,
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderGray),
      ),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: lightGray,
            child: Icon(icon, color: darkText),
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
