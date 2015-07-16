// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_COMMON_TRACING_CONTROLLER_IMPL_H_
#define MOJO_COMMON_TRACING_CONTROLLER_IMPL_H_

#include "base/memory/ref_counted_memory.h"
#include "mojo/public/cpp/bindings/interface_request.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "mojo/services/tracing/public/interfaces/tracing.mojom.h"

namespace mojo {

class TraceControllerImpl : public tracing::TraceController {
 public:
  explicit TraceControllerImpl(
      InterfaceRequest<tracing::TraceController> request);
  ~TraceControllerImpl() override;

  // Set to true if base::trace_event::TraceLog is enabled externally to this
  // class. If this is set to true this class will save the collector but not
  // enable tracing when it receives a StartTracing message from the tracing
  // service.
  void set_tracing_already_started(bool tracing_already_started) {
    tracing_already_started_ = tracing_already_started;
  }

 private:
  // tracing::TraceController implementation:
  void StartTracing(const String& categories,
                    tracing::TraceDataCollectorPtr collector) override;
  void StopTracing() override;

  void SendChunk(const scoped_refptr<base::RefCountedString>& events_str,
                 bool has_more_events);

  bool tracing_already_started_;
  tracing::TraceDataCollectorPtr collector_;
  StrongBinding<tracing::TraceController> binding_;

  DISALLOW_COPY_AND_ASSIGN(TraceControllerImpl);
};

}  // namespace mojo

#endif  // MOJO_COMMON_TRACING_CONTROLLER_IMPL_H_
