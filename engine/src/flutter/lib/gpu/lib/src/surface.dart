// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of flutter_gpu;

/// A pool of presentable Flutter GPU render targets.
///
/// A surface is useful when GPU content is rendered repeatedly and then drawn
/// by Flutter as a [ui.Image]. It owns the final color textures that may be
/// sampled by Flutter after a frame is presented. The renderer is still
/// responsible for ordinary intermediate render targets such as depth, stencil,
/// multisample, shadow, or post-processing textures.
///
/// The surface chooses how many backing textures to retain. Applications
/// should acquire a frame when they are ready to render and let the surface
/// decide whether an existing texture can be reused or a new texture is needed.
///
/// To render a frame, call [acquireNextFrame], render into the returned
/// [SurfaceFrame.colorTexture], call [SurfaceFrame.present] with the command
/// buffer that contains the final writes, submit that command buffer, and then
/// draw [currentImage].
final class GpuSurface extends NativeFieldWrapperClass1 {
  GpuSurface._(this._gpuContext, int width, int height, PixelFormat format)
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
  /// The returned [SurfaceFrame] owns the write lease for its
  /// [SurfaceFrame.colorTexture]. Renderers should write their final color
  /// result into that texture and then call [SurfaceFrame.present].
  ///
  /// The surface will not return a backing texture that is still the current
  /// image, is waiting on producer GPU work, or is still referenced by Flutter.
  /// If no retained backing texture is available, the surface allocates another
  /// one.
  SurfaceFrame acquireNextFrame() {
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
    return SurfaceFrame._(this, textureIndex, texture);
  }

  ui.Image _presentFrame(SurfaceFrame frame, CommandBuffer commandBuffer) {
    final Object? result = _presentFrameNative(
      frame._textureIndex,
      commandBuffer,
    );
    if (result is String) {
      throw Exception(result);
    }
    return result! as ui.Image;
  }

  void _discardFrame(SurfaceFrame frame) {
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

/// A writable frame acquired from a [GpuSurface].
///
/// A frame represents a temporary write lease for [colorTexture]. Once the
/// renderer has recorded all commands that write the final color result, call
/// [present] to publish the frame as the surface's current image. If the frame
/// will not be presented, call [discard] so the surface can reuse its backing
/// texture.
final class SurfaceFrame {
  SurfaceFrame._(this._surface, this._textureIndex, this.colorTexture);

  final GpuSurface _surface;
  final int _textureIndex;
  bool _isActive = true;

  /// The color texture to use as the final render target for this frame.
  ///
  /// This texture is render-target and shader-read capable. It is writable
  /// until [present] or [discard] is called. After that point, applications
  /// must not render into it again.
  final Texture colorTexture;

  /// Publishes this frame as the current image for the surface.
  ///
  /// The [commandBuffer] must be the command buffer that contains the final
  /// writes to [colorTexture]. Call this method after recording those writes
  /// and before submitting [commandBuffer].
  ///
  /// Calling this method does not submit [commandBuffer]. It registers the
  /// frame with [commandBuffer] so the surface can use command buffer
  /// completion to decide when this texture can be considered for reuse. If the
  /// command buffer is never submitted, the texture remains unavailable for
  /// future frames.
  ///
  /// The returned [ui.Image] is also available from [GpuSurface.currentImage].
  ui.Image present(CommandBuffer commandBuffer) {
    if (!_isActive) {
      throw StateError('SurfaceFrame has already been presented or discarded.');
    }
    final ui.Image image = _surface._presentFrame(this, commandBuffer);
    _isActive = false;
    colorTexture._valid = false;
    return image;
  }

  /// Releases this frame without presenting it.
  ///
  /// Use this when rendering is abandoned after acquiring a frame. Discarding a
  /// frame does not change [GpuSurface.currentImage].
  void discard() {
    if (!_isActive) {
      return;
    }
    _isActive = false;
    colorTexture._valid = false;
    _surface._discardFrame(this);
  }
}
