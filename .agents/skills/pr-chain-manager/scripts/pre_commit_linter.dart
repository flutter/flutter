// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

/// Represents a single verification/linter task to be executed on a worker Isolate.
class CheckTask {
  const CheckTask({
    required this.name,
    required this.category,
    required this.executable,
    required this.arguments,
    required this.workingDirectory,
    required this.environment,
  });

  final String name;
  final String category;
  final String executable;
  final List<String> arguments;
  final String workingDirectory;
  final Map<String, String> environment;
}

/// Represents the result of executing a [CheckTask] on a worker Isolate,
/// including Perfetto trace timing metadata.
class CheckResult {
  const CheckResult({
    required this.name,
    required this.category,
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.startTimeMicros,
    required this.durationMicros,
    required this.isolateId,
  });

  final String name;
  final String category;
  final int exitCode;
  final String stdout;
  final String stderr;
  final int startTimeMicros;
  final int durationMicros;
  final int isolateId;

  bool get passed => exitCode == 0;
}

/// Executes a single [CheckTask] inside a background [Isolate].
Future<CheckResult> _executeTaskOnWorker(CheckTask task) {
  return Isolate.run<CheckResult>(() async {
    final int startMicros = DateTime.now().microsecondsSinceEpoch;
    final stopwatch = Stopwatch()..start();
    final isolateHash = Isolate.current.hashCode;

    try {
      final ProcessResult result = await Process.run(
        task.executable,
        task.arguments,
        workingDirectory: task.workingDirectory,
        environment: task.environment,
      );
      stopwatch.stop();
      return CheckResult(
        name: task.name,
        category: task.category,
        exitCode: result.exitCode,
        stdout: result.stdout.toString().trim(),
        stderr: result.stderr.toString().trim(),
        startTimeMicros: startMicros,
        durationMicros: stopwatch.elapsedMicroseconds,
        isolateId: isolateHash,
      );
    } on Object catch (e) {
      stopwatch.stop();
      return CheckResult(
        name: task.name,
        category: task.category,
        exitCode: 1,
        stdout: '',
        stderr: 'Exception running ${task.name}: $e',
        startTimeMicros: startMicros,
        durationMicros: stopwatch.elapsedMicroseconds,
        isolateId: isolateHash,
      );
    }
  });
}

/// Audits staged C++ files in `shell/platform/android/` for RFC 410 invariants:
/// 1. No `// nogncheck` escape hatches.
/// 2. No direct static calls to `FlutterEngine*` C-API functions in `:flutter_embedder_native_src` files.
Future<CheckResult> _runRfc410InvariantAudit(
  String flutterRoot,
  List<String> stagedAndroidCppFiles,
) {
  return Isolate.run<CheckResult>(() async {
    final int startMicros = DateTime.now().microsecondsSinceEpoch;
    final stopwatch = Stopwatch()..start();
    final isolateHash = Isolate.current.hashCode;
    final violations = <String>[];

    final directApiPattern = RegExp(
      r'\bFlutterEngine(Run|Initialize|RunInitialized|Deinitialize|Shutdown|'
      r'SendPlatformMessage|NotifyCreated|NotifyDestroyed|OnVsync|'
      r'ScheduleFrame|UpdateSemanticsEnabled|RegisterExternalTexture)\s*\(',
    );
    final shellIsolationPattern = RegExp(r'\b(Shell::Create|AndroidShellHolder)\b');

    for (final relPath in stagedAndroidCppFiles) {
      final file = File('$flutterRoot/$relPath');
      if (!file.existsSync()) {
        continue;
      }
      final List<String> lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final String line = lines[i];
        final String trimmed = line.trim();
        if (line.contains('nogncheck')) {
          violations.add(
            '$relPath:${i + 1}: Prohibited "// nogncheck" escape hatch detected (violates ADR-0000).',
          );
        }
        // Check modular embedder files for direct static C-API symbol linkage and Shell::Create ban.
        if ((relPath.contains('embedder') || relPath.contains('flutter_embedder_native')) &&
            !relPath.endsWith('_unittests.cc') &&
            !trimmed.startsWith('//') &&
            !trimmed.startsWith('*')) {
          if (directApiPattern.hasMatch(line)) {
            violations.add(
              '$relPath:${i + 1}: Direct static C-API call detected: "$trimmed". '
              'Route through FlutterEngineProcTable (embedder_api_) per ADR-0001.',
            );
          }
          if (shellIsolationPattern.hasMatch(line)) {
            violations.add(
              '$relPath:${i + 1}: Forbidden Shell::Create or AndroidShellHolder reference on C-API path: "$trimmed". '
              'No flutter::Shell may exist when the feature flag is true per ADR-0011.',
            );
          }
        }
      }
    }

    stopwatch.stop();
    return CheckResult(
      name: 'RFC 410 Invariant & Firewall Audit',
      category: 'architecture',
      exitCode: violations.isEmpty ? 0 : 1,
      stdout: violations.isEmpty
          ? 'All ${stagedAndroidCppFiles.length} staged Android C++ file(s) conform to RFC 410 invariants.'
          : '',
      stderr: violations.join('\n'),
      startTimeMicros: startMicros,
      durationMicros: stopwatch.elapsedMicroseconds,
      isolateId: isolateHash,
    );
  });
}

