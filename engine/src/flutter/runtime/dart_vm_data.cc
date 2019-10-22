// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/runtime/dart_vm_data.h"

namespace flutter {

std::shared_ptr<const DartVMData> DartVMData::Create(
    Settings settings,
    fml::RefPtr<DartSnapshot> vm_snapshot,
    fml::RefPtr<DartSnapshot> isolate_snapshot) {
  if (!vm_snapshot || !vm_snapshot->IsValid()) {
    // Caller did not provide a valid VM snapshot. Attempt to infer one
    // from the settings.
    vm_snapshot = DartSnapshot::VMSnapshotFromSettings(settings);
    if (!vm_snapshot) {
      FML_LOG(ERROR)
          << "VM snapshot invalid and could not be inferred from settings.";
      return {};
    }
  }

  if (!isolate_snapshot || !isolate_snapshot->IsValid()) {
    // Caller did not provide a valid isolate snapshot. Attempt to infer one
    // from the settings.
    isolate_snapshot = DartSnapshot::IsolateSnapshotFromSettings(settings);
    if (!isolate_snapshot) {
      FML_LOG(ERROR) << "Isolate snapshot invalid and could not be inferred "
                        "from settings.";
      return {};
    }
  }

  return std::shared_ptr<const DartVMData>(new DartVMData(
      std::move(settings),         //
      std::move(vm_snapshot),      //
      std::move(isolate_snapshot)  //
      ));
}

DartVMData::DartVMData(Settings settings,
                       fml::RefPtr<const DartSnapshot> vm_snapshot,
                       fml::RefPtr<const DartSnapshot> isolate_snapshot)
    : settings_(settings),
      vm_snapshot_(vm_snapshot),
      isolate_snapshot_(isolate_snapshot) {}

DartVMData::~DartVMData() = default;

const Settings& DartVMData::GetSettings() const {
  return settings_;
}

const DartSnapshot& DartVMData::GetVMSnapshot() const {
  return *vm_snapshot_;
}

fml::RefPtr<const DartSnapshot> DartVMData::GetIsolateSnapshot() const {
  return isolate_snapshot_;
}

}  // namespace flutter
