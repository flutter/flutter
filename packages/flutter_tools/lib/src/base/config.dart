// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../convert.dart';
import 'file_system.dart';
import 'logger.dart';
import 'utils.dart';

class Config {
  Config({
    @required File file,
    @required Logger logger,
  }) : _file = file, _logger = logger {
    if (!_file.existsSync()) {
      return;
    }
    try {
      _values = castStringKeyedMap(json.decode(_file.readAsStringSync()));
    } on FormatException {
      _logger
        ..printError('Failed to decode preferences in ${_file.path}.')
        ..printError(
            'You may need to reapply any previously saved configuration '
            'with the "flutter config" command.',
        );
      _file.deleteSync();
    }
  }

  static const String kFlutterSettings = '.flutter_settings';

  final File _file;
  final Logger _logger;

  String get configPath => _file.path;

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
    _file.writeAsStringSync(json);
  }
}
