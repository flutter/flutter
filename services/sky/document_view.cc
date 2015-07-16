// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "services/sky/document_view.h"

#include "base/bind.h"
#include "base/location.h"
#include "base/single_thread_task_runner.h"
#include "base/strings/string_util.h"
#include "base/thread_task_runner_handle.h"
#include "mojo/converters/geometry/geometry_type_converters.h"
#include "mojo/converters/input_events/input_events_type_converters.h"
#include "mojo/public/cpp/application/connect.h"
#include "mojo/public/cpp/system/data_pipe.h"
#include "mojo/public/interfaces/application/shell.mojom.h"
#include "mojo/services/view_manager/public/cpp/view.h"
#include "mojo/services/view_manager/public/cpp/view_manager.h"
#include "mojo/services/view_manager/public/interfaces/view_manager.mojom.h"
#include "services/sky/compositor/layer.h"
#include "services/sky/compositor/layer_host.h"
#include "services/sky/compositor/rasterizer_bitmap.h"
#include "services/sky/compositor/rasterizer_ganesh.h"
#include "services/sky/converters/input_event_types.h"
#include "services/sky/dart_library_provider_impl.h"
#include "services/sky/internals.h"
#include "services/sky/runtime_flags.h"
#include "skia/ext/refptr.h"
#include "sky/engine/public/platform/Platform.h"
#include "sky/engine/public/platform/WebInputEvent.h"
#include "sky/engine/public/platform/WebScreenInfo.h"
#include "sky/engine/public/web/Sky.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkColor.h"
#include "third_party/skia/include/core/SkDevice.h"
#include "ui/events/gestures/gesture_recognizer.h"

