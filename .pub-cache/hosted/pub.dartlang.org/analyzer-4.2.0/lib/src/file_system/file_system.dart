// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/util/uri.dart';

/// A [UriResolver] for [Resource]s.
class ResourceUriResolver extends UriResolver {
  /// The name of the `file` scheme.
  static final String FILE_SCHEME = "file";

  final ResourceProvider _provider;

  ResourceUriResolver(this._provider);

  ResourceProvider get provider => _provider;

  @override
  Uri pathToUri(String path) {
    return _provider.pathContext.toUri(path);
  }

  @override
  Source? resolveAbsolute(Uri uri) {
    if (!isFileUri(uri)) {
      return null;
    }
    String path = fileUriToNormalizedPath(_provider.pathContext, uri);
    File file = _provider.getFile(path);
    return file.createSource(uri);
  }

  /// Return `true` if the given [uri] is a `file` URI.
  static bool isFileUri(Uri uri) => uri.isScheme(FILE_SCHEME);
}
