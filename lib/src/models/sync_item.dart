/// Represents a single API request stored in the offline sync queue.
///
/// Each SyncItem contains the API endpoint, request data,
/// HTTP method, and retry information.
/// These items are stored locally and synced with the server
/// when internet connectivity becomes available.
library;

class SyncItem {
  /// Unique UUID for this request.
  final String id;
  /// The API endpoint URL.
  final String endpoint;
  /// The JSON data body to send.
  final Map<String, dynamic> data;
  /// The HTTP method (GET, POST, PUT, DELETE, PATCH).
  final String method;
  /// Optional custom HTTP headers.
  final Map<String, String>? headers;
  /// Optional map of file fields (field_name -> local_file_path) for Multipart uploads.
  final Map<String, String>? files;
  /// Number of times this request has failed and been retried.
  int retryCount;
  /// Whether this item has successfully synced.
  bool synced;
  /// Queue priority (higher number syncs first).
  int priority;

  /// Creates a new SyncItem for offline storage.
  SyncItem({
    required this.id,
    required this.endpoint,
    required this.data,
    required this.method,
    this.headers,
    this.files,
    this.retryCount = 0,
    this.synced = false,
    this.priority = 0,
  });

  /// Converts the SyncItem to a JSON map for Hive storage.
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "endpoint": endpoint,
      "data": data,
      "method": method,
      "headers": headers,
      "files": files,
      "retryCount": retryCount,
      "synced": synced,
      "priority": priority,
    };
  }

  /// Creates a SyncItem from a JSON map retrieved from Hive.
  factory SyncItem.fromJson(Map<String, dynamic> json) {
    return SyncItem(
      id: json["id"],
      endpoint: json["endpoint"],
      data: Map<String, dynamic>.from(json["data"]),
      method: json["method"],
      headers: json["headers"] != null
          ? Map<String, String>.from(json["headers"])
          : null,
      files: json["files"] != null
          ? Map<String, String>.from(json["files"])
          : null,
      retryCount: json["retryCount"] ?? 0,
      synced: json["synced"],
      priority: json["priority"] ?? 0,
    );
  }
}
