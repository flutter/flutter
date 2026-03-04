import 'session_storage.dart';

class _MemorySessionStorage implements SessionStorage {
  SessionSnapshot? _snapshot;

  @override
  Future<SessionSnapshot?> read() async {
    return _snapshot;
  }

  @override
  Future<void> write(SessionSnapshot snapshot) async {
    _snapshot = snapshot;
  }
}

SessionStorage createSessionStorageImpl() => _MemorySessionStorage();
