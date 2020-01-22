// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../convert.dart';
import '../globals.dart' as globals;
import 'file_system.dart';
import 'logger.dart';
import 'utils.dart';

class Config {
  Config([File configFile, Logger localLogger]) {
    final Logger loggerInstance = localLogger ?? globals.logger;
    _configFile = configFile ?? globals.fs.file(globals.fs.path.join(
      fsUtils.userHomePath,
      '.flutter_settings',
    ));
    if (_configFile.existsSync()) {
      try {
        _values = castStringKeyedMap(json.decode(_configFile.readAsStringSync()));
      } on FormatException {
        loggerInstance
          ..printError('Failed to decode preferences in ${_configFile.path}.')
          ..printError(
              'You may need to reapply any previously saved configuration '
              'with the "flutter config" command.',
          );
        _configFile.deleteSync();
      }
    }
  }

  File _configFile;
  String get configPath => _configFile.path;

  Map<String, dynamic> _values = <String, dynamic>{};

  Iterable<String> get keys => _values.keys;

  bool containsKey(String key) => _values.containsKey(key);

  dynamic getValue(String key) => _values[key];

  void setValue(String key, Object value) {
    _values[key] = value;
    _flushValues();
  }

  void removeValue(String key) {
    _values.remove(key);
    _flushValues();
  }

  void _flushValues() {
    String json = const JsonEncoder.withIndent('  ').convert(_values);
    json = '$json\n';
    _configFile.writeAsStringSync(json);
  }
}
