// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import '../path.dart' as p;
import 'characters.dart' as chars;
import 'internal_style.dart';
import 'parsed_path.dart';
import 'path_exception.dart';
import 'style.dart';

Context createInternal() => Context._internal();

/// An instantiable class for manipulating paths. Unlike the top-level
/// functions, this lets you explicitly select what platform the paths will use.
class Context {
  /// Creates a new path context for the given style and current directory.
  ///
  /// If [style] is omitted, it uses the host operating system's path style. If
  /// only [current] is omitted, it defaults ".". If *both* [style] and
  /// [current] are omitted, [current] defaults to the real current working
  /// directory.
  ///
  /// On the browser, [style] defaults to [Style.url] and [current] defaults to
  /// the current URL.
  factory Context({Style? style, String? current}) {
    if (current == null) {
      if (style == null) {
        current = p.current;
      } else {
        current = '.';
      }
    }

    if (style == null) {
      style = Style.platform;
    } else if (style is! InternalStyle) {
      throw ArgumentError('Only styles defined by the path package are '
          'allowed.');
    }

    return Context._(style as InternalStyle, current);
  }

  /// Create a [Context] to be used internally within path.
  Context._internal()
      : style = Style.platform as InternalStyle,
        _current = null;

  Context._(this.style, this._current);

  /// The style of path that this context works with.
  final InternalStyle style;

  /// The current directory given when Context was created. If null, current
  /// directory is evaluated from 'p.current'.
  final String? _current;

  /// The current directory that relative paths are relative to.
  String get current => _current ?? p.current;

  /// Gets the path separator for the context's [style]. On Mac and Linux,
  /// this is `/`. On Windows, it's `\`.
  String get separator => style.separator;

  /// Returns a new path with the given path parts appended to [current].
  ///
  /// Equivalent to [join()] with [current] as the first argument. Example:
  ///
  ///     var context = Context(current: '/root');
  ///     context.absolute('path', 'to', 'foo'); // -> '/root/path/to/foo'
  ///
  /// If [current] isn't absolute, this won't return an absolute path. Does not
  /// [normalize] or [canonicalize] paths.
  String absolute(String part1,
      [String? part2,
      String? part3,
      String? part4,
      String? part5,
      String? part6,
      String? part7]) {
    _validateArgList(
        'absolute', [part1, part2, part3, part4, part5, part6, part7]);

    // If there's a single absolute path, just return it. This is a lot faster
    // for the common case of `p.absolute(path)`.
    if (part2 == null && isAbsolute(part1) && !isRootRelative(part1)) {
      return part1;
    }

    return join(current, part1, part2, part3, part4, part5, part6, part7);
  }

  /// Gets the part of [path] after the last separator on the context's
  /// platform.
  ///
  ///     context.basename('path/to/foo.dart'); // -> 'foo.dart'
  ///     context.basename('path/to');          // -> 'to'
  ///
  /// Trailing separators are ignored.
  ///
  ///     context.basename('path/to/'); // -> 'to'
  String basename(String path) => _parse(path).basename;

  /// Gets the part of [path] after the last separator on the context's
  /// platform, and without any trailing file extension.
  ///
  ///     context.basenameWithoutExtension('path/to/foo.dart'); // -> 'foo'
  ///
  /// Trailing separators are ignored.
  ///
  ///     context.basenameWithoutExtension('path/to/foo.dart/'); // -> 'foo'
  String basenameWithoutExtension(String path) =>
      _parse(path).basenameWithoutExtension;

  /// Gets the part of [path] before the last separator.
  ///
  ///     context.dirname('path/to/foo.dart'); // -> 'path/to'
  ///     context.dirname('path/to');          // -> 'path'
  ///
  /// Trailing separators are ignored.
  ///
  ///     context.dirname('path/to/'); // -> 'path'
  String dirname(String path) {
    final parsed = _parse(path);
    parsed.removeTrailingSeparators();
    if (parsed.parts.isEmpty) return parsed.root ?? '.';
    if (parsed.parts.length == 1) return parsed.root ?? '.';
    parsed.parts.removeLast();
    parsed.separators.removeLast();
    parsed.removeTrailingSeparators();
    return parsed.toString();
  }

  /// Gets the file extension of [path]: the portion of [basename] from the last
  /// `.` to the end (including the `.` itself).
  ///
  ///     context.extension('path/to/foo.dart'); // -> '.dart'
  ///     context.extension('path/to/foo'); // -> ''
  ///     context.extension('path.to/foo'); // -> ''
  ///     context.extension('path/to/foo.dart.js'); // -> '.js'
  ///
  /// If the file name starts with a `.`, then it is not considered an
  /// extension:
  ///
  ///     context.extension('~/.bashrc');    // -> ''
  ///     context.extension('~/.notes.txt'); // -> '.txt'
  ///
  /// Takes an optional parameter `level` which makes possible to return
  /// multiple extensions having `level` number of dots. If `level` exceeds the
  /// number of dots, the full extension is returned. The value of `level` must
  /// be greater than 0, else `RangeError` is thrown.
  ///
  ///     context.extension('foo.bar.dart.js', 2);   // -> '.dart.js
  ///     context.extension('foo.bar.dart.js', 3);   // -> '.bar.dart.js'
  ///     context.extension('foo.bar.dart.js', 10);  // -> '.bar.dart.js'
  ///     context.extension('path/to/foo.bar.dart.js', 2);  // -> '.dart.js'
  String extension(String path, [int level = 1]) =>
      _parse(path).extension(level);

