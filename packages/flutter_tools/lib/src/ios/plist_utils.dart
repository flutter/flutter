// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/context.dart';
import '../base/file_system.dart';
import '../base/process.dart';
import '../convert.dart';
import '../globals.dart';

class PlistUtils {
  const PlistUtils();

  static const String kCFBundleIdentifierKey = 'CFBundleIdentifier';
  static const String kCFBundleShortVersionStringKey = 'CFBundleShortVersionString';
  static const String kCFBundleExecutable = 'CFBundleExecutable';

  static PlistUtils get instance => context.get<PlistUtils>() ?? const PlistUtils();

  Map<String, dynamic> parseFile(String plistFilePath) {
    assert(plistFilePath != null);
    const String executable = '/usr/bin/plutil';
    if (!fs.isFileSync(executable))
      return null;
    if (!fs.isFileSync(plistFilePath))
      return null;

    final String normalizedPlistPath = fs.path.absolute(plistFilePath);

    try {
      final List<String> args = <String>[
        executable, '-convert', 'json', '-o', '-', normalizedPlistPath,
      ];
      final String jsonContent = runCheckedSync(args);
      return json.decode(jsonContent);
    } catch (error) {
      printTrace('$error');
      return null;
    }
  }

  String getValueFromFile(String plistFilePath, String key) {
    assert(key != null);
    final Map<String, dynamic> parsed = parseFile(plistFilePath);
    return parsed == null ? null : parsed[key];
  }
}
