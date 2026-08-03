import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/sync_item.dart';

/// Handles local storage of sync queue items using Hive.
///
/// This class is responsible for:
/// - Initializing Hive database with AES encryption
/// - Adding items to the sync queue
/// - Retrieving stored sync items sorted by priority
/// - Updating retry information
/// - Removing synced items
///
class LocalStorage {
  static const String boxName = "sync_queue";
  static const String keyName = "hive_encryption_key";

  static Future<void> init() async {
    await Hive.initFlutter();
    
    const secureStorage = FlutterSecureStorage();
    String? encryptionKeyStr = await secureStorage.read(key: keyName);
    
    if (encryptionKeyStr == null) {
      final key = Hive.generateSecureKey();
      await secureStorage.write(
        key: keyName,
        value: base64UrlEncode(key),
      );
      encryptionKeyStr = base64UrlEncode(key);
    }
    
    final encryptionKey = base64Url.decode(encryptionKeyStr);
    await Hive.openBox(boxName, encryptionCipher: HiveAesCipher(encryptionKey));
  }

  static Future<void> addItem(SyncItem item) async {
    final box = Hive.box(boxName);
    await box.put(item.id, item.toJson());
  }

  static List<SyncItem> getItems() {
    final box = Hive.box(boxName);
    final items = box.values
        .map((e) => SyncItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
        
    // Sort by priority descending (highest priority first)
    items.sort((a, b) => b.priority.compareTo(a.priority));
    return items;
  }

  static Future<void> removeItem(String id) async {
    final box = Hive.box(boxName);
    await box.delete(id);
  }

  static Future<void> updateItem(SyncItem item) async {
    final box = Hive.box(boxName);
    await box.put(item.id, item.toJson());
  }
}
