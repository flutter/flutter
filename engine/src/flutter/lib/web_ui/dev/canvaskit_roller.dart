// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show json;
import 'dart:io';

import 'package:path/path.dart' as pathlib;
import 'package:yaml/yaml.dart';

import 'environment.dart';
import 'utils.dart';

/// Rolls CanvasKit to the version specified in `dev/canvaskit_lock.yaml`.
///
/// Detailed instructions for how to use this script can be found in
/// `lib/web_ui/README.md`.
Future<void> main(List<String> args) async {
  final String canvaskitVersion = _readCanvaskitVersion();
  print('Rolling CanvasKit to version $canvaskitVersion');

  final Directory canvaskitDirectory = await Directory.systemTemp.createTemp('canvaskit-roll-$canvaskitVersion-');
  print('Will use ${canvaskitDirectory.path} as staging directory.');

  final String baseUrl = 'https://unpkg.com/canvaskit-wasm@$canvaskitVersion/bin/';
  print('Downloading CanvasKit from $baseUrl');
  final HttpClient client = HttpClient();
  for (final String assetPath in _canvaskitAssets) {
    final String assetUrl = '$baseUrl/$assetPath';
    final File assetFile = File(pathlib.joinAll(<String>[
      canvaskitDirectory.path,
      'canvaskit',
      ...assetPath.split('/'), // so it's compatible with Windows
    ]));
    await assetFile.parent.create(recursive: true);
    final HttpClientRequest request = await client.getUrl(Uri.parse(assetUrl));
    final HttpClientResponse response = await request.close();
    final IOSink fileSink = assetFile.openWrite();
    await response.pipe(fileSink);
  }
  client.close();

  final File cipdConfigFile = File(pathlib.join(
    canvaskitDirectory.path,
    'cipd.yaml',
  ));
  await cipdConfigFile.writeAsString('''
package: flutter/web/canvaskit_bundle
description: A build of CanvasKit bundled with Flutter Web apps
preserve_writable: true
data:
  - dir: canvaskit
''');

  print('Uploading to CIPD');
  await runProcess('cipd', <String>[
    'create',
    '--tag=version:$canvaskitVersion',
    '--pkg-def=cipd.yaml',
    '--json-output=result.json',
  ], workingDirectory: canvaskitDirectory.path);

  final Map<String, dynamic> cipdResult = json.decode(File(pathlib.join(
    canvaskitDirectory.path,
    'result.json',
  )).readAsStringSync()) as Map<String, dynamic>;
  final String cipdInstanceId = cipdResult['result']['instance_id'] as String;

  print('CIPD instance information:');
  final String cipdInfo = await evalProcess('cipd', <String>[
    'describe',
    'flutter/web/canvaskit_bundle',
    '--version=$cipdInstanceId',
  ], workingDirectory: canvaskitDirectory.path);
  print(cipdInfo.trim().split('\n').map((String line) => ' • $line').join('\n'));

  print('Updating DEPS file');
  await _updateDepsFile(cipdInstanceId);
  await _updateCanvaskitInitializationCode(canvaskitVersion);

  print('\nATTENTION: the roll process is not complete yet.');
  print('Last step: for the roll to take effect submit an engine pull request from local git changes.');
}

const List<String> _canvaskitAssets = <String>[
  'canvaskit.js',
  'canvaskit.wasm',
  'profiling/canvaskit.js',
  'profiling/canvaskit.wasm',
];

String _readCanvaskitVersion() {
  final YamlMap canvaskitLock = loadYaml(File(pathlib.join(
    environment.webUiDevDir.path,
    'canvaskit_lock.yaml',
  )).readAsStringSync()) as YamlMap;
  return canvaskitLock['canvaskit_version'] as String;
}

Future<void> _updateDepsFile(String cipdInstanceId) async {
  final File depsFile = File(pathlib.join(
    environment.flutterDirectory.path,
    'DEPS',
  ));

  final String originalDepsCode = await depsFile.readAsString();
  final List<String> rewrittenDepsCode = <String>[];
  const String kCanvasKitDependencyKeyInDeps = '\'canvaskit_cipd_instance\': \'';
  bool canvaskitDependencyFound = false;
  for (final String line in originalDepsCode.split('\n')) {
    if (line.trim().startsWith(kCanvasKitDependencyKeyInDeps)) {
      canvaskitDependencyFound = true;
      rewrittenDepsCode.add(
        "  'canvaskit_cipd_instance': '$cipdInstanceId',",
      );
    } else {
      rewrittenDepsCode.add(line);
    }
  }

  if (!canvaskitDependencyFound) {
    stderr.writeln(
      'Failed to update the DEPS file.\n'
      'Could not to locate CanvasKit dependency in the DEPS file. Make sure the '
      'DEPS file contains a line like this:\n'
      '\n'
      '  \'canvaskit_cipd_instance\': \'SOME_VALUE\','
    );
    exit(1);
  }

  await depsFile.writeAsString(rewrittenDepsCode.join('\n'));
}

Future<void> _updateCanvaskitInitializationCode(String canvaskitVersion) async {
  const String kCanvasKitVersionKey = 'const String _canvaskitVersion';
  const String kPathToConfigurationCode = 'lib/src/engine/configuration.dart';
  final File initializationFile = File(pathlib.join(
    environment.webUiRootDir.path,
    kPathToConfigurationCode,
  ));
  final String originalInitializationCode = await initializationFile.readAsString();

  final List<String> rewrittenCode = <String>[];
  bool canvaskitVersionFound = false;
  for (final String line in originalInitializationCode.split('\n')) {
    if (line.trim().startsWith(kCanvasKitVersionKey)) {
      canvaskitVersionFound = true;
      rewrittenCode.add(
        "const String _canvaskitVersion = '$canvaskitVersion';",
      );
    } else {
      rewrittenCode.add(line);
    }
  }

  if (!canvaskitVersionFound) {
    stderr.writeln(
      'Failed to update CanvasKit version in $kPathToConfigurationCode.\n'
      'Could not to locate the constant that defines the version. Make sure the '
      '$kPathToConfigurationCode file contains a line like this:\n'
      '\n'
      'const String _canvaskitVersion = \'VERSION\';'
    );
    exit(1);
  }

  await initializationFile.writeAsString(rewrittenCode.join('\n'));
}