  /// Returns the root of [path] if it's absolute, or an empty string if it's
  /// relative.
  ///
  ///     // Unix
  ///     context.rootPrefix('path/to/foo'); // -> ''
  ///     context.rootPrefix('/path/to/foo'); // -> '/'
  ///
  ///     // Windows
  ///     context.rootPrefix(r'path\to\foo'); // -> ''
  ///     context.rootPrefix(r'C:\path\to\foo'); // -> r'C:\'
  ///     context.rootPrefix(r'\\server\share\a\b'); // -> r'\\server\share'
  ///
  ///     // URL
  ///     context.rootPrefix('path/to/foo'); // -> ''
  ///     context.rootPrefix('https://dart.dev/path/to/foo');
  ///       // -> 'https://dart.dev'
  String rootPrefix(String path) => path.substring(0, style.rootLength(path));

  /// Returns `true` if [path] is an absolute path and `false` if it is a
  /// relative path.
  ///
  /// On POSIX systems, absolute paths start with a `/` (forward slash). On
  /// Windows, an absolute path starts with `\\`, or a drive letter followed by
  /// `:/` or `:\`. For URLs, absolute paths either start with a protocol and
  /// optional hostname (e.g. `https://dart.dev`, `file://`) or with a `/`.
  ///
  /// URLs that start with `/` are known as "root-relative", since they're
  /// relative to the root of the current URL. Since root-relative paths are
  /// still absolute in every other sense, [isAbsolute] will return true for
  /// them. They can be detected using [isRootRelative].
  bool isAbsolute(String path) => style.rootLength(path) > 0;

  /// Returns `true` if [path] is a relative path and `false` if it is absolute.
  /// On POSIX systems, absolute paths start with a `/` (forward slash). On
  /// Windows, an absolute path starts with `\\`, or a drive letter followed by
  /// `:/` or `:\`.
  bool isRelative(String path) => !isAbsolute(path);

  /// Returns `true` if [path] is a root-relative path and `false` if it's not.
  ///
  /// URLs that start with `/` are known as "root-relative", since they're
  /// relative to the root of the current URL. Since root-relative paths are
  /// still absolute in every other sense, [isAbsolute] will return true for
  /// them. They can be detected using [isRootRelative].
  ///
  /// No POSIX and Windows paths are root-relative.
  bool isRootRelative(String path) => style.isRootRelative(path);

  /// Joins the given path parts into a single path. Example:
  ///
  ///     context.join('path', 'to', 'foo'); // -> 'path/to/foo'
  ///
  /// If any part ends in a path separator, then a redundant separator will not
  /// be added:
  ///
  ///     context.join('path/', 'to', 'foo'); // -> 'path/to/foo
  ///
  /// If a part is an absolute path, then anything before that will be ignored:
  ///
  ///     context.join('path', '/to', 'foo'); // -> '/to/foo'
  ///
  String join(String part1,
      [String? part2,
      String? part3,
      String? part4,
      String? part5,
      String? part6,
      String? part7,
      String? part8]) {
    final parts = <String?>[
      part1,
      part2,
      part3,
      part4,
      part5,
      part6,
      part7,
      part8
    ];
    _validateArgList('join', parts);
    return joinAll(parts.whereType<String>());
  }

  /// Joins the given path parts into a single path. Example:
  ///
  ///     context.joinAll(['path', 'to', 'foo']); // -> 'path/to/foo'
  ///
  /// If any part ends in a path separator, then a redundant separator will not
  /// be added:
  ///
  ///     context.joinAll(['path/', 'to', 'foo']); // -> 'path/to/foo
  ///
  /// If a part is an absolute path, then anything before that will be ignored:
  ///
  ///     context.joinAll(['path', '/to', 'foo']); // -> '/to/foo'
  ///
  /// For a fixed number of parts, [join] is usually terser.
  String joinAll(Iterable<String> parts) {
    final buffer = StringBuffer();
    var needsSeparator = false;
    var isAbsoluteAndNotRootRelative = false;

    for (var part in parts.where((part) => part != '')) {
      if (isRootRelative(part) && isAbsoluteAndNotRootRelative) {
        // If the new part is root-relative, it preserves the previous root but
        // replaces the path after it.
        final parsed = _parse(part);
        final path = buffer.toString();
        parsed.root =
            path.substring(0, style.rootLength(path, withDrive: true));
        if (style.needsSeparator(parsed.root!)) {
          parsed.separators[0] = style.separator;
        }
        buffer.clear();
        buffer.write(parsed.toString());
      } else if (isAbsolute(part)) {
        isAbsoluteAndNotRootRelative = !isRootRelative(part);
        // An absolute path discards everything before it.
        buffer.clear();
        buffer.write(part);
      } else {
        if (part.isNotEmpty && style.containsSeparator(part[0])) {
          // The part starts with a separator, so we don't need to add one.
        } else if (needsSeparator) {
          buffer.write(separator);
        }

        buffer.write(part);
      }

      // Unless this part ends with a separator, we'll need to add one before
      // the next part.
      needsSeparator = style.needsSeparator(part);
    }

    return buffer.toString();
  }

