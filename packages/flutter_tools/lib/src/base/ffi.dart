// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '_ffi_unuspported.dart'
  if (dart.library.ffi) '_ffi_supported.dart' as ffi_impl;

abstract class FFIService {
  factory FFIService() = ffi_impl.FFIServiceImpl;

  /// Whether the file is considered "hidden" by the native file system.
  ///
  /// On Windows this checks for the `FileHidden` attribute via
  /// `GetFileAttributesW`.
  ///
  /// On all other platforms this returns false.
  ///
  /// This function will always use the real platform implementation and cannot
  /// be mocked with `package:platform`. This is intentional to prevent
  /// incorrect ffi invocations.
  ///
  /// See also:
  ///  * https://docs.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-getfileattributesw
  bool isFileHidden(String path);
}
