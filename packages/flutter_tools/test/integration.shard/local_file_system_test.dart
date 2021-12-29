// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/signals.dart';
import 'package:test/fake.dart';

import '../src/common.dart';

void main() {
  group('LocalFileSystem', () {
    testWithoutContext('.deletePreviousTempDirs() deletes previous temp dirs', () async {
      final Signals signals = Signals.test();
      // create one LocalFileSystem and generate a 'flutter_tools' namespaced
      // temp directory
      final Directory oldTempDir = LocalFileSystem.test(signals: signals)
          .systemTempDirectory
          .createTempSync('foo');
      oldTempDir.childFile('bar.txt').writeAsStringSync('Hello, world!');
      // since we do not call .dispose() on the fs, the temp directory is not
      // deleted
      expect(oldTempDir.existsSync(), true);

      // now create "another" LocalFileSystem, to simulate a second flutter
      // tools invocation
      final LocalFileSystem localFileSystem = LocalFileSystem.test(
        signals: signals,
      );
      localFileSystem.deletePreviousTempDirs();
      expect(oldTempDir.existsSync(), false, reason: '${oldTempDir.path} still exists!');
    });

    testWithoutContext('deletes system temp entry on a fatal signal', () async {
      final FakeProcessSignal fakeSignal = FakeProcessSignal();
      final ProcessSignal signalUnderTest = ProcessSignal(fakeSignal);
      final Completer<void> completer = Completer<void>();
      final Signals signals = Signals.test();
      final LocalFileSystem localFileSystem = LocalFileSystem.test(
        signals: signals,
        fatalSignals: <ProcessSignal>[signalUnderTest],
      );
      final Directory temp = localFileSystem.systemTempDirectory;

      signals.addHandler(signalUnderTest, (ProcessSignal s) {
        completer.complete();
      });

      expect(temp.existsSync(), isTrue);

      fakeSignal.controller.add(fakeSignal);
      await completer.future;

      expect(temp.existsSync(), isFalse);
    });
  });
}

class FakeProcessSignal extends Fake implements io.ProcessSignal {
  final StreamController<io.ProcessSignal> controller = StreamController<io.ProcessSignal>();

  @override
  Stream<io.ProcessSignal> watch() => controller.stream;
}
