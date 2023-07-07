// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

/// The directory used to store per-user settings for Dart tooling.
Directory getDartPrefsDirectory() {
  return Directory(path.join(getUserHomeDir(), '.dart'));
}

/// Return the user's home directory.
String getUserHomeDir() {
  final String envKey =
      Platform.operatingSystem == 'windows' ? 'APPDATA' : 'HOME';
  final String? value = Platform.environment[envKey];
  return value == null ? '.' : value;
}
