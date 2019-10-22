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
  }, skip: isBrowser);

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
  }, skip: isBrowser);

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
        '\n'
        'INFO\n'
        '═════════════════════════════════════════════════════════════════\n',

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
      '\n'
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
        '\n'
        'INFO\n'
        '═════════════════════════════════════════════════════════════════\n',
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
      '\n'
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
      '═════════════════════════════════════════════════════════════════\n',
    );
    expect(
      const FlutterErrorDetails().toString(),
      '══╡ EXCEPTION CAUGHT BY FLUTTER FRAMEWORK ╞══════════════════════\n'
      'The following Null object was thrown:\n'
      '  null\n'
      '═════════════════════════════════════════════════════════════════\n',
    );
  });

  test('FlutterErrorDetails.toStringShort', () {
    expect(
        FlutterErrorDetails(
          exception: 'MESSAGE',
          library: 'library',
          context: ErrorDescription('CONTEXTING'),
          informationCollector: () sync* {
            yield ErrorDescription('INFO');
          },
        ).toStringShort(),
        'Exception caught by library',
    );
  });

  test('FlutterError default constructor', () {
    FlutterError error = FlutterError(
      'My Error Summary.\n'
      'My first description.\n'
      'My second description.'
    );
    expect(error.diagnostics.length, equals(3));
    expect(error.diagnostics[0].level, DiagnosticLevel.summary);
    expect(error.diagnostics[1].level, DiagnosticLevel.info);
    expect(error.diagnostics[2].level, DiagnosticLevel.info);
    expect(error.diagnostics[0].toString(), 'My Error Summary.');
    expect(error.diagnostics[1].toString(), 'My first description.');
    expect(error.diagnostics[2].toString(), 'My second description.');
    expect(
      error.toStringDeep(),
      'FlutterError\n'
      '   My Error Summary.\n'
      '   My first description.\n'
      '   My second description.\n',
    );

    error = FlutterError(
      'My Error Summary.\n'
      'My first description.\n'
      'My second description.\n'
      '\n'
    );

    expect(error.diagnostics.length, equals(5));
    expect(error.diagnostics[0].level, DiagnosticLevel.summary);
    expect(error.diagnostics[1].level, DiagnosticLevel.info);
    expect(error.diagnostics[2].level, DiagnosticLevel.info);
    expect(error.diagnostics[0].toString(), 'My Error Summary.');
    expect(error.diagnostics[1].toString(), 'My first description.');
    expect(error.diagnostics[2].toString(), 'My second description.');
    expect(error.diagnostics[3].toString(), '');
    expect(error.diagnostics[4].toString(), '');
    expect(
      error.toStringDeep(),
      'FlutterError\n'
      '   My Error Summary.\n'
      '   My first description.\n'
      '   My second description.\n'
      '\n'
      '\n',
    );

    error = FlutterError(
      'My Error Summary.\n'
      'My first description.\n'
      '\n'
      'My second description.'
    );
    expect(error.diagnostics.length, equals(4));
    expect(error.diagnostics[0].level, DiagnosticLevel.summary);
    expect(error.diagnostics[1].level, DiagnosticLevel.info);
    expect(error.diagnostics[2].level, DiagnosticLevel.info);
    expect(error.diagnostics[3].level, DiagnosticLevel.info);
    expect(error.diagnostics[0].toString(), 'My Error Summary.');
    expect(error.diagnostics[1].toString(), 'My first description.');
    expect(error.diagnostics[2].toString(), '');
    expect(error.diagnostics[3].toString(), 'My second description.');

    expect(
      error.toStringDeep(),
      'FlutterError\n'
      '   My Error Summary.\n'
      '   My first description.\n'
      '\n'
      '   My second description.\n',
    );
    error = FlutterError('My Error Summary.');
    expect(error.diagnostics.length, 1);
    expect(error.diagnostics.first.level, DiagnosticLevel.summary);
    expect(error.diagnostics.first.toString(), 'My Error Summary.');

    expect(
      error.toStringDeep(),
      'FlutterError\n'
      '   My Error Summary.\n',
    );
  });

  test('Malformed FlutterError objects', () {
    {
      AssertionError error;
      try {
        throw FlutterError.fromParts(<DiagnosticsNode>[]);
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
        throw FlutterError.fromParts(<DiagnosticsNode>[
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
        throw FlutterError.fromParts(<DiagnosticsNode>[
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
        throw FlutterError.fromParts(<DiagnosticsNode>[
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

  test('User-thrown exceptions have ErrorSummary properties', () {
    {
      DiagnosticsNode node;
      try {
        throw 'User thrown string';
      } catch (e) {
        node = FlutterErrorDetails(exception: e).toDiagnosticsNode();
      }
      final ErrorSummary summary = node.getProperties().whereType<ErrorSummary>().single;
      expect(summary.value, equals(<String>['User thrown string']));
    }

    {
      DiagnosticsNode node;
      try {
        throw ArgumentError.notNull('myArgument');
      } catch (e) {
        node = FlutterErrorDetails(exception: e).toDiagnosticsNode();
      }
      final ErrorSummary summary = node.getProperties().whereType<ErrorSummary>().single;
      expect(summary.value, equals(<String>['Invalid argument(s) (myArgument): Must not be null']));
    }
  });
}
