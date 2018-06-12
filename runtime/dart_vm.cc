// Copyright 2017 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/runtime/dart_vm.h"

#include <sys/stat.h>

#include <mutex>
#include <vector>

#include "flutter/common/settings.h"
#include "flutter/fml/trace_event.h"
#include "flutter/lib/io/dart_io.h"
#include "flutter/lib/ui/dart_runtime_hooks.h"
#include "flutter/lib/ui/dart_ui.h"
#include "flutter/runtime/dart_isolate.h"
#include "flutter/runtime/dart_service_isolate.h"
#include "flutter/runtime/start_up.h"
#include "lib/fxl/arraysize.h"
#include "lib/fxl/compiler_specific.h"
#include "lib/fxl/files/file.h"
#include "lib/fxl/logging.h"
#include "lib/fxl/time/time_delta.h"
#include "lib/tonic/converter/dart_converter.h"
#include "lib/tonic/dart_class_library.h"
#include "lib/tonic/dart_class_provider.h"
#include "lib/tonic/dart_sticky_error.h"
#include "lib/tonic/file_loader/file_loader.h"
#include "lib/tonic/logging/dart_error.h"
#include "lib/tonic/scopes/dart_api_scope.h"
#include "lib/tonic/typed_data/uint8_list.h"
#include "third_party/dart/runtime/bin/embedded_dart_io.h"

#ifdef ERROR
#undef ERROR
#endif

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
    "--await_is_keyword",
    "--causal_async_stacks",
    // clang-format on
};

static const char* kDartPrecompilationArgs[] = {
    "--precompilation",
};

FXL_ALLOW_UNUSED_TYPE
static const char* kDartWriteProtectCodeArgs[] = {
    "--no_write_protect_code",
};

static const char* kDartAssertArgs[] = {
    // clang-format off
    "--enable_asserts",
    // clang-format on
};

