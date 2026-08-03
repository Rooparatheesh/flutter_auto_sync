/// Represents a single API request stored in the offline sync queue.
///
/// Each SyncItem contains the API endpoint, request data,
/// HTTP method, and retry information.
/// These items are stored locally and synced with the server
/// when internet connectivity becomes available.
library;

class SyncItem {
  final String id;
  final String endpoint;
  final Map<String, dynamic> data;
  final String method;
  final Map<String, String>? headers;
  int retryCount;
  bool synced;

  SyncItem({
    required this.id,
    required this.endpoint,
    required this.data,
    required this.method,
    this.headers,
    this.retryCount = 0,
    this.synced = false,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "endpoint": endpoint,
      "data": data,
      "method": method,
      "headers": headers,
      "retryCount": retryCount,
      "synced": synced,
    };
  }

  factory SyncItem.fromJson(Map<String, dynamic> json) {
    return SyncItem(
      id: json["id"],
      endpoint: json["endpoint"],
      data: Map<String, dynamic>.from(json["data"]),
      method: json["method"],
      headers: json["headers"] != null ? Map<String, String>.from(json["headers"]) : null,
      retryCount: json["retryCount"] ?? 0,
      synced: json["synced"],
    );
  }
}
