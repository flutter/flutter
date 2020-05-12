// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../base/utils.dart';
import '../convert.dart';

class PlistParser {
  PlistParser({
    @required FileSystem fileSystem,
    @required Logger logger,
    @required ProcessManager processManager,
  }) : _fileSystem = fileSystem,
       _logger = logger,
       _processUtils = ProcessUtils(logger: logger, processManager: processManager);

  final FileSystem _fileSystem;
  final Logger _logger;
  final ProcessUtils _processUtils;

  static const String kCFBundleIdentifierKey = 'CFBundleIdentifier';
  static const String kCFBundleShortVersionStringKey = 'CFBundleShortVersionString';
  static const String kCFBundleExecutable = 'CFBundleExecutable';

  /// Parses the plist file located at [plistFilePath] and returns the
  /// associated map of key/value property list pairs.
  ///
  /// If [plistFilePath] points to a non-existent file or a file that's not a
  /// valid property list file, this will return an empty map.
  ///
  /// The [plistFilePath] argument must not be null.
  Map<String, dynamic> parseFile(String plistFilePath) {
    assert(plistFilePath != null);
    const String executable = '/usr/bin/plutil';
    if (!_fileSystem.isFileSync(executable)) {
      throw const FileNotFoundException(executable);
    }
    if (!_fileSystem.isFileSync(plistFilePath)) {
      return const <String, dynamic>{};
    }

    final String normalizedPlistPath = _fileSystem.path.absolute(plistFilePath);

    try {
      final List<String> args = <String>[
        executable, '-convert', 'json', '-o', '-', normalizedPlistPath,
      ];
      final String jsonContent = _processUtils.runSync(
        args,
        throwOnError: true,
      ).stdout.trim();
      return castStringKeyedMap(json.decode(jsonContent));
    } on ProcessException catch (error) {
      _logger.printTrace('$error');
      return const <String, dynamic>{};
    }
  }

  /// Parses the Plist file located at [plistFilePath] and returns the value
  /// that's associated with the specified [key] within the property list.
  ///
  /// If [plistFilePath] points to a non-existent file or a file that's not a
  /// valid property list file, this will return null.
  ///
  /// If [key] is not found in the property list, this will return null.
  ///
  /// The [plistFilePath] and [key] arguments must not be null.
  String getValueFromFile(String plistFilePath, String key) {
    assert(key != null);
    final Map<String, dynamic> parsed = parseFile(plistFilePath);
    return parsed[key] as String;
  }
}
