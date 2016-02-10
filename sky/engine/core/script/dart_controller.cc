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

void CallHandleMessage(base::WeakPtr<DartState> dart_state) {
  TRACE_EVENT0("flutter", "CallHandleMessage");

  if (!dart_state)
    return;

  DartIsolateScope scope(dart_state->isolate());
  DartApiScope dart_api_scope;
  LogIfError(Dart_HandleMessage());
}

void MessageNotifyCallback(Dart_Isolate dest_isolate) {
  DCHECK(Platform::current());
  Platform::current()->GetUITaskRunner()->PostTask(FROM_HERE,
      base::Bind(&CallHandleMessage, DartState::From(dest_isolate)->GetWeakPtr()));
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

void DartController::DidLoadMainLibrary(std::string name) {
  DCHECK(Dart_CurrentIsolate() == dart_state()->isolate());
  DartApiScope dart_api_scope;

  CHECK(!LogIfError(Dart_FinalizeLoading(true)));

  Dart_Handle library = Dart_LookupLibrary(ToDart(name));
  if (LogIfError(library))
    exit(1);
  if (DartInvokeField(library, "main", {}))
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
  DART_CHECK_VALID(library);
  DartInvokeField(library, "main", {});
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
  DartInvokeField(library, "main", {});
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
  Dart_SetMessageNotifyCallback(MessageNotifyCallback);
  CHECK(isolate) << error;
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
