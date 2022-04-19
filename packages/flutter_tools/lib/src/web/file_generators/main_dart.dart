// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:package_config/package_config.dart';

/// Generates the main.dart file.
String generateMainDartFile(String appEntrypoint, {
  LanguageVersion? languageVersion,
  String? pluginRegistrantEntrypoint,
}) {
  final bool hasWebPlugins = pluginRegistrantEntrypoint != null;

  return <String>[
    if (languageVersion != null)
      '// @dart=${languageVersion.major}.${languageVersion.minor}',
    '// Flutter web bootstrap script for $appEntrypoint.',
    '',
    "import 'dart:ui' as ui;",
    "import 'dart:async';",
    '',
    "import '$appEntrypoint' as entrypoint;",
    if (hasWebPlugins) ...<String>[
      "import 'package:flutter_web_plugins/flutter_web_plugins.dart';",
      "import '$pluginRegistrantEntrypoint';",
    ],
    '',
    'typedef _UnaryFunction = dynamic Function(List<String> args);',
    'typedef _NullaryFunction = dynamic Function();',
    '',
    'Future<void> main() async {',
    '  await ui.webOnlyWarmupEngine(',
    '    runApp: () {',
    '      if (entrypoint.main is _UnaryFunction) {',
    '        return (entrypoint.main as _UnaryFunction)(<String>[]);',
    '      }',
    '      return (entrypoint.main as _NullaryFunction)();',
    '    },',
    if (hasWebPlugins) ...<String>[
    '    registerPlugins: () {',
    '      registerPlugins(webPluginRegistrar);',
    '    },',
    ],
    '  );',
    '}',
    '',
  ].join('\n');
}
