// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html';

final AnchorElement _urlParsingNode = AnchorElement();

/// Extracts the pathname part of a full [url].
///
/// Example: for the url `http://example.com/foo`, the extracted pathname will
/// be `/foo`.
String extractPathname(String url) {
  _urlParsingNode.href = url;
  final String pathname = _urlParsingNode.pathname ?? '';
  return (pathname.isEmpty || pathname[0] == '/') ? pathname : '/$pathname';
}

// The <base> element in the document.
final Element? _baseElement = document.querySelector('base');

/// Returns the `href` attribute of the <base> element in the document.
///
/// Returns null if the element isn't found.
String? getBaseElementHrefFromDom() => _baseElement?.getAttribute('href');

/// Checks that [baseHref] is set.
///
/// Throws an exception otherwise.
String checkBaseHref(String? baseHref) {
  if (baseHref == null) {
    throw Exception('Please add a <base> element to your index.html');
  }
  if (!baseHref.endsWith('/')) {
    throw Exception('The base href has to end with a "/" to work correctly');
  }
  return baseHref;
}

/// Prepends a forward slash to [path] if it doesn't start with one already.
///
/// Returns [path] unchanged if it already starts with a forward slash.
String ensureLeadingSlash(String path) {
  if (!path.startsWith('/')) {
    return '/$path';
  }
  return path;
}

/// Removes the trailing forward slash from [path] if any.
String stripTrailingSlash(String path) {
  if (path.endsWith('/')) {
    return path.substring(0, path.length - 1);
  }
  return path;
}
