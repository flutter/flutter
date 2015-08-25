// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_COMMON_TRACE_PROVIDER_IMPL_H_
#define MOJO_COMMON_TRACE_PROVIDER_IMPL_H_

#include "base/memory/ref_counted_memory.h"
#include "mojo/public/cpp/bindings/interface_request.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "mojo/services/tracing/public/interfaces/tracing.mojom.h"

namespace mojo {

class TraceProviderImpl : public tracing::TraceProvider {
 public:
  explicit TraceProviderImpl(InterfaceRequest<tracing::TraceProvider> request);
  ~TraceProviderImpl() override;

  // Set to true if base::trace_event::TraceLog is enabled externally to this
  // class. If this is set to true this class will save the collector but not
  // enable tracing when it receives a StartTracing message from the tracing
  // service.
  void set_tracing_already_started(bool tracing_already_started) {
    tracing_already_started_ = tracing_already_started;
  }

 private:
  // tracing::TraceProvider implementation:
  void StartTracing(const String& categories,
                    tracing::TraceRecorderPtr collector) override;
  void StopTracing() override;

  void SendChunk(const scoped_refptr<base::RefCountedString>& events_str,
                 bool has_more_events);

  bool tracing_already_started_;
  tracing::TraceRecorderPtr recorder_;
  StrongBinding<tracing::TraceProvider> binding_;

  DISALLOW_COPY_AND_ASSIGN(TraceProviderImpl);
};

}  // namespace mojo

#endif  // MOJO_COMMON_TRACE_PROVIDER_IMPL_H_
