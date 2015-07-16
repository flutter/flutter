// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/callback.h"
#include "base/files/file_util.h"
#include "base/logging.h"
#include "base/path_service.h"
#include "base/sys_info.h"
#include "crypto/random.h"
#include "dart/runtime/include/dart_api.h"
#include "dart/runtime/include/dart_native_api.h"
#include "mojo/dart/embedder/builtin.h"
#include "mojo/dart/embedder/dart_controller.h"
#include "mojo/dart/embedder/dart_debugger.h"
#include "mojo/dart/embedder/isolate_data.h"
#include "mojo/dart/embedder/vmservice.h"
#include "mojo/public/c/system/core.h"

namespace mojo {
namespace dart {

extern const uint8_t* vm_isolate_snapshot_buffer;
extern const uint8_t* isolate_snapshot_buffer;

const char* kDartScheme = "dart:";
const char* kAsyncLibURL = "dart:async";
const char* kInternalLibURL = "dart:_internal";
const char* kIsolateLibURL = "dart:isolate";
const char* kIOLibURL = "dart:io";
const char* kCoreLibURL = "dart:core";

static bool IsDartSchemeURL(const char* url_name) {
  static const intptr_t kDartSchemeLen = strlen(kDartScheme);
  // If the URL starts with "dart:" then it is considered as a special
  // library URL which is handled differently from other URLs.
  return (strncmp(url_name, kDartScheme, kDartSchemeLen) == 0);
}

static void ReportScriptError(Dart_Handle handle) {
  // The normal DART_CHECK_VALID macro displays error information and a stack
  // dump for the C++ application, which is confusing. Only show the Dart error.
  if (Dart_IsError((handle))) {
    LOG(ERROR) << "Dart runtime error:\n" << Dart_GetError(handle) << "\n";
  }
}

Dart_Handle ResolveUri(Dart_Handle library_url,
                       Dart_Handle url,
                       Dart_Handle builtin_lib) {
  const int kNumArgs = 2;
  Dart_Handle dart_args[kNumArgs];
  dart_args[0] = library_url;
  dart_args[1] = url;
  return Dart_Invoke(builtin_lib,
                     Dart_NewStringFromCString("_resolveUri"),
                     kNumArgs,
                     dart_args);
}

static Dart_Handle LoadDataAsync_Invoke(Dart_Handle tag,
                                        Dart_Handle url,
                                        Dart_Handle library_url,
                                        Dart_Handle builtin_lib,
                                        Dart_Handle data) {
  const int kNumArgs = 4;
  Dart_Handle dart_args[kNumArgs];
  dart_args[0] = tag;
  dart_args[1] = url;
  dart_args[2] = library_url;
  dart_args[3] = data;
  return Dart_Invoke(builtin_lib,
                     Dart_NewStringFromCString("_loadDataAsync"),
                     kNumArgs,
                     dart_args);
}

Dart_Handle DartController::LibraryTagHandler(Dart_LibraryTag tag,
                                              Dart_Handle library,
                                              Dart_Handle url) {
  if (!Dart_IsLibrary(library)) {
    return Dart_NewApiError("not a library");
  }
  if (!Dart_IsString(url)) {
    return Dart_NewApiError("url is not a string");
  }
  Dart_Handle library_url = Dart_LibraryUrl(library);
  const char* library_url_string = nullptr;
  Dart_Handle result = Dart_StringToCString(library_url, &library_url_string);
  if (Dart_IsError(result)) {
    return result;
  }

  // Handle URI canonicalization requests.
  const char* url_string = nullptr;
  result = Dart_StringToCString(url, &url_string);
  if (tag == Dart_kCanonicalizeUrl) {
    if (Dart_IsError(result)) {
      return result;
    }
    const bool is_internal_scheme_url = IsDartSchemeURL(url_string);
    // If this is a Dart Scheme URL, or a Mojo Scheme URL, then it is not
    // modified as it will be handled internally.
    if (is_internal_scheme_url) {
      return url;
    }
    // Resolve the url within the context of the library's URL.
    Dart_Handle builtin_lib =
        Builtin::GetLibrary(Builtin::kBuiltinLibrary);
    return ResolveUri(library_url, url, builtin_lib);
  }

  Dart_Handle builtin_lib =
      Builtin::GetLibrary(Builtin::kBuiltinLibrary);
  // Handle 'import' or 'part' requests for all other URIs. Call dart code to
  // read the source code asynchronously.
  return LoadDataAsync_Invoke(
      Dart_NewInteger(tag), url, library_url, builtin_lib, Dart_Null());
}

static Dart_Handle SetWorkingDirectory(Dart_Handle builtin_lib) {
  base::FilePath current_dir;
  PathService::Get(base::DIR_CURRENT, &current_dir);

  const int kNumArgs = 1;
  Dart_Handle dart_args[kNumArgs];
  std::string current_dir_string = current_dir.AsUTF8Unsafe();
  dart_args[0] = Dart_NewStringFromUTF8(
      reinterpret_cast<const uint8_t*>(current_dir_string.data()),
      current_dir_string.length());
  return Dart_Invoke(builtin_lib,
                     Dart_NewStringFromCString("_setWorkingDirectory"),
                     kNumArgs,
                     dart_args);
}

static Dart_Handle PrepareScriptForLoading(const std::string& package_root,
                                           Dart_Handle builtin_lib) {
  // First ensure all required libraries are available.
  Dart_Handle url = Dart_NewStringFromCString(kInternalLibURL);
  DART_CHECK_VALID(url);
  Dart_Handle internal_lib = Dart_LookupLibrary(url);
  DART_CHECK_VALID(internal_lib);
  url = Dart_NewStringFromCString(kCoreLibURL);
  DART_CHECK_VALID(url);
  Dart_Handle core_lib = Dart_LookupLibrary(url);
  DART_CHECK_VALID(internal_lib);
  url = Dart_NewStringFromCString(kAsyncLibURL);
  DART_CHECK_VALID(url);
  Dart_Handle async_lib = Dart_LookupLibrary(url);
  DART_CHECK_VALID(async_lib);
  url = Dart_NewStringFromCString(kIsolateLibURL);
  DART_CHECK_VALID(url);
  Dart_Handle isolate_lib = Dart_LookupLibrary(url);
  DART_CHECK_VALID(isolate_lib);
  Dart_Handle mojo_internal_lib =
      Builtin::GetLibrary(Builtin::kMojoInternalLibrary);
  DART_CHECK_VALID(mojo_internal_lib);

  // We need to ensure that all the scripts loaded so far are finalized
  // as we are about to invoke some Dart code below to setup closures.
  Dart_Handle result = Dart_FinalizeLoading(false);
  DART_CHECK_VALID(result);

  // Import dart:_internal into dart:mojo.builtin for setting up hooks.
  result = Dart_LibraryImportLibrary(builtin_lib, internal_lib, Dart_Null());
  DART_CHECK_VALID(result);

  // Setup the internal library's 'internalPrint' function.
  Dart_Handle print = Dart_Invoke(builtin_lib,
                                  Dart_NewStringFromCString("_getPrintClosure"),
                                  0,
                                  nullptr);
  DART_CHECK_VALID(print);
  result = Dart_SetField(internal_lib,
                         Dart_NewStringFromCString("_printClosure"),
                         print);
  DART_CHECK_VALID(result);

  DART_CHECK_VALID(Dart_Invoke(
      builtin_lib, Dart_NewStringFromCString("_setupHooks"), 0, nullptr));
  DART_CHECK_VALID(Dart_Invoke(
      isolate_lib, Dart_NewStringFromCString("_setupHooks"), 0, nullptr));

  // Setup the 'scheduleImmediate' closure.
  Dart_Handle schedule_immediate_closure = Dart_Invoke(
      isolate_lib,
      Dart_NewStringFromCString("_getIsolateScheduleImmediateClosure"),
      0,
      nullptr);
  Dart_Handle schedule_args[1];
  schedule_args[0] = schedule_immediate_closure;
  result = Dart_Invoke(
      async_lib,
      Dart_NewStringFromCString("_setScheduleImmediateClosure"),
      1,
      schedule_args);
  DART_CHECK_VALID(result);

  // Set current working directory.
  result = SetWorkingDirectory(builtin_lib);
  if (Dart_IsError(result)) {
    return result;
  }

  // Set up package root.
  result = Dart_NewStringFromUTF8(
      reinterpret_cast<const uint8_t*>(package_root.c_str()),
      package_root.length());
  DART_CHECK_VALID(result);

  const int kNumArgs = 1;
  Dart_Handle dart_args[kNumArgs];
  dart_args[0] = result;
  result = Dart_Invoke(builtin_lib,
                     Dart_NewStringFromCString("_setPackageRoot"),
                     kNumArgs,
                     dart_args);
  DART_CHECK_VALID(result);

  // Setup the uriBase with the base uri of the mojo app.
  Dart_Handle uri_base = Dart_Invoke(
      builtin_lib,
      Dart_NewStringFromCString("_getUriBaseClosure"),
      0,
      nullptr);
  DART_CHECK_VALID(uri_base);
  result = Dart_SetField(core_lib,
                         Dart_NewStringFromCString("_uriBaseClosure"),
                         uri_base);
  DART_CHECK_VALID(result);

  return result;
}


Dart_Isolate DartController::CreateIsolateHelper(
    void* dart_app,
    bool strict_compilation,
    IsolateCallbacks callbacks,
    const std::string& script,
    const std::string& script_uri,
    const std::string& package_root,
    char** error) {
  IsolateData* isolate_data = new IsolateData(
      dart_app,
      strict_compilation,
      callbacks,
      script,
      script_uri,
      package_root);
  Dart_Isolate isolate =
      Dart_CreateIsolate(script_uri.c_str(), "main", isolate_snapshot_buffer,
                         nullptr, isolate_data, error);
  if (isolate == nullptr) {
    delete isolate_data;
    return nullptr;
  }

  Dart_EnterScope();

  Dart_IsolateSetStrictCompilation(strict_compilation);

  // Set up the library tag handler for this isolate.
  Dart_Handle result = Dart_SetLibraryTagHandler(LibraryTagHandler);
  DART_CHECK_VALID(result);

  // Setup the native resolvers for the builtin libraries as they are not set
  // up when the snapshot is read.
  CHECK(isolate_snapshot_buffer != nullptr);
  Builtin::PrepareLibrary(Builtin::kBuiltinLibrary);
  Builtin::PrepareLibrary(Builtin::kMojoInternalLibrary);
  Builtin::PrepareLibrary(Builtin::kDartMojoIoLibrary);

  if (!callbacks.create.is_null()) {
    callbacks.create.Run(script_uri.c_str(),
                         "main",
                         package_root.c_str(),
                         isolate_data,
                         error);
  }

  // Prepare builtin and its dependent libraries for use to resolve URIs.
  // The builtin library is part of the snapshot and is already available.
  Dart_Handle builtin_lib =
      Builtin::GetLibrary(Builtin::kBuiltinLibrary);
  DART_CHECK_VALID(builtin_lib);

  if (Dart_IsServiceIsolate(isolate)) {
    result = PrepareScriptForLoading(package_root, builtin_lib);
    DART_CHECK_VALID(result);
    const intptr_t port = SupportDartMojoIo() ? 0 : -1;
    InitializeDartMojoIo();
    StartHandleWatcherIsolate();
    if (!VmService::Setup("127.0.0.1", port)) {
      *error = strdup(VmService::GetErrorMessage());
      return nullptr;
    }
    Dart_ExitScope();
    Dart_ExitIsolate();
    return isolate;
  }
  result = PrepareScriptForLoading(package_root, builtin_lib);
  DART_CHECK_VALID(result);

  Dart_Handle uri = Dart_NewStringFromUTF8(
      reinterpret_cast<const uint8_t*>(script_uri.c_str()),
      script_uri.length());
  DART_CHECK_VALID(uri);

  const void* data = static_cast<const void*>(script.data());
  Dart_Handle script_source = Dart_NewExternalTypedData(
      Dart_TypedData_kUint8,
      const_cast<void*>(data),
      script.length());
  DART_CHECK_VALID(script_source);

  result = LoadDataAsync_Invoke(
      Dart_Null(), uri, Dart_Null(), builtin_lib, script_source);
  DART_CHECK_VALID(result);

  // Run event-loop and wait for script loading to complete.
  result = Dart_RunLoop();
  ReportScriptError(result);

  DartController::InitializeDartMojoIo();

  // Make the isolate runnable so that it is ready to handle messages.
  Dart_ExitScope();
  Dart_ExitIsolate();
  bool retval = Dart_IsolateMakeRunnable(isolate);
  if (!retval) {
    *error = strdup("Invalid isolate state - Unable to make it runnable");
    Dart_EnterIsolate(isolate);
    Dart_ShutdownIsolate();
    return nullptr;
  }

  return isolate;
}

Dart_Isolate DartController::IsolateCreateCallback(const char* script_uri,
                                                   const char* main,
                                                   const char* package_root,
                                                   Dart_IsolateFlags* flags,
                                                   void* callback_data,
                                                   char** error) {
  IsolateData* parent_isolate_data =
      reinterpret_cast<IsolateData*>(callback_data);
  std::string script_uri_string;
  std::string package_root_string;

  if (script_uri == nullptr) {
    if (callback_data == nullptr) {
      *error = strdup("Invalid 'callback_data' - Unable to spawn new isolate");
      return nullptr;
    }
    script_uri_string = parent_isolate_data->script_uri;
  } else {
    script_uri_string = std::string(script_uri);
  }
  if (package_root == nullptr) {
    if (parent_isolate_data != nullptr) {
      package_root_string = parent_isolate_data->package_root;
    }
  } else {
    package_root_string = std::string(package_root);
  }
  // Inherit parameters from parent isolate (if any).
  void* dart_app = nullptr;
  bool strict_compilation = true;
  IsolateCallbacks callbacks;
  std::string script;
  if (parent_isolate_data != nullptr) {
    dart_app = parent_isolate_data->app;
    strict_compilation = parent_isolate_data->strict_compilation;
    callbacks = parent_isolate_data->callbacks;
    script = parent_isolate_data->script;
  }
  return CreateIsolateHelper(dart_app,
                             strict_compilation,
                             callbacks,
                             script,
                             script_uri_string,
                             package_root_string,
                             error);
}

void DartController::IsolateShutdownCallback(void* callback_data) {
  Dart_EnterScope();
  ShutdownDartMojoIo();
  Dart_ExitScope();

  IsolateData* isolate_data = reinterpret_cast<IsolateData*>(callback_data);
  if (!isolate_data->callbacks.shutdown.is_null()) {
    isolate_data->callbacks.shutdown.Run(callback_data);
  }
  delete isolate_data;
}

void DartController::UnhandledExceptionCallback(Dart_Handle error) {
  Dart_Isolate isolate = Dart_CurrentIsolate();
  void* data = Dart_IsolateData(isolate);
  IsolateData* isolate_data = reinterpret_cast<IsolateData*>(data);
  if (!isolate_data->callbacks.exception.is_null()) {
    // TODO(zra): Instead of passing an error handle, it may make life easier
    // for clients if we pass any error string here instead.
    isolate_data->callbacks.exception.Run(error);
  }

  // Close handles generated by the isolate.
  std::set<MojoHandle>& handles = isolate_data->unclosed_handles;
  for (auto it = handles.begin(); it != handles.end(); ++it) {
    MojoClose((*it));
  }
  handles.clear();
}


bool DartController::initialized_ = false;
bool DartController::service_isolate_running_ = false;
bool DartController::strict_compilation_ = false;
DartControllerServiceConnector* DartController::service_connector_ = nullptr;

bool DartController::SupportDartMojoIo() {
  return service_connector_ != nullptr;
}

void DartController::InitializeDartMojoIo() {
  Dart_Isolate current_isolate = Dart_CurrentIsolate();
  CHECK(current_isolate != nullptr);
  if (!SupportDartMojoIo()) {
    return;
  }
  CHECK(service_connector_ != nullptr);
  MojoHandle network_service_mojo_handle = MOJO_HANDLE_INVALID;
  network_service_mojo_handle =
        service_connector_->ConnectToService(
            DartControllerServiceConnector::kNetworkServiceId);
  if (network_service_mojo_handle == MOJO_HANDLE_INVALID) {
    // Not supported.
    return;
  }
  // Pass handle into 'dart:io' library.
  Dart_Handle mojo_io_library =
      Builtin::GetLibrary(Builtin::kDartMojoIoLibrary);
  CHECK(!Dart_IsError(mojo_io_library));
  Dart_Handle method_name = Dart_NewStringFromCString("_initialize");
  CHECK(!Dart_IsError(method_name));
  Dart_Handle network_service_handle =
      Dart_NewInteger(network_service_mojo_handle);
  CHECK(!Dart_IsError(network_service_handle));
  Dart_Handle result = Dart_Invoke(mojo_io_library,
                                   method_name,
                                   1,
                                   &network_service_handle);
  CHECK(!Dart_IsError(result));
}

void DartController::ShutdownDartMojoIo() {
  Dart_Isolate current_isolate = Dart_CurrentIsolate();
  CHECK(current_isolate != nullptr);
  if (!SupportDartMojoIo()) {
    return;
  }
  Dart_Handle mojo_io_library =
      Builtin::GetLibrary(Builtin::kDartMojoIoLibrary);
  CHECK(!Dart_IsError(mojo_io_library));
  Dart_Handle method_name = Dart_NewStringFromCString("_shutdown");
  CHECK(!Dart_IsError(method_name));
  Dart_Handle result = Dart_Invoke(mojo_io_library,
                                   method_name,
                                   0,
                                   nullptr);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
}

void DartController::StartHandleWatcherIsolate() {
  Dart_Handle result;

  // Start the Mojo handle watcher isolate.
  Dart_Handle mojo_core_lib =
      Builtin::GetLibrary(Builtin::kMojoInternalLibrary);
  DART_CHECK_VALID(mojo_core_lib);
  Dart_Handle handle_watcher_type = Dart_GetType(
      mojo_core_lib,
      Dart_NewStringFromCString("MojoHandleWatcher"),
      0,
      nullptr);
  DART_CHECK_VALID(handle_watcher_type);
  result = Dart_Invoke(
      handle_watcher_type,
      Dart_NewStringFromCString("_start"),
      0,
      nullptr);
  DART_CHECK_VALID(result);
}

// TODO(johnmccutchan): Move handle watcher shutdown into the service isolate
// once the VM can shutdown cleanly.
void DartController::StopHandleWatcherIsolate() {
  // Spin up an isolate to initiate the handle watcher shutdown.
  IsolateCallbacks callbacks;
  char* error;
  Dart_Isolate shutdown_isolate = CreateIsolateHelper(
      nullptr, false, callbacks, "", "", "", &error);
  CHECK(shutdown_isolate);

  Dart_EnterIsolate(shutdown_isolate);
  Dart_EnterScope();
  Dart_Handle result;

  // Stop the Mojo handle watcher isolate.
  Dart_Handle mojo_core_lib =
      Builtin::GetLibrary(Builtin::kMojoInternalLibrary);
  DART_CHECK_VALID(mojo_core_lib);
  Dart_Handle handle_watcher_type = Dart_GetType(
      mojo_core_lib,
      Dart_NewStringFromCString("MojoHandleWatcher"),
      0,
      nullptr);
  DART_CHECK_VALID(handle_watcher_type);
  result = Dart_Invoke(
      handle_watcher_type,
      Dart_NewStringFromCString("_stop"),
      0,
      nullptr);
  DART_CHECK_VALID(result);

  // Run until the handle watcher isolate has exited.
  result = Dart_RunLoop();
  DART_CHECK_VALID(result);

  Dart_ExitScope();
  Dart_ShutdownIsolate();
}

void DartController::InitVmIfNeeded(Dart_EntropySource entropy,
                                    const char** arguments,
                                    int arguments_count) {
  // TODO(zra): If runDartScript can be called from multiple threads
  // concurrently, then initialized_ will need to be protected by a lock.
  if (initialized_) {
    return;
  }

  const int kNumArgs = arguments_count + 1;
  const char* args[kNumArgs];

  // TODO(zra): Fix Dart VM Shutdown race.
  // There is a bug in Dart VM shutdown which causes its thread pool threads
  // to potentially fail to exit when the rest of the VM is going down. This
  // results in a segfault if they begin running again after the Dart
  // embedder has been unloaded. Setting this flag to 0 ensures that these
  // threads sleep forever instead of waking up and trying to run code
  // that isn't there anymore.
  args[0] = "--worker-timeout-millis=0";

  for (int i = 0; i < arguments_count; ++i) {
    args[i + 1] = arguments[i];
  }

  bool result = Dart_SetVMFlags(kNumArgs, args);
  CHECK(result);

  // This should be called before calling Dart_Initialize.
  DartDebugger::InitDebugger();

  result = Dart_Initialize(vm_isolate_snapshot_buffer,
                           IsolateCreateCallback,
                           nullptr,  // Isolate interrupt callback.
                           UnhandledExceptionCallback,
                           IsolateShutdownCallback,
                           // File IO callbacks.
                           nullptr, nullptr, nullptr, nullptr,
                           entropy);
  CHECK(result);
  // By waiting for the load port, we ensure that the service isolate is fully
  // running before returning.
  Dart_ServiceWaitForLoadPort();
  initialized_ = true;
  service_isolate_running_ = true;
}

bool DartController::RunSingleDartScript(const DartControllerConfig& config) {
  InitVmIfNeeded(config.entropy,
                 config.arguments,
                 config.arguments_count);
  Dart_Isolate isolate = CreateIsolateHelper(config.application_data,
                                             config.strict_compilation,
                                             config.callbacks,
                                             config.script,
                                             config.script_uri,
                                             config.package_root,
                                             config.error);
  if (isolate == nullptr) {
    return false;
  }

  Dart_EnterIsolate(isolate);
  Dart_Handle result;
  Dart_EnterScope();

  // Load the root library into the builtin library so that main can be found.
  Dart_Handle builtin_lib =
      Builtin::GetLibrary(Builtin::kBuiltinLibrary);
  DART_CHECK_VALID(builtin_lib);
  Dart_Handle root_lib = Dart_RootLibrary();
  DART_CHECK_VALID(root_lib);
  result = Dart_LibraryImportLibrary(builtin_lib, root_lib, Dart_Null());
  DART_CHECK_VALID(result);

  if (config.compile_all) {
    result = Dart_CompileAll();
    DART_CHECK_VALID(result);
  }

  Dart_Handle main_closure = Dart_Invoke(
      builtin_lib,
      Dart_NewStringFromCString("_getMainClosure"),
      0,
      nullptr);
  DART_CHECK_VALID(main_closure);

  // Call _startIsolate in the isolate library to enable dispatching the
  // initial startup message.
  const intptr_t kNumIsolateArgs = 2;
  Dart_Handle isolate_args[kNumIsolateArgs];
  isolate_args[0] = main_closure;     // entryPoint
  isolate_args[1] = Dart_NewList(2);  // args
  DART_CHECK_VALID(isolate_args[1]);

  Dart_Handle script_uri = Dart_NewStringFromUTF8(
      reinterpret_cast<const uint8_t*>(config.script_uri.data()),
      config.script_uri.length());
  Dart_ListSetAt(isolate_args[1], 0, Dart_NewInteger(config.handle));
  Dart_ListSetAt(isolate_args[1], 1, script_uri);

  Dart_Handle isolate_lib =
      Dart_LookupLibrary(Dart_NewStringFromCString(kIsolateLibURL));
  DART_CHECK_VALID(isolate_lib);

  result = Dart_Invoke(isolate_lib,
                       Dart_NewStringFromCString("_startMainIsolate"),
                       kNumIsolateArgs,
                       isolate_args);
  DART_CHECK_VALID(result);

  result = Dart_RunLoop();
  DART_CHECK_VALID(result);

  Dart_ExitScope();
  Dart_ShutdownIsolate();
  Dart_Cleanup();
  return true;
}

static bool generateEntropy(uint8_t* buffer, intptr_t length) {
  crypto::RandBytes(reinterpret_cast<void*>(buffer), length);
  return true;
}

bool DartController::Initialize(
    DartControllerServiceConnector* service_connector,
    bool strict_compilation) {
  service_connector_ = service_connector;
  strict_compilation_ = strict_compilation;
  InitVmIfNeeded(generateEntropy, nullptr, 0);
  return true;
}

bool DartController::RunDartScript(const DartControllerConfig& config) {
  CHECK(service_isolate_running_);
  const bool strict = strict_compilation_ || config.strict_compilation;
  Dart_Isolate isolate = CreateIsolateHelper(
      config.application_data, strict, config.callbacks, config.script,
      config.script_uri, config.package_root, config.error);
  if (isolate == nullptr) {
    return false;
  }

  Dart_EnterIsolate(isolate);
  Dart_Handle result;
  Dart_EnterScope();

  // Load the root library into the builtin library so that main can be found.
  Dart_Handle builtin_lib =
      Builtin::GetLibrary(Builtin::kBuiltinLibrary);
  DART_CHECK_VALID(builtin_lib);
  Dart_Handle root_lib = Dart_RootLibrary();
  DART_CHECK_VALID(root_lib);
  result = Dart_LibraryImportLibrary(builtin_lib, root_lib, Dart_Null());
  DART_CHECK_VALID(result);

  if (config.compile_all) {
    result = Dart_CompileAll();
    DART_CHECK_VALID(result);
  }

  Dart_Handle main_closure = Dart_Invoke(
      builtin_lib,
      Dart_NewStringFromCString("_getMainClosure"),
      0,
      nullptr);
  DART_CHECK_VALID(main_closure);

  // Call _startIsolate in the isolate library to enable dispatching the
  // initial startup message.
  const intptr_t kNumIsolateArgs = 2;
  Dart_Handle isolate_args[kNumIsolateArgs];
  isolate_args[0] = main_closure;     // entryPoint
  isolate_args[1] = Dart_NewList(2);  // args
  DART_CHECK_VALID(isolate_args[1]);

  Dart_Handle script_uri = Dart_NewStringFromUTF8(
      reinterpret_cast<const uint8_t*>(config.script_uri.data()),
      config.script_uri.length());
  Dart_ListSetAt(isolate_args[1], 0, Dart_NewInteger(config.handle));
  Dart_ListSetAt(isolate_args[1], 1, script_uri);

  Dart_Handle isolate_lib =
      Dart_LookupLibrary(Dart_NewStringFromCString(kIsolateLibURL));
  DART_CHECK_VALID(isolate_lib);

  result = Dart_Invoke(isolate_lib,
                       Dart_NewStringFromCString("_startMainIsolate"),
                       kNumIsolateArgs,
                       isolate_args);
  DART_CHECK_VALID(result);

  // Run main until completion.
  result = Dart_RunLoop();
  ReportScriptError(result);

  Dart_ExitScope();
  Dart_ShutdownIsolate();
  return true;
}

void DartController::Shutdown() {
  StopHandleWatcherIsolate();
  Dart_Cleanup();
  service_isolate_running_ = false;
  initialized_ = false;
}

}  // namespace apps
}  // namespace mojo
