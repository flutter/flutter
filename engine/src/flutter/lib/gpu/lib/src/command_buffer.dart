// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

part of flutter_gpu;

typedef CompletionCallback<T> = void Function(bool success);

/// A rectangular region within a [Texture].
///
/// [width] and [height] default to the full size of [texture] at [mipLevel].
/// Buffer-to-texture and texture-to-buffer copies use tightly packed rows; the
/// copied byte count is rounded up to whole pixel-format blocks.
base class TextureRegion {
  const TextureRegion(
    this.texture, {
    this.x = 0,
    this.y = 0,
    this.width = -1,
    this.height = -1,
    this.mipLevel = 0,
    this.slice = 0,
  });

  final Texture texture;
  final int x;
  final int y;
  final int width;
  final int height;
  final int mipLevel;
  final int slice;

  int _resolvedWidth() {
    return width == -1 ? texture.getMipLevelWidth(mipLevel) : width;
  }

  int _resolvedHeight() {
    return height == -1 ? texture.getMipLevelHeight(mipLevel) : height;
  }

  void _validate({bool allowMipAndSlice = true}) {
    texture._validateMipLevelAndSlice(mipLevel, slice);
    if (!allowMipAndSlice && (mipLevel != 0 || slice != 0)) {
      throw Exception(
        'Only mipLevel 0 and slice 0 are currently supported for this copy operation',
      );
    }
    if (x < 0 || y < 0) {
      throw Exception('Texture region x and y must be non-negative');
    }
    if (width < -1 || width == 0 || height < -1 || height == 0) {
      throw Exception(
        'Texture region width and height must be positive, or -1 to use the full mip size',
      );
    }
    final int resolvedWidth = _resolvedWidth();
    final int resolvedHeight = _resolvedHeight();
    if (x + resolvedWidth > texture.getMipLevelWidth(mipLevel) ||
        y + resolvedHeight > texture.getMipLevelHeight(mipLevel)) {
      throw Exception(
        'Texture region ($x, $y, $resolvedWidth, $resolvedHeight) exceeds '
        'mip level $mipLevel size '
        '(${texture.getMipLevelWidth(mipLevel)}, ${texture.getMipLevelHeight(mipLevel)})',
      );
    }
  }

  int _sizeInBytes() {
    final int bw = texture.format.blockWidth;
    final int bh = texture.format.blockHeight;
    final int blocksWide = (_resolvedWidth() + bw - 1) ~/ bw;
    final int blocksHigh = (_resolvedHeight() + bh - 1) ~/ bh;
    return blocksWide * blocksHigh * texture.format.bytesPerBlock;
  }
}

/// The upper-left destination of a texture-to-texture copy.
base class TextureDestinationRegion {
  const TextureDestinationRegion(
    this.texture, {
    this.x = 0,
    this.y = 0,
    this.mipLevel = 0,
    this.slice = 0,
  });

  final Texture texture;
  final int x;
  final int y;
  final int mipLevel;
  final int slice;

  void _validate(TextureRegion source) {
    texture._validateMipLevelAndSlice(mipLevel, slice);
    if (mipLevel != 0 ||
        slice != 0 ||
        source.mipLevel != 0 ||
        source.slice != 0) {
      throw Exception(
        'Only mipLevel 0 and slice 0 are currently supported for texture-to-texture copies',
      );
    }
    if (x < 0 || y < 0) {
      throw Exception('Texture copy destination x and y must be non-negative');
    }
    if (x + source._resolvedWidth() > texture.getMipLevelWidth(mipLevel) ||
        y + source._resolvedHeight() > texture.getMipLevelHeight(mipLevel)) {
      throw Exception(
        'Texture copy destination region exceeds the destination texture size',
      );
    }
  }
}

