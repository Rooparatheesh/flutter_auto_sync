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
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('enqueue').listen((event) async {
    if (event != null) {
      try {
        final item = SyncItem.fromJson(Map<String, dynamic>.from(event));
        await LocalStorage.addItem(item);
        service.invoke('updateCount', {'count': LocalStorage.getItems().length});
        if (await ConnectivityService.isOnline()) {
          SyncService.sync(isBackground: true);
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
  print("🚀 BACKGROUND SERVICE STARTED (FOREGROUND MODE)");
  print("==================================================");

  // Sync right away if online
  if (await ConnectivityService.isOnline()) {
    print("🌐 Network is online on start. Syncing...");
    await SyncService.sync(isBackground: true);
  }

  // Listen to network changes forever
  ConnectivityService.connectionStream.listen((event) async {
    if (await ConnectivityService.isOnline()) {
      print("🌐 Network became online in background. Syncing instantly...");
      await SyncService.sync(isBackground: true);
    }
  });

  // Keep alive timer just in case, but we rely mostly on connectivity stream
  // Reduced to 1 minute so it quickly picks up pending items if the app is killed
  // while a large queue (e.g. 10000 items) is still syncing.
  Timer.periodic(const Duration(minutes: 1), (timer) async {
    if (await ConnectivityService.isOnline()) {
      await SyncService.sync(isBackground: true);
    }
  });
}

/// Main controller that manages offline data synchronization.
class AutoSyncManager {
  static const _uuid = Uuid();

  static final StreamController<int> _pendingItemsController =
      StreamController<int>.broadcast();
  static final StreamController<bool> _isSyncingController =
      StreamController<bool>.broadcast();

  static Stream<int> get pendingItemsStream => _pendingItemsController.stream;

  static Future<void> init() async {
    await LocalStorage.init();
    updatePendingItemsCount();

    if (await ConnectivityService.isOnline()) {
      SyncService.sync(); 
    }

    ConnectivityService.connectionStream.listen((event) async {
      if (await ConnectivityService.isOnline()) {
        await SyncService.sync();
      }
    });

    final service = FlutterBackgroundService();
    service.on('updateCount').listen((event) {
      if (event != null && event['count'] != null) {
        _pendingItemsController.add(event['count'] as int);
      }
    });
  }

  /// Initializes foreground service to keep app alive
  static Future<void> initializeBackgroundSync() async {
    final service = FlutterBackgroundService();

    // Setup notifications
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'auto_sync_foreground',
      'Auto Sync Service',
      description: 'This channel is used for auto sync foreground service.',
      importance: Importance.low, // low importance to prevent sounds/vibrations
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
        autoStart: true,
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
          return true; // We don't have true background execution like android on iOS
        },
      ),
    );

    service.startService();
  }

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
    if (await service.isRunning()) {
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
