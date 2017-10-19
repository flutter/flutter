// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/runtime/dart_controller.h"

#include <utility>

#include "flutter/common/settings.h"
#include "flutter/common/threads.h"
#include "flutter/glue/trace_event.h"
#include "flutter/lib/io/dart_io.h"
#include "flutter/lib/ui/dart_runtime_hooks.h"
#include "flutter/lib/ui/dart_ui.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "flutter/runtime/dart_init.h"
#include "flutter/runtime/dart_service_isolate.h"
#include "lib/fxl/files/directory.h"
#include "lib/fxl/files/path.h"
#include "lib/tonic/dart_class_library.h"
#include "lib/tonic/dart_message_handler.h"
#include "lib/tonic/dart_state.h"
#include "lib/tonic/dart_wrappable.h"
#include "lib/tonic/file_loader/file_loader.h"
#include "lib/tonic/logging/dart_error.h"
#include "lib/tonic/logging/dart_invoke.h"
#include "lib/tonic/scopes/dart_api_scope.h"
#include "lib/tonic/scopes/dart_isolate_scope.h"
#include "third_party/dart/runtime/include/dart_tools_api.h"

using tonic::LogIfError;
using tonic::ToDart;

namespace blink {
namespace {

// TODO(abarth): Consider adding this to //garnet/public/lib/fxl.
std::string ResolvePath(std::string path) {
  if (!path.empty() && path[0] == '/')
    return path;
  return files::SimplifyPath(files::GetCurrentDirectory() + "/" + path);
}

}  // namespace

DartController::DartController()
    : ui_dart_state_(nullptr), platform_kernel_bytes(nullptr) {}

DartController::~DartController() {
  if (ui_dart_state_) {
    ui_dart_state_->set_isolate_client(nullptr);

    // Don't use a tonic::DartIsolateScope here since we never exit the isolate.
    Dart_EnterIsolate(ui_dart_state_->isolate());
    // Clear the message notify callback.
    Dart_SetMessageNotifyCallback(nullptr);
    Dart_ShutdownIsolate();
    delete ui_dart_state_;
  }
  if (platform_kernel_bytes) {
    free(platform_kernel_bytes);
  }
}

const std::string DartController::main_entrypoint_ = "main";

bool DartController::SendStartMessage(Dart_Handle root_library,
                                      const std::string& entrypoint) {
  if (LogIfError(root_library))
    return true;

  {
    // Temporarily exit the isolate while we make it runnable.
    Dart_Isolate isolate = dart_state()->isolate();
    FXL_DCHECK(Dart_CurrentIsolate() == isolate);
    Dart_ExitIsolate();
    Dart_IsolateMakeRunnable(isolate);
    Dart_EnterIsolate(isolate);
  }

  // In order to support pausing the isolate at start, we indirectly invoke
  // main by sending a message to the isolate.

  // Get the closure of main().
  Dart_Handle main_closure = Dart_GetClosure(
      root_library, Dart_NewStringFromCString(entrypoint.c_str()));
  if (LogIfError(main_closure))
    return true;

  // Grab the 'dart:isolate' library.
  Dart_Handle isolate_lib = Dart_LookupLibrary(ToDart("dart:isolate"));
  DART_CHECK_VALID(isolate_lib);

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

static void CopyVectorBytes(const std::vector<uint8_t>& vector,
                            uint8_t*& bytes) {
  bytes = (uint8_t*)malloc(vector.size());
  memcpy(bytes, vector.data(), vector.size());
}

static void ReleaseFetchedBytes(uint8_t* buffer) {
  free(buffer);
}

tonic::DartErrorHandleType DartController::RunFromKernel(
    const std::vector<uint8_t>& kernel,
    const std::string& entrypoint) {
  tonic::DartState::Scope scope(dart_state());
  tonic::DartErrorHandleType error = tonic::kNoError;
  if (Dart_IsNull(Dart_RootLibrary())) {
    // Copy kernel bytes and pass ownership of the copy to the Dart_LoadKernel,
    // which is expected to release them.
    uint8_t* kernel_bytes = nullptr;
    CopyVectorBytes(kernel, kernel_bytes);

    Dart_Handle result = Dart_LoadKernel(Dart_ReadKernelBinary(
        kernel_bytes, kernel.size(), ReleaseFetchedBytes));
    LogIfError(result);
    error = tonic::GetErrorHandleType(result);
  }
  if (SendStartMessage(Dart_RootLibrary(), entrypoint)) {
    return tonic::kUnknownErrorType;
  }
  return error;
}

tonic::DartErrorHandleType DartController::RunFromPrecompiledSnapshot(
    const std::string& entrypoint) {
  TRACE_EVENT0("flutter", "DartController::RunFromPrecompiledSnapshot");
  FXL_DCHECK(Dart_CurrentIsolate() == nullptr);
  tonic::DartState::Scope scope(dart_state());
  if (SendStartMessage(Dart_RootLibrary(), entrypoint)) {
    return tonic::kUnknownErrorType;
  }
  return tonic::kNoError;
}

tonic::DartErrorHandleType DartController::RunFromScriptSnapshot(
    const uint8_t* buffer,
    size_t size,
    const std::string& entrypoint) {
  tonic::DartState::Scope scope(dart_state());
  tonic::DartErrorHandleType error = tonic::kNoError;
  if (Dart_IsNull(Dart_RootLibrary())) {
    Dart_Handle result = Dart_LoadScriptFromSnapshot(buffer, size);
    LogIfError(result);
    error = tonic::GetErrorHandleType(result);
  }
  if (SendStartMessage(Dart_RootLibrary(), entrypoint)) {
    return tonic::kUnknownErrorType;
  }
  return error;
}

tonic::DartErrorHandleType DartController::RunFromSource(
    const std::string& main,
    const std::string& packages) {
  tonic::DartState::Scope scope(dart_state());
  tonic::DartErrorHandleType error = tonic::kNoError;
  if (Dart_IsNull(Dart_RootLibrary())) {
    tonic::FileLoader& loader = dart_state()->file_loader();
    if (!packages.empty() && !loader.LoadPackagesMap(ResolvePath(packages)))
      FXL_LOG(WARNING) << "Failed to load package map: " << packages;
    Dart_Handle result = loader.LoadScript(main);
    LogIfError(result);
    error = tonic::GetErrorHandleType(result);
  }
  if (SendStartMessage(Dart_RootLibrary())) {
    return tonic::kCompilationErrorType;
  }
  return error;
}

void DartController::CreateIsolateFor(
    const std::string& script_uri,
    const uint8_t* isolate_snapshot_data,
    const uint8_t* isolate_snapshot_instr,
    const std::vector<uint8_t>& platform_kernel,
    std::unique_ptr<UIDartState> state) {
  char* error = nullptr;

  Dart_Isolate isolate;
  if (!platform_kernel.empty()) {
    // Copy kernel bytes so they won't go away after we exit this method.
    // This is needed because original kernel data has to be available
    // during code execution.
    CopyVectorBytes(platform_kernel, platform_kernel_bytes);

    isolate = Dart_CreateIsolateFromKernel(
        script_uri.c_str(), "main",
        Dart_ReadKernelBinary(platform_kernel_bytes, platform_kernel.size(),
                              ReleaseFetchedBytes),
        nullptr /* flags */, static_cast<tonic::DartState*>(state.get()),
        &error);
  } else {
    isolate =
        Dart_CreateIsolate(script_uri.c_str(), "main", isolate_snapshot_data,
                           isolate_snapshot_instr, nullptr,
                           static_cast<tonic::DartState*>(state.get()), &error);
  }
  FXL_CHECK(isolate) << error;
  ui_dart_state_ = state.release();
  ui_dart_state_->set_is_controller_state(true);
  dart_state()->message_handler().Initialize(blink::Threads::UI());

  Dart_SetShouldPauseOnStart(Settings::Get().start_paused);

  ui_dart_state_->set_debug_name_prefix(script_uri);
  ui_dart_state_->SetIsolate(isolate);
  FXL_CHECK(!LogIfError(
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
  }
  Dart_ExitIsolate();
}

}  // namespace blink
