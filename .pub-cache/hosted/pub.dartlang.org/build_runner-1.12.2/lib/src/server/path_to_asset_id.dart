// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:path/path.dart' as p;

AssetId pathToAssetId(
    String rootPackage, String rootDir, List<String> pathSegments) {
  var packagesIndex = pathSegments.indexOf('packages');
  rootDir ??= '';
  return packagesIndex >= 0
      ? AssetId(pathSegments[packagesIndex + 1],
          p.join('lib', p.joinAll(pathSegments.sublist(packagesIndex + 2))))
      : AssetId(rootPackage, p.joinAll([rootDir].followedBy(pathSegments)));
}

/// Returns null for paths that neither a lib nor starts from a rootDir
String assetIdToPath(AssetId assetId, String rootDir) =>
    assetId.path.startsWith('lib/')
        ? assetId.path.replaceFirst('lib/', 'packages/${assetId.package}/')
        : assetId.path.startsWith('$rootDir/')
            ? assetId.path.substring(rootDir.length + 1)
            : null;
