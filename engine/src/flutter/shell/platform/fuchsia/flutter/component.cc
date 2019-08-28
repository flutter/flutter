// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "component.h"

#include <dlfcn.h>
#include <fuchsia/mem/cpp/fidl.h>
#include <lib/async-loop/cpp/loop.h>
#include <lib/async/cpp/task.h>
#include <lib/fdio/directory.h>
#include <lib/fdio/namespace.h>
#include <lib/ui/scenic/cpp/view_token_pair.h>
#include <lib/vfs/cpp/remote_dir.h>
#include <lib/vfs/cpp/service.h>
#include <sys/stat.h>
#include <zircon/dlfcn.h>
#include <zircon/status.h>
#include <regex>
#include <sstream>

#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/runtime/dart_vm_lifecycle.h"
#include "flutter/shell/common/switches.h"
#include "runtime/dart/utils/files.h"
#include "runtime/dart/utils/handle_exception.h"
#include "runtime/dart/utils/tempfs.h"
#include "runtime/dart/utils/vmo.h"

#include "service_provider_dir.h"
#include "task_observers.h"
#include "task_runner_adapter.h"
#include "thread.h"

namespace flutter_runner {

constexpr char kDataKey[] = "data";
constexpr char kTmpPath[] = "/tmp";
constexpr char kServiceRootPath[] = "/svc";

std::pair<std::unique_ptr<Thread>, std::unique_ptr<Application>>
Application::Create(
    TerminationCallback termination_callback,
    fuchsia::sys::Package package,
    fuchsia::sys::StartupInfo startup_info,
    std::shared_ptr<sys::ServiceDirectory> runner_incoming_services,
    fidl::InterfaceRequest<fuchsia::sys::ComponentController> controller) {
  std::unique_ptr<Thread> thread = std::make_unique<Thread>();
  std::unique_ptr<Application> application;

  fml::AutoResetWaitableEvent latch;
  async::PostTask(thread->dispatcher(), [&]() mutable {
    application.reset(
        new Application(std::move(termination_callback), std::move(package),
                        std::move(startup_info), runner_incoming_services,
                        std::move(controller)));
    latch.Signal();
  });

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
    fuchsia::sys::Package package,
    fuchsia::sys::StartupInfo startup_info,
    std::shared_ptr<sys::ServiceDirectory> runner_incoming_services,
    fidl::InterfaceRequest<fuchsia::sys::ComponentController>
        application_controller_request)
    : termination_callback_(std::move(termination_callback)),
      debug_label_(DebugLabelForURL(startup_info.launch_info.url)),
      application_controller_(this),
      outgoing_dir_(new vfs::PseudoDir()),
      runner_incoming_services_(runner_incoming_services),
      weak_factory_(this) {
  application_controller_.set_error_handler(
      [this](zx_status_t status) { Kill(); });

  FML_DCHECK(fdio_ns_.is_valid());
  // LaunchInfo::url non-optional.
  auto& launch_info = startup_info.launch_info;

  // LaunchInfo::arguments optional.
  if (auto& arguments = launch_info.arguments) {
    settings_ = flutter::SettingsFromCommandLine(fml::CommandLineFromIterators(
        arguments.value().begin(), arguments.value().end()));
  }

  // Determine /pkg/data directory from StartupInfo.
  std::string data_path;
  for (size_t i = 0; i < startup_info.program_metadata->size(); ++i) {
    auto pg = startup_info.program_metadata->at(i);
    if (pg.key.compare(kDataKey) == 0) {
      data_path = "pkg/" + pg.value;
    }
  }
  if (data_path.empty()) {
    FML_DLOG(ERROR) << "Could not find a /pkg/data directory for "
                    << package.resolved_url;
    return;
  }

  // Setup /tmp to be mapped to the process-local memfs.
  dart_utils::SetupComponentTemp(fdio_ns_.get());

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
      FML_DLOG(ERROR) << "Could not bind path to namespace: " << path;
      zx_handle_close(dir_handle);
    }
  }

  application_directory_.reset(fdio_ns_opendir(fdio_ns_.get()));
  FML_DCHECK(application_directory_.is_valid());

  application_assets_directory_.reset(openat(
      application_directory_.get(), data_path.c_str(), O_RDONLY | O_DIRECTORY));

  // TODO: LaunchInfo::out.

  // TODO: LaunchInfo::err.

  // LaunchInfo::service_request optional.
  if (launch_info.directory_request) {
    outgoing_dir_->Serve(fuchsia::io::OPEN_RIGHT_READABLE |
                             fuchsia::io::OPEN_RIGHT_WRITABLE |
                             fuchsia::io::OPEN_FLAG_DIRECTORY,
                         std::move(launch_info.directory_request));
  }

  directory_request_ = directory_ptr_.NewRequest();

  fidl::InterfaceHandle<fuchsia::io::Directory> flutter_public_dir;
  // TODO(anmittal): when fixing enumeration using new c++ vfs, make sure that
  // flutter_public_dir is only accessed once we receive OnOpen Event.
  // That will prevent FL-175 for public directory
  auto request = flutter_public_dir.NewRequest().TakeChannel();
  fdio_service_connect_at(directory_ptr_.channel().get(), "svc",
                          request.release());

  auto service_provider_dir = std::make_unique<ServiceProviderDir>();
  service_provider_dir->set_fallback(std::move(flutter_public_dir));

  // Clone and check if client is servicing the directory.
  directory_ptr_->Clone(fuchsia::io::OPEN_FLAG_DESCRIBE |
                            fuchsia::io::OPEN_RIGHT_READABLE |
                            fuchsia::io::OPEN_RIGHT_WRITABLE,
                        cloned_directory_ptr_.NewRequest());

  cloned_directory_ptr_.events().OnOpen =
      [this](zx_status_t status, std::unique_ptr<fuchsia::io::NodeInfo> info) {
        cloned_directory_ptr_.Unbind();
        if (status != ZX_OK) {
          FML_LOG(ERROR) << "could not bind out directory for flutter app("
                         << debug_label_
                         << "): " << zx_status_get_string(status);
          return;
        }
        const char* other_dirs[] = {"debug", "ctrl"};
        // add other directories as RemoteDirs.
        for (auto& dir_str : other_dirs) {
          fidl::InterfaceHandle<fuchsia::io::Directory> dir;
          auto request = dir.NewRequest().TakeChannel();
          fdio_service_connect_at(directory_ptr_.channel().get(), dir_str,
                                  request.release());
          outgoing_dir_->AddEntry(
              dir_str, std::make_unique<vfs::RemoteDir>(dir.TakeChannel()));
        }
      };

  cloned_directory_ptr_.set_error_handler(
      [this](zx_status_t status) { cloned_directory_ptr_.Unbind(); });

  // TODO: LaunchInfo::additional_services optional.

  // All launch arguments have been read. Perform service binding and
  // final settings configuration. The next call will be to create a view
  // for this application.
  service_provider_dir->AddService(
      fuchsia::ui::app::ViewProvider::Name_,
      std::make_unique<vfs::Service>(
          [this](zx::channel channel, async_dispatcher_t* dispatcher) {
            shells_bindings_.AddBinding(
                this, fidl::InterfaceRequest<fuchsia::ui::app::ViewProvider>(
                          std::move(channel)));
          }));

  outgoing_dir_->AddEntry("svc", std::move(service_provider_dir));

  // Setup the application controller binding.
  if (application_controller_request) {
    application_controller_.Bind(std::move(application_controller_request));
  }

  // Compare flutter_jit_runner in BUILD.gn.
  settings_.vm_snapshot_data_path = "pkg/data/vm_snapshot_data.bin";
  settings_.vm_snapshot_instr_path = "pkg/data/vm_snapshot_instructions.bin";
  settings_.isolate_snapshot_data_path =
      "pkg/data/isolate_core_snapshot_data.bin";
  settings_.isolate_snapshot_instr_path =
      "pkg/data/isolate_core_snapshot_instructions.bin";

  {
    // Check if we can use the snapshot with the framework already loaded.
    std::string runner_framework;
    std::string app_framework;
    if (dart_utils::ReadFileToString("pkg/data/runner.frameworkversion",
                                     &runner_framework) &&
        dart_utils::ReadFileToStringAt(application_assets_directory_.get(),
                                       "app.frameworkversion",
                                       &app_framework) &&
        (runner_framework.compare(app_framework) == 0)) {
      settings_.vm_snapshot_data_path =
          "pkg/data/framework_vm_snapshot_data.bin";
      settings_.vm_snapshot_instr_path =
          "pkg/data/framework_vm_snapshot_instructions.bin";
      settings_.isolate_snapshot_data_path =
          "pkg/data/framework_isolate_core_snapshot_data.bin";
      settings_.isolate_snapshot_instr_path =
          "pkg/data/framework_isolate_core_snapshot_instructions.bin";

      FML_LOG(INFO) << "Using snapshot with framework for "
                    << package.resolved_url;
    } else {
      FML_LOG(INFO) << "Using snapshot without framework for "
                    << package.resolved_url;
    }
  }

