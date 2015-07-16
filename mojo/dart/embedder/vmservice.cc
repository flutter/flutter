// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/dart/embedder/vmservice.h"

#include "base/logging.h"
#include "dart/runtime/include/dart_api.h"
#include "mojo/dart/embedder/builtin.h"
#include "mojo/dart/embedder/common.h"
#include "mojo/dart/embedder/dart_controller.h"

namespace mojo {
namespace dart {

#define RETURN_ERROR_HANDLE(handle)                             \
  if (Dart_IsError(handle)) {                                   \
    return handle;                                              \
  }

#define SHUTDOWN_ON_ERROR(handle)                               \
  if (Dart_IsError(handle)) {                                   \
    error_msg_ = strdup(Dart_GetError(handle));                 \
    Dart_ExitScope();                                           \
    Dart_ShutdownIsolate();                                     \
    return false;                                               \
  }

#define kLibrarySourceNamePrefix "/vmservice"
static const char* kVMServiceIOLibraryScriptResourceName = "main.dart";

struct ResourcesEntry {
  const char* path_;
  const char* resource_;
  int length_;
};

extern ResourcesEntry __dart_embedder_service_isolate_resources_[];

class Resources {
 public:
  static const int kNoSuchInstance = -1;
  static int ResourceLookup(const char* path, const char** resource) {
    ResourcesEntry* table = ResourcesTable();
    for (int i = 0; table[i].path_ != NULL; i++) {
      const ResourcesEntry& entry = table[i];
      if (strcmp(path, entry.path_) == 0) {
        *resource = entry.resource_;
        DCHECK(entry.length_ > 0);
        return entry.length_;
      }
    }
    return kNoSuchInstance;
  }

  static const char* Path(int idx) {
    DCHECK(idx >= 0);
    ResourcesEntry* entry = At(idx);
    if (entry == NULL) {
      return NULL;
    }
    DCHECK(entry->path_ != NULL);
    return entry->path_;
  }

