import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';

import 'database.dart';

/// Custom platform Handler, need to handle Web or IO differently or from a
/// custom app
abstract class PlatformHandler {
  /// delete the db, create the folder and returns its path
  Future<String> initDeleteDb(String dbName) async {
    if (await databaseExists(dbName)) {
      await deleteDatabase(dbName);
    }
    return dbName;
  }

  /// Write the db file directly to the file system
  Future<void> writeFileAsBytes(String path, List<int> bytes,
      {bool flush = false});

  /// Read a file as bytes
  Future<Uint8List> readFileAsBytes(String path);

  /// Write a file as a string
  Future<void> writeFileAsString(String path, String text,
      {bool flush = false});

  /// Read a file as a string
  Future<String> readFileAsString(String path);

  /// Check if a path exists.
  Future<bool> pathExists(String path);

  /// Recursively create a directory
  Future<void> createDirectory(String path);

  /// Recursively delete a directory
  Future<void> deleteDirectory(String path);

  /// Check if a directory exists
  Future<bool> existsDirectory(String path);
}

// ---
// Compat, to keep the example page as is
// ---

/// delete the db, create the folder and returnes its path
Future<String> initDeleteDb(String dbName) =>
    platformHandler.initDeleteDb(dbName);

/// Write the db file directly to the file system
Future<void> writeFileAsBytes(String path, List<int> bytes,
        {bool flush = false}) =>
    platformHandler.writeFileAsBytes(path, bytes, flush: flush);

/// Read a file as bytes
Future<Uint8List> readFileAsBytes(String path) =>
    platformHandler.readFileAsBytes(path);

/// Write a file as a string
Future<void> writeFileAsString(String path, String text,
        {bool flush = false}) =>
    platformHandler.writeFileAsString(path, text, flush: flush);

/// Read a file as a string
Future<String> readFileAsString(String path) =>
    platformHandler.readFileAsString(path);

/// Check if a path exists.
Future<bool> pathExists(String path) => platformHandler.pathExists(path);

/// Recursively create a directory
Future<void> createDirectory(String path) =>
    platformHandler.createDirectory(path);

/// Recursively delete a directory
Future<void> deleteDirectory(String path) =>
    platformHandler.deleteDirectory(path);

/// Check if a directory exists
Future<bool> existsDirectory(String path) =>
    platformHandler.existsDirectory(path);

PlatformHandler? _platformHandler;

/// Platform handler (can be overriden, needed for the web test app)
PlatformHandler get platformHandler => _platformHandler ??= platformHandlerIo;
set platformHandler(PlatformHandler handler) => _platformHandler = handler;
