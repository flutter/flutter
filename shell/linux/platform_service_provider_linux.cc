// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/bind.h"
#include "base/trace_event/trace_event.h"
#include "mojo/public/cpp/bindings/interface_request.h"
#include "sky/shell/service_provider.h"

namespace sky {
namespace shell {

mojo::ServiceProviderPtr CreateServiceProvider(
    ServiceProviderContext* context) {
  mojo::MessagePipe pipe;
  // TODO(abarth): Wire pipe.handle1 up to something.
  return mojo::MakeProxy(
      mojo::InterfacePtrInfo<mojo::ServiceProvider>(pipe.handle0.Pass(), 0u));
}

}  // namespace shell
}  // namespace sky
