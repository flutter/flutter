// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'context.dart';
import 'file_system.dart';
import 'platform.dart';

class Config {
  Config([File configFile]) {
    _configFile = configFile ?? fs.file(fs.path.join(_userHomeDir(), '.flutter_settings'));
    if (_configFile.existsSync())
      _values = json.decode(_configFile.readAsStringSync());
  }

  static Config get instance => context[Config];

  File _configFile;
  String get configPath => _configFile.path;

  Map<String, dynamic> _values = <String, dynamic>{};

  Iterable<String> get keys => _values.keys;

  bool containsKey(String key) => _values.containsKey(key);

  dynamic getValue(String key) => _values[key];

  void setValue(String key, String value) {
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

String _userHomeDir() {
  final String envKey = platform.operatingSystem == 'windows' ? 'APPDATA' : 'HOME';
  final String value = platform.environment[envKey];
  return value == null ? '.' : value;
}
