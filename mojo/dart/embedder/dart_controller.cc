// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/bind.h"
#include "base/callback.h"
#include "base/files/file_util.h"
#include "base/logging.h"
#include "base/path_service.h"
#include "base/rand_util.h"
#include "base/run_loop.h"
#include "base/strings/string_util.h"
#include "base/sys_info.h"
#include "dart/runtime/include/dart_api.h"
#include "dart/runtime/include/dart_native_api.h"
#include "mojo/common/message_pump_mojo.h"
#include "mojo/dart/embedder/builtin.h"
#include "mojo/dart/embedder/dart_controller.h"
#include "mojo/dart/embedder/mojo_dart_state.h"
#include "mojo/dart/embedder/vmservice.h"
#include "mojo/public/c/system/core.h"
#include "tonic/dart_converter.h"
#include "tonic/dart_debugger.h"
#include "tonic/dart_dependency_catcher.h"
#include "tonic/dart_error.h"
#include "tonic/dart_library_loader.h"
#include "tonic/dart_library_provider.h"
#include "tonic/dart_library_provider_files.h"
#include "tonic/dart_library_provider_network.h"

namespace mojo {
namespace dart {

extern const uint8_t* vm_isolate_snapshot_buffer;
extern const uint8_t* isolate_snapshot_buffer;

static const char* kAsyncLibURL = "dart:async";
static const char* kInternalLibURL = "dart:_internal";
static const char* kIsolateLibURL = "dart:isolate";
static const char* kCoreLibURL = "dart:core";

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

static Dart_Handle ResolveScriptUri(Dart_Handle builtin_lib, Dart_Handle uri) {
  const int kNumArgs = 1;
  Dart_Handle dart_args[kNumArgs];
  dart_args[0] = uri;
  return Dart_Invoke(builtin_lib,
                     Dart_NewStringFromCString("_resolveScriptUri"),
                     kNumArgs,
                     dart_args);
}

static Dart_Handle PrepareIsolateLibraries(const std::string& package_root,
                                           const std::string& script_uri) {
  // First ensure all required libraries are available.
  Dart_Handle builtin_lib = Builtin::GetLibrary(Builtin::kBuiltinLibrary);
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

  // Set script entry uri.
  Dart_Handle uri = Dart_NewStringFromUTF8(
      reinterpret_cast<const uint8_t*>(script_uri.c_str()),
      script_uri.length());
  DART_CHECK_VALID(uri);
  result = ResolveScriptUri(builtin_lib, uri);

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

static const intptr_t kStartIsolateArgumentsLength = 2;

static void SetupStartIsolateArguments(
    const DartControllerConfig& config,
    Dart_Handle main_closure,
    Dart_Handle* start_isolate_args) {
  // start_isolate_args:
  // [0] -> main closure
  // [1] -> args list.
  // args list:
  // [0] -> mojo handle.
  // [1] -> script uri
  // [2] -> list of script arguments in config.
  start_isolate_args[0] = main_closure;     // entryPoint
  DART_CHECK_VALID(start_isolate_args[0]);
  start_isolate_args[1] = Dart_NewList(3);  // args
  DART_CHECK_VALID(start_isolate_args[1]);
  Dart_Handle script_uri = Dart_NewStringFromUTF8(
      reinterpret_cast<const uint8_t*>(config.script_uri.data()),
      config.script_uri.length());
  Dart_ListSetAt(start_isolate_args[1], 0, Dart_NewInteger(config.handle));
  Dart_ListSetAt(start_isolate_args[1], 1, script_uri);
  Dart_Handle script_args = Dart_NewList(config.script_flags_count);
  DART_CHECK_VALID(script_args);
  Dart_ListSetAt(start_isolate_args[1], 2, script_args);
  for (intptr_t i = 0; i < config.script_flags_count; i++) {
    Dart_ListSetAt(script_args, i,
                   Dart_NewStringFromCString(config.script_flags[i]));
  }
}

static void RunIsolate(Dart_Isolate isolate,
                       const DartControllerConfig& config) {
  tonic::DartIsolateScope isolate_scope(isolate);
  tonic::DartApiScope api_scope;

  Dart_Handle result;

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

  Dart_Handle start_isolate_args[kStartIsolateArgumentsLength];
  SetupStartIsolateArguments(config, main_closure, &start_isolate_args[0]);
  Dart_Handle isolate_lib =
      Dart_LookupLibrary(Dart_NewStringFromCString(kIsolateLibURL));
  DART_CHECK_VALID(isolate_lib);

  result = Dart_Invoke(isolate_lib,
                       Dart_NewStringFromCString("_startMainIsolate"),
                       kStartIsolateArgumentsLength,
                       start_isolate_args);
  DART_CHECK_VALID(result);

  result = Dart_RunLoop();
  tonic::LogIfError(result);
  DART_CHECK_VALID(result);
}

Dart_Handle DartController::LibraryTagHandler(Dart_LibraryTag tag,
                                              Dart_Handle library,
                                              Dart_Handle url) {
  if (tag == Dart_kCanonicalizeUrl) {
    std::string string = tonic::StdStringFromDart(url);
    if (StartsWithASCII(string, "dart:", true))
      return url;
  }
  return tonic::DartLibraryLoader::HandleLibraryTag(tag, library, url);
}

Dart_Isolate DartController::CreateIsolateHelper(
    void* dart_app,
    bool strict_compilation,
    IsolateCallbacks callbacks,
    const std::string& script_uri,
    const std::string& package_root,
    char** error,
    bool use_network_loader) {
  auto isolate_data = new MojoDartState(dart_app,
                                        strict_compilation,
                                        callbacks,
                                        script_uri,
                                        package_root);
  Dart_Isolate isolate =
      Dart_CreateIsolate(script_uri.c_str(), "main", isolate_snapshot_buffer,
                         nullptr, isolate_data, error);
  if (isolate == nullptr) {
    delete isolate_data;
    return nullptr;
  }
  Dart_ExitIsolate();

  isolate_data->SetIsolate(isolate);
  if (service_connector_ != nullptr) {
    // This is not supported in the unit test harness.
    isolate_data->BindNetworkService(
        service_connector_->ConnectToService(
            DartControllerServiceConnector::kNetworkServiceId));
  }

  // Setup isolate and load script.
  {
    tonic::DartIsolateScope isolate_scope(isolate);
    tonic::DartApiScope api_scope;
    // Setup loader.
    const char* package_root_str = nullptr;
    if (package_root.empty()) {
      package_root_str = "/";
    } else {
      package_root_str = package_root.c_str();
    }
    if (use_network_loader) {
      mojo::NetworkService* network_service = isolate_data->network_service();
      isolate_data->set_library_provider(
          new tonic::DartLibraryProviderNetwork(network_service));
    } else {
      isolate_data->set_library_provider(
          new tonic::DartLibraryProviderFiles(
              base::FilePath(package_root_str)));
    }
    Dart_Handle result = Dart_SetLibraryTagHandler(LibraryTagHandler);
    DART_CHECK_VALID(result);
    // Toggle checked mode.
    Dart_IsolateSetStrictCompilation(strict_compilation);
    // Setup the native resolvers for the builtin libraries as they are not set
    // up when the snapshot is read.
    CHECK(isolate_snapshot_buffer != nullptr);
    Builtin::PrepareLibrary(Builtin::kBuiltinLibrary);
    Builtin::PrepareLibrary(Builtin::kMojoInternalLibrary);
    Builtin::PrepareLibrary(Builtin::kDartMojoIoLibrary);

    // TODO(johnmccutchan): Remove?
    if (!callbacks.create.is_null()) {
      DCHECK(false);
      callbacks.create.Run(script_uri.c_str(),
                           "main",
                           package_root.c_str(),
                           isolate_data,
                           error);
    }

    // Prepare builtin and its dependent libraries.
    result = PrepareIsolateLibraries(package_root, script_uri);
    DART_CHECK_VALID(result);

    // The VM is creating the service isolate.
    if (Dart_IsServiceIsolate(isolate)) {
      const intptr_t port = SupportDartMojoIo() ? 0 : -1;
      InitializeDartMojoIo();
      StartHandleWatcherIsolate();
      if (!VmService::Setup("127.0.0.1", port)) {
        *error = strdup(VmService::GetErrorMessage());
        return nullptr;
      }
      return isolate;
    }

    if ((script_uri == "vm-service") || (script_uri == "stop-handle-watcher")) {
      // Special case for starting and stopping the the handle watcher isolate.
      LoadEmptyScript(script_uri);
    } else {
      LoadScript(script_uri, isolate_data->library_provider());
    }

    InitializeDartMojoIo();
  }

  // Make the isolate runnable so that it is ready to handle messages.
  bool retval = Dart_IsolateMakeRunnable(isolate);
  if (!retval) {
    *error = strdup("Invalid isolate state - Unable to make it runnable");
    Dart_EnterIsolate(isolate);
    Dart_ShutdownIsolate();
    return nullptr;
  }

  DCHECK(Dart_CurrentIsolate() == nullptr);

  return isolate;
}

Dart_Isolate DartController::IsolateCreateCallback(const char* script_uri,
                                                   const char* main,
                                                   const char* package_root,
                                                   Dart_IsolateFlags* flags,
                                                   void* callback_data,
                                                   char** error) {
  auto parent_isolate_data = MojoDartState::Cast(callback_data);
  std::string script_uri_string;
  std::string package_root_string;

  if (script_uri == nullptr) {
    if (callback_data == nullptr) {
      *error = strdup("Invalid 'callback_data' - Unable to spawn new isolate");
      return nullptr;
    }
    script_uri_string = parent_isolate_data->script_uri();
  } else {
    script_uri_string = std::string(script_uri);
  }
  if (package_root == nullptr) {
    if (parent_isolate_data != nullptr) {
      package_root_string = parent_isolate_data->package_root();
    }
  } else {
    package_root_string = std::string(package_root);
  }
  // Inherit parameters from parent isolate (if any).
  void* dart_app = nullptr;
  bool strict_compilation = true;
  // TODO(johnmccutchan): Use parent's setting?
  bool use_network_loader = false;
  IsolateCallbacks callbacks;
  if (parent_isolate_data != nullptr) {
    dart_app = parent_isolate_data->application_data();
    strict_compilation = parent_isolate_data->strict_compilation();
    callbacks = parent_isolate_data->callbacks();
  }
  return CreateIsolateHelper(dart_app,
                             strict_compilation,
                             callbacks,
                             script_uri_string,
                             package_root_string,
                             error,
                             use_network_loader);
}

void DartController::IsolateShutdownCallback(void* callback_data) {
  {
    tonic::DartApiScope api_scope;
    ShutdownDartMojoIo();
  }

  auto isolate_data = MojoDartState::Cast(callback_data);
  if (!isolate_data->callbacks().shutdown.is_null()) {
    isolate_data->callbacks().shutdown.Run(callback_data);
  }
  delete isolate_data;
}

void DartController::UnhandledExceptionCallback(Dart_Handle error) {
  auto isolate_data = MojoDartState::Current();
  if (!isolate_data->callbacks().exception.is_null()) {
    // TODO(zra): Instead of passing an error handle, it may make life easier
    // for clients if we pass any error string here instead.
    isolate_data->callbacks().exception.Run(error);
  }

  // Close handles generated by the isolate.
  std::set<MojoHandle>& handles = isolate_data->unclosed_handles();
  for (auto it = handles.begin(); it != handles.end(); ++it) {
    MojoClose((*it));
  }
  handles.clear();
}


bool DartController::initialized_ = false;
bool DartController::service_isolate_running_ = false;
bool DartController::strict_compilation_ = false;
DartControllerServiceConnector* DartController::service_connector_ = nullptr;
base::Lock DartController::lock_;

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
      nullptr, false, callbacks, "stop-handle-watcher", "", &error, false);
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
  tonic::LogIfError(result);
  DART_CHECK_VALID(result);

