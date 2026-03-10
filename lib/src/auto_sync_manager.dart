import 'package:uuid/uuid.dart';
import 'connectivity_service.dart';
import 'local_storage.dart';
import 'models/sync_item.dart';
import 'sync_service.dart';

class AutoSyncManager {
  static final _uuid = Uuid();

  static Future<void> init() async {
    await LocalStorage.init();

    ConnectivityService.connectionStream.listen((event) async {
      if (await ConnectivityService.isOnline()) {
        await SyncService.sync();
      }
    });
  }

  static Future<void> addToQueue({
    required String endpoint,
    required Map<String, dynamic> data,
    String method = "POST",
  }) async {
    final item = SyncItem(
      id: _uuid.v4(),
      endpoint: endpoint,
      data: data,
      method: method,
    );

    await LocalStorage.addItem(item);
  }
}
