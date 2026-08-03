import 'dart:convert';
import 'package:http/http.dart' as http;
import 'local_storage.dart';
import 'models/sync_item.dart';
import 'auto_sync_manager.dart';

/// Service responsible for syncing offline stored API requests
/// with the backend server.
///
/// It reads pending items from local storage and sends them
/// to the server when internet connectivity is available.
/// Failed requests are retried up to a maximum retry limit.
class SyncService {
  /// The maximum number of times an API request will be retried before being discarded.
  static const int maxRetries = 3;
  static bool _isSyncing = false;

  /// Triggers a synchronization attempt.
  /// 
  /// This method iterates through all pending items in the offline queue,
  /// attempts to send them via HTTP, and removes them if successful.
  static Future<void> sync() async {
    if (_isSyncing) return;
    _isSyncing = true;
    AutoSyncManager.setSyncingState(true);

    try {
      final items = LocalStorage.getItems();

      for (SyncItem item in items) {
        try {
          final uri = Uri.parse(item.endpoint);
          final body = jsonEncode(item.data);
          final headers = {
            "Content-Type": "application/json",
            if (item.headers != null) ...item.headers!,
          };

          http.Response response;
          final method = item.method.toUpperCase();

          if (item.files != null && item.files!.isNotEmpty) {
            var request = http.MultipartRequest(method, uri);
            request.headers.addAll(headers);

            item.data.forEach((key, value) {
              request.fields[key] = value.toString();
            });

            for (var entry in item.files!.entries) {
              request.files.add(
                await http.MultipartFile.fromPath(entry.key, entry.value),
              );
            }

            final streamedResponse = await request.send();
            response = await http.Response.fromStream(streamedResponse);
          } else {
            if (method == "GET") {
              response = await http.get(uri, headers: headers);
            } else if (method == "PUT") {
              response = await http.put(uri, headers: headers, body: body);
            } else if (method == "DELETE") {
              response = await http.delete(uri, headers: headers, body: body);
            } else if (method == "PATCH") {
              response = await http.patch(uri, headers: headers, body: body);
            } else {
              response = await http.post(uri, headers: headers, body: body);
            }
          }

          if (response.statusCode >= 200 && response.statusCode < 300) {
            await LocalStorage.removeItem(item.id);
            AutoSyncManager.updatePendingItemsCount();
          } else {
            // Treat non-2xx as a failure to trigger retry logic
            throw Exception('HTTP Error: ${response.statusCode}');
          }
        } catch (e) {
          item.retryCount++;

          if (item.retryCount >= maxRetries) {
            await LocalStorage.removeItem(item.id);
            AutoSyncManager.updatePendingItemsCount();
          } else {
            await LocalStorage.updateItem(item); // save retry count
          }
        }
      }
    } finally {
      _isSyncing = false;
      AutoSyncManager.setSyncingState(false);
    }
  }
}
