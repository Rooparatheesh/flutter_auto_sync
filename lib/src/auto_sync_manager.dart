import 'dart:async';
import 'package:uuid/uuid.dart';
import 'connectivity_service.dart';
import 'local_storage.dart';
import 'models/sync_item.dart';
import 'sync_service.dart';

/// Main controller that manages offline data synchronization.
///
/// This class:
/// - Initializes the offline sync system
/// - Listens for internet connectivity changes
/// - Automatically triggers sync when internet returns
/// - Adds API requests to the offline queue
class AutoSyncManager {
  static const _uuid = Uuid();

  // Streams for UI integration
  static final StreamController<int> _pendingItemsController =
      StreamController<int>.broadcast();
  static final StreamController<bool> _isSyncingController =
      StreamController<bool>.broadcast();

  static Stream<int> get pendingItemsStream => _pendingItemsController.stream;
  static Stream<bool> get isSyncingStream => _isSyncingController.stream;

  static Future<void> init() async {
    await LocalStorage.init();
    updatePendingItemsCount();

    ConnectivityService.connectionStream.listen((event) async {
      if (await ConnectivityService.isOnline()) {
        await SyncService.sync();
      }
    });
  }

  /// Adds a new API request to the offline queue.
  static Future<void> addToQueue({
    required String endpoint,
    required Map<String, dynamic> data,
    String method = "POST",
    Map<String, String>? headers,
    int priority = 0,
  }) async {
    final item = SyncItem(
      id: _uuid.v4(),
      endpoint: endpoint,
      data: data,
      method: method,
      headers: headers,
      priority: priority,
    );

    await LocalStorage.addItem(item);
    updatePendingItemsCount();
  }

  /// Manually trigger synchronization of queued requests.
  static Future<void> sync() async {
    await SyncService.sync();
  }

  /// Updates the syncing state stream
  static void setSyncingState(bool isSyncing) {
    _isSyncingController.add(isSyncing);
  }

  /// Updates the pending items count stream
  static void updatePendingItemsCount() {
    _pendingItemsController.add(LocalStorage.getItems().length);
  }
}
