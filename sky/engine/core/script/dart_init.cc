// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/sky/engine/core/script/dart_init.h"

#include <dlfcn.h>
#include <fcntl.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#include "dart/runtime/bin/embedded_dart_io.h"
#include "dart/runtime/include/dart_mirrors_api.h"
#include "flutter/assets/zip_asset_store.h"
#include "flutter/glue/trace_event.h"
#include "flutter/lib/io/dart_io.h"
#include "flutter/sky/engine/bindings/dart_mojo_internal.h"
#include "flutter/sky/engine/bindings/dart_runtime_hooks.h"
#include "flutter/sky/engine/bindings/dart_ui.h"
#include "flutter/sky/engine/core/script/dart_service_isolate.h"
#include "flutter/sky/engine/core/script/ui_dart_state.h"
#include "flutter/sky/engine/core/start_up.h"
#include "flutter/sky/engine/public/platform/sky_settings.h"
#include "flutter/sky/engine/wtf/MakeUnique.h"
#include "flutter/tonic/dart_state.h"
#include "lib/ftl/files/eintr_wrapper.h"
#include "lib/ftl/files/unique_fd.h"
#include "lib/ftl/logging.h"
#include "lib/ftl/time/time_delta.h"
#include "lib/tonic/dart_class_library.h"
#include "lib/tonic/dart_wrappable.h"
#include "lib/tonic/debugger/dart_debugger.h"
#include "lib/tonic/logging/dart_error.h"
#include "lib/tonic/logging/dart_invoke.h"
#include "lib/tonic/scopes/dart_api_scope.h"
#include "lib/tonic/scopes/dart_isolate_scope.h"
#include "lib/tonic/typed_data/uint8_list.h"
#include "mojo/public/platform/dart/dart_handle_watcher.h"

#ifdef OS_ANDROID
#include "flutter/lib/jni/dart_jni.h"
#endif

using tonic::LogIfError;
using tonic::ToDart;

namespace dart {
namespace observatory {

#if !FLUTTER_PRODUCT_MODE

// These two symbols are defined in |observatory_archive.cc| which is generated
// by the |//dart/runtime/observatory:archive_observatory| rule. Both of these
// symbols will be part of the data segment and therefore are read only.
extern unsigned int observatory_assets_archive_len;
extern const uint8_t* observatory_assets_archive;

#endif  // !FLUTTER_PRODUCT_MODE

}  // namespace observatory
}  // namespace dart

