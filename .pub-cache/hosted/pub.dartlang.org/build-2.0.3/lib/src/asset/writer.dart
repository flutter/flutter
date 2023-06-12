// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:convert';

import 'id.dart';

/// Standard interface for writing an asset into a package's outputs.
abstract class AssetWriter {
  /// Writes [bytes] to a binary file located at [id].
  ///
  /// Returns a [Future] that completes after writing the asset out.
  ///
  /// * Throws a `PackageNotFoundException` if `id.package` is not found.
  /// * Throws an `InvalidOutputException` if the output was not valid.
  Future<void> writeAsBytes(AssetId id, List<int> bytes);

  /// Writes [contents] to a text file located at [id] with [encoding].
  ///
  /// Returns a [Future] that completes after writing the asset out.
  ///
  /// * Throws a `PackageNotFoundException` if `id.package` is not found.
  /// * Throws an `InvalidOutputException` if the output was not valid.
  Future<void> writeAsString(AssetId id, String contents,
      {Encoding encoding = utf8});
}

/// An [AssetWriter] which tracks all [assetsWritten] during its lifetime.
class AssetWriterSpy implements AssetWriter {
  final AssetWriter _delegate;
  final _assetsWritten = <AssetId>{};

  AssetWriterSpy(this._delegate);

  Iterable<AssetId> get assetsWritten => _assetsWritten;

  @override
  Future<void> writeAsBytes(AssetId id, List<int> bytes) {
    _assetsWritten.add(id);
    return _delegate.writeAsBytes(id, bytes);
  }

  @override
  Future<void> writeAsString(AssetId id, String contents,
      {Encoding encoding = utf8}) {
    _assetsWritten.add(id);
    return _delegate.writeAsString(id, contents, encoding: encoding);
  }
}
