// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of flutter_gpu;

/// The result of presenting a [GpuSurfaceFrame].
///
/// Image surfaces always report [success]. The other values exist for
/// destinations whose presentation can fail or require reconfiguration, so that
/// one calling pattern is correct for every surface type.
enum GpuPresentStatus {
  /// The frame was presented and no reconfiguration is needed.
  success,

  /// The frame was presented, but the surface should be reconfigured before the
  /// next frame.
  suboptimal,

  /// The surface is out of date and must be reconfigured before presenting
  /// again.
  outOfDate,
}

/// A presentable Flutter GPU render target.
///
/// A surface vends [GpuSurfaceFrame]s. Each frame exposes a color texture to
/// render into and is published with [GpuSurfaceFrame.present]. The destination
/// of a surface is fixed when the surface is created.
///
/// Use [GpuContext.createImageSurface] to create an image surface that Flutter
/// draws as a [ui.Image].
sealed class GpuSurface {
  /// Acquires the next frame to render into, or null if no frame is available.
  ///
  /// Image surfaces always return a frame. The nullable result exists for
  /// destinations that may skip a frame, such as a throttled window swapchain.
  GpuSurfaceFrame? acquireNextFrame();
}

/// A writable frame acquired from a [GpuSurface].
///
/// A frame is a temporary write lease for [colorTexture]. Record the final
/// color writes into that texture, then call [present]. If the frame will not
/// be presented, call [discard] so the surface can reuse its backing texture.
///
/// Call exactly one of [present] or [discard] for each acquired frame. Calling
/// [discard] after [present] is a no-op, and calling [present] after [discard]
/// throws.
sealed class GpuSurfaceFrame {
  /// The color texture to use as the final render target for this frame.
  ///
  /// This texture is render-target and shader-read capable. It is writable
  /// until [present] or [discard] is called. After that point, applications
  /// must not render into it again.
  Texture get colorTexture;

  /// Publishes this frame and returns the presentation status.
  ///
  /// The [commandBuffer] must be the command buffer that contains the final
  /// writes to [colorTexture]. Call this method after recording those writes
  /// and before submitting [commandBuffer].
  ///
  /// Calling this method does not submit [commandBuffer]. You must submit it for
  /// the presented frame to be rendered.
  ///
  /// For an image surface, the published image is available from
  /// [GpuImageSurface.currentImage].
  GpuPresentStatus present(CommandBuffer commandBuffer);

  /// Releases this frame without presenting it.
  ///
  /// Use this when rendering is abandoned after acquiring a frame. Discarding a
  /// frame does not change [GpuImageSurface.currentImage].
  void discard();
}

