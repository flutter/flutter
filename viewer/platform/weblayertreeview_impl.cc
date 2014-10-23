// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/viewer/platform/weblayertreeview_impl.h"

#include "base/message_loop/message_loop_proxy.h"
#include "cc/layers/layer.h"
#include "cc/output/begin_frame_args.h"
#include "cc/trees/layer_tree_host.h"
#include "mojo/cc/context_provider_mojo.h"
#include "mojo/cc/output_surface_mojo.h"
#include "mojo/converters/surfaces/surfaces_type_converters.h"
#include "mojo/services/public/cpp/view_manager/view.h"
#include "sky/engine/public/web/WebWidget.h"
#include "sky/viewer/cc/web_layer_impl.h"

namespace sky {

WebLayerTreeViewImpl::WebLayerTreeViewImpl(
    scoped_refptr<base::MessageLoopProxy> compositor_message_loop_proxy,
    mojo::SurfacesServicePtr surfaces_service,
    mojo::GpuPtr gpu_service)
    : widget_(NULL),
      view_(NULL),
      surfaces_service_(surfaces_service.Pass()),
      gpu_service_(gpu_service.Pass()),
      main_thread_compositor_task_runner_(base::MessageLoopProxy::current()),
      weak_factory_(this) {
  main_thread_bound_weak_ptr_ = weak_factory_.GetWeakPtr();
  surfaces_service_->CreateSurfaceConnection(
      base::Bind(&WebLayerTreeViewImpl::OnSurfaceConnectionCreated,
                 main_thread_bound_weak_ptr_));

  cc::LayerTreeSettings settings;

  // For web contents, layer transforms should scale up the contents of layers
  // to keep content always crisp when possible.
  settings.layer_transforms_should_scale_layer_contents = true;

  cc::SharedBitmapManager* shared_bitmap_manager = NULL;
  cc::GpuMemoryBufferManager* gpu_memory_buffer_manager = NULL;

  layer_tree_host_ =
      cc::LayerTreeHost::CreateThreaded(this,
                                        shared_bitmap_manager,
                                        gpu_memory_buffer_manager,
                                        settings,
                                        base::MessageLoopProxy::current(),
                                        compositor_message_loop_proxy);
  DCHECK(layer_tree_host_);
}

WebLayerTreeViewImpl::~WebLayerTreeViewImpl() {
  layer_tree_host_.reset();
}

void WebLayerTreeViewImpl::WillBeginMainFrame(int frame_id) {
}

void WebLayerTreeViewImpl::DidBeginMainFrame() {
}

void WebLayerTreeViewImpl::BeginMainFrame(const cc::BeginFrameArgs& args) {
  VLOG(2) << "WebLayerTreeViewImpl::BeginMainFrame";
  double frame_time_sec = (args.frame_time - base::TimeTicks()).InSecondsF();
  double deadline_sec = (args.deadline - base::TimeTicks()).InSecondsF();
  double interval_sec = args.interval.InSecondsF();
  blink::WebBeginFrameArgs web_begin_frame_args(
      frame_time_sec, deadline_sec, interval_sec);
  widget_->beginFrame(web_begin_frame_args);
}

void WebLayerTreeViewImpl::Layout() {
  widget_->layout();
}

void WebLayerTreeViewImpl::ApplyViewportDeltas(
    const gfx::Vector2d& scroll_delta,
    float page_scale,
    float top_controls_delta) {
}

void WebLayerTreeViewImpl::ApplyViewportDeltas(const gfx::Vector2d& inner_delta,
                                               const gfx::Vector2d& outer_delta,
                                               float page_scale,
                                               float top_controls_delta){
}

void WebLayerTreeViewImpl::RequestNewOutputSurface(bool fallback) {
  layer_tree_host_->SetOutputSurface(output_surface_.Pass());
}

void WebLayerTreeViewImpl::DidInitializeOutputSurface() {
}

void WebLayerTreeViewImpl::WillCommit() {
}

void WebLayerTreeViewImpl::DidCommit() {
  widget_->didCommitFrameToCompositor();
}

void WebLayerTreeViewImpl::DidCommitAndDrawFrame() {
}

void WebLayerTreeViewImpl::DidCompleteSwapBuffers() {
}

void WebLayerTreeViewImpl::setSurfaceReady() {
}

void WebLayerTreeViewImpl::setRootLayer(const blink::WebLayer& layer) {
  layer_tree_host_->SetRootLayer(
      static_cast<const sky_viewer_cc::WebLayerImpl*>(&layer)->layer());
}

void WebLayerTreeViewImpl::clearRootLayer() {
  layer_tree_host_->SetRootLayer(scoped_refptr<cc::Layer>());
}

void WebLayerTreeViewImpl::setViewportSize(
    const blink::WebSize& device_viewport_size) {
  layer_tree_host_->SetViewportSize(device_viewport_size);
}

blink::WebSize WebLayerTreeViewImpl::deviceViewportSize() const {
  return layer_tree_host_->device_viewport_size();
}

void WebLayerTreeViewImpl::setDeviceScaleFactor(float device_scale_factor) {
  layer_tree_host_->SetDeviceScaleFactor(device_scale_factor);
}

float WebLayerTreeViewImpl::deviceScaleFactor() const {
  return layer_tree_host_->device_scale_factor();
}

void WebLayerTreeViewImpl::setBackgroundColor(blink::WebColor color) {
  layer_tree_host_->set_background_color(color);
}

void WebLayerTreeViewImpl::setHasTransparentBackground(
    bool has_transparent_background) {
  layer_tree_host_->set_has_transparent_background(has_transparent_background);
}

void WebLayerTreeViewImpl::setOverhangBitmap(const SkBitmap& bitmap) {
  layer_tree_host_->SetOverhangBitmap(bitmap);
}

void WebLayerTreeViewImpl::setVisible(bool visible) {
  layer_tree_host_->SetVisible(visible);
}

void WebLayerTreeViewImpl::registerForAnimations(blink::WebLayer* layer) {
  cc::Layer* cc_layer = static_cast<sky_viewer_cc::WebLayerImpl*>(layer)->layer();
  cc_layer->layer_animation_controller()->SetAnimationRegistrar(
      layer_tree_host_->animation_registrar());
}

void WebLayerTreeViewImpl::registerViewportLayers(
    const blink::WebLayer* pageScaleLayer,
    const blink::WebLayer* innerViewportScrollLayer,
    const blink::WebLayer* outerViewportScrollLayer) {
  layer_tree_host_->RegisterViewportLayers(
      static_cast<const sky_viewer_cc::WebLayerImpl*>(pageScaleLayer)->layer(),
      static_cast<const sky_viewer_cc::WebLayerImpl*>(innerViewportScrollLayer)
          ->layer(),
      // The outer viewport layer will only exist when using pinch virtual
      // viewports.
      outerViewportScrollLayer ? static_cast<const sky_viewer_cc::WebLayerImpl*>(
                                     outerViewportScrollLayer)->layer()
                               : NULL);
}

void WebLayerTreeViewImpl::clearViewportLayers() {
  layer_tree_host_->RegisterViewportLayers(scoped_refptr<cc::Layer>(),
                                           scoped_refptr<cc::Layer>(),
                                           scoped_refptr<cc::Layer>());
}

void WebLayerTreeViewImpl::setNeedsAnimate() {
  layer_tree_host_->SetNeedsAnimate();
}

bool WebLayerTreeViewImpl::commitRequested() const {
  return layer_tree_host_->CommitRequested();
}

void WebLayerTreeViewImpl::finishAllRendering() {
  layer_tree_host_->FinishAllRendering();
}

void WebLayerTreeViewImpl::OnSurfaceConnectionCreated(mojo::SurfacePtr surface,
                                                      uint32_t id_namespace) {
  mojo::CommandBufferPtr cb;
  gpu_service_->CreateOffscreenGLES2Context(GetProxy(&cb));
  scoped_refptr<cc::ContextProvider> context_provider(
      new mojo::ContextProviderMojo(cb.PassMessagePipe()));
  output_surface_.reset(new mojo::OutputSurfaceMojo(
      this, context_provider, surface.Pass(), id_namespace));
  layer_tree_host_->SetLayerTreeHostClientReady();
}

void WebLayerTreeViewImpl::DidCreateSurface(cc::SurfaceId id) {
  main_thread_compositor_task_runner_->PostTask(
      FROM_HERE,
      base::Bind(&WebLayerTreeViewImpl::DidCreateSurfaceOnMainThread,
                 main_thread_bound_weak_ptr_,
                 id));
}

void WebLayerTreeViewImpl::DidCreateSurfaceOnMainThread(cc::SurfaceId id) {
  view_->SetSurfaceId(mojo::SurfaceId::From(id));
}

}  // namespace sky
