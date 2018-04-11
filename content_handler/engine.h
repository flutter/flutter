// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/shell/common/shell.h"
#include "isolate_configurator.h"
#include "lib/app/cpp/application_context.h"
#include "lib/fsl/threading/thread.h"
#include "lib/fxl/macros.h"
#include "lib/fxl/memory/weak_ptr.h"
#include "lib/ui/views/fidl/view_manager.fidl.h"

namespace flutter {

// Represents an instance of running Flutter engine along with the threads that
// host the same.
class Engine final {
 public:
  class Delegate {
   public:
    virtual void OnEngineTerminate(const Engine* holder) = 0;
  };

  Engine(Delegate& delegate,
         std::string thread_label,
         component::ApplicationContext& application_context,
         blink::Settings settings,
         f1dl::InterfaceRequest<mozart::ViewOwner> view_owner,
         const UniqueFDIONS& fdio_ns,
         f1dl::InterfaceRequest<component::ServiceProvider>
             outgoing_services_request);

  ~Engine();

  // Returns the Dart return code for the root isolate if one is present. This
  // call is thread safe and synchronous. This call must be made infrequently.
  std::pair<bool, uint32_t> GetEngineReturnCode() const;

 private:
  Delegate& delegate_;
  const std::string thread_label_;
  blink::Settings settings_;
  std::array<fsl::Thread, 3> host_threads_;
  std::unique_ptr<IsolateConfigurator> isolate_configurator_;
  std::unique_ptr<shell::Shell> shell_;
  fxl::WeakPtrFactory<Engine> weak_factory_;

  void OnMainIsolateStart();

  void OnMainIsolateShutdown();

  void Terminate();

  void OnSessionMetricsDidChange(double device_pixel_ratio);

  void UpdateNativeThreadLabelNames() const;

  FXL_DISALLOW_COPY_AND_ASSIGN(Engine);
};

}  // namespace flutter
