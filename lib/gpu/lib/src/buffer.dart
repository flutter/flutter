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
mixin Buffer {
  void _bindAsVertexBuffer(RenderPass renderPass, int offsetInBytes,
      int lengthInBytes, int vertexCount);

  void _bindAsIndexBuffer(RenderPass renderPass, int offsetInBytes,
      int lengthInBytes, IndexType indexType, int indexCount);

  bool _bindAsUniform(RenderPass renderPass, UniformSlot slot,
      int offsetInBytes, int lengthInBytes);
}

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

  @override
  void _bindAsVertexBuffer(RenderPass renderPass, int offsetInBytes,
      int lengthInBytes, int vertexCount) {
    renderPass._bindVertexBufferDevice(
        this, offsetInBytes, lengthInBytes, vertexCount);
  }

  @override
  void _bindAsIndexBuffer(RenderPass renderPass, int offsetInBytes,
      int lengthInBytes, IndexType indexType, int indexCount) {
    renderPass._bindIndexBufferDevice(
        this, offsetInBytes, lengthInBytes, indexType.index, indexCount);
  }

  @override
  bool _bindAsUniform(RenderPass renderPass, UniformSlot slot,
      int offsetInBytes, int lengthInBytes) {
    return renderPass._bindUniformDevice(
        slot.shader, slot.uniformName, this, offsetInBytes, lengthInBytes);
  }

  /// Wrap with native counterpart.
  @Native<Bool Function(Handle, Pointer<Void>, Int, Int)>(
      symbol: 'InternalFlutterGpu_DeviceBuffer_Initialize')
  external bool _initialize(
      GpuContext gpuContext, int storageMode, int sizeInBytes);

  /// Wrap with native counterpart.
  @Native<Bool Function(Handle, Pointer<Void>, Handle)>(
      symbol: 'InternalFlutterGpu_DeviceBuffer_InitializeWithHostData')
  external bool _initializeWithHostData(GpuContext gpuContext, ByteData data);

  /// Overwrite a range of bytes within an existing [DeviceBuffer].
  ///
  /// This method can only be used if the [DeviceBuffer] was created with
  /// [StorageMode.hostVisible]. An exception will be thrown otherwise.
  ///
  /// After new writes have been staged, the [DeviceBuffer.flush] should be
  /// called prior to accessing the data. Otherwise, the updated data will not
  /// be copied to the GPU on devices that don't have host coherent memory.
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

  /// Flush the contents of the [DeviceBuffer] to the GPU.
  ///
  /// This method can only be used if the [DeviceBuffer] was created with
  /// [StorageMode.hostVisible]. An exception will be thrown otherwise.
  ///
  /// If [lengthInBytes] is set to -1, the entire buffer will be flushed.
  ///
  /// On devices with coherent host memory (memory shared between the CPU and
  /// GPU), this method is a no-op.
  void flush({int offsetInBytes = 0, int lengthInBytes = -1}) {
    if (storageMode != StorageMode.hostVisible) {
      throw Exception(
          'DeviceBuffer.flush can only be used with DeviceBuffers that are host visible');
    }
    if (offsetInBytes < 0 || offsetInBytes >= sizeInBytes) {
      throw Exception('offsetInBytes must be within the bounds of the buffer');
    }
    if (lengthInBytes < -1) {
      throw Exception('lengthInBytes must be either positive or -1');
    }
    if (lengthInBytes != -1 && offsetInBytes + lengthInBytes > sizeInBytes) {
      throw Exception(
          'The provided range must not be too large to fit within the buffer');
    }
    _flush(offsetInBytes, lengthInBytes);
  }

  @Native<Void Function(Pointer<Void>, Int, Int)>(
      symbol: 'InternalFlutterGpu_DeviceBuffer_Flush')
  external void _flush(int offsetInBytes, int lengthInBytes);
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
  HostBuffer._initialize(GpuContext gpuContext) {
    _initialize(gpuContext);
  }

  @override
  void _bindAsVertexBuffer(RenderPass renderPass, int offsetInBytes,
      int lengthInBytes, int vertexCount) {
    renderPass._bindVertexBufferHost(
        this, offsetInBytes, lengthInBytes, vertexCount);
  }

  @override
  void _bindAsIndexBuffer(RenderPass renderPass, int offsetInBytes,
      int lengthInBytes, IndexType indexType, int indexCount) {
    renderPass._bindIndexBufferHost(
        this, offsetInBytes, lengthInBytes, indexType.index, indexCount);
  }

  @override
  bool _bindAsUniform(RenderPass renderPass, UniformSlot slot,
      int offsetInBytes, int lengthInBytes) {
    return renderPass._bindUniformHost(
        slot.shader, slot.uniformName, this, offsetInBytes, lengthInBytes);
  }

  /// Wrap with native counterpart.
  @Native<Void Function(Handle, Pointer<Void>)>(
      symbol: 'InternalFlutterGpu_HostBuffer_Initialize')
  external void _initialize(GpuContext gpuContext);

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
