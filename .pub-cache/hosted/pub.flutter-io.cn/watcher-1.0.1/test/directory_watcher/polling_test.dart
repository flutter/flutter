// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

import 'shared.dart';
import '../utils.dart';

void main() {
  // Use a short delay to make the tests run quickly.
  watcherFactory = (dir) =>
      PollingDirectoryWatcher(dir, pollingDelay: Duration(milliseconds: 100));

  sharedTests();

  test('does not notify if the modification time did not change', () async {
    writeFile('a.txt', contents: 'before');
    writeFile('b.txt', contents: 'before');
    await startWatcher();
    writeFile('a.txt', contents: 'after', updateModified: false);
    writeFile('b.txt', contents: 'after');
    await expectModifyEvent('b.txt');
  });
}
