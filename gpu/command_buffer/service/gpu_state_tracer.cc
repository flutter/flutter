// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/gpu_state_tracer.h"

#include "base/base64.h"
#include "base/trace_event/trace_event.h"
#include "context_state.h"
#include "ui/gfx/codec/png_codec.h"
#include "ui/gl/gl_bindings.h"

namespace gpu {
namespace gles2 {
namespace {

const int kBytesPerPixel = 4;

class Snapshot : public base::trace_event::ConvertableToTraceFormat {
 public:
  static scoped_refptr<Snapshot> Create(const ContextState* state);

  // Save a screenshot of the currently bound framebuffer.
  bool SaveScreenshot(const gfx::Size& size);

  // base::trace_event::ConvertableToTraceFormat implementation.
  void AppendAsTraceFormat(std::string* out) const override;

 private:
  explicit Snapshot(const ContextState* state);
  ~Snapshot() override {}

  const ContextState* state_;

  std::vector<unsigned char> screenshot_pixels_;
  gfx::Size screenshot_size_;

  DISALLOW_COPY_AND_ASSIGN(Snapshot);
};

}  // namespace

Snapshot::Snapshot(const ContextState* state) : state_(state) {}

scoped_refptr<Snapshot> Snapshot::Create(const ContextState* state) {
  return scoped_refptr<Snapshot>(new Snapshot(state));
}

bool Snapshot::SaveScreenshot(const gfx::Size& size) {
  screenshot_size_ = size;
  screenshot_pixels_.resize(screenshot_size_.width() *
                            screenshot_size_.height() * kBytesPerPixel);

  glPixelStorei(GL_PACK_ALIGNMENT, kBytesPerPixel);
  glReadPixels(0,
               0,
               screenshot_size_.width(),
               screenshot_size_.height(),
               GL_RGBA,
               GL_UNSIGNED_BYTE,
               &screenshot_pixels_[0]);
  glPixelStorei(GL_PACK_ALIGNMENT, state_->pack_alignment);

  // Flip the screenshot vertically.
  int bytes_per_row = screenshot_size_.width() * kBytesPerPixel;
  for (int y = 0; y < screenshot_size_.height() / 2; y++) {
    for (int x = 0; x < bytes_per_row; x++) {
      std::swap(screenshot_pixels_[y * bytes_per_row + x],
                screenshot_pixels_
                    [(screenshot_size_.height() - y - 1) * bytes_per_row + x]);
    }
  }
  return true;
}

void Snapshot::AppendAsTraceFormat(std::string* out) const {
  *out += "{";
  if (screenshot_pixels_.size()) {
    std::vector<unsigned char> png_data;
    int bytes_per_row = screenshot_size_.width() * kBytesPerPixel;
    bool png_ok = gfx::PNGCodec::Encode(&screenshot_pixels_[0],
                                        gfx::PNGCodec::FORMAT_RGBA,
                                        screenshot_size_,
                                        bytes_per_row,
                                        false,
                                        std::vector<gfx::PNGCodec::Comment>(),
                                        &png_data);
    DCHECK(png_ok);

    base::StringPiece base64_input(reinterpret_cast<const char*>(&png_data[0]),
                                   png_data.size());
    std::string base64_output;
    Base64Encode(base64_input, &base64_output);

    *out += "\"screenshot\":\"" + base64_output + "\"";
  }
  *out += "}";
}

scoped_ptr<GPUStateTracer> GPUStateTracer::Create(const ContextState* state) {
  return scoped_ptr<GPUStateTracer>(new GPUStateTracer(state));
}

GPUStateTracer::GPUStateTracer(const ContextState* state) : state_(state) {
  TRACE_EVENT_OBJECT_CREATED_WITH_ID(
      TRACE_DISABLED_BY_DEFAULT("gpu.debug"), "gpu::State", state_);
}

GPUStateTracer::~GPUStateTracer() {
  TRACE_EVENT_OBJECT_DELETED_WITH_ID(
      TRACE_DISABLED_BY_DEFAULT("gpu.debug"), "gpu::State", state_);
}

void GPUStateTracer::TakeSnapshotWithCurrentFramebuffer(const gfx::Size& size) {
  TRACE_EVENT0(TRACE_DISABLED_BY_DEFAULT("gpu.debug"),
               "GPUStateTracer::TakeSnapshotWithCurrentFramebuffer");

  scoped_refptr<Snapshot> snapshot(Snapshot::Create(state_));

  // Only save a screenshot for now.
  if (!snapshot->SaveScreenshot(size))
    return;

  TRACE_EVENT_OBJECT_SNAPSHOT_WITH_ID(
      TRACE_DISABLED_BY_DEFAULT("gpu.debug"),
      "gpu::State",
      state_,
      scoped_refptr<base::trace_event::ConvertableToTraceFormat>(snapshot));
}

}  // namespace gles2
}  // namespace gpu
