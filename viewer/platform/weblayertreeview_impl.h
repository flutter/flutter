// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_VIEWER_PLATFORM_WEBLAYERTREEVIEW_IMPL_H_
#define SKY_VIEWER_PLATFORM_WEBLAYERTREEVIEW_IMPL_H_

#include "base/memory/ref_counted.h"
#include "base/memory/scoped_ptr.h"
#include "base/memory/weak_ptr.h"
#include "base/single_thread_task_runner.h"
#include "cc/trees/layer_tree_host_client.h"
#include "mojo/cc/output_surface_mojo.h"
#include "mojo/services/public/interfaces/gpu/gpu.mojom.h"
#include "mojo/services/public/interfaces/surfaces/surfaces_service.mojom.h"
#include "sky/engine/public/platform/WebLayerTreeView.h"

namespace base {
class MessageLoopProxy;
}

namespace blink {
class WebWidget;
}

namespace cc {
class LayerTreeHost;
}

namespace mojo {
class View;
}

namespace sky {

class WebLayerTreeViewImpl : public blink::WebLayerTreeView,
                             public cc::LayerTreeHostClient,
                             public mojo::OutputSurfaceMojoClient {
 public:
  WebLayerTreeViewImpl(
      scoped_refptr<base::MessageLoopProxy> compositor_message_loop_proxy,
      mojo::SurfacesServicePtr surfaces_service,
      mojo::GpuPtr gpu_service);
  virtual ~WebLayerTreeViewImpl();

  void set_widget(blink::WebWidget* widget) { widget_ = widget; }
  void set_view(mojo::View* view) { view_ = view; }

  // cc::LayerTreeHostClient implementation.
  virtual void WillBeginMainFrame(int frame_id) override;
  virtual void DidBeginMainFrame() override;
  virtual void BeginMainFrame(const cc::BeginFrameArgs& args) override;
  virtual void Layout() override;
  virtual void ApplyViewportDeltas(const gfx::Vector2d& scroll_delta,
                                   float page_scale,
                                   float top_controls_delta) override;
  virtual void ApplyViewportDeltas(const gfx::Vector2d& inner_delta,
                                   const gfx::Vector2d& outer_delta,
                                   float page_scale,
                                   float top_controls_delta) override;
  virtual void RequestNewOutputSurface(bool fallback) override;
  virtual void DidInitializeOutputSurface() override;
  virtual void WillCommit() override;
  virtual void DidCommit() override;
  virtual void DidCommitAndDrawFrame() override;
  virtual void DidCompleteSwapBuffers() override;
  virtual void RateLimitSharedMainThreadContext() override {}

  // blink::WebLayerTreeView implementation.
  virtual void setSurfaceReady() override;
  virtual void setRootLayer(const blink::WebLayer& layer) override;
  virtual void clearRootLayer() override;
  virtual void setViewportSize(
      const blink::WebSize& device_viewport_size) override;
  virtual blink::WebSize deviceViewportSize() const override;
  virtual void setDeviceScaleFactor(float) override;
  virtual float deviceScaleFactor() const override;
  virtual void setBackgroundColor(blink::WebColor color) override;
  virtual void setHasTransparentBackground(
      bool has_transparent_background) override;
  virtual void setOverhangBitmap(const SkBitmap& bitmap) override;
  virtual void setVisible(bool visible) override;
  virtual void heuristicsForGpuRasterizationUpdated(bool matches_heuristic) {}
  virtual void setTopControlsContentOffset(float offset) {}
  virtual void setNeedsAnimate() override;
  virtual bool commitRequested() const override;
  virtual void didStopFlinging() {}
  virtual void compositeAndReadbackAsync(
      blink::WebCompositeAndReadbackAsyncCallback* callback) {}
  virtual void finishAllRendering() override;
  virtual void setDeferCommits(bool defer_commits) {}
  virtual void registerForAnimations(blink::WebLayer* layer) override;
  virtual void registerViewportLayers(
      const blink::WebLayer* page_scale_layer,
      const blink::WebLayer* inner_viewport_scroll_layer,
      const blink::WebLayer* outer_viewport_scroll_layer) override;
  virtual void clearViewportLayers() override;
  virtual void registerSelection(const blink::WebSelectionBound& start,
                                 const blink::WebSelectionBound& end) {}
  virtual void clearSelection() {}
  virtual void setShowFPSCounter(bool) {}
  virtual void setShowPaintRects(bool) {}
  virtual void setShowDebugBorders(bool) {}
  virtual void setContinuousPaintingEnabled(bool) {}
  virtual void setShowScrollBottleneckRects(bool) {}

  // OutputSurfaceMojoClient implementation.
  virtual void DidCreateSurface(cc::SurfaceId id) override;

 private:
  void OnSurfaceConnectionCreated(mojo::SurfacePtr surface, uint32_t id_namespace);
  void DidCreateSurfaceOnMainThread(cc::SurfaceId id);

  // widget_ and view_ will outlive us.
  blink::WebWidget* widget_;
  mojo::View* view_;
  scoped_ptr<cc::LayerTreeHost> layer_tree_host_;
  mojo::SurfacesServicePtr surfaces_service_;
  scoped_ptr<cc::OutputSurface> output_surface_;
  mojo::GpuPtr gpu_service_;
  scoped_refptr<base::SingleThreadTaskRunner>
      main_thread_compositor_task_runner_;
  base::WeakPtr<WebLayerTreeViewImpl> main_thread_bound_weak_ptr_;

  base::WeakPtrFactory<WebLayerTreeViewImpl> weak_factory_;
  DISALLOW_COPY_AND_ASSIGN(WebLayerTreeViewImpl);
};

}  // namespace sky

#endif  // SKY_VIEWER_PLATFORM_WEBLAYERTREEVIEW_IMPL_H_
