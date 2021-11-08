// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// The purpose of this test is to verify the end-to-end behavior of
// "flutter run" and other such commands, as closely as possible to
// the default behavior. To that end, it avoids the use of any test
// features that are not critical (-dflutter-test being the primary
// example of a test feature that it does use). For example, no use
// is made of "--machine" in these tests.

// There are a number of risks when it comes to writing a test such
// as this one. Typically these tests are hard to debug if they are
// in a failing condition, because they just hang as they await the
// next expected line that never comes. To avoid this, here we have
// the policy of looking for multiple lines, printing what expected
// lines were not seen when a short timeout expires (but timing out
// does not cause the test to fail, to reduce flakes), and wherever
// possible recording all output and comparing the actual output to
// the expected output only once the test is completed.

// To aid in debugging, consider passing the `debug: true` argument
// to the runFlutter function.

// @dart = 2.8
// This file is ready to transition, just uncomment /*?*/, /*!*/, and /*late*/.

// This file intentionally assumes the tests run in order.
@Tags(<String>['no-shuffle'])

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import 'test_utils.dart' show fileSystem;

const ProcessManager processManager = LocalProcessManager();
final String flutterRoot = getFlutterRoot();
final String flutterBin = fileSystem.path.join(flutterRoot, 'bin', 'flutter');

void debugPrint(String message) {
  // This is called to intentionally print debugging output when a test is
  // either taking too long or has failed.
  // ignore: avoid_print
  print(message);
}

typedef LineHandler = String/*?*/ Function(String line);

abstract class Transition {
  const Transition({this.handler, this.logging});

  /// Callback that is invoked when the transition matches.
  ///
  /// This should not throw, even if the test is failing. (For example, don't use "expect"
  /// in these callbacks.) Throwing here would prevent the [runFlutter] function from running
  /// to completion, which would leave zombie `flutter` processes around.
  final LineHandler/*?*/ handler;

  /// Whether to enable or disable logging when this transition is matched.
  ///
  /// The default value, null, leaves the logging state unaffected.
  final bool/*?*/ logging;

  bool matches(String line);

  @protected
  bool lineMatchesPattern(String line, Pattern pattern) {
    if (pattern is String) {
      return line == pattern;
    }
    return line.contains(pattern);
  }

  @protected
  String describe(Pattern pattern) {
    if (pattern is String) {
      return '"$pattern"';
    }
    if (pattern is RegExp) {
      return '/${pattern.pattern}/';
    }
    return '$pattern';
  }
}

class Barrier extends Transition {
  const Barrier(this.pattern, {LineHandler/*?*/ handler, bool/*?*/ logging}) : super(handler: handler, logging: logging);
  final Pattern pattern;

  @override
  bool matches(String line) => lineMatchesPattern(line, pattern);

  @override
  String toString() => describe(pattern);
}

class Multiple extends Transition {
  Multiple(List<Pattern> patterns, {
    LineHandler/*?*/ handler,
    bool/*?*/ logging,
  }) : _originalPatterns = patterns,
       patterns = patterns.toList(),
       super(handler: handler, logging: logging);

  final List<Pattern> _originalPatterns;
  final List<Pattern> patterns;

  @override
  bool matches(String line) {
    for (int index = 0; index < patterns.length; index += 1) {
      if (lineMatchesPattern(line, patterns[index])) {
        patterns.removeAt(index);
        break;
      }
    }
    return patterns.isEmpty;
  }

  @override
  String toString() {
    if (patterns.isEmpty) {
      return '${_originalPatterns.map(describe).join(', ')} (all matched)';
    }
    return '${_originalPatterns.map(describe).join(', ')} (matched ${_originalPatterns.length - patterns.length} so far)';
  }
}

class LogLine {
  const LogLine(this.channel, this.stamp, this.message);
  final String channel;
  final String stamp;
  final String message;

  bool get couldBeCrash => message.contains('Oops; flutter has exited unexpectedly:');

  @override
  String toString() => '$stamp $channel: $message';

  void printClearly() {
    debugPrint('$stamp $channel: ${clarify(message)}');
  }

