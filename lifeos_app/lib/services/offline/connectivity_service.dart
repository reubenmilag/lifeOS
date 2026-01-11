import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service for monitoring network connectivity
/// 
/// This service provides real-time connectivity status and
/// notifies listeners when connectivity changes.
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  
  StreamSubscription? _subscription;
  
  final _connectivityController = StreamController<bool>.broadcast();
  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    // Check initial connectivity
    final results = await _connectivity.checkConnectivity();
    _updateConnectivity(results);
    
    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(_updateConnectivity);
  }

  void _updateConnectivity(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;
    
    // Consider connected if we have any connection type other than none
    _isConnected = results.isNotEmpty && 
                   !results.contains(ConnectivityResult.none);
    
    // Only emit if state changed
    if (wasConnected != _isConnected) {
      _connectivityController.add(_isConnected);
    }
  }

  /// Check current connectivity (one-time check)
  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _updateConnectivity(results);
    return _isConnected;
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _connectivityController.close();
  }
}
