import 'dart:async';
import 'dart:io' as io;

import 'package:flutter_tools/src/base/io.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../context.dart';

void main() {
  group('ProcessSignal', () {

    testUsingContext('signals are properly delegated', () async {
      final MockIoProcessSignal mockSignal = new MockIoProcessSignal();
      final ProcessSignal signalUnderTest = new ProcessSignal(mockSignal);
      final StreamController<io.ProcessSignal> controller = new StreamController<io.ProcessSignal>();

      when(mockSignal.watch()).thenReturn(controller.stream);
      controller.add(mockSignal);

      expect(signalUnderTest, await signalUnderTest.watch().first);
    });

    testUsingContext('toString() works', () async {
      expect(io.ProcessSignal.SIGINT.toString(), ProcessSignal.SIGINT.toString());
    });
  });
}

class MockIoProcessSignal extends Mock implements io.ProcessSignal {}