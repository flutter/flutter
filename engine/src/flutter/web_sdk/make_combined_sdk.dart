// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:dev_compiler/src/analyzer/command.dart' as command; // ignore: uri_does_not_exist

// Creates flutter precompiled web sdk and analyzer summary.
Future<void> main() async {
  // create a temporary dart-sdk directory.
  final Directory tempDartSdk = Directory(path.join('temp_dart_sdk', 'lib'))
    ..createSync(recursive: true);
  final Directory patchedDartSdk = Directory(path.join(
      'gen', 'third_party', 'dart', 'utils', 'dartdevc', 'patched_sdk', 'lib'));
  final Directory flutterWebUi = Directory(path.join(
    'flutter_web_sdk',
    'lib',
    'ui',
  ));

  // Copy this patched dart sdk into the temporary directory.
  for (FileSystemEntity entity in patchedDartSdk.listSync(recursive: true)) {
    if (entity is File) {
      final String targetPath = path.join(tempDartSdk.path,
          path.relative(entity.path, from: patchedDartSdk.path));
      File(targetPath).createSync(recursive: true);
      entity.copySync(path.join(tempDartSdk.path,
          path.relative(entity.path, from: patchedDartSdk.path)));
    }
  }
  // Copy the dart:ui sources into the temporary directory.
  for (FileSystemEntity entity in flutterWebUi.listSync(recursive: true)) {
    if (entity is File) {
      final String targetPath = path.join(tempDartSdk.path, 'ui',
          path.relative(entity.path, from: flutterWebUi.path));
      File(targetPath).createSync(recursive: true);
      entity.copySync(targetPath);
    }
  }
  // Copy the libraries.dart file into the temporary directory.
  final File libraries = File(path.join('..', '..', 'flutter', 'web_sdk', 'libraries.dart'));
  libraries.copySync(path.join(tempDartSdk.path, '_internal', 'libraries.dart'));
  libraries.copySync(path.join(tempDartSdk.path, '_internal', 'sdk_library_metadata', 'lib', 'libraries.dart'));

  // Prevent regular compilation from leaking into flutter
  final File ddcSummary =
      File(path.join(tempDartSdk.path, '_internal', 'ddc_sdk.sum'));
  final File jsSdk =
      File(path.join(tempDartSdk.parent.path, 'js', 'amd', 'dart_sdk.js'));
  final File jsSdkMap =
      File(path.join(tempDartSdk.parent.path, 'js', 'amd', 'dart_sdk.js.map'));
  if (ddcSummary.existsSync()) {
    ddcSummary.deleteSync();
  }
  if (jsSdk.existsSync()) {
    jsSdk.deleteSync();
  }
  if (jsSdkMap.existsSync()) {
    jsSdkMap.deleteSync();
  }

  // Execute the analyzer summary and sdk generation.
  final List<String> args = <String>['--no-source-map', '--no-emit-metadata'];
  args.addAll(<String>[
    '--dart-sdk=temp_dart_sdk',
    '--dart-sdk-summary=build',
    '--summary-out=temp_dart_sdk/lib/_internal/ddc_sdk.sum',
    '--source-map',
    '--source-map-comment',
    '--modules=amd',
    '-o',
    'temp_dart_sdk/js/amd/dart_sdk.js'
  ]);
  args.addAll(<String>[
    'dart:_runtime',
    'dart:_debugger',
    'dart:_foreign_helper',
    'dart:_interceptors',
    'dart:_internal',
    'dart:_isolate_helper',
    'dart:_js_helper',
    'dart:_js_mirrors',
    'dart:_js_primitives',
    'dart:_metadata',
    'dart:_native_typed_data',
    'dart:async',
    'dart:collection',
    'dart:convert',
    'dart:core',
    'dart:developer',
    'dart:io',
    'dart:isolate',
    'dart:js',
    'dart:js_util',
    'dart:math',
    'dart:mirrors',
    'dart:typed_data',
    'dart:indexed_db',
    'dart:html',
    'dart:html_common',
    'dart:svg',
    'dart:web_audio',
    'dart:web_gl',
    'dart:web_sql',
    'dart:ui',
  ]);
  final int result = (await command.compile(args)).exitCode;
  if (result != 0) {
    throw 'SDK generation failed with exit code $result';
  }

  // Copy generated sdk and summary back to flutter web sdk.
  ddcSummary.copySync(
      path.join('flutter_web_sdk', 'lib', '_internal', 'ddc_sdk.sum'));
  jsSdk.copySync(path.join('flutter_web_sdk', 'js', 'amd', 'dart_sdk.js'));
  jsSdkMap
      .copySync(path.join('flutter_web_sdk', 'js', 'amd', 'dart_sdk.js.map'));
}
