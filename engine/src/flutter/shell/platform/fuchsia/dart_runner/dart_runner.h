// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_FUCHSIA_DART_RUNNER_DART_RUNNER_H_
#define FLUTTER_SHELL_PLATFORM_FUCHSIA_DART_RUNNER_DART_RUNNER_H_

#include <fuchsia/component/runner/cpp/fidl.h>
#include <fuchsia/sys/cpp/fidl.h>
#include <lib/fidl/cpp/binding_set.h>
#include <lib/sys/cpp/component_context.h>

#include "dart_test_component_controller_v2.h"
#include "runtime/dart/utils/mapped_resource.h"

namespace dart_runner {

class DartRunner : public fuchsia::sys::Runner,
                   public fuchsia::component::runner::ComponentRunner {
 public:
  explicit DartRunner(sys::ComponentContext* context);
  ~DartRunner() override;

 private:
  // |fuchsia::sys::Runner| implementation:
  void StartComponent(fuchsia::sys::Package package,
                      fuchsia::sys::StartupInfo startup_info,
                      fidl::InterfaceRequest<fuchsia::sys::ComponentController>
                          controller) override;

  // |fuchsia::component::runner::ComponentRunner| implementation:
  void Start(
      fuchsia::component::runner::ComponentStartInfo start_info,
      fidl::InterfaceRequest<fuchsia::component::runner::ComponentController>
          controller) override;

  // Add test components to this map to ensure it is kept alive in memory for
  // the duration of test execution and retrieval of exit code.
  std::map<DartTestComponentControllerV2*,
           std::shared_ptr<DartTestComponentControllerV2>>
      test_components_;

  // Not owned by DartRunner.
  sys::ComponentContext* context_;
  fidl::BindingSet<fuchsia::sys::Runner> bindings_;
  fidl::BindingSet<fuchsia::component::runner::ComponentRunner>
      component_runner_bindings_;

#if !defined(AOT_RUNTIME)
  dart_utils::MappedResource vm_snapshot_data_;
  dart_utils::MappedResource vm_snapshot_instructions_;
#endif

  // Disallow copy and assignment.
  DartRunner(const DartRunner&) = delete;
  DartRunner& operator=(const DartRunner&) = delete;
};

}  // namespace dart_runner

#endif  // FLUTTER_SHELL_PLATFORM_FUCHSIA_DART_RUNNER_DART_RUNNER_H_
