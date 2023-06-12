// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

class DuplicateAssetNodeException implements Exception {
  final String rootPackage;
  final AssetId assetId;
  final String initialBuilderLabel;
  final String newBuilderLabel;

  DuplicateAssetNodeException(this.rootPackage, this.assetId,
      this.initialBuilderLabel, this.newBuilderLabel);
  @override
  String toString() {
    final friendlyAsset =
        assetId.package == rootPackage ? assetId.path : assetId.uri;
    return 'Both $initialBuilderLabel and $newBuilderLabel may output '
        '$friendlyAsset. Potential outputs must be unique across all builders. '
        'See https://github.com/dart-lang/build/blob/master/docs/faq.md'
        '#why-do-builders-need-unique-outputs';
  }
}

class AssetGraphCorruptedException implements Exception {}
