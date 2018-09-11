// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/runtime/dart_service_isolate.h"

#include <string.h>

#include "flutter/fml/logging.h"
#include "flutter/runtime/embedder_resources.h"
#include "third_party/dart/runtime/include/dart_api.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_library_natives.h"
#include "third_party/tonic/logging/dart_error.h"

#define RETURN_ERROR_HANDLE(handle) \
  if (Dart_IsError(handle)) {       \
    return handle;                  \
  }

#define SHUTDOWN_ON_ERROR(handle)           \
  if (Dart_IsError(handle)) {               \
    *error = strdup(Dart_GetError(handle)); \
    Dart_ExitScope();                       \
    Dart_ShutdownIsolate();                 \
    return false;                           \
  }

namespace blink {
namespace {

static Dart_LibraryTagHandler g_embedder_tag_handler;
static tonic::DartLibraryNatives* g_natives;
static std::string observatory_uri_;

Dart_NativeFunction GetNativeFunction(Dart_Handle name,
                                      int argument_count,
                                      bool* auto_setup_scope) {
  FML_CHECK(g_natives);
  return g_natives->GetNativeFunction(name, argument_count, auto_setup_scope);
}

const uint8_t* GetSymbol(Dart_NativeFunction native_function) {
  FML_CHECK(g_natives);
  return g_natives->GetSymbol(native_function);
}

}  // namespace

void DartServiceIsolate::NotifyServerState(Dart_NativeArguments args) {
  Dart_Handle exception = nullptr;
  std::string uri =
      tonic::DartConverter<std::string>::FromArguments(args, 0, exception);
  if (!exception) {
    observatory_uri_ = uri;
  }
}

std::string DartServiceIsolate::GetObservatoryUri() {
  return observatory_uri_;
}

void DartServiceIsolate::Shutdown(Dart_NativeArguments args) {
  // NO-OP.
}

bool DartServiceIsolate::Startup(std::string server_ip,
                                 intptr_t server_port,
                                 Dart_LibraryTagHandler embedder_tag_handler,
                                 bool disable_origin_check,
                                 char** error) {
  Dart_Isolate isolate = Dart_CurrentIsolate();
  FML_CHECK(isolate);

  // Remember the embedder's library tag handler.
  g_embedder_tag_handler = embedder_tag_handler;
  FML_CHECK(g_embedder_tag_handler);

  // Setup native entries.
  if (!g_natives) {
    g_natives = new tonic::DartLibraryNatives();
    g_natives->Register({
        {"VMServiceIO_NotifyServerState", NotifyServerState, 1, true},
        {"VMServiceIO_Shutdown", Shutdown, 0, true},
    });
  }

  Dart_Handle uri = Dart_NewStringFromCString("dart:vmservice_io");
  Dart_Handle library = Dart_LookupLibrary(uri);
  SHUTDOWN_ON_ERROR(library);
  Dart_Handle result = Dart_SetRootLibrary(library);
  SHUTDOWN_ON_ERROR(result);
  result = Dart_SetNativeResolver(library, GetNativeFunction, GetSymbol);
  SHUTDOWN_ON_ERROR(result);

  // Make runnable.
  Dart_ExitScope();
  Dart_ExitIsolate();
  *error = Dart_IsolateMakeRunnable(isolate);
  if (*error) {
    Dart_EnterIsolate(isolate);
    Dart_ShutdownIsolate();
    return false;
  }
  Dart_EnterIsolate(isolate);
  Dart_EnterScope();

  library = Dart_RootLibrary();
  SHUTDOWN_ON_ERROR(library);

  // Set the HTTP server's ip.
  result = Dart_SetField(library, Dart_NewStringFromCString("_ip"),
                         Dart_NewStringFromCString(server_ip.c_str()));
  SHUTDOWN_ON_ERROR(result);
  // If we have a port specified, start the server immediately.
  bool auto_start = server_port >= 0;
  if (server_port < 0) {
    // Adjust server_port to port 0 which will result in the first available
    // port when the HTTP server is started.
    server_port = 0;
  }
  // Set the HTTP's servers port.
  result = Dart_SetField(library, Dart_NewStringFromCString("_port"),
                         Dart_NewInteger(server_port));
  SHUTDOWN_ON_ERROR(result);
  result = Dart_SetField(library, Dart_NewStringFromCString("_autoStart"),
                         Dart_NewBoolean(auto_start));
  SHUTDOWN_ON_ERROR(result);
  result =
      Dart_SetField(library, Dart_NewStringFromCString("_originCheckDisabled"),
                    Dart_NewBoolean(disable_origin_check));
  SHUTDOWN_ON_ERROR(result);
  return true;
}

}  // namespace blink
