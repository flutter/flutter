// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_DART_EMBEDDER_DART_CONTROLLER_H_
#define MOJO_DART_EMBEDDER_DART_CONTROLLER_H_

#include <unordered_set>

#include "base/synchronization/lock.h"
#include "dart/runtime/include/dart_api.h"
#include "mojo/dart/embedder/mojo_dart_state.h"
#include "mojo/public/c/system/types.h"

namespace tonic {
class DartDependency;
class DartLibraryLoader;
}

namespace mojo {
namespace dart {

struct DartControllerConfig {
  DartControllerConfig()
      : application_data(nullptr),
        strict_compilation(false),
        entropy(nullptr),
        vm_flags(nullptr),
        vm_flags_count(0),
        script_flags(nullptr),
        script_flags_count(0),
        handle(MOJO_HANDLE_INVALID),
        compile_all(false),
        error(nullptr),
        use_network_loader(false) {
  }

  void SetVmFlags(const char** vm_flags, intptr_t vm_flags_count) {
    this->vm_flags = vm_flags;
    this->vm_flags_count = vm_flags_count;

    // See if compile_all is one of the vm flags.
    compile_all = false;
    const char* kCompileAllFlag = "--compile_all";
    const intptr_t kCompileAllFlagLen = strlen(kCompileAllFlag);
    for (intptr_t i = 0; i < vm_flags_count; i++) {
      if (strncmp(vm_flags[i], kCompileAllFlag, kCompileAllFlagLen) == 0) {
        compile_all = true;
      }
    }
  }

  void SetScriptFlags(const char** script_flags, intptr_t script_flags_count) {
    this->script_flags = script_flags;
    this->script_flags_count = script_flags_count;
  }

  void* application_data;
  bool strict_compilation;
  std::string script_uri;
  std::string package_root;
  IsolateCallbacks callbacks;
  Dart_EntropySource entropy;
  const char** vm_flags;
  int vm_flags_count;
  const char** script_flags;
  int script_flags_count;
  MojoHandle handle;
  bool compile_all;
  char** error;
  bool use_network_loader;
};

// The DartController may need to request for services to be connected
// to for an isolate that isn't associated with a Mojo application. An
// implementation of this class can be passed to the DartController during
// initialization. ConnectToService requests can come from any thread.
//
// An implementation of this interface is available from the Dart content
// handler, where connections are made via the content handler application.
class DartControllerServiceConnector {
 public:
  // List of services that are supported.
  enum ServiceId {
    kNetworkServiceId,
    kNumServiceIds,
  };

  DartControllerServiceConnector() {}
  virtual ~DartControllerServiceConnector() {}

  // Connects to service_id and returns a bare MojoHandle. Calls to this
  // can be made from any thread.
  virtual MojoHandle ConnectToService(ServiceId service_id) = 0;
};

class DartController {
 public:
  // Initializes the VM, starts up Dart's handle watcher, and runs the script
  // config.script to completion. This function returns when the script exits
  // and the handle watcher is shutdown. If you need to run multiple Dart
  // scripts in the same VM, use the calls below.
  static bool RunSingleDartScript(const DartControllerConfig& config);

  // Initializes the Dart VM, and starts up Dart's handle watcher.
  // If strict_compilation is true, the VM runs scripts with assertions and
  // type checking enabled.
  static bool Initialize(DartControllerServiceConnector* service_connector,
                         bool strict_compilation);

  // Assumes Initialize has been called. Runs the main function using the
  // script, arguments, and package_root given by 'config'.
  static bool RunDartScript(const DartControllerConfig& config);

  // Waits for the handle watcher isolate to finish and shuts down the VM.
  static void Shutdown();

  // Does this controller support the 'dart:io' library?
  static bool SupportDartMojoIo();
  // Initialize 'dart:io' for the current isolate.
  static void InitializeDartMojoIo();
  // Shutdown 'dart:io' for the current isolate.
  static void ShutdownDartMojoIo();

  static Dart_Handle LibraryTagHandler(Dart_LibraryTag tag,
                                       Dart_Handle library,
                                       Dart_Handle url);

 private:

  // Start the handle watcher isolate.
  static void StartHandleWatcherIsolate();
  // Stop the handle watcher isolate.
  static void StopHandleWatcherIsolate();

  // Dart API callback(s).
  static Dart_Isolate IsolateCreateCallback(const char* script_uri,
                                            const char* main,
                                            const char* package_root,
                                            Dart_IsolateFlags* flags,
                                            void* callback_data,
                                            char** error);
  static void IsolateShutdownCallback(void* callback_data);
  static void UnhandledExceptionCallback(Dart_Handle error);

  // Dart API callback helper(s).
  static Dart_Isolate CreateIsolateHelper(void* dart_app,
                                          bool strict_compilation,
                                          IsolateCallbacks callbacks,
                                          const std::string& script_uri,
                                          const std::string& package_root,
                                          char** error,
                                          bool use_network_loader);

  static void InitVmIfNeeded(Dart_EntropySource entropy,
                             const char** arguments,
                             int arguments_count);

  static void BlockWaitingForDependencies(
      tonic::DartLibraryLoader* loader,
      const std::unordered_set<tonic::DartDependency*>& dependencies);
  static void LoadEmptyScript(const std::string& script_uri);
  static void InnerLoadScript(const std::string& script_uri,
                              tonic::DartLibraryProvider* library_provider);
  static void LoadScript(const std::string& script_uri,
                         tonic::DartLibraryProvider* library_provider);

  static tonic::DartLibraryProvider* library_provider_;
  static base::Lock lock_;
  static bool initialized_;
  static bool strict_compilation_;
  static bool service_isolate_running_;
  static DartControllerServiceConnector* service_connector_;
};

}  // namespace dart
}  // namespace mojo

#endif  // MOJO_DART_EMBEDDER_DART_CONTROLLER_H_
