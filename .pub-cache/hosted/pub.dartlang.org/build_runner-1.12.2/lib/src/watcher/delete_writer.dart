// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_runner_core/build_runner_core.dart';

/// A [RunnerAssetWriter] that forwards delete events to [_onDelete];
class OnDeleteWriter implements RunnerAssetWriter {
  final RunnerAssetWriter _writer;
  final void Function(AssetId id) _onDelete;

  OnDeleteWriter(this._writer, this._onDelete);

  @override
  Future delete(AssetId id) {
    _onDelete(id);
    return _writer.delete(id);
  }

  @override
  Future writeAsBytes(AssetId id, List<int> bytes) =>
      _writer.writeAsBytes(id, bytes);

  @override
  Future writeAsString(AssetId id, String contents,
          {Encoding encoding = utf8}) =>
      _writer.writeAsString(id, contents, encoding: encoding);
}
