import 'package:flutter/material.dart';
import '../../core/errors/failures.dart';

class AppErrorWidget extends StatelessWidget {
  final Failure failure;
  final VoidCallback? onRetry;
  
  const AppErrorWidget({
    super.key,
    required this.failure,
    this.onRetry,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getErrorIcon(),
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              failure.userMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  IconData _getErrorIcon() {
    return failure.when(
      server: (_, __) => Icons.cloud_off,
      network: (_) => Icons.wifi_off,
      cache: (_) => Icons.storage,
      unauthorized: (_) => Icons.lock,
      validation: (_) => Icons.error_outline,
      unknown: (_) => Icons.error,
    );
  }
}

