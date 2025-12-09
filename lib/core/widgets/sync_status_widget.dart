import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/daily_activities/models/event_service.dart';
import 'app_logger.dart';

/// Provider for sync status
final syncStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return await EventService.getSyncStatus();
});

/// Widget that displays sync status information
class SyncStatusWidget extends ConsumerWidget {
  final bool showDetails;
  final VoidCallback? onManualSync;

  const SyncStatusWidget({
    Key? key,
    this.showDetails = false,
    this.onManualSync,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);

    return syncStatus.when(
      loading: () =>
          const SyncStatusIndicator(status: 'Loading...', isLoading: true),
      error: (error, stack) => SyncStatusIndicator(
        status: 'Sync Error',
        isError: true,
        onTap: () => ref.refresh(syncStatusProvider),
      ),
      data: (status) {
        final pendingCount = status['pendingSyncCount'] as int;
        final isSyncing = status['isSyncing'] as bool;
        final isConnected = status['isConnected'] as bool;
        final statusMessage = status['statusMessage'] as String;
        final lastSyncTime = status['lastSyncTime'] as DateTime?;

        if (showDetails) {
          return SyncStatusDetails(
            pendingCount: pendingCount,
            isSyncing: isSyncing,
            isConnected: isConnected,
            statusMessage: statusMessage,
            lastSyncTime: lastSyncTime,
            onManualSync: onManualSync,
            onRefresh: () => ref.refresh(syncStatusProvider),
          );
        } else {
          return SyncStatusIndicator(
            status: statusMessage,
            isLoading: isSyncing,
            isError: !isConnected,
            pendingCount: pendingCount,
            onTap: () => ref.refresh(syncStatusProvider),
          );
        }
      },
    );
  }
}

/// Simple sync status indicator
class SyncStatusIndicator extends StatelessWidget {
  final String status;
  final bool isLoading;
  final bool isError;
  final int? pendingCount;
  final VoidCallback? onTap;

  const SyncStatusIndicator({
    Key? key,
    required this.status,
    this.isLoading = false,
    this.isError = false,
    this.pendingCount,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _getBorderColor(), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(),
            const SizedBox(width: 6),
            Text(
              status,
              style: TextStyle(
                fontSize: 12,
                color: _getTextColor(),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (pendingCount != null && pendingCount! > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade600,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$pendingCount',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (isLoading) {
      return SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(_getTextColor()),
        ),
      );
    } else if (isError) {
      return Icon(Icons.cloud_off, size: 12, color: _getTextColor());
    } else if (pendingCount != null && pendingCount! > 0) {
      return Icon(Icons.cloud_upload, size: 12, color: _getTextColor());
    } else {
      return Icon(Icons.cloud_done, size: 12, color: _getTextColor());
    }
  }

  Color _getBackgroundColor() {
    if (isError) return Colors.red.shade50;
    if (isLoading) return Colors.blue.shade50;
    if (pendingCount != null && pendingCount! > 0) return Colors.orange.shade50;
    return Colors.green.shade50;
  }

  Color _getBorderColor() {
    if (isError) return Colors.red.shade200;
    if (isLoading) return Colors.blue.shade200;
    if (pendingCount != null && pendingCount! > 0)
      return Colors.orange.shade200;
    return Colors.green.shade200;
  }

  Color _getTextColor() {
    if (isError) return Colors.red.shade700;
    if (isLoading) return Colors.blue.shade700;
    if (pendingCount != null && pendingCount! > 0)
      return Colors.orange.shade700;
    return Colors.green.shade700;
  }
}

/// Detailed sync status view
class SyncStatusDetails extends StatelessWidget {
  final int pendingCount;
  final bool isSyncing;
  final bool isConnected;
  final String statusMessage;
  final DateTime? lastSyncTime;
  final VoidCallback? onManualSync;
  final VoidCallback? onRefresh;

  const SyncStatusDetails({
    Key? key,
    required this.pendingCount,
    required this.isSyncing,
    required this.isConnected,
    required this.statusMessage,
    this.lastSyncTime,
    this.onManualSync,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isConnected ? Icons.cloud_done : Icons.cloud_off,
                  color: isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sync Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (onRefresh != null)
                  IconButton(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh),
                    iconSize: 20,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatusRow('Status', statusMessage),
            _buildStatusRow(
              'Connection',
              isConnected ? 'Connected' : 'Offline',
            ),
            _buildStatusRow('Pending Sync', '$pendingCount items'),
            if (lastSyncTime != null)
              _buildStatusRow('Last Sync', _formatLastSync(lastSyncTime!)),
            const SizedBox(height: 16),
            if (onManualSync != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isSyncing
                      ? null
                      : () async {
                          try {
                            AppLogger.userAction(
                              'Manual sync requested from UI',
                              {},
                            );
                            onManualSync?.call();
                            if (onRefresh != null) {
                              onRefresh!();
                            }
                          } catch (e) {
                            AppLogger.exception('Manual sync from UI', e);
                          }
                        },
                  icon: isSyncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync),
                  label: Text(isSyncing ? 'Syncing...' : 'Sync Now'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatLastSync(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}

/// Extension to easily add sync status to any screen
extension SyncStatusHelper on Widget {
  Widget withSyncStatus({bool showDetails = false}) {
    return Column(
      children: [
        Expanded(child: this),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: SyncStatusWidget(
            showDetails: showDetails,
            onManualSync: () {
              EventService.performManualSync();
            },
          ),
        ),
      ],
    );
  }
}
