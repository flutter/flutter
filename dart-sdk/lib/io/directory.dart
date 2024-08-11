// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

/// A reference to a directory (or _folder_) on the file system.
///
/// A [Directory] is an object holding a [path] on which operations can
/// be performed. The path to the directory can be [absolute] or relative.
/// It allows access to the [parent] directory,
/// since it is a [FileSystemEntity].
///
/// The [Directory] also provides static access to the system's temporary
/// file directory, [systemTemp], and the ability to access and change
/// the [current] directory.
///
/// Create a new [Directory] to give access the directory with the specified
/// path:
/// ```dart
/// var myDir = Directory('myDir');
/// ```
/// Most instance methods of [Directory] exist in both synchronous
/// and asynchronous variants, for example, [create] and [createSync].
/// Unless you have a specific reason for using the synchronous version
/// of a method, prefer the asynchronous version to avoid blocking your program.
///
/// ## Create a directory
///
/// The following code sample creates a directory using the [create] method.
/// By setting the `recursive` parameter to true, you can create the
/// named directory and all its necessary parent directories,
/// if they do not already exist.
/// ```dart
/// import 'dart:io';
///
/// void main() async {
///   // Creates dir/ and dir/subdir/.
///   var directory = await Directory('dir/subdir').create(recursive: true);
///   print(directory.path);
/// }
/// ```
/// ## List the entries of a directory
///
/// Use the [list] or [listSync] methods to get the files and directories
/// contained in a directory.
/// Set `recursive` to true to recursively list all subdirectories.
/// Set `followLinks` to true to follow symbolic links.
/// The list method returns a [Stream] of [FileSystemEntity] objects.
/// Listen on the stream to access each object as it is found:
/// ```dart
/// import 'dart:io';
///
/// void main() async {
///   // Get the system temp directory.
///   var systemTempDir = Directory.systemTemp;
///
///   // List directory contents, recursing into sub-directories,
///   // but not following symbolic links.
///   await for (var entity in
///       systemTempDir.list(recursive: true, followLinks: false)) {
///     print(entity.path);
///   }
/// }
/// ```
/// ## The use of asynchronous methods
///
/// I/O operations can block a program for some period of time while it waits for
/// the operation to complete. To avoid this, all
/// methods involving I/O have an asynchronous variant which returns a [Future].
/// This future completes when the I/O operation finishes. While the I/O
/// operation is in progress, the Dart program is not blocked,
/// and can perform other operations.
///
/// For example,
/// the [exists] method, which determines whether the directory exists,
/// returns a boolean value asynchronously using a [Future].
/// ```dart
/// import 'dart:io';
///
/// void main() async {
///   final myDir = Directory('dir');
///   var isThere = await myDir.exists();
///   print(isThere ? 'exists' : 'nonexistent');
/// }
/// ```
///
/// In addition to [exists], the [stat], [rename],
/// and other methods are also asynchronous.
///
/// ## Other resources
///
/// * The [Files and directories](https://dart.dev/guides/libraries/library-tour#files-and-directories)
///   section of the library tour.
///
/// * [Write Command-Line Apps](https://dart.dev/tutorials/server/cmdline),
///   a tutorial about writing command-line apps, includes information about
///   files and directories.
@pragma("vm:entry-point")
abstract interface class Directory implements FileSystemEntity {
  /// Gets the path of this directory.
  String get path;

  /// Creates a [Directory] object.
  ///
  /// If [path] is a relative path, it will be interpreted relative to the
  /// current working directory (see [Directory.current]), when used.
  ///
  /// If [path] is an absolute path, it will be immune to changes to the
  /// current working directory.
  @pragma("vm:entry-point")
  factory Directory(String path) {
    final IOOverrides? overrides = IOOverrides.current;
    if (overrides == null) {
      return new _Directory(path);
    }
    return overrides.createDirectory(path);
  }

  @pragma("vm:entry-point")
  factory Directory.fromRawPath(Uint8List path) {
    // TODO(bkonyi): Handle overrides.
    return new _Directory.fromRawPath(path);
  }

  /// Create a [Directory] from a URI.
  ///
  /// If [uri] cannot reference a directory this throws [UnsupportedError].
  factory Directory.fromUri(Uri uri) => new Directory(uri.toFilePath());

  /// Creates a directory object pointing to the current working
  /// directory.
  static Directory get current {
    final IOOverrides? overrides = IOOverrides.current;
    if (overrides == null) {
      return _Directory.current;
    }
    return overrides.getCurrentDirectory();
  }

