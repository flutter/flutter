import 'dart:convert';
import 'dart:io';

import '../../features/workout/domain/session_log.dart';
import 'session_storage.dart';

class _FileSessionStorage implements SessionStorage {
  static const String _fileName = 'trainflow_session_snapshot.json';

  File get _storageFile => File('${Directory.systemTemp.path}/$_fileName');

  @override
  Future<SessionSnapshot?> read() async {
    if (!await _storageFile.exists()) {
      return null;
    }

    try {
      final String content = await _storageFile.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final activeProgramId = json['activeProgramId'] as String?;
      final List<dynamic> rawLogs = (json['logs'] as List<dynamic>?) ?? <dynamic>[];
      if (activeProgramId == null || activeProgramId.isEmpty) {
        return null;
      }

      return SessionSnapshot(
        activeProgramId: activeProgramId,
        logs: rawLogs
            .whereType<Map<String, dynamic>>()
            .map(SessionLog.fromJson)
            .toList(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(SessionSnapshot snapshot) async {
    final json = <String, dynamic>{
      'activeProgramId': snapshot.activeProgramId,
      'logs': snapshot.logs.map((SessionLog log) => log.toJson()).toList(),
    };
    await _storageFile.writeAsString(jsonEncode(json), flush: true);
  }
}

SessionStorage createSessionStorageImpl() => _FileSessionStorage();
