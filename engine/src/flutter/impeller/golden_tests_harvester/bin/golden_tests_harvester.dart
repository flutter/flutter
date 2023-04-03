// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:golden_tests_harvester/golden_tests_harvester.dart';
import 'package:process/src/interface/process_manager.dart';
import 'package:skia_gold_client/skia_gold_client.dart';

const String _kLuciEnvName = 'LUCI_CONTEXT';

bool get isLuciEnv => Platform.environment.containsKey(_kLuciEnvName);

/// Fake SkiaGoldClient that is used if the harvester is run outside of Luci.
class FakeSkiaGoldClient implements SkiaGoldClient {
  FakeSkiaGoldClient(this._workingDirectory);

  final Directory _workingDirectory;

  @override
  Future<void> addImg(String testName, File goldenFile,
      {double differentPixelsRate = 0.01,
      int pixelColorDelta = 0,
      required int screenshotSize}) async {
    Logger.instance.log('addImg testName:$testName goldenFile:${goldenFile.path} screenshotSize:$screenshotSize differentPixelsRate:$differentPixelsRate pixelColorDelta:$pixelColorDelta');
  }

  @override
  Future<void> auth() async {
    Logger.instance.log('auth');
  }

  @override
  String cleanTestName(String fileName) {
    throw UnimplementedError();
  }

  @override
  Map<String, String>? get dimensions => throw UnimplementedError();

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
  final SkiaGoldClient skiaGoldClient = isLuciEnv
      ? SkiaGoldClient(workDirectory)
      : FakeSkiaGoldClient(workDirectory);

  await harvest(skiaGoldClient, workDirectory);
}
