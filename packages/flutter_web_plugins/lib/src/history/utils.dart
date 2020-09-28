// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html';

AnchorElement _urlParsingNode;

/// Extracts the pathname part of a full [url].
///
/// Example: for the url `http://example.com/foo`, the extracted pathname will
/// be `/foo`.
String extractPathname(String url) {
  _urlParsingNode ??= AnchorElement();
  _urlParsingNode.href = url;
  final String pathname = _urlParsingNode.pathname;
  return (pathname.isEmpty || pathname[0] == '/') ? pathname : '/$pathname';
}

/// Checks that [baseHref] is set.
///
/// Throws an exception otherwise.
String checkBaseHref(String baseHref) {
  if (baseHref != null) {
    return baseHref;
  }
  throw Exception('Please add a <base> element to your index.html');
}

/// Prepends a slash to [path] if it doesn't start with a slash already.
///
/// If the path already starts with a slash, it'll be returned unchanged.
String ensureLeadingSlash(String path) {
  if (!path.startsWith('/')) {
    return '/$path';
  }
  return path;
}

/// Removes the trailing slash from [path] if any exists.
String stripTrailingSlash(String path) {
  if (path.endsWith('/')) {
    return path.substring(0, path.length - 1);
  }
  return path;
}