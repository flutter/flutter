// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/script/dart_controller.h"

#include "base/bind.h"
#include "base/logging.h"
#include "base/single_thread_task_runner.h"
#include "base/trace_event/trace_event.h"
#include "dart/runtime/include/dart_tools_api.h"
#include "mojo/data_pipe_utils/data_pipe_utils.h"
#include "mojo/public/cpp/system/data_pipe.h"
#include "sky/engine/bindings/dart_mojo_internal.h"
#include "sky/engine/bindings/dart_runtime_hooks.h"
#include "sky/engine/bindings/dart_ui.h"
#include "sky/engine/core/script/dart_debugger.h"
#include "sky/engine/core/script/dart_init.h"
#include "sky/engine/core/script/dart_service_isolate.h"
#include "sky/engine/core/script/dom_dart_state.h"
#include "sky/engine/public/platform/Platform.h"
#include "sky/engine/public/platform/sky_settings.h"
#include "sky/engine/tonic/dart_api_scope.h"
#include "sky/engine/tonic/dart_class_library.h"
#include "sky/engine/tonic/dart_dependency_catcher.h"
#include "sky/engine/tonic/dart_error.h"
#include "sky/engine/tonic/dart_invoke.h"
#include "sky/engine/tonic/dart_io.h"
#include "sky/engine/tonic/dart_isolate_scope.h"
#include "sky/engine/tonic/dart_library_loader.h"
#include "sky/engine/tonic/dart_message_handler.h"
#include "sky/engine/tonic/dart_snapshot_loader.h"
#include "sky/engine/tonic/dart_state.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/MakeUnique.h"

#ifdef OS_ANDROID
#include "sky/engine/bindings/jni/dart_jni.h"
#endif

