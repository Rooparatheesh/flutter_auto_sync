import 'dart:convert';
import 'package:http/http.dart' as http;
import 'local_storage.dart';
import 'models/sync_item.dart';

class SyncService {
  static const int maxRetries = 3;

  static Future<void> sync() async {
    final items = LocalStorage.getItems();

    for (SyncItem item in items) {
      try {
        final response = await http.post(
          Uri.parse(item.endpoint),
          body: jsonEncode(item.data),
          headers: {"Content-Type": "application/json"},
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          await LocalStorage.removeItem(item.id);
        }
      } catch (e) {
        item.retryCount++;

        if (item.retryCount >= maxRetries) {
          await LocalStorage.removeItem(item.id);
        } else {
          await LocalStorage.updateItem(item); // save retry count
        }
      }
    }
  }
}
