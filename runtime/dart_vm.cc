// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/runtime/dart_vm.h"

#include <sys/stat.h>

#include <mutex>
#include <vector>

#include "flutter/common/settings.h"
#include "flutter/fml/arraysize.h"
#include "flutter/fml/compiler_specific.h"
#include "flutter/fml/file.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/mapping.h"
#include "flutter/fml/synchronization/count_down_latch.h"
#include "flutter/fml/synchronization/thread_annotations.h"
#include "flutter/fml/time/time_delta.h"
#include "flutter/fml/trace_event.h"
#include "flutter/lib/io/dart_io.h"
#include "flutter/lib/ui/dart_runtime_hooks.h"
#include "flutter/lib/ui/dart_ui.h"
#include "flutter/runtime/dart_isolate.h"
#include "flutter/runtime/dart_service_isolate.h"
#include "flutter/runtime/start_up.h"
#include "third_party/dart/runtime/include/bin/dart_io_api.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_class_library.h"
#include "third_party/tonic/dart_class_provider.h"
#include "third_party/tonic/file_loader/file_loader.h"
#include "third_party/tonic/logging/dart_error.h"
#include "third_party/tonic/scopes/dart_api_scope.h"
#include "third_party/tonic/typed_data/uint8_list.h"

namespace dart {
namespace observatory {

#if !OS_FUCHSIA && (FLUTTER_RUNTIME_MODE != FLUTTER_RUNTIME_MODE_RELEASE) && \
    (FLUTTER_RUNTIME_MODE != FLUTTER_RUNTIME_MODE_DYNAMIC_RELEASE)

// These two symbols are defined in |observatory_archive.cc| which is generated
// by the |//third_party/dart/runtime/observatory:archive_observatory| rule.
// Both of these symbols will be part of the data segment and therefore are read
// only.
extern unsigned int observatory_assets_archive_len;
extern const uint8_t* observatory_assets_archive;

#endif  // !OS_FUCHSIA && (FLUTTER_RUNTIME_MODE !=
        // FLUTTER_RUNTIME_MODE_RELEASE) && (FLUTTER_RUNTIME_MODE !=
        // FLUTTER_RUNTIME_MODE_DYNAMIC_RELEASE)

}  // namespace observatory
}  // namespace dart

