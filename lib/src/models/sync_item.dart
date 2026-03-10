class SyncItem {
  final String id;
  final String endpoint;
  final Map<String, dynamic> data;
  final String method;
  bool synced;

  SyncItem({
    required this.id,
    required this.endpoint,
    required this.data,
    required this.method,
    this.synced = false,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "endpoint": endpoint,
      "data": data,
      "method": method,
      "synced": synced,
    };
  }

  factory SyncItem.fromJson(Map<String, dynamic> json) {
    return SyncItem(
      id: json["id"],
      endpoint: json["endpoint"],
      data: Map<String, dynamic>.from(json["data"]),
      method: json["method"],
      synced: json["synced"],
    );
  }
}
