// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import '../flutter_test_alternative.dart';

import 'capture_output.dart';

void main() {
  test('debugPrintStack', () {
    final List<String> log = captureOutput(() {
      debugPrintStack(label: 'Example label', maxFrames: 7);
    });
    expect(log[0], contains('Example label'));
    expect(log[1], contains('debugPrintStack'));
  });

  test('debugPrintStack', () {
    final List<String> log = captureOutput(() {
      final FlutterErrorDetails details = FlutterErrorDetails(
        exception: 'Example exception',
        stack: StackTrace.current,
        library: 'Example library',
        context: ErrorDescription('Example context'),
        informationCollector: (List<DiagnosticsNode> information) {
          information.add(ErrorDescription('Example information'));
        },
      );

      FlutterError.dumpErrorToConsole(details);
    });

    expect(log[0], contains('EXAMPLE LIBRARY'));
    expect(log[1], contains('Example context'));
    expect(log[2], contains('Example exception'));

    final String joined = log.join('\n');

    expect(joined, contains('captureOutput'));
    expect(joined, contains('\nExample information\n'));
  });

  test('FlutterErrorDetails.toString', () {
    expect(
      FlutterErrorDetails(
        exception: 'MESSAGE',
        library: 'LIBRARY',
        context: ErrorDescription('CONTEXTING'),
        informationCollector: (List<DiagnosticsNode> information) {
          information.add(ErrorDescription('INFO'));
        },
      ).toString(),
        '══╡ EXCEPTION CAUGHT BY LIBRARY ╞════════════════════════════════\n'
        'The following message was thrown CONTEXTING:\n'
        'MESSAGE\n'
        'INFO\n'
        '═════════════════════════════════════════════════════════════════\n'

    );
    expect(
      FlutterErrorDetails(
        library: 'LIBRARY',
        context: ErrorDescription('CONTEXTING'),
        informationCollector: (List<DiagnosticsNode> information) {
          information.add(ErrorDescription('INFO'));
        },
      ).toString(),
      '══╡ EXCEPTION CAUGHT BY LIBRARY ╞════════════════════════════════\n'
      'The following Null object was thrown CONTEXTING:\n'
      '  null\n'
      'INFO\n'
      '═════════════════════════════════════════════════════════════════\n',
    );
    expect(
      FlutterErrorDetails(
        exception: 'MESSAGE',
        context: ErrorDescription('CONTEXTING'),
        informationCollector: (List<DiagnosticsNode> information) {
          information.add(ErrorDescription('INFO'));
        },
      ).toString(),
        '══╡ EXCEPTION CAUGHT BY FLUTTER FRAMEWORK ╞══════════════════════\n'
        'The following message was thrown CONTEXTING:\n'
        'MESSAGE\n'
        'INFO\n'
        '═════════════════════════════════════════════════════════════════\n'
    );
    expect(
      FlutterErrorDetails(
        exception: 'MESSAGE',
        context: ErrorDescription('CONTEXTING ${'SomeContext(BlaBla)'}'),
        informationCollector: (List<DiagnosticsNode> information) {
          information.add(ErrorDescription('INFO'));
        },
      ).toString(),
      '══╡ EXCEPTION CAUGHT BY FLUTTER FRAMEWORK ╞══════════════════════\n'
      'The following message was thrown CONTEXTING SomeContext(BlaBla):\n'
      'MESSAGE\n'
      'INFO\n'
      '═════════════════════════════════════════════════════════════════\n',
    );
    expect(
      const FlutterErrorDetails(
        exception: 'MESSAGE',
      ).toString(),
      '══╡ EXCEPTION CAUGHT BY FLUTTER FRAMEWORK ╞══════════════════════\n'
      'The following message was thrown:\n'
      'MESSAGE\n'
      '═════════════════════════════════════════════════════════════════\n'
    );
    expect(
      const FlutterErrorDetails().toString(),
      '══╡ EXCEPTION CAUGHT BY FLUTTER FRAMEWORK ╞══════════════════════\n'
      'The following Null object was thrown:\n'
      '  null\n'
      '═════════════════════════════════════════════════════════════════\n'
    );
  });
}
