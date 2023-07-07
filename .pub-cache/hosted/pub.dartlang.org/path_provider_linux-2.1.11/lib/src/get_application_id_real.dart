// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

// GApplication* g_application_get_default();
typedef _GApplicationGetDefaultC = IntPtr Function();
typedef _GApplicationGetDefaultDart = int Function();

// const gchar* g_application_get_application_id(GApplication* application);
typedef _GApplicationGetApplicationIdC = Pointer<Utf8> Function(IntPtr);
typedef _GApplicationGetApplicationIdDart = Pointer<Utf8> Function(int);

/// Interface for interacting with libgio.
@visibleForTesting
class GioUtils {
  /// Creates a default instance that uses the real libgio.
  GioUtils() {
    try {
      _gio = DynamicLibrary.open('libgio-2.0.so');
    } on ArgumentError {
      _gio = null;
    }
  }

  DynamicLibrary? _gio;

  /// True if libgio was opened successfully.
  bool get libraryIsPresent => _gio != null;

  /// Wraps `g_application_get_default`.
  int gApplicationGetDefault() {
    if (_gio == null) {
      return 0;
    }
    final _GApplicationGetDefaultDart getDefault = _gio!
        .lookupFunction<_GApplicationGetDefaultC, _GApplicationGetDefaultDart>(
            'g_application_get_default');
    return getDefault();
  }

  /// Wraps g_application_get_application_id.
  Pointer<Utf8> gApplicationGetApplicationId(int app) {
    if (_gio == null) {
      return nullptr;
    }
    final _GApplicationGetApplicationIdDart gApplicationGetApplicationId = _gio!
        .lookupFunction<_GApplicationGetApplicationIdC,
                _GApplicationGetApplicationIdDart>(
            'g_application_get_application_id');
    return gApplicationGetApplicationId(app);
  }
}

/// Allows overriding the default GioUtils instance with a fake for testing.
@visibleForTesting
GioUtils? gioUtilsOverride;

/// Gets the application ID for this app.
String? getApplicationId() {
  final GioUtils gio = gioUtilsOverride ?? GioUtils();
  if (!gio.libraryIsPresent) {
    return null;
  }

  final int app = gio.gApplicationGetDefault();
  if (app == 0) {
    return null;
  }
  final Pointer<Utf8> appId = gio.gApplicationGetApplicationId(app);
  if (appId == nullptr) {
    return null;
  }
  return appId.toDartString();
}
