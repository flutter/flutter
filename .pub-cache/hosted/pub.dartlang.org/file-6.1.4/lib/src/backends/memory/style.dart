// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:file/file.dart';
import 'package:path/path.dart' as p;

/// Class that represents the path style that a memory file system should
/// adopt.
///
/// This is primarily useful if you want to test how your code will behave
/// when faced with particular paths or particular path separator characters.
/// For instance, you may want to test that your code will work on Windows,
/// while still using a memory file system in order to gain hermeticity in your
/// tests.
abstract class FileSystemStyle {
  const FileSystemStyle._();

  /// Mimics the Unix file system style.
  ///
  /// * This style does not have the notion of drives
  /// * All file system paths are rooted at `/`
  /// * The path separator is `/`
  ///
  /// An example path in this style is `/path/to/file`.
  static const FileSystemStyle posix = _Posix();

  /// Mimics the Windows file system style.
  ///
  /// * This style mounts its root folder on a single root drive (`C:`)
  /// * All file system paths are rooted at `C:\`
  /// * The path separator is `\`
  ///
  /// An example path in this style is `C:\path\to\file`.
  static const FileSystemStyle windows = _Windows();

  /// The drive upon which the root directory is mounted.
  ///
  /// While real-world file systems that have the notion of drives will support
  /// multiple drives per system, memory file system will only support one
  /// root drive.
  ///
  /// This will be the empty string for styles that don't have the notion of
  /// drives (e.g. [posix]).
  String get drive;

  /// The String that represents the delineation between a directory and its
  /// children.
  String get separator;

  /// The string that represents the root of the file system.
  ///
  /// Memory file system is always single-rooted.
  String get root => '$drive$separator';

  /// Gets an object useful for manipulating paths in this style.
  ///
  /// Relative path manipulations will be relative to the specified [path].
  p.Context contextFor(String path);
}

class _Posix extends FileSystemStyle {
  const _Posix() : super._();

  @override
  String get drive => '';

  @override
  String get separator {
    return p.Style.posix.separator; // ignore: deprecated_member_use
  }

  @override
  p.Context contextFor(String path) =>
      p.Context(style: p.Style.posix, current: path);
}

class _Windows extends FileSystemStyle {
  const _Windows() : super._();

  @override
  String get drive => 'C:';

  @override
  String get separator {
    return p.Style.windows.separator; // ignore: deprecated_member_use
  }

  @override
  p.Context contextFor(String path) =>
      p.Context(style: p.Style.windows, current: path);
}

/// A file system that supports different styles.
abstract class StyleableFileSystem implements FileSystem {
  /// The style used by this file system.
  FileSystemStyle get style;
}
