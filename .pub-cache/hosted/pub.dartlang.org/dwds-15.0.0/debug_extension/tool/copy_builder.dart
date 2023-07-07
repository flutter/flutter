// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

/// Factory for the build script.
Builder copyBuilder(_) => _CopyBuilder();

/// Copies the [_backgroundJsId] file to [_backgroundJsCopyId].
class _CopyBuilder extends Builder {
  @override
  Map<String, List<String>> get buildExtensions => {
        _backgroundJsId.path: [_backgroundJsCopyId.path]
      };

  @override
  void build(BuildStep buildStep) {
    if (buildStep.inputId == _backgroundJsId) {
      buildStep.writeAsString(
          _backgroundJsCopyId, buildStep.readAsString(_backgroundJsId));
      return;
    } else {
      throw StateError(
          'Unexpected input for `CopyBuilder` expected only $_backgroundJsId');
    }
  }
}

final _backgroundJsId = AssetId('extension', 'web/background.dart.js');
final _backgroundJsCopyId = AssetId('extension', 'web/background.js');
