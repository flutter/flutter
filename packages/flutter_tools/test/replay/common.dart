// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/local.dart';
import 'package:flutter_tools/runner.dart' as tools;
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/io.dart' as io;
import 'package:flutter_tools/src/base/port_scanner.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:test/test.dart';

import '../src/common.dart';
import '../src/context.dart';

/// Runs the specified [testMethod] in a minimal `AppContext` that is set up
/// to redirect log output to a `BufferLogger` to avoid spamming `stdout`.
///
/// Test methods will generally want to use [expectProcessExits] in their method
/// bodies.
void testReplay(
  String description,
  dynamic testMethod(), {
  Timeout timeout,
  Map<Type, Generator> overrides: const <Type, Generator>{},
  bool skip,
}) {
  setUp(() {
    io.setExitFunctionForTests();
  });

  tearDown(() {
    io.restoreExitFunction();
  });

  testUsingContext(
    description,
    testMethod,
    timeout: timeout,
    overrides: overrides,
    skip: skip,
    initializeContext: (AppContext testContext) {
      testContext.putIfAbsent(PortScanner, () => new MockPortScanner());
    },
  );
}

/// Expects that the specified [command] to Flutter tools exits with the
/// specified [exitCode] (defaults to zero). It is expected that callers will
/// be running in a test via [testReplay].
///
/// [command] should be the list of arguments that are passed to the `flutter`
/// command-line tool. For example:
///
/// ```
///   <String>[
///     'run',
///     '--no-hot',
///     '--no-resident',
///   ]
/// ```
void expectProcessExits(
  FlutterCommand command, {
  List<String> args: const <String>[],
  dynamic exitCode: 0,
}) {
  final Future<Null> runFuture = tools.run(
    <String>[command.name]..addAll(args),
    <FlutterCommand>[command],
    reportCrashes: false,
    flutterVersion: 'test',
  );
  expect(runFuture, throwsProcessExit(exitCode));
}

/// The base path of the replay tests.
String get replayBase {
  return const LocalFileSystem().path.joinAll(<String>[
    Cache.flutterRoot,
    'packages',
    'flutter_tools',
    'test',
    'replay',
  ]);
}
