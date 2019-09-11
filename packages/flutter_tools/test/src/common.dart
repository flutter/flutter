// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/commands/create.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/runner/flutter_command_runner.dart';
import 'package:test_api/test_api.dart' as test_package show TypeMatcher;
import 'package:test_api/test_api.dart' hide TypeMatcher, isInstanceOf;

export 'package:test_core/test_core.dart' hide TypeMatcher, isInstanceOf; // Defines a 'package:test' shim.

/// A matcher that compares the type of the actual value to the type argument T.
// TODO(ianh): Remove this once https://github.com/dart-lang/matcher/issues/98 is fixed
Matcher isInstanceOf<T>() => test_package.TypeMatcher<T>();

void tryToDelete(Directory directory) {
  // This should not be necessary, but it turns out that
  // on Windows it's common for deletions to fail due to
  // bogus (we think) "access denied" errors.
  try {
    directory.deleteSync(recursive: true);
  } on FileSystemException catch (error) {
    print('Failed to delete ${directory.path}: $error');
  }
}

/// Gets the path to the root of the Flutter repository.
///
/// This will first look for a `FLUTTER_ROOT` environment variable. If the
/// environment variable is set, it will be returned. Otherwise, this will
/// deduce the path from `platform.script`.
String getFlutterRoot() {
  if (platform.environment.containsKey('FLUTTER_ROOT'))
    return platform.environment['FLUTTER_ROOT'];

  Error invalidScript() => StateError('Invalid script: ${platform.script}');

  Uri scriptUri;
  switch (platform.script.scheme) {
    case 'file':
      scriptUri = platform.script;
      break;
    case 'data':
      final RegExp flutterTools = RegExp(r'(file://[^"]*[/\\]flutter_tools[/\\][^"]+\.dart)', multiLine: true);
      final Match match = flutterTools.firstMatch(Uri.decodeFull(platform.script.path));
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

CommandRunner<void> createTestCommandRunner([ FlutterCommand command ]) {
  final FlutterCommandRunner runner = FlutterCommandRunner();
  if (command != null)
    runner.addCommand(command);
  return runner;
}

/// Updates [path] to have a modification time [seconds] from now.
void updateFileModificationTime(
  String path,
  DateTime baseTime,
  int seconds,
) {
  final DateTime modificationTime = baseTime.add(Duration(seconds: seconds));
  fs.file(path).setLastModifiedSync(modificationTime);
}

/// Matcher for functions that throw [ToolExit].
Matcher throwsToolExit({ int exitCode, Pattern message }) {
  Matcher matcher = isToolExit;
  if (exitCode != null)
    matcher = allOf(matcher, (ToolExit e) => e.exitCode == exitCode);
  if (message != null)
    matcher = allOf(matcher, (ToolExit e) => e.message.contains(message));
  return throwsA(matcher);
}

/// Matcher for [ToolExit]s.
final Matcher isToolExit = isInstanceOf<ToolExit>();

/// Matcher for functions that throw [ProcessExit].
Matcher throwsProcessExit([ dynamic exitCode ]) {
  return exitCode == null
      ? throwsA(isProcessExit)
      : throwsA(allOf(isProcessExit, (ProcessExit e) => e.exitCode == exitCode));
}

/// Matcher for [ProcessExit]s.
final Matcher isProcessExit = isInstanceOf<ProcessExit>();

/// Creates a flutter project in the [temp] directory using the
/// [arguments] list if specified, or `--no-pub` if not.
/// Returns the path to the flutter project.
Future<String> createProject(Directory temp, { List<String> arguments }) async {
  arguments ??= <String>['--no-pub'];
  final String projectPath = fs.path.join(temp.path, 'flutter_project');
  final CreateCommand command = CreateCommand();
  final CommandRunner<void> runner = createTestCommandRunner(command);
  await runner.run(<String>['create', ...arguments, projectPath]);
  // Created `.packages` since it's not created when the flag `--no-pub` is passed.
  fs.file(fs.path.join(projectPath, '.packages')).createSync();
  return projectPath;
}

/// Test case timeout for tests involving remote calls to `pub get` or similar.
const Timeout allowForRemotePubInvocation = Timeout.factor(10.0);

/// Test case timeout for tests involving creating a Flutter project with
/// `--no-pub`. Use [allowForRemotePubInvocation] when creation involves `pub`.
const Timeout allowForCreateFlutterProject = Timeout.factor(3.0);

Future<void> expectToolExitLater(Future<dynamic> future, Matcher messageMatcher) async {
  try {
    await future;
    fail('ToolExit expected, but nothing thrown');
  } on ToolExit catch(e) {
    expect(e.message, messageMatcher);
  } catch(e, trace) {
    fail('ToolExit expected, got $e\n$trace');
  }
}
