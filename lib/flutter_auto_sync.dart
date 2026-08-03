/// A Flutter package that automatically stores API requests offline and securely syncs them when internet connectivity returns.
/// 
/// This package exposes `AutoSyncManager` as the primary entry point for managing offline queues.
library flutter_auto_sync;

export 'src/auto_sync_manager.dart';
export 'src/connectivity_service.dart';
export 'src/local_storage.dart';
export 'src/sync_service.dart';
export 'src/models/sync_item.dart';