  /// Splits [path] into its components using the current platform's
  /// [separator]. Example:
  ///
  ///     context.split('path/to/foo'); // -> ['path', 'to', 'foo']
  ///
  /// The path will *not* be normalized before splitting.
  ///
  ///     context.split('path/../foo'); // -> ['path', '..', 'foo']
  ///
  /// If [path] is absolute, the root directory will be the first element in the
  /// array. Example:
  ///
  ///     // Unix
  ///     context.split('/path/to/foo'); // -> ['/', 'path', 'to', 'foo']
  ///
  ///     // Windows
  ///     context.split(r'C:\path\to\foo'); // -> [r'C:\', 'path', 'to', 'foo']
  ///     context.split(r'\\server\share\path\to\foo');
  ///       // -> [r'\\server\share', 'foo', 'bar', 'baz']
  ///
  ///     // Browser
  ///     context.split('https://dart.dev/path/to/foo');
  ///       // -> ['https://dart.dev', 'path', 'to', 'foo']
  List<String> split(String path) {
    final parsed = _parse(path);
    // Filter out empty parts that exist due to multiple separators in a row.
    parsed.parts = parsed.parts.where((part) => part.isNotEmpty).toList();
    if (parsed.root != null) parsed.parts.insert(0, parsed.root!);
    return parsed.parts;
  }

  /// Canonicalizes [path].
  ///
  /// This is guaranteed to return the same path for two different input paths
  /// if and only if both input paths point to the same location. Unlike
  /// [normalize], it returns absolute paths when possible and canonicalizes
  /// ASCII case on Windows.
  ///
  /// Note that this does not resolve symlinks.
  ///
  /// If you want a map that uses path keys, it's probably more efficient to use
  /// a Map with [equals] and [hash] specified as the callbacks to use for keys
  /// than it is to canonicalize every key.
  String canonicalize(String path) {
    path = absolute(path);
    if (style != Style.windows && !_needsNormalization(path)) return path;

    final parsed = _parse(path);
    parsed.normalize(canonicalize: true);
    return parsed.toString();
  }

  /// Normalizes [path], simplifying it by handling `..`, and `.`, and
  /// removing redundant path separators whenever possible.
  ///
  /// Note that this is *not* guaranteed to return the same result for two
  /// equivalent input paths. For that, see [canonicalize]. Or, if you're using
  /// paths as map keys use [equals] and [hash] as the key callbacks.
  ///
  ///     context.normalize('path/./to/..//file.text'); // -> 'path/file.txt'
  String normalize(String path) {
    if (!_needsNormalization(path)) return path;

    final parsed = _parse(path);
    parsed.normalize();
    return parsed.toString();
  }

  /// Returns whether [path] needs to be normalized.
  bool _needsNormalization(String path) {
    var start = 0;
    final codeUnits = path.codeUnits;
    int? previousPrevious;
    int? previous;

    // Skip past the root before we start looking for snippets that need
    // normalization. We want to normalize "//", but not when it's part of
    // "http://".
    final root = style.rootLength(path);
    if (root != 0) {
      start = root;
      previous = chars.slash;

      // On Windows, the root still needs to be normalized if it contains a
      // forward slash.
      if (style == Style.windows) {
        for (var i = 0; i < root; i++) {
          if (codeUnits[i] == chars.slash) return true;
        }
      }
    }

    for (var i = start; i < codeUnits.length; i++) {
      final codeUnit = codeUnits[i];
      if (style.isSeparator(codeUnit)) {
        // Forward slashes in Windows paths are normalized to backslashes.
        if (style == Style.windows && codeUnit == chars.slash) return true;

        // Multiple separators are normalized to single separators.
        if (previous != null && style.isSeparator(previous)) return true;

        // Single dots and double dots are normalized to directory traversals.
        //
        // This can return false positives for ".../", but that's unlikely
        // enough that it's probably not going to cause performance issues.
        if (previous == chars.period &&
            (previousPrevious == null ||
                previousPrevious == chars.period ||
                style.isSeparator(previousPrevious))) {
          return true;
        }
      }

      previousPrevious = previous;
      previous = codeUnit;
    }

    // Empty paths are normalized to ".".
    if (previous == null) return true;

    // Trailing separators are removed.
    if (style.isSeparator(previous)) return true;

    // Single dots and double dots are normalized to directory traversals.
    if (previous == chars.period &&
        (previousPrevious == null ||
            style.isSeparator(previousPrevious) ||
            previousPrevious == chars.period)) {
      return true;
    }

    return false;
  }

