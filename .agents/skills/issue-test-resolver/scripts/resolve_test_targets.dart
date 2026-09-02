// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

void main(List<String> args) async {
  final String scriptPath = Platform.script.toFilePath();
  final Directory scriptDir = File(scriptPath).parent;
  final Directory repoRootDir = scriptDir.parent.parent.parent.parent;

  if (args.isEmpty || !args.first.startsWith('--files=')) {
    stderr.writeln('Error: Must provide candidate files via --files=file1,file2');
    exit(1);
  }

  final String filesArg = args.first.substring('--files='.length);
  final List<String> files = filesArg.split(',');

  stdout.writeln('# Candidate Test Target Resolution Report\n');
  stdout.writeln(
    'Based on the candidate source files provided, the following test targets and verification skills have been identified:\n',
  );

  for (final file in files) {
    stdout.writeln('## Source File: `$file`');
    var resolved = false;

    if (file.startsWith('engine/src/flutter/lib/web_ui/lib/')) {
      final String subPath = file.substring('engine/src/flutter/lib/web_ui/lib/'.length);
      if (subPath.endsWith('.dart')) {
        final testPath =
            'engine/src/flutter/lib/web_ui/test/${subPath.substring(0, subPath.length - 5)}_test.dart';
        if (File('${repoRootDir.path}/$testPath').existsSync()) {
          stdout.writeln('- **Target Test File**: `$testPath`');
          stdout.writeln('- **Test Type**: Web Unit (`felt`)');
          stdout.writeln('- **Execution Skill**: `flutter-web-tester`');
          stdout.writeln('- **Command**: `felt test $testPath`\n');
          resolved = true;
        }
      }
    } else if (file.startsWith('engine/src/flutter/')) {
      stdout.writeln('- **Target Component**: Flutter Engine / Platform Embedding');
      stdout.writeln('- **Test Type**: Engine C++ / Platform Unit (`et`)');
      stdout.writeln('- **Execution Skill**: `flutter-engine-tester`');
      stdout.writeln(
        '- **Command**: `et test //flutter/...` (Use `et query targets --testonly` for specific GN target)\n',
      );
      resolved = true;
    } else if (file.startsWith('packages/flutter/lib/src/')) {
      final String subPath = file.substring('packages/flutter/lib/src/'.length);
      if (subPath.endsWith('.dart')) {
        final testPath =
            'packages/flutter/test/${subPath.substring(0, subPath.length - 5)}_test.dart';
        if (File('${repoRootDir.path}/$testPath').existsSync()) {
          stdout.writeln('- **Target Test File**: `$testPath`');
          stdout.writeln('- **Test Type**: Framework Dart Unit / Widget');
          stdout.writeln('- **Execution Skill**: `flutter-framework-tester`');
          stdout.writeln('- **Command**: `flutter test --no-pub $testPath`\n');
          resolved = true;
        }
      }
    } else if (file.startsWith('packages/flutter_tools/lib/src/')) {
      final String subPath = file.substring('packages/flutter_tools/lib/src/'.length);
      if (subPath.endsWith('.dart')) {
        final testPath =
            'packages/flutter_tools/test/${subPath.substring(0, subPath.length - 5)}_test.dart';
        if (File('${repoRootDir.path}/$testPath').existsSync()) {
          stdout.writeln('- **Target Test File**: `$testPath`');
          stdout.writeln('- **Test Type**: Tool Dart Unit');
          stdout.writeln('- **Execution Skill**: `flutter-framework-tester`');
          stdout.writeln('- **Command**: `flutter test --no-pub $testPath`\n');
          resolved = true;
        }
      }
    }

    if (!resolved) {
      if (file.startsWith('packages/flutter/')) {
        stdout.writeln('- **Target Test Suite**: `packages/flutter/test/`');
        stdout.writeln('- **Execution Skill**: `flutter-framework-tester`');
        stdout.writeln('- **Command**: `flutter test --no-pub packages/flutter/test`\n');
      } else if (file.startsWith('packages/flutter_tools/')) {
        stdout.writeln('- **Target Test Suite**: `packages/flutter_tools/test/`');
        stdout.writeln('- **Execution Skill**: `flutter-framework-tester`');
        stdout.writeln('- **Command**: `flutter test --no-pub packages/flutter_tools/test`\n');
      } else {
        stdout.writeln('- **Target Test Suite**: General Monorepo Suite');
        stdout.writeln('- **Execution Skill**: `flutter-test-orchestrator`');
        stdout.writeln(
          '- **Command**: `dart .agents/skills/flutter-test-orchestrator/scripts/orchestrate.dart --files=$file`\n',
        );
      }
    }
  }
}
