// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "component_v1.h"

#include <dlfcn.h>
#include <fuchsia/mem/cpp/fidl.h>
#include <lib/async-loop/cpp/loop.h>
#include <lib/async/cpp/task.h>
#include <lib/async/default.h>
#include <lib/fdio/directory.h>
#include <lib/fdio/io.h>
#include <lib/fdio/namespace.h>
#include <lib/ui/scenic/cpp/view_ref_pair.h>
#include <lib/ui/scenic/cpp/view_token_pair.h>
#include <lib/vfs/cpp/composed_service_dir.h>
#include <lib/vfs/cpp/remote_dir.h>
#include <lib/vfs/cpp/service.h>
#include <sys/stat.h>
#include <zircon/dlfcn.h>
#include <zircon/status.h>
#include <zircon/types.h>

#include <memory>
#include <regex>
#include <sstream>

#include "file_in_namespace_buffer.h"
#include "flutter/fml/mapping.h"
#include "flutter/fml/platform/fuchsia/task_observers.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/unique_fd.h"
#include "flutter/runtime/dart_vm_lifecycle.h"
#include "flutter/shell/common/switches.h"
#include "runtime/dart/utils/files.h"
#include "runtime/dart/utils/handle_exception.h"
#include "runtime/dart/utils/mapped_resource.h"
#include "runtime/dart/utils/tempfs.h"
#include "runtime/dart/utils/vmo.h"

