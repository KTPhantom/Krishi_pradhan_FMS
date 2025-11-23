import 'package:freezed_annotation/freezed_annotation.dart';
import '../errors/failures.dart';

part 'result.freezed.dart';

@freezed
class Result<T> with _$Result<T> {
  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(Failure failure) = FailureResult<T>;
}

extension ResultExtension<T> on Result<T> {
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is FailureResult<T>;
  
  T? get dataOrNull => when(
    success: (data) => data,
    failure: (_) => null,
  );
  
  Failure? get failureOrNull => when(
    success: (_) => null,
    failure: (failure) => failure,
  );
}

