class LogEntry {
  final String counterName;
  final String action;
  final DateTime timestamp;

  LogEntry({
    required this.counterName,
    required this.action,
    required this.timestamp,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      counterName: json['counterName'],
      action: json['action'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'counterName': counterName,
      'action': action,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class Log {
  List<LogEntry> entries = [];

  Log();

  factory Log.fromJson(Map<String, dynamic> json) {
    final log = Log();
    log.entries = (json['entries'] as List)
        .map((entryJson) => LogEntry.fromJson(entryJson))
        .toList();
    return log;
  }

  void add(LogEntry entry) {
    entries.add(entry);
  }

  Map<String, dynamic> toJson() {
    return {'entries': entries.map((entry) => entry.toJson()).toList()};
  }
}
