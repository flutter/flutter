// Copyright 2014 The Flutter Authors. All rights reserved.
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

  test('Identifies user fault', () {
    // User fault because they called `new Text(null)` from their own code.
    final StackTrace stack = StackTrace.fromString('''#0      _AssertionError._doThrowNew (dart:core-patch/errors_patch.dart:42:39)
#1      _AssertionError._throwNew (dart:core-patch/errors_patch.dart:38:5)
#2      new Text (package:flutter/src/widgets/text.dart:287:10)
#3      _MyHomePageState.build (package:hello_flutter/main.dart:72:16)
#4      StatefulElement.build (package:flutter/src/widgets/framework.dart:4414:27)
#5      ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4303:15)
#6      Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#7      ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#8      StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:4461:11)
#9      ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#10      Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#11     Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#12     SingleChildRenderObjectElement.mount (package:flutter/blah.dart:999:9)''');

    final FlutterErrorDetails details = FlutterErrorDetails(
      exception: AssertionError('Test assertion'),
      stack: stack,
    );

    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    details.debugFillProperties(builder);

    expect(builder.properties.length, 4);
    expect(builder.properties[0].toString(), 'The following assertion was thrown:');
    expect(builder.properties[1].toString(), 'Assertion failed');
    expect(builder.properties[2] is ErrorSpacer, true);
    final DiagnosticsStackTrace trace = builder.properties[3] as DiagnosticsStackTrace;
    expect(trace, isNotNull);
    expect(trace.value, stack);
  });

  test('Identifies our fault', () {
    // Our fault because we should either have an assertion in `text_helper.dart`
    // or we should make sure not to pass bad values into new Text.
    final StackTrace stack = StackTrace.fromString('''#0      _AssertionError._doThrowNew (dart:core-patch/errors_patch.dart:42:39)
#1      _AssertionError._throwNew (dart:core-patch/errors_patch.dart:38:5)
#2      new Text (package:flutter/src/widgets/text.dart:287:10)
#3      new SomeWidgetUsingText (package:flutter/src/widgets/text_helper.dart:287:10)
#4      _MyHomePageState.build (package:hello_flutter/main.dart:72:16)
#5      StatefulElement.build (package:flutter/src/widgets/framework.dart:4414:27)
#6      ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4303:15)
#7      Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#8      ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#9      StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:4461:11)
#10     ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#11     Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#12     Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#13     SingleChildRenderObjectElement.mount (package:flutter/blah.dart:999:9)''');

    final FlutterErrorDetails details = FlutterErrorDetails(
      exception: AssertionError('Test assertion'),
      stack: stack,
    );

    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    details.debugFillProperties(builder);
    expect(builder.properties.length, 6);
    expect(builder.properties[0].toString(), 'The following assertion was thrown:');
    expect(builder.properties[1].toString(), 'Assertion failed');
    expect(builder.properties[2] is ErrorSpacer, true);
    expect(
      builder.properties[3].toString(),
      'Either the assertion indicates an error in the framework itself, or we should '
      'provide substantially more information in this error message to help you determine '
      'and fix the underlying cause.\n'
      'In either case, please report this assertion by filing a bug on GitHub:\n'
      '  https://github.com/flutter/flutter/issues/new?template=BUG.md',
    );
    expect(builder.properties[4] is ErrorSpacer, true);
    final DiagnosticsStackTrace trace = builder.properties[5] as DiagnosticsStackTrace;
    expect(trace, isNotNull);
    expect(trace.value, stack);
  });

  test('defaultStackFilter compresses huge ugly stacks', () {
    expect(
      FlutterError.defaultStackFilter(hugeUglyStack.split('\n')),
      const <String>[
        '#2      new Text (package:flutter/src/widgets/text.dart:287:10)',
        '#3      _MyHomePageState.build (package:assertions/main.dart:100:15)',
        '#4      StatefulElement.build (package:flutter/src/widgets/framework.dart:4414:27)',
        '#5      ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4303:15)',
        '#6      Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)',
        '#7      ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)',
        '#8      StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:4461:11)',
        '#9      ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)',
        '#10     Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)',
        '#11     Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)',
        '#12     SingleChildRenderObjectElement.mount (package:flutter/src/widgets/framework.dart:5525:14)',
        '(elided 2 frames from package:flutter)',
        '#15     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)',
        '(elided 91 frames from package:flutter)',
        '#107    MultiChildRenderObjectElement.mount (package:flutter/src/widgets/framework.dart:5634:32)',
        '(elided 2 frames from package:flutter)',
        '#110    _TheatreElement.mount (package:flutter/src/widgets/overlay.dart:591:16)',
        '(elided 222 frames from package:flutter)',
        '#333    RenderObjectToWidgetElement._rebuild (package:flutter/src/widgets/binding.dart:1054:16)',
        '#334    RenderObjectToWidgetElement.mount (package:flutter/src/widgets/binding.dart:1025:5)',
        '#335    RenderObjectToWidgetAdapter.attachToRenderTree.<anonymous closure> (package:flutter/src/widgets/binding.dart:968:17)',
        '#336    BuildOwner.buildScope (package:flutter/src/widgets/framework.dart:2494:19)',
        '#337    RenderObjectToWidgetAdapter.attachToRenderTree (package:flutter/src/widgets/binding.dart:967:13)',
        '#338    WidgetsBinding.attachRootWidget (package:flutter/src/widgets/binding.dart:848:7)',
        '#339    WidgetsBinding.scheduleAttachRootWidget.<anonymous closure> (package:flutter/src/widgets/binding.dart:830:7)',
        '#348    _Timer._runTimers (dart:isolate-patch/timer_impl.dart:384:19)',
        '#349    _Timer._handleMessage (dart:isolate-patch/timer_impl.dart:418:5)',
        '#350    _RawReceivePortImpl._handleMessage (dart:isolate-patch/isolate_patch.dart:174:12)',
      ],
    );
  });
}

