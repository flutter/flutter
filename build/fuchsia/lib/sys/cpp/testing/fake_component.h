// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef LIB_SYS_CPP_TESTING_FAKE_COMPONENT_H_
#define LIB_SYS_CPP_TESTING_FAKE_COMPONENT_H_

#include <lib/async/dispatcher.h>
#include <lib/sys/cpp/testing/fake_launcher.h>
#include <lib/vfs/cpp/pseudo_dir.h>
#include <lib/vfs/cpp/service.h>
#include <memory>
#include <utility>

namespace sys {
namespace testing {

// A fake component which can be used to intercept component launch using
// |FakeLauncher| and publish fake services for unit testing.
class FakeComponent {
 public:
  FakeComponent();
  ~FakeComponent();

  // Adds specified interface to the set of public interfaces.
  //
  // Adds a supported service with the given |service_name|, using the given
  // |interface_request_handler|, which should remain valid for the lifetime of
  // this object.
  //
  // A typical usage may be:
  //
  //   AddPublicService(foobar_bindings_.GetHandler(this));
  template <typename Interface>
  zx_status_t AddPublicService(
      fidl::InterfaceRequestHandler<Interface> handler,
      const std::string& service_name = Interface::Name_) {
    return directory_.AddEntry(
        service_name.c_str(),
        std::make_unique<vfs::Service>(std::move(handler)));
  }

  // Registers this component with a FakeLauncher.
  void Register(std::string url, FakeLauncher& fake_launcher,
                async_dispatcher_t* dispatcher = nullptr);

 private:
  vfs::PseudoDir directory_;
  std::vector<fidl::InterfaceRequest<fuchsia::sys::ComponentController>> ctrls_;
};

}  // namespace testing
}  // namespace sys

#endif  // LIB_SYS_CPP_TESTING_FAKE_COMPONENT_H_