 private:
  static ResourcesEntry* At(int idx) {
    DCHECK(idx >= 0);
    ResourcesEntry* table = ResourcesTable();
    for (int i = 0; table[i].path_ != NULL; i++) {
      if (idx == i) {
        return &table[i];
      }
    }
    return NULL;
  }
  static ResourcesEntry* ResourcesTable() {
    return &__dart_embedder_service_isolate_resources_[0];
  }
};

void ServiceIsolate_TriggerResourceLoad(Dart_NativeArguments args) {
  Dart_Handle library = Dart_RootLibrary();
  DCHECK(!Dart_IsError(library));
  Dart_Handle result = VmService::LoadResources(library);
  DCHECK(!Dart_IsError(result));
}

void ServiceIsolate_NotifyServerState(Dart_NativeArguments args) {
  Dart_EnterScope();
  const char* ip_chars;
  Dart_Handle ip_arg = Dart_GetNativeArgument(args, 0);
  if (Dart_IsError(ip_arg)) {
    VmService::SetServerIPAndPort("", 0);
    Dart_ExitScope();
    return;
  }
  Dart_Handle result = Dart_StringToCString(ip_arg, &ip_chars);
  if (Dart_IsError(result)) {
    VmService::SetServerIPAndPort("", 0);
    Dart_ExitScope();
    return;
  }
  Dart_Handle port_arg = Dart_GetNativeArgument(args, 1);
  if (Dart_IsError(port_arg)) {
    VmService::SetServerIPAndPort("", 0);
    Dart_ExitScope();
    return;
  }
  int64_t port = DartEmbedder::GetInt64ValueCheckRange(port_arg, 0, 65535);
  VmService::SetServerIPAndPort(ip_chars, port);
  Dart_ExitScope();
}

void ServiceIsolate_Shutdown(Dart_NativeArguments args) {
  Dart_EnterScope();
  DartController::ShutdownDartMojoIo();
  Dart_ExitScope();
}

struct VmServiceIONativeEntry {
  const char* name;
  int num_arguments;
  Dart_NativeFunction function;
};


static VmServiceIONativeEntry _VmServiceIONativeEntries[] = {
  {"ServiceIsolate_TriggerResourceLoad", 0, ServiceIsolate_TriggerResourceLoad},
  {"ServiceIsolate_NotifyServerState", 2, ServiceIsolate_NotifyServerState},
  {"ServiceIsolate_Shutdown", 0, ServiceIsolate_Shutdown },
};


static Dart_NativeFunction VmServiceIONativeResolver(Dart_Handle name,
                                                     int num_arguments,
                                                     bool* auto_setup_scope) {
  const char* function_name = NULL;
  Dart_Handle result = Dart_StringToCString(name, &function_name);
  DCHECK(!Dart_IsError(result));
  DCHECK(function_name != NULL);
  *auto_setup_scope = true;
  intptr_t n =
      sizeof(_VmServiceIONativeEntries) / sizeof(_VmServiceIONativeEntries[0]);
  for (intptr_t i = 0; i < n; i++) {
    VmServiceIONativeEntry entry = _VmServiceIONativeEntries[i];
    if ((strcmp(function_name, entry.name) == 0) &&
        (num_arguments == entry.num_arguments)) {
      return entry.function;
    }
  }
  return NULL;
}


const char* VmService::error_msg_ = NULL;
char VmService::server_ip_[kServerIpStringBufferSize];
intptr_t VmService::server_port_ = 0;

bool VmService::Setup(const char* server_ip, intptr_t server_port) {
  Dart_Isolate isolate = Dart_CurrentIsolate();
  DCHECK(isolate != NULL);
  SetServerIPAndPort("", 0);

  Dart_Handle result;

  // Load main script.
  Dart_SetLibraryTagHandler(VmService::LibraryTagHandler);
  Dart_Handle library = LoadScript(kVMServiceIOLibraryScriptResourceName);
  DCHECK(library != Dart_Null());
  SHUTDOWN_ON_ERROR(library);
  result = Dart_SetNativeResolver(library, VmServiceIONativeResolver, NULL);
  SHUTDOWN_ON_ERROR(result);
  result = Dart_FinalizeLoading(false);
  SHUTDOWN_ON_ERROR(result);

  // Make runnable.
  Dart_ExitScope();
  Dart_ExitIsolate();
  bool retval = Dart_IsolateMakeRunnable(isolate);
  if (!retval) {
    Dart_EnterIsolate(isolate);
    Dart_ShutdownIsolate();
    error_msg_ = "Invalid isolate state - Unable to make it runnable.";
    return false;
  }
  Dart_EnterIsolate(isolate);
  Dart_EnterScope();

  library = Dart_RootLibrary();
  SHUTDOWN_ON_ERROR(library);

  // Set HTTP server state.
  DartEmbedder::SetStringField(library, "_ip", server_ip);
  // If we have a port specified, start the server immediately.
  bool auto_start = server_port >= 0;
  if (server_port < 0) {
    // Adjust server_port to port 0 which will result in the first available
    // port when the HTTP server is started.
    server_port = 0;
  }
  DartEmbedder::SetIntegerField(library, "_port", server_port);
  result = Dart_SetField(library,
                         DartEmbedder::NewCString("_autoStart"),
                         Dart_NewBoolean(auto_start));
  SHUTDOWN_ON_ERROR(result);
  return true;
}


const char* VmService::GetErrorMessage() {
  return error_msg_ == NULL ? "No error." : error_msg_;
}


void VmService::SetServerIPAndPort(const char* ip, intptr_t port) {
  if (ip == NULL) {
    ip = "";
  }
  strncpy(server_ip_, ip, kServerIpStringBufferSize);
  server_ip_[kServerIpStringBufferSize - 1] = '\0';
  server_port_ = port;
}


Dart_Handle VmService::GetSource(const char* name) {
  const intptr_t kBufferSize = 512;
  char buffer[kBufferSize];
  snprintf(&buffer[0], kBufferSize-1, "%s/%s", kLibrarySourceNamePrefix, name);
  const char* vmservice_source = NULL;
  int r = Resources::ResourceLookup(buffer, &vmservice_source);
  DCHECK(r != Resources::kNoSuchInstance);
  return Dart_NewStringFromCString(vmservice_source);
}


Dart_Handle VmService::LoadScript(const char* name) {
  Dart_Handle url = Dart_NewStringFromCString("dart:vmservice_io");
  Dart_Handle source = GetSource(name);
  return Dart_LoadScript(url, source, 0, 0);
}


Dart_Handle VmService::LoadSource(Dart_Handle library, const char* name) {
  Dart_Handle url = Dart_NewStringFromCString(name);
  Dart_Handle source = GetSource(name);
  return Dart_LoadSource(library, url, source, 0, 0);
}


Dart_Handle VmService::LoadResource(Dart_Handle library,
                                    const char* resource_name) {
  // Prepare for invoke call.
  Dart_Handle name = Dart_NewStringFromCString(resource_name);
  RETURN_ERROR_HANDLE(name);
  const char* data_buffer = NULL;
  int data_buffer_length = Resources::ResourceLookup(resource_name,
                                                     &data_buffer);
  DCHECK(data_buffer_length != Resources::kNoSuchInstance);
  Dart_Handle data_list = Dart_NewTypedData(Dart_TypedData_kUint8,
                                            data_buffer_length);
  RETURN_ERROR_HANDLE(data_list);
  Dart_TypedData_Type type = Dart_TypedData_kInvalid;
  void* data_list_buffer = NULL;
  intptr_t data_list_buffer_length = 0;
  Dart_Handle result = Dart_TypedDataAcquireData(data_list, &type,
                                                 &data_list_buffer,
                                                 &data_list_buffer_length);
  RETURN_ERROR_HANDLE(result);
  DCHECK(data_buffer_length == data_list_buffer_length);
  DCHECK(data_list_buffer != NULL);
  DCHECK(type = Dart_TypedData_kUint8);
  memmove(data_list_buffer, &data_buffer[0], data_buffer_length);
  result = Dart_TypedDataReleaseData(data_list);
  RETURN_ERROR_HANDLE(result);

  // Make invoke call.
  const intptr_t kNumArgs = 2;
  Dart_Handle args[kNumArgs] = { name, data_list };
  result = Dart_Invoke(library, Dart_NewStringFromCString("_addResource"),
                       kNumArgs, args);
  return result;
}


Dart_Handle VmService::LoadResources(Dart_Handle library) {
  Dart_Handle result = Dart_Null();
  intptr_t prefixLen = strlen(kLibrarySourceNamePrefix);
  for (intptr_t i = 0; Resources::Path(i) != NULL; i++) {
    const char* path = Resources::Path(i);
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


Dart_Handle VmService::LibraryTagHandler(Dart_LibraryTag tag,
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
    return DartController::LibraryTagHandler(tag, library, url);
  }
  DCHECK((tag == Dart_kSourceTag) || (tag == Dart_kCanonicalizeUrl));
  if (tag == Dart_kCanonicalizeUrl) {
    // url is already canonicalized.
    return url;
  }
  Dart_Handle source = GetSource(url_string);
  if (Dart_IsError(source)) {
    return source;
  }
  return Dart_LoadSource(library, url, source, 0, 0);
}


}  // namespace dart
}  // namespace mojo