  /// A [Uri] representing the directory's location.
  ///
  /// The URI's scheme is always "file" if the entity's [path] is
  /// absolute, otherwise the scheme will be empty and the URI relative.
  /// The URI's path always ends in a slash ('/').
  Uri get uri;

  /// Sets the current working directory of the Dart process.
  ///
  /// This affects all running isolates.
  /// The new value set can be either a [Directory] or a [String].
  ///
  /// The new value is passed to the OS's system call unchanged, so a
  /// relative path passed as the new working directory will be
  /// resolved by the OS.
  ///
  /// Note that setting the current working directory is a synchronous
  /// operation and that it changes the working directory of *all*
  /// isolates.
  ///
  /// Use this with care — especially when working with asynchronous
  /// operations and multiple isolates. Changing the working directory,
  /// while asynchronous operations are pending or when other isolates
  /// are working with the file system, can lead to unexpected results.
  static void set current(dynamic path) {
    // Disallow implicit casts to avoid bugs like
    // <https://github.com/dart-lang/sdk/issues/52140>.
    //
    // This can be removed if `strict-casts` is enabled.
    path as Object?;

    final IOOverrides? overrides = IOOverrides.current;
    if (overrides == null) {
      _Directory.current = path;
      return;
    }

    // IOOverrides.setCurrentDirectory accepts only a [String].
    overrides.setCurrentDirectory(switch (path) {
      String s => s,
      Directory d => d.path,
      _ => throw ArgumentError('${Error.safeToString(path)} is not a String or'
          ' Directory'),
    });
  }

  /// Creates the directory if it doesn't exist.
  ///
  /// If [recursive] is false, only the last directory in the path is
  /// created. If [recursive] is true, all non-existing path components
  /// are created. If the directory already exists nothing is done.
  ///
  /// Returns a `Future<Directory>` that completes with this
  /// directory once it has been created. If the directory cannot be
  /// created the future completes with an exception.
  Future<Directory> create({bool recursive = false});

  /// Synchronously creates the directory if it doesn't exist.
  ///
  /// If [recursive] is false, only the last directory in the path is
  /// created. If [recursive] is true, all non-existing path components
  /// are created. If the directory already exists nothing is done.
  ///
  /// If the directory cannot be created an exception is thrown.
  void createSync({bool recursive = false});

  /// The system temp directory.
  ///
  /// This is the directory provided by the operating system for creating
  /// temporary files and directories in.
  /// The location of the system temporary directory is platform-dependent,
  /// and may be controlled by an environment variable on some platforms.
  static Directory get systemTemp {
    final IOOverrides? overrides = IOOverrides.current;
    if (overrides == null) {
      return _Directory.systemTemp;
    }
    return overrides.getSystemTempDirectory();
  }

  /// Creates a temporary directory in this directory.
  ///
  /// Additional random characters are appended to [prefix]
  /// to produce a unique directory name.
  /// If [prefix] is missing or null, the empty string is used as [prefix].
  ///
  /// Returns a `Future<Directory>` that completes with the newly
  /// created temporary directory.
  Future<Directory> createTemp([String? prefix]);

  /// Synchronously creates a temporary directory in this directory.
  ///
  /// Additional random characters are appended to [prefix] to produce
  /// a unique directory name. If [prefix] is missing or null, the empty
  /// string is used as [prefix].
  ///
  /// Returns the newly created temporary directory.
  Directory createTempSync([String? prefix]);

  Future<String> resolveSymbolicLinks();

  String resolveSymbolicLinksSync();

  /// Renames this directory.
  ///
  /// Returns a `Future<Directory>` that completes
  /// with a [Directory] for the renamed directory.
  ///
  /// If [newPath] identifies an existing directory, then the behavior is
  /// platform-specific. On all platforms, the future completes with a
  /// [FileSystemException] if the existing directory is not empty. On POSIX
  /// systems, if [newPath] identifies an existing empty directory then that
  /// directory is deleted before this directory is renamed.
  ///
  /// If [newPath] identifies an existing file or link, the operation
  /// fails and the future completes with a [FileSystemException].
  Future<Directory> rename(String newPath);

  /// Synchronously renames this directory.
  ///
  /// Returns a [Directory] for the renamed directory.
  ///
  /// If [newPath] identifies an existing directory, then the behavior is
  /// platform-specific. On all platforms, a [FileSystemException] is thrown
  /// if the existing directory is not empty. On POSIX systems, if [newPath]
  /// identifies an existing empty directory then that directory is deleted
  /// before this directory is renamed.
  ///
  /// If [newPath] identifies an existing file or link the operation
  /// fails and a [FileSystemException] is thrown.
  Directory renameSync(String newPath);

