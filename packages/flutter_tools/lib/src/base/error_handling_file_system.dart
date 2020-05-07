// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io' as io show Directory, File, Link;

import 'package:file/file.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p; // ignore: package_path_import

import 'common.dart' show throwToolExit;
import 'platform.dart';

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
  ErrorHandlingFileSystem({
    @required FileSystem delegate,
    @required Platform platform,
  }) :
      assert(delegate != null),
      assert(platform != null),
      _platform = platform,
      super(delegate);

  @visibleForTesting
  FileSystem get fileSystem => delegate;

  final Platform _platform;

  @override
  File file(dynamic path) => ErrorHandlingFile(
    platform: _platform,
    fileSystem: delegate,
    delegate: delegate.file(path),
  );

  @override
  Directory directory(dynamic path) => ErrorHandlingDirectory(
    platform: _platform,
    fileSystem: delegate,
    delegate: delegate.directory(path),
  );

  @override
  Link link(dynamic path) => ErrorHandlingLink(
    platform: _platform,
    fileSystem: delegate,
    delegate: delegate.link(path),
  );

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

  @override
  String toString() => delegate.toString();
}

class ErrorHandlingFile
    extends ForwardingFileSystemEntity<File, io.File>
    with ForwardingFile {
  ErrorHandlingFile({
    @required Platform platform,
    @required this.fileSystem,
    @required this.delegate,
  }) :
    assert(platform != null),
    assert(fileSystem != null),
    assert(delegate != null),
    _platform = platform;

  @override
  final io.File delegate;

  @override
  final FileSystem fileSystem;

  final Platform _platform;

  @override
  File wrapFile(io.File delegate) => ErrorHandlingFile(
    platform: _platform,
    fileSystem: fileSystem,
    delegate: delegate,
  );

  @override
  Directory wrapDirectory(io.Directory delegate) => ErrorHandlingDirectory(
    platform: _platform,
    fileSystem: fileSystem,
    delegate: delegate,
  );

  @override
  Link wrapLink(io.Link delegate) => ErrorHandlingLink(
    platform: _platform,
    fileSystem: fileSystem,
    delegate: delegate,
  );

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
      platform: _platform,
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
      platform: _platform,
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
      platform: _platform,
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
      platform: _platform,
      failureMessage: 'Flutter failed to write to a file at "${delegate.path}"',
    );
  }

  @override
  String toString() => delegate.toString();
}

class ErrorHandlingDirectory
    extends ForwardingFileSystemEntity<Directory, io.Directory>
    with ForwardingDirectory<Directory> {
  ErrorHandlingDirectory({
    @required Platform platform,
    @required this.fileSystem,
    @required this.delegate,
  }) :
    assert(platform != null),
    assert(fileSystem != null),
    assert(delegate != null),
    _platform = platform;

  @override
  final io.Directory delegate;

  @override
  final FileSystem fileSystem;

  final Platform _platform;

  @override
  File wrapFile(io.File delegate) => ErrorHandlingFile(
    platform: _platform,
    fileSystem: fileSystem,
    delegate: delegate,
  );

  @override
  Directory wrapDirectory(io.Directory delegate) => ErrorHandlingDirectory(
    platform: _platform,
    fileSystem: fileSystem,
    delegate: delegate,
  );

  @override
  Link wrapLink(io.Link delegate) => ErrorHandlingLink(
    platform: _platform,
    fileSystem: fileSystem,
    delegate: delegate,
  );

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

  @override
  Future<Directory> createTemp([String prefix]) {
    return _run<Directory>(
      () async => wrap(await delegate.createTemp(prefix)),
      platform: _platform,
      failureMessage:
        'Flutter failed to create a temporary directory with prefix "$prefix"',
    );
  }

  @override
  Directory createTempSync([String prefix]) {
    return _runSync<Directory>(
      () => wrap(delegate.createTempSync(prefix)),
      platform: _platform,
      failureMessage:
        'Flutter failed to create a temporary directory with prefix "$prefix"',
    );
  }

  @override
  String toString() => delegate.toString();
}

class ErrorHandlingLink
    extends ForwardingFileSystemEntity<Link, io.Link>
    with ForwardingLink {
  ErrorHandlingLink({
    @required Platform platform,
    @required this.fileSystem,
    @required this.delegate,
  }) :
    assert(platform != null),
    assert(fileSystem != null),
    assert(delegate != null),
    _platform = platform;

  @override
  final io.Link delegate;

  @override
  final FileSystem fileSystem;

  final Platform _platform;

  @override
  File wrapFile(io.File delegate) => ErrorHandlingFile(
    platform: _platform,
    fileSystem: fileSystem,
    delegate: delegate,
  );

  @override
  Directory wrapDirectory(io.Directory delegate) => ErrorHandlingDirectory(
    platform: _platform,
    fileSystem: fileSystem,
    delegate: delegate,
  );

  @override
  Link wrapLink(io.Link delegate) => ErrorHandlingLink(
    platform: _platform,
    fileSystem: fileSystem,
    delegate: delegate,
  );

  @override
  String toString() => delegate.toString();
}

Future<T> _run<T>(Future<T> Function() op, {
  @required Platform platform,
  String failureMessage,
}) async {
  assert(platform != null);
  try {
    return await op();
  } on FileSystemException catch (e) {
    if (platform.isWindows) {
      _handleWindowsException(e, failureMessage);
    } else if (platform.isLinux) {
      _handleLinuxException(e, failureMessage);
    }
    rethrow;
  }
}

T _runSync<T>(T Function() op, {
  @required Platform platform,
  String failureMessage,
}) {
  assert(platform != null);
  try {
    return op();
  } on FileSystemException catch (e) {
    if (platform.isWindows) {
      _handleWindowsException(e, failureMessage);
    } else if (platform.isLinux) {
      _handleLinuxException(e, failureMessage);
    }
    rethrow;
  }
}

void _handleLinuxException(FileSystemException e, String message) {
  // From:
  // https://github.com/torvalds/linux/blob/master/include/uapi/asm-generic/errno.h
  // https://github.com/torvalds/linux/blob/master/include/uapi/asm-generic/errno-base.h
  const int enospc = 28;
  final int errorCode = e.osError?.errorCode ?? 0;
  // Catch errors and bail when:
  switch (errorCode) {
    case enospc:
      throwToolExit(
        '$message. The target device is full.'
        '\n$e\n'
        'Free up space and try again.',
      );
      break;
    default:
      // Caller must rethrow the exception.
      break;
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
