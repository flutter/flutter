// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../convert.dart';
import 'file_system.dart';
import 'logger.dart';
import 'platform.dart';
import 'utils.dart';

/// A class to abstract configuration files.
class Config {
  /// Constructs a new [Config] object from a file called [name] in the
  /// current user's home directory as determined by the [Platform] and
  /// [FileSystem].
  factory Config(
    String name, {
    @required FileSystem fileSystem,
    @required Logger logger,
    @required Platform platform,
  }) {
    final File file = fileSystem.file(fileSystem.path.join(
      _userHomePath(platform),
      name,
    ));
    return Config._(file, logger);
  }

  /// Constructs a new [Config] object from a file called [name] in
  /// the given [Directory].
  factory Config.test(
    String name, {
    @required Directory directory,
    @required Logger logger,
  }) => Config._(directory.childFile(name), logger);

  Config._(File file, Logger logger) : _file = file, _logger = logger {
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

  /// The default name for the Flutter config file.
  static const String kFlutterSettings = '.flutter_settings';

  final Logger _logger;

  File _file;

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

  // Reads the process environment to find the current user's home directory.
  //
  // If the searched environment variables are not set, '.' is returned instead.
  //
  // Note that this is different from FileSystemUtils.homeDirPath.
  static String _userHomePath(Platform platform) {
    final String envKey = platform.operatingSystem == 'windows'
      ? 'APPDATA'
      : 'HOME';
    return platform.environment[envKey] ?? '.';
  }
}
