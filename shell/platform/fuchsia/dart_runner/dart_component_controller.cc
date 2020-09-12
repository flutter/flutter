// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "dart_component_controller.h"

#include <fcntl.h>
#include <lib/async-loop/loop.h>
#include <lib/async/cpp/task.h>
#include <lib/async/default.h>
#include <lib/fdio/directory.h>
#include <lib/fdio/fd.h>
#include <lib/fdio/namespace.h>
#include <lib/fidl/cpp/optional.h>
#include <lib/fidl/cpp/string.h>
#include <lib/sys/cpp/service_directory.h>
#include <lib/syslog/global.h>
#include <lib/zx/clock.h>
#include <lib/zx/thread.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <zircon/status.h>

#include <regex>
#include <utility>

#include "runtime/dart/utils/files.h"
#include "runtime/dart/utils/handle_exception.h"
#include "runtime/dart/utils/inlines.h"
#include "runtime/dart/utils/tempfs.h"
#include "third_party/dart/runtime/include/dart_tools_api.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_message_handler.h"
#include "third_party/tonic/dart_microtask_queue.h"
#include "third_party/tonic/dart_state.h"
#include "third_party/tonic/logging/dart_error.h"

#include "builtin_libraries.h"
#include "logging.h"

using tonic::ToDart;

