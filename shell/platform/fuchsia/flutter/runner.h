// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_FUCHSIA_RUNNER_H_
#define FLUTTER_SHELL_PLATFORM_FUCHSIA_RUNNER_H_

#include <memory>
#include <unordered_map>

#include <fuchsia/sys/cpp/fidl.h>
#include <lib/async-loop/cpp/loop.h>
#include <lib/sys/cpp/component_context.h>
#include <lib/trace-engine/instrumentation.h>
#include <lib/trace/observer.h>

#include "component.h"
#include "flutter/fml/macros.h"
#include "lib/fidl/cpp/binding_set.h"
#include "runtime/dart/utils/vmservice_object.h"

namespace flutter_runner {

// Publishes the |fuchsia::sys::Runner| service and runs applications on
// their own threads.
class Runner final : public fuchsia::sys::Runner {
 public:
  // Does not take ownership of loop or context.
  Runner(async::Loop* loop, sys::ComponentContext* context);

  ~Runner();

 private:
  async::Loop* loop_;

  sys::ComponentContext* context_;
  fidl::BindingSet<fuchsia::sys::Runner> active_applications_bindings_;
  std::unordered_map<const Application*, ActiveApplication>
      active_applications_;

#if !defined(DART_PRODUCT)
  // The connection between the Dart VM service and The Hub.
  std::unique_ptr<dart_utils::VMServiceObject> vmservice_object_;

  std::unique_ptr<trace::TraceObserver> trace_observer_;
  trace_prolonged_context_t* prolonged_context_;
#endif  // !defined(DART_PRODUCT)

  // |fuchsia::sys::Runner|
  void StartComponent(fuchsia::sys::Package package,
                      fuchsia::sys::StartupInfo startup_info,
                      fidl::InterfaceRequest<fuchsia::sys::ComponentController>
                          controller) override;

  void RegisterApplication(
      fidl::InterfaceRequest<fuchsia::sys::Runner> request);

  void UnregisterApplication(const Application* application);

  void OnApplicationTerminate(const Application* application);

  void SetupICU();

#if !defined(DART_PRODUCT)
  void SetupTraceObserver();
#endif  // !defined(DART_PRODUCT)

  // Called from SetupICU, for testing only.  Returns false on error.
  static bool SetupICUInternal();
  // Called from SetupICU, for testing only.  Returns false on error.
  static bool SetupTZDataInternal();
#if defined(FRIEND_TEST)
  FRIEND_TEST(RunnerTest, TZData);
  FRIEND_TEST(RunnerTZDataTest, LoadsWithoutTZDataPresent);
#endif  // defined(FRIEND_TEST)

  FML_DISALLOW_COPY_AND_ASSIGN(Runner);
};

}  // namespace flutter_runner

#endif  // FLUTTER_SHELL_PLATFORM_FUCHSIA_RUNNER_H_
