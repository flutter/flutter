// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:engine_repo_tools/engine_repo_tools.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  final engine = Engine.findWithin();
  final String? manualBuildDir = io.Platform.environment['FLUTTER_BUILD_DIRECTORY'];
  final String? buildDir = manualBuildDir ?? engine.latestOutput()?.path.path;
  if (buildDir == null) {
    fail('No build directory found. Set FLUTTER_BUILD_DIRECTORY');
  }
  final String frontendServer = path.join(buildDir, 'gen', 'frontend_server_aot.dart.snapshot');
  final String sdkRoot = path.join(buildDir, 'flutter_patched_sdk');

  final String dart = io.Platform.resolvedExecutable;
  final String dartaotruntime = path.join(
    path.dirname(io.Platform.resolvedExecutable),
    'dartaotruntime',
  );

  final String engineDir = engine.flutterDir.path;
  final String basePath = path.join(engineDir, 'flutter_frontend_server');
  final String fixtures = path.join(basePath, 'test', 'fixtures');
  final String mainDart = path.join(fixtures, 'lib', 'main.dart');
  final String packageConfig = path.join(fixtures, '.dart_tool', 'package_config.json');
  final String regularDill = path.join(fixtures, 'toString.dill');
  final String transformedDill = path.join(fixtures, 'toStringTransformed.dill');

  void checkProcessResult(io.ProcessResult result) {
    printOnFailure(result.stdout.toString());
    printOnFailure(result.stderr.toString());
    expect(result.exitCode, 0);
  }

  test('Without flag', () {
    checkProcessResult(
      io.Process.runSync(dartaotruntime, <String>[
        frontendServer,
        '--sdk-root=$sdkRoot',
        '--target=flutter',
        '--packages=$packageConfig',
        '--output-dill=$regularDill',
        mainDart,
      ]),
    );
    final io.ProcessResult runResult = io.Process.runSync(dart, <String>[regularDill]);
    checkProcessResult(runResult);
    var paintString =
        '"Paint.toString":"Paint(Color(alpha: 1.0000, red: 1.0000, green: 1.0000, blue: 1.0000, colorSpace: ColorSpace.sRGB))"';
    if (buildDir.contains('release')) {
      paintString = '"Paint.toString":"Instance of \'Paint\'"';
    }

    final expectedStdout =
        '{$paintString,'
        '"Brightness.toString":"Brightness.dark",'
        '"Foo.toString":"I am a Foo",'
        '"Keep.toString":"I am a Keep"}';
    final String actualStdout = (runResult.stdout as String).trim();
    expect(actualStdout, equals(expectedStdout));
  });

  test('With flag', () {
    checkProcessResult(
      io.Process.runSync(dartaotruntime, <String>[
        frontendServer,
        '--sdk-root=$sdkRoot',
        '--target=flutter',
        '--packages=$packageConfig',
        '--output-dill=$transformedDill',
        '--delete-tostring-package-uri',
        'dart:ui',
        '--delete-tostring-package-uri',
        'package:flutter_frontend_fixtures',
        mainDart,
      ]),
    );
    final io.ProcessResult runResult = io.Process.runSync(dart, <String>[transformedDill]);
    checkProcessResult(runResult);

    const expectedStdout =
        '{"Paint.toString":"Instance of \'Paint\'",'
        '"Brightness.toString":"Brightness.dark",'
        '"Foo.toString":"Instance of \'Foo\'",'
        '"Keep.toString":"I am a Keep"}';
    final String actualStdout = (runResult.stdout as String).trim();
    expect(actualStdout, equals(expectedStdout));
  });
}
