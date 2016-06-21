// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_COMMON_TRACING_IMPL_H_
#define MOJO_COMMON_TRACING_IMPL_H_

#include <string>
#include <vector>

#include "base/macros.h"
#include "mojo/common/trace_provider_impl.h"

namespace mojo {

class Shell;

class TracingImpl {
 public:
  TracingImpl();
  ~TracingImpl();

  // This connects to the tracing service and registers ourselves to provide
  // tracing data on demand. |shell| will not be stored (so it need only be
  // valid for this call). |args| may be null, but if not should typically point
  // to the applications "command line".
  void Initialize(Shell* shell, const std::vector<std::string>* args);

 private:
  TraceProviderImpl provider_impl_;

  DISALLOW_COPY_AND_ASSIGN(TracingImpl);
};

}  // namespace mojo

#endif  // MOJO_COMMON_TRACING_IMPL_H_
