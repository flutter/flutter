// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/script/dart_controller.h"

#include "dart/runtime/include/dart_tools_api.h"
#include "flutter/tonic/dart_debugger.h"
#include "flutter/tonic/dart_dependency_catcher.h"
#include "flutter/tonic/dart_io.h"
#include "flutter/tonic/dart_library_loader.h"
#include "flutter/tonic/dart_snapshot_loader.h"
#include "flutter/tonic/dart_state.h"
#include "glue/trace_event.h"
#include "lib/tonic/dart_class_library.h"
#include "lib/tonic/dart_message_handler.h"
#include "lib/tonic/dart_wrappable.h"
#include "lib/tonic/logging/dart_error.h"
#include "lib/tonic/logging/dart_invoke.h"
#include "lib/tonic/scopes/dart_api_scope.h"
#include "lib/tonic/scopes/dart_isolate_scope.h"
#include "mojo/public/cpp/system/data_pipe.h"
#include "sky/engine/bindings/dart_mojo_internal.h"
#include "sky/engine/bindings/dart_runtime_hooks.h"
#include "sky/engine/bindings/dart_ui.h"
#include "sky/engine/core/script/dart_init.h"
#include "sky/engine/core/script/dart_service_isolate.h"
#include "sky/engine/core/script/ui_dart_state.h"
#include "sky/engine/public/platform/Platform.h"
#include "sky/engine/public/platform/sky_settings.h"
#include "sky/engine/wtf/MakeUnique.h"

#ifdef OS_ANDROID
#include "flutter/lib/jni/dart_jni.h"
#endif

using tonic::LogIfError;
using tonic::ToDart;

namespace blink {

DartController::DartController() : ui_dart_state_(nullptr) {}

DartController::~DartController() {
  if (ui_dart_state_) {
    // Don't use a tonic::DartIsolateScope here since we never exit the isolate.
    Dart_EnterIsolate(ui_dart_state_->isolate());
    // Clear the message notify callback.
    Dart_SetMessageNotifyCallback(nullptr);
    Dart_ShutdownIsolate();  // deletes ui_dart_state_
    ui_dart_state_ = nullptr;
  }
}

bool DartController::SendStartMessage(Dart_Handle root_library) {
  {
    // Temporarily exit the isolate while we make it runnable.
    Dart_Isolate isolate = dart_state()->isolate();
    FTL_DCHECK(Dart_CurrentIsolate() == isolate);
    Dart_ExitIsolate();
    Dart_IsolateMakeRunnable(isolate);
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
  Dart_Handle main_closure =
      Dart_Invoke(ui_library, ToDart("_getMainClosure"), 0, NULL);
  if (LogIfError(main_closure))
    return true;

  // Send the start message containing the entry point by calling
  // _startMainIsolate in dart:isolate.
  const intptr_t kNumIsolateArgs = 2;
  Dart_Handle isolate_args[kNumIsolateArgs];
  isolate_args[0] = main_closure;
  isolate_args[1] = Dart_Null();
  Dart_Handle result = Dart_Invoke(isolate_lib, ToDart("_startMainIsolate"),
                                   kNumIsolateArgs, isolate_args);
  return LogIfError(result);
}

void DartController::DidLoadMainLibrary(std::string name) {
  FTL_DCHECK(Dart_CurrentIsolate() == dart_state()->isolate());
  tonic::DartApiScope dart_api_scope;

  FTL_CHECK(!LogIfError(Dart_FinalizeLoading(true)));

  Dart_Handle library = Dart_LookupLibrary(ToDart(name));
  if (LogIfError(library))
    exit(1);
  if (SendStartMessage(library))
    exit(1);
}

void DartController::DidLoadSnapshot() {
  TRACE_EVENT0("flutter", "DartController::DidLoadSnapshot");

  FTL_DCHECK(Dart_CurrentIsolate() == nullptr);
  snapshot_loader_ = nullptr;

  Dart_Isolate isolate = dart_state()->isolate();
  tonic::DartIsolateScope isolate_scope(isolate);
  tonic::DartApiScope dart_api_scope;
  Dart_Handle library = Dart_RootLibrary();
  if (LogIfError(library))
    exit(1);
  if (SendStartMessage(library))
    exit(1);
}

void DartController::RunFromPrecompiledSnapshot() {
  DidLoadSnapshot();
}

void DartController::RunFromSnapshot(
    mojo::ScopedDataPipeConsumerHandle snapshot) {
  snapshot_loader_ = WTF::MakeUnique<DartSnapshotLoader>(dart_state());
  snapshot_loader_->LoadSnapshot(snapshot.Pass(),
                                 [this]() { DidLoadSnapshot(); });
}

void DartController::RunFromSnapshotBuffer(const uint8_t* buffer, size_t size) {
  DartState::Scope scope(dart_state());
  LogIfError(Dart_LoadScriptFromSnapshot(buffer, size));
  Dart_Handle library = Dart_RootLibrary();
  if (LogIfError(library))
    exit(1);
  if (SendStartMessage(library))
    exit(1);
}

void DartController::RunFromLibrary(std::string name,
                                    DartLibraryProvider* library_provider) {
  DartState::Scope scope(dart_state());

  DartLibraryLoader& loader = dart_state()->library_loader();
  loader.set_library_provider(library_provider);

  DartDependencyCatcher dependency_catcher(loader);
  loader.LoadScript(name);
  loader.WaitForDependencies(dependency_catcher.dependencies(),
                             [this, name]() { DidLoadMainLibrary(name); });
}

void DartController::CreateIsolateFor(std::unique_ptr<UIDartState> state) {
  char* error = nullptr;
  Dart_Isolate isolate = Dart_CreateIsolate(
      state->url().c_str(), "main",
      reinterpret_cast<uint8_t*>(DART_SYMBOL(kDartIsolateSnapshotBuffer)),
      nullptr, static_cast<DartState*>(state.get()), &error);
  FTL_CHECK(isolate) << error;
  ui_dart_state_ = state.release();
  auto& message_handler = dart_state()->message_handler();
  FTL_DCHECK(Platform::current());
  message_handler.Initialize(
      ftl::RefPtr<ftl::TaskRunner>(Platform::current()->GetUITaskRunner()));

  Dart_SetShouldPauseOnStart(SkySettings::Get().start_paused);
  ui_dart_state_->SetIsolate(isolate);
  FTL_CHECK(!LogIfError(Dart_SetLibraryTagHandler(DartLibraryTagHandler)));

  {
    tonic::DartApiScope dart_api_scope;
    DartIO::InitForIsolate();
    DartUI::InitForIsolate();
    DartMojoInternal::InitForIsolate();
    DartRuntimeHooks::Install(DartRuntimeHooks::MainIsolate,
                              ui_dart_state_->url().c_str());

    dart_state()->class_library().add_provider(
        "ui",
        WTF::MakeUnique<tonic::DartClassProvider>(dart_state(), "dart:ui"));

#ifdef OS_ANDROID
    DartJni::InitForIsolate();
    dart_state()->class_library().add_provider(
        "jni",
        WTF::MakeUnique<tonic::DartClassProvider>(dart_state(), "dart:jni"));
#endif
  }
  Dart_ExitIsolate();
}

}  // namespace blink
