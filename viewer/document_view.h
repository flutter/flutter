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
#include "mojo/public/interfaces/application/application.mojom.h"
#include "mojo/services/public/interfaces/content_handler/content_handler.mojom.h"
#include "mojo/services/public/interfaces/navigation/navigation.mojom.h"
#include "mojo/services/public/interfaces/network/url_loader.mojom.h"
#include "mojo/services/view_manager/public/cpp/view_manager_client_factory.h"
#include "mojo/services/view_manager/public/cpp/view_manager_delegate.h"
#include "mojo/services/view_manager/public/cpp/view_observer.h"
#include "sky/compositor/layer_client.h"
#include "sky/compositor/layer_host_client.h"
#include "sky/engine/public/platform/ServiceProvider.h"
#include "sky/engine/public/web/WebFrameClient.h"
#include "sky/engine/public/web/WebViewClient.h"
#include "sky/viewer/services/inspector_impl.h"

namespace mojo {
class ViewManager;
class View;
}

namespace inspector {
class InspectorBackendMojo;
}

namespace sky {
class InspectorHostImpl;
class ScriptRunner;
class Layer;
class LayerHost;

class DocumentView : public blink::ServiceProvider,
                     public blink::WebViewClient,
                     public blink::WebFrameClient,
                     public sky::LayerClient,
                     public sky::LayerHostClient,
                     public mojo::ViewManagerDelegate,
                     public mojo::ViewObserver {
 public:
  DocumentView(mojo::ServiceProviderPtr provider,
               mojo::URLResponsePtr response,
               mojo::Shell* shell);
  virtual ~DocumentView();

  base::WeakPtr<DocumentView> GetWeakPtr();

  blink::WebView* web_view() const { return web_view_; }
  mojo::ServiceProvider* imported_services() const {
    return imported_services_.get();
  }

  mojo::Shell* shell() const { return shell_; }

  // sky::LayerHostClient
  mojo::Shell* GetShell() override;
  void BeginFrame(base::TimeTicks frame_time) override;
  void OnSurfaceIdAvailable(mojo::SurfaceIdPtr surface_id) override;
  // sky::LayerClient
  void PaintContents(SkCanvas* canvas, const gfx::Rect& clip) override;

  void StartDebuggerInspectorBackend();

 private:
  // WebWidgetClient methods:
  void initializeLayerTreeView() override;
  void scheduleAnimation() override;

  // WebFrameClient methods:
  mojo::View* createChildFrame(const blink::WebURL& url) override;
  void frameDetached(blink::WebFrame*) override;
  blink::WebNavigationPolicy decidePolicyForNavigation(
    const blink::WebFrameClient::NavigationPolicyInfo& info) override;
  void didAddMessageToConsole(
      const blink::WebConsoleMessage& message,
      const blink::WebString& source_name,
      unsigned source_line,
      const blink::WebString& stack_trace) override;
  void didCreateScriptContext(
      blink::WebLocalFrame*,
      v8::Handle<v8::Context>) override;

  // WebViewClient methods:
  blink::ServiceProvider& services() override;

  // Services methods:
  mojo::NavigatorHost* NavigatorHost() override;
  mojo::Shell* Shell() override;

  // ViewManagerDelegate methods:
  void OnEmbed(
      mojo::ViewManager* view_manager,
      mojo::View* root,
      mojo::ServiceProviderImpl* exported_services,
      scoped_ptr<mojo::ServiceProvider> imported_services) override;
  void OnViewManagerDisconnected(mojo::ViewManager* view_manager) override;

  // ViewObserver methods:
  void OnViewBoundsChanged(mojo::View* view,
                           const mojo::Rect& old_bounds,
                           const mojo::Rect& new_bounds) override;
  void OnViewFocusChanged(mojo::View* gained_focus,
                          mojo::View* lost_focus) override;
  void OnViewDestroyed(mojo::View* view) override;
  void OnViewInputEvent(mojo::View* view, const mojo::EventPtr& event) override;

  void Load(mojo::URLResponsePtr response);

  mojo::URLResponsePtr response_;
  mojo::ServiceProviderImpl exported_services_;
  scoped_ptr<mojo::ServiceProvider> imported_services_;
  mojo::Shell* shell_;
  mojo::LazyInterfacePtr<mojo::NavigatorHost> navigator_host_;
  blink::WebView* web_view_;
  mojo::View* root_;
  mojo::ViewManagerClientFactory view_manager_client_factory_;
  InspectorServiceFactory inspector_service_factory_;
  scoped_ptr<LayerHost> layer_host_;
  scoped_refptr<Layer> root_layer_;
  scoped_ptr<ScriptRunner> script_runner_;
  scoped_ptr<InspectorHostImpl> inspector_host_;
  scoped_ptr<inspector::InspectorBackendMojo> inspector_backend_;
  int debugger_id_;

  base::WeakPtrFactory<DocumentView> weak_factory_;
  DISALLOW_COPY_AND_ASSIGN(DocumentView);
};

}  // namespace sky

#endif  // SKY_VIEWER_DOCUMENT_VIEW_H_
