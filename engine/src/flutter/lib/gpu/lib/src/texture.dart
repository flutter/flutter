// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

part of flutter_gpu;

base class Texture extends NativeFieldWrapperClass1 {
  bool _valid = false;
  get isValid {
    return _valid;
  }

  /// Returns the maximum number of mip levels Flutter GPU will allocate
  /// for a texture of the given [width] and [height].
  ///
  /// This currently uses `floor(log2(min(w, h)))` and clamps at 1. Note
  /// that this is one less than the canonical `floor(log2(max(w, h))) + 1`
  /// used by Vulkan and OpenGL, and uses the smaller dimension instead of
  /// the larger; Flutter GPU may eventually relax this (tracked in
  /// https://github.com/flutter/flutter/issues/186176). Users should treat
  /// this as the upper bound for the `mipLevelCount` argument to
  /// `GpuContext.createTexture` rather than as a fixed mathematical
  /// formula.
  static int fullMipCount(int width, int height) {
    if (width < 1 || height < 1) {
      return 1;
    }
    final int smallest = width < height ? width : height;
    final int count = smallest.bitLength - 1;
    return count > 0 ? count : 1;
  }

  /// Creates a new Texture.
  Texture._initialize(
    GpuContext gpuContext,
    this.storageMode,
    this.format,
    this.width,
    this.height,
    this.sampleCount,
    TextureCoordinateSystem coordinateSystem,
    this.textureType,
    this.enableRenderTargetUsage,
    this.enableShaderReadUsage,
    this.enableShaderWriteUsage,
    this.mipLevelCount,
  ) : _gpuContext = gpuContext,
      _coordinateSystem = coordinateSystem {
    if (sampleCount != 1 && sampleCount != 4) {
      throw Exception("Only a sample count of 1 or 4 is currently supported");
    }
    _valid = _initialize(
      gpuContext,
      storageMode.index,
      format.index,
      width,
      height,
      sampleCount,
      coordinateSystem.index,
      textureType.index,
      enableRenderTargetUsage,
      enableShaderReadUsage,
      enableShaderWriteUsage,
      mipLevelCount,
    );
  }

  GpuContext _gpuContext;

  final StorageMode storageMode;
  final PixelFormat format;
  final int width;
  final int height;
  final int sampleCount;
  final TextureType textureType;

  /// Enable using this texture as a render pass attachment.
  final bool enableRenderTargetUsage;

  /// Enable reading or sampling from this texture in a shader.
  final bool enableShaderReadUsage;

  /// Enable writing to the texture in a shader.
  ///
  /// Note that this is distinct from [enableRenderTargetUsage].
  final bool enableShaderWriteUsage;

  /// The number of mip levels allocated for this texture.
  ///
  /// A value of 1 means no mip chain (only the base level). Larger values
  /// allocate additional levels with halved dimensions per step. Use
  /// [Texture.fullMipCount] to compute the maximum for a given size.
  final int mipLevelCount;

  /// The number of slices in this texture. Determined by [textureType]:
  /// 1 for 2D and external textures, 6 for cubemap textures.
  int get sliceCount => textureType == TextureType.textureCube ? 6 : 1;

  TextureCoordinateSystem _coordinateSystem;
  TextureCoordinateSystem get coordinateSystem {
    return _coordinateSystem;
  }

  set coordinateSystem(TextureCoordinateSystem value) {
    value;
    _setCoordinateSystem(value.index);
  }

  int get bytesPerTexel {
    return _bytesPerTexel();
  }

  /// Returns the size in bytes of the [mipLevel] mip level (one slice). Mip
  /// dimensions are clamped at 1, matching standard mip chain semantics.
  int getMipLevelSizeInBytes(int mipLevel) {
    final int mipWidth = width >> mipLevel;
    final int mipHeight = height >> mipLevel;
    final int w = mipWidth > 0 ? mipWidth : 1;
    final int h = mipHeight > 0 ? mipHeight : 1;
    return bytesPerTexel * w * h;
  }

  /// Returns the size in bytes of the base mip level (one slice). Equivalent
  /// to `getMipLevelSizeInBytes(0)`.
  int getBaseMipLevelSizeInBytes() {
    return getMipLevelSizeInBytes(0);
  }

  /// Overwrites a mip level (and slice for cubemap textures) of this
  /// [Texture] with the contents of [sourceBytes].
  ///
  /// [mipLevel] selects which mip level to write to. Defaults to 0 (base
  /// level). Must be in the range `[0, mipLevelCount)`.
  ///
  /// [slice] selects which slice to write to for cubemap textures, where
  /// each face is a separate slice in the order
  /// `+X, -X, +Y, -Y, +Z, -Z`. Must be 0 for non-cubemap textures.
  ///
  /// The length of [sourceBytes] must exactly match the size of the
  /// requested mip level, which is `mipWidth * mipHeight * bytesPerTexel`
  /// (where `mipWidth` and `mipHeight` are the base dimensions right-shifted
  /// by [mipLevel], floored at 1).
  ///
  /// Throws an exception if the write fails due to an internal error or if
  /// any of the parameters are out of range.
  void overwrite(ByteData sourceBytes, {int mipLevel = 0, int slice = 0}) {
    if (mipLevel < 0 || mipLevel >= mipLevelCount) {
      throw Exception(
        'mipLevel ($mipLevel) must be in the range [0, $mipLevelCount) for this texture',
      );
    }
    final int slices = sliceCount;
    if (slice < 0 || slice >= slices) {
      throw Exception(
        'slice ($slice) must be in the range [0, $slices) for textures of type $textureType',
      );
    }
    final int expectedSize = getMipLevelSizeInBytes(mipLevel);
    if (sourceBytes.lengthInBytes != expectedSize) {
      throw Exception(
        'The length of sourceBytes (bytes: ${sourceBytes.lengthInBytes}) must exactly match the size of mip level $mipLevel (bytes: $expectedSize)',
      );
    }
    bool success = _overwrite(_gpuContext, sourceBytes, mipLevel, slice);
    if (!success) {
      throw Exception("Texture overwrite failed");
    }
  }

  ui.Image asImage() {
    if (!enableShaderReadUsage) {
      throw Exception(
        'Only shader readable Flutter GPU textures can be used as UI Images',
      );
    }
    return _asImage();
  }

  /// Wrap with native counterpart.
  @Native<
    Bool Function(
      Handle,
      Pointer<Void>,
      Int,
      Int,
      Int,
      Int,
      Int,
      Int,
      Int,
      Bool,
      Bool,
      Bool,
      Int,
    )
  >(symbol: 'InternalFlutterGpu_Texture_Initialize')
  external bool _initialize(
    GpuContext gpuContext,
    int storageMode,
    int format,
    int width,
    int height,
    int sampleCount,
    int coordinateSystem,
    int textureType,
    bool enableRenderTargetUsage,
    bool enableShaderReadUsage,
    bool enableShaderWriteUsage,
    int mipLevelCount,
  );

  @Native<Void Function(Handle, Int)>(
    symbol: 'InternalFlutterGpu_Texture_SetCoordinateSystem',
  )
  external void _setCoordinateSystem(int coordinateSystem);

  @Native<Int Function(Pointer<Void>)>(
    symbol: 'InternalFlutterGpu_Texture_BytesPerTexel',
  )
  external int _bytesPerTexel();

  @Native<Bool Function(Pointer<Void>, Pointer<Void>, Handle, Int, Int)>(
    symbol: 'InternalFlutterGpu_Texture_Overwrite',
  )
  external bool _overwrite(
    GpuContext gpuContext,
    ByteData bytes,
    int mipLevel,
    int slice,
  );

  @Native<Handle Function(Pointer<Void>)>(
    symbol: 'InternalFlutterGpu_Texture_AsImage',
  )
  external ui.Image _asImage();
}
