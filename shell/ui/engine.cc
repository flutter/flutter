// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/ui/engine.h"

#include "base/bind.h"
#include "base/files/file_path.h"
#include "base/threading/worker_pool.h"
#include "base/trace_event/trace_event.h"
#include "mojo/common/data_pipe_utils.h"
#include "mojo/public/cpp/application/connect.h"
#include "services/asset_bundle/asset_unpacker_job.h"
#include "sky/engine/public/platform/WebInputEvent.h"
#include "sky/engine/public/platform/sky_display_metrics.h"
#include "sky/engine/public/platform/sky_display_metrics.h"
#include "sky/engine/public/web/Sky.h"
#include "sky/services/platform/platform_impl.h"
#include "sky/shell/dart/dart_library_provider_files.h"
#include "sky/shell/dart/dart_library_provider_network.h"
#include "sky/shell/service_provider.h"
#include "sky/shell/ui/animator.h"
#include "sky/shell/ui/input_event_converter.h"
#include "sky/shell/ui/internals.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"

namespace sky {
namespace shell {

const char kSnapshotKey[] = "snapshot_blob.bin";

namespace {

void Ignored(bool) {
}

mojo::ScopedDataPipeConsumerHandle Fetch(const base::FilePath& path) {
  mojo::DataPipe pipe;
  auto runner = base::WorkerPool::GetTaskRunner(true);
  mojo::common::CopyFromFile(base::FilePath(path), pipe.producer_handle.Pass(),
                             0, runner.get(), base::Bind(&Ignored));
  return pipe.consumer_handle.Pass();
}

PlatformImpl* g_platform_impl = nullptr;

}  // namespace

using mojo::asset_bundle::AssetUnpackerJob;

Engine::Config::Config() {
}

Engine::Config::~Config() {
}

Engine::Engine(const Config& config)
    : config_(config),
      animator_(new Animator(config, this)),
      binding_(this),
      weak_factory_(this) {
}

Engine::~Engine() {
}

base::WeakPtr<Engine> Engine::GetWeakPtr() {
  return weak_factory_.GetWeakPtr();
}

void Engine::Init(ServiceProviderContext* service_provider_context) {
  TRACE_EVENT0("sky", "Engine::Init");

  mojo::ServiceProviderPtr service_provider =
      CreateServiceProvider(service_provider_context);
  mojo::NetworkServicePtr network_service;
  mojo::ConnectToService(service_provider.get(), &network_service);

  DCHECK(!g_platform_impl);
  g_platform_impl = new PlatformImpl(network_service.Pass());
  blink::initialize(g_platform_impl);
}

void Engine::BeginFrame(base::TimeTicks frame_time) {
  TRACE_EVENT0("sky", "Engine::BeginFrame");

  if (sky_view_)
    sky_view_->BeginFrame(frame_time);
}

skia::RefPtr<SkPicture> Engine::Paint() {
  TRACE_EVENT0("sky", "Engine::Paint");

  SkRTreeFactory factory;
  SkPictureRecorder recorder;
  auto canvas = skia::SharePtr(recorder.beginRecording(
      physical_size_.width(), physical_size_.height(), &factory,
      SkPictureRecorder::kComputeSaveLayerInfo_RecordFlag));

  if (sky_view_) {
    skia::RefPtr<SkPicture> picture = sky_view_->Paint();
    canvas->clear(SK_ColorBLACK);
    canvas->scale(display_metrics_.device_pixel_ratio,
                  display_metrics_.device_pixel_ratio);
    if (picture)
      canvas->drawPicture(picture.get());
  }

  return skia::AdoptRef(recorder.endRecordingAsPicture());
}

void Engine::ConnectToEngine(mojo::InterfaceRequest<SkyEngine> request) {
  binding_.Bind(request.Pass());
}

void Engine::OnAcceleratedWidgetAvailable(gfx::AcceleratedWidget widget) {
  config_.gpu_task_runner->PostTask(
      FROM_HERE, base::Bind(&GPUDelegate::OnAcceleratedWidgetAvailable,
                            config_.gpu_delegate, widget));
  if (sky_view_)
    ScheduleFrame();
}

void Engine::OnOutputSurfaceDestroyed() {
  config_.gpu_task_runner->PostTask(
      FROM_HERE,
      base::Bind(&GPUDelegate::OnOutputSurfaceDestroyed, config_.gpu_delegate));
}

void Engine::OnViewportMetricsChanged(ViewportMetricsPtr metrics) {
  physical_size_.SetSize(metrics->physical_width, metrics->physical_height);

  display_metrics_.physical_size = physical_size_;
  display_metrics_.device_pixel_ratio = metrics->device_pixel_ratio;
  display_metrics_.padding_top = metrics->padding_top;
  display_metrics_.padding_right = metrics->padding_right;
  display_metrics_.padding_bottom = metrics->padding_bottom;
  display_metrics_.padding_left = metrics->padding_left;

  if (sky_view_)
    sky_view_->SetDisplayMetrics(display_metrics_);
}

void Engine::OnInputEvent(InputEventPtr event) {
  TRACE_EVENT0("sky", "Engine::OnInputEvent");
  scoped_ptr<blink::WebInputEvent> web_event =
      ConvertEvent(event, display_metrics_.device_pixel_ratio);
  if (!web_event)
    return;
  if (sky_view_)
    sky_view_->HandleInputEvent(*web_event);
}

void Engine::RunFromLibrary(const std::string& name) {
  sky_view_ = blink::SkyView::Create(this);
  sky_view_->RunFromLibrary(blink::WebString::fromUTF8(name),
                            dart_library_provider_.get());
  sky_view_->SetDisplayMetrics(display_metrics_);
}

void Engine::RunFromSnapshotStream(
    const std::string& name,
    mojo::ScopedDataPipeConsumerHandle snapshot) {
  sky_view_ = blink::SkyView::Create(this);
  sky_view_->RunFromSnapshot(blink::WebString::fromUTF8(name), snapshot.Pass());
  sky_view_->SetDisplayMetrics(display_metrics_);
}

void Engine::RunFromNetwork(const mojo::String& url) {
  dart_library_provider_.reset(
      new DartLibraryProviderNetwork(g_platform_impl->networkService()));
  RunFromLibrary(url);
}

void Engine::RunFromFile(const mojo::String& main,
                         const mojo::String& package_root) {
  dart_library_provider_.reset(
      new DartLibraryProviderFiles(base::FilePath(package_root)));
  RunFromLibrary(main);
}

void Engine::RunFromSnapshot(const mojo::String& path) {
  std::string path_str = path;
  RunFromSnapshotStream(path_str, Fetch(base::FilePath(path_str)));
}

void Engine::RunFromBundle(const mojo::String& path) {
  AssetUnpackerJob* unpacker = new AssetUnpackerJob(
      mojo::GetProxy(&root_bundle_), base::WorkerPool::GetTaskRunner(true));
  std::string path_str = path;
  unpacker->Unpack(Fetch(base::FilePath(path_str)));
  root_bundle_->GetAsStream(kSnapshotKey,
                            base::Bind(&Engine::RunFromSnapshotStream,
                                       weak_factory_.GetWeakPtr(), path_str));
}

void Engine::DidCreateIsolate(Dart_Isolate isolate) {
  Internals::Create(isolate,
                    CreateServiceProvider(config_.service_provider_context),
                    root_bundle_.Pass());
}

void Engine::ScheduleFrame() {
  animator_->RequestFrame();
}

mojo::NavigatorHost* Engine::NavigatorHost() {
  return this;
}

void Engine::RequestNavigate(mojo::Target target,
                             mojo::URLRequestPtr request) {
  // Ignoring target for now.
  base::MessageLoop::current()->PostTask(
      FROM_HERE,
      base::Bind(&Engine::RunFromNetwork, GetWeakPtr(), request->url));
}

void Engine::DidNavigateLocally(const mojo::String& url) {
}

void Engine::RequestNavigateHistory(int32_t delta) {
  NOTIMPLEMENTED();
}

}  // namespace shell
}  // namespace sky
