// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:build/build.dart';
import 'package:crypto/src/digest.dart';

// This is not exported to hack around a package-private constructor.
PostProcessBuildStep postProcessBuildStep(
        AssetId inputId,
        AssetReader reader,
        AssetWriter writer,
        void Function(AssetId) addAsset,
        void Function(AssetId) deleteAsset) =>
    PostProcessBuildStep._(inputId, reader, writer, addAsset, deleteAsset);

/// A simplified [BuildStep] which can only read its primary input, and can't
/// get a [Resolver] or any [Resource]s, at least for now.
class PostProcessBuildStep {
  final AssetId inputId;

  final AssetReader _reader;
  final AssetWriter _writer;
  final void Function(AssetId) _addAsset;
  final void Function(AssetId) _deleteAsset;

  /// The result of any writes which are starting during this step.
  final _writeResults = <Future<Result<void>>>[];

  PostProcessBuildStep._(this.inputId, this._reader, this._writer,
      this._addAsset, this._deleteAsset);

  Future<Digest> digest(AssetId id) => inputId == id
      ? _reader.digest(id)
      : Future.error(InvalidInputException(id));

  Future<List<int>> readInputAsBytes() => _reader.readAsBytes(inputId);

  Future<String> readInputAsString({Encoding encoding = utf8}) =>
      _reader.readAsString(inputId, encoding: encoding);

  Future<void> writeAsBytes(AssetId id, FutureOr<List<int>> bytes) {
    _addAsset(id);
    var done =
        _futureOrWrite(bytes, (List<int> b) => _writer.writeAsBytes(id, b));
    _writeResults.add(Result.capture(done));
    return done;
  }

  Future<void> writeAsString(AssetId id, FutureOr<String> content,
      {Encoding encoding = utf8}) {
    _addAsset(id);
    var done = _futureOrWrite(content,
        (String c) => _writer.writeAsString(id, c, encoding: encoding));
    _writeResults.add(Result.capture(done));
    return done;
  }

  /// Marks an asset for deletion in the post process step.
  void deletePrimaryInput() {
    _deleteAsset(inputId);
  }

  /// Waits for work to finish and cleans up resources.
  ///
  /// This method should be called after a build has completed. After the
  /// returned [Future] completes then all outputs have been written.
  Future<void> complete() async {
    await Future.wait(_writeResults.map(Result.release));
  }
}

Future<void> _futureOrWrite<T>(
        FutureOr<T> content, Future<void> Function(T content) write) =>
    (content is Future<T>) ? content.then(write) : write(content);