  /// Attempts to convert [path] to an equivalent relative path relative to
  /// [current].
  ///
  ///     var context = Context(current: '/root/path');
  ///     context.relative('/root/path/a/b.dart'); // -> 'a/b.dart'
  ///     context.relative('/root/other.dart'); // -> '../other.dart'
  ///
  /// If the [from] argument is passed, [path] is made relative to that instead.
  ///
  ///     context.relative('/root/path/a/b.dart',
  ///         from: '/root/path'); // -> 'a/b.dart'
  ///     context.relative('/root/other.dart',
  ///         from: '/root/path'); // -> '../other.dart'
  ///
  /// If [path] and/or [from] are relative paths, they are assumed to be
  /// relative to [current].
  ///
  /// Since there is no relative path from one drive letter to another on
  /// Windows, this will return an absolute path in that case.
  ///
  ///     context.relative(r'D:\other', from: r'C:\other'); // -> 'D:\other'
  ///
  /// This will also return an absolute path if an absolute [path] is passed to
  /// a context with a relative path for [current].
  ///
  ///     var context = Context(r'some/relative/path');
  ///     context.relative(r'/absolute/path'); // -> '/absolute/path'
  ///
  /// If [current] is relative, it may be impossible to determine a path from
  /// [from] to [path]. For example, if [current] and [path] are "." and [from]
  /// is "/", no path can be determined. In this case, a [PathException] will be
  /// thrown.
  String relative(String path, {String? from}) {
    // Avoid expensive computation if the path is already relative.
    if (from == null && isRelative(path)) return normalize(path);

    from = from == null ? current : absolute(from);

    // We can't determine the path from a relative path to an absolute path.
    if (isRelative(from) && isAbsolute(path)) {
      return normalize(path);
    }

    // If the given path is relative, resolve it relative to the context's
    // current directory.
    if (isRelative(path) || isRootRelative(path)) {
      path = absolute(path);
    }

    // If the path is still relative and `from` is absolute, we're unable to
    // find a path from `from` to `path`.
    if (isRelative(path) && isAbsolute(from)) {
      throw PathException('Unable to find a path to "$path" from "$from".');
    }

    final fromParsed = _parse(from)..normalize();
    final pathParsed = _parse(path)..normalize();

    if (fromParsed.parts.isNotEmpty && fromParsed.parts[0] == '.') {
      return pathParsed.toString();
    }

    // If the root prefixes don't match (for example, different drive letters
    // on Windows), then there is no relative path, so just return the absolute
    // one. In Windows, drive letters are case-insenstive and we allow
    // calculation of relative paths, even if a path has not been normalized.
    if (fromParsed.root != pathParsed.root &&
        ((fromParsed.root == null || pathParsed.root == null) ||
            !style.pathsEqual(fromParsed.root!, pathParsed.root!))) {
      return pathParsed.toString();
    }

    // Strip off their common prefix.
    while (fromParsed.parts.isNotEmpty &&
        pathParsed.parts.isNotEmpty &&
        style.pathsEqual(fromParsed.parts[0], pathParsed.parts[0])) {
      fromParsed.parts.removeAt(0);
      fromParsed.separators.removeAt(1);
      pathParsed.parts.removeAt(0);
      pathParsed.separators.removeAt(1);
    }

    // If there are any directories left in the from path, we need to walk up
    // out of them. If a directory left in the from path is '..', it cannot
    // be cancelled by adding a '..'.
    if (fromParsed.parts.isNotEmpty && fromParsed.parts[0] == '..') {
      throw PathException('Unable to find a path to "$path" from "$from".');
    }
    pathParsed.parts.insertAll(0, List.filled(fromParsed.parts.length, '..'));
    pathParsed.separators[0] = '';
    pathParsed.separators
        .insertAll(1, List.filled(fromParsed.parts.length, style.separator));

    // Corner case: the paths completely collapsed.
    if (pathParsed.parts.isEmpty) return '.';

    // Corner case: path was '.' and some '..' directories were added in front.
    // Don't add a final '/.' in that case.
    if (pathParsed.parts.length > 1 && pathParsed.parts.last == '.') {
      pathParsed.parts.removeLast();
      pathParsed.separators
        ..removeLast()
        ..removeLast()
        ..add('');
    }

    // Make it relative.
    pathParsed.root = '';
    pathParsed.removeTrailingSeparators();

    return pathParsed.toString();
  }

  /// Returns `true` if [child] is a path beneath `parent`, and `false`
  /// otherwise.
  ///
  ///     path.isWithin('/root/path', '/root/path/a'); // -> true
  ///     path.isWithin('/root/path', '/root/other'); // -> false
  ///     path.isWithin('/root/path', '/root/path'); // -> false
  bool isWithin(String parent, String child) =>
      _isWithinOrEquals(parent, child) == _PathRelation.within;

  /// Returns `true` if [path1] points to the same location as [path2], and
  /// `false` otherwise.
  ///
  /// The [hash] function returns a hash code that matches these equality
  /// semantics.
  bool equals(String path1, String path2) =>
      _isWithinOrEquals(path1, path2) == _PathRelation.equal;

