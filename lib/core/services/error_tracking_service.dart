import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Error Tracking Service - Task H3
/// Comprehensive error tracking and monitoring with Firebase Crashlytics and Sentry
///
/// Features:
/// - Automatic crash reporting
/// - Custom error logging
/// - User context tracking
/// - Breadcrumb tracking
/// - Performance monitoring

class ErrorTrackingService {
  static final ErrorTrackingService _instance = ErrorTrackingService._internal();
  factory ErrorTrackingService() => _instance;
  ErrorTrackingService._internal();

  bool _isInitialized = false;

  /// Initialize error tracking
  ///
  /// Call this in main.dart before runApp()
  ///
  /// Optional: Pass Sentry DSN if you want to use Sentry
  /// Get your DSN from: https://sentry.io/settings/projects/
  Future<void> initialize({String? sentryDsn}) async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase Crashlytics
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);

      // Initialize Sentry (optional)
      if (sentryDsn != null && sentryDsn.isNotEmpty) {
        await SentryFlutter.init(
          (options) {
            options.dsn = sentryDsn;
            options.tracesSampleRate = 1.0;
            options.environment = kDebugMode ? 'development' : 'production';
            options.debug = kDebugMode;
          },
        );
      }

      // Set up Flutter error handler
      FlutterError.onError = (FlutterErrorDetails details) {
        recordFlutterError(details);
      };

      // Set up platform error handler
      PlatformDispatcher.instance.onError = (error, stack) {
        recordError(error, stack);
        return true;
      };

      _isInitialized = true;
      debugPrint('✅ Error tracking initialized');
      debugPrint('   - Crashlytics: enabled');
      debugPrint('   - Sentry: ${sentryDsn != null ? "enabled" : "disabled"}');
    } catch (e) {
      debugPrint('❌ Error tracking initialization failed: $e');
    }
  }

  /// Record a Flutter error
  void recordFlutterError(FlutterErrorDetails details) {
    // Log to console in debug mode
    if (kDebugMode) {
      FlutterError.presentError(details);
    }

    // Send to Crashlytics
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);

    // Send to Sentry
    Sentry.captureException(
      details.exception,
      stackTrace: details.stack,
    );
  }

  /// Record a general error
  void recordError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, dynamic>? context,
  }) {
    // Log to console in debug mode
    if (kDebugMode) {
      debugPrint('❌ Error: $error');
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
      if (reason != null) {
        debugPrint('Reason: $reason');
      }
    }

    // Send to Crashlytics
    FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: reason,
      information: context?.entries.map((e) => '${e.key}: ${e.value}').toList() ?? [],
    );

    // Send to Sentry
    Sentry.captureException(
      error,
      stackTrace: stackTrace,
      hint: Hint.withMap(context ?? {}),
    );
  }

  /// Log a message
  void log(String message, {Map<String, dynamic>? context}) {
    if (kDebugMode) {
      debugPrint('📝 Log: $message');
    }

    // Send to Crashlytics
    FirebaseCrashlytics.instance.log(message);

    // Send to Sentry
    Sentry.captureMessage(message);
  }

  /// Set user identifier
  void setUserIdentifier(String userId) {
    // Set in Crashlytics
    FirebaseCrashlytics.instance.setUserIdentifier(userId);

    // Set in Sentry
    Sentry.configureScope((scope) {
      scope.setUser(SentryUser(id: userId));
    });

    if (kDebugMode) {
      debugPrint('👤 User ID set: $userId');
    }
  }

  /// Set custom key-value pair
  void setCustomKey(String key, dynamic value) {
    // Set in Crashlytics
    FirebaseCrashlytics.instance.setCustomKey(key, value);

    // Set in Sentry
    Sentry.configureScope((scope) {
      scope.setContexts(key, value);
    });

    if (kDebugMode) {
      debugPrint('🔑 Custom key set: $key = $value');
    }
  }

  /// Force a crash (for testing only)
  /// WARNING: Only use this in debug mode for testing!
  void forceCrash() {
    if (kDebugMode) {
      debugPrint('💥 Forcing crash for testing...');
      throw Exception('Test crash from ErrorTrackingService');
    } else {
      debugPrint('⚠️ Force crash is disabled in production mode');
    }
  }

  /// Record a breadcrumb (for debugging)
  void addBreadcrumb(String message, {Map<String, dynamic>? data}) {
    if (kDebugMode) {
      debugPrint('🍞 Breadcrumb: $message');
    }

    // Add to Sentry
    Sentry.addBreadcrumb(Breadcrumb(
      message: message,
      data: data,
      timestamp: DateTime.now(),
    ));
  }

  /// Record a network error
  void recordNetworkError(
    String url,
    int? statusCode,
    String? errorMessage,
  ) {
    recordError(
      'Network Error',
      StackTrace.current,
      reason: 'HTTP $statusCode: $errorMessage',
      context: {
        'url': url,
        'statusCode': statusCode,
        'errorMessage': errorMessage,
      },
    );
  }

  /// Record a database error
  void recordDatabaseError(
    String operation,
    dynamic error,
    StackTrace? stackTrace,
  ) {
    recordError(
      error,
      stackTrace,
      reason: 'Database operation failed: $operation',
      context: {
        'operation': operation,
      },
    );
  }

  /// Record a performance issue
  void recordPerformanceIssue(
    String operation,
    Duration duration, {
    Map<String, dynamic>? context,
  }) {
    if (duration.inMilliseconds > 1000) {
      log(
        'Performance issue: $operation took ${duration.inMilliseconds}ms',
        context: {
          'operation': operation,
          'duration_ms': duration.inMilliseconds,
          ...?context,
        },
      );
    }
  }
}

/// Error boundary widget
class ErrorBoundaryWidget extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace? stackTrace)? errorBuilder;

  const ErrorBoundaryWidget({
    Key? key,
    required this.child,
    this.errorBuilder,
  }) : super(key: key);

  @override
  State<ErrorBoundaryWidget> createState() => _ErrorBoundaryWidgetState();
}

class _ErrorBoundaryWidgetState extends State<ErrorBoundaryWidget> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_error!, _stackTrace);
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Something went wrong'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                  _stackTrace = null;
                });
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return widget.child;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ErrorWidget.builder = (FlutterErrorDetails details) {
      setState(() {
        _error = details.exception;
        _stackTrace = details.stack;
      });
      ErrorTrackingService().recordFlutterError(details);
      return const SizedBox.shrink();
    };
  }
}

/// Extension for easy error tracking
extension ErrorTrackingExtension on Object {
  void trackError([StackTrace? stackTrace]) {
    ErrorTrackingService().recordError(this, stackTrace ?? StackTrace.current);
  }
}

/// Usage Examples:
/// 
/// 1. Initialize in main.dart:
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await ErrorTrackingService().initialize();
///   runApp(MyApp());
/// }
/// ```
/// 
/// 2. Track errors:
/// ```dart
/// try {
///   // Your code
/// } catch (e, stackTrace) {
///   ErrorTrackingService().recordError(e, stackTrace);
/// }
/// ```
/// 
/// 3. Set user context:
/// ```dart
/// ErrorTrackingService().setUserIdentifier(userId);
/// ErrorTrackingService().setCustomKey('user_level', userLevel);
/// ```
/// 
/// 4. Add breadcrumbs:
/// ```dart
/// ErrorTrackingService().addBreadcrumb('User clicked button');
/// ```
/// 
/// 5. Track network errors:
/// ```dart
/// ErrorTrackingService().recordNetworkError(url, 404, 'Not found');
/// ```

