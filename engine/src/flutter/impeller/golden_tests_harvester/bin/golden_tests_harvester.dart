// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:golden_tests_harvester/golden_tests_harvester.dart';
import 'package:path/path.dart' as p;
import 'package:process/src/interface/process_manager.dart';
import 'package:skia_gold_client/skia_gold_client.dart';

const String _kLuciEnvName = 'LUCI_CONTEXT';

bool get isLuciEnv => Platform.environment.containsKey(_kLuciEnvName);

/// Fake SkiaGoldClient that is used if the harvester is run outside of Luci.
class FakeSkiaGoldClient implements SkiaGoldClient {
  FakeSkiaGoldClient(this._workingDirectory, {this.dimensions});

  final Directory _workingDirectory;

  @override
  final Map<String, String>? dimensions;

  @override
  Future<void> addImg(String testName, File goldenFile,
      {double differentPixelsRate = 0.01,
      int pixelColorDelta = 0,
      required int screenshotSize}) async {
    Logger.instance.log(
        'addImg testName:$testName goldenFile:${goldenFile.path} screenshotSize:$screenshotSize differentPixelsRate:$differentPixelsRate pixelColorDelta:$pixelColorDelta');
  }

  @override
  Future<void> auth() async {
    Logger.instance.log('auth dimensions:${dimensions ?? 'null'}');
  }

  @override
  String cleanTestName(String fileName) {
    throw UnimplementedError();
  }

  @override
  List<String> getCIArguments() {
    throw UnimplementedError();
  }

  @override
  Future<String?> getExpectationForTest(String testName) {
    throw UnimplementedError();
  }

  @override
  Future<List<int>> getImageBytes(String imageHash) {
    throw UnimplementedError();
  }

  @override
  String getTraceID(String testName) {
    throw UnimplementedError();
  }

  @override
  HttpClient get httpClient => throw UnimplementedError();

  @override
  ProcessManager get process => throw UnimplementedError();

  @override
  Directory get workDirectory => _workingDirectory;
}

void _printUsage() {
  Logger.instance
      .log('dart run ./bin/golden_tests_harvester.dart <working_dir>');
}

Future<void> main(List<String> arguments) async {
  if (arguments.length != 1) {
    return _printUsage();
  }

  final Directory workDirectory = Directory(arguments[0]);

  final File digest = File(p.join(workDirectory.path, 'digest.json'));
  if (!digest.existsSync()) {
    Logger.instance
        .log('Error: digest.json does not exist in ${workDirectory.path}.');
    return;
  }
  final Object? decoded = jsonDecode(digest.readAsStringSync());
  final Map<String?, Object?> data = (decoded as Map<String?, Object?>?)!;
  final Map<String, String> dimensions =
      (data['dimensions'] as Map<String, Object?>?)!.cast<String, String>();
  final List<Object?> entries = (data['entries'] as List<Object?>?)!;

  final SkiaGoldClient skiaGoldClient = isLuciEnv
      ? SkiaGoldClient(workDirectory, dimensions: dimensions)
      : FakeSkiaGoldClient(workDirectory, dimensions: dimensions);

  await harvest(skiaGoldClient, workDirectory, entries);
}
