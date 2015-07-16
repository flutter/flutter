// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library path.style;

import 'context.dart';
import 'style/posix.dart';
import 'style/url.dart';
import 'style/windows.dart';

/// An enum type describing a "flavor" of path.
abstract class Style {
  /// POSIX-style paths use "/" (forward slash) as separators. Absolute paths
  /// start with "/". Used by UNIX, Linux, Mac OS X, and others.
  static final posix = new PosixStyle();

  /// Windows paths use "\" (backslash) as separators. Absolute paths start with
  /// a drive letter followed by a colon (example, "C:") or two backslashes
  /// ("\\") for UNC paths.
  // TODO(rnystrom): The UNC root prefix should include the drive name too, not
  // just the "\\".
  static final windows = new WindowsStyle();

  /// URLs aren't filesystem paths, but they're supported to make it easier to
  /// manipulate URL paths in the browser.
  ///
  /// URLs use "/" (forward slash) as separators. Absolute paths either start
  /// with a protocol and optional hostname (e.g. `http://dartlang.org`,
  /// `file://`) or with "/".
  static final url = new UrlStyle();

  /// The style of the host platform.
  ///
  /// When running on the command line, this will be [windows] or [posix] based
  /// on the host operating system. On a browser, this will be [url].
  static final platform = _getPlatformStyle();

  /// Gets the type of the host platform.
  static Style _getPlatformStyle() {
    // If we're running a Dart file in the browser from a `file:` URI,
    // [Uri.base] will point to a file. If we're running on the standalone,
    // it will point to a directory. We can use that fact to determine which
    // style to use.
    if (Uri.base.scheme != 'file') return Style.url;
    if (!Uri.base.path.endsWith('/')) return Style.url;
    if (new Uri(path: 'a/b').toFilePath() == 'a\\b') return Style.windows;
    return Style.posix;
  }

  /// The name of this path style. Will be "posix" or "windows".
  String get name;

  /// A [Context] that uses this style.
  Context get context => new Context(style: this);

  @Deprecated("Most Style members will be removed in path 2.0.")
  String get separator;

  @Deprecated("Most Style members will be removed in path 2.0.")
  Pattern get separatorPattern;

  @Deprecated("Most Style members will be removed in path 2.0.")
  Pattern get needsSeparatorPattern;

  @Deprecated("Most Style members will be removed in path 2.0.")
  Pattern get rootPattern;

  @Deprecated("Most Style members will be removed in path 2.0.")
  Pattern get relativeRootPattern;

  @Deprecated("Most style members will be removed in path 2.0.")
  String getRoot(String path);

  @Deprecated("Most style members will be removed in path 2.0.")
  String getRelativeRoot(String path);

  @Deprecated("Most style members will be removed in path 2.0.")
  String pathFromUri(Uri uri);

  @Deprecated("Most style members will be removed in path 2.0.")
  Uri relativePathToUri(String path);

  @Deprecated("Most style members will be removed in path 2.0.")
  Uri absolutePathToUri(String path);

  String toString() => name;
}
