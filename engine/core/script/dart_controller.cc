// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/script/dart_controller.h"

#include "base/bind.h"
#include "base/logging.h"
#include "base/single_thread_task_runner.h"
#include "base/trace_event/trace_event.h"
#include "sky/engine/bindings/builtin.h"
#include "sky/engine/bindings/builtin_natives.h"
#include "sky/engine/bindings/builtin_sky.h"
#include "sky/engine/core/script/dart_debugger.h"
#include "sky/engine/core/script/dart_init.h"
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

namespace blink {
namespace {

void CreateEmptyRootLibraryIfNeeded() {
  if (Dart_IsNull(Dart_RootLibrary())) {
    Dart_LoadScript(Dart_NewStringFromCString("dart:empty"), Dart_EmptyString(),
                    0, 0);
  }
}

void CallHandleMessage(base::WeakPtr<DartState> dart_state) {
  TRACE_EVENT0("sky", "CallHandleMessage");

  if (!dart_state)
    return;

  DartIsolateScope scope(dart_state->isolate());
  DartApiScope api_scope;
  LogIfError(Dart_HandleMessage());
}

void MessageNotifyCallback(Dart_Isolate dest_isolate) {
  DCHECK(Platform::current());
  Platform::current()->mainThreadTaskRunner()->PostTask(FROM_HERE,
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
    dom_dart_state_.clear();
  }
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
  loader.LoadLibrary(name.toUTF8());
  loader.WaitForDependencies(dependency_catcher.dependencies(),
                             base::Bind(&DartController::DidLoadMainLibrary,
                                        weak_factory_.GetWeakPtr(), name));
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
  CHECK(!LogIfError(Dart_SetLibraryTagHandler(DartLibraryTagHandler)));

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

} // namespace blink
