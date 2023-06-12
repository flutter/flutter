// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A utility class used to convert between URIs and absolute file paths.
abstract class UriConverter {
  /// Return the URI that should be used to reference the file at the absolute
  /// [path], or `null` if there is no valid way to reference the file in this
  /// converter’s context. The file at that path is not required to exist.
  ///
  /// If a [containingPath] is provided and both the [path] and [containingPath]
  /// are within the root of this converter’s context, then the returned URI
  /// will be a relative path. Otherwise, the returned URI will be an absolute
  /// URI.
  ///
  /// Throws an `ArgumentError` if the [path] is `null` or is not a valid
  /// absolute file path.
  Uri? pathToUri(String path, {String? containingPath});

  /// Return the absolute path of the file to which the absolute [uri] resolves,
  /// or `null` if the [uri] cannot be resolved in this converter’s context.
  ///
  /// Throws an `ArgumentError` if the [uri] is `null` or is not an absolute
  /// URI.
  String? uriToPath(Uri uri);
}
