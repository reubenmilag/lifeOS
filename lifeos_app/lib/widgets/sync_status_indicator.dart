import 'package:flutter/material.dart';
import '../service_locator.dart';
import '../services/offline/sync_engine.dart';

/// Widget that displays the current sync status
/// 
/// Shows an indicator when syncing, offline, or has pending changes.
class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncState>(
      stream: locator.syncEngine.syncStatus,
      initialData: locator.syncEngine.currentState,
      builder: (context, snapshot) {
        final state = snapshot.data ?? SyncState.idle;
        
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _buildIndicator(state),
        );
      },
    );
  }

  Widget _buildIndicator(SyncState state) {
    switch (state) {
      case SyncState.syncing:
        return const _SyncingIndicator();
      case SyncState.offline:
        return const _OfflineIndicator();
      case SyncState.error:
        return const _ErrorIndicator();
      case SyncState.idle:
        return const SizedBox.shrink();
    }
  }
}

class _SyncingIndicator extends StatelessWidget {
  const _SyncingIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Syncing...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineIndicator extends StatelessWidget {
  const _OfflineIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off,
            size: 14,
            color: Colors.orange.shade700,
          ),
          const SizedBox(width: 8),
          Text(
            'Offline',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorIndicator extends StatelessWidget {
  const _ErrorIndicator();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => locator.syncEngine.triggerSync(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 14,
              color: Colors.red.shade700,
            ),
            const SizedBox(width: 8),
            Text(
              'Sync Error - Tap to retry',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full sync status banner for app bar
class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncState>(
      stream: locator.syncEngine.syncStatus,
      initialData: locator.syncEngine.currentState,
      builder: (context, snapshot) {
        final state = snapshot.data ?? SyncState.idle;
        
        if (state == SyncState.idle) {
          return const SizedBox.shrink();
        }
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: state == SyncState.idle ? 0 : 40,
          color: _getBackgroundColor(state),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _getIcon(state),
                const SizedBox(width: 8),
                Text(
                  _getMessage(state),
                  style: TextStyle(
                    color: _getTextColor(state),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getBackgroundColor(SyncState state) {
    switch (state) {
      case SyncState.syncing:
        return Colors.blue.shade50;
      case SyncState.offline:
        return Colors.orange.shade50;
      case SyncState.error:
        return Colors.red.shade50;
      case SyncState.idle:
        return Colors.transparent;
    }
  }

  Color _getTextColor(SyncState state) {
    switch (state) {
      case SyncState.syncing:
        return Colors.blue.shade700;
      case SyncState.offline:
        return Colors.orange.shade700;
      case SyncState.error:
        return Colors.red.shade700;
      case SyncState.idle:
        return Colors.transparent;
    }
  }

  Widget _getIcon(SyncState state) {
    switch (state) {
      case SyncState.syncing:
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.blue.shade700,
          ),
        );
      case SyncState.offline:
        return Icon(Icons.cloud_off, size: 16, color: Colors.orange.shade700);
      case SyncState.error:
        return Icon(Icons.error_outline, size: 16, color: Colors.red.shade700);
      case SyncState.idle:
        return const SizedBox.shrink();
    }
  }

  String _getMessage(SyncState state) {
    switch (state) {
      case SyncState.syncing:
        return 'Syncing your data...';
      case SyncState.offline:
        return 'You\'re offline. Changes will sync when connected.';
      case SyncState.error:
        return 'Sync error. Tap to retry.';
      case SyncState.idle:
        return '';
    }
  }
}
