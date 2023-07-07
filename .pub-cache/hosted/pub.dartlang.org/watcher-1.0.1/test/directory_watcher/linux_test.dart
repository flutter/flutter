// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('linux')

import 'package:test/test.dart';
import 'package:watcher/src/directory_watcher/linux.dart';
import 'package:watcher/watcher.dart';

import 'shared.dart';
import '../utils.dart';

void main() {
  watcherFactory = (dir) => LinuxDirectoryWatcher(dir);

  sharedTests();

  test('DirectoryWatcher creates a LinuxDirectoryWatcher on Linux', () {
    expect(DirectoryWatcher('.'), TypeMatcher<LinuxDirectoryWatcher>());
  });

  test('emits events for many nested files moved out then immediately back in',
      () async {
    withPermutations(
        (i, j, k) => writeFile('dir/sub/sub-$i/sub-$j/file-$k.txt'));
    await startWatcher(path: 'dir');

    renameDir('dir/sub', 'sub');
    renameDir('sub', 'dir/sub');

    await allowEither(() {
      inAnyOrder(withPermutations(
          (i, j, k) => isRemoveEvent('dir/sub/sub-$i/sub-$j/file-$k.txt')));

      inAnyOrder(withPermutations(
          (i, j, k) => isAddEvent('dir/sub/sub-$i/sub-$j/file-$k.txt')));
    }, () {
      inAnyOrder(withPermutations(
          (i, j, k) => isModifyEvent('dir/sub/sub-$i/sub-$j/file-$k.txt')));
    });
  });
}
