// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SERVICES_DYNAMIC_DYNAMIC_SERVICE_DEFINITION_H_
#define SKY_SERVICES_DYNAMIC_DYNAMIC_SERVICE_DEFINITION_H_

#include "mojo/public/cpp/system/macros.h"
#include "mojo/public/cpp/bindings/string.h"
#include "mojo/public/platform/native/system_thunks.h"
#include "sky/services/dynamic/dynamic_service_embedder.h"

#include <mutex>

namespace sky {
namespace services {

class DynamicServiceDefinition {
 public:
  static std::unique_ptr<DynamicServiceDefinition> Initialize(
      const mojo::String& dylib_path);

  void InvokeServiceHandler(mojo::ScopedMessagePipeHandle handle,
                            const mojo::String& service_name) const;

  ~DynamicServiceDefinition();

 private:
  struct ServiceProcs {
    FlutterServiceGetVersionProc version;
    FlutterServiceOnLoadProc load;
    FlutterServiceInvokeProc invoke;
    FlutterServiceOnUnloadProc unload;
    MojoSetSystemThunksFn set_thunks;
  };

  explicit DynamicServiceDefinition(const mojo::String& dylib_path);

  bool IsReady() const;

  std::mutex lifecycle_mtx_;

  void* dylib_handle_;
  ServiceProcs service_procs_;
  bool is_ready_;

  void Setup(const mojo::String& dylib_path);
  void Teardown();

  bool OpenDylib(const mojo::String& dylib_path);
  bool CloseDylib();
  bool AcquireServiceVersionProc();
  bool AcquireServiceProcs();
  bool CheckServiceVersion();
  bool InstallSystemThunks();
  bool InvokeLibraryOnLoad();
  bool InvokeLibraryOnUnload();

  MOJO_DISALLOW_COPY_AND_ASSIGN(DynamicServiceDefinition);
};

}  // namespace services
}  // namespace sky

#endif  // SKY_SERVICES_DYNAMIC_DYNAMIC_SERVICE_DEFINITION_H_
