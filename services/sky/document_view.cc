// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "services/sky/document_view.h"

#include "base/bind.h"
#include "base/location.h"
#include "base/message_loop/message_loop.h"
#include "base/single_thread_task_runner.h"
#include "base/strings/string_util.h"
#include "base/thread_task_runner_handle.h"
#include "mojo/converters/geometry/geometry_type_converters.h"
#include "mojo/converters/input_events/input_events_type_converters.h"
#include "mojo/public/cpp/application/connect.h"
#include "mojo/public/cpp/system/data_pipe.h"
#include "mojo/public/interfaces/application/shell.mojom.h"
#include "mojo/services/surfaces/cpp/surfaces_utils.h"
#include "mojo/services/surfaces/interfaces/quads.mojom.h"
#include "services/asset_bundle/asset_unpacker_job.h"
#include "services/sky/compositor/layer_host.h"
#include "services/sky/compositor/rasterizer_bitmap.h"
#include "services/sky/compositor/rasterizer_ganesh.h"
#include "services/sky/compositor/texture_layer.h"
#include "services/sky/converters/input_event_types.h"
#include "services/sky/dart_library_provider_impl.h"
#include "services/sky/internals.h"
#include "services/sky/runtime_flags.h"
#include "skia/ext/refptr.h"
#include "sky/compositor/paint_context.h"
#include "sky/engine/public/platform/Platform.h"
#include "sky/engine/public/platform/WebInputEvent.h"
#include "sky/engine/public/web/Sky.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkColor.h"
#include "third_party/skia/include/core/SkDevice.h"

using mojo::asset_bundle::AssetUnpackerJob;

