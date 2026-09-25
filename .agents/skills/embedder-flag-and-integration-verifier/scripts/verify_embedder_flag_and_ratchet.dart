// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

const String _flutterRoot = '/usr/local/google/home/boetger/src/flutter';
const String _ratchetPath =
    '$_flutterRoot/.agents/embedder_migration/integration_test_ratchet.json';
const String _androidEmbedderDir = '$_flutterRoot/engine/src/flutter/shell/platform/android';

/// Represents the result of a static or dynamic verification check.
class VerificationOutcome {
  const VerificationOutcome({
    required this.passed,
    required this.summary,
    this.violations = const <String>[],
  });

  final bool passed;
  final String summary;
  final List<String> violations;
}

/// Audits `engine/src/flutter/shell/platform/android/` on a background [Isolate]
/// to ensure no C-API embedder files instantiate `flutter::Shell::Create` or
/// `AndroidShellHolder` when the Embedder API path is active.
Future<VerificationOutcome> _verifyStaticShellIsolation() {
  return Isolate.run<VerificationOutcome>(() {
    final dir = Directory(_androidEmbedderDir);
    if (!dir.existsSync()) {
      return const VerificationOutcome(
        passed: false,
        summary: 'Android embedder directory not found at $_androidEmbedderDir',
      );
    }

    final violations = <String>[];
    final shellCreatePattern = RegExp(r'\b(Shell::Create|AndroidShellHolder)\b');

    final List<FileSystemEntity> entities = dir.listSync(recursive: true);
    var checkedCapiFiles = 0;

    for (final entity in entities) {
      if (entity is! File) {
        continue;
      }
      final String filePath = entity.path;
      if (!filePath.endsWith('.cc') && !filePath.endsWith('.h')) {
        continue;
      }
      final String relPath = filePath.replaceFirst('$_flutterRoot/', '');

      // Check files belonging to the modular C-API embedder implementation.
      final bool isCapiEmbedderFile =
          (relPath.contains('/embedder/') || relPath.contains('flutter_embedder_native')) &&
          !relPath.endsWith('_unittests.cc');

      if (!isCapiEmbedderFile) {
        continue;
      }

      checkedCapiFiles++;
      final List<String> lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final String line = lines[i];
        final String trimmed = line.trim();
        if (trimmed.startsWith('//') || trimmed.startsWith('*')) {
          continue;
        }
        if (shellCreatePattern.hasMatch(line)) {
          violations.add(
            '$relPath:${i + 1}: Forbidden Shell::Create or AndroidShellHolder reference on C-API path: "$trimmed" (violates ADR-0011).',
          );
        }
      }
    }

    return VerificationOutcome(
      passed: violations.isEmpty,
      summary:
          'Static Shell Isolation Audit: checked $checkedCapiFiles C-API embedder file(s), ${violations.length} violation(s).',
      violations: violations,
    );
  });
}

