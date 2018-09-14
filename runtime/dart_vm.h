// Copyright 2017 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_RUNTIME_DART_VM_H_
#define FLUTTER_RUNTIME_DART_VM_H_

#include <functional>
#include <string>
#include <vector>

#include "flutter/common/settings.h"
#include "flutter/fml/build_config.h"
#include "flutter/fml/closure.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/memory/ref_counted.h"
#include "flutter/fml/memory/ref_ptr.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/lib/ui/isolate_name_server/isolate_name_server.h"
#include "flutter/runtime/dart_isolate.h"
#include "flutter/runtime/dart_snapshot.h"
#include "flutter/runtime/service_protocol.h"
#include "third_party/dart/runtime/include/dart_api.h"

namespace blink {

class DartVM : public fml::RefCountedThreadSafe<DartVM> {
 public:
  static fml::RefPtr<DartVM> ForProcess(Settings settings);

  static fml::RefPtr<DartVM> ForProcess(
      Settings settings,
      fml::RefPtr<DartSnapshot> vm_snapshot,
      fml::RefPtr<DartSnapshot> isolate_snapshot,
      fml::RefPtr<DartSnapshot> shared_snapshot);

  static fml::RefPtr<DartVM> ForProcessIfInitialized();

  static bool IsRunningPrecompiledCode();

  static bool IsKernelMapping(const fml::FileMapping* mapping);

  const Settings& GetSettings() const;

  const DartSnapshot& GetVMSnapshot() const;

  IsolateNameServer* GetIsolateNameServer();

  fml::RefPtr<DartSnapshot> GetIsolateSnapshot() const;

  fml::RefPtr<DartSnapshot> GetSharedSnapshot() const;

  fml::WeakPtr<DartVM> GetWeakPtr();

  ServiceProtocol& GetServiceProtocol();

 private:
  const Settings settings_;
  const fml::RefPtr<DartSnapshot> vm_snapshot_;
  IsolateNameServer isolate_name_server_;
  const fml::RefPtr<DartSnapshot> isolate_snapshot_;
  const fml::RefPtr<DartSnapshot> shared_snapshot_;
  ServiceProtocol service_protocol_;
  fml::WeakPtrFactory<DartVM> weak_factory_;

  DartVM(const Settings& settings,
         fml::RefPtr<DartSnapshot> vm_snapshot,
         fml::RefPtr<DartSnapshot> isolate_snapshot,
         fml::RefPtr<DartSnapshot> shared_snapshot);

  ~DartVM();

  FML_FRIEND_REF_COUNTED_THREAD_SAFE(DartVM);
  FML_FRIEND_MAKE_REF_COUNTED(DartVM);
  FML_DISALLOW_COPY_AND_ASSIGN(DartVM);
};

}  // namespace blink

#endif  // FLUTTER_RUNTIME_DART_VM_H_
