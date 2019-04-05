// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/runtime/dart_vm_lifecycle.h"

#include <mutex>

namespace blink {

// We need to explicitly put the constructor and destructor of the DartVM in the
// critical section. All accesses (not just const members) to the global VM
// object weak pointer are behind this mutex.
static std::mutex gVMMutex;
static std::weak_ptr<DartVM> gVM FML_GUARDED_BY(gVMMutex);
static std::shared_ptr<DartVM>* gVMLeak FML_GUARDED_BY(gVMMutex);

// We are going to be modifying more than just the control blocks of the
// following weak pointers (in the |Create| case where an old VM could not be
// reused). Ideally, we would use |std::atomic<std::weak_ptr<T>>| specialization
// but that is only available since C++20. We don't expect contention on these
// locks so we just use one mutex for all.
static std::mutex gVMDependentsMutex;
static std::weak_ptr<const DartVMData> gVMData
    FML_GUARDED_BY(gVMDependentsMutex);
static std::weak_ptr<ServiceProtocol> gVMServiceProtocol
    FML_GUARDED_BY(gVMDependentsMutex);
static std::weak_ptr<IsolateNameServer> gVMIsolateNameServer
    FML_GUARDED_BY(gVMDependentsMutex);

DartVMRef::DartVMRef(std::shared_ptr<DartVM> vm) : vm_(vm) {}

DartVMRef::DartVMRef(DartVMRef&& other) = default;

DartVMRef::~DartVMRef() {
  if (!vm_) {
    // If there is no valid VM (possible via a move), there is no way that the
    // decrement on the shared pointer can cause a collection. Avoid acquiring
    // the lifecycle lock in this case. This is just working around a
    // pessimization and not required for correctness.
    return;
  }
  std::lock_guard<std::mutex> lifecycle_lock(gVMMutex);
  vm_.reset();
}

DartVMRef DartVMRef::Create(Settings settings,
                            fml::RefPtr<DartSnapshot> vm_snapshot,
                            fml::RefPtr<DartSnapshot> isolate_snapshot,
                            fml::RefPtr<DartSnapshot> shared_snapshot) {
  std::lock_guard<std::mutex> lifecycle_lock(gVMMutex);

  // If there is already a running VM in the process, grab a strong reference to
  // it.
  if (auto vm = gVM.lock()) {
    FML_DLOG(WARNING) << "Attempted to create a VM in a process where one was "
                         "already running. Ignoring arguments for current VM "
                         "create call and reusing the old VM.";
    // There was already a running VM in the process,
    return DartVMRef{std::move(vm)};
  }

  std::lock_guard<std::mutex> dependents_lock(gVMDependentsMutex);

  gVMData.reset();
  gVMServiceProtocol.reset();
  gVMIsolateNameServer.reset();
  gVM.reset();

  // If there is no VM in the process. Initialize one, hold the weak reference
  // and pass a strong reference to the caller.
  auto isolate_name_server = std::make_shared<IsolateNameServer>();
  auto vm = DartVM::Create(std::move(settings),          //
                           std::move(vm_snapshot),       //
                           std::move(isolate_snapshot),  //
                           std::move(shared_snapshot),   //
                           isolate_name_server           //
  );

  if (!vm) {
    FML_LOG(ERROR) << "Could not create Dart VM instance.";
    return {nullptr};
  }

  gVMData = vm->GetVMData();
  gVMServiceProtocol = vm->GetServiceProtocol();
  gVMIsolateNameServer = isolate_name_server;
  gVM = vm;

  if (settings.leak_vm) {
    gVMLeak = new std::shared_ptr<DartVM>(vm);
  }

  return DartVMRef{std::move(vm)};
}

bool DartVMRef::IsInstanceRunning() {
  std::lock_guard<std::mutex> lock(gVMMutex);
  return !gVM.expired();
}

std::shared_ptr<const DartVMData> DartVMRef::GetVMData() {
  std::lock_guard<std::mutex> lock(gVMDependentsMutex);
  return gVMData.lock();
}

std::shared_ptr<ServiceProtocol> DartVMRef::GetServiceProtocol() {
  std::lock_guard<std::mutex> lock(gVMDependentsMutex);
  return gVMServiceProtocol.lock();
}

std::shared_ptr<IsolateNameServer> DartVMRef::GetIsolateNameServer() {
  std::lock_guard<std::mutex> lock(gVMDependentsMutex);
  return gVMIsolateNameServer.lock();
}

DartVM* DartVMRef::GetRunningVM() {
  std::lock_guard<std::mutex> lock(gVMMutex);
  auto vm = gVM.lock().get();
  FML_CHECK(vm) << "Caller assumed VM would be running when it wasn't";
  return vm;
}

}  // namespace blink
