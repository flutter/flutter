// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_RUNTIME_DART_VM_H_
#define FLUTTER_RUNTIME_DART_VM_H_

#include <memory>
#include <string>

#include "flutter/common/settings.h"
#include "flutter/fml/build_config.h"
#include "flutter/fml/closure.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/memory/ref_counted.h"
#include "flutter/fml/memory/ref_ptr.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/fml/message_loop.h"
#include "flutter/lib/ui/isolate_name_server/isolate_name_server.h"
#include "flutter/runtime/dart_isolate.h"
#include "flutter/runtime/dart_snapshot.h"
#include "flutter/runtime/dart_vm_data.h"
#include "flutter/runtime/service_protocol.h"
#include "flutter/runtime/skia_concurrent_executor.h"
#include "third_party/dart/runtime/include/dart_api.h"

namespace flutter {

class DartVM {
 public:
  ~DartVM();

  static bool IsRunningPrecompiledCode();

  static size_t GetVMLaunchCount();

  const Settings& GetSettings() const;

  std::shared_ptr<const DartVMData> GetVMData() const;

  std::shared_ptr<ServiceProtocol> GetServiceProtocol() const;

  std::shared_ptr<IsolateNameServer> GetIsolateNameServer() const;

  std::shared_ptr<fml::ConcurrentTaskRunner> GetConcurrentWorkerTaskRunner()
      const;

 private:
  const Settings settings_;
  std::shared_ptr<fml::ConcurrentMessageLoop> concurrent_message_loop_;
  SkiaConcurrentExecutor skia_concurrent_executor_;
  std::shared_ptr<const DartVMData> vm_data_;
  const std::shared_ptr<IsolateNameServer> isolate_name_server_;
  const std::shared_ptr<ServiceProtocol> service_protocol_;

  friend class DartVMRef;
  friend class DartIsolate;

  static std::shared_ptr<DartVM> Create(
      Settings settings,
      fml::RefPtr<DartSnapshot> vm_snapshot,
      fml::RefPtr<DartSnapshot> isolate_snapshot,
      fml::RefPtr<DartSnapshot> shared_snapshot,
      std::shared_ptr<IsolateNameServer> isolate_name_server);

  DartVM(std::shared_ptr<const DartVMData> data,
         std::shared_ptr<IsolateNameServer> isolate_name_server);

  FML_DISALLOW_COPY_AND_ASSIGN(DartVM);
};

}  // namespace flutter

#endif  // FLUTTER_RUNTIME_DART_VM_H_
