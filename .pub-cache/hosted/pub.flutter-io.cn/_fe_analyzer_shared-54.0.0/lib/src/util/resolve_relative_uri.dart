// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Resolve the [containedUri] against [baseUri] using Dart rules.
 *
 * This function behaves similarly to [Uri.resolveUri], except that it properly
 * handles situations like the following:
 *
 *     resolveRelativeUri(dart:core, bool.dart) -> dart:core/bool.dart
 *     resolveRelativeUri(package:a/b.dart, ../c.dart) -> package:a/c.dart
 */
Uri resolveRelativeUri(Uri baseUri, Uri containedUri) {
  if (containedUri.isAbsolute) {
    return containedUri;
  }
  String scheme = baseUri.scheme;
  // dart:core => dart:core/core.dart
  if (scheme == 'dart') {
    String part = baseUri.path;
    if (part.indexOf('/') < 0) {
      baseUri = Uri.parse('$scheme:$part/$part.dart');
    }
  }
  return baseUri.resolveUri(containedUri);
}
