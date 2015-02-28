// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_VIEWER_DOCUMENT_VIEW_H_
#define SKY_VIEWER_DOCUMENT_VIEW_H_

#include "base/callback.h"
#include "base/memory/weak_ptr.h"
#include "mojo/public/cpp/application/lazy_interface_ptr.h"
#include "mojo/public/cpp/application/service_provider_impl.h"
#include "mojo/public/cpp/bindings/interface_impl.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "mojo/public/interfaces/application/application.mojom.h"
#include "mojo/services/content_handler/public/interfaces/content_handler.mojom.h"
#include "mojo/services/navigation/public/interfaces/navigation.mojom.h"
#include "mojo/services/network/public/interfaces/url_loader.mojom.h"
#include "mojo/services/service_registry/public/interfaces/service_registry.mojom.h"
#include "mojo/services/view_manager/public/cpp/view_manager_client_factory.h"
#include "mojo/services/view_manager/public/cpp/view_manager_delegate.h"
#include "mojo/services/view_manager/public/cpp/view_observer.h"
#include "sky/compositor/layer_client.h"
#include "sky/compositor/layer_host_client.h"
#include "sky/engine/public/platform/ServiceProvider.h"
#include "sky/engine/public/web/WebFrameClient.h"
#include "sky/engine/public/web/WebViewClient.h"
#include "sky/services/testing/test_harness.mojom.h"
#include "ui/events/gestures/gesture_types.h"

namespace mojo {
class ViewManager;
class View;
}

namespace sky {
class Rasterizer;
class RasterizerBitmap;
class Layer;
class LayerHost;

class DocumentView : public blink::ServiceProvider,
                     public blink::WebFrameClient,
                     public blink::WebViewClient,
                     public mojo::ViewManagerDelegate,
                     public mojo::ViewObserver,
                     public sky::LayerClient,
                     public sky::LayerHostClient,
                     public ui::GestureConsumer {
 public:
  DocumentView(mojo::InterfaceRequest<mojo::ServiceProvider> services,
               mojo::ServiceProviderPtr exported_services,
               mojo::URLResponsePtr response,
               mojo::Shell* shell);
  ~DocumentView() override;

  base::WeakPtr<DocumentView> GetWeakPtr();

  blink::WebView* web_view() const { return web_view_; }

  mojo::Shell* shell() const { return shell_; }

  // sky::LayerHostClient
  mojo::Shell* GetShell() override;
  void BeginFrame(base::TimeTicks frame_time) override;
  void OnSurfaceIdAvailable(mojo::SurfaceIdPtr surface_id) override;
  // sky::LayerClient
  void PaintContents(SkCanvas* canvas, const gfx::Rect& clip) override;

  void StartDebuggerInspectorBackend();

  void GetPixelsForTesting(std::vector<unsigned char>* pixels);

  TestHarnessPtr TakeTestHarness();
  mojo::ScopedMessagePipeHandle TakeServicesProvidedToEmbedder();
  mojo::ScopedMessagePipeHandle TakeServicesProvidedByEmbedder();
  mojo::ScopedMessagePipeHandle TakeServiceRegistry();

 private:
  // WebViewClient methods:
  void initializeLayerTreeView() override;
  void scheduleVisualUpdate() override;
  blink::WebScreenInfo screenInfo() override;

  // WebFrameClient methods:
  mojo::View* createChildFrame() override;
  void frameDetached(blink::WebFrame*) override;
  blink::WebNavigationPolicy decidePolicyForNavigation(
    const blink::WebFrameClient::NavigationPolicyInfo& info) override;
  void didAddMessageToConsole(
      const blink::WebConsoleMessage& message,
      const blink::WebString& source_name,
      unsigned source_line,
      const blink::WebString& stack_trace) override;
  void didCreateIsolate(blink::WebLocalFrame* frame,
                        Dart_Isolate isolate) override;

  // WebViewClient methods:
  blink::ServiceProvider* services() override;

  // Services methods:
  mojo::NavigatorHost* NavigatorHost() override;

  // ViewManagerDelegate methods:
  void OnEmbed(mojo::View* root,
               mojo::InterfaceRequest<mojo::ServiceProvider> services,
               mojo::ServiceProviderPtr exposed_services) override;
  void OnViewManagerDisconnected(mojo::ViewManager* view_manager) override;

  // ViewObserver methods:
  void OnViewBoundsChanged(mojo::View* view,
                           const mojo::Rect& old_bounds,
                           const mojo::Rect& new_bounds) override;
  void OnViewViewportMetricsChanged(
      mojo::View* view,
      const mojo::ViewportMetrics& old_metrics,
      const mojo::ViewportMetrics& new_metrics) override;
  void OnViewFocusChanged(mojo::View* gained_focus,
                          mojo::View* lost_focus) override;
  void OnViewDestroyed(mojo::View* view) override;
  void OnViewInputEvent(mojo::View* view, const mojo::EventPtr& event) override;

  void Load(mojo::URLResponsePtr response);
  float GetDevicePixelRatio() const;
  scoped_ptr<Rasterizer> CreateRasterizer();

  void UpdateRootSizeAndViewportMetrics(const mojo::Rect& new_bounds);

  void InitServiceRegistry();

  mojo::URLResponsePtr response_;
  mojo::ServiceProviderImpl exported_services_;
  mojo::ServiceProviderPtr imported_services_;
  mojo::InterfaceRequest<mojo::ServiceProvider> services_provided_to_embedder_;
  mojo::ServiceProviderPtr services_provided_by_embedder_;
  mojo::Shell* shell_;
  TestHarnessPtr test_harness_;
  mojo::NavigatorHostPtr navigator_host_;
  blink::WebView* web_view_;
  mojo::View* root_;
  mojo::ViewManagerClientFactory view_manager_client_factory_;
  scoped_ptr<LayerHost> layer_host_;
  scoped_refptr<Layer> root_layer_;
  RasterizerBitmap* bitmap_rasterizer_;  // Used for pixel tests.
  service_registry::ServiceRegistryPtr service_registry_;
  scoped_ptr<mojo::StrongBinding<mojo::ServiceProvider>>
      service_registry_service_provider_binding_;
  base::WeakPtrFactory<DocumentView> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(DocumentView);
};

}  // namespace sky

#endif  // SKY_VIEWER_DOCUMENT_VIEW_H_
