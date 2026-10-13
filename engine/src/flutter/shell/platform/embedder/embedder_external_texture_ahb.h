// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_TEXTURE_AHB_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_TEXTURE_AHB_H_

#include <memory>

#include "flutter/common/graphics/texture.h"
#include "flutter/fml/logging.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/embedder/embedder_image_lru.h"

namespace flutter {

//------------------------------------------------------------------------------
/// @brief      The callbacks of an Android hardware buffer texture and the
///             `user_data` they take. The texture does not own `user_data`.
///
struct EmbedderAndroidHardwareBufferSource {
  FlutterAndroidHardwareBufferSource callbacks = {};
  void* user_data = nullptr;
};

//------------------------------------------------------------------------------
/// @brief      External texture peered to a sequence of
///             android.hardware.HardwareBuffers.
///
///             Android Hardware Buffers are available on newer versions of
///             Android (API 29 and above).
///
///             This is an abstract base class and graphics packages provide
///             concrete implementations of this class that bind hardware
///             buffers to their own package-specific implementations of
///             textures (SkImages, impeller::Texture, etc...).
///
///             Android Hardware Buffers allow binding to both OpenGL and Vulkan
///             client-rendering APIs in a zero copy manner. Because of this
///             graphics packages that support OpenGL and Vulkan can have
///             multiple subclasses for each supported client-rendering API.
///
class EmbedderExternalTextureAHB : public flutter::Texture {
 public:
  //----------------------------------------------------------------------------
  /// @brief      Creates a texture that draws the frames of `source`.
  ///
  EmbedderExternalTextureAHB(int64_t id,
                             EmbedderAndroidHardwareBufferSource source);

  // |flutter::Texture|
  virtual ~EmbedderExternalTextureAHB();

 protected:
  //----------------------------------------------------------------------------
  /// @brief      Subclasses override this method to bind the latest
  ///             representation of the hardware buffer wrapped by this texture
  ///             instance to their own graphics package specific texture
  ///             classes (SkImage, impeller::Texture, etc...).
  ///
  ///             After a call to this method, attachment state of this instance
  ///             must be kAttached. That is the responsibility of the subclass.
  ///
  /// @param      context  The context
  /// @param[in]  bounds   The bounds
  ///
  virtual void ProcessFrame(PaintContext& context, const SkRect& bounds) = 0;

  virtual void Attach(PaintContext& context) = 0;

  virtual void Detach() = 0;

  //----------------------------------------------------------------------------
  /// @brief      A frame from the source. The source releases it when this
  ///             object is destroyed.
  ///
  class AcquiredFrame {
   public:
    explicit AcquiredFrame(const FlutterAndroidHardwareBufferFrame& frame);

    ~AcquiredFrame();

    /// The frame's buffer, an `AHardwareBuffer*`. May be null where the device
    /// cannot hand out AHardwareBuffers.
    FlutterAndroidHardwareBufferHandle buffer() const {
      return frame_.hardware_buffer;
    }

   private:
    const FlutterAndroidHardwareBufferFrame frame_;

    FML_DISALLOW_COPY_AND_ASSIGN(AcquiredFrame);
  };

  //----------------------------------------------------------------------------
  /// @return     The source's next frame, or null if it has none.
  ///
  std::unique_ptr<AcquiredFrame> AcquireFrame();

  const EmbedderAndroidHardwareBufferSource source_;

  enum class AttachmentState { kUninitialized, kAttached, kDetached };
  AttachmentState state_ = AttachmentState::kUninitialized;
  sk_sp<flutter::DlImage> dl_image_;
  ImageLRU image_lru_ = ImageLRU();

 private:
  // |flutter::Texture|.
  void Paint(PaintContext& context,
             const DlRect& bounds,
             bool freeze,
             const DlImageSampling sampling) override;

  // |flutter::Texture|.
  void MarkNewFrameAvailable() override;

  // |flutter::Texture|
  void OnTextureUnregistered() override;

  // |flutter::ContextListener|
  void OnGrContextCreated() override;

  // |flutter::ContextListener|
  void OnGrContextDestroyed() override;

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderExternalTextureAHB);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_TEXTURE_AHB_H_
