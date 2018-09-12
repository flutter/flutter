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

#define kLibrarySourceNamePrefix "/vmservice"
static const char* kServiceIsolateScript = "vmservice_io.dart";

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
  FML_CHECK(g_natives);
  return g_natives->GetNativeFunction(name, argument_count, auto_setup_scope);
}

const uint8_t* GetSymbol(Dart_NativeFunction native_function) {
  FML_CHECK(g_natives);
  return g_natives->GetSymbol(native_function);
}

}  // namespace

void DartServiceIsolate::TriggerResourceLoad(Dart_NativeArguments args) {
  Dart_Handle library = Dart_RootLibrary();
  FML_DCHECK(!Dart_IsError(library));
  Dart_Handle result = LoadResources(library);
  FML_DCHECK(!Dart_IsError(result));
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
                                 bool running_from_sources,
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

  if (!g_resources) {
    g_resources = new EmbedderResources(
        &flutter::runtime::__flutter_embedded_service_isolate_resources_[0]);
  }

  Dart_Handle result;

  if (running_from_sources) {
    // Use our own library tag handler when loading service isolate sources.
    Dart_SetLibraryTagHandler(DartServiceIsolate::LibraryTagHandler);
    // Load main script.
    Dart_Handle library = LoadScript(kServiceIsolateScript);
    FML_DCHECK(library != Dart_Null());
    SHUTDOWN_ON_ERROR(library);
    // Setup native entry resolution.
    result = Dart_SetNativeResolver(library, GetNativeFunction, GetSymbol);

    SHUTDOWN_ON_ERROR(result);
    // Finalize loading.
    result = Dart_FinalizeLoading(false);
    SHUTDOWN_ON_ERROR(result);
  } else {
    Dart_Handle uri = Dart_NewStringFromCString("dart:vmservice_io");
    Dart_Handle library = Dart_LookupLibrary(uri);
    SHUTDOWN_ON_ERROR(library);
    result = Dart_SetRootLibrary(library);
    SHUTDOWN_ON_ERROR(result);
    result = Dart_SetNativeResolver(library, GetNativeFunction, GetSymbol);
    SHUTDOWN_ON_ERROR(result);
  }

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

  Dart_Handle library = Dart_RootLibrary();
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

Dart_Handle DartServiceIsolate::GetSource(const char* name) {
  const intptr_t kBufferSize = 512;
  char buffer[kBufferSize];
  snprintf(&buffer[0], kBufferSize - 1, "%s/%s", kLibrarySourceNamePrefix,
           name);
  const char* vmservice_source = NULL;
  int r = g_resources->ResourceLookup(buffer, &vmservice_source);
  FML_DCHECK(r != EmbedderResources::kNoSuchInstance);
  return Dart_NewStringFromCString(vmservice_source);
}

Dart_Handle DartServiceIsolate::LoadScript(const char* name) {
  Dart_Handle url = Dart_NewStringFromCString("dart:vmservice_io");
  Dart_Handle source = GetSource(name);
  return Dart_LoadScript(url, Dart_Null(), source, 0, 0);
}

Dart_Handle DartServiceIsolate::LoadSource(Dart_Handle library,
                                           const char* name) {
  Dart_Handle url = Dart_NewStringFromCString(name);
  Dart_Handle source = GetSource(name);
  return Dart_LoadSource(library, url, Dart_Null(), source, 0, 0);
}

Dart_Handle DartServiceIsolate::LoadResource(Dart_Handle library,
                                             const char* resource_name) {
  // Prepare for invoke call.
  Dart_Handle name = Dart_NewStringFromCString(resource_name);
  RETURN_ERROR_HANDLE(name);
  const char* data_buffer = NULL;
  int data_buffer_length =
      g_resources->ResourceLookup(resource_name, &data_buffer);
  FML_DCHECK(data_buffer_length != EmbedderResources::kNoSuchInstance);
  Dart_Handle data_list =
      Dart_NewTypedData(Dart_TypedData_kUint8, data_buffer_length);
  RETURN_ERROR_HANDLE(data_list);
  Dart_TypedData_Type type = Dart_TypedData_kInvalid;
  void* data_list_buffer = NULL;
  intptr_t data_list_buffer_length = 0;
  Dart_Handle result = Dart_TypedDataAcquireData(
      data_list, &type, &data_list_buffer, &data_list_buffer_length);
  RETURN_ERROR_HANDLE(result);
  FML_DCHECK(data_buffer_length == data_list_buffer_length);
  FML_DCHECK(data_list_buffer != NULL);
  FML_DCHECK(type = Dart_TypedData_kUint8);
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

Dart_Handle DartServiceIsolate::LibraryTagHandler(Dart_LibraryTag tag,
                                                  Dart_Handle library,
                                                  Dart_Handle url) {
  if (!Dart_IsLibrary(library)) {
    return Dart_NewApiError("not a library");
  }
  if (!Dart_IsString(url)) {
    return Dart_NewApiError("url is not a string");
  }
  const char* url_string = NULL;
  Dart_Handle result = Dart_StringToCString(url, &url_string);
  if (Dart_IsError(result)) {
    return result;
  }
  Dart_Handle library_url = Dart_LibraryUrl(library);
  const char* library_url_string = NULL;
  result = Dart_StringToCString(library_url, &library_url_string);
  if (Dart_IsError(result)) {
    return result;
  }
  if (tag == Dart_kImportTag) {
    // Embedder handles all requests for external libraries.
    return g_embedder_tag_handler(tag, library, url);
  }
  FML_DCHECK((tag == Dart_kSourceTag) || (tag == Dart_kCanonicalizeUrl));
  if (tag == Dart_kCanonicalizeUrl) {
    // url is already canonicalized.
    return url;
  }
  // Get source from builtin resources.
  Dart_Handle source = GetSource(url_string);
  if (Dart_IsError(source)) {
    return source;
  }
  return Dart_LoadSource(library, url, Dart_Null(), source, 0, 0);
}

}  // namespace blink
