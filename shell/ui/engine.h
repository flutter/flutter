// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_UI_ENGINE_H_
#define SKY_SHELL_UI_ENGINE_H_

#include "base/macros.h"
#include "base/memory/scoped_ptr.h"
#include "base/memory/weak_ptr.h"
#include "base/single_thread_task_runner.h"
#include "mojo/public/cpp/bindings/binding.h"
#include "mojo/public/cpp/system/core.h"
#include "mojo/public/interfaces/application/service_provider.mojom.h"
#include "mojo/services/navigation/public/interfaces/navigation.mojom.h"
#include "skia/ext/refptr.h"
#include "sky/engine/public/platform/ServiceProvider.h"
#include "sky/engine/public/sky/sky_view.h"
#include "sky/engine/public/sky/sky_view_client.h"
#include "sky/engine/public/web/WebFrameClient.h"
#include "sky/engine/public/web/WebViewClient.h"
#include "sky/shell/gpu_delegate.h"
#include "sky/shell/ui_delegate.h"
#include "sky/shell/service_provider.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "ui/gfx/geometry/size.h"

namespace sky {
class PlatformImpl;
namespace shell {
class Animator;

class Engine : public UIDelegate,
               public ViewportObserver,
               public blink::ServiceProvider,
               public mojo::NavigatorHost,
               public blink::WebFrameClient,
               public blink::WebViewClient,
               public blink::SkyViewClient {
 public:
  struct Config {
    ServiceProviderContext* service_provider_context;

    base::WeakPtr<GPUDelegate> gpu_delegate;
    scoped_refptr<base::SingleThreadTaskRunner> gpu_task_runner;
  };

  explicit Engine(const Config& config);
  ~Engine() override;

  base::WeakPtr<Engine> GetWeakPtr();

  void Init();

  void BeginFrame(base::TimeTicks frame_time);
  skia::RefPtr<SkPicture> Paint();

 private:
  // UIDelegate methods:
  void ConnectToViewportObserver(
      mojo::InterfaceRequest<ViewportObserver> request) override;
  void OnAcceleratedWidgetAvailable(gfx::AcceleratedWidget widget) override;
  void OnOutputSurfaceDestroyed() override;

  // ViewportObserver:
  void OnViewportMetricsChanged(int width, int height,
                                float device_pixel_ratio) override;
  void OnInputEvent(InputEventPtr event) override;
  void LoadURL(const mojo::String& url) override;

  // WebViewClient methods:
  void frameDetached(blink::WebFrame*) override;
  void initializeLayerTreeView() override;
  void scheduleVisualUpdate() override;
  blink::WebScreenInfo screenInfo() override;
  blink::ServiceProvider* services() override;

  // WebFrameClient methods:
  void didCreateIsolate(blink::WebLocalFrame* frame,
                        Dart_Isolate isolate) override;

  // SkyViewClient methods:
  void ScheduleFrame() override;
  void DidCreateIsolate(Dart_Isolate isolate) override;

  // Services methods:
  mojo::NavigatorHost* NavigatorHost() override;

  // NavigatorHost methods:
  void RequestNavigate(mojo::Target target,
                       mojo::URLRequestPtr request) override;
  void DidNavigateLocally(const mojo::String& url) override;
  void RequestNavigateHistory(int32_t delta) override;

  void UpdateWebViewSize();

  Config config_;
  mojo::ServiceProviderPtr service_provider_;
  scoped_ptr<PlatformImpl> platform_impl_;
  scoped_ptr<Animator> animator_;

  std::unique_ptr<blink::SkyView> sky_view_;
  blink::WebView* web_view_;

  float device_pixel_ratio_;
  gfx::Size physical_size_;
  mojo::Binding<ViewportObserver> viewport_observer_binding_;

  base::WeakPtrFactory<Engine> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(Engine);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_UI_ENGINE_H_
