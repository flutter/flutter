// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "application.h"

#include <dlfcn.h>
#include <zircon/dlfcn.h>

#include <sstream>

#include "flutter/shell/common/switches.h"
#include "lib/fsl/vmo/file.h"
#include "lib/fsl/vmo/vector.h"
#include "lib/fxl/command_line.h"
#include "lib/fxl/synchronization/waitable_event.h"
#include "task_observers.h"

namespace flutter {

std::pair<std::unique_ptr<fsl::Thread>, std::unique_ptr<Application>>
Application::Create(
    TerminationCallback termination_callback,
    component::ApplicationPackage package,
    component::ApplicationStartupInfo startup_info,
    fidl::InterfaceRequest<component::ApplicationController> controller) {
  auto thread = std::make_unique<fsl::Thread>();
  std::unique_ptr<Application> application;

  fxl::AutoResetWaitableEvent latch;
  thread->TaskRunner()->PostTask([&]() mutable {
    application.reset(new Application(termination_callback,     //
                                      std::move(package),       //
                                      std::move(startup_info),  //
                                      std::move(controller)     //
                                      ));
    latch.Signal();
  });
  thread->Run();
  latch.Wait();
  return {std::move(thread), std::move(application)};
}

static std::string DebugLabelForURL(const std::string& url) {
  auto found = url.rfind("/");
  if (found == std::string::npos) {
    return url;
  } else {
    return {url, found + 1};
  }
}

Application::Application(
    TerminationCallback termination_callback,
    component::ApplicationPackage,
    component::ApplicationStartupInfo startup_info,
    fidl::InterfaceRequest<component::ApplicationController>
        application_controller_request)
    : termination_callback_(termination_callback),
      debug_label_(DebugLabelForURL(startup_info.launch_info.url)),
      application_controller_(this) {
  application_controller_.set_error_handler([this]() { Kill(); });

  FXL_DCHECK(fdio_ns_.is_valid());
  // ApplicationLaunchInfo::url non-optional.
  auto& launch_info = startup_info.launch_info;

  // ApplicationLaunchInfo::arguments optional.
  if (auto& arguments = launch_info.arguments) {
    settings_ = shell::SettingsFromCommandLine(
        fxl::CommandLineFromIterators(arguments->begin(), arguments->end()));
  }

  // TODO: ApplicationLaunchInfo::out.

  // TODO: ApplicationLaunchInfo::err.

  // ApplicationLaunchInfo::service_request optional.
  if (launch_info.directory_request) {
    service_provider_bridge_.ServeDirectory(
        std::move(launch_info.directory_request));
  }

  // ApplicationLaunchInfo::flat_namespace optional.
  for (size_t i = 0; i < startup_info.flat_namespace.paths->size(); ++i) {
    const auto& path = startup_info.flat_namespace.paths->at(i);
    if (path == "/svc") {
      continue;
    }

    zx::channel dir = std::move(startup_info.flat_namespace.directories->at(i));
    zx_handle_t dir_handle = dir.release();
    if (fdio_ns_bind(fdio_ns_.get(), path->data(), dir_handle) != ZX_OK) {
      FXL_DLOG(ERROR) << "Could not bind path to namespace: " << path;
      zx_handle_close(dir_handle);
    }
  }

  application_directory_.reset(fdio_ns_opendir(fdio_ns_.get()));
  FXL_DCHECK(application_directory_.is_valid());

  application_assets_directory_.reset(
      openat(application_directory_.get(), "pkg/data", O_RDONLY | O_DIRECTORY));

  // TODO: ApplicationLaunchInfo::additional_services optional.

  // All launch arguments have been read. Perform service binding and
  // final settings configuration. The next call will be to create a view
  // for this application.

  service_provider_bridge_.AddService<views_v1::ViewProvider>(
      std::bind(&Application::CreateShellForView, this, std::placeholders::_1));

  component::ServiceProviderPtr outgoing_services;
  outgoing_services_request_ = outgoing_services.NewRequest();
  service_provider_bridge_.set_backend(std::move(outgoing_services));

  // Setup the application controller binding.
  if (application_controller_request) {
    application_controller_.Bind(std::move(application_controller_request));
  }

  application_context_ =
      component::ApplicationContext::CreateFrom(std::move(startup_info));

  settings_.vm_snapshot_data_path = "pkg/data/vm_snapshot_data.bin";
  settings_.vm_snapshot_instr_path = "pkg/data/vm_snapshot_instructions.bin";
  settings_.isolate_snapshot_data_path =
      "pkg/data/isolate_core_snapshot_data.bin";
  settings_.isolate_snapshot_instr_path =
      "pkg/data/isolate_core_snapshot_instructions.bin";

  settings_.enable_observatory = true;

  settings_.icu_data_path = "";

  settings_.assets_dir = application_assets_directory_.get();

  settings_.script_snapshot_path = "snapshot_blob.bin";
  settings_.application_kernel_asset = "kernel_blob.dill";

  settings_.log_tag = debug_label_ + std::string{"(flutter)"};

#ifndef NDEBUG
  // Debug mode
  settings_.dart_non_checked_mode = false;
#else   // NDEBUG
  // Release mode
  settings_.dart_non_checked_mode = true;
#endif  // NDEBUG

  settings_.task_observer_add =
      std::bind(&CurrentMessageLoopAddAfterTaskObserver, std::placeholders::_1,
                std::placeholders::_2);

  settings_.task_observer_remove = std::bind(
      &CurrentMessageLoopRemoveAfterTaskObserver, std::placeholders::_1);

  AttemptVMLaunchWithCurrentSettings(settings_);
}

Application::~Application() = default;

const std::string& Application::GetDebugLabel() const {
  return debug_label_;
}

void Application::AttemptVMLaunchWithCurrentSettings(
    const blink::Settings& settings) {
  if (!blink::DartVM::IsRunningPrecompiledCode()) {
    // We will be initializing the VM lazily in this case.
    return;
  }

  fsl::SizedVmo dylib_vmo;

  if (!fsl::VmoFromFilenameAt(
          application_assets_directory_.get() /* /pkg/data */, "libapp.so",
          &dylib_vmo)) {
    FXL_LOG(ERROR) << "Dylib containing VM and isolate snapshots does not "
                      "exist. Will not be able to launch VM.";
    return;
  }

  dlerror();

  auto library_handle = dlopen_vmo(dylib_vmo.vmo().get(), RTLD_LAZY);

  if (library_handle == nullptr) {
    FXL_LOG(ERROR) << "Could not open dylib: " << dlerror();
    return;
  }

  auto lib =
      fml::NativeLibrary::CreateWithHandle(library_handle,  // library handle
                                           true  // close the handle when done
      );

  auto symbol = [](const char* str) {
    return std::string{"_"} + std::string{str};
  };

  fxl::RefPtr<blink::DartSnapshot> vm_snapshot =
      fxl::MakeRefCounted<blink::DartSnapshot>(
          blink::DartSnapshotBuffer::CreateWithSymbolInLibrary(
              lib, symbol(blink::DartSnapshot::kVMDataSymbol).c_str()),
          blink::DartSnapshotBuffer::CreateWithSymbolInLibrary(
              lib, symbol(blink::DartSnapshot::kVMInstructionsSymbol).c_str()));

  isolate_snapshot_ = fxl::MakeRefCounted<blink::DartSnapshot>(
      blink::DartSnapshotBuffer::CreateWithSymbolInLibrary(
          lib, symbol(blink::DartSnapshot::kIsolateDataSymbol).c_str()),
      blink::DartSnapshotBuffer::CreateWithSymbolInLibrary(
          lib,
          symbol(blink::DartSnapshot::kIsolateInstructionsSymbol).c_str()));

  blink::DartVM::ForProcess(settings_,               //
                            std::move(vm_snapshot),  //
                            isolate_snapshot_        //
  );
  if (blink::DartVM::ForProcessIfInitialized()) {
    FXL_DLOG(INFO) << "VM successfully initialized for AOT mode.";
  } else {
    FXL_LOG(ERROR) << "VM could not be initialized for AOT mode.";
  }
}

// |component::ApplicationController|
void Application::Kill() {
  if (last_return_code_.first) {
    for (auto wait_callback : wait_callbacks_) {
      wait_callback(last_return_code_.second);
    }
  }
  wait_callbacks_.clear();

  termination_callback_(this);
  // WARNING: Don't do anything past this point as this instance may have been
  // collected.
}

// |component::ApplicationController|
void Application::Detach() {
  application_controller_.set_error_handler(nullptr);
}

// |component::ApplicationController|
void Application::Wait(WaitCallback callback) {
  wait_callbacks_.emplace_back(std::move(callback));
}

// |flutter::Engine::Delegate|
void Application::OnEngineTerminate(const Engine* shell_holder) {
  auto found = std::find_if(shell_holders_.begin(), shell_holders_.end(),
                            [shell_holder](const auto& holder) {
                              return holder.get() == shell_holder;
                            });

  if (found == shell_holders_.end()) {
    return;
  }

  // We may launch multiple shell in this application. However, we will
  // terminate when the last shell goes away. The error code return to the
  // application controller will be the last isolate that had an error.
  auto return_code = shell_holder->GetEngineReturnCode();
  if (return_code.first) {
    last_return_code_ = return_code;
  }

  shell_holders_.erase(found);

  if (shell_holders_.size() == 0) {
    Kill();
    // WARNING: Don't do anything past this point because the delegate may have
    // collected this instance via the termination callback.
  }
}

void Application::CreateShellForView(
    fidl::InterfaceRequest<views_v1::ViewProvider> view_provider_request) {
  shells_bindings_.AddBinding(this, std::move(view_provider_request));
}

// |views_v1::ViewProvider|
void Application::CreateView(
    fidl::InterfaceRequest<views_v1_token::ViewOwner> view_owner,
    fidl::InterfaceRequest<component::ServiceProvider>) {
  if (!application_context_) {
    FXL_DLOG(ERROR) << "Application context was invalid when attempting to "
                       "create a shell for a view provider request.";
    return;
  }

  shell_holders_.emplace(std::make_unique<Engine>(
      *this,                                 // delegate
      debug_label_,                          // thread label
      *application_context_,                 // application context
      settings_,                             // settings
      std::move(isolate_snapshot_),          // isolate snapshot
      std::move(view_owner),                 // view owner
      std::move(fdio_ns_),                   // FDIO namespace
      std::move(outgoing_services_request_)  // outgoing request
      ));
}

}  // namespace flutter
