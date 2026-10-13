// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/image_external_texture.h"

#include "flutter/display_list/geometry/dl_geometry_conversions.h"

#include "flutter/fml/trace_event.h"

namespace flutter {

ImageExternalTexture::ImageExternalTexture(int64_t id,
                                           HardwareBufferSource source)
    : Texture(id), source_(source) {}

ImageExternalTexture::~ImageExternalTexture() {
  if (source_.destruction != nullptr) {
    source_.destruction(source_.user_data);
  }
}
void ImageExternalTexture::Paint(PaintContext& context,
                                 const DlRect& bounds,
                                 bool freeze,
                                 const DlImageSampling sampling) {
  if (state_ == AttachmentState::kDetached) {
    return;
  }
  Attach(context);
  const bool should_process_frame = !freeze;
  if (should_process_frame) {
    ProcessFrame(context, ToSkRect(bounds));
  }
  if (dl_image_) {
    context.canvas->DrawImageRect(
        dl_image_,                             // image
        DlRect::Make(dl_image_->GetBounds()),  // source rect
        bounds,                                // destination rect
        sampling,                              // sampling
        context.paint,                         // paint
        flutter::DlSrcRectConstraint::kStrict  // enforce edges
    );
  } else {
    FML_LOG(INFO) << "No DlImage available for ImageExternalTexture to paint.";
  }
}

// Implementing flutter::Texture.
void ImageExternalTexture::MarkNewFrameAvailable() {
  // NOOP.
}

// Implementing flutter::Texture.
void ImageExternalTexture::OnTextureUnregistered() {}

// Implementing flutter::ContextListener.
void ImageExternalTexture::OnGrContextCreated() {
  state_ = AttachmentState::kUninitialized;
}

// Implementing flutter::ContextListener.
void ImageExternalTexture::OnGrContextDestroyed() {
  if (state_ == AttachmentState::kAttached) {
    if (source_.drop_frames_on_context_destroyed) {
      dl_image_.reset();
      image_lru_.Clear();
    }
    // Otherwise intentionally do nothing.
    //
    // If we reset the image, we are not able to re-acquire it, but the
    // producer of the image will not know to reproduce it, resulting in a
    // blank image. See https://github.com/flutter/flutter/issues/163561.
    Detach();
  }
  state_ = AttachmentState::kDetached;
}

ImageExternalTexture::AcquiredFrame::AcquiredFrame(
    const HardwareBufferFrame& frame)
    : frame_(frame) {}

ImageExternalTexture::AcquiredFrame::~AcquiredFrame() {
  if (frame_.release != nullptr) {
    frame_.release(frame_.release_user_data);
  }
}

std::unique_ptr<ImageExternalTexture::AcquiredFrame>
ImageExternalTexture::AcquireFrame() {
  TRACE_EVENT0("flutter", "ImageExternalTexture::AcquireFrame");
  HardwareBufferFrame frame;
  if (!source_.acquire_frame(source_.user_data, &frame)) {
    return nullptr;
  }
  return std::make_unique<AcquiredFrame>(frame);
}

}  // namespace flutter
