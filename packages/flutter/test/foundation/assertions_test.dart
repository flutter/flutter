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
        informationCollector: () sync* {
          yield ErrorDescription('Example information');
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
        informationCollector: () sync* {
          yield ErrorDescription('INFO');
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
        informationCollector: () sync* {
          yield ErrorDescription('INFO');
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
        informationCollector: () sync* {
          yield ErrorDescription('INFO');
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
        informationCollector: () sync* {
          yield ErrorDescription('INFO');
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

  test('Malformed FlutterError objects', () {
    {
      AssertionError error;
      try {
        throw FlutterError(<DiagnosticsNode>[]);
      } on AssertionError catch (e) {
        error = e;
      }
      expect(
        FlutterErrorDetails(exception: error).toString(),
        '══╡ EXCEPTION CAUGHT BY FLUTTER FRAMEWORK ╞══════════════════════\n'
            'The following assertion was thrown:\n'
            'Empty FlutterError\n'
            '═════════════════════════════════════════════════════════════════\n',
      );
    }

    {
      AssertionError error;
      try {
        throw FlutterError(<DiagnosticsNode>[
          (ErrorDescription('Error description without a summary'))]);
      } on AssertionError catch (e) {
        error = e;
      }
      expect(
        FlutterErrorDetails(exception: error).toString(),
        '══╡ EXCEPTION CAUGHT BY FLUTTER FRAMEWORK ╞══════════════════════\n'
        'The following assertion was thrown:\n'
        'FlutterError is missing a summary.\n'
        'All FlutterError objects should start with a short (one line)\n'
        'summary description of the problem that was detected.\n'
        'Malformed FlutterError:\n'
        '  Error description without a summary\n'
        '\n'
        'This error should still help you solve your problem, however\n'
        'please also report this malformed error in the framework by\n'
        'filing a bug on GitHub:\n'
        '  https://github.com/flutter/flutter/issues/new?template=BUG.md\n'
        '═════════════════════════════════════════════════════════════════\n',
      );
    }

    {
      AssertionError error;
      try {
        throw FlutterError(<DiagnosticsNode>[
          ErrorSummary('Error Summary A'),
          ErrorDescription('Some descriptionA'),
          ErrorSummary('Error Summary B'),
          ErrorDescription('Some descriptionB'),
        ]);
      } on AssertionError catch (e) {
        error = e;
      }
      expect(
        FlutterErrorDetails(exception: error).toString(),
        '══╡ EXCEPTION CAUGHT BY FLUTTER FRAMEWORK ╞══════════════════════\n'
        'The following assertion was thrown:\n'
        'FlutterError contained multiple error summaries.\n'
        'All FlutterError objects should have only a single short (one\n'
        'line) summary description of the problem that was detected.\n'
        'Malformed FlutterError:\n'
        '  Error Summary A\n'
        '  Some descriptionA\n'
        '  Error Summary B\n'
        '  Some descriptionB\n'
        '\n'
        'The malformed error has 2 summaries.\n'
        'Summary 1: Error Summary A\n'
        'Summary 2: Error Summary B\n'
        '\n'
        'This error should still help you solve your problem, however\n'
        'please also report this malformed error in the framework by\n'
        'filing a bug on GitHub:\n'
        '  https://github.com/flutter/flutter/issues/new?template=BUG.md\n'
        '═════════════════════════════════════════════════════════════════\n',
      );
    }

    {
      AssertionError error;
      try {
        throw FlutterError(<DiagnosticsNode>[
          ErrorDescription('Some description'),
          ErrorSummary('Error summary'),
        ]);
      } on AssertionError catch (e) {
        error = e;
      }
      expect(
        FlutterErrorDetails(exception: error).toString(),
        '══╡ EXCEPTION CAUGHT BY FLUTTER FRAMEWORK ╞══════════════════════\n'
        'The following assertion was thrown:\n'
        'FlutterError is missing a summary.\n'
        'All FlutterError objects should start with a short (one line)\n'
        'summary description of the problem that was detected.\n'
        'Malformed FlutterError:\n'
        '  Some description\n'
        '  Error summary\n'
        '\n'
        'This error should still help you solve your problem, however\n'
        'please also report this malformed error in the framework by\n'
        'filing a bug on GitHub:\n'
        '  https://github.com/flutter/flutter/issues/new?template=BUG.md\n'
        '═════════════════════════════════════════════════════════════════\n',
      );
    }
  });
}
