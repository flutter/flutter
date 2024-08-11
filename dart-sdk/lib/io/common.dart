// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

// Constants used when working with native ports.
// These must match the constants in runtime/bin/dartutils.h class CObject.
const int _successResponse = 0;
const int _illegalArgumentResponse = 1;
const int _osErrorResponse = 2;
const int _fileClosedResponse = 3;

const int _errorResponseErrorType = 0;
const int _osErrorResponseErrorCode = 1;
const int _osErrorResponseMessage = 2;

// POSIX error codes.
// See https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/errno.h.html
const _ePerm = 1;
const _eNoEnt = 2;
const _eAccess = 13;
const _eExist = 17;

// Windows error codes.
// See https://learn.microsoft.com/en-us/windows/win32/debug/system-error-codes--0-499-
const _errorFileNotFound = 2;
const _errorPathNotFound = 3;
const _errorAccessDenied = 5;
const _errorInvalidDrive = 15;
const _errorCurrentDirectory = 16;
const _errorNoMoreFiles = 18;
const _errorWriteProtect = 19;
const _errorBadLength = 24;
const _errorSharingViolation = 32;
const _errorLockViolation = 33;
const _errorBadNetpath = 53;
const _errorNetworkAccessDenied = 65;
const _errorBadNetName = 67;
const _errorFileExists = 80;
const _errorDriveLocked = 108;
const _errorBadPathName = 161;
const _errorAlreadyExists = 183;
const _errorFilenameExedRange = 206;

/// If the [response] is an error, throws an [Exception] or an [Error].
void _checkForErrorResponse(Object? response, String message, String path) {
  if (response is List<Object?> && response[0] != _successResponse) {
    switch (response[_errorResponseErrorType]) {
      case _illegalArgumentResponse:
        throw ArgumentError("$message: $path");
      case _osErrorResponse:
        var err = OSError(response[_osErrorResponseMessage] as String,
            response[_osErrorResponseErrorCode] as int);
        throw FileSystemException._fromOSError(err, message, path);
      case _fileClosedResponse:
        throw FileSystemException("File closed", path);
      default:
        throw AssertionError("Unknown error");
    }
  }
}

/// Base class for all IO related exceptions.
abstract class IOException implements Exception {
  String toString() => "IOException";
}

/// An [Exception] holding information about an error from the
/// operating system.
@pragma("vm:entry-point")
class OSError implements Exception {
  /// Constant used to indicate that no OS error code is available.
  static const int noErrorCode = -1;

  /// Error message supplied by the operating system. This will be empty if no
  /// message is associated with the error.
  final String message;

  /// Error code supplied by the operating system.
  ///
  /// Will have the value [OSError.noErrorCode] if there is no error code
  /// associated with the error.
  final int errorCode;

  /// Creates an OSError object from a message and an errorCode.
  @pragma("vm:entry-point")
  const OSError([this.message = "", this.errorCode = noErrorCode]);

  /// Converts an OSError object to a string representation.
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write("OS Error");
    if (message.isNotEmpty) {
      sb
        ..write(": ")
        ..write(message);
      if (errorCode != noErrorCode) {
        sb
          ..write(", errno = ")
          ..write(errorCode.toString());
      }
    } else if (errorCode != noErrorCode) {
      sb
        ..write(": errno = ")
        ..write(errorCode.toString());
    }
    return sb.toString();
  }
}

// Object for holding a buffer and an offset.
class _BufferAndStart {
  List<int> buffer;
  int start;
  _BufferAndStart(this.buffer, this.start);
}

// Ensure that the input List can be serialized through a native port.
_BufferAndStart _ensureFastAndSerializableByteData(
    List<int> buffer, int start, int end) {
  if ((buffer is Uint8List) && (buffer.buffer.lengthInBytes == buffer.length)) {
    // Send typed data directly, unless it is a partial view, in which case we
    // would rather copy than drag in the potentially much large backing store.
    // See issue 50206.
    return new _BufferAndStart(buffer, start);
  }
  int length = end - start;
  var newBuffer = new Uint8List(length);
  newBuffer.setRange(0, length, buffer, start);
  return new _BufferAndStart(newBuffer, 0);
}

class _IOCrypto {
  external static Uint8List getRandomBytes(int count);
}
