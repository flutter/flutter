// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/runtime/dart_init.h"
#include "flutter/sky/engine/wtf/OperatingSystem.h"

#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>

#if defined(OS_WIN)
#include <io.h>
#include <windows.h>
#undef ERROR

#define access _access
#define R_OK 0x4

#ifndef S_ISDIR
#define S_ISDIR(mode) (((mode)&S_IFMT) == S_IFDIR)
#endif

#else
#include <unistd.h>
#endif

#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "flutter/assets/directory_asset_bundle.h"
#include "flutter/assets/unzipper_provider.h"
#include "flutter/assets/zip_asset_store.h"
#include "flutter/common/settings.h"
#include "flutter/glue/trace_event.h"
#include "flutter/lib/io/dart_io.h"
#include "flutter/lib/ui/dart_runtime_hooks.h"
#include "flutter/lib/ui/dart_ui.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "flutter/lib/ui/window/window.h"
#include "flutter/runtime/dart_service_isolate.h"
#include "flutter/runtime/start_up.h"
#include "lib/fxl/arraysize.h"
#include "lib/fxl/build_config.h"
#include "lib/fxl/files/path.h"
#include "lib/fxl/files/file.h"
#include "lib/fxl/logging.h"
#include "lib/fxl/time/time_delta.h"
#include "lib/tonic/converter/dart_converter.h"
#include "lib/tonic/dart_class_library.h"
#include "lib/tonic/dart_state.h"
#include "lib/tonic/dart_sticky_error.h"
#include "lib/tonic/dart_wrappable.h"
#include "lib/tonic/file_loader/file_loader.h"
#include "lib/tonic/logging/dart_error.h"
#include "lib/tonic/logging/dart_invoke.h"
#include "lib/tonic/scopes/dart_api_scope.h"
#include "lib/tonic/scopes/dart_isolate_scope.h"
#include "lib/tonic/typed_data/uint8_list.h"
#include "third_party/dart/runtime/bin/embedded_dart_io.h"
#include "third_party/dart/runtime/include/dart_mirrors_api.h"

using tonic::DartClassProvider;
using tonic::LogIfError;
using tonic::ToDart;

namespace dart {
namespace observatory {

#if !OS(FUCHSIA) && FLUTTER_RUNTIME_MODE != FLUTTER_RUNTIME_MODE_RELEASE

// These two symbols are defined in |observatory_archive.cc| which is generated
// by the |//third_party/dart/runtime/observatory:archive_observatory| rule.
// Both of these symbols will be part of the data segment and therefore are read
// only.
extern unsigned int observatory_assets_archive_len;
extern const uint8_t* observatory_assets_archive;

#endif  // FLUTTER_RUNTIME_MODE != FLUTTER_RUNTIME_MODE_RELEASE

}  // namespace observatory
}  // namespace dart

