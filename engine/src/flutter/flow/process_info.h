// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_PROCESS_INFO_H_
#define FLUTTER_FLOW_PROCESS_INFO_H_

#include "lib/ftl/macros.h"

namespace flow {

/// The CompositorContext attempts to collect information from the process for
/// instrumentation purposes. The compositor does not have the platform
/// specific capabilities to collect this information on its own. The platform
/// can choose to provide this information however.
class ProcessInfo {
 public:
  virtual ~ProcessInfo() = default;

  virtual bool SampleNow() = 0;

  /// Virtual memory size in bytes.
  virtual size_t GetVirtualMemorySize() = 0;

  /// Resident memory size in bytes.
  virtual size_t GetResidentMemorySize() = 0;
};

}  // namespace flow

#endif  // FLUTTER_FLOW_PROCESS_INFO_H_