namespace blink {
namespace {

void CreateEmptyRootLibraryIfNeeded() {
  if (Dart_IsNull(Dart_RootLibrary())) {
    Dart_LoadScript(Dart_NewStringFromCString("dart:empty"), Dart_EmptyString(),
                    0, 0);
  }
}

} // namespace

DartController::DartController() : weak_factory_(this) {
}

DartController::~DartController() {
  if (dom_dart_state_) {
    // Don't use a DartIsolateScope here since we never exit the isolate.
    Dart_EnterIsolate(dom_dart_state_->isolate());
    Dart_ShutdownIsolate();
    dom_dart_state_->SetIsolate(nullptr);
    dom_dart_state_ = nullptr;
  }
}

bool DartController::SendStartMessage(Dart_Handle root_library) {
  {
    // Temporarily exit the isolate while we make it runnable.
    Dart_Isolate isolate = dart_state()->isolate();
    DCHECK(Dart_CurrentIsolate() == isolate);
    Dart_ExitIsolate();
    CHECK(Dart_IsolateMakeRunnable(isolate));
    Dart_EnterIsolate(isolate);
  }

  // In order to support pausing the isolate at start, we indirectly invoke
  // main by sending a message to the isolate.
  // Grab the 'dart:ui' library.
  Dart_Handle ui_library = Dart_LookupLibrary(ToDart("dart:ui"));
  DART_CHECK_VALID(ui_library);

  // Grab the 'dart:isolate' library.
  Dart_Handle isolate_lib = Dart_LookupLibrary(ToDart("dart:isolate"));
  DART_CHECK_VALID(isolate_lib);

  // Import the root library into the 'dart:ui' library so that we can
  // reach main.
  Dart_LibraryImportLibrary(ui_library, root_library, Dart_Null());

  // Get the closure of main().
  Dart_Handle main_closure = Dart_Invoke(ui_library,
                                         ToDart("_getMainClosure"),
                                         0,
                                         NULL);
  DART_CHECK_VALID(main_closure);

  // Send the start message containing the entry point by calling
  // _startMainIsolate in dart:isolate.
  const intptr_t kNumIsolateArgs = 2;
  Dart_Handle isolate_args[kNumIsolateArgs];
  isolate_args[0] = main_closure;
  isolate_args[1] = Dart_Null();
  Dart_Handle result = Dart_Invoke(isolate_lib,
                                   ToDart("_startMainIsolate"),
                                   kNumIsolateArgs,
                                   isolate_args);
  return LogIfError(result);
}

void DartController::DidLoadMainLibrary(std::string name) {
  DCHECK(Dart_CurrentIsolate() == dart_state()->isolate());
  DartApiScope dart_api_scope;

  CHECK(!LogIfError(Dart_FinalizeLoading(true)));

  Dart_Handle library = Dart_LookupLibrary(ToDart(name));
  if (LogIfError(library))
    exit(1);
  if (SendStartMessage(library))
    exit(1);
}

void DartController::DidLoadSnapshot() {
  TRACE_EVENT0("flutter", "DartController::DidLoadSnapshot");

  DCHECK(Dart_CurrentIsolate() == nullptr);
  snapshot_loader_ = nullptr;

  Dart_Isolate isolate = dart_state()->isolate();
  DartIsolateScope isolate_scope(isolate);
  DartApiScope dart_api_scope;
  Dart_Handle library = Dart_RootLibrary();
  if (LogIfError(library))
    return;
  SendStartMessage(library);
}

void DartController::RunFromPrecompiledSnapshot() {
  DidLoadSnapshot();
}

void DartController::RunFromSnapshot(
    mojo::ScopedDataPipeConsumerHandle snapshot) {
  snapshot_loader_ = WTF::MakeUnique<DartSnapshotLoader>(dart_state());
  snapshot_loader_->LoadSnapshot(
      snapshot.Pass(),
      base::Bind(&DartController::DidLoadSnapshot, weak_factory_.GetWeakPtr()));
}

void DartController::RunFromSnapshotBuffer(const uint8_t* buffer, size_t size) {
  DartState::Scope scope(dart_state());
  LogIfError(Dart_LoadScriptFromSnapshot(buffer, size));
  Dart_Handle library = Dart_RootLibrary();
  if (LogIfError(library))
    return;
  SendStartMessage(library);
}

void DartController::RunFromLibrary(const std::string& name,
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

void DartController::CreateIsolateFor(std::unique_ptr<DOMDartState> state) {
  char* error = nullptr;
  dom_dart_state_ = std::move(state);
  Dart_Isolate isolate = Dart_CreateIsolate(
      dom_dart_state_->url().c_str(), "main",
      reinterpret_cast<uint8_t*>(DART_SYMBOL(kDartIsolateSnapshotBuffer)),
      nullptr, static_cast<DartState*>(dom_dart_state_.get()), &error);
  CHECK(isolate) << error;
  auto& message_handler = dart_state()->message_handler();
  message_handler.set_quit_message_loop_when_isolate_exits(false);
  DCHECK(Platform::current());
  message_handler.Initialize(Platform::current()->GetUITaskRunner());

  Dart_SetShouldPauseOnStart(SkySettings::Get().start_paused);
  dom_dart_state_->SetIsolate(isolate);
  CHECK(!LogIfError(Dart_SetLibraryTagHandler(DartLibraryTagHandler)));

  {
    DartApiScope dart_api_scope;
    DartIO::InitForIsolate();
    DartUI::InitForIsolate();
    DartMojoInternal::InitForIsolate();
    DartRuntimeHooks::Install(DartRuntimeHooks::MainIsolate);

    dart_state()->class_library().add_provider(
      "ui",
      WTF::MakeUnique<DartClassProvider>(dart_state(), "dart:ui"));

#ifdef OS_ANDROID
    DartJni::InitForIsolate();
    dart_state()->class_library().add_provider(
      "jni",
      WTF::MakeUnique<DartClassProvider>(dart_state(), "dart:jni"));
#endif
  }
  Dart_ExitIsolate();
}

} // namespace blink