  static String clarify(String line) {
    return line.runes.map<String>((int rune) {
      if (rune >= 0x20 && rune <= 0x7F) {
        return String.fromCharCode(rune);
      }
      switch (rune) {
        case 0x00: return '<NUL>';
        case 0x07: return '<BEL>';
        case 0x08: return '<TAB>';
        case 0x09: return '<BS>';
        case 0x0A: return '<LF>';
        case 0x0D: return '<CR>';
      }
      return '<${rune.toRadixString(16).padLeft(rune <= 0xFF ? 2 : rune <= 0xFFFF ? 4 : 5, '0')}>';
    }).join('');
  }
}

class ProcessTestResult {
  const ProcessTestResult(this.exitCode, this.logs);
  final int exitCode;
  final List<LogLine> logs;

  List<String> get stdout {
    return logs
      .where((LogLine log) => log.channel == 'stdout')
      .map<String>((LogLine log) => log.message)
      .toList();
  }

  List<String> get stderr {
    return logs
      .where((LogLine log) => log.channel == 'stderr')
      .map<String>((LogLine log) => log.message)
      .toList();
  }

  @override
  String toString() => 'exit code $exitCode\nlogs:\n  ${logs.join('\n  ')}\n';
}

Future<ProcessTestResult> runFlutter(
  List<String> arguments,
  String workingDirectory,
  List<Transition> transitions, {
  bool debug = false,
  bool logging = true,
  Duration expectedMaxDuration = const Duration(minutes: 10), // must be less than test timeout of 15 minutes! See ../../dart_test.yaml.
}) async {
  final Stopwatch clock = Stopwatch()..start();
  final Process process = await processManager.start(
    <String>[flutterBin, ...arguments],
    workingDirectory: workingDirectory,
  );
  final List<LogLine> logs = <LogLine>[];
  int nextTransition = 0;
  void describeStatus() {
    if (transitions.isNotEmpty) {
      debugPrint('Expected state transitions:');
      for (int index = 0; index < transitions.length; index += 1) {
        debugPrint(
          '${index.toString().padLeft(5)} '
          '${index <  nextTransition ? 'ALREADY MATCHED ' :
             index == nextTransition ? 'NOW WAITING FOR>' :
                                       '                '} ${transitions[index]}');
      }
    }
    if (logs.isEmpty) {
      debugPrint('So far nothing has been logged${ debug ? "" : "; use debug:true to print all output" }.');
    } else {
      debugPrint('Log${ debug ? "" : " (only contains logged lines; use debug:true to print all output)" }:');
      for (final LogLine log in logs) {
        log.printClearly();
      }
    }
  }
  bool streamingLogs = false;
  Timer/*?*/ timeout;
  void processTimeout() {
    if (!streamingLogs) {
      streamingLogs = true;
      if (!debug) {
        debugPrint('Test is taking a long time (${clock.elapsed.inSeconds} seconds so far).');
      }
      describeStatus();
      debugPrint('(streaming all logs from this point on...)');
    } else {
      debugPrint('(taking a long time...)');
    }
  }
  String stamp() => '[${(clock.elapsed.inMilliseconds / 1000.0).toStringAsFixed(1).padLeft(5, " ")}s]';
  void processStdout(String line) {
    final LogLine log = LogLine('stdout', stamp(), line);
    if (logging) {
      logs.add(log);
    }
    if (streamingLogs) {
      log.printClearly();
    }
    if (nextTransition < transitions.length && transitions[nextTransition].matches(line)) {
      if (streamingLogs) {
        debugPrint('(matched ${transitions[nextTransition]})');
      }
      if (transitions[nextTransition].logging != null) {
        if (!logging && transitions[nextTransition].logging/*!*/) {
          logs.add(log);
        }
        logging = transitions[nextTransition].logging/*!*/;
        if (streamingLogs) {
          if (logging) {
            debugPrint('(enabled logging)');
          } else {
            debugPrint('(disabled logging)');
          }
        }
      }
      if (transitions[nextTransition].handler != null) {
        final String/*?*/ command = transitions[nextTransition].handler/*!*/(line);
        if (command != null) {
          final LogLine inLog = LogLine('stdin', stamp(), command);
          logs.add(inLog);
          if (streamingLogs) {
            inLog.printClearly();
          }
          process.stdin.write(command);
        }
      }
      nextTransition += 1;
      timeout?.cancel();
      timeout = Timer(expectedMaxDuration ~/ 5, processTimeout); // This is not a failure timeout, just when to start logging verbosely to help debugging.
    }
  }
  void processStderr(String line) {
    final LogLine log = LogLine('stdout', stamp(), line);
    logs.add(log);
    if (streamingLogs) {
      log.printClearly();
    }
  }
  if (debug) {
    processTimeout();
  } else {
    timeout = Timer(expectedMaxDuration ~/ 2, processTimeout); // This is not a failure timeout, just when to start logging verbosely to help debugging.
  }
  process.stdout.transform<String>(utf8.decoder).transform<String>(const LineSplitter()).listen(processStdout);
  process.stderr.transform<String>(utf8.decoder).transform<String>(const LineSplitter()).listen(processStderr);
  unawaited(process.exitCode.timeout(expectedMaxDuration, onTimeout: () { // This is a failure timeout, must not be short.
    debugPrint('${stamp()} (process is not quitting, trying to send a "q" just in case that helps)');
    debugPrint('(a functional test should never reach this point)');
    final LogLine inLog = LogLine('stdin', stamp(), 'q');
    logs.add(inLog);
    if (streamingLogs) {
      inLog.printClearly();
    }
    process.stdin.write('q');
    return -1; // discarded
  }).catchError((Object error) { /* ignore errors here, they will be reported on the next line */ }));
  final int exitCode = await process.exitCode;
  if (streamingLogs) {
    debugPrint('${stamp()} (process terminated with exit code $exitCode)');
  }
  timeout?.cancel();
  if (nextTransition < transitions.length) {
    debugPrint('The subprocess terminated before all the expected transitions had been matched.');
    if (logs.any((LogLine line) => line.couldBeCrash)) {
      debugPrint('The subprocess may in fact have crashed. Check the stderr logs below.');
    }
    debugPrint('The transition that we were hoping to see next but that we never saw was:');
    debugPrint('${nextTransition.toString().padLeft(5)} NOW WAITING FOR> ${transitions[nextTransition]}');
    if (!streamingLogs) {
      describeStatus();
      debugPrint('(process terminated with exit code $exitCode)');
    }
    throw TestFailure('Missed some expected transitions.');
  }
  if (streamingLogs) {
    debugPrint('${stamp()} (completed execution successfully!)');
  }
  return ProcessTestResult(exitCode, logs);
}

