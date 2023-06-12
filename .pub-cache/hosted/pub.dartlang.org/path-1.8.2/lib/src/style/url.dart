// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../characters.dart' as chars;
import '../internal_style.dart';
import '../utils.dart';

/// The style for URL paths.
class UrlStyle extends InternalStyle {
  @override
  final name = 'url';
  @override
  final separator = '/';
  final separators = const ['/'];

  // Deprecated properties.

  @override
  final separatorPattern = RegExp(r'/');
  @override
  final needsSeparatorPattern = RegExp(r'(^[a-zA-Z][-+.a-zA-Z\d]*://|[^/])$');
  @override
  final rootPattern = RegExp(r'[a-zA-Z][-+.a-zA-Z\d]*://[^/]*');
  @override
  final relativeRootPattern = RegExp(r'^/');

  @override
  bool containsSeparator(String path) => path.contains('/');

  @override
  bool isSeparator(int codeUnit) => codeUnit == chars.slash;

  @override
  bool needsSeparator(String path) {
    if (path.isEmpty) return false;

    // A URL that doesn't end in "/" always needs a separator.
    if (!isSeparator(path.codeUnitAt(path.length - 1))) return true;

    // A URI that's just "scheme://" needs an extra separator, despite ending
    // with "/".
    return path.endsWith('://') && rootLength(path) == path.length;
  }

  @override
  int rootLength(String path, {bool withDrive = false}) {
    if (path.isEmpty) return 0;
    if (isSeparator(path.codeUnitAt(0))) return 1;

    for (var i = 0; i < path.length; i++) {
      final codeUnit = path.codeUnitAt(i);
      if (isSeparator(codeUnit)) return 0;
      if (codeUnit == chars.colon) {
        if (i == 0) return 0;

        // The root part is up until the next '/', or the full path. Skip ':'
        // (and '//' if it exists) and search for '/' after that.
        if (path.startsWith('//', i + 1)) i += 3;
        final index = path.indexOf('/', i);
        if (index <= 0) return path.length;

        // file: URLs sometimes consider Windows drive letters part of the root.
        // See https://url.spec.whatwg.org/#file-slash-state.
        if (!withDrive || path.length < index + 3) return index;
        if (!path.startsWith('file://')) return index;
        if (!isDriveLetter(path, index + 1)) return index;
        return path.length == index + 3 ? index + 3 : index + 4;
      }
    }

    return 0;
  }

  @override
  bool isRootRelative(String path) =>
      path.isNotEmpty && isSeparator(path.codeUnitAt(0));

  @override
  String? getRelativeRoot(String path) => isRootRelative(path) ? '/' : null;

  @override
  String pathFromUri(Uri uri) => uri.toString();

  @override
  Uri relativePathToUri(String path) => Uri.parse(path);
  @override
  Uri absolutePathToUri(String path) => Uri.parse(path);
}
