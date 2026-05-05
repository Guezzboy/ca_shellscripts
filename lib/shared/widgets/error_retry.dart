import 'package:flutter/material.dart';

/// A simple error display with a retry button.
/// Used in .when(error:) callbacks across the app.
class ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorRetry({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 36, color: Colors.red.shade300),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade700, fontSize: 13),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
