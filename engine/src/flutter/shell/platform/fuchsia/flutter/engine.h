// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_FUCHSIA_ENGINE_H_
#define FLUTTER_SHELL_PLATFORM_FUCHSIA_ENGINE_H_

#include <optional>

#include <fuchsia/intl/cpp/fidl.h>
#include <fuchsia/io/cpp/fidl.h>
#include <fuchsia/ui/gfx/cpp/fidl.h>
#include <fuchsia/ui/views/cpp/fidl.h>
#include <lib/async-loop/cpp/loop.h>
#include <lib/sys/cpp/service_directory.h>
#include <lib/ui/scenic/cpp/id.h>
#include <lib/ui/scenic/cpp/view_ref_pair.h>
#include <lib/zx/event.h>

#include "flutter/flow/embedded_views.h"
#include "flutter/flow/surface.h"
#include "flutter/fml/macros.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/platform/fuchsia/flutter/accessibility_bridge.h"

#include "default_session_connection.h"
#include "flutter_runner_product_configuration.h"
#include "fuchsia_external_view_embedder.h"
#include "isolate_configurator.h"
#include "vulkan_surface_producer.h"

namespace flutter_runner {

namespace testing {
class EngineTest;
}

// Represents an instance of running Flutter engine along with the threads
// that host the same.
class Engine final {
 public:
  class Delegate {
   public:
    virtual void OnEngineTerminate(const Engine* holder) = 0;
  };

  Engine(Delegate& delegate,
         std::string thread_label,
         std::shared_ptr<sys::ServiceDirectory> svc,
         std::shared_ptr<sys::ServiceDirectory> runner_services,
         flutter::Settings settings,
         fuchsia::ui::views::ViewToken view_token,
         scenic::ViewRefPair view_ref_pair,
         UniqueFDIONS fdio_ns,
         fidl::InterfaceRequest<fuchsia::io::Directory> directory_request,
         FlutterRunnerProductConfiguration product_config);
  ~Engine();

  // Returns the Dart return code for the root isolate if one is present. This
  // call is thread safe and synchronous. This call must be made infrequently.
  std::optional<uint32_t> GetEngineReturnCode() const;

#if !defined(DART_PRODUCT)
  void WriteProfileToTrace() const;
#endif  // !defined(DART_PRODUCT)

 private:
  Delegate& delegate_;

  const std::string thread_label_;
  std::array<fml::Thread, 3> threads_;

  std::shared_ptr<DefaultSessionConnection> session_connection_;
  std::optional<VulkanSurfaceProducer> surface_producer_;
  std::shared_ptr<FuchsiaExternalViewEmbedder> external_view_embedder_;

  std::unique_ptr<IsolateConfigurator> isolate_configurator_;
  std::unique_ptr<flutter::Shell> shell_;
  std::unique_ptr<AccessibilityBridge> accessibility_bridge_;

  fuchsia::intl::PropertyProviderPtr intl_property_provider_;

  zx::event vsync_event_;

  bool intercept_all_input_ = false;

  fml::WeakPtrFactory<Engine> weak_factory_;

  static void WarmupSkps(
      fml::BasicTaskRunner* concurrent_task_runner,
      fml::BasicTaskRunner* raster_task_runner,
      VulkanSurfaceProducer& surface_producer,
      uint64_t width,
      uint64_t height,
      std::shared_ptr<flutter::AssetManager> asset_manager,
      std::optional<const std::vector<std::string>> skp_names,
      std::optional<std::function<void(uint32_t)>> completion_callback);

  void OnMainIsolateStart();

  void OnMainIsolateShutdown();

  void Terminate();

  void DebugWireframeSettingsChanged(bool enabled);
  void CreateView(int64_t view_id,
                  ViewCallback on_view_created,
                  ViewIdCallback on_view_bound,
                  bool hit_testable,
                  bool focusable);
  void UpdateView(int64_t view_id,
                  SkRect occlusion_hint,
                  bool hit_testable,
                  bool focusable);
  void DestroyView(int64_t view_id, ViewIdCallback on_view_unbound);

  std::shared_ptr<flutter::ExternalViewEmbedder> GetExternalViewEmbedder();

  std::unique_ptr<flutter::Surface> CreateSurface();

  friend class testing::EngineTest;

  fidl::InterfacePtr<fuchsia::ui::input3::Keyboard> keyboard_svc_;

  FML_DISALLOW_COPY_AND_ASSIGN(Engine);
};

}  // namespace flutter_runner

#endif  // FLUTTER_SHELL_PLATFORM_FUCHSIA_ENGINE_H_
