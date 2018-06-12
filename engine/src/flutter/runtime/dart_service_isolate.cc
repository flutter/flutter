// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/runtime/dart_service_isolate.h"

#include <string.h>

#include "flutter/runtime/embedder_resources.h"
#include "lib/fxl/logging.h"
#include "lib/tonic/converter/dart_converter.h"
#include "lib/tonic/dart_library_natives.h"
#include "lib/tonic/logging/dart_error.h"
#include "third_party/dart/runtime/include/dart_api.h"

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

#define kLibrarySourceNamePrefix "/vmservice"

namespace flutter {
namespace runtime {
extern ResourcesEntry __flutter_embedded_service_isolate_resources_[];
}
}  // namespace flutter

namespace blink {
namespace {

static Dart_LibraryTagHandler g_embedder_tag_handler;
static tonic::DartLibraryNatives* g_natives;
static EmbedderResources* g_resources;
static std::string observatory_uri_;

Dart_NativeFunction GetNativeFunction(Dart_Handle name,
                                      int argument_count,
                                      bool* auto_setup_scope) {
  FXL_CHECK(g_natives);
  return g_natives->GetNativeFunction(name, argument_count, auto_setup_scope);
}

const uint8_t* GetSymbol(Dart_NativeFunction native_function) {
  FXL_CHECK(g_natives);
  return g_natives->GetSymbol(native_function);
}

}  // namespace

void DartServiceIsolate::TriggerResourceLoad(Dart_NativeArguments args) {
  Dart_Handle library = Dart_RootLibrary();
  FXL_DCHECK(!Dart_IsError(library));
  Dart_Handle result = LoadResources(library);
  FXL_DCHECK(!Dart_IsError(result));
}

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
  FXL_CHECK(isolate);

  // Remember the embedder's library tag handler.
  g_embedder_tag_handler = embedder_tag_handler;
  FXL_CHECK(g_embedder_tag_handler);

  // Setup native entries.
  if (!g_natives) {
    g_natives = new tonic::DartLibraryNatives();
    g_natives->Register({
        {"VMServiceIO_NotifyServerState", NotifyServerState, 1, true},
        {"VMServiceIO_Shutdown", Shutdown, 0, true},
    });
  }

  if (!g_resources) {
    g_resources = new EmbedderResources(
        &flutter::runtime::__flutter_embedded_service_isolate_resources_[0]);
  }

  // Set the root library for the isolate.
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

Dart_Handle DartServiceIsolate::LoadResource(Dart_Handle library,
                                             const char* resource_name) {
  // Prepare for invoke call.
  Dart_Handle name = Dart_NewStringFromCString(resource_name);
  RETURN_ERROR_HANDLE(name);
  const char* data_buffer = NULL;
  int data_buffer_length =
      g_resources->ResourceLookup(resource_name, &data_buffer);
  FXL_DCHECK(data_buffer_length != EmbedderResources::kNoSuchInstance);
  Dart_Handle data_list =
      Dart_NewTypedData(Dart_TypedData_kUint8, data_buffer_length);
  RETURN_ERROR_HANDLE(data_list);
  Dart_TypedData_Type type = Dart_TypedData_kInvalid;
  void* data_list_buffer = NULL;
  intptr_t data_list_buffer_length = 0;
  Dart_Handle result = Dart_TypedDataAcquireData(
      data_list, &type, &data_list_buffer, &data_list_buffer_length);
  RETURN_ERROR_HANDLE(result);
  FXL_DCHECK(data_buffer_length == data_list_buffer_length);
  FXL_DCHECK(data_list_buffer != NULL);
  FXL_DCHECK(type = Dart_TypedData_kUint8);
  memmove(data_list_buffer, &data_buffer[0], data_buffer_length);
  result = Dart_TypedDataReleaseData(data_list);
  RETURN_ERROR_HANDLE(result);

  // Make invoke call.
  const intptr_t kNumArgs = 2;
  Dart_Handle args[kNumArgs] = {name, data_list};
  result = Dart_Invoke(library, Dart_NewStringFromCString("_addResource"),
                       kNumArgs, args);
  return result;
}

Dart_Handle DartServiceIsolate::LoadResources(Dart_Handle library) {
  Dart_Handle result = Dart_Null();
  intptr_t prefixLen = strlen(kLibrarySourceNamePrefix);
  for (intptr_t i = 0; g_resources->Path(i) != NULL; i++) {
    const char* path = g_resources->Path(i);
    // If it doesn't begin with kLibrarySourceNamePrefix it is a frontend
    // resource.
    if (strncmp(path, kLibrarySourceNamePrefix, prefixLen) != 0) {
      result = LoadResource(library, path);
      if (Dart_IsError(result)) {
        break;
      }
    }
  }
  return result;
}

}  // namespace blink
