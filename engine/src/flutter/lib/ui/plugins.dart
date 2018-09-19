// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart.ui;

/// An wrapper for a raw callback handle.
class CallbackHandle {
  final int _handle;

  /// Create an instance using a raw callback handle.
  ///
  /// Only values produced by a call to [CallbackHandle.toRawHandle] should be
  /// used, otherwise this object will be an invalid handle.
  CallbackHandle.fromRawHandle(this._handle)
      : assert(_handle != null, "'_handle' must not be null.");

  /// Get the raw callback handle to pass over a [MethodChannel] or isolate
  /// port.
  int toRawHandle() => _handle;

  @override
  int get hashCode => _handle;

  @override
  bool operator ==(dynamic other) =>
      (other is CallbackHandle) && (_handle == other._handle);
}

/// Functionality for Flutter plugin authors.
abstract class PluginUtilities {
  // This class is only a namespace, and should not be instantiated or
  // extended directly.
  factory PluginUtilities._() => null;

  static Map<Function, CallbackHandle> _forwardCache =
      <Function, CallbackHandle>{};
  static Map<CallbackHandle, Function> _backwardCache =
      <CallbackHandle, Function>{};

  /// Get a handle to a named top-level or static callback function which can
  /// be easily passed between isolates.
  ///
  /// `callback` must not be null.
  ///
  /// Returns a [CallbackHandle] that can be provided to
  /// [PluginUtilities.getCallbackFromHandle] to retrieve a tear-off of the
  /// original callback. If `callback` is not a top-level or static function,
  /// null is returned.
  static CallbackHandle getCallbackHandle(Function callback) {
    assert(callback != null, "'callback' must not be null.");
    return _forwardCache.putIfAbsent(callback, () {
      final int handle = _getCallbackHandle(callback);
      return handle != null ? new CallbackHandle.fromRawHandle(handle) : null;
    });
  }

  /// Get a tear-off of a named top-level or static callback represented by a
  /// handle.
  ///
  /// `handle` must not be null.
  ///
  /// If `handle` is not a valid handle returned by
  /// [PluginUtilities.getCallbackHandle], null is returned. Otherwise, a
  /// tear-off of the callback associated with `handle` is returned.
  static Function getCallbackFromHandle(CallbackHandle handle) {
    assert(handle != null, "'handle' must not be null.");
    return _backwardCache.putIfAbsent(
        handle, () => _getCallbackFromHandle(handle.toRawHandle()));
  }
}
