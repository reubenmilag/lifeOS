import 'dart:developer' as developer;

/// Logging service for sync operations
/// 
/// Provides structured logging for debugging and observability
/// of the sync process.
class SyncLogger {
  static const String _tag = 'SyncEngine';
  
  bool _verbose = false;
  
  /// Enable verbose logging
  void setVerbose(bool verbose) {
    _verbose = verbose;
  }

  /// Log sync start
  void logSyncStart() {
    log('Sync started');
  }

  /// Log sync completion
  void logSyncComplete(bool success, {int pushed = 0, int pulled = 0}) {
    log('Sync completed: success=$success, pushed=$pushed, pulled=$pulled');
  }

  /// Log a retry attempt
  void logRetry(int attempt, Duration delay, String error) {
    log('Retry attempt $attempt after ${delay.inMilliseconds}ms: $error');
  }

  /// Log a conflict occurrence
  void logConflict(String entityType, String entityId) {
    log('Conflict detected: $entityType/$entityId');
  }

  /// Log an error
  void logError(String message, Object error) {
    developer.log(
      '❌ $message: $error',
      name: _tag,
      level: 1000, // Error level
    );
  }

  /// Log a general message
  void log(String message) {
    if (_verbose) {
      developer.log(
        message,
        name: _tag,
        level: 800, // Info level
      );
    }
  }

  /// Log backoff delay
  void logBackoff(int retryCount, Duration delay) {
    log('Backoff: retry=$retryCount, delay=${delay.inMilliseconds}ms');
  }

  /// Log batch operation
  void logBatch(String operation, int count, int successful, int failed) {
    log('Batch $operation: total=$count, success=$successful, failed=$failed');
  }

  /// Log pull operation
  void logPull(String entityType, int count) {
    log('Pulled $count $entityType records');
  }

  /// Log push operation
  void logPush(String entityType, int count) {
    log('Pushed $count $entityType records');
  }
}
