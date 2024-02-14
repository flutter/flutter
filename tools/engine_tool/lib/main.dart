// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi' as ffi show Abi;
import 'dart:io' as io show Directory, exitCode, stderr, stdout;

import 'package:engine_build_configs/engine_build_configs.dart';
import 'package:engine_repo_tools/engine_repo_tools.dart';
import 'package:path/path.dart' as p;
import 'package:platform/platform.dart';
import 'package:process_runner/process_runner.dart';

import 'src/commands/command_runner.dart';
import 'src/environment.dart';

void main(List<String> args) async {
  // Find the engine repo.
  final Engine engine;
  try {
    engine = Engine.findWithin();
  } catch (e) {
    io.stderr.writeln(e);
    io.exitCode = 1;
    return;
  }

  // Find and parse the engine build configs.
  final io.Directory buildConfigsDir = io.Directory(p.join(
    engine.flutterDir.path, 'ci', 'builders',
  ));
  final BuildConfigLoader loader = BuildConfigLoader(
    buildConfigsDir: buildConfigsDir,
  );

  // Treat it as an error if no build configs were found. The caller likely
  // expected to find some.
  final Map<String, BuildConfig> configs = loader.configs;
  if (configs.isEmpty) {
    io.stderr.writeln(
      'Error: No build configs found under ${buildConfigsDir.path}',
    );
    io.exitCode = 1;
    return;
  }
  if (loader.errors.isNotEmpty) {
    loader.errors.forEach(io.stderr.writeln);
    io.exitCode = 1;
  }

  // Use the Engine and BuildConfig collection to build the CommandRunner.
  final ToolCommandRunner runner = ToolCommandRunner(
    environment: Environment(
      abi: ffi.Abi.current(),
      engine: engine,
      platform: const LocalPlatform(),
      processRunner: ProcessRunner(),
      stderr: io.stderr,
      stdout: io.stdout,
    ),
    configs: configs,
  );

  io.exitCode = await runner.run(args);
  return;
}