  /// Compares two paths and returns an enum value indicating their relationship
  /// to one another.
  ///
  /// This never returns [_PathRelation.inconclusive].
  _PathRelation _isWithinOrEquals(String parent, String child) {
    // Make both paths the same level of relative. We're only able to do the
    // quick comparison if both paths are in the same format, and making a path
    // absolute is faster than making it relative.
    final parentIsAbsolute = isAbsolute(parent);
    final childIsAbsolute = isAbsolute(child);
    if (parentIsAbsolute && !childIsAbsolute) {
      child = absolute(child);
      if (style.isRootRelative(parent)) parent = absolute(parent);
    } else if (childIsAbsolute && !parentIsAbsolute) {
      parent = absolute(parent);
      if (style.isRootRelative(child)) child = absolute(child);
    } else if (childIsAbsolute && parentIsAbsolute) {
      final childIsRootRelative = style.isRootRelative(child);
      final parentIsRootRelative = style.isRootRelative(parent);

      if (childIsRootRelative && !parentIsRootRelative) {
        child = absolute(child);
      } else if (parentIsRootRelative && !childIsRootRelative) {
        parent = absolute(parent);
      }
    }

    final result = _isWithinOrEqualsFast(parent, child);
    if (result != _PathRelation.inconclusive) return result;

    String relative;
    try {
      relative = this.relative(child, from: parent);
    } on PathException catch (_) {
      // If no relative path from [parent] to [child] is found, [child]
      // definitely isn't a child of [parent].
      return _PathRelation.different;
    }

    if (!isRelative(relative)) return _PathRelation.different;
    if (relative == '.') return _PathRelation.equal;
    if (relative == '..') return _PathRelation.different;
    return (relative.length >= 3 &&
            relative.startsWith('..') &&
            style.isSeparator(relative.codeUnitAt(2)))
        ? _PathRelation.different
        : _PathRelation.within;
  }

  /// An optimized implementation of [_isWithinOrEquals] that doesn't handle a
  /// few complex cases.
  _PathRelation _isWithinOrEqualsFast(String parent, String child) {
    // Normally we just bail when we see "." path components, but we can handle
    // a single dot easily enough.
    if (parent == '.') parent = '';

    final parentRootLength = style.rootLength(parent);
    final childRootLength = style.rootLength(child);

    // If the roots aren't the same length, we know both paths are absolute or
    // both are root-relative, and thus that the roots are meaningfully
    // different.
    //
    //     isWithin("C:/bar", "//foo/bar/baz") //=> false
    //     isWithin("http://example.com/", "http://google.com/bar") //=> false
    if (parentRootLength != childRootLength) return _PathRelation.different;

    // Make sure that the roots are textually the same as well.
    //
    //     isWithin("C:/bar", "D:/bar/baz") //=> false
    //     isWithin("http://example.com/", "http://example.org/bar") //=> false
    for (var i = 0; i < parentRootLength; i++) {
      final parentCodeUnit = parent.codeUnitAt(i);
      final childCodeUnit = child.codeUnitAt(i);
      if (!style.codeUnitsEqual(parentCodeUnit, childCodeUnit)) {
        return _PathRelation.different;
      }
    }

    // Start by considering the last code unit as a separator, since
    // semantically we're starting at a new path component even if we're
    // comparing relative paths.
    var lastCodeUnit = chars.slash;

    /// The index of the last separator in [parent].
    int? lastParentSeparator;

    // Iterate through both paths as long as they're semantically identical.
    var parentIndex = parentRootLength;
    var childIndex = childRootLength;
    while (parentIndex < parent.length && childIndex < child.length) {
      var parentCodeUnit = parent.codeUnitAt(parentIndex);
      var childCodeUnit = child.codeUnitAt(childIndex);
      if (style.codeUnitsEqual(parentCodeUnit, childCodeUnit)) {
        if (style.isSeparator(parentCodeUnit)) {
          lastParentSeparator = parentIndex;
        }

        lastCodeUnit = parentCodeUnit;
        parentIndex++;
        childIndex++;
        continue;
      }

      // Ignore multiple separators in a row.
      if (style.isSeparator(parentCodeUnit) &&
          style.isSeparator(lastCodeUnit)) {
        lastParentSeparator = parentIndex;
        parentIndex++;
        continue;
      } else if (style.isSeparator(childCodeUnit) &&
          style.isSeparator(lastCodeUnit)) {
        childIndex++;
        continue;
      }

      // If a dot comes after a separator, it may be a directory traversal
      // operator. To check that, we need to know if it's followed by either
      // "/" or "./". Otherwise, it's just a normal non-matching character.
      //
      //     isWithin("foo/./bar", "foo/bar/baz") //=> true
      //     isWithin("foo/bar/../baz", "foo/bar/.foo") //=> false
      if (parentCodeUnit == chars.period && style.isSeparator(lastCodeUnit)) {
        parentIndex++;

        // We've hit "/." at the end of the parent path, which we can ignore,
        // since the paths were equivalent up to this point.
        if (parentIndex == parent.length) break;
        parentCodeUnit = parent.codeUnitAt(parentIndex);

        // We've hit "/./", which we can ignore.
        if (style.isSeparator(parentCodeUnit)) {
          lastParentSeparator = parentIndex;
          parentIndex++;
          continue;
        }

        // We've hit "/..", which may be a directory traversal operator that
        // we can't handle on the fast track.
        if (parentCodeUnit == chars.period) {
          parentIndex++;
          if (parentIndex == parent.length ||
              style.isSeparator(parent.codeUnitAt(parentIndex))) {
            return _PathRelation.inconclusive;
          }
        }

        // If this isn't a directory traversal, fall through so we hit the
        // normal handling for mismatched paths.
      }

      // This is the same logic as above, but for the child path instead of the
      // parent.
      if (childCodeUnit == chars.period && style.isSeparator(lastCodeUnit)) {
        childIndex++;
        if (childIndex == child.length) break;
        childCodeUnit = child.codeUnitAt(childIndex);

        if (style.isSeparator(childCodeUnit)) {
          childIndex++;
          continue;
        }

        if (childCodeUnit == chars.period) {
          childIndex++;
          if (childIndex == child.length ||
              style.isSeparator(child.codeUnitAt(childIndex))) {
            return _PathRelation.inconclusive;
          }
        }
      }

      // If we're here, we've hit two non-matching, non-significant characters.
      // As long as the remainders of the two paths don't have any unresolved
      // ".." components, we can be confident that [child] is not within
      // [parent].
      final childDirection = _pathDirection(child, childIndex);
      if (childDirection != _PathDirection.belowRoot) {
        return _PathRelation.inconclusive;
      }

      final parentDirection = _pathDirection(parent, parentIndex);
      if (parentDirection != _PathDirection.belowRoot) {
        return _PathRelation.inconclusive;
      }

      return _PathRelation.different;
    }

    // If the child is shorter than the parent, it's probably not within the
    // parent. The only exception is if the parent has some weird ".." stuff
    // going on, in which case we do the slow check.
    //
    //     isWithin("foo/bar/baz", "foo/bar") //=> false
    //     isWithin("foo/bar/baz/../..", "foo/bar") //=> true
    if (childIndex == child.length) {
      if (parentIndex == parent.length ||
          style.isSeparator(parent.codeUnitAt(parentIndex))) {
        lastParentSeparator = parentIndex;
      } else {
        lastParentSeparator ??= math.max(0, parentRootLength - 1);
      }

      final direction = _pathDirection(parent, lastParentSeparator);
      if (direction == _PathDirection.atRoot) return _PathRelation.equal;
      return direction == _PathDirection.aboveRoot
          ? _PathRelation.inconclusive
          : _PathRelation.different;
    }

    // We've reached the end of the parent path, which means it's time to make a
    // decision. Before we do, though, we'll check the rest of the child to see
    // what that tells us.
    final direction = _pathDirection(child, childIndex);

    // If there are no more components in the child, then it's the same as
    // the parent.
    //
    //     isWithin("foo/bar", "foo/bar") //=> false
    //     isWithin("foo/bar", "foo/bar//") //=> false
    //     equals("foo/bar", "foo/bar") //=> true
    //     equals("foo/bar", "foo/bar//") //=> true
    if (direction == _PathDirection.atRoot) return _PathRelation.equal;

    // If there are unresolved ".." components in the child, no decision we make
    // will be valid. We'll abort and do the slow check instead.
    //
    //     isWithin("foo/bar", "foo/bar/..") //=> false
    //     isWithin("foo/bar", "foo/bar/baz/bang/../../..") //=> false
    //     isWithin("foo/bar", "foo/bar/baz/bang/../../../bar/baz") //=> true
    if (direction == _PathDirection.aboveRoot) {
      return _PathRelation.inconclusive;
    }

    // The child is within the parent if and only if we're on a separator
    // boundary.
    //
    //     isWithin("foo/bar", "foo/bar/baz") //=> true
    //     isWithin("foo/bar/", "foo/bar/baz") //=> true
    //     isWithin("foo/bar", "foo/barbaz") //=> false
    return (style.isSeparator(child.codeUnitAt(childIndex)) ||
            style.isSeparator(lastCodeUnit))
        ? _PathRelation.within
        : _PathRelation.different;
  }

