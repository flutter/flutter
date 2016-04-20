// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_UI_ENGINE_H_
#define SKY_SHELL_UI_ENGINE_H_

#include "base/files/file_path.h"
#include "base/macros.h"
#include "base/memory/weak_ptr.h"
#include "base/single_thread_task_runner.h"
#include "mojo/common/binding_set.h"
#include "mojo/public/cpp/application/interface_factory.h"
#include "mojo/public/cpp/application/service_provider_impl.h"
#include "mojo/public/cpp/bindings/binding.h"
#include "mojo/public/cpp/system/data_pipe.h"
#include "mojo/public/cpp/system/handle.h"
#include "mojo/public/interfaces/application/service_provider.mojom.h"
#include "mojo/services/asset_bundle/interfaces/asset_bundle.mojom.h"
#include "skia/ext/refptr.h"
#include "sky/engine/public/sky/sky_view.h"
#include "sky/engine/public/sky/sky_view_client.h"
#include "sky/services/engine/sky_engine.mojom.h"
#include "sky/services/rasterizer/rasterizer.mojom.h"
#include "sky/shell/rasterizer.h"
#include "sky/shell/ui_delegate.h"
#include "third_party/skia/include/core/SkPicture.h"

namespace mojo {
namespace asset_bundle {
class ZipAssetBundle;
}
}

namespace sky {
class PlatformImpl;
namespace shell {
class Animator;

class Engine : public UIDelegate,
               public SkyEngine,
               public blink::SkyViewClient {
 public:
  struct Config {
    Config();
    ~Config();

    scoped_refptr<base::SingleThreadTaskRunner> gpu_task_runner;
  };

  explicit Engine(const Config& config, rasterizer::RasterizerPtr rasterizer);
  ~Engine() override;

  base::WeakPtr<Engine> GetWeakPtr();

  static void Init();

  void BeginFrame(base::TimeTicks frame_time);

 private:
  // UIDelegate implementation:
  void ConnectToEngine(mojo::InterfaceRequest<SkyEngine> request) override;
  void OnOutputSurfaceCreated(const base::Closure& gpu_continuation) override;
  void OnOutputSurfaceDestroyed(const base::Closure& gpu_continuation) override;

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

  // SkyViewClient methods:
  void ScheduleFrame() override;
  void FlushRealTimeEvents() override;
  void Render(std::unique_ptr<flow::LayerTree> layer_tree) override;
  void DidCreateMainIsolate(Dart_Isolate isolate) override;
  void DidCreateSecondaryIsolate(Dart_Isolate isolate) override;

  void BindToServiceProvider(
      mojo::InterfaceRequest<mojo::ServiceProvider> request);

  void RunFromLibrary(const std::string& name);
  void RunFromSnapshotStream(const std::string& script_uri,
                             mojo::ScopedDataPipeConsumerHandle snapshot);

  void SetupAssetBundle(const mojo::String& bundle_path);

  void StopAnimator();
  void StartAnimatorIfPossible();

  void ConfigureZipAssetBundle(const mojo::String& path);

  Config config_;
  std::unique_ptr<Animator> animator_;

  ServicesDataPtr services_;
  mojo::ServiceProviderImpl service_provider_impl_;
  mojo::ServiceProviderPtr incoming_services_;
  mojo::BindingSet<mojo::ServiceProvider> service_provider_bindings_;

  mojo::asset_bundle::AssetBundlePtr root_bundle_;
  std::unique_ptr<blink::DartLibraryProvider> dart_library_provider_;
  std::unique_ptr<blink::SkyView> sky_view_;

  std::string initial_route_;
  ViewportMetricsPtr viewport_metrics_;
  std::string language_code_;
  std::string country_code_;
  mojo::Binding<SkyEngine> binding_;
  scoped_refptr<mojo::asset_bundle::ZipAssetBundle> zip_asset_bundle_;

  // TODO(eseidel): This should move into an AnimatorStateMachine.
  bool activity_running_;
  bool have_surface_;

  base::WeakPtrFactory<Engine> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(Engine);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_UI_ENGINE_H_
