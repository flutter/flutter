// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:watcher/watcher.dart';

DirectoryWatcher defaultDirectoryWatcherFactory(String path) =>
    DirectoryWatcher(path);

DirectoryWatcher pollingDirectoryWatcherFactory(String path) =>
    PollingDirectoryWatcher(path);