namespace dart_runner {

constexpr char kDataKey[] = "data";

namespace {

void AfterTask(async_loop_t*, void*) {
  tonic::DartMicrotaskQueue* queue =
      tonic::DartMicrotaskQueue::GetForCurrentThread();
  // Verify that the queue exists, as this method could have been called back as
  // part of the exit routine, after the destruction of the microtask queue.
  if (queue) {
    queue->RunMicrotasks();
  }
}

constexpr async_loop_config_t kLoopConfig = {
    .default_accessors =
        {
            .getter = async_get_default_dispatcher,
            .setter = async_set_default_dispatcher,
        },
    .make_default_for_current_thread = true,
    .epilogue = &AfterTask,
};

// Find the last path component.
// fuchsia-pkg://fuchsia.com/hello_dart#meta/hello_dart.cmx -> hello_dart.cmx
std::string GetLabelFromURL(const std::string& url) {
  for (size_t i = url.length() - 1; i > 0; i--) {
    if (url[i] == '/') {
      return url.substr(i + 1, url.length() - 1);
    }
  }
  return url;
}

}  // namespace

DartComponentController::DartComponentController(
    fuchsia::sys::Package package,
    fuchsia::sys::StartupInfo startup_info,
    std::shared_ptr<sys::ServiceDirectory> runner_incoming_services,
    fidl::InterfaceRequest<fuchsia::sys::ComponentController> controller)
    : loop_(new async::Loop(&kLoopConfig)),
      label_(GetLabelFromURL(package.resolved_url)),
      url_(std::move(package.resolved_url)),
      package_(std::move(package)),
      startup_info_(std::move(startup_info)),
      runner_incoming_services_(runner_incoming_services),
      binding_(this) {
  for (size_t i = 0; i < startup_info_.program_metadata->size(); ++i) {
    auto pg = startup_info_.program_metadata->at(i);
    if (pg.key.compare(kDataKey) == 0) {
      data_path_ = "pkg/" + pg.value;
    }
  }
  if (data_path_.empty()) {
    FX_LOGF(ERROR, LOG_TAG, "Could not find a /pkg/data directory for %s",
            url_.c_str());
    return;
  }
  if (controller.is_valid()) {
    binding_.Bind(std::move(controller));
    binding_.set_error_handler([this](zx_status_t status) { Kill(); });
  }

  zx_status_t status =
      zx::timer::create(ZX_TIMER_SLACK_LATE, ZX_CLOCK_MONOTONIC, &idle_timer_);
  if (status != ZX_OK) {
    FX_LOGF(INFO, LOG_TAG, "Idle timer creation failed: %s",
            zx_status_get_string(status));
  } else {
    idle_wait_.set_object(idle_timer_.get());
    idle_wait_.set_trigger(ZX_TIMER_SIGNALED);
    idle_wait_.Begin(async_get_default_dispatcher());
  }
}

DartComponentController::~DartComponentController() {
  if (namespace_) {
    fdio_ns_destroy(namespace_);
    namespace_ = nullptr;
  }
  close(stdoutfd_);
  close(stderrfd_);
}

bool DartComponentController::Setup() {
  // Name the thread after the url of the component being launched.
  zx::thread::self()->set_property(ZX_PROP_NAME, label_.c_str(), label_.size());
  Dart_SetThreadName(label_.c_str());

  if (!SetupNamespace()) {
    return false;
  }

  if (SetupFromAppSnapshot()) {
    FX_LOGF(INFO, LOG_TAG, "%s is running from an app snapshot", url_.c_str());
  } else if (SetupFromKernel()) {
    FX_LOGF(INFO, LOG_TAG, "%s is running from kernel", url_.c_str());
  } else {
    FX_LOGF(ERROR, LOG_TAG,
            "Could not find a program in %s. Was data specified"
            " correctly in the component manifest?",
            url_.c_str());
    return false;
  }

  return true;
}

constexpr char kTmpPath[] = "/tmp";
constexpr char kServiceRootPath[] = "/svc";

bool DartComponentController::SetupNamespace() {
  fuchsia::sys::FlatNamespace* flat = &startup_info_.flat_namespace;
  zx_status_t status = fdio_ns_create(&namespace_);
  if (status != ZX_OK) {
    FX_LOG(ERROR, LOG_TAG, "Failed to create namespace");
    return false;
  }

  dart_utils::RunnerTemp::SetupComponent(namespace_);

  for (size_t i = 0; i < flat->paths.size(); ++i) {
    if (flat->paths.at(i) == kTmpPath) {
      // /tmp is covered by the local memfs.
      continue;
    }

    zx::channel dir;
    if (flat->paths.at(i) == kServiceRootPath) {
      // clone /svc so component_context can still use it below
      dir = zx::channel(fdio_service_clone(flat->directories.at(i).get()));
    } else {
      dir = std::move(flat->directories.at(i));
    }

    zx_handle_t dir_handle = dir.release();
    const char* path = flat->paths.at(i).data();
    status = fdio_ns_bind(namespace_, path, dir_handle);
    if (status != ZX_OK) {
      FX_LOGF(ERROR, LOG_TAG, "Failed to bind %s to namespace: %s",
              flat->paths.at(i).c_str(), zx_status_get_string(status));
      zx_handle_close(dir_handle);
      return false;
    }
  }

  return true;
}

bool DartComponentController::SetupFromKernel() {
  dart_utils::MappedResource manifest;
  if (!dart_utils::MappedResource::LoadFromNamespace(
          namespace_, data_path_ + "/app.dilplist", manifest)) {
    return false;
  }

  if (!dart_utils::MappedResource::LoadFromNamespace(
          nullptr, "/pkg/data/isolate_core_snapshot_data.bin",
          isolate_snapshot_data_)) {
    return false;
  }
  if (!dart_utils::MappedResource::LoadFromNamespace(
          nullptr, "/pkg/data/isolate_core_snapshot_instructions.bin",
          isolate_snapshot_instructions_, true /* executable */)) {
    return false;
  }

  if (!CreateIsolate(isolate_snapshot_data_.address(),
                     isolate_snapshot_instructions_.address())) {
    return false;
  }

  Dart_EnterScope();

  std::string str(reinterpret_cast<const char*>(manifest.address()),
                  manifest.size());
  Dart_Handle library = Dart_Null();
  for (size_t start = 0; start < manifest.size();) {
    size_t end = str.find("\n", start);
    if (end == std::string::npos) {
      FX_LOG(ERROR, LOG_TAG, "Malformed manifest");
      Dart_ExitScope();
      return false;
    }

    std::string path = data_path_ + "/" + str.substr(start, end - start);
    start = end + 1;

    dart_utils::MappedResource kernel;
    if (!dart_utils::MappedResource::LoadFromNamespace(namespace_, path,
                                                       kernel)) {
      FX_LOGF(ERROR, LOG_TAG, "Failed to find kernel: %s", path.c_str());
      Dart_ExitScope();
      return false;
    }
    library = Dart_LoadLibraryFromKernel(kernel.address(), kernel.size());
    if (Dart_IsError(library)) {
      FX_LOGF(ERROR, LOG_TAG, "Failed to load kernel: %s",
              Dart_GetError(library));
      Dart_ExitScope();
      return false;
    }

    kernel_peices_.emplace_back(std::move(kernel));
  }
  Dart_SetRootLibrary(library);

  Dart_Handle result = Dart_FinalizeLoading(false);
  if (Dart_IsError(result)) {
    FX_LOGF(ERROR, LOG_TAG, "Failed to FinalizeLoading: %s",
            Dart_GetError(result));
    Dart_ExitScope();
    return false;
  }

  return true;
}

bool DartComponentController::SetupFromAppSnapshot() {
#if !defined(AOT_RUNTIME)
  return false;
#else
  // Load the ELF snapshot as available, and fall back to a blobs snapshot
  // otherwise.
  const uint8_t *isolate_data, *isolate_instructions;
  if (elf_snapshot_.Load(namespace_, data_path_ + "/app_aot_snapshot.so")) {
    isolate_data = elf_snapshot_.IsolateData();
    isolate_instructions = elf_snapshot_.IsolateInstrs();
    if (isolate_data == nullptr || isolate_instructions == nullptr) {
      return false;
    }
  } else {
    if (!dart_utils::MappedResource::LoadFromNamespace(
            namespace_, data_path_ + "/isolate_snapshot_data.bin",
            isolate_snapshot_data_)) {
      return false;
    }
    if (!dart_utils::MappedResource::LoadFromNamespace(
            namespace_, data_path_ + "/isolate_snapshot_instructions.bin",
            isolate_snapshot_instructions_, true /* executable */)) {
      return false;
    }
  }
  return CreateIsolate(isolate_data, isolate_instructions);
#endif  // defined(AOT_RUNTIME)
}

int DartComponentController::SetupFileDescriptor(
    fuchsia::sys::FileDescriptorPtr fd) {
  if (!fd) {
    return -1;
  }
  // fd->handle1 and fd->handle2 are no longer used.
  int outfd = -1;
  zx_status_t status = fdio_fd_create(fd->handle0.release(), &outfd);
  if (status != ZX_OK) {
    FX_LOGF(ERROR, LOG_TAG, "Failed to extract output fd: %s",
            zx_status_get_string(status));
    return -1;
  }
  return outfd;
}

bool DartComponentController::CreateIsolate(
    const uint8_t* isolate_snapshot_data,
    const uint8_t* isolate_snapshot_instructions) {
  // Create the isolate from the snapshot.
  char* error = nullptr;

  // TODO(dart_runner): Pass if we start using tonic's loader.
  intptr_t namespace_fd = -1;
  // Freed in IsolateShutdownCallback.
  auto state = new std::shared_ptr<tonic::DartState>(new tonic::DartState(
      namespace_fd, [this](Dart_Handle result) { MessageEpilogue(result); }));

  isolate_ = Dart_CreateIsolateGroup(
      url_.c_str(), label_.c_str(), isolate_snapshot_data,
      isolate_snapshot_instructions, nullptr /* flags */, state, state, &error);
  if (!isolate_) {
    FX_LOGF(ERROR, LOG_TAG, "Dart_CreateIsolateGroup failed: %s", error);
    return false;
  }

  state->get()->SetIsolate(isolate_);

  tonic::DartMessageHandler::TaskDispatcher dispatcher =
      [loop = loop_.get()](auto callback) {
        async::PostTask(loop->dispatcher(), std::move(callback));
      };
  state->get()->message_handler().Initialize(dispatcher);

  state->get()->SetReturnCodeCallback(
      [this](uint32_t return_code) { return_code_ = return_code; });

  return true;
}

void DartComponentController::Run() {
  async::PostTask(loop_->dispatcher(), [loop = loop_.get(), app = this] {
    if (!app->Main()) {
      loop->Quit();
    }
  });
  loop_->Run();
  SendReturnCode();
}

bool DartComponentController::Main() {
  Dart_EnterScope();

  tonic::DartMicrotaskQueue::StartForCurrentThread();

  std::vector<std::string> arguments =
      startup_info_.launch_info.arguments.value_or(std::vector<std::string>());

  stdoutfd_ = SetupFileDescriptor(std::move(startup_info_.launch_info.out));
  stderrfd_ = SetupFileDescriptor(std::move(startup_info_.launch_info.err));
  auto directory_request =
      std::move(startup_info_.launch_info.directory_request);

  auto* flat = &startup_info_.flat_namespace;
  std::unique_ptr<sys::ServiceDirectory> svc;
  for (size_t i = 0; i < flat->paths.size(); ++i) {
    zx::channel dir;
    if (flat->paths.at(i) == kServiceRootPath) {
      svc = std::make_unique<sys::ServiceDirectory>(
          std::move(flat->directories.at(i)));
      break;
    }
  }
  if (!svc) {
    FX_LOG(ERROR, LOG_TAG, "Unable to get /svc for dart component");
    return false;
  }

  fidl::InterfaceHandle<fuchsia::sys::Environment> environment;
  svc->Connect(environment.NewRequest());

  InitBuiltinLibrariesForIsolate(
      url_, namespace_, stdoutfd_, stderrfd_, std::move(environment),
      std::move(directory_request), false /* service_isolate */);
  namespace_ = nullptr;

  Dart_ExitScope();
  Dart_ExitIsolate();
  char* error = Dart_IsolateMakeRunnable(isolate_);
  if (error != nullptr) {
    Dart_EnterIsolate(isolate_);
    Dart_ShutdownIsolate();
    FX_LOGF(ERROR, LOG_TAG, "Unable to make isolate runnable: %s", error);
    free(error);
    return false;
  }
  Dart_EnterIsolate(isolate_);
  Dart_EnterScope();

  Dart_Handle dart_arguments =
      Dart_NewListOf(Dart_CoreType_String, arguments.size());
  if (Dart_IsError(dart_arguments)) {
    FX_LOGF(ERROR, LOG_TAG, "Failed to allocate Dart arguments list: %s",
            Dart_GetError(dart_arguments));
    Dart_ExitScope();
    return false;
  }
  for (size_t i = 0; i < arguments.size(); i++) {
    tonic::LogIfError(
        Dart_ListSetAt(dart_arguments, i, ToDart(arguments.at(i))));
  }

  Dart_Handle argv[] = {
      dart_arguments,
  };

  Dart_Handle main_result = Dart_Invoke(Dart_RootLibrary(), ToDart("main"),
                                        dart_utils::ArraySize(argv), argv);
  if (Dart_IsError(main_result)) {
    auto dart_state = tonic::DartState::Current();
    if (!dart_state->has_set_return_code()) {
      // The program hasn't set a return code meaning this exit is unexpected.
      FX_LOG(ERROR, LOG_TAG, Dart_GetError(main_result));
      return_code_ = tonic::GetErrorExitCode(main_result);

      dart_utils::HandleIfException(runner_incoming_services_, url_,
                                    main_result);
    }
    Dart_ExitScope();
    return false;
  }

  Dart_ExitScope();
  return true;
}

void DartComponentController::Kill() {
  if (Dart_CurrentIsolate()) {
    tonic::DartMicrotaskQueue::GetForCurrentThread()->Destroy();

    loop_->Quit();

    // TODO(rosswang): The docs warn of threading issues if doing this again,
    // but without this, attempting to shut down the isolate finalizes app
    // contexts that can't tell a shutdown is in progress and so fatal.
    Dart_SetMessageNotifyCallback(nullptr);

    Dart_ShutdownIsolate();
  }
}

void DartComponentController::Detach() {
  binding_.set_error_handler([](zx_status_t status) {});
}

void DartComponentController::SendReturnCode() {
  binding_.events().OnTerminated(return_code_,
                                 fuchsia::sys::TerminationReason::EXITED);
}

const zx::duration kIdleWaitDuration = zx::sec(2);
const zx::duration kIdleNotifyDuration = zx::msec(500);
const zx::duration kIdleSlack = zx::sec(1);

void DartComponentController::MessageEpilogue(Dart_Handle result) {
  auto dart_state = tonic::DartState::Current();
  // If the Dart program has set a return code, then it is intending to shut
  // down by way of a fatal error, and so there is no need to override
  // return_code_.
  if (dart_state->has_set_return_code()) {
    Dart_ShutdownIsolate();
    return;
  }

  dart_utils::HandleIfException(runner_incoming_services_, url_, result);

  // Otherwise, see if there was any other error.
  return_code_ = tonic::GetErrorExitCode(result);
  if (return_code_ != 0) {
    Dart_ShutdownIsolate();
    return;
  }

  idle_start_ = zx::clock::get_monotonic();
  zx_status_t status =
      idle_timer_.set(idle_start_ + kIdleWaitDuration, kIdleSlack);
  if (status != ZX_OK) {
    FX_LOGF(INFO, LOG_TAG, "Idle timer set failed: %s",
            zx_status_get_string(status));
  }
}

void DartComponentController::OnIdleTimer(async_dispatcher_t* dispatcher,
                                          async::WaitBase* wait,
                                          zx_status_t status,
                                          const zx_packet_signal* signal) {
  if ((status != ZX_OK) || !(signal->observed & ZX_TIMER_SIGNALED) ||
      !Dart_CurrentIsolate()) {
    // Timer closed or isolate shutdown.
    return;
  }

  zx::time deadline = idle_start_ + kIdleWaitDuration;
  zx::time now = zx::clock::get_monotonic();
  if (now >= deadline) {
    // No Dart message has been processed for kIdleWaitDuration: assume we'll
    // stay idle for kIdleNotifyDuration.
    Dart_NotifyIdle((now + kIdleNotifyDuration).get());
    idle_start_ = zx::time(0);
    idle_timer_.cancel();  // De-assert signal.
  } else {
    // Early wakeup or message pushed idle time forward: reschedule.
    zx_status_t status = idle_timer_.set(deadline, kIdleSlack);
    if (status != ZX_OK) {
      FX_LOGF(INFO, LOG_TAG, "Idle timer set failed: %s",
              zx_status_get_string(status));
    }
  }
  wait->Begin(dispatcher);  // ignore errors
}

}  // namespace dart_runner
