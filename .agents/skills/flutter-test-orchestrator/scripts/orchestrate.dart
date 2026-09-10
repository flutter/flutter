// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

void main(List<String> args) async {
  final String scriptPath = Platform.script.toFilePath();
  final Directory scriptDir = File(scriptPath).parent;
  final Directory repoRootDir = scriptDir.parent.parent.parent.parent;

  if (args.isEmpty || !args.first.startsWith('--files=')) {
    stderr.writeln('Error: Must provide changed files via --files=file1,file2');
    exit(1);
  }

  final String filesArg = args.first.substring('--files='.length);
  final List<String> files = filesArg.split(',');

  var engineChanged = false;
  var frameworkChanged = false;
  var webChanged = false;
  var devicelabChanged = false;
  var toolChanged = false;

  final frameworkTargets = <String>[];
  final toolTargets = <String>[];
  final webTargets = <String>[];

  for (final file in files) {
    if (file.startsWith('engine/src/flutter/lib/web_ui/lib/')) {
      webChanged = true;
      final String subPath = file.substring('engine/src/flutter/lib/web_ui/lib/'.length);
      if (subPath.endsWith('.dart')) {
        final testPath =
            'engine/src/flutter/lib/web_ui/test/${subPath.substring(0, subPath.length - 5)}_test.dart';
        if (File('${repoRootDir.path}/$testPath').existsSync()) {
          webTargets.add(testPath);
        }
      }
    } else if (file.startsWith('engine/src/flutter/lib/web_ui/')) {
      webChanged = true;
    } else if (file.startsWith('engine/src/flutter/')) {
      engineChanged = true;
    } else if (file.startsWith('packages/flutter/lib/src/')) {
      frameworkChanged = true;
      final String subPath = file.substring('packages/flutter/lib/src/'.length);
      if (subPath.endsWith('.dart')) {
        final testPath =
            'packages/flutter/test/${subPath.substring(0, subPath.length - 5)}_test.dart';
        if (File('${repoRootDir.path}/$testPath').existsSync()) {
          frameworkTargets.add(testPath);
        }
      }
    } else if (file.startsWith('packages/flutter/')) {
      frameworkChanged = true;
    } else if (file.startsWith('packages/flutter_tools/lib/src/')) {
      toolChanged = true;
      final String subPath = file.substring('packages/flutter_tools/lib/src/'.length);
      if (subPath.endsWith('.dart')) {
        final testPath =
            'packages/flutter_tools/test/${subPath.substring(0, subPath.length - 5)}_test.dart';
        if (File('${repoRootDir.path}/$testPath').existsSync()) {
          toolTargets.add(testPath);
        }
      }
    } else if (file.startsWith('packages/flutter_tools/')) {
      toolChanged = true;
    } else if (file.startsWith('dev/devicelab/') || file.startsWith('dev/integration_tests/')) {
      devicelabChanged = true;
    }
  }

  if (engineChanged) {
    stdout.writeln('Engine files modified. Invoking flutter-engine-builder...');
    final Process buildProc = await Process.start(
      'dart',
      <String>['.agents/skills/flutter-engine-builder/scripts/build_engine.dart'],
      workingDirectory: repoRootDir.path,
      mode: ProcessStartMode.inheritStdio,
    );
    final int buildCode = await buildProc.exitCode;
    if (buildCode != 0) {
      stderr.writeln('Error: Engine build failed with exit code $buildCode');
      exit(buildCode);
    }

    stdout.writeln('Invoking flutter-engine-tester...');
    final Process testProc = await Process.start(
      'dart',
      <String>['.agents/skills/flutter-engine-tester/scripts/test_engine.dart', '//flutter/...'],
      workingDirectory: repoRootDir.path,
      mode: ProcessStartMode.inheritStdio,
    );
    final int testCode = await testProc.exitCode;
    if (testCode != 0) {
      stderr.writeln('Error: Engine tests failed with exit code $testCode');
      exit(testCode);
    }
  }

  if (webChanged) {
    stdout.writeln('Web engine files modified. Invoking flutter-web-tester...');
    final webArgs = <String>['.agents/skills/flutter-web-tester/scripts/test_web.dart'];
    if (webTargets.isNotEmpty) {
      webArgs.addAll(webTargets);
    }
    final Process webProc = await Process.start(
      'dart',
      webArgs,
      workingDirectory: repoRootDir.path,
      mode: ProcessStartMode.inheritStdio,
    );
    final int webCode = await webProc.exitCode;
    if (webCode != 0) {
      stderr.writeln('Error: Web tests failed with exit code $webCode');
      exit(webCode);
    }
  }

  if (frameworkChanged) {
    final targets = frameworkTargets.isNotEmpty
        ? frameworkTargets
        : <String>['packages/flutter/test'];
    stdout.writeln(
      'Framework files modified. Invoking flutter-framework-tester on ${targets.join(', ')}...',
    );
    final frameworkArgs = <String>[
      '.agents/skills/flutter-framework-tester/scripts/test_framework.dart',
    ];
    if (engineChanged) {
      frameworkArgs.add('--local-engine');
    }
    frameworkArgs.addAll(targets);

    final Process frameProc = await Process.start(
      'dart',
      frameworkArgs,
      workingDirectory: repoRootDir.path,
      mode: ProcessStartMode.inheritStdio,
    );
    final int frameCode = await frameProc.exitCode;
    if (frameCode != 0) {
      stderr.writeln('Error: Framework tests failed with exit code $frameCode');
      exit(frameCode);
    }
  }

  if (toolChanged) {
    final targets = toolTargets.isNotEmpty ? toolTargets : <String>['packages/flutter_tools/test'];
    stdout.writeln(
      'Tool files modified. Invoking flutter-framework-tester on ${targets.join(', ')}...',
    );
    final toolArgs = <String>[
      '.agents/skills/flutter-framework-tester/scripts/test_framework.dart',
    ];
    if (engineChanged) {
      toolArgs.add('--local-engine');
    }
    toolArgs.addAll(targets);

    final Process toolProc = await Process.start(
      'dart',
      toolArgs,
      workingDirectory: repoRootDir.path,
      mode: ProcessStartMode.inheritStdio,
    );
    final int toolCode = await toolProc.exitCode;
    if (toolCode != 0) {
      stderr.writeln('Error: Tool tests failed with exit code $toolCode');
      exit(toolCode);
    }
  }

  if (devicelabChanged) {
    stdout.writeln('DeviceLab files modified. Note: Requires connected device.');
  }

  stdout.writeln('All affected test suites orchestrated and verified successfully!');
}
