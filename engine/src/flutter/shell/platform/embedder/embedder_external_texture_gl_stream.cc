// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_external_texture_gl_stream.h"

#include "flutter/display_list/geometry/dl_geometry_conversions.h"

#include <utility>

#include "flutter/display_list/effects/dl_color_source.h"

namespace flutter {

EmbedderExternalTextureGLStream::EmbedderExternalTextureGLStream(
    int64_t id,
    EmbedderOpenGLTextureStream stream)
    : Texture(id), stream_(stream), transform_(SkMatrix::I()) {}

EmbedderExternalTextureGLStream::~EmbedderExternalTextureGLStream() = default;

void EmbedderExternalTextureGLStream::OnGrContextCreated() {
  state_ = AttachmentState::kUninitialized;
}

void EmbedderExternalTextureGLStream::MarkNewFrameAvailable() {
  // NOOP.
}

void EmbedderExternalTextureGLStream::Paint(PaintContext& context,
                                            const DlRect& bounds,
                                            bool freeze,
                                            const DlImageSampling sampling) {
  if (state_ == AttachmentState::kDetached) {
    return;
  }
  const bool should_process_frame =
      !freeze || ShouldUpdate() || dl_image_ == nullptr;
  if (should_process_frame) {
    ProcessFrame(context, ToSkRect(bounds));
  }
  // If process frame failed, this may not be in attached state.
  if (state_ != AttachmentState::kAttached) {
    return;
  }

  if (!dl_image_) {
    FML_LOG(WARNING)
        << "No DlImage available for EmbedderExternalTextureGLStream to paint.";
    return;
  }

  DrawFrame(context, ToSkRect(bounds), sampling);
}

void EmbedderExternalTextureGLStream::DrawFrame(
    PaintContext& context,
    const SkRect& bounds,
    const DlImageSampling sampling) const {
  auto transform = ToDlMatrix(GetCurrentUVTransformation());

  // Android's SurfaceTexture transform matrix works on texture coordinate
  // lookups in the range 0.0-1.0, while Skia's Shader transform matrix works on
  // the image itself, as if it were inscribed inside a clip rect.
  // An Android transform that scales lookup by 0.5 (displaying 50% of the
  // texture) is the same as a Skia transform by 2.0 (scaling 50% of the image
  // outside of the virtual "clip rect"), so we invert the incoming matrix.

  if (transform.IsIdentity()) {
    context.canvas->DrawImage(dl_image_, DlPoint{0, 0}, sampling,
                              context.paint);
    return;
  }

  if (!transform.IsInvertible()) {
    FML_LOG(FATAL)
        << "Invalid (not invertable) SurfaceTexture transformation matrix";
  }
  transform = transform.Invert();

  DlAutoCanvasRestore autoRestore(context.canvas, true);

  // The incoming texture is vertically flipped, so we flip it
  // back. OpenGL's coordinate system has Positive Y equivalent to up, while
  // Skia's coordinate system has Negative Y equvalent to up.
  context.canvas->Translate(bounds.x(), bounds.y() + bounds.height());
  context.canvas->Scale(bounds.width(), -bounds.height());

  auto source = DlColorSource::MakeImage(
      dl_image_, DlTileMode::kClamp, DlTileMode::kClamp, sampling, &transform);

  DlPaint paintWithShader;
  if (context.paint) {
    paintWithShader = *context.paint;
  }
  paintWithShader.setColorSource(source);
  context.canvas->DrawRect(DlRect::MakeWH(1, 1), paintWithShader);
}

void EmbedderExternalTextureGLStream::OnGrContextDestroyed() {
  if (state_ == AttachmentState::kAttached) {
    Detach();
  }
  state_ = AttachmentState::kDetached;
}

void EmbedderExternalTextureGLStream::OnTextureUnregistered() {}

void EmbedderExternalTextureGLStream::Detach() {
  stream_.callbacks.detach_callback(stream_.user_data);
  dl_image_.reset();
}

void EmbedderExternalTextureGLStream::Attach(int gl_tex_id) {
  stream_.callbacks.attach_callback(stream_.user_data,
                                    static_cast<uint32_t>(gl_tex_id));
  state_ = AttachmentState::kAttached;
}

bool EmbedderExternalTextureGLStream::ShouldUpdate() {
  return stream_.callbacks.has_pending_frame_callback != nullptr &&
         stream_.callbacks.has_pending_frame_callback(stream_.user_data);
}

void EmbedderExternalTextureGLStream::Update() {
  float transformation[16];
  stream_.callbacks.update_callback(stream_.user_data, transformation);
  static_assert(sizeof(SkScalar) == sizeof(float));
  transform_ = SkM44::ColMajor(transformation);
}

const SkM44& EmbedderExternalTextureGLStream::GetCurrentUVTransformation()
    const {
  return transform_;
}

}  // namespace flutter
