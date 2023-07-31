// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:watcher/watcher.dart';

import 'physical_file_system_test.dart' show BaseTest;

main() {
  if (!bool.fromEnvironment('skipPhysicalResourceProviderTests')) {
    defineReflectiveSuite(() {
      defineReflectiveTests(PhysicalResourceProviderWatchTest);
    });
  }
}

@reflectiveTest
class PhysicalResourceProviderWatchTest extends BaseTest {
  test_watchFile_delete() {
    var filePath = path.join(tempPath, 'foo');
    var file = io.File(filePath);
    file.writeAsStringSync('contents 1');
    return _watchingFile(filePath, (changesReceived) {
      expect(changesReceived, hasLength(0));
      file.deleteSync();
      return _delayed(() {
        expect(changesReceived, hasLength(1));
        if (io.Platform.isWindows) {
          // See https://github.com/dart-lang/sdk/issues/23762
          // Not sure why this breaks under Windows, but testing to see whether
          // we are running Windows causes the type to change. For now we print
          // the type out of curiosity.
          print('PhysicalResourceProviderWatchTest:test_watchFile_delete '
              'received an event with type = ${changesReceived[0].type}');
        } else {
          expect(changesReceived[0].type, equals(ChangeType.REMOVE));
        }
        expect(changesReceived[0].path, equals(filePath));
      });
    });
  }

  test_watchFile_modify() {
    var filePath = path.join(tempPath, 'foo');
    var file = io.File(filePath);
    file.writeAsStringSync('contents 1');
    return _watchingFile(filePath, (changesReceived) {
      expect(changesReceived, hasLength(0));
      file.writeAsStringSync('contents 2');
      return _delayed(() {
        expect(changesReceived, hasLength(1));
        expect(changesReceived[0].type, equals(ChangeType.MODIFY));
        expect(changesReceived[0].path, equals(filePath));
      });
    });
  }

  test_watchFolder_createFile() {
    return _watchingFolder(tempPath, (changesReceived) {
      expect(changesReceived, hasLength(0));
      var filePath = path.join(tempPath, 'foo');
      io.File(filePath).writeAsStringSync('contents');
      return _delayed(() {
        // There should be an "add" event indicating that the file was added.
        // Depending on how long it took to write the contents, it may be
        // followed by "modify" events.
        expect(changesReceived, isNotEmpty);
        expect(changesReceived[0].type, equals(ChangeType.ADD));
        expect(changesReceived[0].path, equals(filePath));
        for (int i = 1; i < changesReceived.length; i++) {
          expect(changesReceived[i].type, equals(ChangeType.MODIFY));
          expect(changesReceived[i].path, equals(filePath));
        }
      });
    });
  }

  test_watchFolder_deleteFile() {
    var filePath = path.join(tempPath, 'foo');
    var file = io.File(filePath);
    file.writeAsStringSync('contents 1');
    return _watchingFolder(tempPath, (changesReceived) {
      expect(changesReceived, hasLength(0));
      file.deleteSync();
      return _delayed(() {
        expect(changesReceived, hasLength(1));
        expect(changesReceived[0].type, equals(ChangeType.REMOVE));
        expect(changesReceived[0].path, equals(filePath));
      });
    });
  }

  test_watchFolder_modifyFile() {
    var filePath = path.join(tempPath, 'foo');
    var file = io.File(filePath);
    file.writeAsStringSync('contents 1');
    return _watchingFolder(tempPath, (changesReceived) {
      expect(changesReceived, hasLength(0));
      file.writeAsStringSync('contents 2');
      return _delayed(() {
        expect(changesReceived, hasLength(1));
        expect(changesReceived[0].type, equals(ChangeType.MODIFY));
        expect(changesReceived[0].path, equals(filePath));
      });
    });
  }

  test_watchFolder_modifyFile_inSubDir() {
    var fooPath = path.join(tempPath, 'foo');
    io.Directory(fooPath).createSync();
    var barPath = path.join(tempPath, 'bar');
    var file = io.File(barPath);
    file.writeAsStringSync('contents 1');
    return _watchingFolder(tempPath, (changesReceived) {
      expect(changesReceived, hasLength(0));
      file.writeAsStringSync('contents 2');
      return _delayed(() {
        expect(changesReceived, anyOf(hasLength(1), hasLength(2)));
        expect(changesReceived[0].type, equals(ChangeType.MODIFY));
        expect(changesReceived[0].path, equals(barPath));
      });
    });
  }

  Future _delayed(Function() computation) {
    // Give the tests 1 second to detect the changes. While it may only
    // take up to a few hundred ms, a whole second gives a good margin
    // for when running tests.
    return Future.delayed(Duration(seconds: 1), computation);
  }

  _watchingFile(
      String filePath, Function(List<WatchEvent> changesReceived) test) {
    // Delay before we start watching the file.  This is necessary
    // because on MacOS, file modifications that occur just before we
    // start watching are sometimes misclassified as happening just after
    // we start watching.
    return _delayed(() {
      var file =
          PhysicalResourceProvider.INSTANCE.getResource(filePath) as File;
      var changesReceived = <WatchEvent>[];
      var subscription = file.watch().changes.listen(changesReceived.add);
      // Delay running the rest of the test to allow file.changes propagate.
      return _delayed(() => test(changesReceived)).whenComplete(() {
        subscription.cancel();
      });
    });
  }

  _watchingFolder(
      String filePath, Function(List<WatchEvent> changesReceived) test) {
    // Delay before we start watching the folder.  This is necessary
    // because on MacOS, file modifications that occur just before we
    // start watching are sometimes misclassified as happening just after
    // we start watching.
    return _delayed(() {
      var folder =
          PhysicalResourceProvider.INSTANCE.getResource(filePath) as Folder;
      var changesReceived = <WatchEvent>[];
      var subscription = folder.watch().changes.listen(changesReceived.add);
      // Delay running the rest of the test to allow folder.changes to
      // take a snapshot of the current directory state.  Otherwise it
      // won't be able to reliably distinguish new files from modified
      // ones.
      return _delayed(() => test(changesReceived)).whenComplete(() {
        subscription.cancel();
      });
    });
  }
}
