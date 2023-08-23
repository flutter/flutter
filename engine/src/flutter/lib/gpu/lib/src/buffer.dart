// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';
import 'dart:nativewrappers';
import 'dart:typed_data';

/// A reference to a byte range within a GPU-resident [Buffer].
class BufferView {
  /// The buffer of this view.
  final HostBuffer buffer;

  /// The start of the view, in bytes starting from the beginning of the
  /// [buffer].
  final int offsetInBytes;

  /// The length of the view.
  final int lengthInBytes;

  /// Create a new view into a buffer on the GPU.
  const BufferView(this.buffer,
      {required this.offsetInBytes, required this.lengthInBytes});
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
base class HostBuffer extends NativeFieldWrapperClass1 {
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
