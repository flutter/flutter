// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

/// Factory for the build script.
Builder copyBuilder(_) => _CopyBuilder();

/// Copies the [_clientJsId] file to [_clientJsCopyId].
class _CopyBuilder extends Builder {
  @override
  Map<String, List<String>> get buildExtensions => {
        _clientJsId.path: [_clientJsCopyId.path]
      };

  @override
  void build(BuildStep buildStep) {
    if (buildStep.inputId != _clientJsId) {
      throw StateError(
          'Unexpected input for `CopyBuilder` expected only $_clientJsId');
    }
    buildStep.writeAsString(
        _clientJsCopyId, buildStep.readAsString(_clientJsId));
  }
}

final _clientJsId = AssetId('dwds', 'web/client.dart.js');
final _clientJsCopyId = AssetId('dwds', 'lib/src/injected/client.js');
