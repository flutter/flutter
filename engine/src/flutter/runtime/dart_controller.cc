// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/runtime/dart_controller.h"

#include <utility>

#include "dart/runtime/include/dart_tools_api.h"
#include "flutter/common/settings.h"
#include "flutter/common/threads.h"
#include "flutter/glue/trace_event.h"
#include "flutter/lib/io/dart_io.h"
#include "flutter/lib/ui/dart_runtime_hooks.h"
#include "flutter/lib/ui/dart_ui.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "flutter/runtime/dart_init.h"
#include "flutter/runtime/dart_service_isolate.h"
#include "lib/ftl/files/directory.h"
#include "lib/ftl/files/path.h"
#include "lib/tonic/dart_class_library.h"
#include "lib/tonic/dart_message_handler.h"
#include "lib/tonic/dart_state.h"
#include "lib/tonic/dart_wrappable.h"
#include "lib/tonic/debugger/dart_debugger.h"
#include "lib/tonic/file_loader/file_loader.h"
#include "lib/tonic/logging/dart_error.h"
#include "lib/tonic/logging/dart_invoke.h"
#include "lib/tonic/scopes/dart_api_scope.h"
#include "lib/tonic/scopes/dart_isolate_scope.h"

#ifdef OS_ANDROID
#include "flutter/lib/jni/dart_jni.h"
#endif

using tonic::LogIfError;
using tonic::ToDart;

namespace blink {
namespace {

// TODO(abarth): Consider adding this to //lib/ftl.
std::string ResolvePath(std::string path) {
  if (!path.empty() && path[0] == '/')
    return path;
  return files::SimplifyPath(files::GetCurrentDirectory() + "/" + path);
}

}  // namespace

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
  if (LogIfError(root_library))
    return true;

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

void DartController::RunFromPrecompiledSnapshot() {
  TRACE_EVENT0("flutter", "DartController::RunFromPrecompiledSnapshot");
  FTL_DCHECK(Dart_CurrentIsolate() == nullptr);
  tonic::DartState::Scope scope(dart_state());
  if (SendStartMessage(Dart_RootLibrary()))
    exit(1);
}

void DartController::RunFromSnapshot(const uint8_t* buffer, size_t size) {
  tonic::DartState::Scope scope(dart_state());
  LogIfError(Dart_LoadScriptFromSnapshot(buffer, size));
  if (SendStartMessage(Dart_RootLibrary()))
    exit(1);
}

void DartController::RunFromSource(const std::string& main,
                                   const std::string& packages) {
  tonic::DartState::Scope scope(dart_state());
  tonic::FileLoader& loader = dart_state()->file_loader();
  if (!packages.empty() && !loader.LoadPackagesMap(ResolvePath(packages)))
    FTL_LOG(WARNING) << "Failed to load package map: " << packages;
  LogIfError(loader.LoadScript(main));
  if (SendStartMessage(Dart_RootLibrary()))
    exit(1);
}

void DartController::CreateIsolateFor(const std::string& script_uri,
                                      std::unique_ptr<UIDartState> state) {
  char* error = nullptr;
  Dart_Isolate isolate = Dart_CreateIsolate(
      script_uri.c_str(), "main",
      reinterpret_cast<uint8_t*>(DART_SYMBOL(kIsolateSnapshot)), nullptr,
      static_cast<tonic::DartState*>(state.get()), &error);
  FTL_CHECK(isolate) << error;
  ui_dart_state_ = state.release();
  dart_state()->message_handler().Initialize(blink::Threads::UI());

  Dart_SetShouldPauseOnStart(Settings::Get().start_paused);

  ui_dart_state_->SetIsolate(isolate);
  FTL_CHECK(!LogIfError(
      Dart_SetLibraryTagHandler(tonic::DartState::HandleLibraryTag)));

  {
    tonic::DartApiScope dart_api_scope;
    DartIO::InitForIsolate();
    DartUI::InitForIsolate();
    DartRuntimeHooks::Install(DartRuntimeHooks::MainIsolate, script_uri);

    std::unique_ptr<tonic::DartClassProvider> ui_class_provider(
        new tonic::DartClassProvider(dart_state(), "dart:ui"));
    dart_state()->class_library().add_provider("ui",
                                               std::move(ui_class_provider));

#ifdef OS_ANDROID
    DartJni::InitForIsolate();
    std::unique_ptr<tonic::DartClassProvider> jni_class_provider(
        new tonic::DartClassProvider(dart_state(), "dart:jni"));
    dart_state()->class_library().add_provider("jni",
                                               std::move(jni_class_provider));
#endif
  }
  Dart_ExitIsolate();
}

}  // namespace blink
