// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:watcher/src/utils.dart';

import '../utils.dart';

void sharedTests() {
  test('does not notify for files that already exist when started', () async {
    // Make some pre-existing files.
    writeFile('a.txt');
    writeFile('b.txt');

    await startWatcher();

    // Change one after the watcher is running.
    writeFile('b.txt', contents: 'modified');

    // We should get a modify event for the changed file, but no add events
    // for them before this.
    await expectModifyEvent('b.txt');
  });

  test('notifies when a file is added', () async {
    await startWatcher();
    writeFile('file.txt');
    await expectAddEvent('file.txt');
  });

  test('notifies when a file is modified', () async {
    writeFile('file.txt');
    await startWatcher();
    writeFile('file.txt', contents: 'modified');
    await expectModifyEvent('file.txt');
  });

  test('notifies when a file is removed', () async {
    writeFile('file.txt');
    await startWatcher();
    deleteFile('file.txt');
    await expectRemoveEvent('file.txt');
  });

  test('notifies when a file is modified multiple times', () async {
    writeFile('file.txt');
    await startWatcher();
    writeFile('file.txt', contents: 'modified');
    await expectModifyEvent('file.txt');
    writeFile('file.txt', contents: 'modified again');
    await expectModifyEvent('file.txt');
  });

  test('notifies even if the file contents are unchanged', () async {
    writeFile('a.txt', contents: 'same');
    writeFile('b.txt', contents: 'before');
    await startWatcher();

    writeFile('a.txt', contents: 'same');
    writeFile('b.txt', contents: 'after');
    await inAnyOrder([isModifyEvent('a.txt'), isModifyEvent('b.txt')]);
  });

  test('when the watched directory is deleted, removes all files', () async {
    writeFile('dir/a.txt');
    writeFile('dir/b.txt');

    await startWatcher(path: 'dir');

    deleteDir('dir');
    await inAnyOrder([isRemoveEvent('dir/a.txt'), isRemoveEvent('dir/b.txt')]);
  });

  test('when the watched directory is moved, removes all files', () async {
    writeFile('dir/a.txt');
    writeFile('dir/b.txt');

    await startWatcher(path: 'dir');

    renameDir('dir', 'moved_dir');
    createDir('dir');
    await inAnyOrder([isRemoveEvent('dir/a.txt'), isRemoveEvent('dir/b.txt')]);
  });

  // Regression test for b/30768513.
  test(
      "doesn't crash when the directory is moved immediately after a subdir "
      'is added', () async {
    writeFile('dir/a.txt');
    writeFile('dir/b.txt');

    await startWatcher(path: 'dir');

    createDir('dir/subdir');
    renameDir('dir', 'moved_dir');
    createDir('dir');
    await inAnyOrder([isRemoveEvent('dir/a.txt'), isRemoveEvent('dir/b.txt')]);
  });

  group('moves', () {
    test('notifies when a file is moved within the watched directory',
        () async {
      writeFile('old.txt');
      await startWatcher();
      renameFile('old.txt', 'new.txt');

      await inAnyOrder([isAddEvent('new.txt'), isRemoveEvent('old.txt')]);
    });

    test('notifies when a file is moved from outside the watched directory',
        () async {
      writeFile('old.txt');
      createDir('dir');
      await startWatcher(path: 'dir');

      renameFile('old.txt', 'dir/new.txt');
      await expectAddEvent('dir/new.txt');
    });

    test('notifies when a file is moved outside the watched directory',
        () async {
      writeFile('dir/old.txt');
      await startWatcher(path: 'dir');

      renameFile('dir/old.txt', 'new.txt');
      await expectRemoveEvent('dir/old.txt');
    });

    test('notifies when a file is moved onto an existing one', () async {
      writeFile('from.txt');
      writeFile('to.txt');
      await startWatcher();

      renameFile('from.txt', 'to.txt');
      await inAnyOrder([isRemoveEvent('from.txt'), isModifyEvent('to.txt')]);
    }, onPlatform: {
      'windows': Skip('https://github.com/dart-lang/watcher/issues/125')
    });
  });

  // Most of the time, when multiple filesystem actions happen in sequence,
  // they'll be batched together and the watcher will see them all at once.
  // These tests verify that the watcher normalizes and combine these events
  // properly. However, very occasionally the events will be reported in
  // separate batches, and the watcher will report them as though they occurred
  // far apart in time, so each of these tests has a "backup case" to allow for
  // that as well.
  group('clustered changes', () {
    test("doesn't notify when a file is created and then immediately removed",
        () async {
      writeFile('test.txt');
      await startWatcher();
      writeFile('file.txt');
      deleteFile('file.txt');

      // Backup case.
      startClosingEventStream();
      await allowEvents(() {
        expectAddEvent('file.txt');
        expectRemoveEvent('file.txt');
      });
    });

    test(
        'reports a modification when a file is deleted and then immediately '
        'recreated', () async {
      writeFile('file.txt');
      await startWatcher();

      deleteFile('file.txt');
      writeFile('file.txt', contents: 're-created');

      await allowEither(() {
        expectModifyEvent('file.txt');
      }, () {
        // Backup case.
        expectRemoveEvent('file.txt');
        expectAddEvent('file.txt');
      });
    });

    test(
        'reports a modification when a file is moved and then immediately '
        'recreated', () async {
      writeFile('old.txt');
      await startWatcher();

      renameFile('old.txt', 'new.txt');
      writeFile('old.txt', contents: 're-created');

      await allowEither(() {
        inAnyOrder([isModifyEvent('old.txt'), isAddEvent('new.txt')]);
      }, () {
        // Backup case.
        expectRemoveEvent('old.txt');
        expectAddEvent('new.txt');
        expectAddEvent('old.txt');
      });
    });

    test(
        'reports a removal when a file is modified and then immediately '
        'removed', () async {
      writeFile('file.txt');
      await startWatcher();

      writeFile('file.txt', contents: 'modified');
      deleteFile('file.txt');

      // Backup case.
      await allowModifyEvent('file.txt');

      await expectRemoveEvent('file.txt');
    });

    test('reports an add when a file is added and then immediately modified',
        () async {
      await startWatcher();

      writeFile('file.txt');
      writeFile('file.txt', contents: 'modified');

      await expectAddEvent('file.txt');

      // Backup case.
      startClosingEventStream();
      await allowModifyEvent('file.txt');
    });
  });

  group('subdirectories', () {
    test('watches files in subdirectories', () async {
      await startWatcher();
      writeFile('a/b/c/d/file.txt');
      await expectAddEvent('a/b/c/d/file.txt');
    });

    test(
        'notifies when a subdirectory is moved within the watched directory '
        'and then its contents are modified', () async {
      writeFile('old/file.txt');
      await startWatcher();

      renameDir('old', 'new');
      await inAnyOrder(
          [isRemoveEvent('old/file.txt'), isAddEvent('new/file.txt')]);

      writeFile('new/file.txt', contents: 'modified');
      await expectModifyEvent('new/file.txt');
    });

    test('notifies when a file is replaced by a subdirectory', () async {
      writeFile('new');
      writeFile('old/file.txt');
      await startWatcher();

      deleteFile('new');
      renameDir('old', 'new');
      await inAnyOrder([
        isRemoveEvent('new'),
        isRemoveEvent('old/file.txt'),
        isAddEvent('new/file.txt')
      ]);
    });

    test('notifies when a subdirectory is replaced by a file', () async {
      writeFile('old');
      writeFile('new/file.txt');
      await startWatcher();

      renameDir('new', 'newer');
      renameFile('old', 'new');
      await inAnyOrder([
        isRemoveEvent('new/file.txt'),
        isAddEvent('newer/file.txt'),
        isRemoveEvent('old'),
        isAddEvent('new')
      ]);
    }, onPlatform: {
      'mac-os': Skip('https://github.com/dart-lang/watcher/issues/21'),
      'windows': Skip('https://github.com/dart-lang/watcher/issues/21')
    });

    test('emits events for many nested files added at once', () async {
      withPermutations((i, j, k) => writeFile('sub/sub-$i/sub-$j/file-$k.txt'));

      createDir('dir');
      await startWatcher(path: 'dir');
      renameDir('sub', 'dir/sub');

      await inAnyOrder(withPermutations(
          (i, j, k) => isAddEvent('dir/sub/sub-$i/sub-$j/file-$k.txt')));
    });

    test('emits events for many nested files removed at once', () async {
      withPermutations(
          (i, j, k) => writeFile('dir/sub/sub-$i/sub-$j/file-$k.txt'));

      createDir('dir');
      await startWatcher(path: 'dir');

      // Rename the directory rather than deleting it because native watchers
      // report a rename as a single DELETE event for the directory, whereas
      // they report recursive deletion with DELETE events for every file in the
      // directory.
      renameDir('dir/sub', 'sub');

      await inAnyOrder(withPermutations(
          (i, j, k) => isRemoveEvent('dir/sub/sub-$i/sub-$j/file-$k.txt')));
    });

    test('emits events for many nested files moved at once', () async {
      withPermutations(
          (i, j, k) => writeFile('dir/old/sub-$i/sub-$j/file-$k.txt'));

      createDir('dir');
      await startWatcher(path: 'dir');
      renameDir('dir/old', 'dir/new');

      await inAnyOrder(unionAll(withPermutations((i, j, k) {
        return {
          isRemoveEvent('dir/old/sub-$i/sub-$j/file-$k.txt'),
          isAddEvent('dir/new/sub-$i/sub-$j/file-$k.txt')
        };
      })));
    });

    test(
        'emits events for many files added at once in a subdirectory with the '
        'same name as a removed file', () async {
      writeFile('dir/sub');
      withPermutations((i, j, k) => writeFile('old/sub-$i/sub-$j/file-$k.txt'));
      await startWatcher(path: 'dir');

      deleteFile('dir/sub');
      renameDir('old', 'dir/sub');

      var events = withPermutations(
          (i, j, k) => isAddEvent('dir/sub/sub-$i/sub-$j/file-$k.txt'));
      events.add(isRemoveEvent('dir/sub'));
      await inAnyOrder(events);
    });
  });
}
