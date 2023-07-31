import 'dart:convert';
import 'dart:io';

import 'package:process_run/src/characters.dart';
import 'package:process_run/src/user_config.dart';

class FileContent {
  late File file;

  FileContent(String path) {
    file = File(path);
  }

  Future<bool> read() async {
    try {
      lines = LineSplitter.split(await file.readAsString()).toList();
      return true;
    } catch (e) {
      stderr.writeln('Error $e reading $file');
      return false;
    }
  }

  int indexOfTopLevelKey(List<String> supportedKeys) {
    for (var key in supportedKeys) {
      for (var i = 0; i < lines!.length; i++) {
        var line = lines![i];
        // Assume a proper format
        if (line.startsWith(key) &&
            line.substring(key.length).trim().startsWith(':')) {
          return i;
        }
      }
    }
    return -1;
  }

  Future<void> write() async {
    var content = lines!.join(Platform.isWindows ? '\r\n' : '\n');
    await file.parent.create(recursive: true);
    await file.writeAsString(content, flush: true);
  }

  static bool isTopLevelKey(String line) {
    if (startsWithWhitespace(line)) {
      return false;
    }
    if (line.startsWith('#')) {
      return false;
    }
    return true;
  }

  /// Supported top level [parentKeys]
  bool writeKeyValue(List<String> parentKeys, String key,
      {bool delete = false, String? value}) {
    // Remove alias header
    var modified = false;
    var insertTopLevelKey = false;
    var index = indexOfTopLevelKey(parentKeys);
    if (index < 0) {
      index = lines!.length;
      insertTopLevelKey = true;
    } else {
      // Skip top level key
      index++;
      // Remove existing alias
      for (var i = index; i < lines!.length; i++) {
        // Until first non space, non comment stat
        var line = lines![i];
        if (isTopLevelKey(line)) {
          break;
        } else if (line.trimLeft().startsWith('$key:')) {
          // Found! remove
          // Remove last first!
          modified = true;
          lines!.removeAt(i);
          break;
        }
      }
    }
    if (insertTopLevelKey) {
      // Insert top header
      modified = true;
      lines!.insert(index++, '${parentKeys.first}:');
    }
    if (!delete) {
      modified = true;
      lines!.insert(index++, '  $key: $value');
    }

    return modified;
  }

  List<String>? lines;
}

class EnvFileContent extends FileContent {
  EnvFileContent(String path) : super(path);

  bool addAlias(String alias, String command) =>
      writeKeyValue(userConfigAliasKeys, alias, value: command);

  bool deleteAlias(String alias) =>
      writeKeyValue(userConfigAliasKeys, alias, delete: true);

  bool addVar(String key, String value) =>
      writeKeyValue(userConfigVarKeys, key, value: value);

  bool deleteVar(String key) =>
      writeKeyValue(userConfigVarKeys, key, delete: true);

  /// Put the paths at the top
  bool prependPaths(List<String> paths) => writePaths(paths);

  bool deletePaths(List<String> paths) => writePaths(paths, delete: true);

  bool writePaths(List<String> paths, {bool delete = false}) {
    // Remove alias header
    var index = indexOfTopLevelKey(userConfigPathKeys);
    var insertTopLevelKey = false;
    var modified = false;
    if (index < 0) {
      index = lines!.length;
      insertTopLevelKey = true;
    } else {
      // Skip top level key
      index++;
      // Remove existing paths
      for (var path in paths) {
        for (var i = index; i < lines!.length; i++) {
          // Until first non space, non comment stat
          var line = lines![i];
          if (FileContent.isTopLevelKey(line)) {
            break;
          } else if (line.trim() == '- $path') {
            // Found! remove
            // Remove last first!
            modified = true;
            lines!.removeAt(i);
            break;
          }
        }
      }
    }
    if (insertTopLevelKey) {
      // Insert top header
      modified = true;
      lines!.insert(index++, '${userConfigPathKeys.first}:');
    }
    if (!delete) {
      for (var path in paths) {
        modified = true;
        lines!.insert(index++, '  - $path');
      }
    }

    return modified;
  }
}