namespace blink {

const char kSnapshotAssetKey[] = "snapshot_blob.bin";

namespace {

static const char* kDartProfilingArgs[] = {
    // Dart assumes ARM devices are insufficiently powerful and sets the
    // default profile period to 100Hz. This number is suitable for older
    // Raspberry Pi devices but quite low for current smartphones.
    "--profile_period=1000",
#if (WTF_OS_IOS || WTF_OS_MACOSX)
    // On platforms where LLDB is the primary debugger, SIGPROF signals
    // overwhelm LLDB.
    "--no-profiler",
#endif
};

static const char* kDartMirrorsArgs[] = {
    "--enable_mirrors=false",
};

static const char* kDartPrecompilationArgs[] = {
    "--precompilation",
};

static const char* kDartBackgroundCompilationArgs[] = {
    "--background_compilation",
};

static const char* kDartCheckedModeArgs[] = {
    // clang-format off
    "--enable_asserts",
    "--enable_type_checks",
    "--error_on_bad_type",
    "--error_on_bad_override",
    // clang-format on
};

static const char* kDartStartPausedArgs[]{
    "--pause_isolates_on_start",
};

static const char* kDartTraceStartupArgs[]{
    "--timeline_streams=Compiler,Dart,Embedder,GC",
    "--timeline_recorder=endless",
};

constexpr char kFileUriPrefix[] = "file://";
constexpr size_t kFileUriPrefixLength = sizeof(kFileUriPrefix) - 1;

bool g_service_isolate_initialized = false;
ServiceIsolateHook g_service_isolate_hook = nullptr;
RegisterNativeServiceProtocolExtensionHook
    g_register_native_service_protocol_extensions_hook = nullptr;

void IsolateShutdownCallback(void* callback_data) {
  DartState* dart_state = static_cast<DartState*>(callback_data);
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
  ftl::TimeDelta mtime = ftl::TimeDelta::FromSeconds(info.st_mtime + 1);
  ftl::TimeDelta since = ftl::TimeDelta::FromMilliseconds(since_ms);

  return mtime > since;
}

void ThreadExitCallback() {
#ifdef OS_ANDROID
  DartJni::OnThreadExit();
#endif
}

bool IsServiceIsolateURL(const char* url_name) {
  return url_name != nullptr &&
         String(url_name) == DART_VM_SERVICE_ISOLATE_NAME;
}

#ifdef FLUTTER_PRODUCT_MODE

Dart_Isolate ServiceIsolateCreateCallback(const char* script_uri,
                                          char** error) {
  return nullptr;
}

#else  // FLUTTER_PRODUCT_MODE

Dart_Isolate ServiceIsolateCreateCallback(const char* script_uri,
                                          char** error) {
  DartState* dart_state = new DartState();
  Dart_Isolate isolate = Dart_CreateIsolate(
      script_uri, "main",
      reinterpret_cast<const uint8_t*>(DART_SYMBOL(kDartIsolateSnapshotBuffer)),
      nullptr, dart_state, error);
  FTL_CHECK(isolate) << error;
  dart_state->SetIsolate(isolate);
  FTL_CHECK(Dart_IsServiceIsolate(isolate));
  FTL_CHECK(!LogIfError(
      Dart_SetLibraryTagHandler(tonic::DartState::HandleLibraryTag)));
  {
    tonic::DartApiScope dart_api_scope;
    DartIO::InitForIsolate();
    DartUI::InitForIsolate();
    DartMojoInternal::InitForIsolate();
    DartRuntimeHooks::Install(DartRuntimeHooks::SecondaryIsolate, "");
    const SkySettings& settings = SkySettings::Get();
    if (settings.enable_observatory) {
      std::string ip = "127.0.0.1";
      const intptr_t port = settings.observatory_port;
      const bool disable_websocket_origin_check = false;
      const bool service_isolate_booted = DartServiceIsolate::Startup(
          ip, port, tonic::DartState::HandleLibraryTag,
          IsRunningPrecompiledCode(), disable_websocket_origin_check, error);
      FTL_CHECK(service_isolate_booted) << error;
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
}

#endif  // FLUTTER_PRODUCT_MODE

Dart_Isolate IsolateCreateCallback(const char* script_uri,
                                   const char* main,
                                   const char* package_root,
                                   const char* package_config,
                                   Dart_IsolateFlags* flags,
                                   void* callback_data,
                                   char** error) {
  TRACE_EVENT0("flutter", __func__);

  if (IsServiceIsolateURL(script_uri)) {
    return ServiceIsolateCreateCallback(script_uri, error);
  }

  std::vector<uint8_t> snapshot_data;
  if (!IsRunningPrecompiledCode()) {
    std::string uri = script_uri;
    FTL_CHECK(uri.find(kFileUriPrefix) == 0u);
    std::string bundle_path(script_uri + strlen(kFileUriPrefix));
    ftl::RefPtr<ZipAssetStore> zip_asset_store =
        ftl::MakeRefCounted<ZipAssetStore>(std::move(bundle_path),
                                           ftl::RefPtr<ftl::TaskRunner>());
    FTL_CHECK(zip_asset_store->GetAsBuffer(kSnapshotAssetKey, &snapshot_data));
  }

  FlutterDartState* parent_dart_state =
      static_cast<FlutterDartState*>(callback_data);
  FlutterDartState* dart_state = parent_dart_state->CreateForChildIsolate();

  Dart_Isolate isolate = Dart_CreateIsolate(
      script_uri, main,
      reinterpret_cast<uint8_t*>(DART_SYMBOL(kDartIsolateSnapshotBuffer)),
      nullptr, dart_state, error);
  FTL_CHECK(isolate) << error;
  dart_state->SetIsolate(isolate);
  FTL_CHECK(!LogIfError(
      Dart_SetLibraryTagHandler(tonic::DartState::HandleLibraryTag)));

  {
    tonic::DartApiScope dart_api_scope;
    DartIO::InitForIsolate();
    DartUI::InitForIsolate();
    DartMojoInternal::InitForIsolate();
    DartRuntimeHooks::Install(DartRuntimeHooks::SecondaryIsolate, script_uri);

    dart_state->class_library().add_provider(
        "ui", WTF::MakeUnique<tonic::DartClassProvider>(dart_state, "dart:ui"));

#ifdef OS_ANDROID
    DartJni::InitForIsolate();
    dart_state->class_library().add_provider(
        "jni",
        WTF::MakeUnique<tonic::DartClassProvider>(dart_state, "dart:jni"));
#endif

    if (!snapshot_data.empty()) {
      FTL_CHECK(!LogIfError(Dart_LoadScriptFromSnapshot(snapshot_data.data(),
                                                        snapshot_data.size())));
    }

    dart_state->isolate_client()->DidCreateSecondaryIsolate(isolate);
  }

  Dart_ExitIsolate();

  FTL_CHECK(Dart_IsolateMakeRunnable(isolate));
  return isolate;
}

Dart_Handle GetVMServiceAssetsArchiveCallback() {
#if FLUTTER_PRODUCT_MODE
  return nullptr;
#else   // FLUTTER_PRODUCT_MODE
  return tonic::DartConverter<tonic::Uint8List>::ToDart(
      ::dart::observatory::observatory_assets_archive,
      ::dart::observatory::observatory_assets_archive_len);
#endif  // FLUTTER_PRODUCT_MODE
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

#ifdef OS_ANDROID

DartJniIsolateData* GetDartJniDataForCurrentIsolate() {
  return FlutterDartState::Current()->jni_data();
}

#endif

}  // namespace

#if DART_ALLOW_DYNAMIC_RESOLUTION

const char* kDartVmIsolateSnapshotBufferName = "kDartVmIsolateSnapshotBuffer";
const char* kDartIsolateSnapshotBufferName = "kDartIsolateSnapshotBuffer";
const char* kInstructionsSnapshotName = "kInstructionsSnapshot";
const char* kDataSnapshotName = "kDataSnapshot";

#if OS(IOS)

const char* kDartApplicationLibraryPath = "app.dylib";

static void* DartLookupSymbolInLibrary(const char* symbol_name,
                                       const char* library) {
  TRACE_EVENT0("flutter", __func__);
  if (symbol_name == nullptr) {
    return nullptr;
  }
  dlerror();  // clear previous errors on thread
  void* library_handle = dlopen(library, RTLD_NOW);
  if (dlerror() != nullptr) {
    return nullptr;
  }
  void* sym = dlsym(library_handle, symbol_name);
  return dlerror() != nullptr ? nullptr : sym;
}

void* _DartSymbolLookup(const char* symbol_name) {
  TRACE_EVENT0("flutter", __func__);
  if (symbol_name == nullptr) {
    return nullptr;
  }

  // First the application library is checked for the valid symbols. This
  // library may not necessarily exist. If it does exist, it is loaded and the
  // symbols resolved. Once the application library is loaded, there is
  // currently no provision to unload the same.
  void* symbol =
      DartLookupSymbolInLibrary(symbol_name, kDartApplicationLibraryPath);
  if (symbol != nullptr) {
    return symbol;
  }

  // Check inside the default library
  return DartLookupSymbolInLibrary(symbol_name, nullptr);
}

#elif OS(ANDROID)

// Describes an asset file that holds a part of the precompiled snapshot.
struct SymbolAsset {
  const char* symbol_name;
  const char* file_name;
  bool is_executable;
  void* mapping;
};

static SymbolAsset g_symbol_assets[] = {
    {kDartVmIsolateSnapshotBufferName, "snapshot_aot_vmisolate", false},
    {kDartIsolateSnapshotBufferName, "snapshot_aot_isolate", false},
    {kInstructionsSnapshotName, "snapshot_aot_instr", true},
    {kDataSnapshotName, "snapshot_aot_rodata", false},
};

// Resolve a precompiled snapshot symbol by mapping the corresponding asset
// file into memory.
void* _DartSymbolLookup(const char* symbol_name) {
  for (SymbolAsset& symbol_asset : g_symbol_assets) {
    if (strcmp(symbol_name, symbol_asset.symbol_name))
      continue;

    if (symbol_asset.mapping) {
      return symbol_asset.mapping;
    }

    const std::string& aot_snapshot_path = SkySettings::Get().aot_snapshot_path;
    FTL_CHECK(!aot_snapshot_path.empty());

    std::string asset_path = aot_snapshot_path + "/" + symbol_asset.file_name;
    struct stat info;
    if (stat(asset_path.c_str(), &info) < 0)
      return nullptr;
    int64_t asset_size = info.st_size;

    ftl::UniqueFD fd(HANDLE_EINTR(open(asset_path.c_str(), O_RDONLY)));
    if (fd.get() == -1)
      return nullptr;

    int mmap_flags = PROT_READ;
    if (symbol_asset.is_executable)
      mmap_flags |= PROT_EXEC;

    void* symbol = mmap(NULL, asset_size, mmap_flags, MAP_PRIVATE, fd.get(), 0);
    symbol_asset.mapping = symbol == MAP_FAILED ? nullptr : symbol;

    return symbol_asset.mapping;
  }

  return nullptr;
}

#else

#error "AOT mode is not supported on this platform"

#endif

static const uint8_t* PrecompiledInstructionsSymbolIfPresent() {
  return reinterpret_cast<uint8_t*>(DART_SYMBOL(kInstructionsSnapshot));
}

static const uint8_t* PrecompiledDataSnapshotSymbolIfPresent() {
  return reinterpret_cast<uint8_t*>(DART_SYMBOL(kDataSnapshot));
}

bool IsRunningPrecompiledCode() {
  TRACE_EVENT0("flutter", __func__);
  return PrecompiledInstructionsSymbolIfPresent() != nullptr;
}

#else  // DART_ALLOW_DYNAMIC_RESOLUTION

static const uint8_t* PrecompiledInstructionsSymbolIfPresent() {
  return nullptr;
}

static const uint8_t* PrecompiledDataSnapshotSymbolIfPresent() {
  return nullptr;
}

bool IsRunningPrecompiledCode() {
  return false;
}

#endif  // DART_ALLOW_DYNAMIC_RESOLUTION

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

void SetServiceIsolateHook(ServiceIsolateHook hook) {
  FTL_CHECK(!g_service_isolate_initialized);
  g_service_isolate_hook = hook;
}

void SetRegisterNativeServiceProtocolExtensionHook(
    RegisterNativeServiceProtocolExtensionHook hook) {
  CHECK(!g_service_isolate_initialized);
  g_register_native_service_protocol_extensions_hook = hook;
}

static bool ShouldEnableCheckedMode() {
  if (IsRunningPrecompiledCode()) {
    // Checked mode is never enabled during precompilation. Even snapshot
    // generation disables checked mode arguments.
    return false;
  }

#if ENABLE(DART_STRICT)
  return true;
#else
  return SkySettings::Get().enable_dart_checked_mode;
#endif
}

void InitDartVM() {
  TRACE_EVENT0("flutter", __func__);

  const SkySettings& settings = SkySettings::Get();

  {
    TRACE_EVENT0("flutter", "dart::bin::BootstrapDartIo");
    dart::bin::BootstrapDartIo();

    if (!settings.temp_directory_path.empty()) {
      dart::bin::SetSystemTempDirectory(settings.temp_directory_path.c_str());
    }
  }

  DartMojoInternal::SetHandleWatcherProducerHandle(
      mojo::dart::HandleWatcher::Start());

  Vector<const char*> args;

  // Instruct the VM to ignore unrecognized flags.
  // There is a lot of diversity in a lot of combinations when it
  // comes to the arguments the VM supports. And, if the VM comes across a flag
  // it does not recognize, it exits immediately.
  args.append("--ignore-unrecognized-flags");

  args.append(kDartProfilingArgs, arraysize(kDartProfilingArgs));
  args.append(kDartMirrorsArgs, arraysize(kDartMirrorsArgs));
  args.append(kDartBackgroundCompilationArgs,
              arraysize(kDartBackgroundCompilationArgs));

  if (IsRunningPrecompiledCode())
    args.append(kDartPrecompilationArgs, arraysize(kDartPrecompilationArgs));

  if (ShouldEnableCheckedMode())
    args.append(kDartCheckedModeArgs, arraysize(kDartCheckedModeArgs));

  if (settings.start_paused)
    args.append(kDartStartPausedArgs, arraysize(kDartStartPausedArgs));

  if (settings.trace_startup)
    args.append(kDartTraceStartupArgs, arraysize(kDartTraceStartupArgs));

  for (size_t i = 0; i < settings.dart_flags.size(); i++)
    args.append(settings.dart_flags[i].c_str());

  FTL_CHECK(Dart_SetVMFlags(args.size(), args.data()));

#ifndef FLUTTER_PRODUCT_MODE
  {
    TRACE_EVENT0("flutter", "DartDebugger::InitDebugger");
    // This should be called before calling Dart_Initialize.
    tonic::DartDebugger::InitDebugger();
  }
#endif

  DartUI::InitForGlobal();
#ifdef OS_ANDROID
  DartJni::InitForGlobal(GetDartJniDataForCurrentIsolate);
#endif

  // Setup embedder tracing hooks. To avoid data races, it is recommended that
  // these hooks be installed before the DartInitialize, so do that setup now.
  Dart_SetEmbedderTimelineCallbacks(&EmbedderTimelineStartRecording,
                                    &EmbedderTimelineStopRecording);

  Dart_SetFileModifiedCallback(&DartFileModifiedCallback);

  {
    TRACE_EVENT0("flutter", "Dart_Initialize");
    Dart_InitializeParams params = {};
    params.version = DART_INITIALIZE_PARAMS_CURRENT_VERSION;
    params.vm_isolate_snapshot =
        reinterpret_cast<uint8_t*>(DART_SYMBOL(kDartVmIsolateSnapshotBuffer));
    params.instructions_snapshot = PrecompiledInstructionsSymbolIfPresent();
    params.data_snapshot = PrecompiledDataSnapshotSymbolIfPresent();
    params.create = IsolateCreateCallback;
    params.shutdown = IsolateShutdownCallback;
    params.thread_exit = ThreadExitCallback;
    params.get_service_assets = GetVMServiceAssetsArchiveCallback;
    char* init_error = Dart_Initialize(&params);
    if (init_error != nullptr)
      FTL_LOG(FATAL) << "Error while initializing the Dart VM: " << init_error;
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
}

}  // namespace blink