static const char* kDartStrongModeArgs[] = {
    // clang-format off
    "--strong",
    "--reify_generic_functions",
    // TODO(bkonyi): uncomment when sync-async is enabled in flutter/flutter.
    // "--sync_async",
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

static const char* kDartFuchsiaTraceArgs[] FXL_ALLOW_UNUSED_TYPE = {
    "--systrace_timeline",
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
  fxl::TimeDelta mtime = fxl::TimeDelta::FromSeconds(info.st_mtime + 1);
  fxl::TimeDelta since = fxl::TimeDelta::FromMilliseconds(since_ms);

  return mtime > since;
}

void ThreadExitCallback() {}

Dart_Handle GetVMServiceAssetsArchiveCallback() {
#if (FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_RELEASE) || \
    (FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DYNAMIC_RELEASE)
  return nullptr;
#elif OS_FUCHSIA
  std::vector<uint8_t> observatory_assets_archive;
  if (!files::ReadFileToVector("pkg/data/observatory.tar",
                               &observatory_assets_archive)) {
    FXL_LOG(ERROR) << "Fail to load Observatory archive";
    return nullptr;
  }
  return tonic::DartConverter<tonic::Uint8List>::ToDart(
      observatory_assets_archive.data(), observatory_assets_archive.size());
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

fxl::RefPtr<DartVM> DartVM::ForProcess(Settings settings) {
  return ForProcess(settings, nullptr, nullptr, nullptr);
}

static std::once_flag gVMInitialization;
static fxl::RefPtr<DartVM> gVM;

fxl::RefPtr<DartVM> DartVM::ForProcess(
    Settings settings,
    fxl::RefPtr<DartSnapshot> vm_snapshot,
    fxl::RefPtr<DartSnapshot> isolate_snapshot,
    fxl::RefPtr<DartSnapshot> shared_snapshot) {
  std::call_once(gVMInitialization, [settings,          //
                                     vm_snapshot,       //
                                     isolate_snapshot,  //
                                     shared_snapshot    //
  ]() mutable {
    if (!vm_snapshot) {
      vm_snapshot = DartSnapshot::VMSnapshotFromSettings(settings);
    }
    if (!(vm_snapshot && vm_snapshot->IsValid())) {
      FXL_LOG(ERROR) << "VM snapshot must be valid.";
      return;
    }
    if (!isolate_snapshot) {
      isolate_snapshot = DartSnapshot::IsolateSnapshotFromSettings(settings);
    }
    if (!(isolate_snapshot && isolate_snapshot->IsValid())) {
      FXL_LOG(ERROR) << "Isolate snapshot must be valid.";
      return;
    }
    if (!shared_snapshot) {
      shared_snapshot = DartSnapshot::Empty();
    }
    gVM = fxl::MakeRefCounted<DartVM>(settings,                     //
                                      std::move(vm_snapshot),       //
                                      std::move(isolate_snapshot),  //
                                      std::move(shared_snapshot)    //
    );
  });
  return gVM;
}

fxl::RefPtr<DartVM> DartVM::ForProcessIfInitialized() {
  return gVM;
}

DartVM::DartVM(const Settings& settings,
               fxl::RefPtr<DartSnapshot> vm_snapshot,
               fxl::RefPtr<DartSnapshot> isolate_snapshot,
               fxl::RefPtr<DartSnapshot> shared_snapshot)
    : settings_(settings),
      vm_snapshot_(std::move(vm_snapshot)),
      isolate_snapshot_(std::move(isolate_snapshot)),
      shared_snapshot_(std::move(shared_snapshot)),
      platform_kernel_mapping_(
          std::make_unique<fml::FileMapping>(settings.platform_kernel_path)),
      weak_factory_(this) {
  TRACE_EVENT0("flutter", "DartVMInitializer");
  FXL_DLOG(INFO) << "Attempting Dart VM launch for mode: "
                 << (IsRunningPrecompiledCode() ? "AOT" : "Interpreter");

  {
    TRACE_EVENT0("flutter", "dart::bin::BootstrapDartIo");
    dart::bin::BootstrapDartIo();

    if (!settings.temp_directory_path.empty()) {
      dart::bin::SetSystemTempDirectory(settings.temp_directory_path.c_str());
    }
  }

  std::vector<const char*> args;

  // Instruct the VM to ignore unrecognized flags.
  // There is a lot of diversity in a lot of combinations when it
  // comes to the arguments the VM supports. And, if the VM comes across a flag
  // it does not recognize, it exits immediately.
  args.push_back("--ignore-unrecognized-flags");

  for (const auto& profiler_flag :
       ProfilingFlags(settings.enable_dart_profiling)) {
    args.push_back(profiler_flag);
  }

  PushBackAll(&args, kDartLanguageArgs, arraysize(kDartLanguageArgs));

  if (IsRunningPrecompiledCode()) {
    PushBackAll(&args, kDartPrecompilationArgs,
                arraysize(kDartPrecompilationArgs));
  }

  // Enable asserts if we are not running precompiled code. We run non-
  // precompiled code only in the debug product mode.
  bool enable_asserts = true;

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

  // Require Dart 2.
  FML_DCHECK(platform_kernel_mapping_->GetSize() > 0);

  PushBackAll(&args, kDartStrongModeArgs, arraysize(kDartStrongModeArgs));
  if (enable_asserts) {
    PushBackAll(&args, kDartAssertArgs, arraysize(kDartAssertArgs));
  }

  if (settings.start_paused) {
    PushBackAll(&args, kDartStartPausedArgs, arraysize(kDartStartPausedArgs));
  }

  if (settings.endless_trace_buffer || settings.trace_startup) {
    // If we are tracing startup, make sure the trace buffer is endless so we
    // don't lose early traces.
    PushBackAll(&args, kDartEndlessTraceBufferArgs,
                arraysize(kDartEndlessTraceBufferArgs));
  }

  if (settings.trace_startup) {
    PushBackAll(&args, kDartTraceStartupArgs, arraysize(kDartTraceStartupArgs));
  }

#if defined(OS_FUCHSIA)
  PushBackAll(&args, kDartFuchsiaTraceArgs, arraysize(kDartFuchsiaTraceArgs));
#endif

  // Add VM dart_flags last to allow user overrides.
  for (size_t i = 0; i < settings.dart_flags.size(); i++)
    args.push_back(settings.dart_flags[i].c_str());

  char* flags_error = Dart_SetVMFlags(args.size(), args.data());
  if (flags_error) {
    FXL_LOG(FATAL) << "Error while setting Dart VM flags: " << flags_error;
    ::free(flags_error);
  }

  DartUI::InitForGlobal();

  Dart_SetFileModifiedCallback(&DartFileModifiedCallback);

  {
    TRACE_EVENT0("flutter", "Dart_Initialize");
    Dart_InitializeParams params = {};
    params.version = DART_INITIALIZE_PARAMS_CURRENT_VERSION;
    params.vm_snapshot_data = vm_snapshot_->GetData()->GetSnapshotPointer();
    params.vm_snapshot_instructions = vm_snapshot_->GetInstructionsIfPresent();
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
      FXL_LOG(FATAL) << "Error while initializing the Dart VM: " << init_error;
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

  // Allow streaming of stdout and stderr by the Dart vm.
  Dart_SetServiceStreamCallbacks(&ServiceStreamListenCallback,
                                 &ServiceStreamCancelCallback);

  Dart_SetEmbedderInformationCallback(&EmbedderInformationCallback);
}

DartVM::~DartVM() {
  if (Dart_CurrentIsolate() != nullptr) {
    Dart_ExitIsolate();
  }
  char* result = Dart_Cleanup();
  if (result != nullptr) {
    FXL_LOG(ERROR) << "Could not cleanly shut down the Dart VM. Message: \""
                   << result << "\".";
    free(result);
  }
}

const Settings& DartVM::GetSettings() const {
  return settings_;
}

const fml::Mapping& DartVM::GetPlatformKernel() const {
  return *platform_kernel_mapping_.get();
}

const DartSnapshot& DartVM::GetVMSnapshot() const {
  return *vm_snapshot_.get();
}

fxl::RefPtr<DartSnapshot> DartVM::GetIsolateSnapshot() const {
  return isolate_snapshot_;
}

fxl::RefPtr<DartSnapshot> DartVM::GetSharedSnapshot() const {
  return shared_snapshot_;
}

ServiceProtocol& DartVM::GetServiceProtocol() {
  return service_protocol_;
}

fxl::WeakPtr<DartVM> DartVM::GetWeakPtr() {
  return weak_factory_.GetWeakPtr();
}

}  // namespace blink
