// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_FUCHSIA_ENGINE_H_
#define FLUTTER_SHELL_PLATFORM_FUCHSIA_ENGINE_H_

#include <fuchsia/intl/cpp/fidl.h>
#include <fuchsia/io/cpp/fidl.h>
#include <fuchsia/ui/gfx/cpp/fidl.h>
#include <fuchsia/ui/views/cpp/fidl.h>
#include <lib/async-loop/cpp/loop.h>
#include <lib/sys/cpp/service_directory.h>
#include <lib/zx/event.h>

#include "flutter/fml/macros.h"
#include "flutter/shell/common/shell.h"
#include "isolate_configurator.h"
#include "thread.h"

namespace flutter_runner {

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
         fml::RefPtr<const flutter::DartSnapshot> isolate_snapshot,
         fuchsia::ui::views::ViewToken view_token,
         UniqueFDIONS fdio_ns,
         fidl::InterfaceRequest<fuchsia::io::Directory> directory_request);
  ~Engine();

  // Returns the Dart return code for the root isolate if one is present. This
  // call is thread safe and synchronous. This call must be made infrequently.
  std::pair<bool, uint32_t> GetEngineReturnCode() const;

#if !defined(DART_PRODUCT)
  void WriteProfileToTrace() const;
#endif  // !defined(DART_PRODUCT)

 private:
  Delegate& delegate_;
  const std::string thread_label_;
  flutter::Settings settings_;
  std::array<std::unique_ptr<Thread>, 3> threads_;
  std::unique_ptr<IsolateConfigurator> isolate_configurator_;
  std::unique_ptr<flutter::Shell> shell_;
  zx::event vsync_event_;
  fml::WeakPtrFactory<Engine> weak_factory_;
  // A stub for the FIDL protocol fuchsia.intl.PropertyProvider.
  fuchsia::intl::PropertyProviderPtr intl_property_provider_;

  void OnMainIsolateStart();

  void OnMainIsolateShutdown();

  void Terminate();

  void OnSessionMetricsDidChange(const fuchsia::ui::gfx::Metrics& metrics);
  void OnSessionSizeChangeHint(float width_change_factor,
                               float height_change_factor);

  void OnDebugWireframeSettingsChanged(bool enabled);

  FML_DISALLOW_COPY_AND_ASSIGN(Engine);
};

}  // namespace flutter_runner

#endif  // FLUTTER_SHELL_PLATFORM_FUCHSIA_ENGINE_H_
