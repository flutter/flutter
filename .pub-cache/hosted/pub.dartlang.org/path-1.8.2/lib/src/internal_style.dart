// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'context.dart';
import 'style.dart';

/// The internal interface for the [Style] type.
///
/// Users should be able to pass around instances of [Style] like an enum, but
/// the members that [Context] uses should be hidden from them. Those members
/// are defined on this class instead.
abstract class InternalStyle extends Style {
  /// The default path separator for this style.
  ///
  /// On POSIX, this is `/`. On Windows, it's `\`.
  @override
  String get separator;

  /// Returns whether [path] contains a separator.
  bool containsSeparator(String path);

  /// Returns whether [codeUnit] is the character code of a separator.
  bool isSeparator(int codeUnit);

  /// Returns whether this path component needs a separator after it.
  ///
  /// Windows and POSIX styles just need separators when the previous component
  /// doesn't already end in a separator, but the URL always needs to place a
  /// separator between the root and the first component, even if the root
  /// already ends in a separator character. For example, to join "file://" and
  /// "usr", an additional "/" is needed (making "file:///usr").
  bool needsSeparator(String path);

  /// Returns the number of characters of the root part.
  ///
  /// Returns 0 if the path is relative and 1 if the path is root-relative.
  ///
  /// If [withDrive] is `true`, this should include the drive letter for `file:`
  /// URLs. Non-URL styles may ignore the parameter.
  int rootLength(String path, {bool withDrive = false});

  /// Gets the root prefix of [path] if path is absolute. If [path] is relative,
  /// returns `null`.
  @override
  String? getRoot(String path) {
    final length = rootLength(path);
    if (length > 0) return path.substring(0, length);
    return isRootRelative(path) ? path[0] : null;
  }

  /// Returns whether [path] is root-relative.
  ///
  /// If [path] is relative or absolute and not root-relative, returns `false`.
  bool isRootRelative(String path);

  /// Returns the path represented by [uri] in this style.
  @override
  String pathFromUri(Uri uri);

  /// Returns the URI that represents a relative path.
  @override
  Uri relativePathToUri(String path) {
    if (path.isEmpty) return Uri();
    final segments = context.split(path);

    // Ensure that a trailing slash in the path produces a trailing slash in the
    // URL.
    if (isSeparator(path.codeUnitAt(path.length - 1))) segments.add('');
    return Uri(pathSegments: segments);
  }

  /// Returns the URI that represents [path], which is assumed to be absolute.
  @override
  Uri absolutePathToUri(String path);

  /// Returns whether [codeUnit1] and [codeUnit2] are considered equivalent for
  /// this style.
  bool codeUnitsEqual(int codeUnit1, int codeUnit2) => codeUnit1 == codeUnit2;

  /// Returns whether [path1] and [path2] are equivalent.
  ///
  /// This only needs to handle character-by-character comparison; it can assume
  /// the paths are normalized and contain no `..` components.
  bool pathsEqual(String path1, String path2) => path1 == path2;

  int canonicalizeCodeUnit(int codeUnit) => codeUnit;

  String canonicalizePart(String part) => part;
}
