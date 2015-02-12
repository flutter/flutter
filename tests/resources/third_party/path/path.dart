// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A comprehensive, cross-platform path manipulation library.
///
/// ## Installing ##
///
/// Use [pub][] to install this package. Add the following to your
/// `pubspec.yaml` file.
///
///     dependencies:
///       path: any
///
/// Then run `pub install`.
///
/// For more information, see the [path package on pub.dartlang.org][pkg].
///
/// [pub]: http://pub.dartlang.org
/// [pkg]: http://pub.dartlang.org/packages/path
///
/// ## Usage ##
///
/// The path library was designed to be imported with a prefix, though you don't
/// have to if you don't want to:
///
///     import 'package:path/path.dart' as path;
///
/// The most common way to use the library is through the top-level functions.
/// These manipulate path strings based on your current working directory and
/// the path style (POSIX, Windows, or URLs) of the host platform. For example:
///
///     path.join("directory", "file.txt");
///
/// This calls the top-level [join] function to join "directory" and "file.txt"
/// using the current platform's directory separator.
///
/// If you want to work with paths for a specific platform regardless of the
/// underlying platform that the program is running on, you can create a
/// [Context] and give it an explicit [Style]:
///
///     var context = new path.Context(style: Style.windows);
///     context.join("directory", "file.txt");
///
/// This will join "directory" and "file.txt" using the Windows path separator,
/// even when the program is run on a POSIX machine.
library path;

import 'src/context.dart';
import 'src/style.dart';

export 'src/context.dart' hide createInternal;
export 'src/path_exception.dart';
export 'src/style.dart';

/// A default context for manipulating POSIX paths.
final posix = new Context(style: Style.posix);

/// A default context for manipulating Windows paths.
final windows = new Context(style: Style.windows);

/// A default context for manipulating URLs.
final url = new Context(style: Style.url);

/// The system path context.
///
/// This differs from a context created with [new Context] in that its
/// [Context.current] is always the current working directory, rather than being
/// set once when the context is created.
final Context context = createInternal();

/// Returns the [Style] of the current context.
///
/// This is the style that all top-level path functions will use.
Style get style => context.style;

/// Gets the path to the current working directory.
///
/// In the browser, this means the current URL, without the last file segment.
String get current {
  var uri = Uri.base;
  if (Style.platform == Style.url) {
    return uri.resolve('.').toString();
  } else {
    var path = uri.toFilePath();
    // Remove trailing '/' or '\'.
    int lastIndex = path.length - 1;
    assert(path[lastIndex] == '/' || path[lastIndex] == '\\');
    return path.substring(0, lastIndex);
  }
}

/// Gets the path separator for the current platform. This is `\` on Windows
/// and `/` on other platforms (including the browser).
String get separator => context.separator;

/// Creates a new path by appending the given path parts to [current].
/// Equivalent to [join()] with [current] as the first argument. Example:
///
///     path.absolute('path', 'to/foo'); // -> '/your/current/dir/path/to/foo'
String absolute(String part1, [String part2, String part3, String part4,
    String part5, String part6, String part7]) =>
        context.absolute(part1, part2, part3, part4, part5, part6, part7);

/// Gets the part of [path] after the last separator.
///
///     path.basename('path/to/foo.dart'); // -> 'foo.dart'
///     path.basename('path/to');          // -> 'to'
///
/// Trailing separators are ignored.
///
///     path.basename('path/to/'); // -> 'to'
String basename(String path) => context.basename(path);

/// Gets the part of [path] after the last separator, and without any trailing
/// file extension.
///
///     path.basenameWithoutExtension('path/to/foo.dart'); // -> 'foo'
///
/// Trailing separators are ignored.
///
///     path.basenameWithoutExtension('path/to/foo.dart/'); // -> 'foo'
String basenameWithoutExtension(String path) =>
    context.basenameWithoutExtension(path);

/// Gets the part of [path] before the last separator.
///
///     path.dirname('path/to/foo.dart'); // -> 'path/to'
///     path.dirname('path/to');          // -> 'path'
///
/// Trailing separators are ignored.
///
///     path.dirname('path/to/'); // -> 'path'
///
/// If an absolute path contains no directories, only a root, then the root
/// is returned.
///
///     path.dirname('/');  // -> '/' (posix)
///     path.dirname('c:\');  // -> 'c:\' (windows)
///
/// If a relative path has no directories, then '.' is returned.
///
///     path.dirname('foo');  // -> '.'
///     path.dirname('');  // -> '.'
String dirname(String path) => context.dirname(path);

