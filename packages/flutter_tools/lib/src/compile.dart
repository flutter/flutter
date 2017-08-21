// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/globals.dart';

Future<String> compile({String sdkRoot, String packagesPath, String mainPath}) async {
  final String engineDartSdkPath = artifacts.getArtifactPath(Artifact.engineDartSdkPath);
  final String frontendServer = artifacts.getArtifactPath(Artifact.frontendServerSnapshotForEngineDartSdk);

  final Process server = await Process.start('$engineDartSdkPath/bin/dart',
      <String>[frontendServer, '--sdk-root', sdkRoot + '/', mainPath]);
  String boundaryKey;
  String outputFilename;

  server.stderr
      .transform(UTF8.decoder)
      .listen((String s) { print(s); });
  server.stdout
      .transform(UTF8.decoder)
      .transform(new LineSplitter())
      .listen((String string) async {
        if (boundaryKey == null) {
          if (string.startsWith('result ')) {
            boundaryKey = string.substring('result '.length);
          }
        } else {
          if (string.startsWith(boundaryKey)) {
            outputFilename = string.substring(boundaryKey.length + 1);
          } else {
            print(string);
          }
        }
      });
  await server.exitCode;
  return outputFilename;
}

class ResidentCompiler {
  Process compiler;

  Future<Null> compile(String sdkRoot) async {
    final String engineDartSdkPath = artifacts.getArtifactPath(Artifact.engineDartSdkPath);
    final String frontendServer = artifacts.getArtifactPath(Artifact.frontendServerSnapshotForEngineDartSdk);

    final Process server = await Process.start('$engineDartSdkPath/bin/dart',
        <String>[frontendServer, '--sdk-root', sdkRoot + '/']);
    return new Future<Null>.value(null);
  }

  void invalidate(Uri uri) {
    // TOOD(aam): Send invalidate command
  }

}