  Dart_ExitScope();
  Dart_ShutdownIsolate();
}

void DartController::InitVmIfNeeded(Dart_EntropySource entropy,
                                    const char** vm_flags,
                                    int vm_flags_count) {
  base::AutoLock al(lock_);
  if (initialized_) {
    return;
  }

  const int kNumFlags = vm_flags_count + 1;
  const char* flags[kNumFlags];

  // TODO(zra): Fix Dart VM Shutdown race.
  // There is a bug in Dart VM shutdown which causes its thread pool threads
  // to potentially fail to exit when the rest of the VM is going down. This
  // results in a segfault if they begin running again after the Dart
  // embedder has been unloaded. Setting this flag to 0 ensures that these
  // threads sleep forever instead of waking up and trying to run code
  // that isn't there anymore.
  flags[0] = "--worker-timeout-millis=0";

  for (int i = 0; i < vm_flags_count; ++i) {
    flags[i + 1] = vm_flags[i];
  }

  bool result = Dart_SetVMFlags(kNumFlags, flags);
  CHECK(result);

  // This should be called before calling Dart_Initialize.
  tonic::DartDebugger::InitDebugger();

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

void DartController::BlockWaitingForDependencies(
      tonic::DartLibraryLoader* loader,
      const std::unordered_set<tonic::DartDependency*>& dependencies) {
  {
    scoped_refptr<base::SingleThreadTaskRunner> task_runner =
        base::MessageLoop::current()->task_runner();
    base::RunLoop run_loop;
    task_runner->PostTask(
        FROM_HERE,
        base::Bind(
            &tonic::DartLibraryLoader::WaitForDependencies,
            base::Unretained(loader),
            dependencies,
            base::Bind(
               base::IgnoreResult(&base::SingleThreadTaskRunner::PostTask),
               task_runner.get(), FROM_HERE,
               run_loop.QuitClosure())));
    run_loop.Run();
  }
}

void DartController::LoadEmptyScript(const std::string& script_uri) {
  Dart_Handle uri = Dart_NewStringFromUTF8(
      reinterpret_cast<const uint8_t*>(script_uri.c_str()),
      script_uri.length());
  DART_CHECK_VALID(uri);
  Dart_Handle script_source = Dart_NewStringFromCString("");
  DART_CHECK_VALID(script_source);
  Dart_Handle result = Dart_LoadScript(uri, script_source, 0, 0);
  DART_CHECK_VALID(result);
  tonic::LogIfError(Dart_FinalizeLoading(true));
}

void DartController::InnerLoadScript(
    const std::string& script_uri,
    tonic::DartLibraryProvider* library_provider) {
  // When spawning isolates, Dart expects the script loading to be completed
  // before returning from the isolate creation callback. The mojo dart
  // controller also expects the isolate to be finished loading a script
  // before the isolate creation callback returns.

  // We block here by creating a nested message pump and waiting for the load
  // to complete.

  DCHECK(base::MessageLoop::current() != nullptr);
  base::MessageLoop::ScopedNestableTaskAllower allow(
      base::MessageLoop::current());

  // Initiate the load.
  auto dart_state = tonic::DartState::Current();
  DCHECK(library_provider != nullptr);
  tonic::DartLibraryLoader& loader = dart_state->library_loader();
  loader.set_library_provider(library_provider);
  std::unordered_set<tonic::DartDependency*> dependencies;
  {
    tonic::DartDependencyCatcher dependency_catcher(loader);
    loader.LoadScript(script_uri);
    // Copy dependencies before dependency_catcher goes out of scope.
    dependencies = std::unordered_set<tonic::DartDependency*>(
        dependency_catcher.dependencies());
  }

  // Run inner message loop.
  BlockWaitingForDependencies(&loader, dependencies);

  // Finalize loading.
  tonic::LogIfError(Dart_FinalizeLoading(true));
}

void DartController::LoadScript(const std::string& script_uri,
                                tonic::DartLibraryProvider* library_provider) {
  if (base::MessageLoop::current() == nullptr) {
    // Threads running on the Dart thread pool may not have a message loop,
    // we rely on a message loop during loading. Create a temporary one
    // here.
    base::MessageLoop message_loop(common::MessagePumpMojo::Create());
    InnerLoadScript(script_uri, library_provider);
  } else {
    // Thread has a message loop, use it.
    InnerLoadScript(script_uri, library_provider);
  }
}

bool DartController::RunSingleDartScript(const DartControllerConfig& config) {
  InitVmIfNeeded(config.entropy,
                 config.vm_flags,
                 config.vm_flags_count);
  Dart_Isolate isolate = CreateIsolateHelper(config.application_data,
                                             config.strict_compilation,
                                             config.callbacks,
                                             config.script_uri,
                                             config.package_root,
                                             config.error,
                                             config.use_network_loader);
  if (isolate == nullptr) {
    return false;
  }

  RunIsolate(isolate, config);

  // Cleanup.
  Dart_EnterIsolate(isolate);
  Dart_ShutdownIsolate();
  Dart_Cleanup();
  return true;
}

static bool generateEntropy(uint8_t* buffer, intptr_t length) {
  base::RandBytes(reinterpret_cast<void*>(buffer), length);
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
  Dart_Isolate isolate = CreateIsolateHelper(config.application_data,
                                             strict,
                                             config.callbacks,
                                             config.script_uri,
                                             config.package_root,
                                             config.error,
                                             config.use_network_loader);
  if (isolate == nullptr) {
    return false;
  }

  RunIsolate(isolate, config);

  // Cleanup.
  Dart_EnterIsolate(isolate);
  Dart_ShutdownIsolate();

  return true;
}

void DartController::Shutdown() {
  base::AutoLock al(lock_);
  if (!initialized_) {
    return;
  }
  StopHandleWatcherIsolate();
  Dart_Cleanup();
  service_isolate_running_ = false;
  initialized_ = false;
}

}  // namespace apps
}  // namespace mojo
