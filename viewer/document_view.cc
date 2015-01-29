// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/viewer/document_view.h"

#include "base/bind.h"
#include "base/location.h"
#include "base/message_loop/message_loop_proxy.h"
#include "base/single_thread_task_runner.h"
#include "base/strings/string_util.h"
#include "base/thread_task_runner_handle.h"
#include "mojo/converters/geometry/geometry_type_converters.h"
#include "mojo/converters/input_events/input_events_type_converters.h"
#include "mojo/public/cpp/application/connect.h"
#include "mojo/public/cpp/system/data_pipe.h"
#include "mojo/public/interfaces/application/shell.mojom.h"
#include "mojo/services/surfaces/public/interfaces/surfaces_service.mojom.h"
#include "mojo/services/view_manager/public/cpp/view.h"
#include "mojo/services/view_manager/public/cpp/view_manager.h"
#include "skia/ext/refptr.h"
#include "sky/compositor/layer.h"
#include "sky/compositor/layer_host.h"
#include "sky/compositor/rasterizer_bitmap.h"
#include "sky/compositor/rasterizer_ganesh.h"
#include "sky/engine/public/platform/Platform.h"
#include "sky/engine/public/platform/WebHTTPHeaderVisitor.h"
#include "sky/engine/public/platform/WebInputEvent.h"
#include "sky/engine/public/platform/WebScreenInfo.h"
#include "sky/engine/public/web/Sky.h"
#include "sky/engine/public/web/WebConsoleMessage.h"
#include "sky/engine/public/web/WebDocument.h"
#include "sky/engine/public/web/WebElement.h"
#include "sky/engine/public/web/WebLocalFrame.h"
#include "sky/engine/public/web/WebScriptSource.h"
#include "sky/engine/public/web/WebSettings.h"
#include "sky/engine/public/web/WebView.h"
#include "sky/engine/v8_inspector/inspector_backend_mojo.h"
#include "sky/engine/v8_inspector/inspector_host.h"
#include "sky/viewer/converters/input_event_types.h"
#include "sky/viewer/converters/url_request_types.h"
#include "sky/viewer/internals.h"
#include "sky/viewer/platform/weburlloader_impl.h"
#include "sky/viewer/runtime_flags.h"
#include "sky/viewer/script/script_runner.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkColor.h"
#include "third_party/skia/include/core/SkDevice.h"
#include "ui/events/gestures/gesture_recognizer.h"
#include "v8/include/v8.h"