#if defined(DART_PRODUCT)
  settings_.enable_observatory = false;
#else
  settings_.enable_observatory = true;

  // TODO(cbracken): pass this in as a param to allow 0.0.0.0, ::1, etc.
  settings_.observatory_host = "127.0.0.1";
#endif

  settings_.icu_data_path = "";

  settings_.assets_dir = application_assets_directory_.get();

  // Compare flutter_jit_app in flutter_app.gni.
  settings_.application_kernel_list_asset = "app.dilplist";

  settings_.log_tag = debug_label_ + std::string{"(flutter)"};

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

  settings_.task_observer_add =
      std::bind(&CurrentMessageLoopAddAfterTaskObserver, std::placeholders::_1,
                std::placeholders::_2);

  settings_.task_observer_remove = std::bind(
      &CurrentMessageLoopRemoveAfterTaskObserver, std::placeholders::_1);

  // TODO(FL-117): Re-enable causal async stack traces when this issue is
  // addressed.
  settings_.dart_flags = {"--no_causal_async_stacks"};

  // Disable code collection as it interferes with JIT code warmup
  // by decreasing usage counters and flushing code which is still useful.
  settings_.dart_flags.push_back("--no-collect_code");

  if (!flutter::DartVM::IsRunningPrecompiledCode()) {
    // The interpreter is enabled unconditionally in JIT mode. If an app is
    // built for debugging (that is, with no bytecode), the VM will fall back on
    // ASTs.
    settings_.dart_flags.push_back("--enable_interpreter");
  }

  // Don't collect CPU samples from Dart VM C++ code.
  settings_.dart_flags.push_back("--no_profile_vm");

  // Scale back CPU profiler sampling period on ARM64 to avoid overloading
  // the tracing engine.
