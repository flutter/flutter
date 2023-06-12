// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Watches the given directory and prints each modification to it.
library watch;

import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

void main(List<String> arguments) {
  if (arguments.length != 1) {
    print('Usage: watch <directory path>');
    return;
  }

  var watcher = DirectoryWatcher(p.absolute(arguments[0]));
  watcher.events.listen((event) {
    print(event);
  });
}
