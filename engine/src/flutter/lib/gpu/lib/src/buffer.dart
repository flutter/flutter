// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

part of flutter_gpu;

/// A reference to a byte range within a GPU-resident [Buffer].
class BufferView {
  /// The buffer of this view.
  final Buffer buffer;

  /// The start of the view, in bytes starting from the beginning of the
  /// [buffer].
  final int offsetInBytes;

  /// The length of the view.
  final int lengthInBytes;

  /// Create a new view into a buffer on the GPU.
  const BufferView(this.buffer,
      {required this.offsetInBytes, required this.lengthInBytes});
}

/// A buffer that can be referenced by commands on the GPU.
mixin Buffer {}

/// [DeviceBuffer] is a region of memory allocated on the device heap
/// (GPU-resident memory).
base class DeviceBuffer extends NativeFieldWrapperClass1 with Buffer {
  bool _valid = false;
  get isValid {
    return _valid;
  }

  /// Creates a new DeviceBuffer.
  DeviceBuffer._initialize(
      GpuContext gpuContext, StorageMode storageMode, int sizeInBytes)
      : storageMode = storageMode,
        sizeInBytes = sizeInBytes {
    _valid = _initialize(gpuContext, storageMode.index, sizeInBytes);
  }

  /// Creates a new host visible DeviceBuffer with data copied from the host.
  DeviceBuffer._initializeWithHostData(GpuContext gpuContext, ByteData data)
      : storageMode = StorageMode.hostVisible,
        sizeInBytes = data.lengthInBytes {
    _valid = _initializeWithHostData(gpuContext, data);
  }

  final StorageMode storageMode;
  final int sizeInBytes;

  /// Wrap with native counterpart.
  @Native<Bool Function(Handle, Pointer<Void>, Int, Int)>(
      symbol: 'InternalFlutterGpu_DeviceBuffer_Initialize')
  external bool _initialize(
      GpuContext gpuContext, int storageMode, int sizeInBytes);

  /// Wrap with native counterpart.
  @Native<Bool Function(Handle, Pointer<Void>, Handle)>(
      symbol: 'InternalFlutterGpu_DeviceBuffer_InitializeWithHostData')
  external bool _initializeWithHostData(GpuContext gpuContext, ByteData data);

  /// Overwrite a range of bytes in the already created [DeviceBuffer].
  ///
  /// This method can only be used if the [DeviceBuffer] was created with
  /// [StorageMode.hostVisible]. An exception will be thrown otherwise.
  ///
  /// The entire length of [sourceBytes] will be copied into the [DeviceBuffer],
  /// starting at byte index [destinationOffsetInBytes] in the [DeviceBuffer].
  /// If performing this copy would result in an out of bounds write to the
  /// buffer, then the write will not be attempted and will fail.
  ///
  /// Returns [true] if the write was successful, or [false] if the write
  /// failed due to an internal error.
  bool overwrite(ByteData sourceBytes, {int destinationOffsetInBytes = 0}) {
    if (storageMode != StorageMode.hostVisible) {
      throw Exception(
          'DeviceBuffer.overwrite can only be used with DeviceBuffers that are host visible');
    }
    if (destinationOffsetInBytes < 0) {
      throw Exception('destinationOffsetInBytes must be positive');
    }
    return _overwrite(sourceBytes, destinationOffsetInBytes);
  }

  @Native<Bool Function(Pointer<Void>, Handle, Int)>(
      symbol: 'InternalFlutterGpu_DeviceBuffer_Overwrite')
  external bool _overwrite(ByteData bytes, int destinationOffsetInBytes);
}

/// [HostBuffer] is a [Buffer] which is allocated on the host (native CPU
/// resident memory) and lazily uploaded to the GPU. A [HostBuffer] can be
/// safely mutated or extended at any time on the host, and will be
/// automatically re-uploaded to the GPU the next time a GPU operation needs to
/// access it.
///
/// This is useful for efficiently chunking sparse data uploads, especially
/// ephemeral uniform data that needs to change from frame to frame.
///
/// Different platforms have different data alignment requirements for accessing
/// device buffer data. The [HostBuffer] takes these requirements into account
/// and automatically inserts padding between emplaced data if necessary.
base class HostBuffer extends NativeFieldWrapperClass1 with Buffer {
  /// Creates a new HostBuffer.
  HostBuffer() {
    _initialize();
  }

  /// Wrap with native counterpart.
  @Native<Void Function(Handle)>(
      symbol: 'InternalFlutterGpu_HostBuffer_Initialize')
  external void _initialize();

  /// Append byte data to the end of the [HostBuffer] and produce a [BufferView]
  /// that references the new data in the buffer.
  ///
  /// This method automatically inserts padding in-between emplace calls in the
  /// buffer if necessary to abide by platform-specific uniform alignment
  /// requirements.
  ///
  /// The updated buffer will be uploaded to the GPU if the returned
  /// [BufferView] is used by a rendering command.
  BufferView emplace(ByteData bytes) {
    int resultOffset = _emplaceBytes(bytes);
    return BufferView(this,
        offsetInBytes: resultOffset, lengthInBytes: bytes.lengthInBytes);
  }

  @Native<Uint64 Function(Pointer<Void>, Handle)>(
      symbol: 'InternalFlutterGpu_HostBuffer_EmplaceBytes')
  external int _emplaceBytes(ByteData bytes);
}
