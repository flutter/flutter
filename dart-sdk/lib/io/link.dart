// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

/// References to filesystem links.
@pragma("vm:entry-point")
abstract interface class Link implements FileSystemEntity {
  /// Creates a Link object.
  @pragma("vm:entry-point")
  factory Link(String path) {
    final IOOverrides? overrides = IOOverrides.current;
    if (overrides == null) {
      return new _Link(path);
    }
    return overrides.createLink(path);
  }

  @pragma("vm:entry-point")
  factory Link.fromRawPath(Uint8List rawPath) {
    // TODO(bkonyi): handle overrides
    return new _Link.fromRawPath(rawPath);
  }

  /// Creates a [Link] object.
  ///
  /// If [path] is a relative path, it will be interpreted relative to the
  /// current working directory (see [Directory.current]), when used.
  ///
  /// If [path] is an absolute path, it will be immune to changes to the
  /// current working directory.
  factory Link.fromUri(Uri uri) => new Link(uri.toFilePath());

  /// Creates a symbolic link in the file system.
  ///
  /// The created link will point to the path at [target], whether that path
  /// exists or not.
  ///
  /// Returns a `Future<Link>` that completes with
  /// the link when it has been created. If the link path already exists,
  /// the future will complete with an error.
  ///
  /// If [recursive] is `false`, the default, the link is created
  /// only if all directories in its path exist.
  /// If [recursive] is `true`, all non-existing parent paths
  /// are created first. The directories in the path of [target] are
  /// not affected, unless they are also in [path].
  ///
  /// On the Windows platform, this call will create a true symbolic link
  /// instead of a junction. Windows treats links to files and links to
  /// directories as different and non-interchangable kinds of links.
  /// Each link is either a file-link or a directory-link, and the type is
  /// chosen when the link is created, and the link then counts as either a
  /// file or directory for most purposes. Different Win32 API calls are
  /// used to manipulate each. For example, the `DeleteFile` function is
  /// used to delete links to files, and `RemoveDirectory` must be used to
  /// delete links to directories.
  ///
  /// The created Windows symbolic link will match the type of the [target],
  /// if [target] exists, otherwise a file-link is created. The type of the
  /// created link will not change if [target] is later replaced by something
  /// of a different type, but then the link will not be resolvable by
  /// [resolveSymbolicLinks].
  ///
  /// In order to create a symbolic link on Windows, Dart must be run in
  /// Administrator mode or the system must have Developer Mode enabled,
  /// otherwise a [FileSystemException] will be raised with
  /// `ERROR_PRIVILEGE_NOT_HELD` set as the errno when this call is made.
  ///
  /// On other platforms, the POSIX `symlink()` call is used to make a symbolic
  /// link containing the string [target]. If [target] is a relative path,
  /// it will be interpreted relative to the directory containing the link.
  Future<Link> create(String target, {bool recursive = false});

  /// Creates a symbolic link in the file system.
  ///
  /// The created link will point to the path at [target], whether that path
  /// exists or not.
  ///
  /// If the link path already exists, an exception will be thrown.
  ///
  /// If [recursive] is `false`, the default, the link is created only if all
  /// directories in its path exist. If [recursive] is `true`, all
  /// non-existing parent paths are created first. The directories in
  /// the path of [target] are not affected, unless they are also in [path].
  ///
  /// On the Windows platform, this call will create a true symbolic link
  /// instead of a junction. Windows treats links to files and links to
  /// directories as different and non-interchangable kinds of links.
  /// Each link is either a file-link or a directory-link, and the type is
  /// chosen when the link is created, and the link then counts as either a
  /// file or directory for most purposes. Different Win32 API calls are
  /// used to manipulate each.  For example, the `DeleteFile` function is
  /// used to delete links to files, and `RemoveDirectory` must be used to
  /// delete links to directories.
  ///
  /// The created Windows symbolic link will match the type of the [target],
  /// if [target] exists, otherwise a file-link is created. The type of the
  /// created link will not change if [target] is later replaced by something
  /// of a different type, but then the link will not be resolvable by
  /// [resolveSymbolicLinks].
  ///
  /// In order to create a symbolic link on Windows, Dart must be run in
  /// Administrator mode or the system must have Developer Mode enabled,
  /// otherwise a [FileSystemException] will be raised with
  /// `ERROR_PRIVILEGE_NOT_HELD` set as the errno when this call is made.
  ///
  /// On other platforms, the POSIX `symlink()` call is used to make a symbolic
  /// link containing the string [target]. If [target] is a relative path,
  /// it will be interpreted relative to the directory containing the link.
  void createSync(String target, {bool recursive = false});

  /// Synchronously updates an existing link.
  ///
  /// Deletes the existing link at [path] and uses [createSync] to create a new
  /// link to [target]. Throws [PathNotFoundException] if the original link
  /// does not exist or any [FileSystemException] that [deleteSync] or
  /// [createSync] can throw.
  void updateSync(String target);

  /// Updates an existing link.
  ///
  /// Deletes the existing link at [path] and creates a new link to [target],
  /// using [create].
  ///
  /// Returns a future which completes with this `Link` if successful,
  /// and with a [PathNotFoundException] if there is no existing link at [path],
  /// or with any [FileSystemException] that [delete] or [create] can throw.
  Future<Link> update(String target);

  Future<String> resolveSymbolicLinks();

  String resolveSymbolicLinksSync();

  /// Renames this link.
  ///
  /// Returns a `Future<Link>` that completes with a [Link]
  /// for the renamed link.
  ///
  /// If [newPath] identifies an existing file or link, that entity is removed
  /// first. If [newPath] identifies an existing directory then the future
  /// completes with a [FileSystemException].
  Future<Link> rename(String newPath);

