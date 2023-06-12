// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'interface.dart';

/// Returns a 'No such file or directory' [FileSystemException].
FileSystemException noSuchFileOrDirectory(String path) {
  return _fsException(path, 'No such file or directory', ErrorCodes.ENOENT);
}

/// Returns a 'Not a directory' [FileSystemException].
FileSystemException notADirectory(String path) {
  return _fsException(path, 'Not a directory', ErrorCodes.ENOTDIR);
}

/// Returns a 'Is a directory' [FileSystemException].
FileSystemException isADirectory(String path) {
  return _fsException(path, 'Is a directory', ErrorCodes.EISDIR);
}

/// Returns a 'Directory not empty' [FileSystemException].
FileSystemException directoryNotEmpty(String path) {
  return _fsException(path, 'Directory not empty', ErrorCodes.ENOTEMPTY);
}

/// Returns a 'File exists' [FileSystemException].
FileSystemException fileExists(String path) {
  return _fsException(path, 'File exists', ErrorCodes.EEXIST);
}

/// Returns a 'Invalid argument' [FileSystemException].
FileSystemException invalidArgument(String path) {
  return _fsException(path, 'Invalid argument', ErrorCodes.EINVAL);
}

/// Returns a 'Too many levels of symbolic links' [FileSystemException].
FileSystemException tooManyLevelsOfSymbolicLinks(String path) {
  // TODO(tvolkert): Switch to ErrorCodes.EMLINK
  return _fsException(
      path, 'Too many levels of symbolic links', ErrorCodes.ELOOP);
}

/// Returns a 'Bad file descriptor' [FileSystemException].
FileSystemException badFileDescriptor(String path) {
  return _fsException(path, 'Bad file descriptor', ErrorCodes.EBADF);
}

FileSystemException _fsException(String path, String msg, int errorCode) {
  return FileSystemException(msg, path, OSError(msg, errorCode));
}

/// Mixin containing implementations of [Directory] methods that are common
/// to all implementations.
abstract class DirectoryAddOnsMixin implements Directory {
  @override
  Directory childDirectory(String basename) {
    return fileSystem.directory(fileSystem.path.join(path, basename));
  }

  @override
  File childFile(String basename) {
    return fileSystem.file(fileSystem.path.join(path, basename));
  }

  @override
  Link childLink(String basename) {
    return fileSystem.link(fileSystem.path.join(path, basename));
  }
}
