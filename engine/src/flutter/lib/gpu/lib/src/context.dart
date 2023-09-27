// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';
import 'dart:nativewrappers';

/// A handle to a graphics context. Used to create and manage GPU resources.
///
/// To obtain the default graphics context, use [getContext].
base class GpuContext extends NativeFieldWrapperClass1 {
  /// Creates a new graphics context that corresponds to the default Impeller
  /// context.
  GpuContext._createDefault() {
    final String? error = _initializeDefault();
    if (error != null) {
      throw Exception(error);
    }
  }

  /// Associates the default Impeller context with this Context.
  @Native<Handle Function(Handle)>(
      symbol: 'InternalFlutterGpu_Context_InitializeDefault')
  external String? _initializeDefault();
}

/// The default graphics context.
final GpuContext gpuContext = GpuContext._createDefault();
