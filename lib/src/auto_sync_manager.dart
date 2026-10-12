import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:uuid/uuid.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'connectivity_service.dart';
import 'local_storage.dart';
import 'models/sync_item.dart';
import 'sync_service.dart';
import 'package:flutter/widgets.dart';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage in the background isolate
  await LocalStorage.init();

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  void updateNotification(int count, {bool isSyncing = false}) {
    if (service is AndroidServiceInstance) {
      if (isSyncing) {
        service.setForegroundNotificationInfo(
          title: 'Auto Sync Active',
          content: 'Syncing $count offline requests...',
        );
      } else if (count > 0) {
        service.setForegroundNotificationInfo(
          title: 'Auto Sync Active',
          content: '$count offline requests pending network.',
        );
      } else {
        service.setForegroundNotificationInfo(
          title: 'Auto Sync Ready',
          content: 'All offline requests synced. Idle.',
        );
      }
    }
  }

  Future<void> runBackgroundSync() async {
    final items = LocalStorage.getItems();
    if (items.isEmpty) {
      service.invoke('updateCount', {'count': 0});
      updateNotification(0);
      return;
    }

    if (await ConnectivityService.isOnline()) {
      print(
          "🌐 [Background Service] Online. Syncing ${items.length} items (killed state supported)...");
      updateNotification(items.length, isSyncing: true);
      await SyncService.sync(isBackground: true);
      final remaining = LocalStorage.getItems().length;
      service.invoke('updateCount', {'count': remaining});
      updateNotification(remaining, isSyncing: false);
    } else {
      updateNotification(items.length, isSyncing: false);
    }
  }

  service.on('enqueue').listen((event) async {
    if (event != null) {
      try {
        final item = SyncItem.fromJson(Map<String, dynamic>.from(event));
        await LocalStorage.addItem(item);
        final count = LocalStorage.getItems().length;
        service.invoke('updateCount', {'count': count});
        updateNotification(count);
        if (await ConnectivityService.isOnline()) {
          await runBackgroundSync();
        }
      } catch (e) {
        print("Error enqueuing item: $e");
      }
    }
  });

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  print("==================================================");
  print("🚀 BACKGROUND SERVICE STARTED (KILLED STATE READY)");
  print("==================================================");

  // Sync right away if online and items exist
  await runBackgroundSync();

  // Listen to network changes with debounce so reconnecting triggers instant sync in killed state
  Timer? debounceTimer;
  ConnectivityService.connectionStream.listen((event) async {
    debounceTimer?.cancel();
    debounceTimer = Timer(const Duration(milliseconds: 1500), () async {
      if (await ConnectivityService.isOnline()) {
        final items = LocalStorage.getItems();
        if (items.isNotEmpty) {
          print(
              "🌐 [Background Service] Network restored in killed state. Syncing ${items.length} items...");
          await runBackgroundSync();
        }
      }
    });
  });
}

/// Main controller that manages offline data synchronization.
class AutoSyncManager {
  static const _uuid = Uuid();

  static final StreamController<int> _pendingItemsController =
      StreamController<int>.broadcast();
  static final StreamController<bool> _isSyncingController =
      StreamController<bool>.broadcast();

  /// Stream that emits the current count of pending offline items.
  static Stream<int> get pendingItemsStream => _pendingItemsController.stream;

  /// Stream that emits true when synchronization is active.
  static Stream<bool> get isSyncingStream => _isSyncingController.stream;

  /// Initializes local database and sets up sync listeners.
  static Future<void> init() async {
    await LocalStorage.init();
    updatePendingItemsCount();

    final service = FlutterBackgroundService();
    service.on('updateCount').listen((event) {
      if (event != null && event['count'] != null) {
        _pendingItemsController.add(event['count'] as int);
      }
    });

    // Only sync from main isolate if background service is NOT running
    // to avoid duplicate simultaneous HTTP requests and battery waste.
    ConnectivityService.connectionStream.listen((event) async {
      final isBgRunning = await service.isRunning();
      if (!isBgRunning &&
          await ConnectivityService.isOnline() &&
          LocalStorage.getItems().isNotEmpty) {
        await SyncService.sync();
      }
    });
  }

  /// Initializes background service to achieve instant syncing in killed state.
  static Future<void> initializeBackgroundSync() async {
    final service = FlutterBackgroundService();

    // Setup notifications
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'auto_sync_foreground',
      'Auto Sync Service',
      description: 'This channel is used for auto sync foreground service.',
      importance: Importance.low, // low importance prevents sounds/vibrations
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    if (Platform.isAndroid) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true, // Keep alive to support syncing in killed state
        isForegroundMode: true,
        notificationChannelId: 'auto_sync_foreground',
        initialNotificationTitle: 'Auto Sync Active',
        initialNotificationContent: 'Waiting for network to sync offline data',
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [AndroidForegroundType.dataSync],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: (ServiceInstance service) {
          return true;
        },
      ),
    );

    await service.startService();
  }

  /// Adds a new API request to the offline queue.
  static Future<void> addToQueue({
    required String endpoint,
    required Map<String, dynamic> data,
    String method = "POST",
    Map<String, String>? headers,
    Map<String, String>? files,
    int priority = 0,
  }) async {
    final item = SyncItem(
      id: _uuid.v4(),
      endpoint: endpoint,
      data: data,
      method: method,
      headers: headers,
      files: files,
      priority: priority,
    );

    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();

    if (isRunning) {
      service.invoke('enqueue', item.toJson());
    } else {
      await LocalStorage.addItem(item);
      updatePendingItemsCount();
      if (await ConnectivityService.isOnline()) {
        SyncService.sync();
      }
    }
  }

  static Future<void> sync() async {
    await SyncService.sync();
  }

  static void setSyncingState(bool isSyncing) {
    _isSyncingController.add(isSyncing);
  }

  static void updatePendingItemsCount() {
    _pendingItemsController.add(LocalStorage.getItems().length);
  }
}