/// Verifies monotonic reduction of `current_failing_test_count` and preservation
/// of `passing_locked_tests` in `integration_test_ratchet.json` across the PR chain.
Future<VerificationOutcome> _verifyRatchetMonotonicity() async {
  final ratchetFile = File(_ratchetPath);
  if (!ratchetFile.existsSync()) {
    return const VerificationOutcome(
      passed: false,
      summary: 'Missing $_ratchetPath',
      violations: <String>['integration_test_ratchet.json does not exist.'],
    );
  }

  final currentJson = jsonDecode(ratchetFile.readAsStringSync()) as Map<String, Object?>;
  final ratchetState = currentJson['ratchet_state']! as Map<String, Object?>;
  final currentFailing = ratchetState['current_failing_test_count']! as int;
  final maxAllowed = ratchetState['max_allowed_failing_tests']! as int;
  final totalSuite = ratchetState['total_suite_tests']! as int;
  final List<String> currentLocked = (ratchetState['passing_locked_tests']! as List<Object?>)
      .cast<String>();

  final violations = <String>[];

  if (currentFailing > maxAllowed) {
    violations.add(
      'current_failing_test_count ($currentFailing) exceeds max_allowed_failing_tests ($maxAllowed).',
    );
  }
  if (currentFailing < 0 || currentFailing > totalSuite) {
    violations.add(
      'current_failing_test_count ($currentFailing) is out of bounds [0, $totalSuite].',
    );
  }

  // Compare against the parent branch in `android-embedder-migration-v10/*` if one exists.
  final ProcessResult branchRes = await Process.run('git', <String>[
    'for-each-ref',
    '--format=%(refname:short)',
    'refs/heads/android-embedder-migration-v10/',
  ], workingDirectory: _flutterRoot);
  final List<String> branches =
      branchRes.stdout
          .toString()
          .split('\n')
          .map((String s) => s.trim())
          .where((String s) => s.isNotEmpty)
          .toList()
        ..sort();

  final ProcessResult headBranchRes = await Process.run('git', <String>[
    'branch',
    '--show-current',
  ], workingDirectory: _flutterRoot);
  final String activeBranch = headBranchRes.stdout.toString().trim();
  final int activeIdx = branches.indexOf(activeBranch);

  if (activeIdx > 0) {
    final String parentBranch = branches[activeIdx - 1];
    final ProcessResult parentRatchetRes = await Process.run('git', <String>[
      'show',
      '$parentBranch:.agents/embedder_migration/integration_test_ratchet.json',
    ], workingDirectory: _flutterRoot);
    if (parentRatchetRes.exitCode == 0) {
      final parentJson = jsonDecode(parentRatchetRes.stdout.toString()) as Map<String, Object?>;
      final parentState = parentJson['ratchet_state']! as Map<String, Object?>;
      final parentFailing = parentState['current_failing_test_count']! as int;
      final List<String> parentLocked = (parentState['passing_locked_tests']! as List<Object?>)
          .cast<String>();

      if (currentFailing > parentFailing) {
        violations.add(
          'Integration test failure count regressed from $parentFailing (on $parentBranch) to $currentFailing (on $activeBranch). '
          'Failing test count must monotonically decrease across the branch chain per ADR-0011!',
        );
      }

      for (final lockedTest in parentLocked) {
        if (!currentLocked.contains(lockedTest)) {
          violations.add(
            'Locked passing test "$lockedTest" from parent branch $parentBranch was removed or regressed on $activeBranch!',
          );
        }
      }
    }
  }

  return VerificationOutcome(
    passed: violations.isEmpty,
    summary:
        'Integration Test Ratchet Audit: $currentFailing/$totalSuite failing (max allowed: $maxAllowed, locked passing: ${currentLocked.length}).',
    violations: violations,
  );
}

/// Prints the formatted status of `integration_test_ratchet.json`.
void _printStatus() {
  final ratchetFile = File(_ratchetPath);
  if (!ratchetFile.existsSync()) {
    stderr.writeln('ERROR: $_ratchetPath not found.');
    exit(1);
  }
  final root = jsonDecode(ratchetFile.readAsStringSync()) as Map<String, Object?>;
  final proof = root['proof_contract']! as Map<String, Object?>;
  final state = root['ratchet_state']! as Map<String, Object?>;
  final tests = state['failing_tests_by_target_branch']! as List<Object?>;
  final List<String> locked = (state['passing_locked_tests']! as List<Object?>).cast<String>();

  stdout.writeln(
    '================================================================================',
  );
  stdout.writeln('Android Embedder C-API On-Device Integration & DeviceLab Ratchet (ADR-0011)');
  stdout.writeln(
    '================================================================================',
  );
  stdout.writeln('Feature Flag       : ${root['feature_flag_name']}');
  stdout.writeln('Engine Switch      : ${root['engine_switch']}');
  stdout.writeln('Required Logcat    : ${proof['required_logcat_marker']}');
  stdout.writeln(
    'Forbidden Markers  : ${(proof['forbidden_logcat_markers']! as List<Object?>).join(', ')}',
  );
  stdout.writeln(
    'Current Failing    : ${state['current_failing_test_count']} / ${state['total_suite_tests']} (Max Allowed: ${state['max_allowed_failing_tests']})',
  );
  stdout.writeln('Locked Passing     : ${locked.length}');
  stdout.writeln(
    '--------------------------------------------------------------------------------',
  );
  for (final item in tests) {
    final testMap = item! as Map<String, Object?>;
    final id = testMap['id']! as String;
    final subsystem = testMap['subsystem']! as String;
    final expectedBranch = testMap['expected_green_branch']! as String;
    final bool isLocked = locked.contains(id);
    final badge = isLocked ? '[LOCKED PASS]' : '[EXPECTED FAIL UNTIL]';
    stdout.writeln(' $badge $id');
    stdout.writeln('     Subsystem      : $subsystem');
    stdout.writeln('     Target Branch  : $expectedBranch');
  }
  stdout.writeln(
    '================================================================================',
  );
}

