// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TOPAZ_RUNTIME_DART_RUNNER_DART_COMPONENT_CONTROLLER_H_
#define TOPAZ_RUNTIME_DART_RUNNER_DART_COMPONENT_CONTROLLER_H_

#include <memory>

#include <fuchsia/sys/cpp/fidl.h>
#include <lib/async-loop/cpp/loop.h>
#include <lib/async/cpp/wait.h>
#include <lib/fdio/namespace.h>
#include <lib/sys/cpp/component_context.h>
#include <lib/sys/cpp/service_directory.h>
#include <lib/zx/timer.h>

#include "lib/fidl/cpp/binding.h"
#include "mapped_resource.h"
#include "third_party/dart/runtime/include/dart_api.h"

namespace dart_runner {

class DartComponentController : public fuchsia::sys::ComponentController {
 public:
  DartComponentController(
      fuchsia::sys::Package package,
      fuchsia::sys::StartupInfo startup_info,
      std::shared_ptr<sys::ServiceDirectory> runner_incoming_services,
      fidl::InterfaceRequest<fuchsia::sys::ComponentController> controller);
  ~DartComponentController() override;

  bool Setup();
  void Run();
  bool Main();
  void SendReturnCode();

 private:
  bool SetupNamespace();

  bool SetupFromKernel();
  bool SetupFromAppSnapshot();

  bool CreateIsolate(const uint8_t* isolate_snapshot_data,
                     const uint8_t* isolate_snapshot_instructions,
                     const uint8_t* shared_snapshot_data,
                     const uint8_t* shared_snapshot_instructions);

  int SetupFileDescriptor(fuchsia::sys::FileDescriptorPtr fd);

  // |ComponentController|
  void Kill() override;
  void Detach() override;

  // Idle notification.
  void MessageEpilogue(Dart_Handle result);
  void OnIdleTimer(async_dispatcher_t* dispatcher,
                   async::WaitBase* wait,
                   zx_status_t status,
                   const zx_packet_signal* signal);

  // The loop must be the first declared member so that it gets destroyed after
  // binding_ which expects the existence of a loop.
  std::unique_ptr<async::Loop> loop_;
  std::string label_;
  std::string url_;
  fuchsia::sys::Package package_;
  fuchsia::sys::StartupInfo startup_info_;
  std::shared_ptr<sys::ServiceDirectory> runner_incoming_services_;
  std::string data_path_;
  fidl::Binding<fuchsia::sys::ComponentController> binding_;
  std::unique_ptr<sys::ComponentContext> context_;

  fdio_ns_t* namespace_ = nullptr;
  int stdoutfd_ = -1;
  int stderrfd_ = -1;
  MappedResource isolate_snapshot_data_;
  MappedResource isolate_snapshot_instructions_;
  MappedResource shared_snapshot_data_;
  MappedResource shared_snapshot_instructions_;
  std::vector<MappedResource> kernel_peices_;

  Dart_Isolate isolate_;
  int32_t return_code_ = 0;

  zx::time idle_start_{0};
  zx::timer idle_timer_;
  async::WaitMethod<DartComponentController,
                    &DartComponentController::OnIdleTimer>
      idle_wait_{this};

  // Disallow copy and assignment.
  DartComponentController(const DartComponentController&) = delete;
  DartComponentController& operator=(const DartComponentController&) = delete;
};

}  // namespace dart_runner

#endif  // TOPAZ_RUNTIME_DART_RUNNER_DART_COMPONENT_CONTROLLER_H_
