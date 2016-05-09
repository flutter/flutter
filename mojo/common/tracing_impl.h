// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_COMMON_TRACING_IMPL_H_
#define MOJO_COMMON_TRACING_IMPL_H_

#include "base/macros.h"
#include "mojo/common/trace_provider_impl.h"

namespace mojo {

class ApplicationImpl;

class TracingImpl {
 public:
  TracingImpl();
  ~TracingImpl();

  // This connects to the tracing service and registers ourselves to provide
  // tracing data on demand.
  void Initialize(ApplicationImpl* app);

 private:
  TraceProviderImpl provider_impl_;

  DISALLOW_COPY_AND_ASSIGN(TracingImpl);
};

}  // namespace mojo

#endif  // MOJO_COMMON_TRACING_IMPL_H_