  // Returns a [_PathDirection] describing the path represented by [codeUnits]
  // starting at [index].
  //
  // This ignores leading separators.
  //
  //     pathDirection("foo") //=> below root
  //     pathDirection("foo/bar/../baz") //=> below root
  //     pathDirection("//foo/bar/baz") //=> below root
  //     pathDirection("/") //=> at root
  //     pathDirection("foo/..") //=> at root
  //     pathDirection("foo/../baz") //=> reaches root
  //     pathDirection("foo/../..") //=> above root
  //     pathDirection("foo/../../foo/bar/baz") //=> above root
  _PathDirection _pathDirection(String path, int index) {
    var depth = 0;
    var reachedRoot = false;
    var i = index;
    while (i < path.length) {
      // Ignore initial separators or doubled separators.
      while (i < path.length && style.isSeparator(path.codeUnitAt(i))) {
        i++;
      }

      // If we're at the end, stop.
      if (i == path.length) break;

      // Move through the path component to the next separator.
      final start = i;
      while (i < path.length && !style.isSeparator(path.codeUnitAt(i))) {
        i++;
      }

      // See if the path component is ".", "..", or a name.
      if (i - start == 1 && path.codeUnitAt(start) == chars.period) {
        // Don't change the depth.
      } else if (i - start == 2 &&
          path.codeUnitAt(start) == chars.period &&
          path.codeUnitAt(start + 1) == chars.period) {
        // ".." backs out a directory.
        depth--;

        // If we work back beyond the root, stop.
        if (depth < 0) break;

        // Record that we reached the root so we don't return
        // [_PathDirection.belowRoot].
        if (depth == 0) reachedRoot = true;
      } else {
        // Step inside a directory.
        depth++;
      }

      // If we're at the end, stop.
      if (i == path.length) break;

      // Move past the separator.
      i++;
    }

    if (depth < 0) return _PathDirection.aboveRoot;
    if (depth == 0) return _PathDirection.atRoot;
    if (reachedRoot) return _PathDirection.reachesRoot;
    return _PathDirection.belowRoot;
  }

