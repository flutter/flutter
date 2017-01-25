// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_CONTENT_HANDLER_APP_H_
#define FLUTTER_CONTENT_HANDLER_APP_H_

#include <memory>
#include <unordered_set>

#include "apps/modular/lib/app/application_context.h"
#include "apps/modular/services/application/application_runner.fidl.h"
#include "flutter/content_handler/application_controller_impl.h"
#include "flutter/content_handler/content_handler_thread.h"
#include "lib/ftl/macros.h"

namespace flutter_runner {

class App : public modular::ApplicationRunner {
 public:
  App();
  ~App();

  // |modular::ApplicationRunner| implementation:

  void StartApplication(modular::ApplicationPackagePtr application,
                        modular::ApplicationStartupInfoPtr startup_info,
                        fidl::InterfaceRequest<modular::ApplicationController>
                            controller) override;

  void Destroy(ApplicationControllerImpl* controller);

 private:
  std::unique_ptr<modular::ApplicationContext> context_;
  std::unique_ptr<Thread> gpu_thread_;
  std::unique_ptr<Thread> io_thread_;
  fidl::BindingSet<modular::ApplicationRunner> runner_bindings_;
  std::unordered_map<ApplicationControllerImpl*,
                     std::unique_ptr<ApplicationControllerImpl>>
      controllers_;

  FTL_DISALLOW_COPY_AND_ASSIGN(App);
};

}  // namespace flutter_runner

#endif  // FLUTTER_CONTENT_HANDLER_APP_H_