const int progressMessageWidth = 64;

void main() {
  testWithoutContext('flutter run writes and clears pidfile appropriately', () async {
    final String tempDirectory = fileSystem.systemTempDirectory.createTempSync('flutter_overall_experience_test.').resolveSymbolicLinksSync();
    final String pidFile = fileSystem.path.join(tempDirectory, 'flutter.pid');
    final String testDirectory = fileSystem.path.join(flutterRoot, 'examples', 'hello_world');
    bool/*?*/ existsDuringTest;
    try {
      expect(fileSystem.file(pidFile).existsSync(), isFalse);
      final ProcessTestResult result = await runFlutter(
        <String>['run', '-dflutter-tester', '--pid-file', pidFile],
        testDirectory,
        <Transition>[
          Barrier('q Quit (terminate the application on the device).', handler: (String line) {
            existsDuringTest = fileSystem.file(pidFile).existsSync();
            return 'q';
          }),
          const Barrier('Application finished.'),
        ],
      );
      expect(existsDuringTest, isNot(isNull));
      expect(existsDuringTest, isTrue);
      expect(result.exitCode, 0, reason: 'subprocess failed; $result');
      expect(fileSystem.file(pidFile).existsSync(), isFalse);
      // This first test ignores the stdout and stderr, so that if the
      // first run outputs "building flutter", or the "there's a new
      // flutter" banner, or other such first-run messages, they won't
      // fail the tests. This does mean that running this test first is
      // actually important in the case where you're running the tests
      // manually. (On CI, all those messages are expected to be seen
      // long before we get here, e.g. because we run "flutter doctor".)
    } finally {
      tryToDelete(fileSystem.directory(tempDirectory));
    }
    // This test is expected to be skipped when Platform.isWindows:
    // [intended] Windows doesn't support sending signals so we don't care if it can store the PID.
  }, skip: true); // Flake: https://github.com/flutter/flutter/issues/92042

  testWithoutContext('flutter run handle SIGUSR1/2', () async {
    final String tempDirectory = fileSystem.systemTempDirectory.createTempSync('flutter_overall_experience_test.').resolveSymbolicLinksSync();
    final String pidFile = fileSystem.path.join(tempDirectory, 'flutter.pid');
    final String testDirectory = fileSystem.path.join(flutterRoot, 'dev', 'integration_tests', 'ui');
    final String testScript = fileSystem.path.join('lib', 'commands.dart');
    /*late*/ int pid;
    try {
      final ProcessTestResult result = await runFlutter(
        <String>['run', '-dflutter-tester', '--report-ready', '--pid-file', pidFile, '--no-devtools', testScript],
        testDirectory,
        <Transition>[
          Multiple(<Pattern>['Flutter run key commands.', 'called paint'], handler: (String line) {
            pid = int.parse(fileSystem.file(pidFile).readAsStringSync());
            processManager.killPid(pid, ProcessSignal.sigusr1);
            return null;
          }),
          Barrier('Performing hot reload...'.padRight(progressMessageWidth), logging: true),
          Multiple(<Pattern>[RegExp(r'^Reloaded 0 libraries in [0-9]+ms\.$'), 'called reassemble', 'called paint'], handler: (String line) {
            processManager.killPid(pid, ProcessSignal.sigusr2);
            return null;
          }),
          Barrier('Performing hot restart...'.padRight(progressMessageWidth)),
          Multiple(<Pattern>[RegExp(r'^Restarted application in [0-9]+ms.$'), 'called main', 'called paint'], handler: (String line) {
            return 'q';
          }),
          const Barrier('Application finished.'),
        ],
        logging: false, // we ignore leading log lines to avoid making this test sensitive to e.g. the help message text
      );
      // We check the output from the app (all starts with "called ...") and the output from the tool
      // (everything else) separately, because their relative timing isn't guaranteed. Their rough timing
      // is verified by the expected transitions above.
      expect(result.stdout.where((String line) => line.startsWith('called ')), <Object>[
        // logs start after we receive the response to sending SIGUSR1
        // SIGUSR1:
        'called reassemble',
        'called paint',
        // SIGUSR2:
        'called main',
        'called paint',
      ]);
      expect(result.stdout.where((String line) => !line.startsWith('called ')), <Object>[
        // logs start after we receive the response to sending SIGUSR1
        'Performing hot reload...'.padRight(progressMessageWidth),
        startsWith('Reloaded 0 libraries in '),
        'Performing hot restart...'.padRight(progressMessageWidth),
        startsWith('Restarted application in '),
        '', // this newline is the one for after we hit "q"
        'Application finished.',
        'ready',
      ]);
      expect(result.exitCode, 0);
    } finally {
      tryToDelete(fileSystem.directory(tempDirectory));
    }
  }, skip: Platform.isWindows); // [intended] Windows doesn't support sending signals.

  testWithoutContext('flutter run can hot reload and hot restart, handle "p" key', () async {
    final String tempDirectory = fileSystem.systemTempDirectory.createTempSync('flutter_overall_experience_test.').resolveSymbolicLinksSync();
    final String testDirectory = fileSystem.path.join(flutterRoot, 'dev', 'integration_tests', 'ui');
    final String testScript = fileSystem.path.join('lib', 'commands.dart');
    try {
      final ProcessTestResult result = await runFlutter(
        <String>['run', '-dflutter-tester', '--report-ready', '--no-devtools', testScript],
        testDirectory,
        <Transition>[
          Multiple(<Pattern>['Flutter run key commands.', 'called main', 'called paint'], handler: (String line) {
            return 'r';
          }),
          Barrier('Performing hot reload...'.padRight(progressMessageWidth), logging: true),
          Multiple(<Pattern>['ready', 'called reassemble', 'called paint'], handler: (String line) {
            return 'R';
          }),
          Barrier('Performing hot restart...'.padRight(progressMessageWidth)),
          Multiple(<Pattern>['ready', 'called main', 'called paint'], handler: (String line) {
            return 'p';
          }),
          Multiple(<Pattern>['ready', 'called paint', 'called debugPaintSize'], handler: (String line) {
            return 'p';
          }),
          Multiple(<Pattern>['ready', 'called paint'], handler: (String line) {
            return 'q';
          }),
          const Barrier('Application finished.'),
        ],
        logging: false, // we ignore leading log lines to avoid making this test sensitive to e.g. the help message text
      );
      // We check the output from the app (all starts with "called ...") and the output from the tool
      // (everything else) separately, because their relative timing isn't guaranteed. Their rough timing
      // is verified by the expected transitions above.
      expect(result.stdout.where((String line) => line.startsWith('called ')), <Object>[
        // logs start after we initiate the hot reload
        // hot reload:
        'called reassemble',
        'called paint',
        // hot restart:
        'called main',
        'called paint',
        // debugPaintSizeEnabled = true:
        'called paint',
        'called debugPaintSize',
        // debugPaintSizeEnabled = false:
        'called paint',
      ]);
      expect(result.stdout.where((String line) => !line.startsWith('called ')), <Object>[
        // logs start after we receive the response to hitting "r"
        'Performing hot reload...'.padRight(progressMessageWidth),
        startsWith('Reloaded 0 libraries in '),
        'ready',
        '', // this newline is the one for after we hit "R"
        'Performing hot restart...'.padRight(progressMessageWidth),
        startsWith('Restarted application in '),
        'ready',
        '', // newline for after we hit "p" the first time
        'ready',
        '', // newline for after we hit "p" the second time
        'ready',
        '', // this newline is the one for after we hit "q"
        'Application finished.',
        'ready',
      ]);
      expect(result.exitCode, 0);
    } finally {
      tryToDelete(fileSystem.directory(tempDirectory));
    }
  });

  testWithoutContext('flutter error messages include a DevTools link', () async {
    final String testDirectory = fileSystem.path.join(flutterRoot, 'dev', 'integration_tests', 'ui');
    final String tempDirectory = fileSystem.systemTempDirectory.createTempSync('flutter_overall_experience_test.').resolveSymbolicLinksSync();
    final String testScript = fileSystem.path.join('lib', 'overflow.dart');
    try {
      final ProcessTestResult result = await runFlutter(
        <String>['run', '-dflutter-tester', testScript],
        testDirectory,
        <Transition>[
          Barrier(RegExp(r'^An Observatory debugger and profiler on Flutter test device is available at: ')),
          Barrier(RegExp(r'^The Flutter DevTools debugger and profiler on Flutter test device is available at: '), handler: (String line) {
            return 'r';
          }),
          Barrier('Performing hot reload...'.padRight(progressMessageWidth), logging: true),
          Barrier(RegExp(r'^Reloaded 0 libraries in [0-9]+ms.'), handler: (String line) {
            return 'q';
          }),
        ],
        logging: false,
      );
      expect(result.exitCode, 0);
      expect(result.stdout, <Object>[
        startsWith('Performing hot reload...'),
        '',
        '══╡ EXCEPTION CAUGHT BY RENDERING LIBRARY ╞═════════════════════════════════════════════════════════',
        'The following assertion was thrown during layout:',
        'A RenderFlex overflowed by 69200 pixels on the right.',
        '',
        'The relevant error-causing widget was:',
        matches(RegExp(r'^  Row .+flutter/dev/integration_tests/ui/lib/overflow\.dart:31:12$')),
        '',
        'To inspect this widget in Flutter DevTools, visit:',
        startsWith('http'),
        '',
        'The overflowing RenderFlex has an orientation of Axis.horizontal.',
        'The edge of the RenderFlex that is overflowing has been marked in the rendering with a yellow and',
        'black striped pattern. This is usually caused by the contents being too big for the RenderFlex.',
        'Consider applying a flex factor (e.g. using an Expanded widget) to force the children of the',
        'RenderFlex to fit within the available space instead of being sized to their natural size.',
        'This is considered an error condition because it indicates that there is content that cannot be',
        'seen. If the content is legitimately bigger than the available space, consider clipping it with a',
        'ClipRect widget before putting it in the flex, or using a scrollable container rather than a Flex,',
        'like a ListView.',
        matches(RegExp(r'^The specific RenderFlex in question is: RenderFlex#..... OVERFLOWING:$')),
        startsWith('  creator: Row ← Test ← '),
        contains(' ← '),
        endsWith(' ← ⋯'),
        '  parentData: <none> (can use size)',
        '  constraints: BoxConstraints(w=800.0, h=600.0)',
        '  size: Size(800.0, 600.0)',
        '  direction: horizontal',
        '  mainAxisAlignment: start',
        '  mainAxisSize: max',
        '  crossAxisAlignment: center',
        '  textDirection: ltr',
        '  verticalDirection: down',
        '◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤',
        '════════════════════════════════════════════════════════════════════════════════════════════════════',
        startsWith('Reloaded 0 libraries in '),
        '',
        'Application finished.',
      ]);
    } finally {
      tryToDelete(fileSystem.directory(tempDirectory));
    }
  });

  testWithoutContext('flutter run help output', () async {
    // This test enables all logging so that it checks the exact text of starting up an application.
    // The idea is to verify that we're not outputting spurious messages.
    // WHEN EDITING THIS TEST PLEASE CAREFULLY CONSIDER WHETHER THE NEW OUTPUT IS AN IMPROVEMENT.
    final String testDirectory = fileSystem.path.join(flutterRoot, 'examples', 'hello_world');
    final RegExp finalLine = RegExp(r'^The Flutter DevTools');
    final ProcessTestResult result = await runFlutter(
      <String>['run', '-dflutter-tester'],
      testDirectory,
      <Transition>[
        Barrier(finalLine, handler: (String line) {
          return 'h';
        }),
        Barrier(finalLine, handler: (String line) {
          return 'q';
        }),
        const Barrier('Application finished.'),
      ],
    );
    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, <Object>[
      startsWith('Launching '),
      startsWith('Syncing files to device Flutter test device...'),
      '',
      'Flutter run key commands.',
      startsWith('r Hot reload.'),
      'R Hot restart.',
      'h List all available interactive commands.',
      'd Detach (terminate "flutter run" but leave application running).',
      'c Clear the screen',
      'q Quit (terminate the application on the device).',
      '',
      contains('Running with sound null safety'),
      '',
      startsWith('An Observatory debugger and profiler on Flutter test device is available at: http://'),
      startsWith('The Flutter DevTools debugger and profiler on Flutter test device is available at: http://'),
      '',
      'Flutter run key commands.',
      startsWith('r Hot reload.'),
      'R Hot restart.',
      'v Open Flutter DevTools.',
      'w Dump widget hierarchy to the console.                                               (debugDumpApp)',
      't Dump rendering tree to the console.                                          (debugDumpRenderTree)',
      'L Dump layer tree to the console.                                               (debugDumpLayerTree)',
      'S Dump accessibility tree in traversal order.                                   (debugDumpSemantics)',
      'U Dump accessibility tree in inverse hit test order.                            (debugDumpSemantics)',
      'i Toggle widget inspector.                                  (WidgetsApp.showWidgetInspectorOverride)',
      'p Toggle the display of construction lines.                                  (debugPaintSizeEnabled)',
      'I Toggle oversized image inversion.                                     (debugInvertOversizedImages)',
      'o Simulate different operating systems.                                      (defaultTargetPlatform)',
      'b Toggle platform brightness (dark and light mode).                        (debugBrightnessOverride)',
      'P Toggle performance overlay.                                    (WidgetsApp.showPerformanceOverlay)',
      'a Toggle timeline events for all widget build methods.                    (debugProfileWidgetBuilds)',
      'M Write SkSL shaders to a unique file in the project directory.',
      'g Run source code generators.',
      'h Repeat this help message.',
      'd Detach (terminate "flutter run" but leave application running).',
      'c Clear the screen',
      'q Quit (terminate the application on the device).',
      '',
      contains('Running with sound null safety'),
      '',
      startsWith('An Observatory debugger and profiler on Flutter test device is available at: http://'),
      startsWith('The Flutter DevTools debugger and profiler on Flutter test device is available at: http://'),
      '',
      'Application finished.',
    ]);
  });
}
