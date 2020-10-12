// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:html';

AnchorElement _urlParsingNode;

/// Extracts the pathname part of a full [url].
///
/// Example: for the url `http://example.com/foo`, the extracted pathname will
/// be `/foo`.
String extractPathname(String url) {
  // TODO(mdebbar): Use the `URI` class instead?
  _urlParsingNode ??= AnchorElement();
  _urlParsingNode.href = url;
  final String pathname = _urlParsingNode.pathname;
  return (pathname.isEmpty || pathname[0] == '/') ? pathname : '/$pathname';
}

Element _baseElement;

/// Finds the <base> element in the document and returns its `href` attribute.
///
/// Returns null if the element isn't found.
String getBaseElementHrefFromDom() {
  if (_baseElement == null) {
    _baseElement = document.querySelector('base');
    if (_baseElement == null) {
      return null;
    }
  }
  return _baseElement.getAttribute('href');
}

/// Checks that [baseHref] is set.
///
/// Throws an exception otherwise.
String checkBaseHref(String baseHref) {
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
