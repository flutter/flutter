// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

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

  /// A supported [PixelFormat] for textures that store 4-channel colors
  /// (red/green/blue/alpha).
  PixelFormat get defaultColorFormat {
    return PixelFormat.values[_getDefaultColorFormat()];
  }

  /// A supported [PixelFormat] for textures that store stencil information.
  /// May include a depth channel if a stencil-only format is not available.
  PixelFormat get defaultStencilFormat {
    return PixelFormat.values[_getDefaultStencilFormat()];
  }

  /// A supported `PixelFormat` for textures that store both a stencil and depth
  /// component. This will never return a depth-only or stencil-only texture.
  ///
  /// May be [PixelFormat.unknown] if no suitable depth+stencil format was
  /// found.
  PixelFormat get defaultDepthStencilFormat {
    return PixelFormat.values[_getDefaultDepthStencilFormat()];
  }

  /// The minimum alignment required when referencing uniform blocks stored in a
  /// `DeviceBuffer`.
  int get minimumUniformByteAlignment {
    return _getMinimumUniformByteAlignment();
  }

  /// Whether the backend supports multisample anti-aliasing for offscreen
  /// color and stencil attachments. A subset of OpenGLES-only devices do not
  /// support this functionality.
  ///
  /// Any texture created via [createTexture] is an offscreen texture.
  /// There is currently no way to render directly against the "onscreen"
  /// texture that the framework renders to, so all Flutter GPU textures are
  /// "offscreen".
  bool get doesSupportOffscreenMSAA {
    return _getSupportsOffscreenMSAA();
  }

  /// Whether the backend can attach a non-zero mip level of a texture as a
  /// render target (see [ColorAttachment.mipLevel]). Rendering into a cube map
  /// face or array layer is always supported; only non-zero mip levels are
  /// gated. True on Metal and Vulkan; currently false on the GLES backend,
  /// where rendering into non-zero mip levels is not yet implemented.
  bool get doesSupportFramebufferRenderMipmap {
    return _getSupportsFramebufferRenderMipmap();
  }

  /// Whether a texture whose mip levels were uploaded by hand with
  /// [Texture.overwrite] (rather than generated with
  /// [CommandBuffer.generateMipmap]) samples with correct per-level selection.
  /// True on Metal and Vulkan; on OpenGL ES 2.0 devices without the
  /// GL_APPLE_texture_max_level extension this is false, and sampling such a
  /// texture reads as black. Check this before relying on hand-built mip
  /// chains (for example, prefiltered environment maps).
  bool get doesSupportManuallyMippedTextures {
    return _getSupportsManuallyMippedTextures();
  }

  /// Whether this device supports the given family of block-compressed
  /// texture formats. Hardware support is granted on a per-family basis.
  ///
  /// Compressed textures are always sample-only (no render target, no shader
  /// write, no multisampling, and dimensions must be a multiple of the format
  /// block size). [supportsTextureFormat] can be used for a per-format check.
  bool supportsTextureCompression(TextureCompressionFamily family) {
    return _supportsTextureCompression(family.index);
  }

  /// Whether this device can allocate a texture of the given [format] with
  /// the requested usage flags.
  ///
  /// For block-compressed formats this returns false if either [renderTarget]
  /// or [shaderWrite] is true, since compressed formats are sample-only.
  /// For uncompressed formats this currently returns true: today the
  /// underlying capability surface does not vary by per-format usage.
  bool supportsTextureFormat(
    PixelFormat format, {
    bool renderTarget = false,
    bool shaderRead = true,
    bool shaderWrite = false,
  }) {
    return _supportsTextureFormat(
      format.index,
      renderTarget,
      shaderRead,
      shaderWrite,
    );
  }

  /// Allocates a new region of GPU-resident memory.
  ///
  /// The [storageMode] must be either [StorageMode.hostVisible] or
  /// [StorageMode.devicePrivate], otherwise an exception will be thrown.
  ///
  /// Throws an exception if the [DeviceBuffer] creation failed.
  DeviceBuffer createDeviceBuffer(StorageMode storageMode, int sizeInBytes) {
    if (storageMode == StorageMode.deviceTransient) {
      throw Exception(
        'DeviceBuffers cannot be set to StorageMode.deviceTransient',
      );
    }
    DeviceBuffer result = DeviceBuffer._initialize(
      this,
      storageMode,
      sizeInBytes,
    );
    if (!result.isValid) {
      throw Exception('DeviceBuffer creation failed');
    }
    return result;
  }

  /// Allocates a new region of host-visible GPU-resident memory, initialized
  /// with the given [data].
  ///
  /// Given that the buffer will be immediately populated with [data] uploaded
  /// from the host, the [StorageMode] of the new [DeviceBuffer] is
  /// automatically set to [StorageMode.hostVisible].
  ///
  /// Throws an exception if the [DeviceBuffer] creation failed.
  DeviceBuffer createDeviceBufferWithCopy(ByteData data) {
    DeviceBuffer result = DeviceBuffer._initializeWithHostData(this, data);
    if (!result.isValid) {
      throw Exception('DeviceBuffer creation failed');
    }
    return result;
  }

  /// Creates a bump allocator that managed a [DeviceBuffer] block list.
  ///
  /// See also [HostBuffer].
  HostBuffer createHostBuffer({
    int blockLengthInBytes = HostBuffer.kDefaultBlockLengthInBytes,
  }) {
    return HostBuffer._initialize(this, blockLengthInBytes: blockLengthInBytes);
  }

  /// Allocates a new texture in GPU-resident memory.
  ///
  /// [mipLevelCount] specifies the number of mip levels to allocate for the
  /// texture. The default is 1 (no mip chain). Use [Texture.fullMipCount] to
  /// allocate a full chain. Must be in the range
  /// `[1, Texture.fullMipCount(width, height)]`.
  ///
  /// Throws an exception if the [Texture] creation failed.
  Texture createTexture(
    StorageMode storageMode,
    int width,
    int height, {
    PixelFormat format = PixelFormat.r8g8b8a8UNormInt,
    sampleCount = 1,

    /// The type of texture to create.
    ///
    /// If not specified, this will be inferred from the `sampleCount`.
    TextureType? textureType,
    bool enableRenderTargetUsage = true,
    bool enableShaderReadUsage = true,
    bool enableShaderWriteUsage = false,
    int mipLevelCount = 1,
  }) {
    final resolvedTextureType =
        textureType ??
        ((sampleCount == 1)
            ? TextureType.texture2D
            : TextureType.texture2DMultisample);
    final int maxMipLevels = Texture.fullMipCount(width, height);
    if (mipLevelCount < 1 || mipLevelCount > maxMipLevels) {
      throw Exception(
        'mipLevelCount ($mipLevelCount) must be in the range [1, $maxMipLevels] '
        'for a ${width}x$height texture',
      );
    }
    if (format.isCompressed) {
      if (enableRenderTargetUsage ||
          enableShaderWriteUsage ||
          !enableShaderReadUsage ||
          sampleCount != 1 ||
          storageMode == StorageMode.deviceTransient) {
        throw ArgumentError(
          'Compressed pixel format $format can only be used as a sample-only '
          'texture (sampleCount=1, enableShaderReadUsage=true, no render '
          'target, no shader write, and storageMode != deviceTransient)',
        );
      }
      final int bw = format.blockWidth;
      final int bh = format.blockHeight;
      if (width % bw != 0 || height % bh != 0) {
        throw ArgumentError(
          'Compressed pixel format $format requires width and height to be a '
          'multiple of the block size (${bw}x$bh), got ${width}x$height',
        );
      }
    }
    Texture result = Texture._initialize(
      this,
      storageMode,
      format,
      width,
      height,
      sampleCount,
      resolvedTextureType,
      enableRenderTargetUsage,
      enableShaderReadUsage,
      enableShaderWriteUsage,
      mipLevelCount,
    );
    // `Texture._initialize` throws on failure, so `result` is always valid here.
    return result;
  }

  /// Create a new command buffer that can be used to submit GPU commands.
  CommandBuffer createCommandBuffer() {
    return CommandBuffer._(this);
  }

  RenderPipeline createRenderPipeline(
    Shader vertexShader,
    Shader fragmentShader, {
    VertexLayout? vertexLayout,
  }) {
    return RenderPipeline._(
      this,
      vertexShader,
      fragmentShader,
      vertexLayout: vertexLayout,
    );
  }

  /// Associates the default Impeller context with this Context.
  @Native<Handle Function(Handle)>(
    symbol: 'InternalFlutterGpu_Context_InitializeDefault',
  )
  external String? _initializeDefault();

  @Native<Int Function(Pointer<Void>)>(
    symbol: 'InternalFlutterGpu_Context_GetDefaultColorFormat',
  )
  external int _getDefaultColorFormat();

  @Native<Int Function(Pointer<Void>)>(
    symbol: 'InternalFlutterGpu_Context_GetDefaultStencilFormat',
  )
  external int _getDefaultStencilFormat();

  @Native<Int Function(Pointer<Void>)>(
    symbol: 'InternalFlutterGpu_Context_GetDefaultDepthStencilFormat',
  )
  external int _getDefaultDepthStencilFormat();

  @Native<Int Function(Pointer<Void>)>(
    symbol: 'InternalFlutterGpu_Context_GetMinimumUniformByteAlignment',
  )
  external int _getMinimumUniformByteAlignment();

  @Native<Bool Function(Pointer<Void>)>(
    symbol: 'InternalFlutterGpu_Context_GetSupportsOffscreenMSAA',
  )
  external bool _getSupportsOffscreenMSAA();

  @Native<Bool Function(Pointer<Void>)>(
    symbol: 'InternalFlutterGpu_Context_GetSupportsFramebufferRenderMipmap',
  )
  external bool _getSupportsFramebufferRenderMipmap();

  @Native<Bool Function(Pointer<Void>)>(
    symbol: 'InternalFlutterGpu_Context_GetSupportsManuallyMippedTextures',
  )
  external bool _getSupportsManuallyMippedTextures();

  @Native<Bool Function(Pointer<Void>, Int)>(
    symbol: 'InternalFlutterGpu_Context_SupportsTextureCompression',
  )
  external bool _supportsTextureCompression(int family);

  @Native<Bool Function(Pointer<Void>, Int, Bool, Bool, Bool)>(
    symbol: 'InternalFlutterGpu_Context_SupportsTextureFormat',
  )
  external bool _supportsTextureFormat(
    int format,
    bool renderTarget,
    bool shaderRead,
    bool shaderWrite,
  );
}

/// The default graphics context.
final GpuContext gpuContext = GpuContext._createDefault();
