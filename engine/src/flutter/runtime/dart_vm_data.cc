// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/runtime/dart_vm_data.h"

#include <utility>

namespace flutter {

std::shared_ptr<const DartVMData> DartVMData::Create(
    const Settings& settings,
    fml::RefPtr<const DartSnapshot> isolate_snapshot) {
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

  fml::RefPtr<const DartSnapshot> service_isolate_snapshot =
      DartSnapshot::VMServiceIsolateSnapshotFromSettings(settings);

  return std::shared_ptr<const DartVMData>(new DartVMData(
      settings,                            //
      std::move(isolate_snapshot),         //
      std::move(service_isolate_snapshot)  //
      ));
}

DartVMData::DartVMData(const Settings& settings,
                       fml::RefPtr<const DartSnapshot> isolate_snapshot,
                       fml::RefPtr<const DartSnapshot> service_isolate_snapshot)
    : settings_(settings),
      isolate_snapshot_(std::move(isolate_snapshot)),
      service_isolate_snapshot_(std::move(service_isolate_snapshot)) {}

DartVMData::~DartVMData() = default;

const Settings& DartVMData::GetSettings() const {
  return settings_;
}

fml::RefPtr<const DartSnapshot> DartVMData::GetSnapshot() const {
  return isolate_snapshot_;
}

fml::RefPtr<const DartSnapshot> DartVMData::GetServiceIsolateSnapshot() const {
  // Use the specialized snapshot for the service isolate if the embedder
  // provides one.  Otherwise, use the application snapshot.
  return service_isolate_snapshot_ ? service_isolate_snapshot_
                                   : isolate_snapshot_;
}

bool DartVMData::GetServiceIsolateSnapshotNullSafety() const {
  if (service_isolate_snapshot_) {
    // The specialized snapshot for the service isolate is always built
    // using null safety.  However, calling Dart_DetectNullSafety on
    // the service isolate snapshot will not work as expected - it will
    // instead return a cached value representing the app snapshot.
    return true;
  } else {
    return isolate_snapshot_->IsNullSafetyEnabled(nullptr);
  }
}

}  // namespace flutter
