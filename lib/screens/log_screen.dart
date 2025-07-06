import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/log.dart';

class LogScreen extends StatelessWidget {
  final Log log;

  const LogScreen({super.key, required this.log});

  Future<void> _downloadLogs() async {
    final String json = jsonEncode(log.toJson());
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/logs.json');
    await file.writeAsString(json);
    await Share.shareXFiles([XFile(file.path)]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadLogs,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: log.entries.length,
        itemBuilder: (context, index) {
          final entry = log.entries[index];
          return ListTile(
            leading: Icon(entry.action == 'increment' ? Icons.add : Icons.remove),
            title: Text('${entry.counterName} ${entry.action}ed'),
            subtitle: Text(DateFormat.yMd().add_jms().format(entry.timestamp)),
          );
        },
      ),
    );
  }
}
