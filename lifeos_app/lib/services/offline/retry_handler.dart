import 'dart:async';
import 'dart:math';

/// Retry strategy configuration for sync operations
class RetryConfig {
  /// Base delay in milliseconds for exponential backoff
  final int baseDelayMs;
  
  /// Maximum number of retry attempts
  final int maxRetries;
  
  /// Maximum delay cap in milliseconds
  final int maxDelayMs;
  
  /// Whether to apply jitter to prevent thundering herd
  final bool applyJitter;
  
  /// Jitter factor (0.0 to 1.0) - randomness added to delay
  final double jitterFactor;

  const RetryConfig({
    this.baseDelayMs = 2000,
    this.maxRetries = 5,
    this.maxDelayMs = 60000, // 1 minute max
    this.applyJitter = true,
    this.jitterFactor = 0.3,
  });

  /// Default configuration for sync operations
  static const RetryConfig defaultConfig = RetryConfig();
  
  /// Aggressive retry for critical operations
  static const RetryConfig aggressive = RetryConfig(
    baseDelayMs: 1000,
    maxRetries: 7,
    maxDelayMs: 30000,
  );
  
  /// Conservative retry for non-critical operations
  static const RetryConfig conservative = RetryConfig(
    baseDelayMs: 5000,
    maxRetries: 3,
    maxDelayMs: 120000,
  );
}

/// Handles retry logic with exponential backoff and jitter
class RetryHandler {
  final RetryConfig config;
  final Random _random = Random();

  RetryHandler({RetryConfig? config}) : config = config ?? RetryConfig.defaultConfig;

  /// Calculate delay for a given retry attempt
  /// 
  /// Uses exponential backoff: delay = base * 2^attempt
  /// Applies jitter if configured to prevent thundering herd
  Duration calculateDelay(int retryCount) {
    // Exponential backoff: base * 2^retryCount
    int delayMs = config.baseDelayMs * pow(2, retryCount).toInt();
    
    // Cap at maximum delay
    delayMs = min(delayMs, config.maxDelayMs);
    
    // Apply jitter if configured
    if (config.applyJitter) {
      final jitterRange = (delayMs * config.jitterFactor).toInt();
      final jitter = _random.nextInt(jitterRange * 2) - jitterRange;
      delayMs = max(0, delayMs + jitter);
    }
    
    return Duration(milliseconds: delayMs);
  }

  /// Check if retry should be attempted
  bool shouldRetry(int currentRetryCount) {
    return currentRetryCount < config.maxRetries;
  }

  /// Execute an operation with retry logic
  /// 
  /// Returns the result of the operation or throws after max retries
  Future<T> executeWithRetry<T>({
    required Future<T> Function() operation,
    required bool Function(Object error) shouldRetryOnError,
    void Function(int attempt, Duration delay, Object error)? onRetry,
  }) async {
    int attempt = 0;
    
    while (true) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        
        if (!shouldRetryOnError(e) || !shouldRetry(attempt)) {
          rethrow;
        }
        
        final delay = calculateDelay(attempt);
        onRetry?.call(attempt, delay, e);
        
        await Future.delayed(delay);
      }
    }
  }
}

/// Result of a retry operation
class RetryResult<T> {
  final bool success;
  final T? value;
  final Object? error;
  final int attempts;
  final Duration totalTime;

  const RetryResult({
    required this.success,
    this.value,
    this.error,
    required this.attempts,
    required this.totalTime,
  });

  factory RetryResult.success(T value, int attempts, Duration totalTime) {
    return RetryResult(
      success: true,
      value: value,
      attempts: attempts,
      totalTime: totalTime,
    );
  }

  factory RetryResult.failure(Object error, int attempts, Duration totalTime) {
    return RetryResult(
      success: false,
      error: error,
      attempts: attempts,
      totalTime: totalTime,
    );
  }
}

/// Determines if an error is retryable
class RetryableErrorClassifier {
  /// Check if error should trigger a retry
  static bool isRetryable(Object error) {
    final errorString = error.toString().toLowerCase();
    
    // Network errors - always retry
    if (_isNetworkError(errorString)) {
      return true;
    }
    
    // Server errors (5xx) - retry
    if (_isServerError(errorString)) {
      return true;
    }
    
    // Timeout errors - retry
    if (_isTimeoutError(errorString)) {
      return true;
    }
    
    // Client errors (4xx except specific ones) - don't retry
    if (_isClientError(errorString)) {
      return false;
    }
    
    // Default: don't retry unknown errors
    return false;
  }

  static bool _isNetworkError(String error) {
    return error.contains('socketexception') ||
           error.contains('connection refused') ||
           error.contains('connection reset') ||
           error.contains('no route to host') ||
           error.contains('network is unreachable') ||
           error.contains('host not found') ||
           error.contains('failed to connect') ||
           error.contains('connection closed');
  }

  static bool _isServerError(String error) {
    return error.contains('500') ||
           error.contains('502') ||
           error.contains('503') ||
           error.contains('504') ||
           error.contains('internal server error') ||
           error.contains('bad gateway') ||
           error.contains('service unavailable') ||
           error.contains('gateway timeout');
  }

  static bool _isTimeoutError(String error) {
    return error.contains('timeout') ||
           error.contains('timed out') ||
           error.contains('deadline exceeded');
  }

  static bool _isClientError(String error) {
    // 4xx errors that shouldn't be retried
    return error.contains('400') ||
           error.contains('401') ||
           error.contains('403') ||
           error.contains('404') ||
           error.contains('422') ||
           error.contains('bad request') ||
           error.contains('unauthorized') ||
           error.contains('forbidden') ||
           error.contains('not found') ||
           error.contains('unprocessable');
  }

  /// Check if this is a conflict error (requires special handling)
  static bool isConflictError(Object error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('409') || 
           errorString.contains('conflict') ||
           errorString.contains('version mismatch');
  }

  /// Check if this is an idempotent replay (success, not an error)
  static bool isIdempotentReplay(Object error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('idempotent') && 
           errorString.contains('replay');
  }
}
