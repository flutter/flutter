// Copyright 2017 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_RUNTIME_DART_VM_H_
#define FLUTTER_RUNTIME_DART_VM_H_

#include <functional>
#include <string>
#include <vector>

#include "flutter/common/settings.h"
#include "flutter/runtime/dart_isolate.h"
#include "flutter/runtime/dart_snapshot.h"
#include "flutter/runtime/service_protocol.h"
#include "lib/fxl/build_config.h"
#include "lib/fxl/functional/closure.h"
#include "lib/fxl/macros.h"
#include "lib/fxl/memory/ref_counted.h"
#include "lib/fxl/memory/ref_ptr.h"
#include "lib/fxl/memory/weak_ptr.h"
#include "third_party/dart/runtime/include/dart_api.h"

namespace blink {

class DartVM : public fxl::RefCountedThreadSafe<DartVM> {
 public:
  class PlatformKernel;

  static fxl::RefPtr<DartVM> ForProcess(Settings settings);

  static fxl::RefPtr<DartVM> ForProcess(
      Settings settings,
      fxl::RefPtr<DartSnapshot> vm_snapshot,
      fxl::RefPtr<DartSnapshot> isolate_snapshot);

  static fxl::RefPtr<DartVM> ForProcessIfInitialized();

  static bool IsRunningPrecompiledCode();

  const Settings& GetSettings() const;

  PlatformKernel* GetPlatformKernel() const;

  const DartSnapshot& GetVMSnapshot() const;

  fxl::RefPtr<DartSnapshot> GetIsolateSnapshot() const;

  fxl::WeakPtr<DartVM> GetWeakPtr();

  ServiceProtocol& GetServiceProtocol();

 private:
  const Settings settings_;
  const fxl::RefPtr<DartSnapshot> vm_snapshot_;
  const fxl::RefPtr<DartSnapshot> isolate_snapshot_;
  std::unique_ptr<fml::Mapping> platform_kernel_mapping_;
  PlatformKernel* platform_kernel_ = nullptr;
  ServiceProtocol service_protocol_;
  fxl::WeakPtrFactory<DartVM> weak_factory_;

  DartVM(const Settings& settings,
         fxl::RefPtr<DartSnapshot> vm_snapshot,
         fxl::RefPtr<DartSnapshot> isolate_snapshot);

  ~DartVM();

  FRIEND_REF_COUNTED_THREAD_SAFE(DartVM);
  FRIEND_MAKE_REF_COUNTED(DartVM);
  FXL_DISALLOW_COPY_AND_ASSIGN(DartVM);
};

}  // namespace blink

#endif  // FLUTTER_RUNTIME_DART_VM_H_