/// Writes Perfetto / Chrome Trace Event Format JSON for all worker tasks.
void _writePerfettoTrace(List<CheckResult> results, String tracePath) {
  final traceEvents = <Map<String, Object>>[];
  for (final result in results) {
    traceEvents.add(<String, Object>{
      'name': result.name,
      'cat': result.category,
      'ph': 'X',
      'ts': result.startTimeMicros,
      'dur': result.durationMicros,
      'pid': pid,
      'tid': result.isolateId,
      'args': <String, Object>{'exitCode': result.exitCode, 'passed': result.passed},
    });
  }
  try {
    File(tracePath).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(<String, Object>{'traceEvents': traceEvents}),
    );
  } on Object {
    // Non-fatal if trace file cannot be written.
  }
}

Future<void> main(List<String> args) async {
  const flutterRoot = '/usr/local/google/home/boetger/src/flutter';
  const engineSrcDir = '$flutterRoot/engine/src';
  const engineFlutterDir = '$engineSrcDir/flutter';
  const dartBin = '$flutterRoot/bin/dart';
  const engineDartBin = '$engineFlutterDir/third_party/dart/tools/sdks/dart-sdk/bin/dart';
  const etBin = '$engineFlutterDir/bin/et';
  const gnBin = '$engineFlutterDir/third_party/gn/gn';
  const prChainScript = '$flutterRoot/.agents/skills/pr-chain-manager/scripts/pr_chain.dart';
  const flagRatchetScript =
      '$flutterRoot/.agents/skills/embedder-flag-and-integration-verifier/scripts/verify_embedder_flag_and_ratchet.dart';

  final env = Map<String, String>.from(Platform.environment);
  final String existingPath = env['PATH'] ?? '';
  env['PATH'] =
      '$engineFlutterDir/bin:$flutterRoot/bin:/usr/local/google/home/boetger/src/depot_tools:$existingPath';

  // 1. Discover staged files (or modified files if --all-modified is passed).
  final bool checkWorkingTree = args.contains('--working-tree');
  final diffArgs = checkWorkingTree
      ? <String>['diff', '--name-only', '--diff-filter=ACMR', 'HEAD']
      : <String>['diff', '--cached', '--name-only', '--diff-filter=ACMR'];

  final ProcessResult stagedRes = await Process.run(
    'git',
    diffArgs,
    workingDirectory: flutterRoot,
    environment: env,
  );

  final List<String> stagedFiles = stagedRes.stdout
      .toString()
      .split('\n')
      .map((String s) => s.trim())
      .where((String s) => s.isNotEmpty)
      .toList();

  // Classify staged files by language / subsystem.
  final List<String> stagedDartFiles = stagedFiles
      .where((String f) => f.endsWith('.dart'))
      .toList();
  final List<String> stagedEngineFiles = stagedFiles
      .where((String f) => f.startsWith('engine/src/flutter/'))
      .toList();
  final List<String> stagedCppFiles = stagedEngineFiles
      .where(
        (String f) =>
            f.endsWith('.cc') ||
            f.endsWith('.cpp') ||
            f.endsWith('.h') ||
            f.endsWith('.hpp') ||
            f.endsWith('.mm'),
      )
      .toList();
  final List<String> stagedAndroidCppFiles = stagedCppFiles
      .where((String f) => f.startsWith('engine/src/flutter/shell/platform/android/'))
      .toList();
  final List<String> stagedGnFiles = stagedEngineFiles
      .where((String f) => f.endsWith('.gn') || f.endsWith('.gni'))
      .toList();
  final List<String> stagedAndroidJavaFiles = stagedEngineFiles
      .where(
        (String f) =>
            f.startsWith('engine/src/flutter/shell/platform/android/') &&
            (f.endsWith('.java') || f.endsWith('.kt')),
      )
      .toList();

  final tasks = <CheckTask>[];

  // Task 1: PR Chain Verification (Always runs on migration branches)
  if (File(prChainScript).existsSync()) {
    tasks.add(
      CheckTask(
        name: 'PR Chain Topological Verify',
        category: 'git-chain',
        executable: dartBin,
        arguments: <String>[prChainScript, 'verify'],
        workingDirectory: flutterRoot,
        environment: env,
      ),
    );
  }

  // Task 1b: Feature Flag Shell Isolation & Integration Test Ratchet (ADR-0011)
  if (File(flagRatchetScript).existsSync()) {
    tasks.add(
      CheckTask(
        name: 'Feature Flag Shell Isolation & Integration Ratchet (ADR-0011)',
        category: 'flag-ratchet',
        executable: dartBin,
        arguments: <String>[flagRatchetScript, 'verify-ratchet'],
        workingDirectory: flutterRoot,
        environment: env,
      ),
    );
  }

  // Task 2: Dart Format & Analyze on staged .dart files
  if (stagedDartFiles.isNotEmpty) {
    tasks.add(
      CheckTask(
        name: 'Dart Format Check (${stagedDartFiles.length} files)',
        category: 'dart-format',
        executable: dartBin,
        arguments: <String>['format', '--output=none', '--set-exit-if-changed', ...stagedDartFiles],
        workingDirectory: flutterRoot,
        environment: env,
      ),
    );
    tasks.add(
      CheckTask(
        name: 'Dart Static Analyzer (--fatal-infos)',
        category: 'dart-analyze',
        executable: dartBin,
        arguments: <String>['analyze', '--fatal-infos', ...stagedDartFiles],
        workingDirectory: flutterRoot,
        environment: env,
      ),
    );
  }

  // Task 3: Engine Format (`et format --dry-run`) when engine files are staged
  if (stagedEngineFiles.isNotEmpty && File(etBin).existsSync()) {
    tasks.add(
      CheckTask(
        name: 'Engine Formatter (et format --dry-run)',
        category: 'et-format',
        executable: etBin,
        arguments: <String>['format', '--dry-run'],
        workingDirectory: engineFlutterDir,
        environment: env,
      ),
    );
  }

  // Task 4: Engine Clang-Tidy on staged C/C++/ObjC files
  if (stagedCppFiles.isNotEmpty && File(engineDartBin).existsSync()) {
    // Convert `engine/src/flutter/foo/bar.cc` -> escaped regex matching `flutter/foo/bar.cc`
    final String regexPattern = stagedCppFiles
        .map((String f) {
          final String stripped = f.replaceFirst('engine/src/', '');
          return RegExp.escape(stripped);
        })
        .join('|');

    // Choose target variant based on whether Android files are modified
    final primaryVariant =
        stagedAndroidCppFiles.isNotEmpty &&
            File('$engineSrcDir/out/android_debug_unopt/compile_commands.json').existsSync()
        ? 'android_debug_unopt'
        : 'host_debug_unopt';

    final clangTidyArgs = <String>[
      '$engineFlutterDir/tools/clang_tidy/bin/main.dart',
      '--src-dir=$engineSrcDir',
      '--target-variant=$primaryVariant',
      '--lint-regex=($regexPattern)',
    ];

    tasks.add(
      CheckTask(
        name: 'Engine Clang-Tidy (${stagedCppFiles.length} C++ files)',
        category: 'clang-tidy',
        executable: engineDartBin,
        arguments: clangTidyArgs,
        workingDirectory: engineFlutterDir,
        environment: env,
      ),
    );
  }

  // Task 5: GN Header & Firewall Check (`gn check`) when C++ or GN files are staged
  if ((stagedCppFiles.isNotEmpty || stagedGnFiles.isNotEmpty) && File(gnBin).existsSync()) {
    if (Directory('$engineSrcDir/out/android_debug_unopt').existsSync()) {
      tasks.add(
        CheckTask(
          name: 'GN Include & Firewall Check (android_debug_unopt)',
          category: 'gn-check',
          executable: gnBin,
          arguments: <String>[
            'check',
            '$engineSrcDir/out/android_debug_unopt',
            '//flutter/shell/platform/android/*',
          ],
          workingDirectory: engineSrcDir,
          environment: env,
        ),
      );
    }
    if (Directory('$engineSrcDir/out/host_debug_unopt').existsSync()) {
      tasks.add(
        CheckTask(
          name: 'GN Include & Firewall Check (host_debug_unopt)',
          category: 'gn-check',
          executable: gnBin,
          arguments: <String>[
            'check',
            '$engineSrcDir/out/host_debug_unopt',
            '//flutter/shell/platform/embedder/*',
          ],
          workingDirectory: engineSrcDir,
          environment: env,
        ),
      );
    }
  }

  // Task 6: Android SDK Java/Kotlin Lint when Java/Kotlin files in shell/platform/android are staged
  if (stagedAndroidJavaFiles.isNotEmpty && File(engineDartBin).existsSync()) {
    tasks.add(
      CheckTask(
        name: 'Android SDK Lint (${stagedAndroidJavaFiles.length} Java/Kt files)',
        category: 'android-lint',
        executable: engineDartBin,
        arguments: <String>[
          '$engineFlutterDir/tools/android_lint/bin/main.dart',
          '--in=$engineSrcDir',
        ],
        workingDirectory: engineFlutterDir,
        environment: env,
      ),
    );
  }

  // Dispatch all tasks concurrently across worker Isolates!
  final overallStopwatch = Stopwatch()..start();
  final futures = <Future<CheckResult>>[
    for (final CheckTask task in tasks) _executeTaskOnWorker(task),
    if (stagedAndroidCppFiles.isNotEmpty)
      _runRfc410InvariantAudit(flutterRoot, stagedAndroidCppFiles),
  ];

  final List<CheckResult> results = await Future.wait(futures);
  overallStopwatch.stop();

  const traceFile = '/tmp/flutter_pre_commit_trace.json';
  _writePerfettoTrace(results, traceFile);

  stdout.writeln('================================================================');
  stdout.writeln(
    'Pre-Commit Parallel Linter & Analyzer Suite (${results.length} workers in ${overallStopwatch.elapsedMilliseconds}ms)',
  );
  stdout.writeln('Perfetto Trace: $traceFile');
  stdout.writeln('================================================================');

  var allPassed = true;
  for (final result in results) {
    final statusBadge = result.passed ? '[PASS]' : '[FAIL]';
    final int ms = (result.durationMicros / 1000).round();
    stdout.writeln(' $statusBadge ${result.name} (${ms}ms)');
    if (!result.passed) {
      allPassed = false;
      if (result.stdout.isNotEmpty) {
        stderr.writeln('   --- stdout ---\n${result.stdout}');
      }
      if (result.stderr.isNotEmpty) {
        stderr.writeln('   --- stderr ---\n${result.stderr}');
      }
    }
  }

  if (!allPassed) {
    stderr.writeln(
      '\nERROR: One or more pre-commit checks failed. Fix all formatting, lint, and analyzer issues before committing.',
    );
    exit(1);
  }

  stdout.writeln('All pre-commit checks passed!');
}
