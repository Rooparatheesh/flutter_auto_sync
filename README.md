# Flutter Auto Sync

A Flutter package that automatically stores API requests offline and securely syncs them when internet connectivity returns.

## Features

✔ **Offline Data Storage** - Uses Hive for fast local storage.
✔ **Enterprise Security** - Automatically encrypts the offline database using AES 256-bit encryption via `flutter_secure_storage`.
✔ **True Background Sync (Killed State)** - Uses `workmanager` to sync data seamlessly even when the app is completely closed.
✔ **Queue Prioritization** - Ensure critical API calls are dispatched first.
✔ **Real-time UI Streams** - Listen to sync status and pending item counts.
✔ **Retry Mechanism** - Failed requests are retried up to 3 times across app restarts.
✔ **Custom Headers & Methods** - Supports all HTTP methods and custom Authorization headers.

## Real-World Use Cases

Here are some real-time conditions where `flutter_auto_sync` shines:

- **Field Service & Delivery Apps:** Technicians working in basements or remote areas can upload proof-of-delivery photos and update statuses. The app queues the API calls and syncs them when network coverage is restored.
- **Healthcare & Medical Survey Apps:** Doctors collecting patient data in remote clinics. Because of **AES 256-bit encryption**, sensitive patient data remains locally secure (HIPAA compliant) before automatically syncing to the cloud.
- **Retail & E-commerce (Poor Connectivity):** Users shopping on a subway can tap "Add to Cart". The action is queued locally, allowing the UI to remain responsive, and syncs automatically when emerging from the tunnel.
- **Enterprise Data Collection:** Safety inspectors uploading heavy inspection forms. You can prioritize small critical text data to sync instantly on weak connections, while heavy photo uploads wait for a better connection using queue prioritization.
- **Chat & Social Media Apps:** Users can send messages in airplane mode. With the **retry mechanism**, messages are guaranteed to attempt sending when online, even across app restarts.
- **Event Lead Management:** Sales reps scanning badges at crowded trade shows with congested Wi-Fi. The package efficiently flushes the queue to CRM servers in the background whenever the network temporarily stabilizes.

## Installation

```yaml
dependencies:
  flutter_auto_sync: ^1.1.0
```

## Usage

```dart
import 'package:flutter_auto_sync/flutter_auto_sync.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize foreground syncing & local database
  await AutoSyncManager.init();
  
  // 2. Enable True Background Sync (runs even if app is swiped away/killed)
  AutoSyncManager.initializeBackgroundSync();
  
  runApp(MyApp());
}

// Add a request to the offline queue
await AutoSyncManager.addToQueue(
  endpoint: "https://api.example.com/data",
  method: "POST", // Supports GET, POST, PUT, DELETE, PATCH
  headers: {
    "Authorization": "Bearer YOUR_TOKEN",
    "Content-Type": "application/json",
  },
  data: {"name": "Roopa"},
  files: {
    "profile_picture": "/path/to/local/image.jpg", // (Optional) Upload files offline!
  },
  priority: 1, // Higher priority items sync first
);
```

### UI Integration (Streams)
You can listen to real-time streams to build reactive UIs:

```dart
// Stream the number of pending offline requests
AutoSyncManager.pendingItemsStream.listen((count) {
  print("Pending requests: $count");
});

// Stream the current syncing state (useful for loading spinners)
AutoSyncManager.isSyncingStream.listen((isSyncing) {
  print("Is currently syncing: $isSyncing");
});
```

## Example
See the `example` folder for a full demo.