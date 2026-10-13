// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_external_texture_ahb.h"

#include "flutter/display_list/geometry/dl_geometry_conversions.h"

#include "flutter/fml/trace_event.h"

namespace flutter {

EmbedderExternalTextureAHB::EmbedderExternalTextureAHB(
    int64_t id,
    EmbedderAndroidHardwareBufferSource source)
    : Texture(id), source_(source) {}

EmbedderExternalTextureAHB::~EmbedderExternalTextureAHB() = default;

void EmbedderExternalTextureAHB::Paint(PaintContext& context,
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
    FML_LOG(INFO)
        << "No DlImage available for EmbedderExternalTextureAHB to paint.";
  }
}

// Implementing flutter::Texture.
void EmbedderExternalTextureAHB::MarkNewFrameAvailable() {
  // NOOP.
}

// Implementing flutter::Texture.
void EmbedderExternalTextureAHB::OnTextureUnregistered() {}

// Implementing flutter::ContextListener.
void EmbedderExternalTextureAHB::OnGrContextCreated() {
  state_ = AttachmentState::kUninitialized;
}

// Implementing flutter::ContextListener.
void EmbedderExternalTextureAHB::OnGrContextDestroyed() {
  if (state_ == AttachmentState::kAttached) {
    if (source_.callbacks.drop_frames_on_context_destroyed) {
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

EmbedderExternalTextureAHB::AcquiredFrame::AcquiredFrame(
    const FlutterAndroidHardwareBufferFrame& frame)
    : frame_(frame) {}

EmbedderExternalTextureAHB::AcquiredFrame::~AcquiredFrame() {
  if (frame_.release_callback != nullptr) {
    frame_.release_callback(frame_.release_user_data);
  }
}

std::unique_ptr<EmbedderExternalTextureAHB::AcquiredFrame>
EmbedderExternalTextureAHB::AcquireFrame() {
  TRACE_EVENT0("flutter", "EmbedderExternalTextureAHB::AcquireFrame");
  FlutterAndroidHardwareBufferFrame frame = {
      .struct_size = sizeof(FlutterAndroidHardwareBufferFrame),
  };
  if (!source_.callbacks.acquire_frame_callback(source_.user_data, &frame)) {
    return nullptr;
  }
  return std::make_unique<AcquiredFrame>(frame);
}

}  // namespace flutter
