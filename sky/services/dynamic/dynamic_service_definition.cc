// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/services/dynamic/dynamic_service_definition.h"

#include "base/logging.h"
#include <dlfcn.h>

namespace sky {
namespace services {

std::unique_ptr<DynamicServiceDefinition> DynamicServiceDefinition::Initialize(
    const mojo::String& dylib_path) {
  auto definition = std::unique_ptr<DynamicServiceDefinition>(
      new DynamicServiceDefinition(dylib_path));

  if (definition->IsReady()) {
    return definition;
  }

  return nullptr;
}

DynamicServiceDefinition::DynamicServiceDefinition(
    const mojo::String& dylib_path)
    : service_procs_(), is_ready_(false) {
  Setup(dylib_path);
}

DynamicServiceDefinition::~DynamicServiceDefinition() {
  Teardown();
}

void DynamicServiceDefinition::Setup(const mojo::String& dylib_path) {
  std::lock_guard<std::mutex> lock(lifecycle_mtx_);

  if (!OpenDylib(dylib_path)) {
    LOG(ERROR) << "Could not open the service dylib.";
    return;
  }

  // Remember, the service version proc is the only absolutely stable part
  // of the runtime. All other proc acquisition and setup tasks must be
  // performed *after* the version check is complete.

  if (!AcquireServiceVersionProc()) {
    LOG(ERROR) << "Could not acquire proc for service version check.";
    return;
  }

  if (!CheckServiceVersion()) {
    LOG(ERROR) << "Service and embedder versions mismatch.";
    return;
  }

  if (!AcquireServiceProcs()) {
    LOG(ERROR) << "Could not acquire procs for loading the service.";
    return;
  }

  if (!InstallSystemThunks()) {
    LOG(ERROR) << "Could not install system thunks to process the service.";
    return;
  }

  if (!InvokeLibraryOnLoad()) {
    LOG(ERROR) << "Could not invoke library OnLoad.";
    return;
  }

  is_ready_ = true;
}

void DynamicServiceDefinition::Teardown() {
  std::lock_guard<std::mutex> lock(lifecycle_mtx_);

  is_ready_ = false;

  InvokeLibraryOnUnload();

  CloseDylib();
}

bool DynamicServiceDefinition::IsReady() const {
  return is_ready_;
}

bool DynamicServiceDefinition::OpenDylib(const mojo::String& dylib_path) {
  dlerror();
  dylib_handle_ = dlopen(dylib_path.data(), RTLD_NOW);

  if (dylib_handle_ == nullptr || dlerror() != nullptr) {
    dylib_handle_ = nullptr;
    return false;
  }

  return true;
}

bool DynamicServiceDefinition::CloseDylib() {
  if (dylib_handle_ == nullptr) {
    return true;
  }

  dlerror();
  dlclose(dylib_handle_);
  return dlerror() == nullptr;
}

static bool AcquireProc(void* handle, const char* name, void** dest) {
  dlerror();
  void* sym = dlsym(handle, name);
  if (sym != nullptr && dlerror() == nullptr) {
    *dest = sym;
    return true;
  }
  return false;
}

bool DynamicServiceDefinition::AcquireServiceVersionProc() {
  return AcquireProc(dylib_handle_, kFlutterServiceGetVersionProcName,
                     reinterpret_cast<void**>(&service_procs_.version));
}

bool DynamicServiceDefinition::AcquireServiceProcs() {
  if (!AcquireProc(dylib_handle_, kFlutterServiceOnLoadProcName,
                   reinterpret_cast<void**>(&service_procs_.load))) {
    return false;
  }

  if (!AcquireProc(dylib_handle_, kFlutterServiceInvokeProcName,
                   reinterpret_cast<void**>(&service_procs_.invoke))) {
    return false;
  }

  if (!AcquireProc(dylib_handle_, kFlutterServiceOnUnloadProcName,
                   reinterpret_cast<void**>(&service_procs_.unload))) {
    return false;
  }

  if (!AcquireProc(dylib_handle_, "MojoSetSystemThunks",
                   reinterpret_cast<void**>(&service_procs_.set_thunks))) {
    return false;
  }

  return true;
}

bool DynamicServiceDefinition::CheckServiceVersion() {
  if (service_procs_.version == nullptr) {
    return false;
  }

  const FlutterServiceVersion* embedder_version = FlutterServiceGetVersion();
  const FlutterServiceVersion* service_version = service_procs_.version();

  return FlutterServiceVersionsCompatible(embedder_version, service_version);
}

bool DynamicServiceDefinition::InstallSystemThunks() {
  if (service_procs_.set_thunks == nullptr) {
    return false;
  }

  MojoSystemThunks embedder_thunks = MojoMakeSystemThunks();

  size_t result = service_procs_.set_thunks(&embedder_thunks);

  if (result > sizeof(MojoSystemThunks)) {
    // The dylib expects to use a system thunks table that is larger than what
    // is currently supported by the embedder. This indicates that the embedder
    // is older than the dylib.
    return false;
  }

  return true;
}

bool DynamicServiceDefinition::InvokeLibraryOnLoad() {
  if (service_procs_.load == nullptr) {
    return false;
  }

  service_procs_.load(mojo::Environment::GetDefaultAsyncWaiter(),
                      mojo::Environment::GetDefaultLogger());
  return true;
}

bool DynamicServiceDefinition::InvokeLibraryOnUnload() {
  if (service_procs_.unload == nullptr) {
    return false;
  }

  service_procs_.unload();
  return true;
}

void DynamicServiceDefinition::InvokeServiceHandler(
    mojo::ScopedMessagePipeHandle handle,
    const mojo::String& service_name) const {
  if (!is_ready_ || service_procs_.invoke == nullptr) {
    // Handle goes out of scope and is collected
    return;
  }

  mojo::MessagePipeHandle rawMessageHandle = handle.release();
  // The service assumes ownership of the handle
  service_procs_.invoke(rawMessageHandle.value(), service_name.data());
}

}  // namespace services
}  // namespace sky
