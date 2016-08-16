// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_UI_ENGINE_H_
#define SKY_SHELL_UI_ENGINE_H_

#include "flutter/assets/zip_asset_store.h"
#include "flutter/glue/drain_data_pipe_job.h"
#include "flutter/runtime/runtime_delegate.h"
#include "flutter/runtime/runtime_controller.h"
#include "flutter/services/engine/sky_engine.mojom.h"
#include "flutter/services/rasterizer/rasterizer.mojom.h"
#include "flutter/sky/shell/ui_delegate.h"
#include "lib/ftl/macros.h"
#include "lib/ftl/memory/weak_ptr.h"
#include "mojo/public/cpp/application/service_provider_impl.h"
#include "mojo/public/cpp/bindings/binding_set.h"
#include "mojo/public/cpp/bindings/binding.h"
#include "mojo/public/cpp/system/data_pipe.h"
#include "mojo/public/cpp/system/handle.h"
#include "mojo/public/interfaces/application/service_provider.mojom.h"
#include "mojo/services/asset_bundle/interfaces/asset_bundle.mojom.h"
#include "third_party/skia/include/core/SkPicture.h"

namespace sky {
class PlatformImpl;
namespace shell {
class Animator;

class Engine : public UIDelegate,
               public SkyEngine,
               public blink::RuntimeDelegate {
 public:
  struct Config {
    Config();
    ~Config();
  };

  explicit Engine(const Config& config, rasterizer::RasterizerPtr rasterizer);
  ~Engine() override;

  ftl::WeakPtr<Engine> GetWeakPtr();

  static void Init();

  void BeginFrame(ftl::TimePoint frame_time);

  void RunFromSource(const std::string& main,
                     const std::string& packages,
                     const std::string& bundle);

  Dart_Port GetUIIsolateMainPort();

  std::string GetUIIsolateName();

 private:
  // UIDelegate implementation:
  void ConnectToEngine(mojo::InterfaceRequest<SkyEngine> request) override;
  void OnOutputSurfaceCreated(const ftl::Closure& gpu_continuation) override;
  void OnOutputSurfaceDestroyed(const ftl::Closure& gpu_continuation) override;

  // SkyEngine implementation:
  void SetServices(ServicesDataPtr services) override;
  void OnViewportMetricsChanged(ViewportMetricsPtr metrics) override;
  void OnLocaleChanged(const mojo::String& language_code,
                       const mojo::String& country_code) override;
  void OnPointerPacket(pointer::PointerPacketPtr packet) override;

  void RunFromFile(const mojo::String& main,
                   const mojo::String& packages,
                   const mojo::String& bundle) override;
  void RunFromPrecompiledSnapshot(const mojo::String& bundle_path) override;
  void RunFromBundle(const mojo::String& script_uri,
                     const mojo::String& bundle_path) override;
  void RunFromBundleAndSnapshot(const mojo::String& script_uri,
                                const mojo::String& bundle_path,
                                const mojo::String& snapshot_path) override;
  void PushRoute(const mojo::String& route) override;
  void PopRoute() override;
  void OnAppLifecycleStateChanged(sky::AppLifecycleState state) override;

  // RuntimeDelegate methods:
  void ScheduleFrame() override;
  void Render(std::unique_ptr<flow::LayerTree> layer_tree) override;
  void DidCreateMainIsolate(Dart_Isolate isolate) override;
  void DidCreateSecondaryIsolate(Dart_Isolate isolate) override;

  void BindToServiceProvider(
      mojo::InterfaceRequest<mojo::ServiceProvider> request);

  void RunFromSnapshotStream(const std::string& script_uri,
                             mojo::ScopedDataPipeConsumerHandle snapshot);

  void SetupAssetBundle(const mojo::String& bundle_path);

  void StopAnimator();
  void StartAnimatorIfPossible();

  void ConfigureZipAssetBundle(const std::string& path);
  void ConfigureDirectoryAssetBundle(const std::string& path);
  void ConfigureRuntime(const std::string& script_uri);

  Config config_;
  std::unique_ptr<Animator> animator_;

  ServicesDataPtr services_;
  mojo::ServiceProviderImpl service_provider_impl_;
  mojo::ServiceProviderPtr incoming_services_;
  mojo::BindingSet<mojo::ServiceProvider> service_provider_bindings_;

  mojo::asset_bundle::AssetBundlePtr root_bundle_;
  std::unique_ptr<blink::RuntimeController> runtime_;

  std::unique_ptr<glue::DrainDataPipeJob> snapshot_drainer_;

  std::string initial_route_;
  ViewportMetricsPtr viewport_metrics_;
  std::string language_code_;
  std::string country_code_;
  mojo::Binding<SkyEngine> binding_;
  ftl::RefPtr<blink::ZipAssetStore> asset_store_;

  // TODO(eseidel): This should move into an AnimatorStateMachine.
  bool activity_running_;
  bool have_surface_;

  ftl::WeakPtrFactory<Engine> weak_factory_;

  FTL_DISALLOW_COPY_AND_ASSIGN(Engine);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_UI_ENGINE_H_
