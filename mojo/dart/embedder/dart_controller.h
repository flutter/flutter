// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_DART_EMBEDDER_DART_CONTROLLER_H_
#define MOJO_DART_EMBEDDER_DART_CONTROLLER_H_

#include "dart/runtime/include/dart_api.h"
#include "mojo/dart/embedder/isolate_data.h"
#include "mojo/public/c/system/types.h"

namespace mojo {
namespace dart {

struct DartControllerConfig {
  void* application_data;
  bool strict_compilation;
  std::string script;
  std::string script_uri;
  std::string package_root;
  IsolateCallbacks callbacks;
  Dart_EntropySource entropy;
  const char** arguments;
  int arguments_count;
  MojoHandle handle;
  // TODO(zra): search for the --compile_all flag in arguments where needed.
  bool compile_all;
  char** error;
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
                                          const std::string& script,
                                          const std::string& script_uri,
                                          const std::string& package_root,
                                          char** error);

  static void InitVmIfNeeded(Dart_EntropySource entropy,
                             const char** arguments,
                             int arguments_count);
  static bool initialized_;
  static bool strict_compilation_;
  static bool service_isolate_running_;
  static DartControllerServiceConnector* service_connector_;
};

}  // namespace dart
}  // namespace mojo

#endif  // MOJO_DART_EMBEDDER_DART_CONTROLLER_H_
