// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'context.dart';

class Config {
  Config([File configFile]) {
    _configFile = configFile ?? new File(path.join(_userHomeDir(), '.flutter_settings'));
    if (_configFile.existsSync())
      _values = JSON.decode(_configFile.readAsStringSync());
  }

  static Config get instance => context[Config] ?? (context[Config] = new Config());

  File _configFile;
  Map<String, dynamic> _values = <String, dynamic>{};

  Iterable<String> get keys => _values.keys;

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
    String json = new JsonEncoder.withIndent('  ').convert(_values);
    json = '$json\n';
    _configFile.writeAsStringSync(json);
  }
}

String _userHomeDir() {
  String envKey = Platform.operatingSystem == 'windows' ? 'APPDATA' : 'HOME';
  String value = Platform.environment[envKey];
  return value == null ? '.' : value;
}
