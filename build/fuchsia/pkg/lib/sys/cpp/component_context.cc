// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <lib/sys/cpp/component_context.h>

#include <lib/fdio/directory.h>
#include <lib/sys/cpp/outgoing_directory.h>
#include <lib/zx/channel.h>
#include <zircon/process.h>
#include <zircon/processargs.h>

namespace sys {

ComponentContext::ComponentContext(MakePrivate make_private,
                                   std::shared_ptr<ServiceDirectory> svc,
                                   zx::channel directory_request,
                                   async_dispatcher_t* dispatcher)
    : svc_(std::move(svc)), outgoing_(std::make_shared<OutgoingDirectory>()) {
  outgoing_->Serve(std::move(directory_request), dispatcher);
}

ComponentContext::~ComponentContext() = default;

std::unique_ptr<ComponentContext> ComponentContext::Create() {
  zx_handle_t directory_request = zx_take_startup_handle(PA_DIRECTORY_REQUEST);
  return std::make_unique<ComponentContext>(
      MakePrivate{}, ServiceDirectory::CreateFromNamespace(),
      zx::channel(directory_request));
}

}  // namespace sys
