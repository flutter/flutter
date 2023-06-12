// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Exceptions that may be caught or thrown by the win32 library.

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'constants.dart';
import 'extensions/int_to_hexstring.dart';
import 'utils.dart';
import 'win32/kernel32.g.dart';

/// Generic COM Exception
class COMException implements Exception {
  int hr;

  String? message;

  COMException(this.hr, {this.message});
}

/// Generalized Windows exception
class WindowsException extends COMException {
  WindowsException(super.hr, {super.message});

  /// Converts a Windows error into a friendly string.
  ///
  /// Takes one numeric parameter, which may be a general Windows error or an
  /// HRESULT, and converts it into a String representation using the Win32
  /// `FormatMessage()` function. For example, `E_INVALIDARG` (0x80070057)
  /// converts to `The parameter is incorrect.`
  String convertWindowsErrorToString(int windowsError) {
    final buffer = wsalloc(256);

    // If FormatMessage fails, it returns 0; otherwise it returns the number of
    // characters in the buffer.
    try {
      String errorMessage;
      final result = FormatMessage(
          FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
          nullptr,
          windowsError,
          0, // default language
          buffer,
          256,
          nullptr);

      if (result == 0) {
        // Failed to get error string
        errorMessage = '';
      } else {
        errorMessage = buffer.toDartString();
      }

      // Strip off CRLF in the returned error message, if it exists
      if (errorMessage.endsWith('\r\n')) {
        errorMessage = errorMessage.substring(0, errorMessage.length - 2);
      }

      return errorMessage;
    } finally {
      free(buffer);
    }
  }

  @override
  String toString() =>
      'Error ${hr.toHexString(32)}: ${message ?? convertWindowsErrorToString(hr)}';
}