/// Runs the on-device `dev/integration_tests` and `dev/devicelab` suite while
/// capturing Perfetto traces and `adb logcat` output to verify that `FlutterEngineInitialize`
/// (C-API) is active and `Shell::Create` / `AndroidShellHolder` is NEVER called.
Future<void> _runDeviceSuite(List<String> args) async {
  // Verify a connected Android device is available via `adb devices`.
  final ProcessResult adbRes = await Process.run('adb', <String>['devices']);
  final List<String> connectedDevices = adbRes.stdout
      .toString()
      .split('\n')
      .skip(1)
      .map((String line) => line.trim())
      .where((String line) => line.isNotEmpty && line.contains('\tdevice'))
      .toList();

  if (connectedDevices.isEmpty) {
    stderr.writeln(
      'ERROR: No connected Android device found via "adb devices". '
      'On-device integration/devicelab verification requires an attached Android device or emulator.',
    );
    exit(1);
  }

  String? requestedDevice;
  var localEngine = 'android_debug_unopt_arm64';
  var localEngineHost = 'host_debug_unopt';
  String? filterTestId;
  final extraTestArgs = <String>[];
  for (var i = 0; i < args.length; i++) {
    final String arg = args[i];
    if (arg == '--update-ratchet') {
      continue;
    } else if (arg == '--device' && i + 1 < args.length) {
      requestedDevice = args[++i];
    } else if (arg.startsWith('--device=')) {
      requestedDevice = arg.substring('--device='.length);
    } else if (arg == '--local-engine' && i + 1 < args.length) {
      localEngine = args[++i];
    } else if (arg.startsWith('--local-engine=')) {
      localEngine = arg.substring('--local-engine='.length);
    } else if (arg == '--local-engine-host' && i + 1 < args.length) {
      localEngineHost = args[++i];
    } else if (arg.startsWith('--local-engine-host=')) {
      localEngineHost = arg.substring('--local-engine-host='.length);
    } else if (arg == '--test' && i + 1 < args.length) {
      filterTestId = args[++i];
    } else if (arg.startsWith('--test=')) {
      filterTestId = arg.substring('--test='.length);
    } else {
      extraTestArgs.add(arg);
    }
  }

  final String deviceId = requestedDevice ?? connectedDevices.first.split('\t').first;
  stdout.writeln('==> Connected Android Device: $deviceId');
  stdout.writeln('==> Forcing screen to stay awake and unlocked...');
  await Process.run('adb', <String>['-s', deviceId, 'shell', 'svc', 'power', 'stayon', 'true']);
  await Process.run('adb', <String>[
    '-s',
    deviceId,
    'shell',
    'settings',
    'put',
    'system',
    'screen_off_timeout',
    '2147483647',
  ]);
  await Process.run('adb', <String>[
    '-s',
    deviceId,
    'shell',
    'input',
    'keyevent',
    'KEYCODE_WAKEUP',
  ]);
  await Process.run('adb', <String>['-s', deviceId, 'shell', 'wm', 'dismiss-keyguard']);
  await Process.run('adb', <String>['-s', deviceId, 'logcat', '-G', '16M']);
  await Process.run('adb', <String>[
    '-s',
    deviceId,
    'shell',
    'setprop',
    'debug.flutter.enable_embedder_api',
    'true',
  ]);

  final ratchetFile = File(_ratchetPath);
  final root = jsonDecode(ratchetFile.readAsStringSync()) as Map<String, Object?>;
  final proof = root['proof_contract']! as Map<String, Object?>;
  final requiredLogcat = proof['required_logcat_marker']! as String;
  final List<String> forbiddenLogcat = (proof['forbidden_logcat_markers']! as List<Object?>)
      .cast<String>();
  final List<String> requiredPerfetto = (proof['required_perfetto_slices']! as List<Object?>)
      .cast<String>();
  final List<String> forbiddenPerfetto = (proof['forbidden_perfetto_slices']! as List<Object?>)
      .cast<String>();

  final state = root['ratchet_state']! as Map<String, Object?>;
  final suiteTests = state['failing_tests_by_target_branch']! as List<Object?>;

  var failingCount = 0;
  final newlyPassing = <String>[];
  final proofViolations = <String>[];

  for (final item in suiteTests) {
    final testMap = item! as Map<String, Object?>;
    final id = testMap['id']! as String;
    if (filterTestId != null && id != filterTestId) {
      continue;
    }
    final workDir = '$_flutterRoot/${testMap['working_directory']! as String}';
    final List<String> baseCmd = (testMap['command']! as List<Object?>).cast<String>();

    stdout.writeln('\n==> Running [$id] in $workDir with Feature Flag = TRUE...');

    // 0. Keep screen awake, unlocked, and feature flag enabled before each test
    await Process.run('adb', <String>[
      '-s',
      deviceId,
      'shell',
      'input',
      'keyevent',
      'KEYCODE_WAKEUP',
    ]);
    await Process.run('adb', <String>['-s', deviceId, 'shell', 'wm', 'dismiss-keyguard']);
    await Process.run('adb', <String>[
      '-s',
      deviceId,
      'shell',
      'setprop',
      'debug.flutter.enable_embedder_api',
      'true',
    ]);

    // 1. Clear logcat buffer before launching test
    await Process.run('adb', <String>['-s', deviceId, 'logcat', '-c']);

    // 2. Start background Perfetto trace on the Android device (180s ring buffer)
    const perfettoConfig = '''
buffers: { size_kb: 32768 fill_policy: RING_BUFFER }
data_sources: {
  config {
    name: "linux.ftrace"
    ftrace_config {
      atrace_categories: "gfx"
      atrace_categories: "view"
      atrace_apps: "*"
    }
  }
}
duration_ms: 180000
''';
    final Process perfettoProc = await Process.start('adb', <String>[
      '-s',
      deviceId,
      'shell',
      'perfetto',
      '-c',
      '-',
      '--txt',
      '-o',
      '/data/misc/perfetto-traces/embedder_verify.pftrace',
    ]);
    perfettoProc.stdin.writeln(perfettoConfig);
    await perfettoProc.stdin.close();

    // 3. Execute the integration/devicelab test with local engine and device ID
    final cmdArgs = <String>[
      ...baseCmd.skip(1),
      '-d',
      deviceId,
      '--local-engine=$localEngine',
      '--local-engine-host=$localEngineHost',
      ...extraTestArgs,
    ];
    final ProcessResult testRes = await Process.run(
      baseCmd.first,
      cmdArgs,
      workingDirectory: workDir,
    );

    // Stop Perfetto gracefully so it flushes the ring buffer to disk
    await Process.run('adb', <String>['-s', deviceId, 'shell', 'killall', '-2', 'perfetto']);
    await perfettoProc.exitCode;

    // 4. Pull Perfetto trace and capture logcat
    final String safeId = id.replaceAll(':', '_');
    final localTracePath = '/tmp/perfetto_embedder_verify_$safeId.pftrace';
    await Process.run('adb', <String>[
      '-s',
      deviceId,
      'pull',
      '/data/misc/perfetto-traces/embedder_verify.pftrace',
      localTracePath,
    ]);
    final ProcessResult logcatRes = await Process.run('adb', <String>[
      '-s',
      deviceId,
      'logcat',
      '-d',
    ]);
    final logcatOutput = logcatRes.stdout.toString();

    // 5. Verify C-API Proof in Logcat & Perfetto Trace
    for (final forbidden in forbiddenLogcat) {
      if (logcatOutput.contains(forbidden)) {
        proofViolations.add(
          '[$id] FATAL: Forbidden legacy Shell marker "$forbidden" detected in logcat while feature flag is TRUE!',
        );
      }
    }
    if (!logcatOutput.contains(requiredLogcat)) {
      proofViolations.add(
        '[$id] FATAL: Required C-API proof marker "$requiredLogcat" NOT found in logcat! The Embedder API path was not exercised.',
      );
    }

    final traceFile = File(localTracePath);
    if (traceFile.existsSync()) {
      final String traceStrings = latin1.decode(traceFile.readAsBytesSync(), allowInvalid: true);
      for (final forbiddenSlice in forbiddenPerfetto) {
        if (traceStrings.contains(forbiddenSlice)) {
          proofViolations.add(
            '[$id] FATAL: Forbidden legacy Shell slice "$forbiddenSlice" detected in Perfetto trace ($localTracePath)!',
          );
        }
      }
      final bool hasRequiredSlice = requiredPerfetto.any(traceStrings.contains);
      if (!hasRequiredSlice) {
        proofViolations.add(
          '[$id] FATAL: None of required Perfetto C-API slices ($requiredPerfetto) found in $localTracePath!',
        );
      }
    }

    if (testRes.exitCode == 0) {
      stdout.writeln(' [PASS] $id (Perfetto trace: $localTracePath)');
      newlyPassing.add(id);
    } else {
      stdout.writeln(
        ' [EXPECTED/TRACKED FAIL] $id (exitCode=${testRes.exitCode}, Perfetto trace: $localTracePath)',
      );
      failingCount++;
    }
  }

  if (proofViolations.isNotEmpty) {
    stderr.writeln(
      '\n================================================================================',
    );
    stderr.writeln('FATAL: EMBEDDER C-API PROOF VERIFICATION FAILED!');
    stderr.writeln(
      '================================================================================',
    );
    for (final v in proofViolations) {
      stderr.writeln(' - $v');
    }
    exit(1);
  }

  // Update ratchet if monotonic
  final prevFailing = state['current_failing_test_count']! as int;
  if (failingCount > prevFailing) {
    stderr.writeln(
      '\nERROR: Failing integration test count increased from $prevFailing to $failingCount! Rejecting ratchet update.',
    );
    exit(1);
  }

  state['current_failing_test_count'] = failingCount;
  state['max_allowed_failing_tests'] = failingCount;
  final existingLocked = Set<String>.from(
    (state['passing_locked_tests']! as List<Object?>).cast<String>(),
  )..addAll(newlyPassing);
  state['passing_locked_tests'] = existingLocked.toList()..sort();

  ratchetFile.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(root)}\n');
  stdout.writeln(
    '\nSUCCESS: Verified C-API proof (0 Shell::Create calls) and updated integration_test_ratchet.json ($failingCount failing, ${existingLocked.length} locked passing).',
  );
}

