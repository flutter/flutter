// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library path.parsed_path;

import 'internal_style.dart';
import 'style.dart';

class ParsedPath {
  /// The [InternalStyle] that was used to parse this path.
  InternalStyle style;

  /// The absolute root portion of the path, or `null` if the path is relative.
  /// On POSIX systems, this will be `null` or "/". On Windows, it can be
  /// `null`, "//" for a UNC path, or something like "C:\" for paths with drive
  /// letters.
  String root;

  /// Whether this path is root-relative.
  ///
  /// See [Context.isRootRelative].
  bool isRootRelative;

  /// The path-separated parts of the path. All but the last will be
  /// directories.
  List<String> parts;

  /// The path separators preceding each part.
  ///
  /// The first one will be an empty string unless the root requires a separator
  /// between it and the path. The last one will be an empty string unless the
  /// path ends with a trailing separator.
  List<String> separators;

  /// The file extension of the last non-empty part, or "" if it doesn't have
  /// one.
  String get extension => _splitExtension()[1];

  /// `true` if this is an absolute path.
  bool get isAbsolute => root != null;

  factory ParsedPath.parse(String path, InternalStyle style) {
    // Remove the root prefix, if any.
    var root = style.getRoot(path);
    var isRootRelative = style.isRootRelative(path);
    if (root != null) path = path.substring(root.length);

    // Split the parts on path separators.
    var parts = [];
    var separators = [];

    var start = 0;

    if (path.isNotEmpty && style.isSeparator(path.codeUnitAt(0))) {
      separators.add(path[0]);
      start = 1;
    } else {
      separators.add('');
    }

    for (var i = start; i < path.length; i++) {
      if (style.isSeparator(path.codeUnitAt(i))) {
        parts.add(path.substring(start, i));
        separators.add(path[i]);
        start = i + 1;
      }
    }

    // Add the final part, if any.
    if (start < path.length) {
      parts.add(path.substring(start));
      separators.add('');
    }

    return new ParsedPath._(style, root, isRootRelative, parts, separators);
  }

  ParsedPath._(
      this.style, this.root, this.isRootRelative, this.parts, this.separators);

  String get basename {
    var copy = this.clone();
    copy.removeTrailingSeparators();
    if (copy.parts.isEmpty) return root == null ? '' : root;
    return copy.parts.last;
  }

  String get basenameWithoutExtension => _splitExtension()[0];

  bool get hasTrailingSeparator =>
      !parts.isEmpty && (parts.last == '' || separators.last != '');

  void removeTrailingSeparators() {
    while (!parts.isEmpty && parts.last == '') {
      parts.removeLast();
      separators.removeLast();
    }
    if (separators.length > 0) separators[separators.length - 1] = '';
  }

  void normalize() {
    // Handle '.', '..', and empty parts.
    var leadingDoubles = 0;
    var newParts = [];
    for (var part in parts) {
      if (part == '.' || part == '') {
        // Do nothing. Ignore it.
      } else if (part == '..') {
        // Pop the last part off.
        if (newParts.length > 0) {
          newParts.removeLast();
        } else {
          // Backed out past the beginning, so preserve the "..".
          leadingDoubles++;
        }
      } else {
        newParts.add(part);
      }
    }

    // A relative path can back out from the start directory.
    if (!isAbsolute) {
      newParts.insertAll(0, new List.filled(leadingDoubles, '..'));
    }

    // If we collapsed down to nothing, do ".".
    if (newParts.length == 0 && !isAbsolute) {
      newParts.add('.');
    }

    // Canonicalize separators.
    var newSeparators = new List.generate(
        newParts.length, (_) => style.separator, growable: true);
    newSeparators.insert(0, isAbsolute &&
        newParts.length > 0 &&
        style.needsSeparator(root) ? style.separator : '');

    parts = newParts;
    separators = newSeparators;

    // Normalize the Windows root if needed.
    if (root != null && style == Style.windows) {
      root = root.replaceAll('/', '\\');
    }
    removeTrailingSeparators();
  }

  String toString() {
    var builder = new StringBuffer();
    if (root != null) builder.write(root);
    for (var i = 0; i < parts.length; i++) {
      builder.write(separators[i]);
      builder.write(parts[i]);
    }
    builder.write(separators.last);

    return builder.toString();
  }

  /// Splits the last non-empty part of the path into a `[basename, extension`]
  /// pair.
  ///
  /// Returns a two-element list. The first is the name of the file without any
  /// extension. The second is the extension or "" if it has none.
  List<String> _splitExtension() {
    var file = parts.lastWhere((p) => p != '', orElse: () => null);

    if (file == null) return ['', ''];
    if (file == '..') return ['..', ''];

    var lastDot = file.lastIndexOf('.');

    // If there is no dot, or it's the first character, like '.bashrc', it
    // doesn't count.
    if (lastDot <= 0) return [file, ''];

    return [file.substring(0, lastDot), file.substring(lastDot)];
  }

  ParsedPath clone() => new ParsedPath._(style, root, isRootRelative,
      new List.from(parts), new List.from(separators));
}