/// Gets the file extension of [path]: the portion of [basename] from the last
/// `.` to the end (including the `.` itself).
///
///     path.extension('path/to/foo.dart');    // -> '.dart'
///     path.extension('path/to/foo');         // -> ''
///     path.extension('path.to/foo');         // -> ''
///     path.extension('path/to/foo.dart.js'); // -> '.js'
///
/// If the file name starts with a `.`, then that is not considered the
/// extension:
///
///     path.extension('~/.bashrc');    // -> ''
///     path.extension('~/.notes.txt'); // -> '.txt'
String extension(String path) => context.extension(path);

// TODO(nweiz): add a UNC example for Windows once issue 7323 is fixed.
/// Returns the root of [path], if it's absolute, or the empty string if it's
/// relative.
///
///     // Unix
///     path.rootPrefix('path/to/foo'); // -> ''
///     path.rootPrefix('/path/to/foo'); // -> '/'
///
///     // Windows
///     path.rootPrefix(r'path\to\foo'); // -> ''
///     path.rootPrefix(r'C:\path\to\foo'); // -> r'C:\'
///
///     // URL
///     path.rootPrefix('path/to/foo'); // -> ''
///     path.rootPrefix('http://dartlang.org/path/to/foo');
///       // -> 'http://dartlang.org'
String rootPrefix(String path) => context.rootPrefix(path);

/// Returns `true` if [path] is an absolute path and `false` if it is a
/// relative path.
///
/// On POSIX systems, absolute paths start with a `/` (forward slash). On
/// Windows, an absolute path starts with `\\`, or a drive letter followed by
/// `:/` or `:\`. For URLs, absolute paths either start with a protocol and
/// optional hostname (e.g. `http://dartlang.org`, `file://`) or with a `/`.
///
/// URLs that start with `/` are known as "root-relative", since they're
/// relative to the root of the current URL. Since root-relative paths are still
/// absolute in every other sense, [isAbsolute] will return true for them. They
/// can be detected using [isRootRelative].
bool isAbsolute(String path) => context.isAbsolute(path);

/// Returns `true` if [path] is a relative path and `false` if it is absolute.
/// On POSIX systems, absolute paths start with a `/` (forward slash). On
/// Windows, an absolute path starts with `\\`, or a drive letter followed by
/// `:/` or `:\`.
bool isRelative(String path) => context.isRelative(path);

/// Returns `true` if [path] is a root-relative path and `false` if it's not.
///
/// URLs that start with `/` are known as "root-relative", since they're
/// relative to the root of the current URL. Since root-relative paths are still
/// absolute in every other sense, [isAbsolute] will return true for them. They
/// can be detected using [isRootRelative].
///
/// No POSIX and Windows paths are root-relative.
bool isRootRelative(String path) => context.isRootRelative(path);

/// Joins the given path parts into a single path using the current platform's
/// [separator]. Example:
///
///     path.join('path', 'to', 'foo'); // -> 'path/to/foo'
///
/// If any part ends in a path separator, then a redundant separator will not
/// be added:
///
///     path.join('path/', 'to', 'foo'); // -> 'path/to/foo
///
/// If a part is an absolute path, then anything before that will be ignored:
///
///     path.join('path', '/to', 'foo'); // -> '/to/foo'
String join(String part1, [String part2, String part3, String part4,
    String part5, String part6, String part7, String part8]) =>
        context.join(part1, part2, part3, part4, part5, part6, part7, part8);

/// Joins the given path parts into a single path using the current platform's
/// [separator]. Example:
///
///     path.joinAll(['path', 'to', 'foo']); // -> 'path/to/foo'
///
/// If any part ends in a path separator, then a redundant separator will not
/// be added:
///
///     path.joinAll(['path/', 'to', 'foo']); // -> 'path/to/foo
///
/// If a part is an absolute path, then anything before that will be ignored:
///
///     path.joinAll(['path', '/to', 'foo']); // -> '/to/foo'
///
/// For a fixed number of parts, [join] is usually terser.
String joinAll(Iterable<String> parts) => context.joinAll(parts);

