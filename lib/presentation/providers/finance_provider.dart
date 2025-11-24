import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../data/repositories/finance_repository_impl.dart';
import '../../domain/repositories/finance_repository.dart';
import 'database_provider.dart';
import 'auth_provider.dart';
import 'product_provider.dart';

final financeRepositoryProvider = Provider<FinanceRepositoryImpl>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final database = ref.watch(databaseProvider);
  return FinanceRepositoryImpl(apiClient, database);
});

final financeSummaryProvider = FutureProvider<FinanceSummary>((ref) async {
  final repository = ref.watch(financeRepositoryProvider);
  final result = await repository.getFinanceSummary();
  
  return result.when(
    success: (summary) => summary,
    failure: (_) => FinanceSummary(
      monthlySpending: 0,
      totalPaid: 0,
      totalDue: 0,
      paymentPercentage: 0,
      recentTransactions: [],
    ),
  );
});

final transactionsProvider = FutureProvider<List<TransactionModel>>((ref) async {
  final repository = ref.watch(financeRepositoryProvider);
  final result = await repository.getTransactions();
  
  return result.when(
    success: (transactions) => transactions,
    failure: (_) => [],
  );
});

