// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:litetest/litetest.dart';
import 'package:path/path.dart' as path;

Future<void> main(List<String> args) async {
  if (args.length != 3) {
    stderr.writeln('The first argument must be the path to the build output.');
    stderr.writeln('The second argument must be the path to the frontend server dill.');
    stderr.writeln('The third argument must be the path to the flutter_patched_sdk');
    exit(-1);
  }

  final String dart = Platform.resolvedExecutable;
  final String buildDir = args[0];
  final String frontendServer = args[1];
  final String sdkRoot = args[2];
  final String basePath = path.canonicalize(path.join(path.dirname(Platform.script.toFilePath()), '..'));
  final String fixtures = path.join(basePath, 'test', 'fixtures');
  final String mainDart = path.join(fixtures, 'lib', 'main.dart');
  final String packageConfig = path.join(fixtures, '.dart_tool', 'package_config.json');
  final String regularDill = path.join(fixtures, 'toString.dill');
  final String transformedDill = path.join(fixtures, 'toStringTransformed.dill');

  void checkProcessResult(ProcessResult result) {
    if (result.exitCode != 0) {
      stdout.writeln(result.stdout);
      stderr.writeln(result.stderr);
    }
    expect(result.exitCode, 0);
  }

  test('Without flag', () {
    checkProcessResult(Process.runSync(dart, <String>[
      frontendServer,
      '--sdk-root=$sdkRoot',
      '--target=flutter',
      '--packages=$packageConfig',
      '--output-dill=$regularDill',
      mainDart,
    ]));
    final ProcessResult runResult = Process.runSync(dart, <String>[regularDill]);
    checkProcessResult(runResult);
    // TODO(matanlurey): "dither: true" is now present by default, until it is
    // remove entirely. See https://github.com/flutter/flutter/issues/112498.
    String paintString = '"Paint.toString":"Paint(Color(0xffffffff); dither: true)"';
    if (buildDir.contains('release')) {
      paintString = '"Paint.toString":"Instance of \'Paint\'"';
    }

    final String expectedStdout = '{$paintString,'
      '"Brightness.toString":"Brightness.dark",'
      '"Foo.toString":"I am a Foo",'
      '"Keep.toString":"I am a Keep"}';
    final String actualStdout = (runResult.stdout as String).trim();
    expect(actualStdout, equals(expectedStdout));
  });

  test('With flag', () {
    checkProcessResult(Process.runSync(dart, <String>[
      frontendServer,
      '--sdk-root=$sdkRoot',
      '--target=flutter',
      '--packages=$packageConfig',
      '--output-dill=$transformedDill',
      '--delete-tostring-package-uri', 'dart:ui',
      '--delete-tostring-package-uri', 'package:flutter_frontend_fixtures',
      mainDart,
    ]));
    final ProcessResult runResult = Process.runSync(dart, <String>[transformedDill]);
    checkProcessResult(runResult);

    const String expectedStdout = '{"Paint.toString":"Instance of \'Paint\'",'
      '"Brightness.toString":"Brightness.dark",'
      '"Foo.toString":"Instance of \'Foo\'",'
      '"Keep.toString":"I am a Keep"}';
    final String actualStdout = (runResult.stdout as String).trim();
    expect(actualStdout, equals(expectedStdout));
  });
}
