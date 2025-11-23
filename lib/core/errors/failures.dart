import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';

@freezed
class Failure with _$Failure {
  const factory Failure.server({
    required String message,
    int? statusCode,
  }) = ServerFailure;
  
  const factory Failure.network({
    required String message,
  }) = NetworkFailure;
  
  const factory Failure.cache({
    required String message,
  }) = CacheFailure;
  
  const factory Failure.unauthorized({
    required String message,
  }) = UnauthorizedFailure;
  
  const factory Failure.validation({
    required String message,
  }) = ValidationFailure;
  
  const factory Failure.unknown({
    required String message,
  }) = UnknownFailure;
}

extension FailureExtension on Failure {
  String get userMessage {
    return when(
      server: (message, _) => message,
      network: (message) => 'Network error: $message',
      cache: (message) => 'Storage error: $message',
      unauthorized: (message) => 'Authentication required: $message',
      validation: (message) => 'Invalid input: $message',
      unknown: (message) => 'An error occurred: $message',
    );
  }
}

