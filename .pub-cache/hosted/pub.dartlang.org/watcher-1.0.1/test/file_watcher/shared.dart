// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../utils.dart';

void sharedTests() {
  test("doesn't notify if the file isn't modified", () async {
    await startWatcher(path: 'file.txt');
    await pumpEventQueue();
    deleteFile('file.txt');
    await expectRemoveEvent('file.txt');
  });

  test('notifies when a file is modified', () async {
    await startWatcher(path: 'file.txt');
    writeFile('file.txt', contents: 'modified');
    await expectModifyEvent('file.txt');
  });

  test('notifies when a file is removed', () async {
    await startWatcher(path: 'file.txt');
    deleteFile('file.txt');
    await expectRemoveEvent('file.txt');
  });

  test('notifies when a file is modified multiple times', () async {
    await startWatcher(path: 'file.txt');
    writeFile('file.txt', contents: 'modified');
    await expectModifyEvent('file.txt');
    writeFile('file.txt', contents: 'modified again');
    await expectModifyEvent('file.txt');
  });

  test('notifies even if the file contents are unchanged', () async {
    await startWatcher(path: 'file.txt');
    writeFile('file.txt');
    await expectModifyEvent('file.txt');
  });

  test('emits a remove event when the watched file is moved away', () async {
    await startWatcher(path: 'file.txt');
    renameFile('file.txt', 'new.txt');
    await expectRemoveEvent('file.txt');
  });

  test(
      'emits a modify event when another file is moved on top of the watched '
      'file', () async {
    writeFile('old.txt');
    await startWatcher(path: 'file.txt');
    renameFile('old.txt', 'file.txt');
    await expectModifyEvent('file.txt');
  });

  // Regression test for a race condition.
  test('closes the watcher immediately after deleting the file', () async {
    writeFile('old.txt');
    var watcher = createWatcher(path: 'file.txt');
    var sub = watcher.events.listen(null);

    deleteFile('file.txt');
    await Future.delayed(Duration(milliseconds: 10));
    await sub.cancel();
  });
}
