import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction_model.dart';
import '../../../utils/constants.dart';

class TransactionLocalService {
  Box<TransactionModel> get _transactionBox => 
      Hive.box<TransactionModel>(AppConstants.transactionBox);

  // Add a new transaction
  Future<void> addTransaction(TransactionModel transaction) async {
    await _transactionBox.put(transaction.id, transaction);
  }

  // Get transactions for a user
  List<TransactionModel> getTransactionsForUser(String userId) {
    return _transactionBox.values
        .where((t) => t.userId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Update transaction status (e.g., for admin payout approval)
  Future<void> updateTransactionStatus(String id, TransactionStatus status) async {
    final t = _transactionBox.get(id);
    if (t != null) {
      await _transactionBox.put(id, t.copyWith(status: status));
    }
  }

  // Watch transactions for reactive updates
  Stream<BoxEvent> watchTransactions() {
    return _transactionBox.watch();
  }
}
