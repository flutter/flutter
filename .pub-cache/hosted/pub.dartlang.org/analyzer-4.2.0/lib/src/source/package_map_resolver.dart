// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/util/asserts.dart' as asserts;
import 'package:path/path.dart' as pathos;

/// A [UriResolver] implementation for the `package:` scheme that uses a map of
/// package names to their directories.
class PackageMapUriResolver extends UriResolver {
  /// The name of the `package` scheme.
  static const String PACKAGE_SCHEME = "package";

  /// A table mapping package names to the path of the directories containing
  /// the package.
  final Map<String, List<Folder>> packageMap;

  /// The [ResourceProvider] for this resolver.
  final ResourceProvider resourceProvider;

  /// Create a new [PackageMapUriResolver].
  ///
  /// [packageMap] is a table mapping package names to the paths of the
  /// directories containing the package
  PackageMapUriResolver(this.resourceProvider, this.packageMap) {
    asserts.notNull(resourceProvider);
    asserts.notNull(packageMap);
    packageMap.forEach((name, folders) {
      if (folders.length != 1) {
        throw ArgumentError(
            'Exactly one folder must be specified for a package.'
            'Found $name = $folders');
      }
    });
  }

  @override
  Uri? pathToUri(String path) {
    pathos.Context pathContext = resourceProvider.pathContext;
    for (String pkgName in packageMap.keys) {
      Folder pkgFolder = packageMap[pkgName]![0];
      String pkgFolderPath = pkgFolder.path;
      if (path.startsWith(pkgFolderPath + pathContext.separator)) {
        String relPath = path.substring(pkgFolderPath.length + 1);
        List<String> relPathComponents = pathContext.split(relPath);
        String relUriPath = pathos.posix.joinAll(relPathComponents);
        return Uri.parse('$PACKAGE_SCHEME:$pkgName/$relUriPath');
      }
    }
    return null;
  }

  @override
  Source? resolveAbsolute(Uri uri) {
    if (!isPackageUri(uri)) {
      return null;
    }

    var pathSegments = uri.pathSegments;
    if (pathSegments.length < 2) {
      return null;
    }

    // <pkgName>/<relPath>
    String pkgName = pathSegments[0];

    // If the package is known, return the corresponding file.
    var packageDirs = packageMap[pkgName];
    if (packageDirs != null) {
      Folder packageDir = packageDirs.single;
      String relPath = pathSegments.skip(1).join('/');
      File file = packageDir.getChildAssumingFile(relPath);
      return file.createSource(uri);
    }
    return null;
  }

  /// Returns `true` if [uri] is a `package` URI.
  static bool isPackageUri(Uri uri) {
    return uri.isScheme(PACKAGE_SCHEME);
  }
}
