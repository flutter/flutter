// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/file_system.dart';
import '../base/process.dart';

const String kCFBundleIdentifierKey = 'CFBundleIdentifier';
const String kCFBundleShortVersionStringKey = 'CFBundleShortVersionString';

// Prefer using [iosWorkflow.getPlistValueFromFile] to enable mocking.
String getValueFromFile(String plistFilePath, String key) {
  // TODO(chinmaygarde): For now, we only need to read from plist files on a mac
  // host. If this changes, we will need our own Dart plist reader.

  // Don't use PlistBuddy since that is not guaranteed to be installed.
  // 'defaults' requires the path to be absolute and without the 'plist'
  // extension.
  const String executable = '/usr/bin/defaults';
  if (!fs.isFileSync(executable))
    return null;
  if (!fs.isFileSync(plistFilePath))
    return null;

  final String normalizedPlistPath = fs.path.withoutExtension(fs.path.absolute(plistFilePath));

  try {
    final String value = runCheckedSync(<String>[
      executable, 'read', normalizedPlistPath, key
    ]);
    return value.isEmpty ? null : value;
  } catch (error) {
    return null;
  }
}
