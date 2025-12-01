// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:devtools_shared/devtools_server.dart' as devtools;
import 'package:meta/meta.dart';

import '../base/file_system.dart';
import '../convert.dart';

/// A persistent store used to save settings across sessions.
///
/// The store is written to `~/.flutter-devtools/.widget-preview` in JSON format.
class PersistentPreferences {
  PersistentPreferences({required this.fs}) {
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    syncSettings();
  }

  static const _kPreferencesFileName = '.widget-preview';

  final FileSystem fs;

  @visibleForTesting
  late final File file = fs.file(
    fs.path.join(devtools.LocalFileSystem.devToolsDir(), _kPreferencesFileName),
  );

  late Map<String, Object> _map;

  Object? operator [](String key) => _map[key];

  void operator []=(String key, Object? value) {
    if (value == null && !_map.containsKey(key)) {
      return;
    }
    if (_map[key] == value) {
      return;
    }

    if (value == null) {
      _map.remove(key);
    } else {
      _map[key] = value;
    }
    _writeChanges();
  }

  /// Re-read settings from the backing store.
  ///
  /// May be a no-op on some platforms.
  void syncSettings() {
    try {
      String contents = file.readAsStringSync();
      if (contents.isEmpty) {
        contents = '{}';
      }
      _map = (json.decode(contents) as Map).cast<String, Object>();
    } on Exception {
      _map = <String, Object>{};
    }
  }

  void remove(String propertyName) {
    if (!_map.containsKey(propertyName)) {
      return;
    }
    _map.remove(propertyName);
    _writeChanges();
  }

  void _writeChanges() {
    try {
      const jsonEncoder = JsonEncoder.withIndent('  ');
      file.writeAsStringSync('${jsonEncoder.convert(_map)}\n');
    } on Exception {
      // Do nothing.
    }
  }
}
