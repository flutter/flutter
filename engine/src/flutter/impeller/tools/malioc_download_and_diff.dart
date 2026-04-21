#!/usr/bin/env dart
// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// This script automates the process of downloading the `malioc` (Mali Offline Compiler)
/// tools, running the GN and Ninja builds to generate shader performance statistics,
/// and diffing the results against the golden file (`malioc.json`).
///
/// By default, it extracts the version of `malioc` specified in
/// `ci/builders/linux_unopt.json`, downloads it to a temporary directory, and
/// automatically cleans it up when finished.
///
/// Usage:
///   dart flutter/impeller/tools/malioc_download_and_diff.dart [options]
///
/// Options:
///   --config=<config>      The build configuration (default: android_debug_unopt).
///   --target=<target>      The Ninja target to build (default: impeller).
///   --malioc-path=<path>   Use a local `malioc` binary instead of downloading.
///   --update               Update the golden file with the new results.

import 'dart:convert';
import 'dart:io';

class Options {
  Options(this.config, this.target, this.update, this.maliocPath);
  final String config;
  final String target;
  final bool update;
  final String? maliocPath;
}

void main(List<String> arguments) async {
  if (!Platform.isLinux) {
    print('Error: This script is only supported on Linux.');
    exit(1);
  }
  final options = parseArgs(arguments);

  final scriptFile = File(Platform.script.toFilePath());
  final toolsDir = scriptFile.parent;
  final impellerDir = toolsDir.parent;
  final flutterDir = impellerDir.parent;
  final srcRoot = flutterDir.parent;

  Directory? tempDir;
  String? maliocPath = options.maliocPath;

  try {
    if (maliocPath == null) {
      tempDir = Directory.systemTemp.createTempSync('malioc_tools_');
      final armToolsVersion = await getArmToolsVersion(flutterDir);
      print('Using arm_tools version: $armToolsVersion');
      await downloadMalioc(tempDir, armToolsVersion);
      maliocPath = await findMalioc(tempDir);
    }
    print('Using malioc at: $maliocPath');

    await runGN(flutterDir, srcRoot, options.config, maliocPath);
    await runNinja(srcRoot, options.config, options.target);
    await runDiff(flutterDir, srcRoot, options.config, options.update);
  } finally {
    if (tempDir != null && await tempDir.exists()) {
      print('Cleaning up temporary directory: ${tempDir.path}');
      await tempDir.delete(recursive: true);
    }
  }
}

Options parseArgs(List<String> arguments) {
  String config = 'android_debug_unopt';
  String target = 'impeller';
  bool update = false;
  String? maliocPath;

  for (int i = 0; i < arguments.length; i++) {
    final arg = arguments[i];
    if (arg == '--config' && i + 1 < arguments.length) {
      config = arguments[++i];
    } else if (arg.startsWith('--config=')) {
      config = arg.substring('--config='.length);
    } else if (arg == '--target' && i + 1 < arguments.length) {
      target = arguments[++i];
    } else if (arg.startsWith('--target=')) {
      target = arg.substring('--target='.length);
    } else if (arg == '--malioc-path' && i + 1 < arguments.length) {
      maliocPath = arguments[++i];
    } else if (arg.startsWith('--malioc-path=')) {
      maliocPath = arg.substring('--malioc-path='.length);
    } else if (arg == '--update') {
      update = true;
    } else if (arg == '--help' || arg == '-h') {
      print(
        'Usage: dart malioc_download_and_diff.dart [--config=<config>] [--target=<target>] [--malioc-path=<path>] [--update]',
      );
      exit(0);
    }
  }
  return Options(config, target, update, maliocPath);
}

