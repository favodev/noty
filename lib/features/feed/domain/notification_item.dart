class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.appPackage,
    required this.appName,
    required this.title,
    required this.body,
    required this.receivedAt,
    required this.isUnread,
    this.mediaPath,
    this.mediaType,
    this.mediaMimeType,
    this.mediaSizeBytes,
  });

  final String id;
  final String appPackage;
  final String appName;
  final String title;
  final String body;
  final DateTime receivedAt;
  final bool isUnread;
  final String? mediaPath;
  final String? mediaType;
  final String? mediaMimeType;
  final int? mediaSizeBytes;

  bool get hasMedia => mediaPath != null && mediaPath!.trim().isNotEmpty;

  bool matchesQuery(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }

    return appName.toLowerCase().contains(normalized) ||
        title.toLowerCase().contains(normalized) ||
        body.toLowerCase().contains(normalized);
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'appPackage': appPackage,
      'appName': appName,
      'title': title,
      'body': body,
      'receivedAt': receivedAt.toIso8601String(),
      'isUnread': isUnread,
      'mediaPath': mediaPath,
      'mediaType': mediaType,
      'mediaMimeType': mediaMimeType,
      'mediaSizeBytes': mediaSizeBytes,
    };
  }

  factory NotificationItem.fromJson(Map<String, Object?> json) {
    return NotificationItem(
      id: json['id'] as String,
      appPackage: json['appPackage'] as String? ?? '',
      appName: json['appName'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      receivedAt: DateTime.parse(json['receivedAt'] as String),
      isUnread: json['isUnread'] as bool? ?? false,
      mediaPath: json['mediaPath'] as String?,
      mediaType: json['mediaType'] as String?,
      mediaMimeType: json['mediaMimeType'] as String?,
      mediaSizeBytes: (json['mediaSizeBytes'] as num?)?.toInt(),
    );
  }
}
