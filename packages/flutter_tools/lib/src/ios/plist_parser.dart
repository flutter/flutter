// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/process.dart';
import '../convert.dart';
import '../globals.dart';

class PlistParser {
  const PlistParser();

  static const String kCFBundleIdentifierKey = 'CFBundleIdentifier';
  static const String kCFBundleShortVersionStringKey = 'CFBundleShortVersionString';
  static const String kCFBundleExecutable = 'CFBundleExecutable';

  static PlistParser get instance => context.get<PlistParser>() ?? const PlistParser();

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
    if (!fs.isFileSync(executable))
      throw const FileNotFoundException(executable);
    if (!fs.isFileSync(plistFilePath))
      return const <String, dynamic>{};

    final String normalizedPlistPath = fs.path.absolute(plistFilePath);

    try {
      final List<String> args = <String>[
        executable, '-convert', 'json', '-o', '-', normalizedPlistPath,
      ];
      final String jsonContent = processUtils.runSync(
        args,
        throwOnError: true,
      ).stdout.trim();
      return json.decode(jsonContent);
    } on ProcessException catch (error) {
      printTrace('$error');
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
    return parsed[key];
  }
}
