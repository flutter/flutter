import '../../features/workout/domain/session_log.dart';

import 'session_storage_stub.dart' if (dart.library.io) 'session_storage_io.dart';

class SessionSnapshot {
  const SessionSnapshot({
    required this.activeProgramId,
    required this.logs,
  });

  final String activeProgramId;
  final List<SessionLog> logs;
}

abstract class SessionStorage {
  Future<SessionSnapshot?> read();
  Future<void> write(SessionSnapshot snapshot);
}

SessionStorage createSessionStorage() => createSessionStorageImpl();
