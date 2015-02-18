// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/ui/engine.h"

#include "base/bind.h"
#include "sky/engine/public/web/Sky.h"
#include "sky/engine/public/web/WebLocalFrame.h"
#include "sky/engine/public/web/WebView.h"
#include "sky/shell/ui/animator.h"
#include "sky/shell/ui/platform_impl.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"

namespace sky {
namespace shell {

Engine::Engine(const Config& config)
    : animator_(new Animator(config, this)),
      web_view_(nullptr),
      weak_factory_(this) {
}

Engine::~Engine() {
  if (web_view_)
    web_view_->close();
}

base::WeakPtr<Engine> Engine::GetWeakPtr() {
  return weak_factory_.GetWeakPtr();
}

void Engine::Init(mojo::ScopedMessagePipeHandle service_provider) {
  platform_impl_.reset(new PlatformImpl(
      mojo::MakeProxy<mojo::ServiceProvider>(service_provider.Pass())));
  blink::initialize(platform_impl_.get());

  web_view_ = blink::WebView::create(this);
  web_view_->setMainFrame(blink::WebLocalFrame::create(this));
  web_view_->mainFrame()->load(
      GURL("http://127.0.0.1:8000/sky/examples/spinning-square.sky"));
}

void Engine::BeginFrame(base::TimeTicks frame_time) {
  double frame_time_sec = (frame_time - base::TimeTicks()).InSecondsF();
  double deadline_sec = frame_time_sec;
  double interval_sec = 1.0 / 60;
  blink::WebBeginFrameArgs args(frame_time_sec, deadline_sec, interval_sec);

  web_view_->beginFrame(args);
  web_view_->layout();
}

skia::RefPtr<SkPicture> Engine::Paint() {
  SkRTreeFactory factory;
  SkPictureRecorder recorder;
  auto canvas = skia::SharePtr(recorder.beginRecording(
      physical_size_.width(), physical_size_.height(), &factory,
      SkPictureRecorder::kComputeSaveLayerInfo_RecordFlag));

  web_view_->paint(canvas.get(), blink::WebRect(gfx::Rect(physical_size_)));
  return skia::AdoptRef(recorder.endRecordingAsPicture());
}

void Engine::OnViewportMetricsChanged(const gfx::Size& physical_size,
                                      float device_pixel_ratio) {
  physical_size_ = physical_size;
  web_view_->setDeviceScaleFactor(device_pixel_ratio);
  gfx::SizeF size = gfx::ScaleSize(physical_size, 1 / device_pixel_ratio);
  // FIXME: We should be able to set the size of the WebView in floating point
  // because its in logical pixels.
  web_view_->resize(blink::WebSize(size.width(), size.height()));
}

void Engine::initializeLayerTreeView() {
}

void Engine::scheduleVisualUpdate() {
  animator_->RequestFrame();
}

}  // namespace shell
}  // namespace sky