#if defined(__aarch64__)
  settings_.dart_flags.push_back("--profile_period=10000");
#endif  // defined(__aarch64__)

  auto weak_application = weak_factory_.GetWeakPtr();
  auto platform_task_runner =
      CreateFMLTaskRunner(async_get_default_dispatcher());
  const std::string component_url = package.resolved_url;
  settings_.unhandled_exception_callback =
      [weak_application, platform_task_runner, runner_incoming_services,
       component_url](const std::string& error,
                      const std::string& stack_trace) {
        if (weak_application) {
          // TODO(cbracken): unsafe. The above check and the PostTask below are
          // happening on the UI thread. If the Application dtor and thread
          // termination happen (on the platform thread) between the previous
          // line and the next line, a crash will occur since we'll be posting
          // to a dead thread. See Runner::OnApplicationTerminate() in
          // runner.cc.
          platform_task_runner->PostTask([weak_application,
                                          runner_incoming_services,
                                          component_url, error, stack_trace]() {
            if (weak_application) {
              dart_utils::HandleException(runner_incoming_services,
                                          component_url, error, stack_trace);
            } else {
              FML_LOG(ERROR)
                  << "Unhandled exception after application shutdown: "
                  << error;
            }
          });
        } else {
          FML_LOG(ERROR) << "Unhandled exception after application shutdown: "
                         << error;
        }
        // Ideally we would return whether HandleException returned ZX_OK, but
        // short of knowing if the exception was correctly handled, we return
        // false to have the error and stack trace printed in the logs.
        return false;
      };

  AttemptVMLaunchWithCurrentSettings(settings_);
}

Application::~Application() = default;

const std::string& Application::GetDebugLabel() const {
  return debug_label_;
}

class FileInNamespaceBuffer final : public fml::Mapping {
 public:
  FileInNamespaceBuffer(int namespace_fd, const char* path, bool executable)
      : address_(nullptr), size_(0) {
    fuchsia::mem::Buffer buffer;
    if (!dart_utils::VmoFromFilenameAt(namespace_fd, path, &buffer)) {
      return;
    }
    if (buffer.size == 0) {
      return;
    }

    uint32_t flags = ZX_VM_PERM_READ;
    if (executable) {
      flags |= ZX_VM_PERM_EXECUTE;

      // VmoFromFilenameAt will return VMOs without ZX_RIGHT_EXECUTE,
      // so we need replace_as_executable to be able to map them as
      // ZX_VM_PERM_EXECUTE.
      // TODO(mdempsky): Update comment once SEC-42 is fixed.
      zx_status_t status =
          buffer.vmo.replace_as_executable(zx::handle(), &buffer.vmo);
      if (status != ZX_OK) {
        FML_LOG(FATAL) << "Failed to make VMO executable: "
                       << zx_status_get_string(status);
      }
    }
    uintptr_t addr;
    zx_status_t status =
        zx::vmar::root_self()->map(0, buffer.vmo, 0, buffer.size, flags, &addr);
    if (status != ZX_OK) {
      FML_LOG(FATAL) << "Failed to map " << path << ": "
                     << zx_status_get_string(status);
    }

    address_ = reinterpret_cast<void*>(addr);
    size_ = buffer.size;
  }