namespace blink {

// Arguments passed to the Dart VM in all configurations.
static const char* kDartLanguageArgs[] = {
    // clang-format off
    "--enable_mirrors=false",
    "--background_compilation",
    "--causal_async_stacks",
    // clang-format on
};

static const char* kDartPrecompilationArgs[] = {
    "--precompilation",
};

FML_ALLOW_UNUSED_TYPE
static const char* kDartWriteProtectCodeArgs[] = {
    "--no_write_protect_code",
};

static const char* kDartAssertArgs[] = {
    // clang-format off
    "--enable_asserts",
    // clang-format on
};

static const char* kDartStartPausedArgs[]{
    "--pause_isolates_on_start",
};

static const char* kDartTraceStartupArgs[]{
    "--timeline_streams=Compiler,Dart,Debugger,Embedder,GC,Isolate,VM",
};

static const char* kDartEndlessTraceBufferArgs[]{
    "--timeline_recorder=endless",
};

static const char* kDartSystraceTraceBufferArgs[]{
    "--timeline_recorder=systrace",
};

static const char* kDartFuchsiaTraceArgs[] FML_ALLOW_UNUSED_TYPE = {
    "--systrace_timeline",
};

static const char* kDartTraceStreamsArgs[] = {
    "--timeline_streams=Compiler,Dart,Debugger,Embedder,GC,Isolate,VM",
};

constexpr char kFileUriPrefix[] = "file://";
constexpr size_t kFileUriPrefixLength = sizeof(kFileUriPrefix) - 1;

bool DartFileModifiedCallback(const char* source_url, int64_t since_ms) {
  if (strncmp(source_url, kFileUriPrefix, kFileUriPrefixLength) != 0u) {
    // Assume modified.
    return true;
  }

  const char* path = source_url + kFileUriPrefixLength;
  struct stat info;
  if (stat(path, &info) < 0)
    return true;

  // If st_mtime is zero, it's more likely that the file system doesn't support
  // mtime than that the file was actually modified in the 1970s.
  if (!info.st_mtime)
    return true;

  // It's very unclear what time bases we're with here. The Dart API doesn't
  // document the time base for since_ms. Reading the code, the value varies by
  // platform, with a typical source being something like gettimeofday.
  //
  // We add one to st_mtime because st_mtime has less precision than since_ms
  // and we want to treat the file as modified if the since time is between
  // ticks of the mtime.
  fml::TimeDelta mtime = fml::TimeDelta::FromSeconds(info.st_mtime + 1);
  fml::TimeDelta since = fml::TimeDelta::FromMilliseconds(since_ms);

  return mtime > since;
}

void ThreadExitCallback() {}

Dart_Handle GetVMServiceAssetsArchiveCallback() {
#if (FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_RELEASE) || \
    (FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DYNAMIC_RELEASE)
  return nullptr;
#elif OS_FUCHSIA
  fml::UniqueFD fd = fml::OpenFile("pkg/data/observatory.tar", false,
                                   fml::FilePermission::kRead);
  fml::FileMapping mapping(fd, {fml::FileMapping::Protection::kRead});
  if (mapping.GetSize() == 0 || mapping.GetMapping() == nullptr) {
    FML_LOG(ERROR) << "Fail to load Observatory archive";
    return nullptr;
  }
  return tonic::DartConverter<tonic::Uint8List>::ToDart(mapping.GetMapping(),
                                                        mapping.GetSize());
#else
  return tonic::DartConverter<tonic::Uint8List>::ToDart(
      ::dart::observatory::observatory_assets_archive,
      ::dart::observatory::observatory_assets_archive_len);
#endif
}

static const char kStdoutStreamId[] = "Stdout";
static const char kStderrStreamId[] = "Stderr";

static bool ServiceStreamListenCallback(const char* stream_id) {
  if (strcmp(stream_id, kStdoutStreamId) == 0) {
    dart::bin::SetCaptureStdout(true);
    return true;
  } else if (strcmp(stream_id, kStderrStreamId) == 0) {
    dart::bin::SetCaptureStderr(true);
    return true;
  }
  return false;
}

static void ServiceStreamCancelCallback(const char* stream_id) {
  if (strcmp(stream_id, kStdoutStreamId) == 0) {
    dart::bin::SetCaptureStdout(false);
  } else if (strcmp(stream_id, kStderrStreamId) == 0) {
    dart::bin::SetCaptureStderr(false);
  }
}

bool DartVM::IsRunningPrecompiledCode() {
  return Dart_IsPrecompiledRuntime();
}

static std::vector<const char*> ProfilingFlags(bool enable_profiling) {
// Disable Dart's built in profiler when building a debug build. This
// works around a race condition that would sometimes stop a crash's
// stack trace from being printed on Android.
#ifndef NDEBUG
  enable_profiling = false;
#endif

  // We want to disable profiling by default because it overwhelms LLDB. But
  // the VM enables the same by default. In either case, we have some profiling
  // flags.
  if (enable_profiling) {
    return {// This is the default. But just be explicit.
            "--profiler",
            // This instructs the profiler to walk C++ frames, and to include
            // them in the profile.
            "--profile-vm"};
  } else {
    return {"--no-profiler"};
  }
}

void PushBackAll(std::vector<const char*>* args,
                 const char** argv,
                 size_t argc) {
  for (size_t i = 0; i < argc; ++i) {
    args->push_back(argv[i]);
  }
}

static void EmbedderInformationCallback(Dart_EmbedderInformation* info) {
  info->version = DART_EMBEDDER_INFORMATION_CURRENT_VERSION;
  dart::bin::GetIOEmbedderInformation(info);
  info->name = "Flutter";
}

std::shared_ptr<DartVM> DartVM::Create(
    Settings settings,
    fml::RefPtr<DartSnapshot> vm_snapshot,
    fml::RefPtr<DartSnapshot> isolate_snapshot,
    fml::RefPtr<DartSnapshot> shared_snapshot,
    std::shared_ptr<IsolateNameServer> isolate_name_server) {
  auto vm_data = DartVMData::Create(settings,                     //
                                    std::move(vm_snapshot),       //
                                    std::move(isolate_snapshot),  //
                                    std::move(shared_snapshot)    //
  );

  if (!vm_data) {
    FML_LOG(ERROR) << "Could not setup VM data to bootstrap the VM from.";
    return {};
  }

  // Note: std::make_shared unviable due to hidden constructor.
  return std::shared_ptr<DartVM>(
      new DartVM(std::move(vm_data), std::move(isolate_name_server)));
}

static std::atomic_size_t gVMLaunchCount;

size_t DartVM::GetVMLaunchCount() {
  return gVMLaunchCount;
}

DartVM::DartVM(std::shared_ptr<const DartVMData> vm_data,
               std::shared_ptr<IsolateNameServer> isolate_name_server)
    : settings_(vm_data->GetSettings()),
      vm_data_(vm_data),
      isolate_name_server_(std::move(isolate_name_server)),
      service_protocol_(std::make_shared<ServiceProtocol>()) {
  TRACE_EVENT0("flutter", "DartVMInitializer");

  gVMLaunchCount++;

  FML_DCHECK(vm_data_);
  FML_DCHECK(isolate_name_server_);
  FML_DCHECK(service_protocol_);

  FML_DLOG(INFO) << "Attempting Dart VM launch for mode: "
                 << (IsRunningPrecompiledCode() ? "AOT" : "Interpreter");

  {
    TRACE_EVENT0("flutter", "dart::bin::BootstrapDartIo");
    dart::bin::BootstrapDartIo();

    if (!settings_.temp_directory_path.empty()) {
      dart::bin::SetSystemTempDirectory(settings_.temp_directory_path.c_str());
    }
  }

  std::vector<const char*> args;

  // Instruct the VM to ignore unrecognized flags.
  // There is a lot of diversity in a lot of combinations when it
  // comes to the arguments the VM supports. And, if the VM comes across a flag
  // it does not recognize, it exits immediately.
  args.push_back("--ignore-unrecognized-flags");

  for (auto* const profiler_flag :
       ProfilingFlags(settings_.enable_dart_profiling)) {
    args.push_back(profiler_flag);
  }

  PushBackAll(&args, kDartLanguageArgs, arraysize(kDartLanguageArgs));

  if (IsRunningPrecompiledCode()) {
    PushBackAll(&args, kDartPrecompilationArgs,
                arraysize(kDartPrecompilationArgs));
  }

  // Enable Dart assertions if we are not running precompiled code. We run non-
  // precompiled code only in the debug product mode.
  bool enable_asserts = !settings_.disable_dart_asserts;

#if FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DYNAMIC_PROFILE || \
    FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DYNAMIC_RELEASE
  enable_asserts = false;
#endif

#if !OS_FUCHSIA
  if (IsRunningPrecompiledCode()) {
    enable_asserts = false;
  }
#endif  // !OS_FUCHSIA

#if FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG
  // Debug mode uses the JIT, disable code page write protection to avoid
  // memory page protection changes before and after every compilation.
  PushBackAll(&args, kDartWriteProtectCodeArgs,
              arraysize(kDartWriteProtectCodeArgs));
#endif

  if (enable_asserts) {
    PushBackAll(&args, kDartAssertArgs, arraysize(kDartAssertArgs));
  }

  if (settings_.start_paused) {
    PushBackAll(&args, kDartStartPausedArgs, arraysize(kDartStartPausedArgs));
  }

  if (settings_.endless_trace_buffer || settings_.trace_startup) {
    // If we are tracing startup, make sure the trace buffer is endless so we
    // don't lose early traces.
    PushBackAll(&args, kDartEndlessTraceBufferArgs,
                arraysize(kDartEndlessTraceBufferArgs));
  }

  if (settings_.trace_systrace) {
    PushBackAll(&args, kDartSystraceTraceBufferArgs,
                arraysize(kDartSystraceTraceBufferArgs));
    PushBackAll(&args, kDartTraceStreamsArgs, arraysize(kDartTraceStreamsArgs));
  }

  if (settings_.trace_startup) {
    PushBackAll(&args, kDartTraceStartupArgs, arraysize(kDartTraceStartupArgs));
  }

#if defined(OS_FUCHSIA)
  PushBackAll(&args, kDartFuchsiaTraceArgs, arraysize(kDartFuchsiaTraceArgs));
  PushBackAll(&args, kDartTraceStreamsArgs, arraysize(kDartTraceStreamsArgs));
#endif

  for (size_t i = 0; i < settings_.dart_flags.size(); i++)
    args.push_back(settings_.dart_flags[i].c_str());

  char* flags_error = Dart_SetVMFlags(args.size(), args.data());
  if (flags_error) {
    FML_LOG(FATAL) << "Error while setting Dart VM flags: " << flags_error;
    ::free(flags_error);
  }

  DartUI::InitForGlobal();

  {
    TRACE_EVENT0("flutter", "Dart_Initialize");
    Dart_InitializeParams params = {};
    params.version = DART_INITIALIZE_PARAMS_CURRENT_VERSION;
    params.vm_snapshot_data =
        vm_data_->GetVMSnapshot().GetData()->GetSnapshotPointer();
    params.vm_snapshot_instructions =
        vm_data_->GetVMSnapshot().GetInstructionsIfPresent();
    params.create = reinterpret_cast<decltype(params.create)>(
        DartIsolate::DartIsolateCreateCallback);
    params.shutdown = reinterpret_cast<decltype(params.shutdown)>(
        DartIsolate::DartIsolateShutdownCallback);
    params.cleanup = reinterpret_cast<decltype(params.cleanup)>(
        DartIsolate::DartIsolateCleanupCallback);
    params.thread_exit = ThreadExitCallback;
    params.get_service_assets = GetVMServiceAssetsArchiveCallback;
    params.entropy_source = DartIO::EntropySource;
    char* init_error = Dart_Initialize(&params);
    if (init_error) {
      FML_LOG(FATAL) << "Error while initializing the Dart VM: " << init_error;
      ::free(init_error);
    }
    // Send the earliest available timestamp in the application lifecycle to
    // timeline. The difference between this timestamp and the time we render
    // the very first frame gives us a good idea about Flutter's startup time.
    // Use a duration event so about:tracing will consider this event when
    // deciding the earliest event to use as time 0.
    if (blink::engine_main_enter_ts != 0) {
      Dart_TimelineEvent("FlutterEngineMainEnter",     // label
                         blink::engine_main_enter_ts,  // timestamp0
                         blink::engine_main_enter_ts,  // timestamp1_or_async_id
                         Dart_Timeline_Event_Duration,  // event type
                         0,                             // argument_count
                         nullptr,                       // argument_names
                         nullptr                        // argument_values
      );
    }
  }

  Dart_SetFileModifiedCallback(&DartFileModifiedCallback);

  // Allow streaming of stdout and stderr by the Dart vm.
  Dart_SetServiceStreamCallbacks(&ServiceStreamListenCallback,
                                 &ServiceStreamCancelCallback);

  Dart_SetEmbedderInformationCallback(&EmbedderInformationCallback);

  if (settings_.dart_library_sources_kernel != nullptr) {
    std::unique_ptr<fml::Mapping> dart_library_sources =
        settings_.dart_library_sources_kernel();
    // Set sources for dart:* libraries for debugging.
    Dart_SetDartLibrarySourcesKernel(dart_library_sources->GetMapping(),
                                     dart_library_sources->GetSize());
  }

  FML_DLOG(INFO) << "New Dart VM instance created. Instance count: "
                 << gVMLaunchCount;
}

DartVM::~DartVM() {
  if (Dart_CurrentIsolate() != nullptr) {
    Dart_ExitIsolate();
  }

  char* result = Dart_Cleanup();

  dart::bin::CleanupDartIo();

  FML_CHECK(result == nullptr)
      << "Could not cleanly shut down the Dart VM. Error: \"" << result
      << "\".";
  free(result);

  FML_DLOG(INFO) << "Dart VM instance destroyed. Instance count: "
                 << gVMLaunchCount;
}

std::shared_ptr<const DartVMData> DartVM::GetVMData() const {
  return vm_data_;
}

const Settings& DartVM::GetSettings() const {
  return settings_;
}

std::shared_ptr<ServiceProtocol> DartVM::GetServiceProtocol() const {
  return service_protocol_;
}

std::shared_ptr<IsolateNameServer> DartVM::GetIsolateNameServer() const {
  return isolate_name_server_;
}

size_t DartVM::GetIsolateCount() const {
  std::lock_guard<std::mutex> lock(active_isolates_mutex_);
  return active_isolates_.size();
}

void DartVM::ShutdownAllIsolates() {
  std::set<std::shared_ptr<DartIsolate>> isolates_to_shutdown;
  // We may be shutting down isolates on the current thread. Shutting down the
  // isolate calls the shutdown callback which removes the entry from the
  // active isolate. The lock must be obtained to mutate that entry. To avoid a
  // deadlock, collect the isolate is a seprate collection.
  {
    std::lock_guard<std::mutex> lock(active_isolates_mutex_);
    for (const auto& active_isolate : active_isolates_) {
      if (auto task_runner = active_isolate->GetMessageHandlingTaskRunner()) {
        isolates_to_shutdown.insert(active_isolate);
      }
    }
  }

  fml::CountDownLatch latch(isolates_to_shutdown.size());

  for (const auto& isolate : isolates_to_shutdown) {
    fml::TaskRunner::RunNowOrPostTask(
        isolate->GetMessageHandlingTaskRunner(), [&latch, isolate]() {
          if (!isolate || !isolate->Shutdown()) {
            FML_LOG(ERROR) << "Could not shutdown isolate.";
          }
          latch.CountDown();
        });
  }
  latch.Wait();
}

void DartVM::RegisterActiveIsolate(std::shared_ptr<DartIsolate> isolate) {
  if (!isolate) {
    return;
  }
  std::lock_guard<std::mutex> lock(active_isolates_mutex_);
  active_isolates_.insert(isolate);
}

void DartVM::UnregisterActiveIsolate(std::shared_ptr<DartIsolate> isolate) {
  if (!isolate) {
    return;
  }
  std::lock_guard<std::mutex> lock(active_isolates_mutex_);
  active_isolates_.erase(isolate);
}

}  // namespace blink
