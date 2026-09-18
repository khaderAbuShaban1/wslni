import 'dart:io';

import '../models/wallet_model.dart';
import 'api_client.dart';

class WalletService {
  WalletService({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;

  Future<WalletSummary> getWallet() async {
    final result = await _api.get('customers/me/wallet');
    return WalletSummary.fromJson(result);
  }

  Future<WalletDeposit> submitDeposit({
    required int paymentAccountId,
    required String amount,
    required File receipt,
    String? referenceNumber,
    String? note,
  }) async {
    final fields = <String, String>{
      'amount': amount,
      'wallet_payment_account_id': paymentAccountId.toString(),
      if (referenceNumber != null && referenceNumber.trim().isNotEmpty)
        'reference_number': referenceNumber.trim(),
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    };

    final result = await _api.postMultipart(
      'customers/me/wallet/deposits',
      fields: fields,
      fileField: 'receipt_image',
      file: receipt,
    );
    return WalletDeposit.fromJson(result['deposit'] as Map<String, dynamic>);
  }

  Future<({double balance, List<CustomerWithdrawal> withdrawals})>
  getWithdrawals() async {
    final result = await _api.get('customers/me/withdrawals');
    final rows = result['withdrawals'];
    return (
      balance: double.tryParse(result['wallet_balance']?.toString() ?? '') ?? 0,
      withdrawals: rows is List
          ? rows
                .whereType<Map<String, dynamic>>()
                .map(CustomerWithdrawal.fromJson)
                .toList()
          : const <CustomerWithdrawal>[],
    );
  }

  Future<void> requestWithdrawal({
    required String amount,
    required String method,
    required String accountName,
    required String accountNumber,
  }) async {
    await _api.post('customers/me/withdrawals', {
      'amount': amount,
      'method': method,
      'account_name': accountName,
      'account_number': accountNumber,
    });
  }
}
