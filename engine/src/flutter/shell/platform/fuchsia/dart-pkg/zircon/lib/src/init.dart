// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of zircon;

final _kLibZirconDartPath = '/pkg/lib/libzircon_ffi.so';

class _Bindings {
  static ZirconFFIBindings? _bindings;

  @pragma('vm:entry-point')
  static ZirconFFIBindings? get() {
    // For soft-transition until libzircon_ffi.so rolls into GI.
    if (!File(_kLibZirconDartPath).existsSync()) {
      return null;
    }

    if (_bindings == null) {
      final _dylib = DynamicLibrary.open(_kLibZirconDartPath);
      _bindings = ZirconFFIBindings(_dylib);
    }
    return _bindings;
  }
}

final ZirconFFIBindings? zirconFFIBindings = _Bindings.get();
