// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';

import 'id.dart';

/// Standard interface for reading an asset within in a package.
///
/// An [AssetReader] is required when calling the `runBuilder` method.
abstract class AssetReader {
  /// Returns a [Future] that completes with the bytes of a binary asset.
  ///
  /// * Throws a `PackageNotFoundException` if `id.package` is not found.
  /// * Throws a `AssetNotFoundException` if `id.path` is not found.
  /// * Throws an `InvalidInputException` if [id] is an invalid input.
  Future<List<int>> readAsBytes(AssetId id);

  /// Returns a [Future] that completes with the contents of a text asset.
  ///
  /// When decoding as text uses [encoding], or [utf8] is not specified.
  ///
  /// * Throws a `PackageNotFoundException` if `id.package` is not found.
  /// * Throws a `AssetNotFoundException` if `id.path` is not found.
  /// * Throws an `InvalidInputException` if [id] is an invalid input.
  Future<String> readAsString(AssetId id, {Encoding encoding = utf8});

  /// Indicates whether asset at [id] is readable.
  Future<bool> canRead(AssetId id);

  /// Returns all readable assets matching [glob] under the current package.
  Stream<AssetId> findAssets(Glob glob);

  /// Returns a [Digest] representing a hash of the contents of [id].
  ///
  /// The digests should include the asset ID as well as the content of the
  /// file, as some build systems may rely on the digests for two files being
  /// different, even if their content is the same.
  ///
  /// This should be treated as a transparent [Digest] and the implementation
  /// may differ based on the current build system being used.
  ///
  /// Similar to [readAsBytes], `digest` throws an exception if the asset can't
  /// be found or if it's an invalid input.
  Future<Digest> digest(AssetId id) async {
    var digestSink = AccumulatorSink<Digest>();
    md5.startChunkedConversion(digestSink)
      ..add(await readAsBytes(id))
      ..add(id.toString().codeUnits)
      ..close();
    return digestSink.events.first;
  }
}

/// The same as an `AssetReader`, except that `findAssets` takes an optional
/// argument `package` which allows you to glob any package.
///
/// This should not be exposed to end users generally, but can be used by
/// different build system implementations.
abstract class MultiPackageAssetReader extends AssetReader {
  /// Returns all readable assets matching [glob] under [package].
  ///
  /// Some implementations may require the [package] argument, while others
  /// may have a sane default.
  @override
  Stream<AssetId> findAssets(Glob glob, {String? package});
}
