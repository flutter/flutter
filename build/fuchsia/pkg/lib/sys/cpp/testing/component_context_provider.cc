// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <lib/sys/cpp/testing/component_context_provider.h>

#include <lib/fdio/directory.h>
#include <lib/sys/cpp/testing/service_directory_provider.h>
#include <zircon/processargs.h>
#include <memory>

namespace sys {
namespace testing {

ComponentContextProvider::ComponentContextProvider(
    async_dispatcher_t* dispatcher)
    : svc_provider_(std::make_shared<ServiceDirectoryProvider>()) {
  // remove this handle from namespace so that no one is using it.
  zx_take_startup_handle(PA_DIRECTORY_REQUEST);

  component_context_ = std::make_unique<sys::ComponentContext>(
      sys::ComponentContext::MakePrivate{}, svc_provider_->service_directory(),
      outgoing_directory_ptr_.NewRequest(dispatcher).TakeChannel(), dispatcher);

  fdio_service_connect_at(
      outgoing_directory_ptr_.channel().get(), "public",
      public_directory_ptr_.NewRequest().TakeChannel().release());
}

ComponentContextProvider::~ComponentContextProvider() = default;

}  // namespace testing
}  // namespace sys
