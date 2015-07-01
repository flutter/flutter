// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/script/dart_controller.h"

#include "base/bind.h"
#include "base/logging.h"
#include "base/single_thread_task_runner.h"
#include "base/trace_event/trace_event.h"
#include "dart/runtime/bin/embedded_dart_io.h"
#include "dart/runtime/include/dart_mirrors_api.h"
#include "gen/sky/platform/RuntimeEnabledFeatures.h"
#include "sky/engine/bindings/builtin.h"
#include "sky/engine/bindings/builtin_natives.h"
#include "sky/engine/bindings/builtin_sky.h"
#include "sky/engine/core/app/AbstractModule.h"
#include "sky/engine/core/app/Module.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/loader/FrameLoaderClient.h"
#include "sky/engine/core/script/dart_debugger.h"
#include "sky/engine/core/script/dart_service_isolate.h"
#include "sky/engine/core/script/dom_dart_state.h"
#include "sky/engine/public/platform/Platform.h"
#include "sky/engine/tonic/dart_api_scope.h"
#include "sky/engine/tonic/dart_class_library.h"
#include "sky/engine/tonic/dart_dependency_catcher.h"
#include "sky/engine/tonic/dart_error.h"
#include "sky/engine/tonic/dart_gc_controller.h"
#include "sky/engine/tonic/dart_invoke.h"
#include "sky/engine/tonic/dart_isolate_scope.h"
#include "sky/engine/tonic/dart_library_loader.h"
#include "sky/engine/tonic/dart_snapshot_loader.h"
#include "sky/engine/tonic/dart_state.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/text/TextPosition.h"

