// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:githooks/githooks.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

// The path to the flutter checkout. Used to run test against a real checkout.
final String _flutterRoot = io.Platform.environment['FLUTTER_ROOT']!;

void main() {
  assert(_flutterRoot.isNotEmpty, 'Use "flutter test" to run this test.');

  test('Fails gracefully without a command', () async {
    int? result;
    try {
      result = await run(<String>[]);
    } catch (e, st) {
      fail('Unexpected exception: $e\n$st');
    }
    expect(result, equals(1));
  });

  test('Fails gracefully with an unknown command', () async {
    int? result;
    try {
      result = await run(<String>['blah']);
    } catch (e, st) {
      fail('Unexpected exception: $e\n$st');
    }
    expect(result, equals(1));
  });

  test('Fails gracefully without --flutter', () async {
    int? result;
    try {
      result = await run(<String>['pre-push']);
    } catch (e, st) {
      fail('Unexpected exception: $e\n$st');
    }
    expect(result, equals(1));
  });

  test('Fails gracefully when --flutter is not an absolute path', () async {
    int? result;
    try {
      result = await run(<String>['pre-push', '--flutter', 'non/absolute']);
    } catch (e, st) {
      fail('Unexpected exception: $e\n$st');
    }
    expect(result, equals(1));
  });

  test('Fails gracefully when --flutter does not exist', () async {
    int? result;
    try {
      result = await run(<String>[
        'pre-push',
        '--flutter',
        if (io.Platform.isWindows) r'C:\does\not\exist' else '/does/not/exist',
      ]);
    } catch (e, st) {
      fail('Unexpected exception: $e\n$st');
    }
    expect(result, equals(1));
  });

  test('post-merge runs successfully', () async {
    int? result;
    try {
      result = await run(<String>['post-merge', '--flutter', _flutterRoot]);
    } catch (e, st) {
      fail('Unexpected exception: $e\n$st');
    }
    expect(result, equals(0));
  });

  test('pre-rebase runs successfully', () async {
    int? result;
    try {
      result = await run(<String>['pre-rebase', '--flutter', _flutterRoot]);
    } catch (e, st) {
      fail('Unexpected exception: $e\n$st');
    }
    expect(result, equals(0));
  });

  test('post-checkout runs successfully', () async {
    int? result;
    try {
      result = await run(<String>['post-checkout', '--flutter', _flutterRoot]);
    } catch (e, st) {
      fail('Unexpected exception: $e\n$st');
    }
    expect(result, equals(0));
  });

  test('Legacy engine/src/flutter/tools/githooks outputs warning', () async {
    final String oldHooksPath = io.Directory(
      path.join(_flutterRoot, 'engine', 'src', 'flutter', 'tools', 'githooks'),
    ).path;

    final io.ProcessResult postCheckoutResult = await io.Process.run(
      path.join(oldHooksPath, 'post-checkout'),
      <String>[],
      workingDirectory: oldHooksPath,
    );
    expect(postCheckoutResult.exitCode, equals(0));
    expect(
      postCheckoutResult.stdout.toString(),
      contains('Githooks location has moved to dev/tools/githooks'),
    );
  });
}
