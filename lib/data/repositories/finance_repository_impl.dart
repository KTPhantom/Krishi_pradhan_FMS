import '../../core/network/api_client.dart';
import '../../core/utils/result.dart';
import '../../core/errors/failures.dart';
import '../../core/constants/api_constants.dart';
import '../../data/database/app_database.dart';
import '../../domain/repositories/finance_repository.dart';

class FinanceRepositoryImpl implements FinanceRepository {
  final ApiClient _apiClient;
  // Database will be used for caching transactions in future
  // ignore: unused_field
  final AppDatabase _database;

  FinanceRepositoryImpl(this._apiClient, this._database);

  @override
  Future<Result<FinanceSummary>> getFinanceSummary({
    DateTime? month,
    bool forceRefresh = false,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (month != null) {
        queryParams['month'] = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      }

      final result = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConstants.transactions}/summary',
        queryParameters: queryParams.isEmpty ? null : queryParams,
        fromJson: (data) => data as Map<String, dynamic>,
      );

      return result.when(
        success: (data) {
          final summary = FinanceSummary(
            monthlySpending: (data['monthly_spending'] as num).toDouble(),
            totalPaid: (data['total_paid'] as num).toDouble(),
            totalDue: (data['total_due'] as num).toDouble(),
            paymentPercentage: (data['payment_percentage'] as num).toDouble(),
            recentTransactions: (data['recent_transactions'] as List)
                .map((json) => TransactionModelJson.fromJson(json as Map<String, dynamic>))
                .toList(),
          );
          return Result.success(summary);
        },
        failure: (failure) {
          // Return mock data for now
          return Result.success(FinanceSummary(
            monthlySpending: 36756.0,
            totalPaid: 29406.0,
            totalDue: 7450.0,
            paymentPercentage: 80.0,
            recentTransactions: [],
          ));
        },
      );
    } catch (e) {
      // Return mock data on error
      return Result.success(FinanceSummary(
        monthlySpending: 36756.0,
        totalPaid: 29406.0,
        totalDue: 7450.0,
        paymentPercentage: 80.0,
        recentTransactions: [],
      ));
    }
  }

  @override
  Future<Result<List<TransactionModel>>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    bool forceRefresh = false,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String().split('T')[0];
      }
      if (category != null) {
        queryParams['category'] = category;
      }

      final result = await _apiClient.get<List<TransactionModel>>(
        ApiConstants.transactions,
        queryParameters: queryParams.isEmpty ? null : queryParams,
        fromJson: (data) {
          if (data is List) {
            return data.map((json) => TransactionModelJson.fromJson(json as Map<String, dynamic>)).toList();
          }
          return [];
        },
      );

      return result.when(
        success: (transactions) => Result.success(transactions),
        failure: (_) {
          // Return mock data
          return Result.success(_getMockTransactions());
        },
      );
    } catch (e) {
      return Result.success(_getMockTransactions());
    }
  }

  @override
  Future<Result<TransactionModel>> getTransactionById(String id) async {
    try {
      final result = await _apiClient.get<TransactionModel>(
        '${ApiConstants.transactions}/$id',
        fromJson: (data) => TransactionModelJson.fromJson(data as Map<String, dynamic>),
      );
      return result;
    } catch (e) {
      return Result.failure(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Result<TransactionModel>> createTransaction(TransactionModel transaction) async {
    try {
      final result = await _apiClient.post<TransactionModel>(
        ApiConstants.transactions,
        data: TransactionModelJson.toJson(transaction),
        fromJson: (data) => TransactionModelJson.fromJson(data as Map<String, dynamic>),
      );
      return result;
    } catch (e) {
      return Result.failure(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteTransaction(String id) async {
    try {
      final result = await _apiClient.delete('${ApiConstants.transactions}/$id');
      return result;
    } catch (e) {
      return Result.failure(Failure.unknown(message: e.toString()));
    }
  }

  List<TransactionModel> _getMockTransactions() {
    return [
      TransactionModel(
        id: '1',
        title: 'Pesticide',
        amount: 1610.0,
        date: DateTime.now().subtract(const Duration(days: 2)),
        category: 'Supplies',
      ),
      TransactionModel(
        id: '2',
        title: 'Water Pump',
        amount: 6150.0,
        date: DateTime.now().subtract(const Duration(days: 5)),
        category: 'Equipment',
      ),
      TransactionModel(
        id: '3',
        title: 'Greenhouse Repair',
        amount: 4696.0,
        date: DateTime.now().subtract(const Duration(days: 7)),
        category: 'Maintenance',
      ),
    ];
  }
}

// Helper class for JSON serialization
class TransactionModelJson {
  static Map<String, dynamic> toJson(TransactionModel model) {
    return {
      'id': model.id,
      'title': model.title,
      'amount': model.amount,
      'date': model.date.toIso8601String(),
      'category': model.category,
      'description': model.description,
    };
  }

  static TransactionModel fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      category: json['category'] as String,
      description: json['description'] as String?,
    );
  }
}

