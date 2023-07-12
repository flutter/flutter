// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';
import 'package:package_config/package_config.dart';

import '../../asset.dart';

final String _assetManifest = (){
  final ByteBuffer buffer = globalAssetManifest.buffer;
  final Uint8List list = buffer.asUint8List(globalAssetManifest.offsetInBytes, globalAssetManifest.lengthInBytes);
  final String raw =  utf8.decode(list);
  return Uri.encodeFull(raw);
}();

/// Generates the main.dart file.
String generateMainDartFile(String appEntrypoint, {
  required String pluginRegistrantEntrypoint,
  LanguageVersion? languageVersion,
}) {
  return <String>[
    if (languageVersion != null)
      '// @dart=${languageVersion.major}.${languageVersion.minor}',
    '// Flutter web bootstrap script for $appEntrypoint.',
    '//',
    '// Generated file. Do not edit.',
    '//',
    '',
    '// ignore_for_file: type=lint',
    '',
    "import 'dart:ui_web' as ui_web;",
    "import 'dart:async';",
    "import 'package:flutter/services.dart';",
    '',
    "import '$appEntrypoint' as entrypoint;",
    "import '$pluginRegistrantEntrypoint' as pluginRegistrant;",
    '',
    'typedef _UnaryFunction = dynamic Function(List<String> args);',
    'typedef _NullaryFunction = dynamic Function();',
    '',
    'Future<void> main() async {',
    '  await ui_web.bootstrapEngine(',
    '    runApp: () {',
    '      print("hello this is andrew");',
    '      uriEncodedAssetManifestContent = r"$_assetManifest";',
    '      if (entrypoint.main is _UnaryFunction) {',
    '        return (entrypoint.main as _UnaryFunction)(<String>[]);',
    '      }',
    '      return (entrypoint.main as _NullaryFunction)();',
    '    },',
    '    registerPlugins: () {',
    '      pluginRegistrant.registerPlugins();',
    '    },',
    '  );',
    '}',
    '',
  ].join('\n');
}
