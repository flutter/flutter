// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:path/path.dart' as path;

import '../base/process.dart';

const String kCFBundleIdentifierKey = "CFBundleIdentifier";

String plistValueForKey(String plistFilePath, String plistKey) {
  // TODO(chinmaygarde): For now, we only need to read from plist files on a
  // mac host. If this changes, we will need our own Dart plist reader.

  // Don't use PlistBuddy since that is not guaranteed to be installed.
  // 'defaults' requires the path to be absolute and without the 'plist'
  // extension.
  String normalizedPlistPath = path.withoutExtension(path.absolute(plistFilePath));

  try {
    return runCheckedSync([
      '/usr/bin/defaults',
      'read',
      normalizedPlistPath,
      plistKey]).trim();
  } catch (error) {
    return "";
  }
}
