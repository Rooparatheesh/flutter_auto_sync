import 'package:hive_flutter/hive_flutter.dart';
import 'models/sync_item.dart';

/// Handles local storage of sync queue items using Hive.
///
/// This class is responsible for:
/// - Initializing Hive database
/// - Adding items to the sync queue
/// - Retrieving stored sync items
/// - Updating retry information
/// - Removing synced items
///
class LocalStorage {
  static const String boxName = "sync_queue";

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(boxName);
  }

  static Future<void> addItem(SyncItem item) async {
    final box = Hive.box(boxName);
    await box.put(item.id, item.toJson());
  }

  static List<SyncItem> getItems() {
    final box = Hive.box(boxName);
    return box.values
        .map((e) => SyncItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<void> removeItem(String id) async {
    final box = Hive.box(boxName);
    await box.delete(id);
  }

  // ⭐ NEW METHOD (needed for retry system)
  static Future<void> updateItem(SyncItem item) async {
    final box = Hive.box(boxName);
    await box.put(item.id, item.toJson());
  }
}
