# Flutter Auto Sync

A Flutter package that automatically stores API requests offline and securely syncs them when internet connectivity returns.

## Features

✔ **Offline Data Storage** - Uses Hive for fast local storage.
✔ **Enterprise Security** - Automatically encrypts the offline database using AES 256-bit encryption via `flutter_secure_storage`.
✔ **Automatic Background Sync** - Syncs automatically when network connectivity is restored.
✔ **Queue Prioritization** - Ensure critical API calls are dispatched first.
✔ **Real-time UI Streams** - Listen to sync status and pending item counts.
✔ **Retry Mechanism** - Failed requests are retried up to 3 times across app restarts.
✔ **Custom Headers & Methods** - Supports all HTTP methods and custom Authorization headers.

## Installation

```yaml
dependencies:
  flutter_auto_sync: ^0.0.8
```

## Usage

```dart
import 'package:flutter_auto_sync/flutter_auto_sync.dart';

// Initialize the package (automatically sets up AES encryption)
await AutoSyncManager.init();

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