  /// Synchronously renames this link.
  ///
  /// Returns a [Link] instance for the renamed link.
  ///
  /// If [newPath] identifies an existing file or link, that entity is removed
  /// first. If [newPath] identifies an existing directory then
  /// [FileSystemException] is thrown.
  Link renameSync(String newPath);

  /// Deletes this [Link].
  ///
  /// If [recursive] is `false`:
  ///
  ///  * If [path] corresponds to a link then that path is deleted. Otherwise,
  ///    [delete] completes with a [FileSystemException].
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
  /// If this [Link] cannot be deleted, then [delete] completes with a
  /// [FileSystemException].
  Future<FileSystemEntity> delete({bool recursive = false});

  /// Synchronously deletes this [Link].
  ///
  /// If [recursive] is `false`:
  ///
  ///  * If [path] corresponds to a link then that path is deleted. Otherwise,
  ///    [delete] throws a [FileSystemException].
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
  /// If this [Link] cannot be deleted, then [delete] throws a
  /// [FileSystemException].
  void deleteSync({bool recursive = false});

  /// A [Link] instance whose path is the absolute path to this [Link].
  ///
  /// The absolute path is computed by prefixing
  /// a relative path with the current working directory, or returning
  /// an absolute path unchanged.
  Link get absolute;

  /// Gets the target of the link.
  ///
  /// Returns a future that completes with the path to the target.
  ///
  /// If the returned target is a relative path, it is relative to the
  /// directory containing the link.
  ///
  /// If the link does not exist, or is not a link, the future completes with
  /// a [FileSystemException].
  Future<String> target();

  /// Synchronously gets the target of the link.
  ///
  /// Returns the path to the target.
  ///
  /// If the returned target is a relative path, it is relative to the
  /// directory containing the link.
  ///
  /// If the link does not exist, or is not a link,
  /// throws a [FileSystemException].
  String targetSync();
}

class _Link extends FileSystemEntity implements Link {
  final String _path;
  final Uint8List _rawPath;

  _Link(String path)
      : _path = path,
        _rawPath = FileSystemEntity._toUtf8Array(path);

  _Link.fromRawPath(Uint8List rawPath)
      : _rawPath = FileSystemEntity._toNullTerminatedUtf8Array(rawPath),
        _path = FileSystemEntity._toStringFromUtf8Array(rawPath);

  String get path => _path;

  String toString() => "Link: '$path'";

  Future<bool> exists() => FileSystemEntity._isLinkRaw(_rawPath);

  bool existsSync() => FileSystemEntity._isLinkRawSync(_rawPath);

  Link get absolute => isAbsolute ? this : _Link(_absolutePath);

  Future<Link> create(String target, {bool recursive = false}) {
    var result =
        recursive ? parent.create(recursive: true) : new Future.value(null);
    return result
        .then((_) => _File._dispatchWithNamespace(
            _IOService.fileCreateLink, [null, _rawPath, target]))
        .then((response) {
      _checkForErrorResponse(
          response, "Cannot create link to target '$target'", path);
      return this;
    });
  }

  void createSync(String target, {bool recursive = false}) {
    if (recursive) {
      parent.createSync(recursive: true);
    }
    var result = _File._createLink(_Namespace._namespace, _rawPath, target);
    throwIfError(result, "Cannot create link", path);
  }

  void updateSync(String target) {
    // TODO(12414): Replace with atomic update, where supported by platform.
    // Atomically changing a link can be done by creating the new link, with
    // a different name, and using the rename() posix call to move it to
    // the old name atomically.
    deleteSync();
    createSync(target);
  }

  Future<Link> update(String target) {
    // TODO(12414): Replace with atomic update, where supported by platform.
    // Atomically changing a link can be done by creating the new link, with
    // a different name, and using the rename() posix call to move it to
    // the old name atomically.
    return delete().then<Link>((_) => create(target));
  }

  Future<Link> _delete({bool recursive = false}) {
    if (recursive) {
      return new Directory.fromRawPath(_rawPath)
          .delete(recursive: true)
          .then((_) => this);
    }
    return _File._dispatchWithNamespace(
        _IOService.fileDeleteLink, [null, _rawPath]).then((response) {
      _checkForErrorResponse(response, "Cannot delete link", path);
      return this;
    });
  }

  void _deleteSync({bool recursive = false}) {
    if (recursive) {
      return new Directory.fromRawPath(_rawPath).deleteSync(recursive: true);
    }
    var result = _File._deleteLinkNative(_Namespace._namespace, _rawPath);
    throwIfError(result, "Cannot delete link", path);
  }

  Future<Link> rename(String newPath) {
    return _File._dispatchWithNamespace(
        _IOService.fileRenameLink, [null, _rawPath, newPath]).then((response) {
      _checkForErrorResponse(
          response, "Cannot rename link to '$newPath'", path);
      return new Link(newPath);
    });
  }

  Link renameSync(String newPath) {
    var result = _File._renameLink(_Namespace._namespace, _rawPath, newPath);
    throwIfError(result, "Cannot rename link '$path' to '$newPath'");
    return new Link(newPath);
  }

  Future<String> target() {
    return _File._dispatchWithNamespace(
        _IOService.fileLinkTarget, [null, _rawPath]).then((response) {
      _checkForErrorResponse(response, "Cannot get target of link", path);
      return response as String;
    });
  }

  String targetSync() {
    var result = _File._linkTarget(_Namespace._namespace, _rawPath);
    throwIfError(result, "Cannot read link", path);
    return result;
  }

  static throwIfError(Object? result, String msg, [String path = ""]) {
    if (result is OSError) {
      throw FileSystemException._fromOSError(result, msg, path);
    }
  }
}
