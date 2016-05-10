// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/script/dart_init.h"

#include <dlfcn.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>

#include "base/bind.h"
#include "base/command_line.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/lazy_instance.h"
#include "base/logging.h"
#include "base/single_thread_task_runner.h"
#include "base/trace_event/trace_event.h"
#include "dart/runtime/bin/embedded_dart_io.h"
#include "dart/runtime/include/dart_mirrors_api.h"
#include "mojo/public/platform/dart/dart_handle_watcher.h"
#include "services/asset_bundle/zip_asset_bundle.h"
#include "sky/engine/bindings/dart_mojo_internal.h"
#include "sky/engine/bindings/dart_runtime_hooks.h"
#include "sky/engine/bindings/dart_ui.h"
#include "sky/engine/core/script/dart_debugger.h"
#include "sky/engine/core/script/dart_service_isolate.h"
#include "sky/engine/core/script/ui_dart_state.h"
#include "sky/engine/public/platform/sky_settings.h"
#include "sky/engine/tonic/dart_api_scope.h"
#include "sky/engine/tonic/dart_class_library.h"
#include "sky/engine/tonic/dart_dependency_catcher.h"
#include "sky/engine/tonic/dart_error.h"
#include "sky/engine/tonic/dart_invoke.h"
#include "sky/engine/tonic/dart_io.h"
#include "sky/engine/tonic/dart_isolate_scope.h"
#include "sky/engine/tonic/dart_library_loader.h"
#include "sky/engine/tonic/dart_snapshot_loader.h"
#include "sky/engine/tonic/dart_state.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/tonic/uint8_list.h"
#include "sky/engine/wtf/MakeUnique.h"
#include "sky/engine/core/start_up.h"

#ifdef OS_ANDROID
#include "sky/engine/bindings/jni/dart_jni.h"
#endif

namespace dart {
namespace observatory {

// These two symbols are defined in |observatory_archive.cc| which is generated
// by the |//dart/runtime/observatory:archive_observatory| rule. Both of these
// symbols will be part of the data segment and therefore are read only.
extern unsigned int observatory_assets_archive_len;
extern const uint8_t* observatory_assets_archive;

}  // namespace observatory
}  // namespace dart

namespace blink {

using mojo::asset_bundle::ZipAssetBundle;

const char kSnapshotAssetKey[] = "snapshot_blob.bin";

Dart_Handle DartLibraryTagHandler(Dart_LibraryTag tag,
                                  Dart_Handle library,
                                  Dart_Handle url) {
  return DartLibraryLoader::HandleLibraryTag(tag, library, url);
}

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

static const char *kDartMirrorsArgs[] = {
  "--enable_mirrors=false",
};

static const char* kDartPrecompilationArgs[] = {
    "--precompilation",
};

static const char* kDartBackgroundCompilationArgs[] = {
  "--background_compilation",
};

static const char* kDartCheckedModeArgs[] = {
    "--enable_asserts",
    "--enable_type_checks",
    "--error_on_bad_type",
    "--error_on_bad_override",
};

static const char* kDartStartPausedArgs[]{
    "--pause_isolates_on_start",
};

static const char* kDartTraceStartupArgs[]{
    "--timeline_streams=Compiler,Dart,Embedder,GC",
    "--timeline_recorder=endless",
};

const char kFileUriPrefix[] = "file://";

const char kDartFlags[] = "dart-flags";

bool g_service_isolate_initialized = false;
ServiceIsolateHook g_service_isolate_hook = nullptr;

void IsolateShutdownCallback(void* callback_data) {
  DartState* dart_state = static_cast<DartState*>(callback_data);
  delete dart_state;
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
      script_uri, "main", reinterpret_cast<const uint8_t*>(
                              DART_SYMBOL(kDartIsolateSnapshotBuffer)),
      nullptr, dart_state, error);
  CHECK(isolate) << error;
  dart_state->SetIsolate(isolate);
  CHECK(Dart_IsServiceIsolate(isolate));
  CHECK(!LogIfError(Dart_SetLibraryTagHandler(DartLibraryTagHandler)));
  {
    DartApiScope dart_api_scope;
    DartIO::InitForIsolate();
    DartUI::InitForIsolate();
    DartMojoInternal::InitForIsolate();
    DartRuntimeHooks::Install(DartRuntimeHooks::SecondaryIsolate, "");
    const SkySettings& settings = SkySettings::Get();
    if (settings.enable_observatory) {
      std::string ip = "127.0.0.1";
      const intptr_t port = settings.observatory_port;
      const bool service_isolate_booted = DartServiceIsolate::Startup(
          ip, port, DartLibraryTagHandler, IsRunningPrecompiledCode(), error);
      CHECK(service_isolate_booted) << error;
    }

    if (g_service_isolate_hook)
      g_service_isolate_hook(IsRunningPrecompiledCode());
  }
  Dart_ExitIsolate();

