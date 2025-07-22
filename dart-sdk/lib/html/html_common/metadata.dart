// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library metadata;

/**
 * An annotation used to mark a feature as only being supported by a subset
 * of the browsers that Dart supports by default.
 *
 * If an API is not annotated with [SupportedBrowser] then it is assumed to
 * work on all browsers Dart supports.
 */
class SupportedBrowser {
  static const String CHROME = "Chrome";
  static const String FIREFOX = "Firefox";
  static const String IE = "Internet Explorer";
  static const String OPERA = "Opera";
  static const String SAFARI = "Safari";

  /// The name of the browser.
  final String browserName;

  /// The minimum version of the browser that supports the feature, or null
  /// if supported on all versions.
  final String? minimumVersion;

  const SupportedBrowser(this.browserName, [this.minimumVersion]);
}

/**
 * An annotation used to mark an API as being experimental.
 *
 * An API is considered to be experimental if it is still going through the
 * process of stabilizing and is subject to change or removal.
 *
 * See also:
 *
 * * [W3C recommendation](http://en.wikipedia.org/wiki/W3C_recommendation)
 */
class Experimental {
  const Experimental();
}

/**
 * Annotation that specifies that a member is editable through generate files.
 *
 * This is used for API generation.
 *
 * [name] should be formatted as `interface.member`.
 */
class DomName {
  final String name;
  const DomName(this.name);
}

/**
 * Metadata that specifies that the member is editable through generated files.
 */
class DocsEditable {
  const DocsEditable();
}

/**
 * Annotation that indicates that an API is not expected to change but has
 * not undergone enough testing to be considered stable.
 */
class Unstable {
  const Unstable();
}