namespace sky {
namespace {

void ConfigureSettings(blink::WebSettings* settings) {
  settings->setDefaultFixedFontSize(13);
  settings->setDefaultFontSize(16);
  settings->setLoadsImagesAutomatically(true);
}

mojo::Target WebNavigationPolicyToNavigationTarget(
    blink::WebNavigationPolicy policy) {
  switch (policy) {
    case blink::WebNavigationPolicyCurrentTab:
      return mojo::TARGET_SOURCE_NODE;
    case blink::WebNavigationPolicyNewBackgroundTab:
    case blink::WebNavigationPolicyNewForegroundTab:
    case blink::WebNavigationPolicyNewWindow:
    case blink::WebNavigationPolicyNewPopup:
      return mojo::TARGET_NEW_NODE;
    default:
      return mojo::TARGET_DEFAULT;
  }
}

}  // namespace

static int s_next_debugger_id = 1;

DocumentView::DocumentView(
    mojo::InterfaceRequest<mojo::ServiceProvider> services,
    mojo::ServiceProviderPtr exported_services,
    mojo::URLResponsePtr response,
    mojo::Shell* shell)
    : response_(response.Pass()),
      exported_services_(services.Pass()),
      shell_(shell),
      web_view_(nullptr),
      root_(nullptr),
      view_manager_client_factory_(shell_, this),
      inspector_service_factory_(this),
      bitmap_rasterizer_(nullptr),
      debugger_id_(s_next_debugger_id++),
      weak_factory_(this) {
  exported_services_.AddService(&view_manager_client_factory_);
  inspector_service_provider_impl_.AddService(&inspector_service_factory_);
}

DocumentView::~DocumentView() {
  if (web_view_)
    web_view_->close();
  if (root_)
    root_->RemoveObserver(this);
  ui::GestureRecognizer::Get()->CleanupStateForConsumer(this);
}

base::WeakPtr<DocumentView> DocumentView::GetWeakPtr() {
  return weak_factory_.GetWeakPtr();
}

void DocumentView::OnEmbed(
    mojo::View* root,
    mojo::InterfaceRequest<mojo::ServiceProvider> services,
    mojo::ServiceProviderPtr exposed_services) {
  root_ = root;
  imported_services_ = exposed_services.Pass();
  navigator_host_.set_service_provider(imported_services_.get());

  if (services.is_pending())
    inspector_service_provider_impl_.Bind(services.Pass());

  Load(response_.Pass());

  UpdateRootSizeAndViewportMetrics(root_->bounds());

  // TODO(abarth): We should ask the view whether it is focused instead of
  // assuming that we're focused.
  web_view_->setFocus(true);
  root_->AddObserver(this);
}

void DocumentView::OnViewManagerDisconnected(mojo::ViewManager* view_manager) {
  // TODO(aa): Need to figure out how shutdown works.
}

void DocumentView::Load(mojo::URLResponsePtr response) {
  web_view_ = blink::WebView::create(this);
  ConfigureSettings(web_view_->settings());
  web_view_->setMainFrame(blink::WebLocalFrame::create(this));
  web_view_->mainFrame()->load(GURL(response->url), response->body.Pass());
}

void DocumentView::initializeLayerTreeView() {
  layer_host_.reset(new LayerHost(this));
  root_layer_ = make_scoped_refptr(new Layer(this));
  root_layer_->set_rasterizer(CreateRasterizer());
  layer_host_->SetRootLayer(root_layer_);
}

scoped_ptr<Rasterizer> DocumentView::CreateRasterizer() {
  if (!RuntimeFlags::Get().testing())
    return make_scoped_ptr(new RasterizerGanesh(layer_host_.get()));
  // TODO(abarth): If we have more than one layer, we'll need to re-think how
  // we capture pixels for testing;
  DCHECK(!bitmap_rasterizer_);
  bitmap_rasterizer_ = new RasterizerBitmap(layer_host_.get());
  return make_scoped_ptr(bitmap_rasterizer_);
}

void DocumentView::GetPixelsForTesting(std::vector<unsigned char>* pixels) {
  DCHECK(RuntimeFlags::Get().testing()) << "Requires testing runtime flag";
  DCHECK(root_layer_) << "The root layer owns the rasterizer";
  return bitmap_rasterizer_->GetPixelsForTesting(pixels);
}

mojo::Shell* DocumentView::GetShell() {
  return shell_;
}

void DocumentView::BeginFrame(base::TimeTicks frame_time) {
  double frame_time_sec = (frame_time - base::TimeTicks()).InSecondsF();
  double deadline_sec = frame_time_sec;
  double interval_sec = 1.0/60;
  blink::WebBeginFrameArgs web_begin_frame_args(
      frame_time_sec, deadline_sec, interval_sec);
  web_view_->beginFrame(web_begin_frame_args);
  web_view_->layout();
  blink::WebSize size = web_view_->size();
  float device_pixel_ratio = GetDevicePixelRatio();
  root_layer_->SetSize(gfx::Size(size.width * device_pixel_ratio,
                                 size.height * device_pixel_ratio));
}

void DocumentView::OnSurfaceIdAvailable(mojo::SurfaceIdPtr surface_id) {
  if (root_)
    root_->SetSurfaceId(surface_id.Pass());
}

void DocumentView::PaintContents(SkCanvas* canvas, const gfx::Rect& clip) {
  blink::WebRect rect(clip.x(), clip.y(), clip.width(), clip.height());
  web_view_->paint(canvas, rect);
}

void DocumentView::scheduleVisualUpdate() {
  DCHECK(web_view_);
  layer_host_->SetNeedsAnimate();
}

blink::WebScreenInfo DocumentView::screenInfo() {
  DCHECK(root_);
  auto& metrics = root_->viewport_metrics();
  blink::WebScreenInfo screen;
  screen.rect = blink::WebRect(0, 0, metrics.size->width, metrics.size->height);
  screen.availableRect = screen.rect;
  screen.deviceScaleFactor = metrics.device_pixel_ratio;
  return screen;
}

mojo::View* DocumentView::createChildFrame() {
  if (!root_)
    return nullptr;

  mojo::View* child = root_->view_manager()->CreateView();
  child->SetVisible(true);
  root_->AddChild(child);
  return child;
}

void DocumentView::frameDetached(blink::WebFrame* frame) {
  // |frame| is invalid after here.
  frame->close();
}

float DocumentView::GetDevicePixelRatio() const {
  if (root_)
    return root_->viewport_metrics().device_pixel_ratio;
  return 1.f;
}

blink::WebNavigationPolicy DocumentView::decidePolicyForNavigation(
    const blink::WebFrameClient::NavigationPolicyInfo& info) {

  navigator_host_->RequestNavigate(
      WebNavigationPolicyToNavigationTarget(info.defaultPolicy),
      mojo::URLRequest::From(info.urlRequest).Pass());

  return blink::WebNavigationPolicyIgnore;
}

void DocumentView::didAddMessageToConsole(
    const blink::WebConsoleMessage& message,
    const blink::WebString& source_name,
    unsigned source_line,
    const blink::WebString& stack_trace) {
}

void DocumentView::didCreateScriptContext(blink::WebLocalFrame* frame,
                                          v8::Handle<v8::Context> context) {
  script_runner_.reset(new ScriptRunner(frame, context));

  v8::Isolate* isolate = context->GetIsolate();
  gin::Handle<Internals> internals = Internals::Create(isolate, this);
  context->Global()->Set(gin::StringToV8(isolate, "internals"),
                         gin::ConvertToV8(isolate, internals));
}

blink::ServiceProvider& DocumentView::services() {
  return *this;
}

mojo::NavigatorHost* DocumentView::NavigatorHost() {
  return navigator_host_.get();
}

mojo::Shell* DocumentView::Shell() {
  return shell_;
}

void DocumentView::OnViewBoundsChanged(mojo::View* view,
                                       const mojo::Rect& old_bounds,
                                       const mojo::Rect& new_bounds) {
  DCHECK_EQ(view, root_);
  UpdateRootSizeAndViewportMetrics(new_bounds);
}

void DocumentView::OnViewViewportMetricsChanged(
    mojo::View* view,
    const mojo::ViewportMetrics& old_metrics,
    const mojo::ViewportMetrics& new_metrics) {
  DCHECK_EQ(view, root_);
  web_view_->setDeviceScaleFactor(GetDevicePixelRatio());
  UpdateRootSizeAndViewportMetrics(root_->bounds());
}

void DocumentView::UpdateRootSizeAndViewportMetrics(
    const mojo::Rect& new_bounds) {
  float device_pixel_ratio = GetDevicePixelRatio();
  web_view_->resize(blink::WebSize(new_bounds.width / device_pixel_ratio,
                                   new_bounds.height / device_pixel_ratio));
}

void DocumentView::OnViewFocusChanged(mojo::View* gained_focus,
                                      mojo::View* lost_focus) {
  if (root_ == lost_focus) {
    web_view_->setFocus(false);
  } else if (root_ == gained_focus) {
    web_view_->setFocus(true);
  }
}

void DocumentView::OnViewDestroyed(mojo::View* view) {
  DCHECK_EQ(view, root_);

  root_ = nullptr;
}

bool DocumentView::DispatchInputEvent(const mojo::EventPtr& event) {
  scoped_ptr<blink::WebInputEvent> web_event =
      ConvertEvent(event, GetDevicePixelRatio());
  return web_event && web_view_->handleInputEvent(*web_event);
}

void DocumentView::OnViewInputEvent(
    mojo::View* view, const mojo::EventPtr& event) {

  scoped_ptr<ui::Event> ui_event(event.To<scoped_ptr<ui::Event>>());
  ui::TouchEvent* touch_event = nullptr;
  if (ui_event->IsTouchEvent()) {
    touch_event = static_cast<ui::TouchEvent*>(ui_event.get());
    ui::GestureRecognizer::Get()->ProcessTouchEventPreDispatch(
        *touch_event, this);
  }

  bool handled = DispatchInputEvent(event);

  if (touch_event) {
    ui::EventResult result = handled ? ui::ER_UNHANDLED : ui::ER_UNHANDLED;
    if (auto gestures = ui::GestureRecognizer::Get()->ProcessTouchEventPostDispatch(
        *touch_event, result, this)) {
      for (auto& gesture : *gestures)
        DispatchInputEvent(mojo::Event::From(*gesture));
    }
  }
}

class InspectorHostImpl : public inspector::InspectorHost {
 public:
  InspectorHostImpl(blink::WebView* web_view, mojo::Shell* shell)
      : web_view_(web_view), shell_(shell) {}

  virtual ~InspectorHostImpl() {}

  mojo::Shell* GetShell() override { return shell_; }
  v8::Isolate* GetIsolate() override { return blink::mainThreadIsolate(); }
  v8::Local<v8::Context> GetContext() override {
    return web_view_->mainFrame()->mainWorldScriptContext();
  }

 private:
  blink::WebView* web_view_;
  mojo::Shell* shell_;
};

void DocumentView::StartDebuggerInspectorBackend() {
  if (!inspector_backend_) {
    inspector_host_.reset(new InspectorHostImpl(web_view_, shell_));
    inspector_backend_.reset(
        new inspector::InspectorBackendMojo(inspector_host_.get()));
  }
  inspector_backend_->Connect();
}

}  // namespace sky
