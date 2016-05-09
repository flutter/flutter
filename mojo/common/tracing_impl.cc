// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/common/tracing_impl.h"

#include "base/trace_event/trace_event_impl.h"
#include "mojo/public/cpp/application/application_impl.h"
#include "mojo/public/cpp/application/connect.h"
#include "mojo/public/cpp/bindings/interface_handle.h"
#include "mojo/public/cpp/bindings/interface_request.h"
#include "mojo/services/tracing/interfaces/trace_provider_registry.mojom.h"
#include "mojo/services/tracing/interfaces/tracing.mojom.h"

namespace mojo {

TracingImpl::TracingImpl() {}

TracingImpl::~TracingImpl() {}

void TracingImpl::Initialize(ApplicationImpl* app) {
  tracing::TraceProviderRegistryPtr registry;
  ConnectToService(app->shell(), "mojo:tracing", GetProxy(&registry));

  mojo::InterfaceHandle<tracing::TraceProvider> provider;
  provider_impl_.Bind(GetProxy(&provider));
  registry->RegisterTraceProvider(provider.Pass());

#ifdef NDEBUG
  if (app->HasArg("--early-tracing")) {
    provider_impl_.ForceEnableTracing();
  }
#else
  provider_impl_.ForceEnableTracing();
#endif
}

}  // namespace mojo
