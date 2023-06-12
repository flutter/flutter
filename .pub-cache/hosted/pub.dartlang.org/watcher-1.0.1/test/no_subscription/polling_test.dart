// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:watcher/watcher.dart';

import 'shared.dart';
import '../utils.dart';

void main() {
  watcherFactory = (dir) => PollingDirectoryWatcher(dir);

  sharedTests();
}