  g_service_isolate_initialized = true;
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
    CHECK(base::StartsWith(script_uri, kFileUriPrefix,
                           base::CompareCase::SENSITIVE));
    base::FilePath bundle_path(script_uri + strlen(kFileUriPrefix));
    scoped_refptr<ZipAssetBundle> zip_asset_bundle(
        new ZipAssetBundle(bundle_path, nullptr));
    CHECK(zip_asset_bundle->GetAsBuffer(kSnapshotAssetKey, &snapshot_data));
  }

  FlutterDartState* parent_dart_state =
      static_cast<FlutterDartState*>(callback_data);
  FlutterDartState* dart_state = parent_dart_state->CreateForChildIsolate();

  Dart_Isolate isolate = Dart_CreateIsolate(
      script_uri, main,
      reinterpret_cast<uint8_t*>(DART_SYMBOL(kDartIsolateSnapshotBuffer)),
      nullptr, dart_state, error);
  CHECK(isolate) << error;
  dart_state->SetIsolate(isolate);

  CHECK(!LogIfError(Dart_SetLibraryTagHandler(DartLibraryTagHandler)));

  {
    DartApiScope dart_api_scope;
    DartIO::InitForIsolate();
    DartUI::InitForIsolate();
    DartMojoInternal::InitForIsolate();
    DartRuntimeHooks::Install(DartRuntimeHooks::SecondaryIsolate, script_uri);

    dart_state->class_library().add_provider(
      "ui",
      WTF::MakeUnique<DartClassProvider>(dart_state, "dart:ui"));

#ifdef OS_ANDROID
    DartJni::InitForIsolate();
    dart_state->class_library().add_provider(
      "jni",
      WTF::MakeUnique<DartClassProvider>(dart_state, "dart:jni"));
#endif

    if (!snapshot_data.empty()) {
      CHECK(!LogIfError(Dart_LoadScriptFromSnapshot(
          snapshot_data.data(), snapshot_data.size())));
    }

    dart_state->isolate_client()->DidCreateSecondaryIsolate(isolate);
  }

  Dart_ExitIsolate();

  CHECK(Dart_IsolateMakeRunnable(isolate));
  return isolate;
}

