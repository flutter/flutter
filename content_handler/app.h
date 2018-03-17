// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_CONTENT_HANDLER_APP_H_
#define FLUTTER_CONTENT_HANDLER_APP_H_

#include <memory>
#include <unordered_set>

#include "flutter/content_handler/application_controller_impl.h"
#include "lib/app/cpp/application_context.h"
#include "lib/app/fidl/application_runner.fidl.h"
#include "lib/fsl/threading/thread.h"
#include "lib/fxl/macros.h"
#include "lib/fxl/synchronization/waitable_event.h"

namespace flutter_runner {

class App : public component::ApplicationRunner {
 public:
  App();
  ~App();

  static App& Shared();

  // |component::ApplicationRunner| implementation:

  void StartApplication(
      component::ApplicationPackagePtr application,
      component::ApplicationStartupInfoPtr startup_info,
      f1dl::InterfaceRequest<component::ApplicationController> controller) override;

  void Destroy(ApplicationControllerImpl* controller);

  struct PlatformViewInfo {
    uintptr_t view_id;
    int64_t isolate_id;
    std::string isolate_name;
  };

  void WaitForPlatformViewIds(std::vector<PlatformViewInfo>* platform_view_ids);

 private:
  void WaitForPlatformViewsIdsUIThread(
      std::vector<PlatformViewInfo>* platform_view_ids,
      fxl::AutoResetWaitableEvent* latch);
  void UpdateProcessLabel();

  std::unique_ptr<component::ApplicationContext> context_;
  std::unique_ptr<fsl::Thread> gpu_thread_;
  std::unique_ptr<fsl::Thread> io_thread_;
  f1dl::BindingSet<component::ApplicationRunner> runner_bindings_;
  std::unordered_map<ApplicationControllerImpl*,
                     std::unique_ptr<ApplicationControllerImpl>>
      controllers_;
  std::string base_label_;

  FXL_DISALLOW_COPY_AND_ASSIGN(App);
};

}  // namespace flutter_runner

#endif  // FLUTTER_CONTENT_HANDLER_APP_H_
