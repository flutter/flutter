// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../characters.dart' as chars;
import '../internal_style.dart';
import '../parsed_path.dart';

/// The style for POSIX paths.
class PosixStyle extends InternalStyle {
  @override
  final name = 'posix';
  @override
  final separator = '/';
  final separators = const ['/'];

  // Deprecated properties.

  @override
  final separatorPattern = RegExp(r'/');
  @override
  final needsSeparatorPattern = RegExp(r'[^/]$');
  @override
  final rootPattern = RegExp(r'^/');
  @override
  final relativeRootPattern = null;

  @override
  bool containsSeparator(String path) => path.contains('/');

  @override
  bool isSeparator(int codeUnit) => codeUnit == chars.slash;

  @override
  bool needsSeparator(String path) =>
      path.isNotEmpty && !isSeparator(path.codeUnitAt(path.length - 1));

  @override
  int rootLength(String path, {bool withDrive = false}) {
    if (path.isNotEmpty && isSeparator(path.codeUnitAt(0))) return 1;
    return 0;
  }

  @override
  bool isRootRelative(String path) => false;

  @override
  String? getRelativeRoot(String path) => null;

  @override
  String pathFromUri(Uri uri) {
    if (uri.scheme == '' || uri.scheme == 'file') {
      return Uri.decodeComponent(uri.path);
    }
    throw ArgumentError("Uri $uri must have scheme 'file:'.");
  }

  @override
  Uri absolutePathToUri(String path) {
    final parsed = ParsedPath.parse(path, this);
    if (parsed.parts.isEmpty) {
      // If the path is a bare root (e.g. "/"), [components] will
      // currently be empty. We add two empty components so the URL constructor
      // produces "file:///", with a trailing slash.
      parsed.parts.addAll(['', '']);
    } else if (parsed.hasTrailingSeparator) {
      // If the path has a trailing slash, add a single empty component so the
      // URI has a trailing slash as well.
      parsed.parts.add('');
    }

    return Uri(scheme: 'file', pathSegments: parsed.parts);
  }
}
