// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

import 'base/config.dart';
import 'base/file_system.dart';
import 'build_info.dart';
import 'convert.dart';
import 'globals.dart' as globals;

String get defaultMainPath => globals.fs.path.join('lib', 'main.dart');
const defaultManifestPath = 'pubspec.yaml';
String get defaultDepfilePath => globals.fs.path.join(getBuildDirectory(), 'snapshot_blob.bin.d');

String getDefaultApplicationKernelPath({required bool trackWidgetCreation}) {
  return getKernelPathForTransformerOptions(
    globals.fs.path.join(getBuildDirectory(), 'app.dill'),
    trackWidgetCreation: trackWidgetCreation,
  );
}

String getDefaultCachedKernelPath({
  required bool trackWidgetCreation,
  required List<String> dartDefines,
  required Config config,
  required FileSystem fileSystem,
  List<String> extraFrontEndOptions = const <String>[],
}) {
  final buffer = StringBuffer();
  final List<String> cacheFrontEndOptions = extraFrontEndOptions.toList()
    ..removeWhere((String arg) => arg.startsWith('--enable-experiment='));
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
