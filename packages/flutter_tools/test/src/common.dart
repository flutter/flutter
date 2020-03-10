// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';

import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/commands/create.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/runner/flutter_command_runner.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:meta/meta.dart';
import 'package:test_api/test_api.dart' as test_package show TypeMatcher, test; // ignore: deprecated_member_use
import 'package:test_api/test_api.dart' hide TypeMatcher, isInstanceOf; // ignore: deprecated_member_use
// ignore: deprecated_member_use
export 'package:test_core/test_core.dart' hide TypeMatcher, isInstanceOf; // Defines a 'package:test' shim.

/// A matcher that compares the type of the actual value to the type argument T.
// TODO(ianh): Remove this once https://github.com/dart-lang/matcher/issues/98 is fixed
test_package.TypeMatcher<T> isInstanceOf<T>() => isA<T>();

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
  if (globals.platform.environment.containsKey('FLUTTER_ROOT')) {
    return globals.platform.environment['FLUTTER_ROOT'];
  }

  Error invalidScript() => StateError('Could not determine flutter_tools/ path from script URL (${globals.platform.script}); consider setting FLUTTER_ROOT explicitly.');

  Uri scriptUri;
  switch (globals.platform.script.scheme) {
    case 'file':
      scriptUri = globals.platform.script;
      break;
    case 'data':
      final RegExp flutterTools = RegExp(r'(file://[^"]*[/\\]flutter_tools[/\\][^"]+\.dart)', multiLine: true);
      final Match match = flutterTools.firstMatch(Uri.decodeFull(globals.platform.script.path));
      if (match == null) {
        throw invalidScript();
      }
      scriptUri = Uri.parse(match.group(1));
      break;
    default:
      throw invalidScript();
  }

  final List<String> parts = globals.fs.path.split(globals.fs.path.fromUri(scriptUri));
  final int toolsIndex = parts.indexOf('flutter_tools');
  if (toolsIndex == -1) {
    throw invalidScript();
  }
  final String toolsPath = globals.fs.path.joinAll(parts.sublist(0, toolsIndex + 1));
  return globals.fs.path.normalize(globals.fs.path.join(toolsPath, '..', '..'));
}

CommandRunner<void> createTestCommandRunner([ FlutterCommand command ]) {
  final FlutterCommandRunner runner = FlutterCommandRunner();
  if (command != null) {
    runner.addCommand(command);
  }
  return runner;
}

/// Updates [path] to have a modification time [seconds] from now.
void updateFileModificationTime(
  String path,
  DateTime baseTime,
  int seconds,
) {
  final DateTime modificationTime = baseTime.add(Duration(seconds: seconds));
  globals.fs.file(path).setLastModifiedSync(modificationTime);
}

/// Matcher for functions that throw [AssertionError].
final Matcher throwsAssertionError = throwsA(isA<AssertionError>());

/// Matcher for functions that throw [ToolExit].
Matcher throwsToolExit({ int exitCode, Pattern message }) {
  Matcher matcher = isToolExit;
  if (exitCode != null) {
    matcher = allOf(matcher, (ToolExit e) => e.exitCode == exitCode);
  }
  if (message != null) {
    matcher = allOf(matcher, (ToolExit e) => e.message.contains(message));
  }
  return throwsA(matcher);
}

/// Matcher for [ToolExit]s.
final test_package.TypeMatcher<ToolExit> isToolExit = isA<ToolExit>();

/// Matcher for functions that throw [ProcessExit].
Matcher throwsProcessExit([ dynamic exitCode ]) {
  return exitCode == null
      ? throwsA(isProcessExit)
      : throwsA(allOf(isProcessExit, (ProcessExit e) => e.exitCode == exitCode));
}

/// Matcher for [ProcessExit]s.
final test_package.TypeMatcher<ProcessExit> isProcessExit = isA<ProcessExit>();

/// Creates a flutter project in the [temp] directory using the
/// [arguments] list if specified, or `--no-pub` if not.
/// Returns the path to the flutter project.
Future<String> createProject(Directory temp, { List<String> arguments }) async {
  arguments ??= <String>['--no-pub'];
  final String projectPath = globals.fs.path.join(temp.path, 'flutter_project');
  final CreateCommand command = CreateCommand();
  final CommandRunner<void> runner = createTestCommandRunner(command);
  await runner.run(<String>['create', ...arguments, projectPath]);
  // Created `.packages` since it's not created when the flag `--no-pub` is passed.
  globals.fs.file(globals.fs.path.join(projectPath, '.packages')).createSync();
  return projectPath;
}

Future<void> expectToolExitLater(Future<dynamic> future, Matcher messageMatcher) async {
  try {
    await future;
    fail('ToolExit expected, but nothing thrown');
  } on ToolExit catch(e) {
    expect(e.message, messageMatcher);
  // Catch all exceptions to give a better test failure message.
  } catch (e, trace) { // ignore: avoid_catches_without_on_clauses
    fail('ToolExit expected, got $e\n$trace');
  }
}

/// Executes a test body in zone that does not allow context-based injection.
///
/// For classes which have been refactored to excluded context-based injection
/// or globals like [fs] or [platform], prefer using this test method as it
/// will prevent accidentally including these context getters in future code
/// changes.
///
/// For more information, see https://github.com/flutter/flutter/issues/47161
@isTest
void testWithoutContext(String description, FutureOr<void> body(), {
  String testOn,
  Timeout timeout,
  bool skip,
  List<String> tags,
  Map<String, dynamic> onPlatform,
  int retry,
  }) {
  return test_package.test(
    description, () async {
      return runZoned(body, zoneValues: <Object, Object>{
        contextKey: const NoContext(),
      });
    },
    timeout: timeout,
    skip: skip,
    tags: tags,
    onPlatform: onPlatform,
    retry: retry,
    testOn: testOn,
  );
}

/// An implementation of [AppContext] that throws if context.get is called in the test.
///
/// The intention of the class is to ensure we do not accidentally regress when
/// moving towards more explicit dependency injection by accidentally using
/// a Zone value in place of a constructor parameter.
class NoContext implements AppContext {
  const NoContext();

  @override
  T get<T>() {
    throw UnsupportedError(
      'context.get<$T> is not supported in test methods. '
      'Use Testbed or testUsingContext if accessing Zone injected '
      'values.'
    );
  }

  @override
  String get name => 'No Context';

  @override
  Future<V> run<V>({
    FutureOr<V> Function() body,
    String name,
    Map<Type, Generator> overrides,
    Map<Type, Generator> fallbacks,
    ZoneSpecification zoneSpecification,
  }) async {
    return body();
  }
}
