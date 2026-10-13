// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_TEXTURE_GL_STREAM_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_TEXTURE_GL_STREAM_H_

#include "flutter/common/graphics/texture.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "third_party/skia/include/core/SkM44.h"

namespace flutter {

//------------------------------------------------------------------------------
/// @brief      The callbacks of an OpenGL stream texture and the `user_data`
///             they take. The texture does not own `user_data`.
///
struct EmbedderOpenGLTextureStream {
  FlutterOpenGLTextureStreamSource callbacks = {};
  void* user_data = nullptr;
};

//------------------------------------------------------------------------------
/// @brief      Instances of external textures that draw the frames of an
///             embedder's OpenGL texture stream
///             (`kFlutterExternalTextureTypeOpenGLStream`), such as an
///             `android.graphics.SurfaceTexture`.
///
///             SurfaceTextures are used on older versions of Android (API <
///             29). On newer versions, the Android Hardware Buffer backend
///             `flutter::ImageExternalTexture` instances are used instead.
///
///             Due to the way surface textures are designed, a Vulkan renderer
///             cannot sample them directly. Skia and Impeller have OpenGL
///             implementations, and Impeller's Vulkan implementation on
///             Android copies each frame through an OpenGL ES context.
///
///             This is an abstract base class. Minimally, subclasses override
///             the pure virtual `ProcessFrame` method to bind the package
///             specific texture implementation to the surface texture.
///
class EmbedderExternalTextureGLStream : public flutter::Texture {
 public:
  //----------------------------------------------------------------------------
  /// @brief      Creates a texture that draws the frames of `stream`.
  ///
  EmbedderExternalTextureGLStream(int64_t id,
                                  EmbedderOpenGLTextureStream stream);

  // |Texture|
  ~EmbedderExternalTextureGLStream() override;

 protected:
  //----------------------------------------------------------------------------
  /// @brief      Subclasses override this method to bind the OpenGL texture
  ///             resource represented by this surface texture to the package
  ///             specific texture (SkImage, impeller::Texture, etc...).
  ///
  /// @important  The state of texture should be AttachmentState::kAttached
  ///             after a call to this method. That is the responsibility of the
  ///             subclass.
  ///
  /// @param      context  The context.
  /// @param[in]  bounds   The bounds of the texture.
  ///
  virtual void ProcessFrame(PaintContext& context, const SkRect& bounds) = 0;

  virtual void DrawFrame(PaintContext& context,
                         const SkRect& bounds,
                         const DlImageSampling sampling) const;

  //----------------------------------------------------------------------------
  /// @brief      Get the transformation that should be applied to the UV
  ///             texture coordinates when sampling from this texture.
  ///
  /// @return     The current uv transformation.
  ///
  const SkM44& GetCurrentUVTransformation() const;

  //----------------------------------------------------------------------------
  /// @brief      Provides an opportunity for the subclasses to sever the
  ///             connection between the OpenGL texture resource represented by
  ///             this surface texture and the underlying package handle
  ///             (SkImage, impeller::Texture, etc...).
  ///
  /// @important  It is the responsibility of the subclass to ensure that a
  ///             context is current when this call is made. Subclass can do
  ///             this by overriding this method, making the context current in
  ///             the implementation and calling the base class method.
  ///
  virtual void Detach();

  //----------------------------------------------------------------------------
  /// @brief      Attaches the given OpenGL texture handle to the surface
  ///             texture via a bind operation.
  ///
  /// @important  It is the responsibility of the subclass to ensure that a
  ///             context is current when this call is made. Subclass can do
  ///             this by overriding this method, making the context current in
  ///             the implementation and calling the base class method.
  ///
  /// @param[in]  gl_tex_id  The gl tex identifier
  ///
  void Attach(int gl_tex_id);

  bool ShouldUpdate();

  //----------------------------------------------------------------------------
  /// @brief      Update the surface texture contents and transformation matrix.
  ///
  void Update();

  //----------------------------------------------------------------------------
  /// @brief      Specifies how this instance is bound to the underlying surface
  ///             texture.
  ///
  enum class AttachmentState { kUninitialized, kAttached, kDetached };

  const EmbedderOpenGLTextureStream stream_;
  AttachmentState state_ = AttachmentState::kUninitialized;
  sk_sp<flutter::DlImage> dl_image_;

 private:
  SkM44 transform_;

  // |Texture|
  void Paint(PaintContext& context,
             const DlRect& bounds,
             bool freeze,
             const DlImageSampling sampling) override;

  // |ContextListener|
  void OnGrContextCreated() override;

  // |ContextListener|
  void OnGrContextDestroyed() override;

  // |Texture|
  void MarkNewFrameAvailable() override;

  // |Texture|
  void OnTextureUnregistered() override;

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderExternalTextureGLStream);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_TEXTURE_GL_STREAM_H_
