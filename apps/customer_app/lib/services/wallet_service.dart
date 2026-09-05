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
}