  /// Returns a hash code for [path] that matches the semantics of [equals].
  ///
  /// Note that the same path may have different hash codes in different
  /// [Context]s.
  int hash(String path) {
    // Make [path] absolute to ensure that equivalent relative and absolute
    // paths have the same hash code.
    path = absolute(path);

    final result = _hashFast(path);
    if (result != null) return result;

    final parsed = _parse(path);
    parsed.normalize();
    return _hashFast(parsed.toString())!;
  }

  /// An optimized implementation of [hash] that doesn't handle internal `..`
  /// components.
  ///
  /// This will handle `..` components that appear at the beginning of the path.
  int? _hashFast(String path) {
    var hash = 4603;
    var beginning = true;
    var wasSeparator = true;
    for (var i = 0; i < path.length; i++) {
      final codeUnit = style.canonicalizeCodeUnit(path.codeUnitAt(i));

      // Take advantage of the fact that collisions are allowed to ignore
      // separators entirely. This lets us avoid worrying about cases like
      // multiple trailing slashes.
      if (style.isSeparator(codeUnit)) {
        wasSeparator = true;
        continue;
      }

      if (codeUnit == chars.period && wasSeparator) {
        // If a dot comes after a separator, it may be a directory traversal
        // operator. To check that, we need to know if it's followed by either
        // "/" or "./". Otherwise, it's just a normal character.
        //
        //     hash("foo/./bar") == hash("foo/bar")

        // We've hit "/." at the end of the path, which we can ignore.
        if (i + 1 == path.length) break;

        final next = path.codeUnitAt(i + 1);

        // We can just ignore "/./", since they don't affect the semantics of
        // the path.
        if (style.isSeparator(next)) continue;

        // If the path ends with "/.." or contains "/../", we need to
        // canonicalize it before we can hash it. We make an exception for ".."s
        // at the beginning of the path, since those may appear even in a
        // canonicalized path.
        if (!beginning &&
            next == chars.period &&
            (i + 2 == path.length ||
                style.isSeparator(path.codeUnitAt(i + 2)))) {
          return null;
        }
      }

      // Make sure [hash] stays under 32 bits even after multiplication.
      hash &= 0x3FFFFFF;
      hash *= 33;
      hash ^= codeUnit;
      wasSeparator = false;
      beginning = false;
    }
    return hash;
  }

  /// Removes a trailing extension from the last part of [path].
  ///
  ///     context.withoutExtension('path/to/foo.dart'); // -> 'path/to/foo'
  String withoutExtension(String path) {
    final parsed = _parse(path);

    for (var i = parsed.parts.length - 1; i >= 0; i--) {
      if (parsed.parts[i].isNotEmpty) {
        parsed.parts[i] = parsed.basenameWithoutExtension;
        break;
      }
    }

    return parsed.toString();
  }

  /// Returns [path] with the trailing extension set to [extension].
  ///
  /// If [path] doesn't have a trailing extension, this just adds [extension] to
  /// the end.
  ///
  ///     context.setExtension('path/to/foo.dart', '.js')
  ///       // -> 'path/to/foo.js'
  ///     context.setExtension('path/to/foo.dart.js', '.map')
  ///       // -> 'path/to/foo.dart.map'
  ///     context.setExtension('path/to/foo', '.js')
  ///       // -> 'path/to/foo.js'
  String setExtension(String path, String extension) =>
      withoutExtension(path) + extension;

  /// Returns the path represented by [uri], which may be a [String] or a [Uri].
  ///
  /// For POSIX and Windows styles, [uri] must be a `file:` URI. For the URL
  /// style, this will just convert [uri] to a string.
  ///
  ///     // POSIX
  ///     context.fromUri('file:///path/to/foo')
  ///       // -> '/path/to/foo'
  ///
  ///     // Windows
  ///     context.fromUri('file:///C:/path/to/foo')
  ///       // -> r'C:\path\to\foo'
  ///
  ///     // URL
  ///     context.fromUri('https://dart.dev/path/to/foo')
  ///       // -> 'https://dart.dev/path/to/foo'
  ///
  /// If [uri] is relative, a relative path will be returned.
  ///
  ///     path.fromUri('path/to/foo'); // -> 'path/to/foo'
  String fromUri(uri) => style.pathFromUri(_parseUri(uri));

