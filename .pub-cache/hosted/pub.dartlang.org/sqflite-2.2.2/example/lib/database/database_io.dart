import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_example/database/database.dart';

class _PlatformHandlerIo extends PlatformHandler {
  /// delete the db, create the folder and returns its path
  @override
  Future<String> initDeleteDb(String dbName) async {
    final databasePath = await getDatabasesPath();
    // print(databasePath);
    final path = join(databasePath, dbName);

    // make sure the folder exists
    // ignore: avoid_slow_async_io
    if (await Directory(dirname(path)).exists()) {
      await deleteDatabase(path);
    } else {
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (e) {
        // ignore: avoid_print
        print(e);
      }
    }
    return path;
  }

  /// Write the db file directly to the file system
  @override
  Future<void> writeFileAsBytes(String path, List<int> bytes,
      {bool flush = false}) async {
    await File(path).writeAsBytes(bytes, flush: flush);
  }

  /// Read a file as bytes
  @override
  Future<Uint8List> readFileAsBytes(String path) async {
    return File(path).readAsBytes();
  }

  /// Write a file as a string
  @override
  Future<void> writeFileAsString(String path, String text,
      {bool flush = false}) async {
    await File(path).writeAsString(text, flush: true);
  }

  /// Read a file as a string
  @override
  Future<String> readFileAsString(String path) async {
    return File(path).readAsString();
  }

  /// Check if a path exists.
  @override
  Future<bool> pathExists(String path) async {
    // ignore: avoid_slow_async_io
    return File(path).exists();
  }

  /// Recursively create a directory
  @override
  Future<void> createDirectory(String path) async {
    await Directory(dirname(path)).create(recursive: true);
  }

  /// Recursively delete a directory
  @override
  Future<void> deleteDirectory(String path) async {
    await Directory(path).delete(recursive: true);
  }

  /// Check if a directory exists
  @override
  Future<bool> existsDirectory(String path) async {
    // ignore: avoid_slow_async_io
    return Directory(path).exists();
  }
}

/// Io platform handler
PlatformHandler platformHandlerIo = _PlatformHandlerIo();
