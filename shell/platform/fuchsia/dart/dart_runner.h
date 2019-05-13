// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TOPAZ_RUNTIME_DART_RUNNER_DART_RUNNER_H_
#define TOPAZ_RUNTIME_DART_RUNNER_DART_RUNNER_H_

#include <fuchsia/sys/cpp/fidl.h>
#include <lib/fidl/cpp/binding_set.h>
#include <lib/sys/cpp/component_context.h>

#include "mapped_resource.h"

namespace dart_runner {

class DartRunner : public fuchsia::sys::Runner {
 public:
  explicit DartRunner();
  ~DartRunner() override;

 private:
  // |fuchsia::sys::Runner| implementation:
  void StartComponent(
      fuchsia::sys::Package package,
      fuchsia::sys::StartupInfo startup_info,
      ::fidl::InterfaceRequest<fuchsia::sys::ComponentController> controller)
      override;

  std::unique_ptr<sys::ComponentContext> context_;
  fidl::BindingSet<fuchsia::sys::Runner> bindings_;

#if !defined(AOT_RUNTIME)
  MappedResource vm_snapshot_data_;
  MappedResource vm_snapshot_instructions_;
#endif

  // Disallow copy and assignment.
  DartRunner(const DartRunner&) = delete;
  DartRunner& operator=(const DartRunner&) = delete;
};

}  // namespace dart_runner

#endif  // TOPAZ_RUNTIME_DART_RUNNER_DART_RUNNER_H_