namespace sky {
namespace {

const char kSnapshotKey[] = "snapshot_blob.bin";

}  // namespace

DocumentView::DocumentView(
    mojo::InterfaceRequest<mojo::ServiceProvider> exported_services,
    mojo::ServiceProviderPtr imported_services,
    mojo::URLResponsePtr response,
    mojo::Shell* shell)
    : response_(response.Pass()),
      exported_services_(exported_services.Pass()),
      imported_services_(imported_services.Pass()),
      shell_(shell),
      bitmap_rasterizer_(nullptr),
      event_dispatcher_binding_(this),
      weak_factory_(this) {
  InitServiceRegistry();
  InitViewport();
}

DocumentView::~DocumentView() {
}

base::WeakPtr<DocumentView> DocumentView::GetWeakPtr() {
  return weak_factory_.GetWeakPtr();
}

void DocumentView::InitViewport() {
  mojo::ServiceProviderPtr viewport_service_provider;
  shell_->ConnectToApplication("mojo:native_viewport_service",
                               mojo::GetProxy(&viewport_service_provider),
                               nullptr);
  mojo::ConnectToService(viewport_service_provider.get(), &viewport_service_);
  viewport_service_.set_connection_error_handler(
      base::Bind(&DocumentView::OnViewportConnectionError,
                 base::Unretained(this)));

  mojo::NativeViewportEventDispatcherPtr dispatcher;
  event_dispatcher_binding_.Bind(GetProxy(&dispatcher));
  viewport_service_->SetEventDispatcher(dispatcher.Pass());

  // Match the Nexus 5 aspect ratio initially.
  auto size = mojo::Size::New();
  size->width = 320;
  size->height = 640;

  auto requested_configuration = mojo::SurfaceConfiguration::New();

  viewport_service_->Create(size.Clone(),
                            requested_configuration.Pass(),
                            base::Bind(&DocumentView::OnViewportCreated,
                                       base::Unretained(this)));
}

void DocumentView::OnViewportConnectionError() {
  delete this;
}

void DocumentView::OnViewportCreated(mojo::ViewportMetricsPtr metrics) {
  viewport_service_->Show();
  mojo::ContextProviderPtr onscreen_context_provider;
  viewport_service_->GetContextProvider(GetProxy(&onscreen_context_provider));

  mojo::ServiceProviderPtr surfaces_service_provider;
  shell_->ConnectToApplication("mojo:surfaces_service",
                               mojo::GetProxy(&surfaces_service_provider),
                               nullptr);
  mojo::DisplayFactoryPtr display_factory;
  mojo::ConnectToService(surfaces_service_provider.get(), &display_factory);
  display_factory->Create(onscreen_context_provider.Pass(),
                          nullptr, GetProxy(&display_));

  Load(response_.Pass());
  UpdateViewportMetrics(metrics.Pass());
  RequestUpdatedViewportMetrics();
}

void DocumentView::OnViewportMetricsChanged(mojo::ViewportMetricsPtr metrics) {
  UpdateViewportMetrics(metrics.Pass());
  RequestUpdatedViewportMetrics();
}

void DocumentView::RequestUpdatedViewportMetrics() {
  viewport_service_->RequestMetrics(
      base::Bind(&DocumentView::OnViewportMetricsChanged,
                 base::Unretained(this)));
}

void DocumentView::LoadFromSnapshotStream(
    String name, mojo::ScopedDataPipeConsumerHandle snapshot) {
  if (sky_view_) {
    sky_view_->RunFromSnapshot(name, snapshot.Pass());
  }
}

void DocumentView::Load(mojo::URLResponsePtr response) {
  sky_view_ = blink::SkyView::Create(this);
  layer_host_.reset(new LayerHost(this));
  root_layer_ = make_scoped_refptr(new TextureLayer(this));
  root_layer_->set_rasterizer(CreateRasterizer());
  layer_host_->SetRootLayer(root_layer_);

  String name = String::fromUTF8(response->url);
  sky_view_->CreateView(name);
  AssetUnpackerJob* unpacker = new AssetUnpackerJob(
      mojo::GetProxy(&root_bundle_),
      base::MessageLoop::current()->task_runner());
  unpacker->Unpack(response->body.Pass());
  root_bundle_->GetAsStream(kSnapshotKey,
                            base::Bind(&DocumentView::LoadFromSnapshotStream,
                                       weak_factory_.GetWeakPtr(), name));
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

mojo::ScopedMessagePipeHandle DocumentView::TakeRootBundleHandle() {
  return root_bundle_.PassInterface().PassHandle();
}

mojo::ScopedMessagePipeHandle DocumentView::TakeServicesProvidedToEmbedder() {
  // TODO(jeffbrown): Stubbed out until we migrate from native viewport
  // to a new view system that supports embedding again.
  return mojo::ScopedMessagePipeHandle();
}

mojo::ScopedMessagePipeHandle DocumentView::TakeServicesProvidedByEmbedder() {
  // TODO(jeffbrown): Stubbed out until we migrate from native viewport
  // to a new view system that supports embedding again.
  return mojo::ScopedMessagePipeHandle();
}

mojo::ScopedMessagePipeHandle DocumentView::TakeServiceRegistry() {
  return service_registry_.PassInterface().PassHandle();
}

mojo::Shell* DocumentView::GetShell() {
  return shell_;
}

void DocumentView::BeginFrame(base::TimeTicks frame_time) {
  if (sky_view_) {
    std::unique_ptr<compositor::LayerTree> layer_tree = sky_view_->BeginFrame(frame_time);
    if (layer_tree)
      current_layer_tree_ = std::move(layer_tree);
    root_layer_->SetSize(sky_view_->display_metrics().physical_size);
  }
}

void DocumentView::OnSurfaceIdAvailable(mojo::SurfaceIdPtr surface_id) {
  mojo::FramePtr frame = mojo::Frame::New();
  frame->resources.resize(0u);

  mojo::Rect bounds;
  bounds.width = viewport_metrics_->size->width;
  bounds.height = viewport_metrics_->size->height;
  mojo::PassPtr pass = mojo::CreateDefaultPass(1, bounds);
  pass->shared_quad_states.push_back(mojo::CreateDefaultSQS(
      *viewport_metrics_->size));

  mojo::QuadPtr quad = mojo::Quad::New();
  quad->material = mojo::Material::SURFACE_CONTENT;
  quad->rect = bounds.Clone();
  quad->opaque_rect = bounds.Clone();
  quad->visible_rect = bounds.Clone();
  quad->shared_quad_state_index = 0u;
  quad->surface_quad_state = mojo::SurfaceQuadState::New();
  quad->surface_quad_state->surface = surface_id.Pass();

  pass->quads.push_back(quad.Pass());
  frame->passes.push_back(pass.Pass());

  display_->SubmitFrame(frame.Pass(), base::Bind(&base::DoNothing));
}

void DocumentView::PaintContents(SkCanvas* canvas, const gfx::Rect& clip) {
  if (current_layer_tree_) {
    compositor::PaintContext::ScopedFrame frame =
        paint_context_.AcquireFrame(*canvas);
    current_layer_tree_->root_layer()->Paint(frame);
  }
}

void DocumentView::DidCreateIsolate(Dart_Isolate isolate) {
  Internals::Create(isolate, this);
}

mojo::NavigatorHost* DocumentView::NavigatorHost() {
  return navigator_host_.get();
}

void DocumentView::UpdateViewportMetrics(
    mojo::ViewportMetricsPtr viewport_metrics) {
  viewport_metrics_ = viewport_metrics.Pass();

  if (sky_view_) {
    blink::SkyDisplayMetrics metrics;
    metrics.physical_size = blink::WebSize(
        viewport_metrics_->size->width,
        viewport_metrics_->size->height);
    metrics.device_pixel_ratio = viewport_metrics_->device_pixel_ratio;
    sky_view_->SetDisplayMetrics(metrics);
  }
}

void DocumentView::OnEvent(mojo::EventPtr event,
                           const mojo::Callback<void()>& callback) {
  HandleInputEvent(event.Pass());
  callback.Run();
}

void DocumentView::HandleInputEvent(mojo::EventPtr event) {
  if (!viewport_metrics_)
    return;
  float device_pixel_ratio = viewport_metrics_->device_pixel_ratio;
  scoped_ptr<blink::WebInputEvent> web_event =
      ConvertEvent(event, device_pixel_ratio);
  if (!web_event)
    return;

  if (sky_view_)
    sky_view_->HandleInputEvent(*web_event);
}

void DocumentView::StartDebuggerInspectorBackend() {
  // FIXME: Do we need this for dart?
}

void DocumentView::InitServiceRegistry() {
  if (imported_services_)
    mojo::ConnectToService(imported_services_.get(), &service_registry_);
}

void DocumentView::ScheduleFrame() {
  DCHECK(sky_view_);
  layer_host_->SetNeedsAnimate();
}

}  // namespace sky
