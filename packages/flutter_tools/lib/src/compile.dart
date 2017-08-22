// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/globals.dart';
import 'package:usage/uuid/uuid.dart';

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
  ResidentCompiler(this.sdkRoot) {
    assert(sdkRoot != null);
  }

  Process server;
  String sdkRoot;

  Future<String> recompile(List<String> invalidatedFiles) async {
    if (server == null) {
      throw new Future<String>.error("Recompile should be preceded by compile");
    }

    outputFilename = new Completer<String>();

    final String inputKey = new Uuid().generateV4();
    server.stdin.writeln('recompile $inputKey');
    for (String invalidatedFile in invalidatedFiles) {
      server.stdin.writeln(invalidatedFile);
    }
    server.stdin.writeln(inputKey);

    return outputFilename.future;
  }

  Completer<String> outputFilename;
  String boundaryKey;

  Future<Null> handler(String string) async {
    const String RESULT_PREFIX = 'result ';
      if (boundaryKey == null) {
        if (string.startsWith(RESULT_PREFIX)) {
          boundaryKey = string.substring(RESULT_PREFIX.length);
        }
      } else {
        if (string.startsWith(boundaryKey)) {
          outputFilename.complete(string.substring(boundaryKey.length + 1));
          boundaryKey = null;
        } else {
          print(string);
        }
    }
  }

  Future<String> compile(String scriptFilename) async {
    if (server == null) {
      final String engineDartSdkPath = artifacts.getArtifactPath(
          Artifact.engineDartSdkPath);
      final String frontendServer = artifacts.getArtifactPath(
          Artifact.frontendServerSnapshotForEngineDartSdk);

      server = await Process.start('$engineDartSdkPath/bin/dart',
          <String>[frontendServer, '--sdk-root', sdkRoot + '/',
          '--incremental']);
    }
    outputFilename = new Completer<String>();
    server.stdout
        .transform(UTF8.decoder)
        .transform(new LineSplitter())
        .listen(handler);
    server.stderr
        .transform(UTF8.decoder)
        .transform(new LineSplitter())
        .listen((String s) { print("stderr:>$s"); });

    server.stdin.writeln('compile $scriptFilename');

    return outputFilename.future;
  }

  void accept() {
    server.stdin.writeln('accept');
  }
}