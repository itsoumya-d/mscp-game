import 'package:flutter/material.dart';

/// Error State Widget - Task B5
/// Friendly error screens with illustrations, explanations, and recovery actions
class ErrorStateWidget extends StatelessWidget {
  final ErrorType errorType;
  final String? customTitle;
  final String? customMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onGoHome;
  final bool showDetails;
  final String? technicalDetails;

  const ErrorStateWidget({
    Key? key,
    required this.errorType,
    this.customTitle,
    this.customMessage,
    this.onRetry,
    this.onGoHome,
    this.showDetails = false,
    this.technicalDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final errorInfo = _getErrorInfo(errorType);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: errorInfo.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                errorInfo.icon,
                size: 60,
                color: errorInfo.color,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              customTitle ?? errorInfo.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              customMessage ?? errorInfo.message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Action buttons
            if (onRetry != null || onGoHome != null)
              Column(
                children: [
                  if (onRetry != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  if (onRetry != null && onGoHome != null)
                    const SizedBox(height: 12),
                  if (onGoHome != null)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onGoHome,
                        icon: const Icon(Icons.home),
                        label: const Text('Go to Home'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                ],
              ),

            // Technical details (expandable)
            if (showDetails && technicalDetails != null) ...[
              const SizedBox(height: 24),
              ExpansionTile(
                title: const Text('Technical Details'),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      technicalDetails!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  _ErrorInfo _getErrorInfo(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return _ErrorInfo(
          icon: Icons.wifi_off,
          color: Colors.orange,
          title: 'No Internet Connection',
          message:
              'Please check your internet connection and try again. Make sure you\'re connected to Wi-Fi or mobile data.',
        );
      case ErrorType.server:
        return _ErrorInfo(
          icon: Icons.cloud_off,
          color: Colors.red,
          title: 'Server Error',
          message:
              'We\'re having trouble connecting to our servers. Please try again in a few moments.',
        );
      case ErrorType.notFound:
        return _ErrorInfo(
          icon: Icons.search_off,
          color: Colors.blue,
          title: 'Not Found',
          message:
              'We couldn\'t find what you\'re looking for. It may have been moved or deleted.',
        );
      case ErrorType.unauthorized:
        return _ErrorInfo(
          icon: Icons.lock,
          color: Colors.amber,
          title: 'Access Denied',
          message:
              'You don\'t have permission to access this content. Please sign in or contact support.',
        );
      case ErrorType.timeout:
        return _ErrorInfo(
          icon: Icons.timer_off,
          color: Colors.orange,
          title: 'Request Timeout',
          message:
              'The request took too long to complete. Please check your connection and try again.',
        );
      case ErrorType.unknown:
        return _ErrorInfo(
          icon: Icons.error_outline,
          color: Colors.grey,
          title: 'Something Went Wrong',
          message:
              'An unexpected error occurred. Please try again or contact support if the problem persists.',
        );
    }
  }
}

/// Offline mode indicator banner
class OfflineBanner extends StatelessWidget {
  final VoidCallback? onRetry;

  const OfflineBanner({
    Key? key,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.orange,
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'You\'re offline. Some features may be limited.',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}

/// Error types
enum ErrorType {
  network,
  server,
  notFound,
  unauthorized,
  timeout,
  unknown,
}

class _ErrorInfo {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  _ErrorInfo({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });
}

/// Error boundary widget
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace? stackTrace)? errorBuilder;

  const ErrorBoundary({
    Key? key,
    required this.child,
    this.errorBuilder,
  }) : super(key: key);

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    FlutterError.onError = (details) {
      setState(() {
        _error = details.exception;
        _stackTrace = details.stack;
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_error!, _stackTrace);
      }
      return ErrorStateWidget(
        errorType: ErrorType.unknown,
        showDetails: true,
        technicalDetails: _error.toString(),
        onRetry: () {
          setState(() {
            _error = null;
            _stackTrace = null;
          });
        },
      );
    }
    return widget.child;
  }
}