namespace blink {

const char kKernelAssetKey[] = "kernel_blob.bin";
const char kSnapshotAssetKey[] = "snapshot_blob.bin";
const char kPlatformKernelAssetKey[] = "platform.dill";

namespace {

// Arguments passed to the Dart VM in all configurations.
static const char* kDartLanguageArgs[] = {
    "--enable_mirrors=false", "--background_compilation", "--await_is_keyword",
    "--causal_async_stacks",  "--limit-ints-to-64-bits",
};

static const char* kDartPrecompilationArgs[] = {
    "--precompilation",
};

static const char* kDartWriteProtectCodeArgs[] FXL_ALLOW_UNUSED_TYPE = {
    "--no_write_protect_code",
};

static const char* kDartAssertArgs[] = {
    // clang-format off
    "--enable_asserts",
    // clang-format on
};

static const char* kDartCheckedModeArgs[] = {
    // clang-format off
    "--enable_type_checks",
    "--error_on_bad_type",
    "--error_on_bad_override",
    // clang-format on
};

static const char* kDartStrongModeArgs[] = {
    // clang-format off
    "--limit_ints_to_64_bits",
    "--reify_generic_functions",
    "--strong",
    "--sync_async",
    // clang-format on
};

static const char* kDartStartPausedArgs[]{
    "--pause_isolates_on_start",
};

static const char* kDartTraceStartupArgs[]{
    "--timeline_streams=Compiler,Dart,Embedder,GC",
};

static const char* kDartEndlessTraceBufferArgs[]{
    "--timeline_recorder=endless",
};

static const char* kDartFuchsiaTraceArgs[] FXL_ALLOW_UNUSED_TYPE = {
    "--systrace_timeline",
    "--timeline_streams=VM,Isolate,Compiler,Dart,GC",
};

constexpr char kFileUriPrefix[] = "file://";
constexpr size_t kFileUriPrefixLength = sizeof(kFileUriPrefix) - 1;

static const uint8_t* g_default_isolate_snapshot_data = nullptr;
static const uint8_t* g_default_isolate_snapshot_instructions = nullptr;
static bool g_service_isolate_initialized = false;
static ServiceIsolateHook g_service_isolate_hook = nullptr;
static RegisterNativeServiceProtocolExtensionHook
    g_register_native_service_protocol_extensions_hook = nullptr;

// Kernel representation of core dart libraries(loaded from platform.dill).
// TODO(aam): This (and platform_data below) have to be released when engine
// gets torn down. At that point we could also call Dart_Cleanup to complete
// Dart VM cleanup.
static void* kernel_platform = nullptr;
// Bytes actually read from platform.dill that are referenced by kernel_platform
static std::vector<uint8_t> platform_data;

void IsolateShutdownCallback(void* callback_data) {
  if (tonic::DartStickyError::IsSet()) {
    tonic::DartApiScope api_scope;
    FXL_LOG(ERROR) << "Isolate " << tonic::StdStringFromDart(Dart_DebugName())
                   << " exited with an error";
    Dart_Handle sticky_error = Dart_GetStickyError();
    FXL_CHECK(LogIfError(sticky_error));
  }

  UIDartState* dart_state = static_cast<UIDartState*>(callback_data);
  // If the isolate that's shutting down is the main one, tell the higher layers
  // of the stack.
  if ((dart_state != NULL) && dart_state->is_controller_state()) {
    dart_state->set_shutting_down(true);
    if (dart_state->isolate_client()) {
      dart_state->isolate_client()->DidShutdownMainIsolate();
    }
  }
}

// The cleanup callback frees the DartState object.
void IsolateCleanupCallback(void* callback_data) {
  UIDartState* dart_state = static_cast<UIDartState*>(callback_data);
  delete dart_state;
}

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

bool IsServiceIsolateURL(const char* url_name) {
  return url_name != nullptr &&
         std::string(url_name) == DART_VM_SERVICE_ISOLATE_NAME;
}

static bool StringEndsWith(const std::string& string,
                           const std::string& ending) {
  if (ending.size() > string.size())
    return false;

  return string.compare(string.size() - ending.size(), ending.size(), ending) ==
         0;
}

static void ReleaseFetchedBytes(uint8_t* buffer) {
  free(buffer);
}

Dart_Isolate ServiceIsolateCreateCallback(const char* script_uri,
                                          Dart_IsolateFlags* flags,
                                          char** error) {
#if FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_RELEASE
  // No VM-service in release mode.
  return nullptr;
#else   // FLUTTER_RUNTIME_MODE
  UIDartState* dart_state = new UIDartState(nullptr, nullptr);

  bool is_running_from_kernel = GetKernelPlatformBinary() != nullptr;

  flags->load_vmservice_library = true;
  Dart_Isolate isolate =
      is_running_from_kernel
          ? Dart_CreateIsolateFromKernel(
                script_uri, "main", kernel_platform, flags,
                static_cast<tonic::DartState*>(dart_state), error)
          : Dart_CreateIsolate(
                script_uri, "main", g_default_isolate_snapshot_data,
                g_default_isolate_snapshot_instructions, flags,
                static_cast<tonic::DartState*>(dart_state), error);

  FXL_CHECK(isolate) << error;
  dart_state->set_debug_name_prefix(script_uri);
  dart_state->SetIsolate(isolate);
  FXL_CHECK(Dart_IsServiceIsolate(isolate));
  FXL_CHECK(!LogIfError(
      Dart_SetLibraryTagHandler(tonic::DartState::HandleLibraryTag)));
  {
    tonic::DartApiScope dart_api_scope;
    DartIO::InitForIsolate();
    DartUI::InitForIsolate();
    DartRuntimeHooks::Install(DartRuntimeHooks::SecondaryIsolate, script_uri);
    const Settings& settings = Settings::Get();
    if (settings.enable_observatory) {
      std::string ip = settings.ipv6 ? "::1" : "127.0.0.1";
      const intptr_t port = settings.observatory_port;
      const bool disable_websocket_origin_check = false;
      const bool service_isolate_booted = DartServiceIsolate::Startup(
          ip, port, tonic::DartState::HandleLibraryTag,
          !IsRunningPrecompiledCode() && !is_running_from_kernel,
          disable_websocket_origin_check, error);
      FXL_CHECK(service_isolate_booted) << error;
    }

    if (g_service_isolate_hook)
      g_service_isolate_hook(IsRunningPrecompiledCode());
  }
  Dart_ExitIsolate();

  g_service_isolate_initialized = true;
  // Register any native service protocol extensions.
  if (g_register_native_service_protocol_extensions_hook) {
    g_register_native_service_protocol_extensions_hook(
        IsRunningPrecompiledCode());
  }
  return isolate;
#endif  // FLUTTER_RUNTIME_MODE
}

static bool GetAssetAsBuffer(
    const std::string& name,
    std::vector<uint8_t>* data,
    fxl::RefPtr<DirectoryAssetBundle>& directory_asset_bundle,
    fxl::RefPtr<ZipAssetStore>& asset_store) {
  return (directory_asset_bundle &&
          directory_asset_bundle->GetAsBuffer(name, data)) ||
         (asset_store && asset_store->GetAsBuffer(name, data));
}

Dart_Isolate IsolateCreateCallback(const char* script_uri,
                                   const char* main,
                                   const char* package_root,
                                   const char* package_config,
                                   Dart_IsolateFlags* flags,
                                   void* callback_data,
                                   char** error) {
  TRACE_EVENT0("flutter", __func__);

  if (IsServiceIsolateURL(script_uri)) {
    return ServiceIsolateCreateCallback(script_uri, flags, error);
  }

  std::string entry_uri = script_uri;
  // Are we running from a Dart source file?
  const bool running_from_source = StringEndsWith(entry_uri, ".dart");

  std::vector<uint8_t> kernel_data;
  std::vector<uint8_t> snapshot_data;
  std::string entry_path;
  if (!IsRunningPrecompiledCode()) {
    // Check that the entry script URI starts with file://
    if (entry_uri.find(kFileUriPrefix) != 0u) {
      *error = strdup("Isolates must use file:// URIs");
      return nullptr;
    }
    // Entry script path (file:// is stripped).
    entry_path = std::string(script_uri + strlen(kFileUriPrefix));
    if (!running_from_source) {
      // Attempt to copy the snapshot from the asset bundle.
      const std::string& bundle_path = entry_path;

      struct stat stat_result = {};
      if (::stat(bundle_path.c_str(), &stat_result) == 0) {
        fxl::RefPtr<DirectoryAssetBundle> directory_asset_bundle;
        // TODO(zarah): Remove usage of zip_asset_store once app.flx is removed.
        fxl::RefPtr<ZipAssetStore> zip_asset_store;
        // bundle_path is either the path to app.flx or the flutter assets
        // directory.
        std::string flx_path = bundle_path;
        if (S_ISDIR(stat_result.st_mode)) {
          directory_asset_bundle =
              fxl::MakeRefCounted<DirectoryAssetBundle>(bundle_path);
          flx_path = files::GetDirectoryName(bundle_path) + "/app.flx";
        }

        if (access(flx_path.c_str(), R_OK) == 0) {
          zip_asset_store = fxl::MakeRefCounted<ZipAssetStore>(
              GetUnzipperProviderForPath(flx_path));
        }
        GetAssetAsBuffer(kKernelAssetKey, &kernel_data, directory_asset_bundle,
                         zip_asset_store);
        GetAssetAsBuffer(kSnapshotAssetKey, &snapshot_data,
                         directory_asset_bundle, zip_asset_store);
      }
    }
  }

  UIDartState* parent_dart_state = static_cast<UIDartState*>(callback_data);
  UIDartState* dart_state = parent_dart_state->CreateForChildIsolate();

  Dart_Isolate isolate =
      kernel_platform != nullptr
          ? Dart_CreateIsolateFromKernel(script_uri, main, kernel_platform,
                                         nullptr /* flags */, dart_state, error)
          : Dart_CreateIsolate(script_uri, main,
                               g_default_isolate_snapshot_data,
                               g_default_isolate_snapshot_instructions, nullptr,
                               dart_state, error);
  FXL_CHECK(isolate) << error;
  dart_state->set_debug_name_prefix(script_uri);
  dart_state->SetIsolate(isolate);
  FXL_CHECK(!LogIfError(
      Dart_SetLibraryTagHandler(tonic::DartState::HandleLibraryTag)));

  {
    tonic::DartApiScope dart_api_scope;
    DartIO::InitForIsolate();
    DartUI::InitForIsolate();
    DartRuntimeHooks::Install(DartRuntimeHooks::SecondaryIsolate, script_uri);

    std::unique_ptr<DartClassProvider> ui_class_provider(
        new DartClassProvider(dart_state, "dart:ui"));
    dart_state->class_library().add_provider("ui",
                                             std::move(ui_class_provider));

    if (!kernel_data.empty()) {
      // We are running kernel code.
      uint8_t* kernel_buf = static_cast<uint8_t*>(malloc(kernel_data.size()));
      memcpy(kernel_buf, kernel_data.data(), kernel_data.size());
      FXL_CHECK(!LogIfError(Dart_LoadKernel(Dart_ReadKernelBinary(
          kernel_buf, kernel_data.size(), ReleaseFetchedBytes))));
    } else if (!snapshot_data.empty()) {
      // We are running from a script snapshot.
      FXL_CHECK(!LogIfError(Dart_LoadScriptFromSnapshot(snapshot_data.data(),
                                                        snapshot_data.size())));
    } else if (running_from_source) {
      // We are running from source.
      // Forward the .packages configuration from the parent isolate to the
      // child isolate.
      tonic::FileLoader& parent_loader = parent_dart_state->file_loader();
      const std::string& packages = parent_loader.packages();
      tonic::FileLoader& loader = dart_state->file_loader();
      if (!packages.empty() && !loader.LoadPackagesMap(packages)) {
        FXL_LOG(WARNING) << "Failed to load package map: " << packages;
      }
      // Load the script.
      FXL_CHECK(!LogIfError(loader.LoadScript(entry_path)));
    }

    dart_state->isolate_client()->DidCreateSecondaryIsolate(isolate);
  }

  Dart_ExitIsolate();

  FXL_CHECK(Dart_IsolateMakeRunnable(isolate));
  return isolate;
}

Dart_Handle GetVMServiceAssetsArchiveCallback() {
#if FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_RELEASE
  return nullptr;
#elif OS(FUCHSIA)
  std::vector<uint8_t> observatory_assets_archive;
  if (!files::ReadFileToVector("pkg/data/observatory.tar",
                               &observatory_assets_archive)) {
    FXL_LOG(ERROR) << "Fail to load Observatory archive";
    return nullptr;
  }
  return tonic::DartConverter<tonic::Uint8List>::ToDart(
      observatory_assets_archive.data(),
      observatory_assets_archive.size());
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

}  // namespace

bool IsRunningPrecompiledCode() {
  return Dart_IsPrecompiledRuntime();
}

EmbedderTracingCallbacks* g_tracing_callbacks = nullptr;

EmbedderTracingCallbacks::EmbedderTracingCallbacks(
    EmbedderTracingCallback start,
    EmbedderTracingCallback stop)
    : start_tracing_callback(start), stop_tracing_callback(stop) {}

void SetEmbedderTracingCallbacks(
    std::unique_ptr<EmbedderTracingCallbacks> callbacks) {
  g_tracing_callbacks = callbacks.release();
}

static void EmbedderTimelineStartRecording() {
  if (g_tracing_callbacks)
    g_tracing_callbacks->start_tracing_callback();
}

static void EmbedderTimelineStopRecording() {
  if (g_tracing_callbacks)
    g_tracing_callbacks->stop_tracing_callback();
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
    return {
        // Dart assumes ARM devices are insufficiently powerful and sets the
        // default profile period to 100Hz. This number is suitable for older
        // Raspberry Pi devices but quite low for current smartphones.
        "--profile_period=1000",
        // This is the default. But just be explicit.
        "--profiler",
        // This instructs the profiler to walk C++ frames, and to include
        // them in the profile.
        "--profile-vm"};
  } else {
    return {"--no-profiler"};
  }
}

void SetServiceIsolateHook(ServiceIsolateHook hook) {
  FXL_CHECK(!g_service_isolate_initialized);
  g_service_isolate_hook = hook;
}

void SetRegisterNativeServiceProtocolExtensionHook(
    RegisterNativeServiceProtocolExtensionHook hook) {
  FXL_CHECK(!g_service_isolate_initialized);
  g_register_native_service_protocol_extensions_hook = hook;
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

void* GetKernelPlatformBinary() {
  return kernel_platform;
}

void InitDartVM(const uint8_t* vm_snapshot_data,
                const uint8_t* vm_snapshot_instructions,
                const uint8_t* default_isolate_snapshot_data,
                const uint8_t* default_isolate_snapshot_instructions,
                const std::string& bundle_path) {
  TRACE_EVENT0("flutter", __func__);

  g_default_isolate_snapshot_data = default_isolate_snapshot_data;
  g_default_isolate_snapshot_instructions =
      default_isolate_snapshot_instructions;

  const Settings& settings = Settings::Get();

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

#if defined(OS_FUCHSIA)
#if defined(NDEBUG)
  // Do not enable checked mode for Fuchsia release builds
  // TODO(mikejurka): remove this once precompiled code is working on Fuchsia
  const bool use_checked_mode = false;
#else  // !defined(NDEBUG)
  const bool use_checked_mode = true;
#endif  // !defined(NDEBUG)
#else  // !defined(OS_FUCHSIA)
  // Enable checked mode if we are not running precompiled code. We run non-
  // precompiled code only in the debug product mode.
  const bool use_checked_mode =
      !IsRunningPrecompiledCode() && !settings.dart_non_checked_mode;
#endif  // !defined(OS_FUCHSIA)

#if FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG
  // Debug mode uses the JIT, disable code page write protection to avoid
  // memory page protection changes before and after every compilation.
  PushBackAll(&args, kDartWriteProtectCodeArgs,
              arraysize(kDartWriteProtectCodeArgs));
#endif

  if (settings.start_paused)
    PushBackAll(&args, kDartStartPausedArgs, arraysize(kDartStartPausedArgs));

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

  if (!bundle_path.empty()) {
    fxl::RefPtr<blink::DirectoryAssetBundle> directory_asset_bundle =
        fxl::MakeRefCounted<blink::DirectoryAssetBundle>(
            std::move(bundle_path));
    directory_asset_bundle->GetAsBuffer(kPlatformKernelAssetKey,
                                        &platform_data);
    if (!platform_data.empty()) {
      uint8_t* kernel_buf = static_cast<uint8_t*>(malloc(platform_data.size()));
      memcpy(kernel_buf, platform_data.data(), platform_data.size());
      kernel_platform = Dart_ReadKernelBinary(kernel_buf, platform_data.size(),
                                              ReleaseFetchedBytes);
      FXL_DCHECK(kernel_platform != nullptr);
    }
  }
  if ((kernel_platform != nullptr) ||
      Dart_IsDart2Snapshot(g_default_isolate_snapshot_data)) {
    // The presence of the kernel platform file or a snapshot that was generated
    // for Dart2 indicates we are running in preview-dart-2 mode and in this
    // mode enable strong mode options by default.
    // Note: When we start using core snapshots instead of the platform file
    // in the engine just sniffing the snapshot file should be sufficient.
    PushBackAll(&args, kDartStrongModeArgs, arraysize(kDartStrongModeArgs));
    // In addition if we are running in debug mode we also enable asserts.
    if (use_checked_mode) {
      PushBackAll(&args, kDartAssertArgs, arraysize(kDartAssertArgs));
    }
  } else if (use_checked_mode) {
    // In non preview-dart-2 mode we enable checked mode and asserts if
    // we are running in debug mode.
    PushBackAll(&args, kDartAssertArgs, arraysize(kDartAssertArgs));
    PushBackAll(&args, kDartCheckedModeArgs, arraysize(kDartCheckedModeArgs));
  }

  for (size_t i = 0; i < settings.dart_flags.size(); i++)
    args.push_back(settings.dart_flags[i].c_str());

  FXL_CHECK(Dart_SetVMFlags(args.size(), args.data()));

  DartUI::InitForGlobal();

  // Setup embedder tracing hooks. To avoid data races, it is recommended that
  // these hooks be installed before the DartInitialize, so do that setup now.
  Dart_SetEmbedderTimelineCallbacks(&EmbedderTimelineStartRecording,
                                    &EmbedderTimelineStopRecording);

  Dart_SetFileModifiedCallback(&DartFileModifiedCallback);

  {
    TRACE_EVENT0("flutter", "Dart_Initialize");
    Dart_InitializeParams params = {};
    params.version = DART_INITIALIZE_PARAMS_CURRENT_VERSION;
    params.vm_snapshot_data = vm_snapshot_data;
    params.vm_snapshot_instructions = vm_snapshot_instructions;
    params.create = IsolateCreateCallback;
    params.shutdown = IsolateShutdownCallback;
    params.cleanup = IsolateCleanupCallback;
    params.thread_exit = ThreadExitCallback;
    params.get_service_assets = GetVMServiceAssetsArchiveCallback;
    params.entropy_source = DartIO::EntropySource;
    char* init_error = Dart_Initialize(&params);
    if (init_error != nullptr)
      FXL_LOG(FATAL) << "Error while initializing the Dart VM: " << init_error;
    free(init_error);

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

}  // namespace blink