/// A pool of presentable Flutter GPU render targets drawn by Flutter as a
/// [ui.Image].
///
/// An image surface is useful when GPU content is rendered repeatedly and then
/// drawn by Flutter as a [ui.Image]. It owns the final color textures that may
/// be sampled by Flutter after a frame is presented. The renderer is still
/// responsible for ordinary intermediate render targets such as depth, stencil,
/// multisample, shadow, or post-processing textures.
///
/// The surface chooses how many backing textures to retain. Applications
/// should acquire a frame when they are ready to render and let the surface
/// decide whether an existing texture can be reused or a new texture is needed.
///
/// To render a frame, call [acquireNextFrame], render into the returned
/// [GpuSurfaceFrame.colorTexture], call [GpuSurfaceFrame.present] with the
/// command buffer that contains the final writes, submit that command buffer,
/// and then draw [currentImage].
final class GpuImageSurface extends NativeFieldWrapperClass1
    implements GpuSurface {
  GpuImageSurface._(this._gpuContext, int width, int height, PixelFormat format)
    : _width = width,
      _height = height,
      _format = format {
    _checkDimensions(width, height);
    final String? error = _initialize(_gpuContext, width, height, format.index);
    if (error != null) {
      throw Exception(error);
    }
  }

  final GpuContext _gpuContext;

  int _width;
  int _height;
  PixelFormat _format;

  // The command buffer used to present the most recent frame. It is retained
  // only to detect the case where a frame is presented but its command buffer
  // is never submitted, which would leave the presented image blank forever.
  CommandBuffer? _pendingPresentCommandBuffer;

  /// The width, in pixels, of frames acquired from this surface.
  int get width => _width;

  /// The height, in pixels, of frames acquired from this surface.
  int get height => _height;

  /// The color format of frames acquired from this surface.
  PixelFormat get format => _format;

  /// The number of backing textures currently retained by this surface.
  ///
  /// This value is intended for diagnostics and tests. Applications should not
  /// branch on a particular count because the surface may grow the pool when
  /// Flutter or the GPU is still using older presented frames.
  int get debugBackingTextureCount => _getBackingTextureCount();

  /// The most recently presented image, or null if no frame has been presented.
  ///
  /// Each call returns a [ui.Image] handle for the current presented frame. The
  /// image remains valid even if later calls to [acquireNextFrame] return a
  /// different backing texture.
  ui.Image? get currentImage {
    final Object? result = _getCurrentImage();
    if (result == null) {
      return null;
    }
    return result as ui.Image;
  }

  /// Changes the size of future frames acquired from this surface.
  ///
  /// Existing images returned by [currentImage] remain valid. The next
  /// [acquireNextFrame] call returns a texture with the new dimensions. This
  /// method throws if a frame is currently acquired and has not been presented
  /// or discarded.
  void resize(int width, int height) {
    _checkDimensions(width, height);
    final String? error = _resize(width, height);
    if (error != null) {
      throw StateError(error);
    }
    _width = width;
    _height = height;
  }

  /// Acquires a color texture that can be used as the final render target.
  ///
  /// The returned [GpuImageSurfaceFrame] owns the write lease for its
  /// [GpuSurfaceFrame.colorTexture]. Renderers should write their final color
  /// result into that texture and then call [GpuSurfaceFrame.present].
  ///
  /// The surface will not return a backing texture that is still the current
  /// image, is waiting on producer GPU work, or is still referenced by Flutter.
  /// If no retained backing texture is available, the surface allocates another
  /// one.
  @override
  GpuImageSurfaceFrame acquireNextFrame() {
    _checkPreviousPresentSubmitted();
    final Texture texture = Texture._surface(
      _gpuContext,
      _format,
      _width,
      _height,
    );
    final int textureIndex = _acquireNextFrame(texture);
    if (textureIndex < 0) {
      throw Exception('Failed to acquire a Flutter GPU surface frame.');
    }
    texture._valid = true;
    return GpuImageSurfaceFrame._(this, textureIndex, texture);
  }

  void _presentFrame(GpuImageSurfaceFrame frame, CommandBuffer commandBuffer) {
    final Object? result = _presentFrameNative(
      frame._textureIndex,
      commandBuffer,
    );
    if (result is String) {
      throw Exception(result);
    }
    _pendingPresentCommandBuffer = commandBuffer;
  }

  // Verifies that the command buffer used to present the previous frame was
  // submitted. A presented frame is not rendered until its command buffer is
  // submitted, so a forgotten submit would otherwise silently leave the
  // surface's image blank.
  void _checkPreviousPresentSubmitted() {
    final CommandBuffer? commandBuffer = _pendingPresentCommandBuffer;
    if (commandBuffer != null && !commandBuffer.submitted) {
      throw StateError(
        'The command buffer used to present the previous GpuSurfaceFrame was '
        'never submitted. Call commandBuffer.submit() after '
        'GpuSurfaceFrame.present() so the presented frame is rendered.',
      );
    }
    _pendingPresentCommandBuffer = null;
  }

  void _discardFrame(GpuImageSurfaceFrame frame) {
    _discardFrameNative(frame._textureIndex);
  }

  static void _checkDimensions(int width, int height) {
    if (width <= 0) {
      throw ArgumentError.value(width, 'width', 'Must be greater than zero.');
    }
    if (height <= 0) {
      throw ArgumentError.value(height, 'height', 'Must be greater than zero.');
    }
  }

  @Native<Handle Function(Handle, Pointer<Void>, Int, Int, Int)>(
    symbol: 'InternalFlutterGpu_Surface_Initialize',
  )
  external String? _initialize(
    GpuContext gpuContext,
    int width,
    int height,
    int format,
  );

  @Native<Int Function(Pointer<Void>, Handle)>(
    symbol: 'InternalFlutterGpu_Surface_AcquireNextFrame',
  )
  external int _acquireNextFrame(Texture texture);

  @Native<Handle Function(Pointer<Void>, Int, Pointer<Void>)>(
    symbol: 'InternalFlutterGpu_Surface_PresentFrame',
  )
  external Object? _presentFrameNative(
    int textureIndex,
    CommandBuffer commandBuffer,
  );

  @Native<Void Function(Pointer<Void>, Int)>(
    symbol: 'InternalFlutterGpu_Surface_DiscardFrame',
  )
  external void _discardFrameNative(int textureIndex);

  @Native<Handle Function(Pointer<Void>)>(
    symbol: 'InternalFlutterGpu_Surface_GetCurrentImage',
  )
  external Object? _getCurrentImage();

  @Native<Handle Function(Pointer<Void>, Int, Int)>(
    symbol: 'InternalFlutterGpu_Surface_Resize',
  )
  external String? _resize(int width, int height);

  @Native<Int Function(Pointer<Void>)>(
    symbol: 'InternalFlutterGpu_Surface_GetBackingTextureCount',
  )
  external int _getBackingTextureCount();
}

/// A writable frame acquired from a [GpuImageSurface].
final class GpuImageSurfaceFrame implements GpuSurfaceFrame {
  GpuImageSurfaceFrame._(this._surface, this._textureIndex, this.colorTexture);

  final GpuImageSurface _surface;
  final int _textureIndex;
  bool _isActive = true;

  @override
  final Texture colorTexture;

  /// Publishes this frame as the current image for the surface.
  ///
  /// The [commandBuffer] must be the command buffer that contains the final
  /// writes to [colorTexture]. Call this method after recording those writes
  /// and before submitting [commandBuffer].
  ///
  /// Calling this method does not submit [commandBuffer]. It registers the
  /// frame with [commandBuffer] so the surface can use command buffer
  /// completion to decide when this texture can be considered for reuse.
  ///
  /// You must submit [commandBuffer] for the presented frame to be rendered.
  /// Until it is submitted, [GpuImageSurface.currentImage] will not contain
  /// this frame's contents, and the backing texture remains unavailable for
  /// future frames. If a frame is presented but its command buffer is never
  /// submitted, the next [GpuImageSurface.acquireNextFrame] throws a
  /// [StateError].
  ///
  /// The published image is available from [GpuImageSurface.currentImage].
  @override
  GpuPresentStatus present(CommandBuffer commandBuffer) {
    if (!_isActive) {
      throw StateError(
        'GpuSurfaceFrame has already been presented or discarded.',
      );
    }
    _surface._presentFrame(this, commandBuffer);
    _isActive = false;
    colorTexture._valid = false;
    return GpuPresentStatus.success;
  }

  /// Releases this frame without presenting it.
  ///
  /// Use this when rendering is abandoned after acquiring a frame. Discarding a
  /// frame does not change [GpuImageSurface.currentImage].
  @override
  void discard() {
    if (!_isActive) {
      return;
    }
    _isActive = false;
    colorTexture._valid = false;
    _surface._discardFrame(this);
  }
}
