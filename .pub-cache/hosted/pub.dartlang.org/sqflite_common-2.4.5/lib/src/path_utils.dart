import 'package:sqflite_common/sqlite_api.dart';

const _fileUriPrefix = 'file:';

/// True if a database path is in memory
bool isInMemoryDatabasePath(String path) {
  if (path == inMemoryDatabasePath) {
    return true;
  }
  if (isFileUriDatabasePath(path)) {
    if (path.substring(_fileUriPrefix.length) == inMemoryDatabasePath) {
      return true;
    }
  }
  return false;
}

/// True if a database path is a file uri
bool isFileUriDatabasePath(String path) {
  return path.startsWith(_fileUriPrefix);
}
