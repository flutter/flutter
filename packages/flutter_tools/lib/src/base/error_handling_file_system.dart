// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io' as io show Directory, File, Link;

import 'package:file/file.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p; // ignore: package_path_import

import '../globals.dart' as globals;
import 'common.dart' show throwToolExit;

// The Flutter tool hits file system errors that only the end-user can address.
// We would like these errors to not hit crash logging. In these cases, we
// should exit gracefully and provide potentially useful advice. For example, if
// a write fails because the target device is full, we can explain that with a
// ToolExit and a message that is more clear than the FileSystemException by
// itself.

/// A [FileSystem] that throws a [ToolExit] on certain errors.
///
/// If a [FileSystem] error is not caused by the Flutter tool, and can only be
/// addressed by the user, it should be caught by this [FileSystem] and thrown
/// as a [ToolExit] using [throwToolExit].
///
/// Cf. If there is some hope that the tool can continue when an operation fails
/// with an error, then that error/operation should not be handled here. For
/// example, the tool should gernerally be able to continue executing even if it
/// fails to delete a file.
class ErrorHandlingFileSystem extends ForwardingFileSystem {
  ErrorHandlingFileSystem(FileSystem delegate) : super(delegate);

  @visibleForTesting
  FileSystem get fileSystem => delegate;

  @override
  File file(dynamic path) => ErrorHandlingFile(delegate, delegate.file(path));

  // Caching the path context here and clearing when the currentDirectory setter
  // is updated works since the flutter tool restricts usage of dart:io directly
  // via the forbidden import tests. Otherwise, the path context's current
  // working directory might get out of sync, leading to unexpected results from
  // methods like `path.relative`.
  @override
  p.Context get path => _cachedPath ??= delegate.path;
  p.Context _cachedPath;

  @override
  set currentDirectory(dynamic path) {
    _cachedPath = null;
    delegate.currentDirectory = path;
  }
}

class ErrorHandlingFile
    extends ForwardingFileSystemEntity<File, io.File>
    with ForwardingFile {
  ErrorHandlingFile(this.fileSystem, this.delegate);

  @override
  final io.File delegate;

  @override
  final FileSystem fileSystem;

  @override
  File wrapFile(io.File delegate) =>
    ErrorHandlingFile(fileSystem, delegate);

  @override
  Directory wrapDirectory(io.Directory delegate) =>
    ErrorHandlingDirectory(fileSystem, delegate);

  @override
  Link wrapLink(io.Link delegate) =>
    ErrorHandlingLink(fileSystem, delegate);

  @override
  Future<File> writeAsBytes(
    List<int> bytes, {
    FileMode mode = FileMode.write,
    bool flush = false,
  }) async {
    return _run<File>(
      () async => wrap(await delegate.writeAsBytes(
        bytes,
        mode: mode,
        flush: flush,
      )),
      failureMessage: 'Flutter failed to write to a file at "${delegate.path}"',
    );
  }

  @override
  void writeAsBytesSync(
    List<int> bytes, {
    FileMode mode = FileMode.write,
    bool flush = false,
  }) {
    _runSync<void>(
      () => delegate.writeAsBytesSync(bytes, mode: mode, flush: flush),
      failureMessage: 'Flutter failed to write to a file at "${delegate.path}"',
    );
  }

  @override
  Future<File> writeAsString(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) async {
    return _run<File>(
      () async => wrap(await delegate.writeAsString(
        contents,
        mode: mode,
        encoding: encoding,
        flush: flush,
      )),
      failureMessage: 'Flutter failed to write to a file at "${delegate.path}"',
    );
  }

  @override
  void writeAsStringSync(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) {
    _runSync<void>(
      () => delegate.writeAsStringSync(
        contents,
        mode: mode,
        encoding: encoding,
        flush: flush,
      ),
      failureMessage: 'Flutter failed to write to a file at "${delegate.path}"',
    );
  }

  Future<T> _run<T>(Future<T> Function() op, { String failureMessage }) async {
    try {
      return await op();
    } on FileSystemException catch (e) {
      if (globals.platform.isWindows) {
        _handleWindowsException(e, failureMessage);
      }
      rethrow;
    }
  }

  T _runSync<T>(T Function() op, { String failureMessage }) {
    try {
      return op();
    } on FileSystemException catch (e) {
      if (globals.platform.isWindows) {
        _handleWindowsException(e, failureMessage);
      }
      rethrow;
    }
  }

  void _handleWindowsException(FileSystemException e, String message) {
    // From:
    // https://docs.microsoft.com/en-us/windows/win32/debug/system-error-codes
    const int kDeviceFull = 112;
    const int kUserMappedSectionOpened = 1224;
    final int errorCode = e.osError?.errorCode ?? 0;
    // Catch errors and bail when:
    switch (errorCode) {
      case kDeviceFull:
        throwToolExit(
          '$message. The target device is full.'
          '\n$e\n'
          'Free up space and try again.',
        );
        break;
      case kUserMappedSectionOpened:
        throwToolExit(
          '$message. The file is being used by another program.'
          '\n$e\n'
          'Do you have an antivirus program running? '
          'Try disabling your antivirus program and try again.',
        );
        break;
      default:
        // Caller must rethrow the exception.
        break;
    }
  }
}

class ErrorHandlingDirectory
    extends ForwardingFileSystemEntity<Directory, io.Directory>
    with ForwardingDirectory<Directory> {
  ErrorHandlingDirectory(this.fileSystem, this.delegate);

  @override
  final io.Directory delegate;

  @override
  final FileSystem fileSystem;

  @override
  File wrapFile(io.File delegate) =>
    ErrorHandlingFile(fileSystem, delegate);

  @override
  Directory wrapDirectory(io.Directory delegate) =>
    ErrorHandlingDirectory(fileSystem, delegate);

  @override
  Link wrapLink(io.Link delegate) =>
    ErrorHandlingLink(fileSystem, delegate);

  // For the childEntity methods, we first obtain an instance of the entity
  // from the underlying file system, then invoke childEntity() on it, then
  // wrap in the ErrorHandling version.
  @override
  Directory childDirectory(String basename) =>
    wrapDirectory(fileSystem.directory(delegate).childDirectory(basename));

  @override
  File childFile(String basename) =>
    wrapFile(fileSystem.directory(delegate).childFile(basename));

  @override
  Link childLink(String basename) =>
    wrapLink(fileSystem.directory(delegate).childLink(basename));
}

class ErrorHandlingLink
    extends ForwardingFileSystemEntity<Link, io.Link>
    with ForwardingLink {
  ErrorHandlingLink(this.fileSystem, this.delegate);

  @override
  final io.Link delegate;

  @override
  final FileSystem fileSystem;

  @override
  File wrapFile(io.File delegate) =>
    ErrorHandlingFile(fileSystem, delegate);

  @override
  Directory wrapDirectory(io.Directory delegate) =>
    ErrorHandlingDirectory(fileSystem, delegate);

  @override
  Link wrapLink(io.Link delegate) =>
    ErrorHandlingLink(fileSystem, delegate);
}