// TODO(nweiz): add a UNC example for Windows once issue 7323 is fixed.
/// Splits [path] into its components using the current platform's [separator].
///
///     path.split('path/to/foo'); // -> ['path', 'to', 'foo']
///
/// The path will *not* be normalized before splitting.
///
///     path.split('path/../foo'); // -> ['path', '..', 'foo']
///
/// If [path] is absolute, the root directory will be the first element in the
/// array. Example:
///
///     // Unix
///     path.split('/path/to/foo'); // -> ['/', 'path', 'to', 'foo']
///
///     // Windows
///     path.split(r'C:\path\to\foo'); // -> [r'C:\', 'path', 'to', 'foo']
///
///     // Browser
///     path.split('http://dartlang.org/path/to/foo');
///       // -> ['http://dartlang.org', 'path', 'to', 'foo']
List<String> split(String path) => context.split(path);

/// Normalizes [path], simplifying it by handling `..`, and `.`, and
/// removing redundant path separators whenever possible.
///
///     path.normalize('path/./to/..//file.text'); // -> 'path/file.txt'
String normalize(String path) => context.normalize(path);

/// Attempts to convert [path] to an equivalent relative path from the current
/// directory.
///
///     // Given current directory is /root/path:
///     path.relative('/root/path/a/b.dart'); // -> 'a/b.dart'
///     path.relative('/root/other.dart'); // -> '../other.dart'
///
/// If the [from] argument is passed, [path] is made relative to that instead.
///
///     path.relative('/root/path/a/b.dart',
///         from: '/root/path'); // -> 'a/b.dart'
///     path.relative('/root/other.dart',
///         from: '/root/path'); // -> '../other.dart'
///
/// If [path] and/or [from] are relative paths, they are assumed to be relative
/// to the current directory.
///
/// Since there is no relative path from one drive letter to another on Windows,
/// or from one hostname to another for URLs, this will return an absolute path
/// in those cases.
///
///     // Windows
///     path.relative(r'D:\other', from: r'C:\home'); // -> 'D:\other'
///
///     // URL
///     path.relative('http://dartlang.org', from: 'http://pub.dartlang.org');
///       // -> 'http://dartlang.org'
String relative(String path, {String from}) =>
    context.relative(path, from: from);

/// Returns `true` if [child] is a path beneath `parent`, and `false` otherwise.
///
///     path.isWithin('/root/path', '/root/path/a'); // -> true
///     path.isWithin('/root/path', '/root/other'); // -> false
///     path.isWithin('/root/path', '/root/path') // -> false
bool isWithin(String parent, String child) => context.isWithin(parent, child);

/// Removes a trailing extension from the last part of [path].
///
///     withoutExtension('path/to/foo.dart'); // -> 'path/to/foo'
String withoutExtension(String path) => context.withoutExtension(path);

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
String fromUri(uri) => context.fromUri(uri);

/// Returns the URI that represents [path].
///
/// For POSIX and Windows styles, this will return a `file:` URI. For the URL
/// style, this will just convert [path] to a [Uri].
///
///     // POSIX
///     path.toUri('/path/to/foo')
///       // -> Uri.parse('file:///path/to/foo')
///
///     // Windows
///     path.toUri(r'C:\path\to\foo')
///       // -> Uri.parse('file:///C:/path/to/foo')
///
///     // URL
///     path.toUri('http://dartlang.org/path/to/foo')
///       // -> Uri.parse('http://dartlang.org/path/to/foo')
///
/// If [path] is relative, a relative URI will be returned.
///
///     path.toUri('path/to/foo')
///       // -> Uri.parse('path/to/foo')
Uri toUri(String path) => context.toUri(path);

/// Returns a terse, human-readable representation of [uri].
///
/// [uri] can be a [String] or a [Uri]. If it can be made relative to the
/// current working directory, that's done. Otherwise, it's returned as-is. This
/// gracefully handles non-`file:` URIs for [Style.posix] and [Style.windows].
///
/// The returned value is meant for human consumption, and may be either URI-
/// or path-formatted.
///
///     // POSIX at "/root/path"
///     path.prettyUri('file:///root/path/a/b.dart'); // -> 'a/b.dart'
///     path.prettyUri('http://dartlang.org/'); // -> 'http://dartlang.org'
///
///     // Windows at "C:\root\path"
///     path.prettyUri('file:///C:/root/path/a/b.dart'); // -> r'a\b.dart'
///     path.prettyUri('http://dartlang.org/'); // -> 'http://dartlang.org'
///
///     // URL at "http://dartlang.org/root/path"
///     path.prettyUri('http://dartlang.org/root/path/a/b.dart');
///         // -> r'a/b.dart'
///     path.prettyUri('file:///root/path'); // -> 'file:///root/path'
String prettyUri(uri) => context.prettyUri(uri);