  ~FileInNamespaceBuffer() {
    if (address_ != nullptr) {
      zx::vmar::root_self()->unmap(reinterpret_cast<uintptr_t>(address_),
                                   size_);
      address_ = nullptr;
      size_ = 0;
    }
  }

  // |fml::Mapping|
  const uint8_t* GetMapping() const override {
    return reinterpret_cast<const uint8_t*>(address_);
  }

  // |fml::Mapping|
  size_t GetSize() const override { return size_; }

 private:
  void* address_;
  size_t size_;

  FML_DISALLOW_COPY_AND_ASSIGN(FileInNamespaceBuffer);
};

std::unique_ptr<fml::Mapping> CreateWithContentsOfFile(int namespace_fd,
                                                       const char* file_path,
                                                       bool executable) {
  FML_TRACE_EVENT("flutter", "LoadFile", "path", file_path);
  auto source = std::make_unique<FileInNamespaceBuffer>(namespace_fd, file_path,
                                                        executable);
  return source->GetMapping() == nullptr ? nullptr : std::move(source);
}

void Application::AttemptVMLaunchWithCurrentSettings(
    const flutter::Settings& settings) {
  if (!flutter::DartVM::IsRunningPrecompiledCode()) {
    // We will be initializing the VM lazily in this case.
    return;
  }

  // Compare flutter_aot_app in flutter_app.gni.
  fml::RefPtr<flutter::DartSnapshot> vm_snapshot =
      fml::MakeRefCounted<flutter::DartSnapshot>(
          CreateWithContentsOfFile(
              application_assets_directory_.get() /* /pkg/data */,
              "vm_snapshot_data.bin", false),
          CreateWithContentsOfFile(
              application_assets_directory_.get() /* /pkg/data */,
              "vm_snapshot_instructions.bin", true));

  isolate_snapshot_ = fml::MakeRefCounted<flutter::DartSnapshot>(
      CreateWithContentsOfFile(
          application_assets_directory_.get() /* /pkg/data */,
          "isolate_snapshot_data.bin", false),
      CreateWithContentsOfFile(
          application_assets_directory_.get() /* /pkg/data */,
          "isolate_snapshot_instructions.bin", true));

  shared_snapshot_ = fml::MakeRefCounted<flutter::DartSnapshot>(
      CreateWithContentsOfFile(
          application_assets_directory_.get() /* /pkg/data */,
          "shared_snapshot_data.bin", false),
      CreateWithContentsOfFile(
          application_assets_directory_.get() /* /pkg/data */,
          "shared_snapshot_instructions.bin", true));

  auto vm = flutter::DartVMRef::Create(settings_,               //
                                       std::move(vm_snapshot),  //
                                       isolate_snapshot_,       //
                                       shared_snapshot_         //
  );
  FML_CHECK(vm) << "Mut be able to initialize the VM.";
}

// |fuchsia::sys::ComponentController|
void Application::Kill() {
  application_controller_.events().OnTerminated(
      last_return_code_.second, fuchsia::sys::TerminationReason::EXITED);

  termination_callback_(this);
  // WARNING: Don't do anything past this point as this instance may have been
  // collected.
}

// |fuchsia::sys::ComponentController|
void Application::Detach() {
  application_controller_.set_error_handler(nullptr);
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

// |fuchsia::ui::app::ViewProvider|
void Application::CreateView(
    zx::eventpair view_token,
    fidl::InterfaceRequest<fuchsia::sys::ServiceProvider> incoming_services,
    fidl::InterfaceHandle<fuchsia::sys::ServiceProvider> outgoing_services) {
  if (!svc_) {
    FML_DLOG(ERROR)
        << "Component incoming services was invalid when attempting to "
           "create a shell for a view provider request.";
    return;
  }

  shell_holders_.emplace(std::make_unique<Engine>(
      *this,                         // delegate
      debug_label_,                  // thread label
      svc_,                          // Component incoming services
      settings_,                     // settings
      std::move(isolate_snapshot_),  // isolate snapshot
      std::move(shared_snapshot_),   // shared snapshot
      scenic::ToViewToken(std::move(view_token)),  // view token
      std::move(fdio_ns_),                         // FDIO namespace
      std::move(directory_request_)                // outgoing request
      ));
}

#if !defined(DART_PRODUCT)
void Application::WriteProfileToTrace() const {
  for (const auto& engine : shell_holders_) {
    engine->WriteProfileToTrace();
  }
}
#endif  // !defined(DART_PRODUCT)

}  // namespace flutter_runner