Future<void> main(List<String> args) async {
  final String command = args.isEmpty ? 'status' : args.first;

  switch (command) {
    case 'status':
      _printStatus();
    case 'verify-static':
      final VerificationOutcome outcome = await _verifyStaticShellIsolation();
      stdout.writeln(outcome.summary);
      if (!outcome.passed) {
        for (final String v in outcome.violations) {
          stderr.writeln('  - $v');
        }
        exit(1);
      }
    case 'verify-ratchet':
      final List<VerificationOutcome> outcomes = await Future.wait(<Future<VerificationOutcome>>[
        _verifyStaticShellIsolation(),
        _verifyRatchetMonotonicity(),
      ]);
      var allPassed = true;
      for (final outcome in outcomes) {
        stdout.writeln(outcome.summary);
        if (!outcome.passed) {
          allPassed = false;
          for (final String v in outcome.violations) {
            stderr.writeln('  - $v');
          }
        }
      }
      if (!allPassed) {
        exit(1);
      }
    case 'run-suite':
      await _runDeviceSuite(args.skip(1).toList());
    default:
      stderr.writeln(
        'Unknown command "$command". Usage: verify_embedder_flag_and_ratchet.dart <status|verify-static|verify-ratchet|run-suite>',
      );
      exit(1);
  }
}