  /// Returns the URI that represents [path].
  ///
  /// For POSIX and Windows styles, this will return a `file:` URI. For the URL
  /// style, this will just convert [path] to a [Uri].
  ///
  ///     // POSIX
  ///     context.toUri('/path/to/foo')
  ///       // -> Uri.parse('file:///path/to/foo')
  ///
  ///     // Windows
  ///     context.toUri(r'C:\path\to\foo')
  ///       // -> Uri.parse('file:///C:/path/to/foo')
  ///
  ///     // URL
  ///     context.toUri('https://dart.dev/path/to/foo')
  ///       // -> Uri.parse('https://dart.dev/path/to/foo')
  Uri toUri(String path) {
    if (isRelative(path)) {
      return style.relativePathToUri(path);
    } else {
      return style.absolutePathToUri(join(current, path));
    }
  }

  /// Returns a terse, human-readable representation of [uri].
  ///
  /// [uri] can be a [String] or a [Uri]. If it can be made relative to the
  /// current working directory, that's done. Otherwise, it's returned as-is.
  /// This gracefully handles non-`file:` URIs for [Style.posix] and
  /// [Style.windows].
  ///
  /// The returned value is meant for human consumption, and may be either URI-
  /// or path-formatted.
  ///
  ///     // POSIX
  ///     var context = Context(current: '/root/path');
  ///     context.prettyUri('file:///root/path/a/b.dart'); // -> 'a/b.dart'
  ///     context.prettyUri('https://dart.dev/'); // -> 'https://dart.dev'
  ///
  ///     // Windows
  ///     var context = Context(current: r'C:\root\path');
  ///     context.prettyUri('file:///C:/root/path/a/b.dart'); // -> r'a\b.dart'
  ///     context.prettyUri('https://dart.dev/'); // -> 'https://dart.dev'
  ///
  ///     // URL
  ///     var context = Context(current: 'https://dart.dev/root/path');
  ///     context.prettyUri('https://dart.dev/root/path/a/b.dart');
  ///         // -> r'a/b.dart'
  ///     context.prettyUri('file:///root/path'); // -> 'file:///root/path'
  String prettyUri(uri) {
    final typedUri = _parseUri(uri);
    if (typedUri.scheme == 'file' && style == Style.url) {
      return typedUri.toString();
    } else if (typedUri.scheme != 'file' &&
        typedUri.scheme != '' &&
        style != Style.url) {
      return typedUri.toString();
    }

    final path = normalize(fromUri(typedUri));
    final rel = relative(path);

    // Only return a relative path if it's actually shorter than the absolute
    // path. This avoids ugly things like long "../" chains to get to the root
    // and then go back down.
    return split(rel).length > split(path).length ? path : rel;
  }

  ParsedPath _parse(String path) => ParsedPath.parse(path, style);
}

/// Parses argument if it's a [String] or returns it intact if it's a [Uri].
///
/// Throws an [ArgumentError] otherwise.
Uri _parseUri(uri) {
  if (uri is String) return Uri.parse(uri);
  if (uri is Uri) return uri;
  throw ArgumentError.value(uri, 'uri', 'Value must be a String or a Uri');
}

/// Validates that there are no non-null arguments following a null one and
/// throws an appropriate [ArgumentError] on failure.
void _validateArgList(String method, List<String?> args) {
  for (var i = 1; i < args.length; i++) {
    // Ignore nulls hanging off the end.
    if (args[i] == null || args[i - 1] != null) continue;

    int numArgs;
    for (numArgs = args.length; numArgs >= 1; numArgs--) {
      if (args[numArgs - 1] != null) break;
    }

    // Show the arguments.
    final message = StringBuffer();
    message.write('$method(');
    message.write(args
        .take(numArgs)
        .map((arg) => arg == null ? 'null' : '"$arg"')
        .join(', '));
    message.write('): part ${i - 1} was null, but part $i was not.');
    throw ArgumentError(message.toString());
  }
}

/// An enum of possible return values for [Context._pathDirection].
class _PathDirection {
  /// The path contains enough ".." components that at some point it reaches
  /// above its original root.
  ///
  /// Note that this applies even if the path ends beneath its original root. It
  /// takes precendence over any other return values that may apple.
  static const aboveRoot = _PathDirection('above root');

  /// The path contains enough ".." components that it ends at its original
  /// root.
  static const atRoot = _PathDirection('at root');

  /// The path contains enough ".." components that at some point it reaches its
  /// original root, but it ends beneath that root.
  static const reachesRoot = _PathDirection('reaches root');

  /// The path never reaches to or above its original root.
  static const belowRoot = _PathDirection('below root');

  final String name;

  const _PathDirection(this.name);

  @override
  String toString() => name;
}

/// An enum of possible return values for [Context._isWithinOrEquals].
class _PathRelation {
  /// The first path is a proper parent of the second.
  ///
  /// For example, `foo` is a proper parent of `foo/bar`, but not of `foo`.
  static const within = _PathRelation('within');

  /// The two paths are equivalent.
  ///
  /// For example, `foo//bar` is equivalent to `foo/bar`.
  static const equal = _PathRelation('equal');

  /// The first path is neither a parent of nor equal to the second.
  static const different = _PathRelation('different');

  /// We couldn't quickly determine any information about the paths'
  /// relationship to each other.
  ///
  /// Only returned by [Context._isWithinOrEqualsFast].
  static const inconclusive = _PathRelation('inconclusive');

  final String name;

  const _PathRelation(this.name);

  @override
  String toString() => name;
}
