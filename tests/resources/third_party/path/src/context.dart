// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library path.context;

import 'internal_style.dart';
import 'style.dart';
import 'parsed_path.dart';
import 'path_exception.dart';
import '../path.dart' as p;

Context createInternal() => new Context._internal();

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
  factory Context({Style style, String current}) {
    if (current == null) {
      if (style == null) {
        current = p.current;
      } else {
        current = ".";
      }
    }

    if (style == null) {
      style = Style.platform;
    } else if (style is! InternalStyle) {
      throw new ArgumentError("Only styles defined by the path package are "
          "allowed.");
    }

    return new Context._(style, current);
  }

  /// Create a [Context] to be used internally within path.
  Context._internal()
      : style = Style.platform,
        _current = null;

  Context._(this.style, this._current);

  /// The style of path that this context works with.
  final InternalStyle style;

  /// The current directory given when Context was created. If null, current
  /// directory is evaluated from 'p.current'.
  final String _current;

  /// The current directory that relative paths are relative to.
  String get current => _current != null ? _current : p.current;

  /// Gets the path separator for the context's [style]. On Mac and Linux,
  /// this is `/`. On Windows, it's `\`.
  String get separator => style.separator;

  /// Creates a new path by appending the given path parts to [current].
  /// Equivalent to [join()] with [current] as the first argument. Example:
  ///
  ///     var context = new Context(current: '/root');
  ///     context.absolute('path', 'to', 'foo'); // -> '/root/path/to/foo'
  ///
  /// If [current] isn't absolute, this won't return an absolute path.
  String absolute(String part1, [String part2, String part3, String part4,
      String part5, String part6, String part7]) {
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
    var parsed = _parse(path);
    parsed.removeTrailingSeparators();
    if (parsed.parts.isEmpty) return parsed.root == null ? '.' : parsed.root;
    if (parsed.parts.length == 1) {
      return parsed.root == null ? '.' : parsed.root;
    }
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
  String extension(String path) => _parse(path).extension;

  // TODO(nweiz): add a UNC example for Windows once issue 7323 is fixed.
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
  ///
  ///     // URL
  ///     context.rootPrefix('path/to/foo'); // -> ''
  ///     context.rootPrefix('http://dartlang.org/path/to/foo');
  ///       // -> 'http://dartlang.org'
  String rootPrefix(String path) => path.substring(0, style.rootLength(path));

  /// Returns `true` if [path] is an absolute path and `false` if it is a
  /// relative path.
  ///
  /// On POSIX systems, absolute paths start with a `/` (forward slash). On
  /// Windows, an absolute path starts with `\\`, or a drive letter followed by
  /// `:/` or `:\`. For URLs, absolute paths either start with a protocol and
  /// optional hostname (e.g. `http://dartlang.org`, `file://`) or with a `/`.
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
  bool isRelative(String path) => !this.isAbsolute(path);

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
  String join(String part1, [String part2, String part3, String part4,
      String part5, String part6, String part7, String part8]) {
    var parts = [part1, part2, part3, part4, part5, part6, part7, part8];
    _validateArgList("join", parts);
    return joinAll(parts.where((part) => part != null));
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
    var buffer = new StringBuffer();
    var needsSeparator = false;
    var isAbsoluteAndNotRootRelative = false;

    for (var part in parts.where((part) => part != '')) {
      if (this.isRootRelative(part) && isAbsoluteAndNotRootRelative) {
        // If the new part is root-relative, it preserves the previous root but
        // replaces the path after it.
        var parsed = _parse(part);
        parsed.root = this.rootPrefix(buffer.toString());
        if (style.needsSeparator(parsed.root)) {
          parsed.separators[0] = style.separator;
        }
        buffer.clear();
        buffer.write(parsed.toString());
      } else if (this.isAbsolute(part)) {
        isAbsoluteAndNotRootRelative = !this.isRootRelative(part);
        // An absolute path discards everything before it.
        buffer.clear();
        buffer.write(part);
      } else {
        if (part.length > 0 && style.containsSeparator(part[0])) {
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

  // TODO(nweiz): add a UNC example for Windows once issue 7323 is fixed.
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
  List<String> split(String path) {
    var parsed = _parse(path);
    // Filter out empty parts that exist due to multiple separators in a row.
    parsed.parts = parsed.parts.where((part) => !part.isEmpty).toList();
    if (parsed.root != null) parsed.parts.insert(0, parsed.root);
    return parsed.parts;
  }

  /// Normalizes [path], simplifying it by handling `..`, and `.`, and
  /// removing redundant path separators whenever possible.
  ///
  ///     context.normalize('path/./to/..//file.text'); // -> 'path/file.txt'
  String normalize(String path) {
    var parsed = _parse(path);
    parsed.normalize();
    return parsed.toString();
  }

  /// Attempts to convert [path] to an equivalent relative path relative to
  /// [root].
  ///
  ///     var context = new Context(current: '/root/path');
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
  ///     var context = new Context(r'some/relative/path');
  ///     context.relative(r'/absolute/path'); // -> '/absolute/path'
  ///
  /// If [root] is relative, it may be impossible to determine a path from
  /// [from] to [path]. For example, if [root] and [path] are "." and [from] is
  /// "/", no path can be determined. In this case, a [PathException] will be
  /// thrown.
  String relative(String path, {String from}) {
    from = from == null ? current : this.join(current, from);

    // We can't determine the path from a relative path to an absolute path.
    if (this.isRelative(from) && this.isAbsolute(path)) {
      return this.normalize(path);
    }

    // If the given path is relative, resolve it relative to the context's
    // current directory.
    if (this.isRelative(path) || this.isRootRelative(path)) {
      path = this.absolute(path);
    }

    // If the path is still relative and `from` is absolute, we're unable to
    // find a path from `from` to `path`.
    if (this.isRelative(path) && this.isAbsolute(from)) {
      throw new PathException('Unable to find a path to "$path" from "$from".');
    }

    var fromParsed = _parse(from)..normalize();
    var pathParsed = _parse(path)..normalize();

    if (fromParsed.parts.length > 0 && fromParsed.parts[0] == '.') {
      return pathParsed.toString();
    }

    // If the root prefixes don't match (for example, different drive letters
    // on Windows), then there is no relative path, so just return the absolute
    // one. In Windows, drive letters are case-insenstive and we allow
    // calculation of relative paths, even if a path has not been normalized.
    if (fromParsed.root != pathParsed.root &&
        ((fromParsed.root == null || pathParsed.root == null) ||
            fromParsed.root.toLowerCase().replaceAll('/', '\\') !=
                pathParsed.root.toLowerCase().replaceAll('/', '\\'))) {
      return pathParsed.toString();
    }

    // Strip off their common prefix.
    while (fromParsed.parts.length > 0 &&
        pathParsed.parts.length > 0 &&
        fromParsed.parts[0] == pathParsed.parts[0]) {
      fromParsed.parts.removeAt(0);
      fromParsed.separators.removeAt(1);
      pathParsed.parts.removeAt(0);
      pathParsed.separators.removeAt(1);
    }

    // If there are any directories left in the from path, we need to walk up
    // out of them. If a directory left in the from path is '..', it cannot
    // be cancelled by adding a '..'.
    if (fromParsed.parts.length > 0 && fromParsed.parts[0] == '..') {
      throw new PathException('Unable to find a path to "$path" from "$from".');
    }
    pathParsed.parts.insertAll(
        0, new List.filled(fromParsed.parts.length, '..'));
    pathParsed.separators[0] = '';
    pathParsed.separators.insertAll(
        1, new List.filled(fromParsed.parts.length, style.separator));

    // Corner case: the paths completely collapsed.
    if (pathParsed.parts.length == 0) return '.';

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
  bool isWithin(String parent, String child) {
    var relative;
    try {
      relative = this.relative(child, from: parent);
    } on PathException catch (_) {
      // If no relative path from [parent] to [child] is found, [child]
      // definitely isn't a child of [parent].
      return false;
    }

    var parts = this.split(relative);
    return this.isRelative(relative) &&
        parts.first != '..' &&
        parts.first != '.';
  }

  /// Removes a trailing extension from the last part of [path].
  ///
  ///     context.withoutExtension('path/to/foo.dart'); // -> 'path/to/foo'
  String withoutExtension(String path) {
    var parsed = _parse(path);

    for (var i = parsed.parts.length - 1; i >= 0; i--) {
      if (!parsed.parts[i].isEmpty) {
        parsed.parts[i] = parsed.basenameWithoutExtension;
        break;
      }
    }

    return parsed.toString();
  }

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
  ///     context.fromUri('http://dartlang.org/path/to/foo')
  ///       // -> 'http://dartlang.org/path/to/foo'
  ///
  /// If [uri] is relative, a relative path will be returned.
  ///
  ///     path.fromUri('path/to/foo'); // -> 'path/to/foo'
  String fromUri(uri) {
    if (uri is String) uri = Uri.parse(uri);
    return style.pathFromUri(uri);
  }

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
  ///     context.toUri('http://dartlang.org/path/to/foo')
  ///       // -> Uri.parse('http://dartlang.org/path/to/foo')
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
  ///     var context = new Context(current: '/root/path');
  ///     context.prettyUri('file:///root/path/a/b.dart'); // -> 'a/b.dart'
  ///     context.prettyUri('http://dartlang.org/'); // -> 'http://dartlang.org'
  ///
  ///     // Windows
  ///     var context = new Context(current: r'C:\root\path');
  ///     context.prettyUri('file:///C:/root/path/a/b.dart'); // -> r'a\b.dart'
  ///     context.prettyUri('http://dartlang.org/'); // -> 'http://dartlang.org'
  ///
  ///     // URL
  ///     var context = new Context(current: 'http://dartlang.org/root/path');
  ///     context.prettyUri('http://dartlang.org/root/path/a/b.dart');
  ///         // -> r'a/b.dart'
  ///     context.prettyUri('file:///root/path'); // -> 'file:///root/path'
  String prettyUri(uri) {
    if (uri is String) uri = Uri.parse(uri);
    if (uri.scheme == 'file' && style == Style.url) return uri.toString();
    if (uri.scheme != 'file' && uri.scheme != '' && style != Style.url) {
      return uri.toString();
    }

    var path = normalize(fromUri(uri));
    var rel = relative(path);

    // Only return a relative path if it's actually shorter than the absolute
    // path. This avoids ugly things like long "../" chains to get to the root
    // and then go back down.
    return split(rel).length > split(path).length ? path : rel;
  }

  ParsedPath _parse(String path) => new ParsedPath.parse(path, style);
}

/// Validates that there are no non-null arguments following a null one and
/// throws an appropriate [ArgumentError] on failure.
_validateArgList(String method, List<String> args) {
  for (var i = 1; i < args.length; i++) {
    // Ignore nulls hanging off the end.
    if (args[i] == null || args[i - 1] != null) continue;

    var numArgs;
    for (numArgs = args.length; numArgs >= 1; numArgs--) {
      if (args[numArgs - 1] != null) break;
    }

    // Show the arguments.
    var message = new StringBuffer();
    message.write("$method(");
    message.write(args
        .take(numArgs)
        .map((arg) => arg == null ? "null" : '"$arg"')
        .join(", "));
    message.write("): part ${i - 1} was null, but part $i was not.");
    throw new ArgumentError(message.toString());
  }
}
