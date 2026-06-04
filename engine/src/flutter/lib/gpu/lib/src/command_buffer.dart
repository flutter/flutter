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

base class CommandBuffer extends NativeFieldWrapperClass1 {
  final GpuContext _gpuContext;

  /// Creates a new CommandBuffer.
  CommandBuffer._(this._gpuContext) {
    _initialize(_gpuContext);
  }

  RenderPass createRenderPass(RenderTarget renderTarget) {
    return RenderPass._(_gpuContext, this, renderTarget);
  }

  /// Copies tightly packed texel data from [source] into [destination].
  ///
  /// Prefer this over [Texture.overwrite] when uploading more than one texture
  /// region. Multiple contiguous copy commands recorded on the same
  /// [CommandBuffer] are batched by Flutter GPU into a single backend blit
  /// pass where the backend has such a concept.
  void copyBufferToTexture(BufferView source, TextureRegion destination) {
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
  void copyTextureToBuffer(TextureRegion source, BufferView destination) {
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
  void copyTextureToTexture(
    TextureRegion source,
    TextureDestinationRegion destination,
  ) {
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

  void submit({CompletionCallback? completionCallback}) {
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
