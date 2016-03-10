// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/script/dart_init.h"

#include <dlfcn.h>

#include "base/bind.h"
#include "base/command_line.h"
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

const char kFileUriPrefix[] = "file://";

const char kDartFlags[] = "dart-flags";

void IsolateShutdownCallback(void* callback_data) {
  DartState* dart_state = static_cast<DartState*>(callback_data);
  delete dart_state;
}

bool IsServiceIsolateURL(const char* url_name) {
  return url_name != nullptr &&
         String(url_name) == DART_VM_SERVICE_ISOLATE_NAME;
}

// TODO(rafaelw): Right now this only supports the creation of the handle
// watcher isolate and the service isolate. Presumably, we'll want application
// isolates to spawn their own isolates.
Dart_Isolate IsolateCreateCallback(const char* script_uri,
                                   const char* main,
                                   const char* package_root,
                                   const char* package_config,
                                   Dart_IsolateFlags* flags,
                                   void* callback_data,
                                   char** error) {
  TRACE_EVENT0("flutter", __func__);
  if (IsServiceIsolateURL(script_uri)) {
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
    }
    Dart_ExitIsolate();
    return isolate;
  }

  std::vector<uint8_t> snapshot_data;
  if (!IsRunningPrecompiledCode()) {
    CHECK(base::StartsWith(script_uri, kFileUriPrefix,
                           base::CompareCase::SENSITIVE));
    base::FilePath flx_path(script_uri + strlen(kFileUriPrefix));
    scoped_refptr<ZipAssetBundle> zip_asset_bundle(
        new ZipAssetBundle(flx_path, nullptr));
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

void InitDartVM() {
  TRACE_EVENT0("flutter", __func__);

  {
    TRACE_EVENT0("flutter", "dart::bin::BootstrapDartIo");
    dart::bin::BootstrapDartIo();
  }

  DartMojoInternal::SetHandleWatcherProducerHandle(
      mojo::dart::HandleWatcher::Start());

  bool enable_checked_mode = SkySettings::Get().enable_dart_checked_mode;
#if ENABLE(DART_STRICT)
  enable_checked_mode = true;
#endif

  if (IsRunningPrecompiledCode()) {
    enable_checked_mode = false;
  }

  Vector<const char*> args;
  args.append(kDartProfilingArgs, arraysize(kDartProfilingArgs));
  
  if (!IsRunningPrecompiledCode()) {
    // The version of the VM setup to run precompiled code does not recognize
    // the mirrors or the background compilation flags. They are never enabled.
    // Make sure we dont pass in unrecognized flags.
    args.append(kDartMirrorsArgs, arraysize(kDartMirrorsArgs));
    args.append(kDartBackgroundCompilationArgs,
                arraysize(kDartBackgroundCompilationArgs));
  } else {
    args.append(kDartPrecompilationArgs, arraysize(kDartPrecompilationArgs));
  }

  if (enable_checked_mode)
    args.append(kDartCheckedModeArgs, arraysize(kDartCheckedModeArgs));

  if (SkySettings::Get().start_paused)
    args.append(kDartStartPausedArgs, arraysize(kDartStartPausedArgs));

  Vector<std::string> dart_flags;
  if (base::CommandLine::ForCurrentProcess()->HasSwitch(kDartFlags)) {
    // Instruct the VM to ignore unrecognized flags.
    args.append("--ignore-unrecognized-flags");
    // Split up dart flags by spaces.
    base::CommandLine& command_line = *base::CommandLine::ForCurrentProcess();
    std::stringstream ss(
        command_line.GetSwitchValueNative(kDartFlags));
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

  {
    TRACE_EVENT0("flutter", "DartDebugger::InitDebugger");
    // This should be called before calling Dart_Initialize.
    DartDebugger::InitDebugger();
  }

  DartUI::InitForGlobal();
#ifdef OS_ANDROID
  DartJni::InitForGlobal();
#endif

  {
    TRACE_EVENT0("flutter", "Dart_Initialize");
    CHECK(Dart_Initialize(reinterpret_cast<uint8_t*>(
                              DART_SYMBOL(kDartVmIsolateSnapshotBuffer)),
                          PrecompiledInstructionsSymbolIfPresent(),
                          PrecompiledDataSnapshotSymbolIfPresent(),
                          IsolateCreateCallback,
                          nullptr,  // Isolate interrupt callback.
                          nullptr,
                          IsolateShutdownCallback,
                          // File IO callbacks.
                          nullptr, nullptr, nullptr, nullptr,
                          // Entroy source
                          nullptr,
                          // VM service assets archive
                          GetVMServiceAssetsArchiveCallback) == nullptr);
  }

  // Allow streaming of stdout and stderr by the Dart vm.
  Dart_SetServiceStreamCallbacks(&ServiceStreamListenCallback,
                                 &ServiceStreamCancelCallback);
}

}  // namespace blink