const String hugeUglyStack = '''
#2      new Text (package:flutter/src/widgets/text.dart:287:10)
#3      _MyHomePageState.build (package:assertions/main.dart:100:15)
#4      StatefulElement.build (package:flutter/src/widgets/framework.dart:4414:27)
#5      ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4303:15)
#6      Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#7      ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#8      StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:4461:11)
#9      ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#10     Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#11     Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#12     SingleChildRenderObjectElement.mount (package:flutter/src/widgets/framework.dart:5525:14)
#13     Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#14     Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#15     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#16     Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#17     ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#18     ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#19     Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#20     Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#21     SingleChildRenderObjectElement.mount (package:flutter/src/widgets/framework.dart:5525:14)
#22     Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#23     Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#24     SingleChildRenderObjectElement.mount (package:flutter/src/widgets/framework.dart:5525:14)
#25     Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#26     Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#27     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#28     Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#29     ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#30     StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:4461:11)
#31     ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#32     Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#33     Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#34     SingleChildRenderObjectElement.mount (package:flutter/src/widgets/framework.dart:5525:14)
#35     Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#36     Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#37     SingleChildRenderObjectElement.mount (package:flutter/src/widgets/framework.dart:5525:14)
#38     Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#39     Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#40     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#41     Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#42     ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#43     StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:4461:11)
#44     ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#45     Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#46     Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#47     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#48     Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#49     ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#50     ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#51     Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#52     Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#53     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#54     Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#55     ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#56     StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:4461:11)
#57     ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#58     Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#59     Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#60     SingleChildRenderObjectElement.mount (package:flutter/src/widgets/framework.dart:5525:14)
#61     Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#62     Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#63     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#64     Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#65     ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#66     ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#67     Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#68     Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#69     SingleChildRenderObjectElement.mount (package:flutter/src/widgets/framework.dart:5525:14)
#70     Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#71     Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#72     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#73     Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#74     ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#75     StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:4461:11)
#76     ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#77     Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#78     Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#79     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#80     Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#81     ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#82     ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#83     Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#84     Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#85     SingleChildRenderObjectElement.mount (package:flutter/src/widgets/framework.dart:5525:14)
#86     Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#87     Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#88     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#89     Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#90     ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#91     ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#92     Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#93     Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#94     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#95     Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#96     ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#97     StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:4461:11)
#98     ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#99     Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#100    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#101    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#102    Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#103    ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#104    StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:4461:11)
#105    ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#106    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#107    MultiChildRenderObjectElement.mount (package:flutter/src/widgets/framework.dart:5634:32)
#108    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#109    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#110    _TheatreElement.mount (package:flutter/src/widgets/overlay.dart:591:16)
#111    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#112    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#113    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#114    Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#115    ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#116    StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:4461:11)
#117    ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#118    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#119    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#120    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#121    Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#122    ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#123    ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#124    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#125    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#126    SingleChildRenderObjectElement.mount (package:flutter/src/widgets/framework.dart:5525:14)
#127    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#128    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#129    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#130    Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#131    ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#132    StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:4461:11)
#133    ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#134    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#135    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#136    SingleChildRenderObjectElement.mount (package:flutter/src/widgets/framework.dart:5525:14)
#137    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#138    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#139    SingleChildRenderObjectElement.mount (package:flutter/src/widgets/framework.dart:5525:14)
#140    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#141    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#142    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#143    Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#144    ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#145    ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#146    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#147    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#148    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#149    Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#150    ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#151    StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:4461:11)
#152    ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#153    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#154    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#155    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#156    Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#157    ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#158    ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#159    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#160    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#161    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#162    Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#163    ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#164    ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#165    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#166    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#167    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#168    Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#169    ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#170    ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#171    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#172    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#173    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#174    Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#175    ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#176    ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#177    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#178    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#179    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#180    Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#181    ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#182    ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#183    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#184    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#185    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#186    Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#187    ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#188    ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#189    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#190    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#191    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#192    Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#193    ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#194    StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:4461:11)
#195    ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#196    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#197    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#198    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#199    Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#200    ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#201    ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#202    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#203    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#204    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#205    Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#206    ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#207    ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#208    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#209    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#210    SingleChildRenderObjectElement.mount (package:flutter/src/widgets/framework.dart:5525:14)
#211    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#212    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#213    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#214    Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#215    ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#216    ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#217    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#218    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#219    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#220    Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#221    ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#222    ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#223    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#224    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#225    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#226    Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#227    ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#228    ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#229    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#230    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#231    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#232    Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#233    ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#234    ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#235    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#236    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#237    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#238    Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#239    ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#240    ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#241    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#242    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#243    SingleChildRenderObjectElement.mount (package:flutter/src/widgets/framework.dart:5525:14)
#244    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#245    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#246    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#247    Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#248    ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#249    StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:4461:11)
#250    ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#251    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#252    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#253    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#254    Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#255    ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#256    ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#257    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#258    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#259    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#260    Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#261    ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#262    StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:4461:11)
#263    ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#264    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#265    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#266    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#267    Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#268    ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#269    ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#270    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#271    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#272    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#273    Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#274    ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#275    ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#276    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#277    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#278    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#279    Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#280    ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#281    ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#282    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#283    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#284    SingleChildRenderObjectElement.mount (package:flutter/src/widgets/framework.dart:5525:14)
#285    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#286    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#287    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#288    Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#289    ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#290    ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#291    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#292    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#293    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#294    Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#295    ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#296    StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:4461:11)
#297    ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#298    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#299    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#300    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#301    Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#302    ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#303    StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:4461:11)
#304    ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#305    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#306    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#307    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#308    Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#309    ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#310    StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:4461:11)
#311    ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#312    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#313    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#314    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#315    Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#316    ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#317    ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#318    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#319    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#320    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#321    Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#322    ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#323    StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:4461:11)
#324    ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#325    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#326    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#327    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:4323:16)
#328    Element.rebuild (package:flutter/src/widgets/framework.dart:4027:5)
#329    ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:4286:5)
#330    ComponentElement.mount (package:flutter/src/widgets/framework.dart:4281:5)
#331    Element.inflateWidget (package:flutter/src/widgets/framework.dart:3276:14)
#332    Element.updateChild (package:flutter/src/widgets/framework.dart:3070:12)
#333    RenderObjectToWidgetElement._rebuild (package:flutter/src/widgets/binding.dart:1054:16)
#334    RenderObjectToWidgetElement.mount (package:flutter/src/widgets/binding.dart:1025:5)
#335    RenderObjectToWidgetAdapter.attachToRenderTree.<anonymous closure> (package:flutter/src/widgets/binding.dart:968:17)
#336    BuildOwner.buildScope (package:flutter/src/widgets/framework.dart:2494:19)
#337    RenderObjectToWidgetAdapter.attachToRenderTree (package:flutter/src/widgets/binding.dart:967:13)
#338    WidgetsBinding.attachRootWidget (package:flutter/src/widgets/binding.dart:848:7)
#339    WidgetsBinding.scheduleAttachRootWidget.<anonymous closure> (package:flutter/src/widgets/binding.dart:830:7)
#348    _Timer._runTimers (dart:isolate-patch/timer_impl.dart:384:19)
#349    _Timer._handleMessage (dart:isolate-patch/timer_impl.dart:418:5)
#350    _RawReceivePortImpl._handleMessage (dart:isolate-patch/isolate_patch.dart:174:12)''';