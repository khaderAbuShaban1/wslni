class WalletPaymentAccount {
  const WalletPaymentAccount({
    required this.id,
    required this.type,
    required this.invoiceNumber,
    required this.name,
    required this.accountHolderName,
    this.accountNumber,
    this.phoneNumber,
    this.instructions,
  });

  final int id;
  final String type;
  final String invoiceNumber;
  final String name;
  final String accountHolderName;
  final String? accountNumber;
  final String? phoneNumber;
  final String? instructions;

  factory WalletPaymentAccount.fromJson(Map<String, dynamic> json) {
    final id = int.tryParse(json['id']?.toString() ?? '') ?? 0;

    return WalletPaymentAccount(
      id: id,
      type: json['type']?.toString() ?? 'bank',
      invoiceNumber:
          json['invoice_number']?.toString() ?? _defaultInvoiceNumber(id),
      name: json['name']?.toString() ?? '',
      accountHolderName: json['account_holder_name']?.toString() ?? '',
      accountNumber: _stringOrNull(json['account_number']),
      phoneNumber: _stringOrNull(json['phone_number']),
      instructions: _stringOrNull(json['instructions']),
    );
  }

  String get typeLabel {
    return switch (type) {
      'bank' => 'حساب بنكي',
      'mobile_wallet' => 'محفظة إلكترونية',
      _ => 'طريقة دفع',
    };
  }

  String get invoiceText {
    final lines = [
      'فاتورة طريقة دفع',
      'رقم الفاتورة: $invoiceNumber',
      'طريقة الدفع: $name',
      'النوع: $typeLabel',
      'صاحب الحساب: $accountHolderName',
      if (accountNumber != null) 'رقم الحساب / IBAN: $accountNumber',
      if (phoneNumber != null) 'رقم الجوال / المحفظة: $phoneNumber',
      if (instructions != null) 'التعليمات: $instructions',
    ];

    return lines.join('\n');
  }
}

class WalletDeposit {
  const WalletDeposit({
    required this.id,
    required this.amount,
    required this.paymentAccountName,
    required this.status,
    this.referenceNumber,
    this.note,
    this.createdAt,
  });

  final int id;
  final double amount;
  final String paymentAccountName;
  final String status;
  final String? referenceNumber;
  final String? note;
  final DateTime? createdAt;

  factory WalletDeposit.fromJson(Map<String, dynamic> json) {
    return WalletDeposit(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0,
      paymentAccountName: json['payment_account_name']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      referenceNumber: _stringOrNull(json['reference_number']),
      note: _stringOrNull(json['note']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  String get statusLabel {
    return switch (status) {
      'approved' => 'معتمد',
      'rejected' => 'مرفوض',
      _ => 'بانتظار المراجعة',
    };
  }
}

class WalletSummary {
  const WalletSummary({
    required this.balance,
    required this.paymentAccounts,
    required this.deposits,
    this.withdrawals = const [],
  });

  final double balance;
  final List<WalletPaymentAccount> paymentAccounts;
  final List<WalletDeposit> deposits;
  final List<CustomerWithdrawal> withdrawals;

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    return WalletSummary(
      balance: double.tryParse(json['wallet_balance']?.toString() ?? '') ?? 0,
      paymentAccounts: (json['payment_accounts'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(WalletPaymentAccount.fromJson)
          .toList(),
      deposits: (json['deposits'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(WalletDeposit.fromJson)
          .toList(),
      withdrawals: (json['withdrawals'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CustomerWithdrawal.fromJson)
          .toList(),
    );
  }
}

String? _stringOrNull(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

String _defaultInvoiceNumber(int id) {
  return 'WSL-PAY-${id.toString().padLeft(6, '0')}';
}

class CustomerWithdrawal {
  const CustomerWithdrawal({
    required this.id,
    required this.amount,
    required this.method,
    required this.accountName,
    required this.accountNumber,
    required this.status,
    this.createdAt,
  });

  final int id;
  final double amount;
  final String method;
  final String accountName;
  final String accountNumber;
  final String status;
  final DateTime? createdAt;

  factory CustomerWithdrawal.fromJson(Map<String, dynamic> json) {
    return CustomerWithdrawal(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0,
      method: json['method']?.toString() ?? 'mobile_wallet',
      accountName: json['account_name']?.toString() ?? '',
      accountNumber: json['account_number']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  String get methodLabel => method == 'bank' ? 'حساب بنكي' : 'محفظة جوال';

  String get statusLabel => switch (status) {
    'paid' => 'تم التحويل',
    'rejected' => 'مرفوض — أُعيد المبلغ',
    _ => 'بانتظار المراجعة',
  };
}