namespace flutter_runner {
namespace {

constexpr char kDataKey[] = "data";
constexpr char kAssetsKey[] = "assets";
constexpr char kOldGenHeapSizeKey[] = "old_gen_heap_size";

constexpr char kTmpPath[] = "/tmp";
constexpr char kServiceRootPath[] = "/svc";
constexpr char kRunnerConfigPath[] = "/config/data/flutter_runner_config";

std::string DebugLabelForUrl(const std::string& url) {
  auto found = url.rfind("/");
  if (found == std::string::npos) {
    return url;
  } else {
    return {url, found + 1};
  }
}

}  // namespace

ProgramMetadata ComponentV1::ParseProgramMetadata(
    const fidl::VectorPtr<fuchsia::sys::ProgramMetadata>& program_metadata) {
  ProgramMetadata result;
  if (!program_metadata.has_value()) {
    return result;
  }

  for (const auto& pg : *program_metadata) {
    if (pg.key.compare(kDataKey) == 0) {
      result.data_path = "pkg/" + pg.value;
    } else if (pg.key.compare(kAssetsKey) == 0) {
      result.assets_path = "pkg/" + pg.value;
    } else if (pg.key.compare(kOldGenHeapSizeKey) == 0) {
      int64_t specified_old_gen_heap_size =
          strtol(pg.value.c_str(), nullptr /* endptr */, 10 /* base */);
      if (specified_old_gen_heap_size != 0) {
        result.old_gen_heap_size = specified_old_gen_heap_size;
      } else {
        FML_LOG(ERROR) << "Invalid old_gen_heap_size: " << pg.value;
      }
    }
  }

  // assets_path defaults to the same as data_path if omitted.
  if (result.assets_path.empty()) {
    result.assets_path = result.data_path;
  }

  return result;
}

ActiveComponentV1 ComponentV1::Create(
    TerminationCallback termination_callback,
    fuchsia::sys::Package package,
    fuchsia::sys::StartupInfo startup_info,
    std::shared_ptr<sys::ServiceDirectory> runner_incoming_services,
    fidl::InterfaceRequest<fuchsia::sys::ComponentController> controller) {
  auto thread = std::make_unique<fml::Thread>();
  std::unique_ptr<ComponentV1> component;

  fml::AutoResetWaitableEvent latch;
  thread->GetTaskRunner()->PostTask([&]() mutable {
    component.reset(new ComponentV1(std::move(termination_callback),
                                    std::move(package), std::move(startup_info),
                                    runner_incoming_services,
                                    std::move(controller)));
    latch.Signal();
  });

  latch.Wait();
  return {.platform_thread = std::move(thread),
          .component = std::move(component)};
}

ComponentV1::ComponentV1(
    TerminationCallback termination_callback,
    fuchsia::sys::Package package,
    fuchsia::sys::StartupInfo startup_info,
    std::shared_ptr<sys::ServiceDirectory> runner_incoming_services,
    fidl::InterfaceRequest<fuchsia::sys::ComponentController>
        component_controller_request)
    : termination_callback_(std::move(termination_callback)),
      debug_label_(DebugLabelForUrl(startup_info.launch_info.url)),
      component_controller_(this),
      outgoing_dir_(new vfs::PseudoDir()),
      runner_incoming_services_(runner_incoming_services),
      weak_factory_(this) {
  component_controller_.set_error_handler(
      [this](zx_status_t status) { Kill(); });

  FML_DCHECK(fdio_ns_.is_valid());
  // LaunchInfo::url non-optional.
  auto& launch_info = startup_info.launch_info;

  // LaunchInfo::arguments optional.
  if (auto& arguments = launch_info.arguments) {
    dart_entrypoint_args_ = arguments.value();
  }

  const ProgramMetadata metadata =
      ParseProgramMetadata(startup_info.program_metadata);

  if (metadata.data_path.empty()) {
    FML_LOG(ERROR) << "Could not find a /pkg/data directory for "
                   << package.resolved_url;
    return;
  }

  // Setup /tmp to be mapped to the process-local memfs.
  dart_utils::RunnerTemp::SetupComponent(fdio_ns_.get());

  // LaunchInfo::flat_namespace optional.
  for (size_t i = 0; i < startup_info.flat_namespace.paths.size(); ++i) {
    const auto& path = startup_info.flat_namespace.paths.at(i);
    if (path == kTmpPath) {
      continue;
    }

    zx::channel dir;
    if (path == kServiceRootPath) {
      svc_ = std::make_unique<sys::ServiceDirectory>(
          std::move(startup_info.flat_namespace.directories.at(i)));
      dir = svc_->CloneChannel().TakeChannel();
    } else {
      dir = std::move(startup_info.flat_namespace.directories.at(i));
    }

    zx_handle_t dir_handle = dir.release();
    if (fdio_ns_bind(fdio_ns_.get(), path.data(), dir_handle) != ZX_OK) {
      FML_LOG(ERROR) << "Could not bind path to namespace: " << path;
      zx_handle_close(dir_handle);
    }
  }

  {
    fml::UniqueFD ns_fd(fdio_ns_opendir(fdio_ns_.get()));
    FML_DCHECK(ns_fd.is_valid());

    constexpr mode_t mode = O_RDONLY | O_DIRECTORY;

    component_assets_directory_.reset(
        openat(ns_fd.get(), metadata.assets_path.c_str(), mode));
    FML_DCHECK(component_assets_directory_.is_valid());

    component_data_directory_.reset(
        openat(ns_fd.get(), metadata.data_path.c_str(), mode));
    FML_DCHECK(component_data_directory_.is_valid());
  }

  // TODO: LaunchInfo::out.

  // TODO: LaunchInfo::err.

  // LaunchInfo::service_request optional.
  if (launch_info.directory_request) {
    outgoing_dir_->Serve(fuchsia::io::OpenFlags::RIGHT_READABLE |
                             fuchsia::io::OpenFlags::RIGHT_WRITABLE |
                             fuchsia::io::OpenFlags::DIRECTORY,
                         std::move(launch_info.directory_request));
  }

  directory_request_ = directory_ptr_.NewRequest();

  fuchsia::io::DirectoryHandle flutter_public_dir;
  // TODO(anmittal): when fixing enumeration using new c++ vfs, make sure that
  // flutter_public_dir is only accessed once we receive OnOpen Event.
  // That will prevent FL-175 for public directory
  auto request = flutter_public_dir.NewRequest().TakeChannel();
  fdio_service_connect_at(directory_ptr_.channel().get(), "svc",
                          request.release());

  auto composed_service_dir = std::make_unique<vfs::ComposedServiceDir>();
  composed_service_dir->set_fallback(std::move(flutter_public_dir));

  // Clone and check if client is servicing the directory.
  directory_ptr_->Clone(fuchsia::io::OpenFlags::DESCRIBE |
                            fuchsia::io::OpenFlags::RIGHT_READABLE |
                            fuchsia::io::OpenFlags::RIGHT_WRITABLE,
                        cloned_directory_ptr_.NewRequest());

  cloned_directory_ptr_.events().OnOpen =
      [this](zx_status_t status, std::unique_ptr<fuchsia::io::NodeInfo> info) {
        cloned_directory_ptr_.Unbind();
        if (status != ZX_OK) {
          FML_LOG(ERROR)
              << "could not bind out directory for flutter component("
              << debug_label_ << "): " << zx_status_get_string(status);
          return;
        }
        const char* other_dirs[] = {"debug", "ctrl", "diagnostics"};
        // add other directories as RemoteDirs.
        for (auto& dir_str : other_dirs) {
          fuchsia::io::DirectoryHandle dir;
          auto request = dir.NewRequest().TakeChannel();
          auto status = fdio_service_connect_at(directory_ptr_.channel().get(),
                                                dir_str, request.release());
          if (status == ZX_OK) {
            outgoing_dir_->AddEntry(
                dir_str, std::make_unique<vfs::RemoteDir>(dir.TakeChannel()));
          } else {
            FML_LOG(ERROR) << "could not add out directory entry(" << dir_str
                           << ") for flutter component(" << debug_label_
                           << "): " << zx_status_get_string(status);
          }
        }
      };

  cloned_directory_ptr_.set_error_handler(
      [this](zx_status_t status) { cloned_directory_ptr_.Unbind(); });

  // TODO: LaunchInfo::additional_services optional.

  // All launch arguments have been read. Perform service binding and
  // final settings configuration. The next call will be to create a view
  // for this component.
  composed_service_dir->AddService(
      fuchsia::ui::app::ViewProvider::Name_,
      std::make_unique<vfs::Service>(
          [this](zx::channel channel, async_dispatcher_t* dispatcher) {
            shells_bindings_.AddBinding(
                this, fidl::InterfaceRequest<fuchsia::ui::app::ViewProvider>(
                          std::move(channel)));
          }));

  outgoing_dir_->AddEntry("svc", std::move(composed_service_dir));

  // Setup the component controller binding.
  if (component_controller_request) {
    component_controller_.Bind(std::move(component_controller_request));
  }

  // Load and use runner-specific configuration, if it exists.
  std::string json_string;
  if (dart_utils::ReadFileToString(kRunnerConfigPath, &json_string)) {
    product_config_ = FlutterRunnerProductConfiguration(json_string);
    FML_LOG(INFO) << "Successfully loaded runner configuration: "
                  << json_string;
  } else {
    FML_LOG(WARNING) << "Failed to load runner configuration from "
                     << kRunnerConfigPath << "; using default config values.";
  }

  // Load VM and component bytecode.
  // For AOT, compare with flutter_aot_app in flutter_app.gni.
  // For JIT, compare flutter_jit_runner in BUILD.gn.
  if (flutter::DartVM::IsRunningPrecompiledCode()) {
    std::shared_ptr<dart_utils::ElfSnapshot> snapshot =
        std::make_shared<dart_utils::ElfSnapshot>();
    if (snapshot->Load(component_data_directory_.get(),
                       "app_aot_snapshot.so")) {
      const uint8_t* isolate_data = snapshot->IsolateData();
      const uint8_t* isolate_instructions = snapshot->IsolateInstrs();
      const uint8_t* vm_data = snapshot->VmData();
      const uint8_t* vm_instructions = snapshot->VmInstrs();
      if (isolate_data == nullptr || isolate_instructions == nullptr ||
          vm_data == nullptr || vm_instructions == nullptr) {
        FML_LOG(FATAL) << "ELF snapshot missing AOT symbols.";
        return;
      }
      auto hold_snapshot = [snapshot](const uint8_t* _, size_t __) {};
      settings_.vm_snapshot_data = [hold_snapshot, vm_data]() {
        return std::make_unique<fml::NonOwnedMapping>(vm_data, 0, hold_snapshot,
                                                      true /* dontneed_safe */);
      };
      settings_.vm_snapshot_instr = [hold_snapshot, vm_instructions]() {
        return std::make_unique<fml::NonOwnedMapping>(
            vm_instructions, 0, hold_snapshot, true /* dontneed_safe */);
      };
      settings_.isolate_snapshot_data = [hold_snapshot, isolate_data]() {
        return std::make_unique<fml::NonOwnedMapping>(
            isolate_data, 0, hold_snapshot, true /* dontneed_safe */);
      };
      settings_.isolate_snapshot_instr = [hold_snapshot,
                                          isolate_instructions]() {
        return std::make_unique<fml::NonOwnedMapping>(
            isolate_instructions, 0, hold_snapshot, true /* dontneed_safe */);
      };
      isolate_snapshot_ = fml::MakeRefCounted<flutter::DartSnapshot>(
          std::make_shared<fml::NonOwnedMapping>(isolate_data, 0, hold_snapshot,
                                                 true /* dontneed_safe */),
          std::make_shared<fml::NonOwnedMapping>(isolate_instructions, 0,
                                                 hold_snapshot,
                                                 true /* dontneed_safe */));
    } else {
      const int namespace_fd = component_data_directory_.get();
      settings_.vm_snapshot_data = [namespace_fd]() {
        return LoadFile(namespace_fd, "vm_snapshot_data.bin",
                        false /* executable */);
      };
      settings_.vm_snapshot_instr = [namespace_fd]() {
        return LoadFile(namespace_fd, "vm_snapshot_instructions.bin",
                        true /* executable */);
      };
      settings_.isolate_snapshot_data = [namespace_fd]() {
        return LoadFile(namespace_fd, "isolate_snapshot_data.bin",
                        false /* executable */);
      };
      settings_.isolate_snapshot_instr = [namespace_fd]() {
        return LoadFile(namespace_fd, "isolate_snapshot_instructions.bin",
                        true /* executable */);
      };
    }
  } else {
    settings_.vm_snapshot_data = []() {
      return MakeFileMapping("/pkg/data/vm_snapshot_data.bin",
                             false /* executable */);
    };
    settings_.vm_snapshot_instr = []() {
      return MakeFileMapping("/pkg/data/vm_snapshot_instructions.bin",
                             true /* executable */);
    };

    settings_.isolate_snapshot_data = []() {
      return MakeFileMapping("/pkg/data/isolate_core_snapshot_data.bin",
                             false /* executable */);
    };
    settings_.isolate_snapshot_instr = [] {
      return MakeFileMapping("/pkg/data/isolate_core_snapshot_instructions.bin",
                             true /* executable */);
    };
  }

#if defined(DART_PRODUCT)
  settings_.enable_observatory = false;
#else
  settings_.enable_observatory = true;

  // TODO(cbracken): pass this in as a param to allow 0.0.0.0, ::1, etc.
  settings_.observatory_host = "127.0.0.1";
#endif

  // Controls whether category "skia" trace events are enabled.
  settings_.trace_skia = true;

  settings_.verbose_logging = true;

  settings_.advisory_script_uri = debug_label_;

  settings_.advisory_script_entrypoint = debug_label_;

  settings_.icu_data_path = "";

  settings_.assets_dir = component_assets_directory_.get();

  // Compare flutter_jit_app in flutter_app.gni.
  settings_.application_kernel_list_asset = "app.dilplist";

  settings_.log_tag = debug_label_ + std::string{"(flutter)"};

  if (metadata.old_gen_heap_size.has_value()) {
    settings_.old_gen_heap_size = *metadata.old_gen_heap_size;
  }

  // No asserts in debug or release product.
  // No asserts in release with flutter_profile=true (non-product)
  // Yes asserts in non-product debug.
#if !defined(DART_PRODUCT) && (!defined(FLUTTER_PROFILE) || !defined(NDEBUG))
  // Debug mode
  settings_.disable_dart_asserts = false;
#else
  // Release mode
  settings_.disable_dart_asserts = true;
#endif

  // Do not leak the VM; allow it to shut down normally when the last shell
  // terminates.
  settings_.leak_vm = false;

  settings_.task_observer_add =
      std::bind(&fml::CurrentMessageLoopAddAfterTaskObserver,
                std::placeholders::_1, std::placeholders::_2);

  settings_.task_observer_remove = std::bind(
      &fml::CurrentMessageLoopRemoveAfterTaskObserver, std::placeholders::_1);

  settings_.log_message_callback = [](const std::string& tag,
                                      const std::string& message) {
    if (!tag.empty()) {
      std::cout << tag << ": ";
    }
    std::cout << message << std::endl;
  };

  settings_.dart_flags = {};

  // Don't collect CPU samples from Dart VM C++ code.
  settings_.dart_flags.push_back("--no_profile_vm");

  // Scale back CPU profiler sampling period on ARM64 to avoid overloading
  // the tracing engine.
#if defined(__aarch64__)
  settings_.dart_flags.push_back("--profile_period=10000");
#endif  // defined(__aarch64__)

  auto platform_task_runner = fml::MessageLoop::GetCurrent().GetTaskRunner();
  const std::string component_url = package.resolved_url;
  settings_.unhandled_exception_callback = [weak = weak_factory_.GetWeakPtr(),
                                            platform_task_runner,
                                            runner_incoming_services,
                                            component_url](
                                               const std::string& error,
                                               const std::string& stack_trace) {
    if (weak) {
      // TODO(cbracken): unsafe. The above check and the PostTask below are
      // happening on the UI thread. If the Component dtor and thread
      // termination happen (on the platform thread) between the previous
      // line and the next line, a crash will occur since we'll be posting
      // to a dead thread. See Runner::OnComponentV1Terminate() in
      // runner.cc.
      platform_task_runner->PostTask([weak, runner_incoming_services,
                                      component_url, error, stack_trace]() {
        if (weak) {
          dart_utils::HandleException(runner_incoming_services, component_url,
                                      error, stack_trace);
        } else {
          FML_LOG(WARNING)
              << "Exception was thrown which was not caught in Flutter app: "
              << error;
        }
      });
    } else {
      FML_LOG(WARNING)
          << "Exception was thrown which was not caught in Flutter app: "
          << error;
    }
    // Ideally we would return whether HandleException returned ZX_OK, but
    // short of knowing if the exception was correctly handled, we return
    // false to have the error and stack trace printed in the logs.
    return false;
  };
}

ComponentV1::~ComponentV1() = default;

const std::string& ComponentV1::GetDebugLabel() const {
  return debug_label_;
}

void ComponentV1::Kill() {
  component_controller_.events().OnTerminated(
      last_return_code_.second, fuchsia::sys::TerminationReason::EXITED);

  termination_callback_(this);
  // WARNING: Don't do anything past this point as this instance may have been
  // collected.
}

void ComponentV1::Detach() {
  component_controller_.set_error_handler(nullptr);
}

void ComponentV1::OnEngineTerminate(const Engine* shell_holder) {
  auto found = std::find_if(shell_holders_.begin(), shell_holders_.end(),
                            [shell_holder](const auto& holder) {
                              return holder.get() == shell_holder;
                            });

  if (found == shell_holders_.end()) {
    // This indicates a deeper issue with memory management and should never
    // happen.
    FML_LOG(ERROR) << "Tried to terminate an unregistered shell holder.";
    FML_DCHECK(false);

    return;
  }

  // We may launch multiple shell in this component. However, we will
  // terminate when the last shell goes away. The error code return to the
  // component controller will be the last isolate that had an error.
  auto return_code = shell_holder->GetEngineReturnCode();
  if (return_code.has_value()) {
    last_return_code_ = {true, return_code.value()};
  } else {
    FML_LOG(ERROR) << "Failed to get return code from terminated shell holder.";
  }

  shell_holders_.erase(found);

  if (shell_holders_.empty()) {
    FML_VLOG(-1) << "Killing component because all shell holders have been "
                    "terminated.";
    Kill();
    // WARNING: Don't do anything past this point because the delegate may have
    // collected this instance via the termination callback.
  }
}

void ComponentV1::CreateView(
    zx::eventpair token,
    fidl::InterfaceRequest<fuchsia::sys::ServiceProvider> /*incoming_services*/,
    fidl::InterfaceHandle<
        fuchsia::sys::ServiceProvider> /*outgoing_services*/) {
  auto view_ref_pair = scenic::ViewRefPair::New();
  CreateViewWithViewRef(std::move(token), std::move(view_ref_pair.control_ref),
                        std::move(view_ref_pair.view_ref));
}

void ComponentV1::CreateViewWithViewRef(
    zx::eventpair view_token,
    fuchsia::ui::views::ViewRefControl control_ref,
    fuchsia::ui::views::ViewRef view_ref) {
  if (!svc_) {
    FML_LOG(ERROR)
        << "Component incoming services was invalid when attempting to "
           "create a shell for a view provider request.";
    return;
  }

  shell_holders_.emplace(std::make_unique<Engine>(
      *this,                      // delegate
      debug_label_,               // thread label
      svc_,                       // Component incoming services
      runner_incoming_services_,  // Runner incoming services
      settings_,                  // settings
      scenic::ToViewToken(std::move(view_token)),  // view token
      scenic::ViewRefPair{
          .control_ref = std::move(control_ref),
          .view_ref = std::move(view_ref),
      },
      std::move(fdio_ns_),            // FDIO namespace
      std::move(directory_request_),  // outgoing request
      product_config_,                // product configuration
      dart_entrypoint_args_,          // dart entrypoint args
      true                            // v1 component
      ));
}

void ComponentV1::CreateView2(fuchsia::ui::app::CreateView2Args view_args) {
  if (!svc_) {
    FML_LOG(ERROR)
        << "Component incoming services was invalid when attempting to "
           "create a shell for a view provider request.";
    return;
  }

  shell_holders_.emplace(std::make_unique<Engine>(
      *this,                      // delegate
      debug_label_,               // thread label
      svc_,                       // Component incoming services
      runner_incoming_services_,  // Runner incoming services
      settings_,                  // settings
      std::move(
          *view_args.mutable_view_creation_token()),  // view creation token
      scenic::ViewRefPair::New(),                     // view ref pair
      std::move(fdio_ns_),                            // FDIO namespace
      std::move(directory_request_),                  // outgoing request
      product_config_,                                // product configuration
      dart_entrypoint_args_,                          // dart entrypoint args
      true                                            // v1 component
      ));
}

#if !defined(DART_PRODUCT)
void ComponentV1::WriteProfileToTrace() const {
  for (const auto& engine : shell_holders_) {
    engine->WriteProfileToTrace();
  }
}
#endif  // !defined(DART_PRODUCT)

}  // namespace flutter_runner
