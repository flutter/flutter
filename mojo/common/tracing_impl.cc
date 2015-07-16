// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/common/tracing_impl.h"

#include "base/trace_event/trace_event_impl.h"
#include "mojo/common/trace_controller_impl.h"
#include "mojo/public/cpp/application/application_connection.h"
#include "mojo/public/cpp/application/application_impl.h"

namespace mojo {

TracingImpl::TracingImpl() {
}

TracingImpl::~TracingImpl() {
}

void TracingImpl::Initialize(ApplicationImpl* app) {
  ApplicationConnection* connection = app->ConnectToApplication("mojo:tracing");
  connection->AddService(this);
}

void TracingImpl::Create(ApplicationConnection* connection,
                         InterfaceRequest<tracing::TraceController> request) {
  new TraceControllerImpl(request.Pass());
}

}  // namespace mojo
