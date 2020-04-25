// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi'; // ignore: dart_ffi_import
import 'dart:io'; // ignore: dart_io_import

import 'package:ffi/ffi.dart';

import 'ffi.dart';

typedef GetFileAttributes = int Function(Pointer<Utf16>);
typedef GetFileAttributesNative = Uint32 Function(Pointer<Utf16>);

/// An implementation of [FFIService] that is fully backed by dart:ffi.
class FFIServiceImpl implements FFIService {

  /// The available standard library.
  ///
  /// This is required to use the real platform implementation to avoid
  /// incorrect mocking.
  ///
  /// Note that `kernel32.dll` is the correct dll for both 32 bit and 64 bit
  /// windows.
  final DynamicLibrary stdlib = Platform.isWindows
      ? DynamicLibrary.open('kernel32.dll')
      : DynamicLibrary.process();


  GetFileAttributes _getFileAttributes;
  static const int _kWindowsFileAttributeHidden = 0x2;
  static const int _kWindowsFileAttributeInvalid = 4294967295;

  @override
  bool isFileHidden(String path) {
    if (Platform.isWindows) {
      _getFileAttributes ??= stdlib
        .lookupFunction<GetFileAttributesNative, GetFileAttributes>('GetFileAttributesW');
      final Pointer<Utf16> fileName = Utf16.toUtf16(path);
      final int attributes = _getFileAttributes(fileName);
      if (attributes == _kWindowsFileAttributeInvalid) {
        throw FileSystemException('Failed to get file attributes', path);
      }
      return (attributes & _kWindowsFileAttributeHidden) == _kWindowsFileAttributeHidden;
    }
    return false;
  }
}
