// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';

import '../analyzer/resolver.dart';
import '../asset/id.dart';
import '../asset/reader.dart';
import '../asset/writer.dart';
import '../resource/resource.dart';

/// A single step in a build process.
///
/// This represents a single [inputId], logic around resolving as a library,
/// and the ability to read and write assets as allowed by the underlying build
/// system.
abstract class BuildStep implements AssetReader, AssetWriter {
  /// The primary for this build step.
  AssetId get inputId;

  /// Resolved library defined by [inputId].
  ///
  /// Throws [NonLibraryAssetException] if [inputId] is not a Dart library file.
  /// Throws [SyntaxErrorInAssetException] if [inputId] contains syntax errors.
  /// If you want to support libraries with syntax errors, resolve the library
  /// manually instead of using [inputLibrary]:
  /// ```dart
  /// Future<void> build(BuildStep step) async {
  ///   // Resolve the input library, allowing syntax errors
  ///   final inputLibrary =
  ///     await step.resolver.libraryFor(step.inputId, allowSyntaxErrors: true);
  /// }
  /// ```
  Future<LibraryElement> get inputLibrary;

  /// Gets an instance provided by [resource] which is guaranteed to be unique
  /// within a single build, and may be reused across build steps within a
  /// build if the implementation allows.
  ///
  /// It is also guaranteed that [resource] will be disposed before the next
  /// build starts (and the dispose callback will be invoked if provided).
  Future<T> fetchResource<T>(Resource<T> resource);

  /// Writes [bytes] to a binary file located at [id].
  ///
  /// Returns a [Future] that completes after writing the asset out.
  ///
  /// * Throws a `PackageNotFoundException` if `id.package` is not found.
  /// * Throws an `InvalidOutputException` if the output was not valid.
  ///
  /// **NOTE**: Most `Builder` implementations should not need to `await` this
  /// Future since the runner will be responsible for waiting until all outputs
  /// are written.
  @override
  Future<void> writeAsBytes(AssetId id, FutureOr<List<int>> bytes);

  /// Writes [contents] to a text file located at [id] with [encoding].
  ///
  /// Returns a [Future] that completes after writing the asset out.
  ///
  /// * Throws a `PackageNotFoundException` if `id.package` is not found.
  /// * Throws an `InvalidOutputException` if the output was not valid.
  ///
  /// **NOTE**: Most `Builder` implementations should not need to `await` this
  /// Future since the runner will be responsible for waiting until all outputs
  /// are written.
  @override
  Future<void> writeAsString(AssetId id, FutureOr<String> contents,
      {Encoding encoding = utf8});

  /// A [Resolver] for [inputId].
  Resolver get resolver;

  /// Tracks performance of [action] separately.
  ///
  /// If performance tracking is enabled, tracks [action] as separate stage
  /// identified by [label]. Otherwise just runs [action].
  ///
  /// You can specify [action] as [isExternal] (waiting for some external
  /// resource like network, process or file IO). In that case [action] will
  /// be tracked as single time slice from the beginning of the stage till
  /// completion of Future returned by [action].
  ///
  /// Otherwise all separate time slices of asynchronous execution will be
  /// tracked, but waiting for external resources will be a gap.
  ///
  /// Returns value returned by [action].
  /// [action] can be async function returning [Future].
  T trackStage<T>(String label, T Function() action, {bool isExternal = false});

  /// Indicates that [ids] were read but their content has no impact on the
  /// outputs of this step.
  ///
  /// **WARNING**: Using this introduces serious risk of non-hermetic builds.
  ///
  /// If these files change or become unreadable on the next build this build
  /// step may not run.
  ///
  /// **Note**: This is not guaranteed to have any effect and it should be
  /// assumed to be a no-op by default. Implementations must explicitly
  /// choose to support this feature.
  void reportUnusedAssets(Iterable<AssetId> ids);
}

abstract class StageTracker {
  T trackStage<T>(String label, T Function() action, {bool isExternal = false});
}

class NoOpStageTracker implements StageTracker {
  static const StageTracker instance = NoOpStageTracker._();

  @override
  T trackStage<T>(String label, T Function() action,
          {bool isExternal = false}) =>
      action();

  const NoOpStageTracker._();
}
