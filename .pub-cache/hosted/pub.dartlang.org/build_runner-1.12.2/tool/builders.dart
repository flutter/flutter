// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

Builder copyCompiledJs(void _) => _CopyBuilder();

/// A Builder to copy compiled dart2js output to source.
class _CopyBuilder extends Builder {
  @override
  final buildExtensions = {
    'web/graph_viz_main.dart.js': ['lib/src/server/graph_viz_main.dart.js'],
  };

  @override
  void build(BuildStep buildStep) {
    if (!buildExtensions.containsKey(buildStep.inputId.path)) {
      throw StateError('Unexpected input for `CopyBuilder` '
          'expected only ${buildExtensions.keys}');
    }
    buildStep.writeAsString(
        AssetId(buildStep.inputId.package,
            buildExtensions[buildStep.inputId.path].single),
        buildStep.readAsString(buildStep.inputId));
  }
}
