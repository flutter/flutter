// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import '../asset/id.dart';
import '../builder/builder.dart';

/// Collects the expected AssetIds created by [builder] when given [input] based
/// on the extension configuration.
Iterable<AssetId> expectedOutputs(Builder builder, AssetId input) {
  var matchingExtensions =
      builder.buildExtensions.keys.where((e) => input.path.endsWith(e));
  return matchingExtensions
      .expand((e) => _replaceExtensions(input, e, builder.buildExtensions[e]!));
}

Iterable<AssetId> _replaceExtensions(
        AssetId assetId, String oldExtension, List<String> newExtensions) =>
    newExtensions.map((n) => _replaceExtension(assetId, oldExtension, n));

AssetId _replaceExtension(
    AssetId assetId, String oldExtension, String newExtension) {
  var path = assetId.path;
  assert(path.endsWith(oldExtension));
  return AssetId(
      assetId.package,
      path.replaceRange(
          path.length - oldExtension.length, path.length, newExtension));
}
