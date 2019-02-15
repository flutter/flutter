// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_RUNTIME_DART_VM_DATA_H_
#define FLUTTER_RUNTIME_DART_VM_DATA_H_

#include "flutter/fml/macros.h"
#include "flutter/runtime/dart_snapshot.h"

namespace blink {

class DartVMData {
 public:
  static std::shared_ptr<const DartVMData> Create(
      Settings settings,
      fml::RefPtr<DartSnapshot> vm_snapshot,
      fml::RefPtr<DartSnapshot> isolate_snapshot,
      fml::RefPtr<DartSnapshot> shared_snapshot);

  ~DartVMData();

  const Settings& GetSettings() const;

  const DartSnapshot& GetVMSnapshot() const;

  fml::RefPtr<const DartSnapshot> GetIsolateSnapshot() const;

  fml::RefPtr<const DartSnapshot> GetSharedSnapshot() const;

 private:
  const Settings settings_;
  const fml::RefPtr<const DartSnapshot> vm_snapshot_;
  const fml::RefPtr<const DartSnapshot> isolate_snapshot_;
  const fml::RefPtr<const DartSnapshot> shared_snapshot_;

  DartVMData(Settings settings,
             fml::RefPtr<const DartSnapshot> vm_snapshot,
             fml::RefPtr<const DartSnapshot> isolate_snapshot,
             fml::RefPtr<const DartSnapshot> shared_snapshot);

  FML_DISALLOW_COPY_AND_ASSIGN(DartVMData);
};

}  // namespace blink

#endif  // FLUTTER_RUNTIME_DART_VM_DATA_H_