namespace sky {
namespace {

ui::EventType ConvertEventTypeToUIEventType(blink::WebInputEvent::Type type) {
  if (type == blink::WebInputEvent::PointerDown)
    return ui::ET_TOUCH_PRESSED;
  if (type == blink::WebInputEvent::PointerUp)
    return ui::ET_TOUCH_RELEASED;
  if (type == blink::WebInputEvent::PointerMove)
    return ui::ET_TOUCH_MOVED;
  DCHECK(type == blink::WebInputEvent::PointerCancel);
  return ui::ET_TOUCH_CANCELLED;
}

scoped_ptr<ui::TouchEvent> ConvertToUITouchEvent(
    const blink::WebInputEvent& event,
    float device_pixel_ratio) {
  if (!blink::WebInputEvent::isPointerEventType(event.type))
    return nullptr;
  const blink::WebPointerEvent& pointer_event =
      static_cast<const blink::WebPointerEvent&>(event);
  return make_scoped_ptr(new ui::TouchEvent(
      ConvertEventTypeToUIEventType(event.type),
      gfx::PointF(pointer_event.x * device_pixel_ratio,
                  pointer_event.y * device_pixel_ratio),
      pointer_event.pointer,
      base::TimeDelta::FromMillisecondsD(pointer_event.timeStampMS)));
}

scoped_ptr<DartLibraryProviderImpl::PrefetchedLibrary>
CreatePrefetchedLibraryIfNeeded(const String& name,
                                mojo::URLResponsePtr response) {
  scoped_ptr<DartLibraryProviderImpl::PrefetchedLibrary> prefetched;
  if (response->status_code == 200) {
    prefetched.reset(new DartLibraryProviderImpl::PrefetchedLibrary());
    prefetched->name = name.toUTF8();
    prefetched->pipe = response->body.Pass();
  }
  return prefetched.Pass();
}

}  // namespace

DocumentView::DocumentView(
    mojo::InterfaceRequest<mojo::ServiceProvider> services,
    mojo::ServiceProviderPtr exported_services,
    mojo::URLResponsePtr response,
    mojo::Shell* shell)
    : response_(response.Pass()),
      exported_services_(services.Pass()),
      imported_services_(exported_services.Pass()),
      shell_(shell),
      root_(nullptr),
      view_manager_client_factory_(shell_, this),
      bitmap_rasterizer_(nullptr),
      weak_factory_(this) {
  exported_services_.AddService(&view_manager_client_factory_);
  InitServiceRegistry();
  mojo::ServiceProviderPtr network_service_provider;
  shell->ConnectToApplication("mojo:authenticated_network_service",
                              mojo::GetProxy(&network_service_provider),
                              nullptr);
  mojo::ConnectToService(network_service_provider.get(), &network_service_);
}

DocumentView::~DocumentView() {
  if (root_)
    root_->RemoveObserver(this);
  ui::GestureRecognizer::Get()->CleanupStateForConsumer(this);
}

base::WeakPtr<DocumentView> DocumentView::GetWeakPtr() {
  return weak_factory_.GetWeakPtr();
}

void DocumentView::OnEmbed(
    mojo::View* root,
    mojo::InterfaceRequest<mojo::ServiceProvider> services_provided_to_embedder,
    mojo::ServiceProviderPtr services_provided_by_embedder) {
  root_ = root;

  if (services_provided_by_embedder.get()) {
    mojo::ConnectToService(services_provided_by_embedder.get(),
                           &navigator_host_);
  }

  services_provided_to_embedder_ = services_provided_to_embedder.Pass();
  services_provided_by_embedder_ = services_provided_by_embedder.Pass();

  Load(response_.Pass());

  UpdateRootSizeAndViewportMetrics(root_->bounds());

  root_->AddObserver(this);
}

void DocumentView::OnViewManagerDisconnected(mojo::ViewManager* view_manager) {
  // TODO(aa): Need to figure out how shutdown works.
}
void DocumentView::Load(mojo::URLResponsePtr response) {
  String name = String::fromUTF8(response->url);
  library_provider_.reset(new DartLibraryProviderImpl(
      network_service_.get(),
      CreatePrefetchedLibraryIfNeeded(name, response.Pass())));
  sky_view_ = blink::SkyView::Create(this);
  layer_host_.reset(new LayerHost(this));
  root_layer_ = make_scoped_refptr(new Layer(this));
  root_layer_->set_rasterizer(CreateRasterizer());
  layer_host_->SetRootLayer(root_layer_);

  sky_view_->RunFromLibrary(name, library_provider_.get());
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

mojo::ScopedMessagePipeHandle DocumentView::TakeServicesProvidedToEmbedder() {
  return services_provided_to_embedder_.PassMessagePipe();
}

mojo::ScopedMessagePipeHandle DocumentView::TakeServicesProvidedByEmbedder() {
  return services_provided_by_embedder_.PassInterface().PassHandle();
}

mojo::ScopedMessagePipeHandle DocumentView::TakeServiceRegistry() {
  return service_registry_.PassInterface().PassHandle();
}

mojo::Shell* DocumentView::GetShell() {
  return shell_;
}

void DocumentView::BeginFrame(base::TimeTicks frame_time) {
  if (sky_view_) {
    sky_view_->BeginFrame(frame_time);
    root_layer_->SetSize(sky_view_->display_metrics().physical_size);
  }
}

void DocumentView::OnSurfaceIdAvailable(mojo::SurfaceIdPtr surface_id) {
  if (root_)
    root_->SetSurfaceId(surface_id.Pass());
}

void DocumentView::PaintContents(SkCanvas* canvas, const gfx::Rect& clip) {
  blink::WebRect rect(clip.x(), clip.y(), clip.width(), clip.height());

  if (sky_view_) {
    skia::RefPtr<SkPicture> picture = sky_view_->Paint();
    canvas->clear(SK_ColorBLACK);
    canvas->scale(GetDevicePixelRatio(), GetDevicePixelRatio());
    if (picture)
      canvas->drawPicture(picture.get());
  }
}

float DocumentView::GetDevicePixelRatio() const {
  if (root_)
    return root_->viewport_metrics().device_pixel_ratio;
  return 1.f;
}

void DocumentView::DidCreateIsolate(Dart_Isolate isolate) {
  Internals::Create(isolate, this);
}

mojo::NavigatorHost* DocumentView::NavigatorHost() {
  return navigator_host_.get();
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

  UpdateRootSizeAndViewportMetrics(root_->bounds());
}

void DocumentView::UpdateRootSizeAndViewportMetrics(
    const mojo::Rect& new_bounds) {
  float device_pixel_ratio = GetDevicePixelRatio();

  if (sky_view_) {
    blink::SkyDisplayMetrics metrics;
    mojo::Rect bounds = root_->bounds();
    metrics.physical_size = blink::WebSize(bounds.width, bounds.height);
    metrics.device_pixel_ratio = device_pixel_ratio;
    sky_view_->SetDisplayMetrics(metrics);
    return;
  }
}

void DocumentView::OnViewFocusChanged(mojo::View* gained_focus,
                                      mojo::View* lost_focus) {
}

void DocumentView::OnViewDestroyed(mojo::View* view) {
  DCHECK_EQ(view, root_);

  root_ = nullptr;
}

void DocumentView::OnViewInputEvent(
    mojo::View* view, const mojo::EventPtr& event) {
  float device_pixel_ratio = GetDevicePixelRatio();
  scoped_ptr<blink::WebInputEvent> web_event =
      ConvertEvent(event, device_pixel_ratio);
  if (!web_event)
    return;

  ui::GestureRecognizer* recognizer = ui::GestureRecognizer::Get();
  scoped_ptr<ui::TouchEvent> touch_event =
      ConvertToUITouchEvent(*web_event, device_pixel_ratio);
  if (touch_event)
    recognizer->ProcessTouchEventPreDispatch(*touch_event, this);

  bool handled = false;

  if (sky_view_)
    sky_view_->HandleInputEvent(*web_event);

  if (touch_event) {
    ui::EventResult result = handled ? ui::ER_UNHANDLED : ui::ER_UNHANDLED;
    if (auto gestures = recognizer->ProcessTouchEventPostDispatch(
            *touch_event, result, this)) {
      for (auto& gesture : *gestures) {
        scoped_ptr<blink::WebInputEvent> gesture_event =
            ConvertEvent(*gesture, device_pixel_ratio);
        if (gesture_event) {
          if (sky_view_)
            sky_view_->HandleInputEvent(*gesture_event);
        }
      }
    }
  }
}

void DocumentView::StartDebuggerInspectorBackend() {
  // FIXME: Do we need this for dart?
}

void DocumentView::InitServiceRegistry() {
  mojo::ConnectToService(imported_services_.get(), &service_registry_);
  mojo::Array<mojo::String> interface_names(1);
  interface_names[0] = mojo::ViewManagerClient::Name_;
  mojo::ServiceProviderImpl* sp_impl(new mojo::ServiceProviderImpl());
  sp_impl->AddService(&view_manager_client_factory_);
  mojo::ServiceProviderPtr sp;
  service_registry_service_provider_binding_.reset(
      new mojo::StrongBinding<mojo::ServiceProvider>(sp_impl, &sp));
  service_registry_->AddServices(interface_names.Pass(), sp.Pass());
}

void DocumentView::ScheduleFrame() {
  DCHECK(sky_view_);
  layer_host_->SetNeedsAnimate();
}

}  // namespace sky
