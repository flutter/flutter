// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:test/test.dart';

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/commands/create.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/runner/flutter_command_runner.dart';

/// Gets the path to the root of the Flutter repository.
///
/// This will first look for a `FLUTTER_ROOT` environment variable. If the
/// environment variable is set, it will be returned. Otherwise, this will
/// deduce the path from `platform.script`.
String getFlutterRoot() {
  if (platform.environment.containsKey('FLUTTER_ROOT'))
    return platform.environment['FLUTTER_ROOT'];

  Error invalidScript() => new StateError('Invalid script: ${platform.script}');

  Uri scriptUri;
  switch (platform.script.scheme) {
    case 'file':
      scriptUri = platform.script;
      break;
    case 'data':
      final RegExp flutterTools = new RegExp(r'(file://[^%]*[/\\]flutter_tools[^%]+\.dart)%');
      final Match match = flutterTools.firstMatch(platform.script.path);
      if (match == null)
        throw invalidScript();
      scriptUri = Uri.parse(match.group(1));
      break;
    default:
      throw invalidScript();
  }

  final List<String> parts = fs.path.split(fs.path.fromUri(scriptUri));
  final int toolsIndex = parts.indexOf('flutter_tools');
  if (toolsIndex == -1)
    throw invalidScript();
  final String toolsPath = fs.path.joinAll(parts.sublist(0, toolsIndex + 1));
  return fs.path.normalize(fs.path.join(toolsPath, '..', '..'));
}

CommandRunner<Null> createTestCommandRunner([FlutterCommand command]) {
  final FlutterCommandRunner runner  = new FlutterCommandRunner();
  if (command != null)
    runner.addCommand(command);
  return runner;
}

/// Updates [path] to have a modification time [seconds] from now.
void updateFileModificationTime(String path,
                                DateTime baseTime,
                                int seconds) {
  final DateTime modificationTime = baseTime.add(new Duration(seconds: seconds));
  fs.file(path).setLastModifiedSync(modificationTime);
}

/// Matcher for functions that throw [ToolExit].
Matcher throwsToolExit({int exitCode, String message}) {
  Matcher matcher = isToolExit;
  if (exitCode != null)
    matcher = allOf(matcher, (ToolExit e) => e.exitCode == exitCode);
  if (message != null)
    matcher = allOf(matcher, (ToolExit e) => e.message.contains(message));
  return throwsA(matcher);
}

/// Matcher for [ToolExit]s.
const Matcher isToolExit = const isInstanceOf<ToolExit>();

/// Matcher for functions that throw [ProcessExit].
Matcher throwsProcessExit([dynamic exitCode]) {
  return exitCode == null
      ? throwsA(isProcessExit)
      : throwsA(allOf(isProcessExit, (ProcessExit e) => e.exitCode == exitCode));
}

/// Matcher for [ProcessExit]s.
const Matcher isProcessExit = const isInstanceOf<ProcessExit>();

/// Creates a flutter project in the [temp] directory.
/// Returns the path to the flutter project.
Future<String> createProject(Directory temp) async {
  final String projectPath = fs.path.join(temp.path, 'flutter_project');
  final CreateCommand command = new CreateCommand();
  final CommandRunner<Null> runner = createTestCommandRunner(command);
  await runner.run(<String>['create', '--no-pub', projectPath]);
  return projectPath;
}