// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

const _readDelay = Duration(milliseconds: 100);
const _maxWait = Duration(seconds: 5);

/// Returns true if the file exists.
///
/// If the file does not exist it keeps retrying for a period of time.
/// Returns false if the file never becomes available.
///
/// This reduces the likelihood of race conditions.
Future<bool> waitForFile(File file) async {
  final end = DateTime.now().add(_maxWait);
  while (!DateTime.now().isAfter(end)) {
    if (file.existsSync()) return true;
    await Future.delayed(_readDelay);
  }
  return file.existsSync();
}