namespace blink {
namespace {

void CreateEmptyRootLibraryIfNeeded() {
  if (Dart_IsNull(Dart_RootLibrary())) {
    Dart_LoadScript(Dart_NewStringFromCString("dart:empty"), Dart_EmptyString(),
                    0, 0);
  }
}

} // namespace

#if ENABLE(DART_STRICT)
static const char* kCheckedModeArgs[] = {"--enable_asserts",
                                         "--enable_type_checks",
                                         "--error_on_bad_type",
                                         "--error_on_bad_override",
#if WTF_OS_IOS
                                         "--no-profile"
#endif
};
#endif

extern const uint8_t* kDartVmIsolateSnapshotBuffer;
extern const uint8_t* kDartIsolateSnapshotBuffer;

DartController::DartController() : weak_factory_(this) {
}

DartController::~DartController() {
}

void DartController::DidLoadMainLibrary(String name) {
  DCHECK(Dart_CurrentIsolate() == dart_state()->isolate());
  DartApiScope dart_api_scope;

  if (LogIfError(Dart_FinalizeLoading(true)))
    return;

  Dart_Handle library = Dart_LookupLibrary(StringToDart(dart_state(), name));
  // TODO(eseidel): We need to load a 404 page instead!
  if (LogIfError(library))
    return;
  DartInvokeAppField(library, ToDart("main"), 0, nullptr);
}

void DartController::DidLoadSnapshot() {
  DCHECK(Dart_CurrentIsolate() == nullptr);
  snapshot_loader_ = nullptr;

  Dart_Isolate isolate = dart_state()->isolate();
  DartIsolateScope isolate_scope(isolate);
  DartApiScope dart_api_scope;

  Dart_Handle library = Dart_RootLibrary();
  if (LogIfError(library))
    return;
  DartInvokeAppField(library, ToDart("main"), 0, nullptr);
}

void DartController::RunFromSnapshot(
    mojo::ScopedDataPipeConsumerHandle snapshot) {
  snapshot_loader_ = adoptPtr(new DartSnapshotLoader(dart_state()));
  snapshot_loader_->LoadSnapshot(
      snapshot.Pass(),
      base::Bind(&DartController::DidLoadSnapshot, weak_factory_.GetWeakPtr()));
}

void DartController::RunFromLibrary(const String& name,
                                    DartLibraryProvider* library_provider) {
  DartState::Scope scope(dart_state());
  CreateEmptyRootLibraryIfNeeded();

  DartLibraryLoader& loader = dart_state()->library_loader();
  loader.set_library_provider(library_provider);

  DartDependencyCatcher dependency_catcher(loader);
  loader.LoadLibrary(name);
  loader.WaitForDependencies(dependency_catcher.dependencies(),
                             base::Bind(&DartController::DidLoadMainLibrary,
                                        weak_factory_.GetWeakPtr(), name));
}

static void UnhandledExceptionCallback(Dart_Handle error) {
  LOG(ERROR) << Dart_GetError(error);
}

static Dart_Handle LibraryTagHandler(Dart_LibraryTag tag,
                                     Dart_Handle library,
                                     Dart_Handle url) {
  return DartLibraryLoader::HandleLibraryTag(tag, library, url);
}

static void IsolateShutdownCallback(void* callback_data) {
  // TODO(dart)
}

static bool IsServiceIsolateURL(const char* url_name) {
  return url_name != nullptr &&
      String(url_name) == DART_VM_SERVICE_ISOLATE_NAME;
}

static void EnsureHandleWatcherStarted() {
  static bool handle_watcher_started = false;
  if (handle_watcher_started)
    return;

  // TODO(dart): Call Dart_Cleanup (ensure the handle watcher isolate is closed)
  // during shutdown.
  Dart_Handle mojo_core_lib =
      Builtin::LoadAndCheckLibrary(Builtin::kMojoInternalLibrary);
  CHECK(!LogIfError((mojo_core_lib)));
  Dart_Handle handle_watcher_type = Dart_GetType(
      mojo_core_lib,
      Dart_NewStringFromCString("MojoHandleWatcher"),
      0,
      nullptr);
  CHECK(!LogIfError(handle_watcher_type));
  CHECK(!LogIfError(Dart_Invoke(
      handle_watcher_type,
      Dart_NewStringFromCString("_start"),
      0,
      nullptr)));

  // RunLoop until the handle watcher isolate is spun-up.
  CHECK(!LogIfError(Dart_RunLoop()));
  handle_watcher_started = true;
}

// TODO(rafaelw): Right now this only supports the creation of the handle
// watcher isolate and the service isolate. Presumably, we'll want application
// isolates to spawn their own isolates.
static Dart_Isolate IsolateCreateCallback(const char* script_uri,
                                          const char* main,
                                          const char* package_root,
                                          Dart_IsolateFlags* flags,
                                          void* callback_data,
                                          char** error) {
  if (IsServiceIsolateURL(script_uri)) {
    CHECK(kDartIsolateSnapshotBuffer);
    DartState* dart_state = new DartState();
    Dart_Isolate isolate =
        Dart_CreateIsolate(script_uri, "main", kDartIsolateSnapshotBuffer,
                           nullptr, nullptr, error);
    CHECK(isolate) << error;
    dart_state->SetIsolate(isolate);
    CHECK(Dart_IsServiceIsolate(isolate));
    CHECK(!LogIfError(Dart_SetLibraryTagHandler(LibraryTagHandler)));
    {
      DartApiScope apiScope;
      Builtin::SetNativeResolver(Builtin::kBuiltinLibrary);
      Builtin::SetNativeResolver(Builtin::kMojoInternalLibrary);
      Builtin::SetNativeResolver(Builtin::kIOLibrary);
      BuiltinNatives::Init(BuiltinNatives::DartIOIsolate);
      // Start the handle watcher from the service isolate so it isn't available
      // for debugging or general Observatory interaction.
      EnsureHandleWatcherStarted();
      if (RuntimeEnabledFeatures::observatoryEnabled()) {
        std::string ip = "127.0.0.1";
        const intptr_t port = 8181;
        const bool service_isolate_booted =
            DartServiceIsolate::Startup(ip, port, LibraryTagHandler, error);
        CHECK(service_isolate_booted) << error;
      }
    }
    Dart_ExitIsolate();
    return isolate;
  }

  // Create & start the handle watcher isolate
  CHECK(kDartIsolateSnapshotBuffer);
  // TODO(abarth): Who deletes this DartState instance?
  DartState* dart_state = new DartState();
  Dart_Isolate isolate =
      Dart_CreateIsolate("sky:handle_watcher", "", kDartIsolateSnapshotBuffer,
                         nullptr, dart_state, error);
  CHECK(isolate) << error;
  dart_state->SetIsolate(isolate);

  CHECK(!LogIfError(Dart_SetLibraryTagHandler(LibraryTagHandler)));

  {
    DartApiScope apiScope;
    Builtin::SetNativeResolver(Builtin::kBuiltinLibrary);
    Builtin::SetNativeResolver(Builtin::kMojoInternalLibrary);
    Builtin::SetNativeResolver(Builtin::kIOLibrary);

    if (!script_uri)
      CreateEmptyRootLibraryIfNeeded();
  }

  Dart_ExitIsolate();

  CHECK(Dart_IsolateMakeRunnable(isolate));
  return isolate;
}

static void CallHandleMessage(base::WeakPtr<DartState> dart_state) {
  TRACE_EVENT0("sky", "CallHandleMessage");

  if (!dart_state)
    return;

  DartIsolateScope scope(dart_state->isolate());
  DartApiScope api_scope;
  LogIfError(Dart_HandleMessage());
}

static void MessageNotifyCallback(Dart_Isolate dest_isolate) {
  DCHECK(Platform::current());
  Platform::current()->mainThreadTaskRunner()->PostTask(FROM_HERE,
      base::Bind(&CallHandleMessage, DartState::From(dest_isolate)->GetWeakPtr()));
}

void DartController::CreateIsolateFor(PassOwnPtr<DOMDartState> state) {
  CHECK(kDartIsolateSnapshotBuffer);
  char* error = nullptr;
  dom_dart_state_ = state;
  Dart_Isolate isolate = Dart_CreateIsolate(
      dom_dart_state_->url().utf8().data(), "main", kDartIsolateSnapshotBuffer,
      nullptr, static_cast<DartState*>(dom_dart_state_.get()), &error);
  Dart_SetMessageNotifyCallback(MessageNotifyCallback);
  CHECK(isolate) << error;
  dom_dart_state_->SetIsolate(isolate);
  Dart_SetGcCallbacks(DartGCPrologue, DartGCEpilogue);
  CHECK(!LogIfError(Dart_SetLibraryTagHandler(LibraryTagHandler)));

  {
    DartApiScope apiScope;

    Builtin::SetNativeResolver(Builtin::kBuiltinLibrary);
    Builtin::SetNativeResolver(Builtin::kMojoInternalLibrary);
    Builtin::SetNativeResolver(Builtin::kIOLibrary);
    BuiltinNatives::Init(BuiltinNatives::MainIsolate);

    builtin_sky_ = adoptPtr(new BuiltinSky(dart_state()));
    dart_state()->class_library().set_provider(builtin_sky_.get());

    if (dart_state()->document())
      builtin_sky_->InstallWindow(dart_state());

    EnsureHandleWatcherStarted();
  }
  Dart_ExitIsolate();
}

void DartController::InstallView(View* view) {
  DartIsolateScope isolate_scope(dart_state()->isolate());
  DartApiScope dart_api_scope;

  builtin_sky_->InstallView(view);
}

void DartController::ClearForClose() {
  // Don't use a DartIsolateScope here since we never exit the isolate.
  Dart_EnterIsolate(dom_dart_state_->isolate());
  Dart_ShutdownIsolate();
  dom_dart_state_->SetIsolate(nullptr);
  dom_dart_state_.clear();
}

void DartController::InitVM() {
  int argc = 0;
  const char** argv = nullptr;

#if ENABLE(DART_STRICT)
  argc = arraysize(kCheckedModeArgs);
  argv = kCheckedModeArgs;
#endif

  dart::bin::BootstrapDartIo();

  CHECK(Dart_SetVMFlags(argc, argv));
  // This should be called before calling Dart_Initialize.
  DartDebugger::InitDebugger();
  CHECK(Dart_Initialize(kDartVmIsolateSnapshotBuffer,
                        IsolateCreateCallback,
                        nullptr,  // Isolate interrupt callback.
                        UnhandledExceptionCallback, IsolateShutdownCallback,
                        // File IO callbacks.
                        nullptr, nullptr, nullptr, nullptr, nullptr));
  // Wait for load port- ensures handle watcher and service isolates are
  // running.
  Dart_ServiceWaitForLoadPort();
}

} // namespace blink
