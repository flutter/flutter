// Copyright 2021 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'usage.dart';

// ignore: avoid_classes_with_only_static_members
class LocalFileSystem {
  static String _userHomeDir() {
    final String envKey =
        Platform.operatingSystem == 'windows' ? 'APPDATA' : 'HOME';
    return Platform.environment[envKey] ?? '.';
  }

  /// Returns the path to the DevTools storage directory.
  static String devToolsDir() {
    return path.join(_userHomeDir(), '.flutter-devtools');
  }

  /// Moves the .devtools file to ~/.flutter-devtools/.devtools if the .devtools
  /// file exists in the user's home directory.
  static void maybeMoveLegacyDevToolsStore() {
    final file = File(path.join(_userHomeDir(), DevToolsUsage.storeName));
    if (file.existsSync()) {
      ensureDevToolsDirectory();
      file.copySync(devToolsStoreLocation());
      file.deleteSync();
    }
  }

  static String devToolsStoreLocation() {
    return path.join(devToolsDir(), DevToolsUsage.storeName);
  }

  /// Creates the ~/.flutter-devtools directory if it does not already exist.
  static void ensureDevToolsDirectory() {
    Directory('${devToolsDir()}').createSync();
  }

  /// Returns a DevTools file from the given path.
  ///
  /// Only files within ~/.flutter-devtools/ can be accessed.
  static File? devToolsFileFromPath(String pathFromDevToolsDir) {
    if (pathFromDevToolsDir.contains('..')) {
      // The passed in path should not be able to walk up the directory tree
      // outside of the ~/.flutter-devtools/ directory.
      return null;
    }

    ensureDevToolsDirectory();
    final file = File(path.join(devToolsDir(), pathFromDevToolsDir));
    if (!file.existsSync()) {
      return null;
    }
    return file;
  }

  /// Returns a DevTools file from the given path as encoded json.
  ///
  /// Only files within ~/.flutter-devtools/ can be accessed.
  static String? devToolsFileAsJson(String pathFromDevToolsDir) {
    final file = devToolsFileFromPath(pathFromDevToolsDir);
    if (file == null) return null;

    final fileName = path.basename(file.path);
    if (!fileName.endsWith('.json')) return null;

    final content = file.readAsStringSync();
    final json = jsonDecode(content);
    json['lastModifiedTime'] = file.lastModifiedSync().toString();
    return jsonEncode(json);
  }

  /// Whether the flutter store file exists.
  static bool flutterStoreExists() {
    final flutterStore = File(path.join(_userHomeDir(), '.flutter'));
    return flutterStore.existsSync();
  }
}
