// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/surface_texture_external_texture_gl_impeller.h"

#include "flutter/impeller/display_list/dl_image_impeller.h"
#include "flutter/impeller/entity/contents/tiled_texture_contents.h"
#include "flutter/impeller/entity/entity.h"
#include "flutter/impeller/entity/geometry/geometry.h"

namespace flutter {

SurfaceTextureExternalTextureGLImpeller::
    SurfaceTextureExternalTextureGLImpeller(
        const std::shared_ptr<impeller::ContextGLES>& context,
        int64_t id,
        const fml::jni::ScopedJavaGlobalRef<jobject>& surface_texture,
        const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade)
    : SurfaceTextureExternalTexture(id, surface_texture, jni_facade),
      impeller_context_(context) {}

SurfaceTextureExternalTextureGLImpeller::
    ~SurfaceTextureExternalTextureGLImpeller() = default;

sk_sp<flutter::DlImage>
SurfaceTextureExternalTextureGLImpeller::GetTextureImage(PaintContext& context,
                                                         const DlRect& bounds,
                                                         bool freeze) {
  sk_sp<DlImage> image =
      SurfaceTextureExternalTexture::GetTextureImage(context, bounds, freeze);
  if (!image) {
    return nullptr;
  }

  // When snapshotted (e.g., via getImageFromTexture where context.canvas is
  // null), we must rasterize the OES texture into a standard 2D texture because
  // OES textures report a 1x1 size and lack UV matrix support in standard
  // Impeller shaders.
  // See also:
  // https://registry.khronos.org/OpenGL/extensions/OES/OES_EGL_image_external.txt
  if (context.canvas == nullptr && context.aiks_context != nullptr) {
    auto texture = image->impeller_texture();
    if (!texture) {
      return image;
    }

    auto contents = std::make_shared<impeller::TiledTextureContents>();
    contents->SetTexture(texture);

    auto geometry = impeller::Geometry::MakeRect(
        impeller::Rect::MakeXYWH(0, 0, bounds.GetWidth(), bounds.GetHeight()));

    contents->SetGeometry(geometry.get());

    impeller::Matrix dl_transform;
    GetCurrentUVTransformation().getColMajor(
        reinterpret_cast<SkScalar*>(&dl_transform));
    dl_transform = dl_transform.Invert();

    impeller::Matrix effect_transform =
        impeller::Matrix::MakeTranslation(
            {0.0f, static_cast<float>(bounds.GetHeight()), 0.0f}) *
        impeller::Matrix::MakeScale({static_cast<float>(bounds.GetWidth()),
                                     -static_cast<float>(bounds.GetHeight()),
                                     1.0f}) *
        dl_transform;

    contents->SetEffectTransform(effect_transform);

    impeller::Entity entity;
    entity.SetBlendMode(impeller::BlendMode::kSrc);

    auto snapshot = contents->RenderToSnapshot(
        context.aiks_context->GetContentContext(), entity,
        impeller::Contents::SnapshotOptions{
            .label = "OES Rasterization Snapshot",
        });

    if (snapshot.has_value()) {
      return impeller::DlImageImpeller::Make(snapshot.value().texture);
    }
  }

  return image;
}

void SurfaceTextureExternalTextureGLImpeller::ProcessFrame(
    PaintContext& context,
    const SkRect& bounds) {
  if (state_ == AttachmentState::kUninitialized) {
    // Generate the texture handle.
    impeller::TextureDescriptor desc;
    desc.type = impeller::TextureType::kTextureExternalOES;
    desc.storage_mode = impeller::StorageMode::kDevicePrivate;
    desc.format = impeller::PixelFormat::kR8G8B8A8UNormInt;
    desc.size = {1, 1};
    desc.mip_count = 1;
    texture_ = std::make_shared<impeller::TextureGLES>(
        impeller_context_->GetReactor(), desc);
    // The contents will be initialized later in the call to `Attach` instead of
    // by Impeller.
    texture_->MarkContentsInitialized();
    texture_->SetCoordinateSystem(
        impeller::TextureCoordinateSystem::kUploadFromHost);
    auto maybe_handle = texture_->GetGLHandle();
    if (!maybe_handle.has_value()) {
      FML_LOG(ERROR) << "Could not get GL handle from impeller::TextureGLES!";
      return;
    }
    Attach(maybe_handle.value());
  }
  FML_CHECK(state_ == AttachmentState::kAttached);

  // Updates the texture contents and transformation matrix.
  Update();

  dl_image_ = impeller::DlImageImpeller::Make(texture_);
}

void SurfaceTextureExternalTextureGLImpeller::Detach() {
  SurfaceTextureExternalTexture::Detach();
  // Detach will collect the texture handle.
  // See also: https://github.com/flutter/flutter/issues/152459
  texture_->Leak();
  texture_.reset();
}

}  // namespace flutter