  /// Deletes this [Directory].
  ///
  /// If [recursive] is `false`:
  ///
  ///  * If [path] corresponds to an empty directory, then that directory is
  ///    deleted. If [path] corresponds to a link, and that link resolves
  ///    to a directory, then the link at [path] will be deleted. In all
  ///    other cases, [delete] completes with a [FileSystemException].
  ///
  /// If [recursive] is `true`:
  ///
  ///  * The [FileSystemEntity] at [path] is deleted regardless of type. If
  ///    [path] corresponds to a file or link, then that file or link is
  ///    deleted. If [path] corresponds to a directory, then it and all
  ///    sub-directories and files in those directories are deleted. Links
  ///    are not followed when deleting recursively. Only the link is deleted,
  ///    not its target. This behavior allows [delete] to be used to
  ///    unconditionally delete any file system object.
  ///
  /// If this [Directory] cannot be deleted, then [delete] completes with a
  /// [FileSystemException].
  Future<FileSystemEntity> delete({bool recursive = false});

  /// Synchronously deletes this [Directory].
  ///
  /// If [recursive] is `false`:
  ///
  ///  * If [path] corresponds to an empty directory, then that directory is
  ///    deleted. If [path] corresponds to a link, and that link resolves
  ///    to a directory, then the link at [path] will be deleted. In all
  ///    other cases, [delete] throws a [FileSystemException].
  ///
  /// If [recursive] is `true`:
  ///
  ///  * The [FileSystemEntity] at [path] is deleted regardless of type. If
  ///    [path] corresponds to a file or link, then that file or link is
  ///    deleted. If [path] corresponds to a directory, then it and all
  ///    sub-directories and files in those directories are deleted. Links
  ///    are not followed when deleting recursively. Only the link is deleted,
  ///    not its target. This behavior allows [delete] to be used to
  ///    unconditionally delete any file system object.
  ///
  /// If this [Directory] cannot be deleted, then [delete] throws a
  /// [FileSystemException].
  void deleteSync({bool recursive = false});

  /// A [Directory] whose path is the absolute path of this [Directory].
  ///
  /// The absolute path is computed by prefixing
  /// a relative path with the current working directory,
  /// or by returning an absolute path unchanged.
  Directory get absolute;

  /// Lists the sub-directories and files of this [Directory].
  ///
  /// Optionally recurses into sub-directories.
  ///
  /// If [followLinks] is `false`, then any symbolic links found
  /// are reported as [Link] objects, rather than as directories or files,
  /// and are not recursed into.
  ///
  /// If [followLinks] is `true`, then working links are reported as
  /// directories or files, depending on what they point to,
  /// and links to directories are recursed into if [recursive] is `true`.
  ///
  /// Broken links are reported as [Link] objects.
  ///
  /// If a symbolic link makes a loop in the file system, then a recursive
  /// listing will not follow a link twice in the
  /// same recursive descent, but will report it as a [Link]
  /// the second time it is seen.
  ///
  /// The result is a [Stream] of [FileSystemEntity] objects for the
  /// directories, files, and links. The [Stream] will be in an arbitrary
  /// order and does not include the special entries `'.'` and `'..'`.
  Stream<FileSystemEntity> list(
      {bool recursive = false, bool followLinks = true});

  /// Lists the sub-directories and files of this [Directory].
  /// Optionally recurses into sub-directories.
  ///
  /// If [followLinks] is `false`, then any symbolic links found
  /// are reported as [Link] objects, rather than as directories or files,
  /// and are not recursed into.
  ///
  /// If [followLinks] is `true`, then working links are reported as
  /// directories or files, depending on what they point to,
  /// and links to directories are recursed into if [recursive] is `true`.
  ///
  /// Broken links are reported as [Link] objects.
  ///
  /// If a link makes a loop in the file system, then a recursive
  /// listing will not follow a link twice in the
  /// same recursive descent, but will report it as a [Link]
  /// the second time it is seen.
  ///
  /// Returns a [List] containing [FileSystemEntity] objects for the
  /// directories, files, and links. The [List] will be in an arbitrary order
  /// and does not include the special entries `'.'` and `'..'`.
  List<FileSystemEntity> listSync(
      {bool recursive = false, bool followLinks = true});

  /// Returns a human readable representation of this [Directory].
  String toString();
}
