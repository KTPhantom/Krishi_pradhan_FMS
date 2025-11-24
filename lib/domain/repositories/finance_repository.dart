import '../../core/utils/result.dart';

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final String? description;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.description,
  });
}

class FinanceSummary {
  final double monthlySpending;
  final double totalPaid;
  final double totalDue;
  final double paymentPercentage;
  final List<TransactionModel> recentTransactions;

  FinanceSummary({
    required this.monthlySpending,
    required this.totalPaid,
    required this.totalDue,
    required this.paymentPercentage,
    required this.recentTransactions,
  });
}

abstract class FinanceRepository {
  Future<Result<FinanceSummary>> getFinanceSummary({
    DateTime? month,
    bool forceRefresh = false,
  });
  
  Future<Result<List<TransactionModel>>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    bool forceRefresh = false,
  });
  
  Future<Result<TransactionModel>> getTransactionById(String id);
  
  Future<Result<TransactionModel>> createTransaction(TransactionModel transaction);
  
  Future<Result<void>> deleteTransaction(String id);
}