Future<String> getArmToolsVersion(Directory flutterDir) async {
  final jsonFile = File('${flutterDir.path}/ci/builders/linux_unopt.json');
  if (!await jsonFile.exists()) {
    return 'last_updated:2023-02-03T15:32:01-0800';
  }
  try {
    final content = await jsonFile.readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;
    final builds = json['builds'] as List<dynamic>;
    for (final build in builds) {
      if (build is Map<String, dynamic> && build['name'] == 'ci/android_debug_unopt') {
        final deps = build['dependencies'] as List<dynamic>?;
        if (deps != null) {
          for (final dep in deps) {
            if (dep is Map<String, dynamic> && dep['dependency'] == 'arm_tools') {
              return dep['version'] as String;
            }
          }
        }
      }
    }
  } catch (e) {
    print('Error parsing ${jsonFile.path}: $e');
  }
  return 'last_updated:2023-02-03T15:32:01-0800';
}

Future<void> downloadMalioc(Directory armToolsDir, String version) async {
  if (!await armToolsDir.exists()) {
    await armToolsDir.create(recursive: true);
  }

  print('Initializing CIPD in ${armToolsDir.path}...');
  final cipdInitProcess = await Process.start(
    'cipd',
    ['init'],
    workingDirectory: armToolsDir.path,
    mode: ProcessStartMode.inheritStdio,
  );
  final initExitCode = await cipdInitProcess.exitCode;
  if (initExitCode != 0) {
    print('Error running cipd init: $initExitCode');
    exit(initExitCode);
  }

  print('Downloading malioc tools to ${armToolsDir.path}...');
  final cipdProcess = await Process.start('cipd', [
    'install',
    'flutter_internal/tools/arm-tools',
    version,
    '-root',
    armToolsDir.path,
  ], mode: ProcessStartMode.inheritStdio);
  final exitCode = await cipdProcess.exitCode;
  if (exitCode != 0) {
    print('Error running cipd install: $exitCode');
    exit(exitCode);
  }
}

Future<String> findMalioc(Directory armToolsDir) async {
  if (await armToolsDir.exists()) {
    await for (final entity in armToolsDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('/malioc')) {
        return entity.path;
      }
    }
  }
  print('Error: Could not find malioc executable in downloaded tools.');
  exit(1);
}

Future<void> runGN(
  Directory flutterDir,
  Directory srcRoot,
  String config,
  String maliocPath,
) async {
  print('Running GN...');
  final gnArgs = ['--malioc-path', maliocPath];
  if (config == 'android_debug_unopt') {
    gnArgs.addAll(['--android', '--unoptimized']);
  } else if (config == 'host_debug_unopt') {
    gnArgs.add('--unoptimized');
  }

  final process = await Process.start(
    '${flutterDir.path}/tools/gn',
    gnArgs,
    workingDirectory: srcRoot.path,
    mode: ProcessStartMode.inheritStdio,
  );
  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    print('Error running GN: $exitCode');
    exit(exitCode);
  }
}

Future<void> runNinja(Directory srcRoot, String config, String target) async {
  print('Building target \'$target\' in $config...');
  final process = await Process.start(
    'ninja',
    ['-C', '${srcRoot.path}/out/$config', target],
    workingDirectory: srcRoot.path,
    mode: ProcessStartMode.inheritStdio,
  );
  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    print('Error running Ninja: $exitCode');
    exit(exitCode);
  }
}

Future<void> runDiff(Directory flutterDir, Directory srcRoot, String config, bool update) async {
  print('Generating diff...');
  final diffArgs = [
    '${flutterDir.path}/impeller/tools/malioc_diff.py',
    '--before',
    '${flutterDir.path}/impeller/tools/malioc.json',
    '--after',
    '${srcRoot.path}/out/$config/gen/malioc',
    '--print-diff',
  ];
  if (update) {
    diffArgs.add('--update');
  }

  final process = await Process.start(
    'python3',
    diffArgs,
    workingDirectory: srcRoot.path,
    mode: ProcessStartMode.inheritStdio,
  );
  final exitCode = await process.exitCode;
  exit(exitCode);
}
