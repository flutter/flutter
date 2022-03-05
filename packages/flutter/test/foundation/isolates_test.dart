// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart';

int test1(int value) {
  return value + 1;
}

int test2(int value) {
  throw 2;
}

int test3(int value) {
  Isolate.exit();
}

int test4(int value) {
  Isolate.current.kill();

  return value + 1;
}

int test5(int value) {
  Isolate.current.kill(priority: Isolate.immediate);

  return value + 1;
}

Future<int> test1Async(int value) async {
  return value + 1;
}

Future<int> test2Async(int value) async {
  throw 2;
}

Future<int> test3Async(int value) async {
  Isolate.exit();
}

Future<int> test4Async(int value) async {
  Isolate.current.kill();

  return value + 1;
}

Future<int> test5Async(int value) async {
  Isolate.current.kill(priority: Isolate.immediate);

  return value + 1;
}

Future<int> test1CallCompute(int value) {
  return compute(test1, value);
}

Future<int> test2CallCompute(int value) {
  return compute(test2, value);
}

Future<int> test3CallCompute(int value) {
  return compute(test3, value);
}

Future<int> test4CallCompute(int value) {
  return compute(test4, value);
}

Future<int> test5CallCompute(int value) {
  return compute(test5, value);
}

void main() {
  test('compute()', () async {
    expect(await compute(test1, 0), 1);
    expect(compute(test2, 0), throwsException);
    expect(compute(test3, 0), throwsException);
    expect(await compute(test4, 0), 1);
    expect(compute(test5, 0), throwsException);

    expect(await compute(test1Async, 0), 1);
    expect(compute(test2Async, 0), throwsException);
    expect(compute(test3Async, 0), throwsException);
    expect(await compute(test4Async, 0), 1);
    expect(compute(test5Async, 0), throwsException);

    expect(await compute(test1CallCompute, 0), 1);
    expect(compute(test2CallCompute, 0), throwsException);
    expect(compute(test3CallCompute, 0), throwsException);
    expect(await compute(test4CallCompute, 0), 1);
    expect(compute(test5CallCompute, 0), throwsException);
  }, skip: kIsWeb); // [intended] isn't supported on the web.

  test('compute closes all ports', () async {
    // Run a Dart script that calls compute().
    // The Dart process will terminate only if the script exits cleanly with
    // all isolate ports closed.
    const FileSystem fs = LocalFileSystem();
    const Platform platform = LocalPlatform();
    final String flutterRoot = platform.environment['FLUTTER_ROOT']!;
    final String dartPath = fs.path.join(flutterRoot, 'bin', 'cache', 'dart-sdk', 'bin', 'dart');
    final String packageRoot = fs.path.dirname(fs.path.fromUri(platform.script));
    final String scriptPath = fs.path.join(packageRoot, 'test', 'foundation', '_compute_caller.dart');
    final ProcessResult result = await Process.run(dartPath, <String>[scriptPath]);
    expect(result.exitCode, 0);
  }, skip: kIsWeb); // [intended] isn't supported on the web.
}
