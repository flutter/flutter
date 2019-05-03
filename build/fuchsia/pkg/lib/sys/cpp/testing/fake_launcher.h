// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef LIB_SYS_CPP_TESTING_FAKE_LAUNCHER_H_
#define LIB_SYS_CPP_TESTING_FAKE_LAUNCHER_H_

#include <fuchsia/sys/cpp/fidl.h>
#include <lib/async/dispatcher.h>
#include <lib/fidl/cpp/binding_set.h>
#include <lib/fidl/cpp/interface_request.h>
#include <lib/fit/function.h>

namespace sys {
namespace testing {

// A fake |Launcher| for testing.
// Used to intercept component component launch from code under test.
class FakeLauncher : public fuchsia::sys::Launcher {
 public:
  FakeLauncher();
  ~FakeLauncher() override;

  FakeLauncher(const FakeLauncher&) = delete;
  FakeLauncher& operator=(const FakeLauncher&) = delete;

  using ComponentConnector = fit::function<void(
      fuchsia::sys::LaunchInfo,
      fidl::InterfaceRequest<fuchsia::sys::ComponentController>)>;

  // Registers a component located at "url" with a connector. When someone
  // tries to CreateComponent() with this |url|, the supplied |connector| is
  // called with the the LaunchInfo and associated ComponentController request.
  // The connector may implement the |LaunchInfo.services| and
  // |ComponentController| interfaces to communicate with its connector and
  // listen for component signals.
  void RegisterComponent(std::string url, ComponentConnector connector);

  // Forwards this |CreateComponent| request to a registered connector, if an
  // associated one exists. If one is not registered for |launch_info.url|, then
  // this call is dropped.
  void CreateComponent(fuchsia::sys::LaunchInfo launch_info,
                       fidl::InterfaceRequest<fuchsia::sys::ComponentController>
                           controller) override;

  fidl::InterfaceRequestHandler<fuchsia::sys::Launcher> GetHandler(
      async_dispatcher_t* dispatcher = nullptr);

 private:
  std::map<std::string, ComponentConnector> connectors_;
  fidl::BindingSet<Launcher> binding_set_;
};

}  // namespace testing
}  // namespace sys

#endif  // LIB_SYS_CPP_TESTING_FAKE_LAUNCHER_H_
