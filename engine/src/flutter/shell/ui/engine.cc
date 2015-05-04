// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/ui/engine.h"

#include "base/bind.h"
#include "base/trace_event/trace_event.h"
#include "mojo/public/cpp/application/connect.h"
#include "sky/engine/public/platform/WebInputEvent.h"
#include "sky/engine/public/web/Sky.h"
#include "sky/engine/public/web/WebLocalFrame.h"
#include "sky/engine/public/web/WebSettings.h"
#include "sky/engine/public/web/WebView.h"
#include "sky/services/platform/platform_impl.h"
#include "sky/shell/java_service_provider.h"
#include "sky/shell/ui/animator.h"
#include "sky/shell/ui/input_event_converter.h"
#include "sky/shell/ui/internals.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"

namespace sky {
namespace shell {

namespace {

void ConfigureSettings(blink::WebSettings* settings) {
  settings->setDefaultFixedFontSize(13);
  settings->setDefaultFontSize(16);
  settings->setLoadsImagesAutomatically(true);
}

}

Engine::Engine(const Config& config)
    : config_(config),
      animator_(new Animator(config, this)),
      web_view_(nullptr),
      device_pixel_ratio_(1.0f),
      viewport_observer_binding_(this),
      weak_factory_(this) {
}

Engine::~Engine() {
  if (web_view_)
    web_view_->close();
}

base::WeakPtr<Engine> Engine::GetWeakPtr() {
  return weak_factory_.GetWeakPtr();
}

mojo::ServiceProviderPtr Engine::CreateServiceProvider() {
  mojo::MessagePipe pipe;
  config_.java_task_runner->PostTask(
      FROM_HERE,
      base::Bind(CreateJavaServiceProvider,
                 base::Passed(mojo::MakeRequest<mojo::ServiceProvider>(
                     pipe.handle1.Pass()))));
  return mojo::MakeProxy(
      mojo::InterfacePtrInfo<mojo::ServiceProvider>(pipe.handle0.Pass(), 0u));
}

void Engine::Init() {
  TRACE_EVENT0("sky", "Engine::Init");

  service_provider_ = CreateServiceProvider();
  mojo::NetworkServicePtr network_service;
  mojo::ConnectToService(service_provider_.get(), &network_service);
  platform_impl_.reset(new PlatformImpl(network_service.Pass()));

  blink::initialize(platform_impl_.get());
}

void Engine::BeginFrame(base::TimeTicks frame_time) {
  TRACE_EVENT0("sky", "Engine::BeginFrame");

  double frame_time_sec = (frame_time - base::TimeTicks()).InSecondsF();
  double deadline_sec = frame_time_sec;
  double interval_sec = 1.0 / 60;
  blink::WebBeginFrameArgs args(frame_time_sec, deadline_sec, interval_sec);

  web_view_->beginFrame(args);
  web_view_->layout();
}

skia::RefPtr<SkPicture> Engine::Paint() {
  TRACE_EVENT0("sky", "Engine::Paint");

  SkRTreeFactory factory;
  SkPictureRecorder recorder;
  auto canvas = skia::SharePtr(recorder.beginRecording(
      physical_size_.width(), physical_size_.height(), &factory,
      SkPictureRecorder::kComputeSaveLayerInfo_RecordFlag));

  web_view_->paint(canvas.get(), blink::WebRect(gfx::Rect(physical_size_)));
  return skia::AdoptRef(recorder.endRecordingAsPicture());
}

void Engine::ConnectToViewportObserver(
    mojo::InterfaceRequest<ViewportObserver> request) {
  viewport_observer_binding_.Bind(request.Pass());
}

void Engine::OnAcceleratedWidgetAvailable(gfx::AcceleratedWidget widget) {
  config_.gpu_task_runner->PostTask(
      FROM_HERE, base::Bind(&GPUDelegate::OnAcceleratedWidgetAvailable,
                            config_.gpu_delegate, widget));
  if (web_view_)
    scheduleVisualUpdate();
}

void Engine::OnOutputSurfaceDestroyed() {
  config_.gpu_task_runner->PostTask(
      FROM_HERE,
      base::Bind(&GPUDelegate::OnOutputSurfaceDestroyed, config_.gpu_delegate));
}

void Engine::OnViewportMetricsChanged(int width, int height,
                                      float device_pixel_ratio) {
  physical_size_.SetSize(width, height);
  device_pixel_ratio_ = device_pixel_ratio;
  if (web_view_)
    UpdateWebViewSize();
}

void Engine::UpdateWebViewSize()
{
  CHECK(web_view_);
  web_view_->setDeviceScaleFactor(device_pixel_ratio_);
  gfx::SizeF size = gfx::ScaleSize(physical_size_, 1 / device_pixel_ratio_);
  // FIXME: We should be able to set the size of the WebView in floating point
  // because its in logical pixels.
  web_view_->resize(blink::WebSize(size.width(), size.height()));
}

// TODO(eseidel): This is likely not needed anymore.
blink::WebScreenInfo Engine::screenInfo() {
  blink::WebScreenInfo screen;
  screen.rect = blink::WebRect(gfx::Rect(physical_size_));
  screen.availableRect = screen.rect;
  screen.deviceScaleFactor = device_pixel_ratio_;
  return screen;
}

void Engine::OnInputEvent(InputEventPtr event) {
  TRACE_EVENT0("sky", "Engine::OnInputEvent");
  scoped_ptr<blink::WebInputEvent> web_event =
      ConvertEvent(event, device_pixel_ratio_);
  if (!web_event)
    return;
  web_view_->handleInputEvent(*web_event);
}

void Engine::LoadURL(const mojo::String& url) {
  // Something bad happens if you try to call WebView::close and replace
  // the webview.  So for now we just load into the existing one. :/
  if (!web_view_)
    web_view_ = blink::WebView::create(this);
  ConfigureSettings(web_view_->settings());
  web_view_->setMainFrame(blink::WebLocalFrame::create(this));
  UpdateWebViewSize();
  web_view_->mainFrame()->load(GURL(url));
}

void Engine::frameDetached(blink::WebFrame* frame) {
  // |frame| is invalid after here.
  frame->close();
}

void Engine::initializeLayerTreeView() {
}

void Engine::scheduleVisualUpdate() {
  animator_->RequestFrame();
}

void Engine::didCreateIsolate(blink::WebLocalFrame* frame,
                              Dart_Isolate isolate) {
  Internals::Create(isolate, CreateServiceProvider());
}

blink::ServiceProvider* Engine::services() {
  return this;
}

mojo::NavigatorHost* Engine::NavigatorHost() {
  return this;
}

void Engine::RequestNavigate(mojo::Target target,
                             mojo::URLRequestPtr request) {
  // Ignoring target for now.
  base::MessageLoop::current()->PostTask(FROM_HERE,
      base::Bind(&Engine::LoadURL, GetWeakPtr(), request->url));
}

void Engine::DidNavigateLocally(const mojo::String& url) {
}

void Engine::RequestNavigateHistory(int32_t delta) {
  NOTIMPLEMENTED();
}

}  // namespace shell
}  // namespace sky
