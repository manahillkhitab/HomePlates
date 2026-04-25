import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/models/transaction_model.dart';
import '../data/local/services/transaction_local_service.dart';

final transactionService = Provider((ref) => TransactionLocalService());

class WalletState {
  final List<TransactionModel> transactions;
  final double balance;
  final double pendingWithdrawals;
  final double totalEarned;

  WalletState({
    required this.transactions,
    required this.balance,
    required this.pendingWithdrawals,
    required this.totalEarned,
  });

  factory WalletState.initial() => WalletState(
    transactions: [],
    balance: 0,
    pendingWithdrawals: 0,
    totalEarned: 0,
  );

  Map<DateTime, double> getWeeklyEarnings() {
    final Map<DateTime, double> weeklyData = {};
    final now = DateTime.now();

    // Initialize last 7 days with 0
    for (int i = 0; i < 7; i++) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      weeklyData[date] = 0;
    }

    for (var tx in transactions) {
      if (tx.type == TransactionType.earning &&
          tx.status == TransactionStatus.completed) {
        final date = DateTime(
          tx.createdAt.year,
          tx.createdAt.month,
          tx.createdAt.day,
        );
        if (weeklyData.containsKey(date)) {
          weeklyData[date] = (weeklyData[date] ?? 0) + tx.amount;
        }
      }
    }
    return weeklyData;
  }
}

final walletProvider =
    StateNotifierProvider.family<WalletNotifier, WalletState, String>((
      ref,
      userId,
    ) {
      return WalletNotifier(ref.watch(transactionService), userId);
    });

class WalletNotifier extends StateNotifier<WalletState> {
  final TransactionLocalService _service;
  final String _userId;

  WalletNotifier(this._service, this._userId) : super(WalletState.initial()) {
    _loadWallet();
  }

  void _loadWallet() {
    final transactions = _service.getTransactionsForUser(_userId);
    _calculateState(transactions);
  }

  void _calculateState(List<TransactionModel> transactions) {
    double balance = 0;
    double pending = 0;
    double total = 0;

    for (var tx in transactions) {
      if (tx.status == TransactionStatus.completed) {
        if (tx.type == TransactionType.earning ||
            tx.type == TransactionType.refund ||
            tx.type == TransactionType.topup) {
          balance += tx.amount;
          if (tx.type == TransactionType.earning) total += tx.amount;
        } else if (tx.type == TransactionType.withdrawal ||
            tx.type == TransactionType.penalty ||
            tx.type == TransactionType.payment) {
          balance -= tx.amount;
        }
      } else if (tx.status == TransactionStatus.pending) {
        if (tx.type == TransactionType.withdrawal) {
          pending += tx.amount;
        }
      }
    }

    state = WalletState(
      transactions: transactions,
      balance: balance,
      pendingWithdrawals: pending,
      totalEarned: total,
    );
  }

  Future<void> addEarning(double amount, String orderId) async {
    final transaction = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _userId,
      amount: amount,
      type: TransactionType.earning,
      status: TransactionStatus.completed,
      orderId: orderId,
      createdAt: DateTime.now(),
    );
    await _service.addTransaction(transaction);
    _loadWallet();
  }

  Future<void> issueRefund(double amount, String orderId) async {
    final transaction = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _userId,
      amount: amount,
      type: TransactionType.refund,
      status: TransactionStatus.completed,
      orderId: orderId,
      createdAt: DateTime.now(),
    );
    await _service.addTransaction(transaction);
    _loadWallet();
  }

  Future<void> applyPenalty(double amount, String orderId) async {
    final transaction = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _userId,
      amount: amount,
      type: TransactionType.penalty,
      status: TransactionStatus.completed,
      orderId: orderId,
      createdAt: DateTime.now(),
    );
    await _service.addTransaction(transaction);
    _loadWallet();
  }

  Future<bool> makePayment(double amount, String orderId) async {
    if (amount > state.balance) return false;

    final transaction = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _userId,
      amount: amount,
      type: TransactionType.payment, // This requires the enum update
      status: TransactionStatus.completed,
      orderId: orderId,
      createdAt: DateTime.now(),
    );
    await _service.addTransaction(transaction);
    _loadWallet();
    return true;
  }

  Future<bool> requestWithdrawal(double amount) async {
    if (amount > state.balance) return false;

    final transaction = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _userId,
      amount: amount,
      type: TransactionType.withdrawal,
      status: TransactionStatus.pending,
      createdAt: DateTime.now(),
    );
    await _service.addTransaction(transaction);
    _loadWallet();
    return true;
  }

  Future<void> topUp(double amount) async {
    final transaction = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _userId,
      amount: amount,
      type: TransactionType.topup,
      status: TransactionStatus.completed,
      createdAt: DateTime.now(),
    );
    await _service.addTransaction(transaction);
    _loadWallet();
  }
}