/// A sequence of passes and copies that is submitted to the GPU as a unit.
///
/// A command buffer records one pass at a time, and its passes execute in the
/// order they were created. A pass stays open for recording until one of the
/// following ends it:
///
///  * [createRenderPass] creates the next pass.
///  * [copyBufferToTexture], [copyTextureToBuffer] or [copyTextureToTexture]
///    records a copy.
///  * [submit] submits the command buffer.
///  * [RenderPass.end] ends it explicitly.
///
/// Any later call on an ended pass throws a [StateError] naming what ended
/// it. One command buffer can hold any number of passes. Once submitted, a
/// command buffer accepts no more passes or copies.
base class CommandBuffer extends NativeFieldWrapperClass1 {
  final GpuContext _gpuContext;

  /// Creates a new CommandBuffer.
  CommandBuffer._(this._gpuContext) {
    _initialize(_gpuContext);
  }

  bool _submitted = false;

  /// The pass that is recording, if any.
  RenderPass? _openPass;

  /// Whether [submit] has been called on this command buffer.
  bool get submitted => _submitted;

  /// Throws a [StateError] if [submit] was already called. [method] names the
  /// rejected call.
  void _checkNotSubmitted(String method) {
    if (_submitted) {
      throw StateError(
        '$method was called after the CommandBuffer was submitted.',
      );
    }
  }

  /// Ends the open pass, if any. [endedBy] names the call that ended it, for
  /// the [StateError] thrown by any later use of the pass.
  void _endOpenPass(String endedBy) {
    final RenderPass? pass = _openPass;
    if (pass == null) {
      return;
    }
    _openPass = null;
    pass._endedBy = endedBy;
  }

  /// Creates a [RenderPass] that draws into [renderTarget].
  ///
  /// This ends the pass that was recording on this command buffer, if any.
  /// The new pass executes after every pass and copy recorded before it, and
  /// records until the next pass, copy or [submit] ends it, or until
  /// [RenderPass.end] is called.
  ///
  /// Throws a [StateError] if this command buffer was already submitted.
  RenderPass createRenderPass(RenderTarget renderTarget) {
    _checkNotSubmitted('CommandBuffer.createRenderPass()');
    return RenderPass._(_gpuContext, this, renderTarget);
  }

  /// Copies tightly packed texel data from [source] into [destination].
  ///
  /// Prefer this over [Texture.overwrite] when uploading more than one texture
  /// region. Multiple contiguous copy commands recorded on the same
  /// [CommandBuffer] are batched by Flutter GPU into a single backend blit
  /// pass where the backend has such a concept.
  ///
  /// Recording a copy ends the open [RenderPass], if any. The copy executes
  /// after every pass and copy recorded before it. Throws a [StateError] if
  /// this command buffer was already submitted.
  void copyBufferToTexture(BufferView source, TextureRegion destination) {
    _checkNotSubmitted('CommandBuffer.copyBufferToTexture()');
    destination._validate();
    if (source.offsetInBytes < 0 ||
        source.lengthInBytes < 0 ||
        source.offsetInBytes + source.lengthInBytes >
            source.buffer.sizeInBytes) {
      throw Exception('BufferView range is out of bounds');
    }
    final int expectedSize = destination._sizeInBytes();
    if (source.lengthInBytes != expectedSize) {
      throw Exception(
        'The source BufferView length (bytes: ${source.lengthInBytes}) must '
        'match the destination texture region size (bytes: $expectedSize)',
      );
    }
    _endOpenPass('CommandBuffer.copyBufferToTexture()');
    final String? error = _copyBufferToTexture(
      source.buffer,
      source.offsetInBytes,
      source.lengthInBytes,
      destination.texture,
      destination.x,
      destination.y,
      destination._resolvedWidth(),
      destination._resolvedHeight(),
      destination.mipLevel,
      destination.slice,
    );
    if (error != null) {
      throw Exception(error);
    }
  }

  /// Copies a texture region into a tightly packed [destination] buffer view.
  ///
  /// The destination buffer must be large enough to hold
  /// the source region rounded up to whole pixel-format blocks.
  ///
  /// Recording a copy ends the open [RenderPass], if any. The copy executes
  /// after every pass and copy recorded before it. Throws a [StateError] if
  /// this command buffer was already submitted.
  void copyTextureToBuffer(TextureRegion source, BufferView destination) {
    _checkNotSubmitted('CommandBuffer.copyTextureToBuffer()');
    source._validate(allowMipAndSlice: false);
    if (destination.offsetInBytes < 0 ||
        destination.lengthInBytes < 0 ||
        destination.offsetInBytes + destination.lengthInBytes >
            destination.buffer.sizeInBytes) {
      throw Exception('BufferView range is out of bounds');
    }
    final int expectedSize = source._sizeInBytes();
    if (destination.lengthInBytes != expectedSize) {
      throw Exception(
        'The destination BufferView length (bytes: ${destination.lengthInBytes}) '
        'must match the source texture region size (bytes: $expectedSize)',
      );
    }
    _endOpenPass('CommandBuffer.copyTextureToBuffer()');
    final String? error = _copyTextureToBuffer(
      source.texture,
      source.x,
      source.y,
      source._resolvedWidth(),
      source._resolvedHeight(),
      destination.buffer,
      destination.offsetInBytes,
    );
    if (error != null) {
      throw Exception(error);
    }
  }

  /// Copies pixels from [source] into [destination].
  ///
  /// This is a raw copy. Source and destination textures must have matching
  /// formats and sample counts.
  ///
  /// Recording a copy ends the open [RenderPass], if any. The copy executes
  /// after every pass and copy recorded before it. Throws a [StateError] if
  /// this command buffer was already submitted.
  void copyTextureToTexture(
    TextureRegion source,
    TextureDestinationRegion destination,
  ) {
    _checkNotSubmitted('CommandBuffer.copyTextureToTexture()');
    source._validate(allowMipAndSlice: false);
    destination._validate(source);
    if (source.texture.format != destination.texture.format) {
      throw Exception(
        'Source and destination textures must have matching formats',
      );
    }
    if (source.texture.sampleCount != destination.texture.sampleCount) {
      throw Exception(
        'Source and destination textures must have matching sample counts',
      );
    }
    _endOpenPass('CommandBuffer.copyTextureToTexture()');
    final String? error = _copyTextureToTexture(
      source.texture,
      destination.texture,
      source.x,
      source.y,
      source._resolvedWidth(),
      source._resolvedHeight(),
      destination.x,
      destination.y,
    );
    if (error != null) {
      throw Exception(error);
    }
  }

  /// Submits the recorded passes and copies to the GPU, in the order they
  /// were recorded.
  ///
  /// This ends the open [RenderPass], if any. [completionCallback] is called
  /// when the submitted work completes, with `false` if it failed. A command
  /// buffer can be submitted once, and counts as submitted even if this
  /// throws.
  void submit({CompletionCallback? completionCallback}) {
    if (_submitted) {
      throw StateError('CommandBuffer has already been submitted.');
    }
    _endOpenPass('CommandBuffer.submit()');
    // Marked before the native submit, which consumes the command buffer even
    // when it fails.
    _submitted = true;
    String? error = _submit(completionCallback);
    if (error != null) {
      throw Exception(error);
    }
  }

  /// Wrap with native counterpart.
  @Native<Bool Function(Handle, Pointer<Void>)>(
    symbol: 'InternalFlutterGpu_CommandBuffer_Initialize',
  )
  external bool _initialize(GpuContext gpuContext);

  @Native<Handle Function(Pointer<Void>, Handle)>(
    symbol: 'InternalFlutterGpu_CommandBuffer_Submit',
  )
  external String? _submit(CompletionCallback? completionCallback);

  @Native<
    Handle Function(
      Pointer<Void>,
      Pointer<Void>,
      Int,
      Int,
      Pointer<Void>,
      Int,
      Int,
      Int,
      Int,
      Int,
      Int,
    )
  >(symbol: 'InternalFlutterGpu_CommandBuffer_CopyBufferToTexture')
  external String? _copyBufferToTexture(
    DeviceBuffer source,
    int sourceOffsetInBytes,
    int sourceLengthInBytes,
    Texture destination,
    int destinationX,
    int destinationY,
    int destinationWidth,
    int destinationHeight,
    int mipLevel,
    int slice,
  );

  @Native<
    Handle Function(
      Pointer<Void>,
      Pointer<Void>,
      Int,
      Int,
      Int,
      Int,
      Pointer<Void>,
      Int,
    )
  >(symbol: 'InternalFlutterGpu_CommandBuffer_CopyTextureToBuffer')
  external String? _copyTextureToBuffer(
    Texture source,
    int sourceX,
    int sourceY,
    int sourceWidth,
    int sourceHeight,
    DeviceBuffer destination,
    int destinationOffsetInBytes,
  );

  @Native<
    Handle Function(
      Pointer<Void>,
      Pointer<Void>,
      Pointer<Void>,
      Int,
      Int,
      Int,
      Int,
      Int,
      Int,
    )
  >(symbol: 'InternalFlutterGpu_CommandBuffer_CopyTextureToTexture')
  external String? _copyTextureToTexture(
    Texture source,
    Texture destination,
    int sourceX,
    int sourceY,
    int sourceWidth,
    int sourceHeight,
    int destinationX,
    int destinationY,
  );
}
