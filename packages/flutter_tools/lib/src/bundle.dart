// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

import 'base/config.dart';
import 'base/file_system.dart';
import 'build_info.dart';
import 'compile.dart';
import 'convert.dart';
import 'globals.dart' as globals;

FileSystem get _fs {
  try {
    return globals.fs;
  } on UnsupportedError {
    return globals.localFileSystem;
  }
}

String get defaultMainPath => _fs.path.join('lib', 'main.dart');

const defaultManifestPath = 'pubspec.yaml';
String get defaultDepfilePath => _fs.path.join(getBuildDirectory(), 'snapshot_blob.bin.d');

String getDefaultApplicationKernelPath({required bool trackWidgetCreation}) {
  final String appDillPath = _fs.path.join(getBuildDirectory(), 'app.dill');
  return getKernelPathForTransformerOptions(appDillPath, trackWidgetCreation: trackWidgetCreation);
}

String getDefaultCachedKernelPath({
  required Config config,
  required List<String> dartDefines,
  required FileSystem fileSystem,
  required bool trackWidgetCreation,
  List<String> extraFrontEndOptions = const <String>[],
  TargetModel? targetModel,
}) {
  final buffer = StringBuffer();
  final List<String> cacheFrontEndOptions = extraFrontEndOptions.toList()
    ..removeWhere((String arg) => arg.startsWith('--enable-experiment='));
  if (targetModel != null) {
    buffer.write('$targetModel;');
  }
  buffer.writeAll(dartDefines);
  buffer.writeAll(cacheFrontEndOptions);
  var buildPrefix = '';
  if (buffer.isNotEmpty) {
    final output = buffer.toString();
    final Digest digest = md5.convert(utf8.encode(output));
    buildPrefix = '${hex.encode(digest.bytes)}.';
  }
  return getKernelPathForTransformerOptions(
    fileSystem.path.join(getBuildDirectory(config, fileSystem), '${buildPrefix}cache.dill'),
    trackWidgetCreation: trackWidgetCreation,
  );
}

String getKernelPathForTransformerOptions(String path, {required bool trackWidgetCreation}) {
  if (trackWidgetCreation) {
    path += '.track.dill';
  }
  return path;
}
