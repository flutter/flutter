// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('linux')

import 'package:test/test.dart';
import 'package:watcher/src/directory_watcher/linux.dart';

import 'shared.dart';
import '../utils.dart';

void main() {
  watcherFactory = (dir) => LinuxDirectoryWatcher(dir);

  sharedTests();
}
