// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of flutter_gpu;

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

  /// Allocates a new region of GPU-resident memory.
  ///
  /// The [storageMode] must be either [StorageMode.hostVisible] or
  /// [StorageMode.devicePrivate], otherwise an exception will be thrown.
  ///
  /// Returns [null] if the [DeviceBuffer] creation failed.
  DeviceBuffer? createDeviceBuffer(StorageMode storageMode, int sizeInBytes) {
    if (storageMode == StorageMode.deviceTransient) {
      throw Exception(
          'DeviceBuffers cannot be set to StorageMode.deviceTransient');
    }
    DeviceBuffer result =
        DeviceBuffer._initialize(this, storageMode, sizeInBytes);
    return result.isValid ? result : null;
  }

  /// Allocates a new region of host-visible GPU-resident memory, initialized
  /// with the given [data].
  ///
  /// Given that the buffer will be immediately populated with [data] uploaded
  /// from the host, the [StorageMode] of the new [DeviceBuffer] is
  /// automatically set to [StorageMode.hostVisible].
  ///
  /// Returns [null] if the [DeviceBuffer] creation failed.
  DeviceBuffer? createDeviceBufferWithCopy(ByteData data) {
    DeviceBuffer result = DeviceBuffer._initializeWithHostData(this, data);
    return result.isValid ? result : null;
  }

  /// Associates the default Impeller context with this Context.
  @Native<Handle Function(Handle)>(
      symbol: 'InternalFlutterGpu_Context_InitializeDefault')
  external String? _initializeDefault();
}

/// The default graphics context.
final GpuContext gpuContext = GpuContext._createDefault();