Dart_Handle GetVMServiceAssetsArchiveCallback() {
  return DartConverter<Uint8List>::ToDart(
      ::dart::observatory::observatory_assets_archive,
      ::dart::observatory::observatory_assets_archive_len);
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

#if DART_ALLOW_DYNAMIC_RESOLUTION

const char* kDartVmIsolateSnapshotBufferName = "kDartVmIsolateSnapshotBuffer";
const char* kDartIsolateSnapshotBufferName = "kDartIsolateSnapshotBuffer";
const char* kInstructionsSnapshotName = "kInstructionsSnapshot";
const char* kDataSnapshotName = "kDataSnapshot";

#if OS(IOS)

const char* kDartApplicationLibraryPath =
    "FlutterApplication.framework/FlutterApplication";

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
    CHECK(!aot_snapshot_path.empty());

    base::FilePath asset_path =
        base::FilePath(aot_snapshot_path).Append(symbol_asset.file_name);
    int64 asset_size;
    if (!base::GetFileSize(asset_path, &asset_size))
      return nullptr;

    int fd = HANDLE_EINTR(::open(asset_path.value().c_str(), O_RDONLY));
    if (fd == -1) {
      return nullptr;
    }

    int mmap_flags = PROT_READ;
    if (symbol_asset.is_executable)
      mmap_flags |= PROT_EXEC;

    void* symbol = ::mmap(NULL, asset_size, mmap_flags, MAP_PRIVATE, fd, 0);
    if (symbol == MAP_FAILED) {
      HANDLE_EINTR(::close(fd));
      return nullptr;
    }

    symbol_asset.mapping = symbol;
    return symbol;
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

static base::LazyInstance<std::unique_ptr<EmbedderTracingCallbacks>>::Leaky
    g_tracing_callbacks = LAZY_INSTANCE_INITIALIZER;

EmbedderTracingCallbacks::EmbedderTracingCallbacks(
    EmbedderTracingCallback start,
    EmbedderTracingCallback stop)
    : start_tracing_callback(start),
      stop_tracing_callback(stop) {}

void SetEmbedderTracingCallbacks(
    std::unique_ptr<EmbedderTracingCallbacks> callbacks) {
  g_tracing_callbacks.Get() = std::move(callbacks);
}

static void EmbedderTimelineStartRecording() {
  auto& callbacks = g_tracing_callbacks.Get();
  if (!callbacks) {
    return;
  }
  callbacks->start_tracing_callback.Run();
}

static void EmbedderTimelineStopRecording() {
  auto& callbacks = g_tracing_callbacks.Get();
  if (!callbacks) {
    return;
  }
  callbacks->stop_tracing_callback.Run();
}

void SetServiceIsolateHook(ServiceIsolateHook hook) {
  CHECK(!g_service_isolate_initialized);
  g_service_isolate_hook = hook;
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

  {
    TRACE_EVENT0("flutter", "dart::bin::BootstrapDartIo");
    dart::bin::BootstrapDartIo();
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

  if (SkySettings::Get().start_paused)
    args.append(kDartStartPausedArgs, arraysize(kDartStartPausedArgs));

  if (SkySettings::Get().trace_startup)
    args.append(kDartTraceStartupArgs, arraysize(kDartTraceStartupArgs));

  Vector<std::string> dart_flags;
  if (base::CommandLine::ForCurrentProcess()->HasSwitch(kDartFlags)) {
    // Split up dart flags by spaces.
    base::CommandLine& command_line = *base::CommandLine::ForCurrentProcess();
    std::stringstream ss(command_line.GetSwitchValueNative(kDartFlags));
    std::istream_iterator<std::string> it(ss);
    std::istream_iterator<std::string> end;
    while (it != end) {
      dart_flags.append(*it);
      it++;
    }
  }
  for (size_t i = 0; i < dart_flags.size(); i++) {
    args.append(dart_flags[i].data());
  }
  CHECK(Dart_SetVMFlags(args.size(), args.data()));

#ifndef FLUTTER_PRODUCT_MODE
  {
    TRACE_EVENT0("flutter", "DartDebugger::InitDebugger");
    // This should be called before calling Dart_Initialize.
    DartDebugger::InitDebugger();
  }
#endif

  DartUI::InitForGlobal();
#ifdef OS_ANDROID
  DartJni::InitForGlobal();
#endif

  // Setup embedder tracing hooks. To avoid data races, it is recommended that
  // these hooks be installed before the DartInitialize, so do that setup now.
  Dart_SetEmbedderTimelineCallbacks(&EmbedderTimelineStartRecording,
                                    &EmbedderTimelineStopRecording);

  {
    TRACE_EVENT0("flutter", "Dart_Initialize");
    char* init_error = Dart_Initialize(
        reinterpret_cast<uint8_t*>(DART_SYMBOL(kDartVmIsolateSnapshotBuffer)),
        PrecompiledInstructionsSymbolIfPresent(),
        PrecompiledDataSnapshotSymbolIfPresent(), IsolateCreateCallback,
        nullptr,  // Isolate interrupt callback.
        nullptr, IsolateShutdownCallback, ThreadExitCallback,
        // File IO callbacks.
        nullptr, nullptr, nullptr, nullptr,
        // Entroy source
        nullptr,
        // VM service assets archive
        GetVMServiceAssetsArchiveCallback);
    LOG_IF(ERROR, init_error != nullptr)
        << "Error while initializing the Dart VM: " << init_error;
    CHECK(init_error == nullptr);
    free(init_error);

    // Send the earliest available timestamp in the application lifecycle to
    // timeline. The difference between this timestamp and the time we render the
    // very first frame gives us a good idea about Flutter's startup time.
    if (blink::engine_main_enter_ts != 0) {
      Dart_TimelineEvent("FlutterEngineMainEnter",    // label
                         blink::engine_main_enter_ts, // timestamp0
                         0,                           // timestamp1_or_async_id
                         Dart_Timeline_Event_Instant, // event type
                         0,                           // argument_count
                         nullptr,                     // argument_names
                         nullptr                      // argument_values
                         );
    }
  }

  // Allow streaming of stdout and stderr by the Dart vm.
  Dart_SetServiceStreamCallbacks(&ServiceStreamListenCallback,
                                 &ServiceStreamCancelCallback);
}

}  // namespace blink
