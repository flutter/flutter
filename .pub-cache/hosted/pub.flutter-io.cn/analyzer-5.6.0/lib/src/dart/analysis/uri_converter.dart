// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/uri_converter.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:path/path.dart';

/// An implementation of a URI converter based on an analysis driver.
class DriverBasedUriConverter implements UriConverter {
  /// The driver associated with the context in which the conversion will occur.
  final AnalysisDriver driver;

  /// Initialize a newly created URI converter to use the given [driver] to =
  /// perform the conversions.
  DriverBasedUriConverter(this.driver);

  @override
  Uri? pathToUri(String path, {String? containingPath}) {
    ResourceProvider provider = driver.resourceProvider;
    if (containingPath != null) {
      Context context = provider.pathContext;
      String root = driver.analysisContext!.contextRoot.root.path;
      if (context.isWithin(root, path) &&
          context.isWithin(root, containingPath)) {
        String relativePath =
            context.relative(path, from: context.dirname(containingPath));
        if (context.isRelative(relativePath)) {
          return Uri.file(relativePath);
        }
      }
    }
    return driver.sourceFactory.pathToUri(path);
  }

  @override
  String? uriToPath(Uri uri) => driver.sourceFactory.forUri2(uri)?.fullName;
}
