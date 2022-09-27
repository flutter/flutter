// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// The generated C++ bindings for the Echo FIDL protocol
#include <flutter/shell/platform/fuchsia/dart_runner/tests/fidl/flutter.example.echo/flutter/example/echo/cpp/fidl.h>

#include <lib/async-loop/testing/cpp/real_loop.h>
#include <lib/sys/component/cpp/testing/realm_builder.h>
#include <lib/sys/component/cpp/testing/realm_builder_types.h>

#include "flutter/fml/logging.h"
#include "gtest/gtest.h"

namespace dart_jit_runner_testing::testing {
namespace {

using component_testing::ChildRef;
using component_testing::ParentRef;
using component_testing::Protocol;
using component_testing::RealmBuilder;
using component_testing::RealmRoot;
using component_testing::Route;

class RealmBuilderTest : public ::loop_fixture::RealLoop,
                         public ::testing::Test {
 public:
  RealmBuilderTest() = default;
};

TEST_F(RealmBuilderTest, DartRunnerStartsUp) {
  auto realm_builder = RealmBuilder::Create();
  // Add Dart server component as a child of Realm Builder
  realm_builder.AddChild("hello_world",
                         "fuchsia-pkg://fuchsia.com/dart_jit_echo_server#meta/"
                         "dart_jit_echo_server.cm");
  realm_builder.AddRoute(
      Route{.capabilities = {Protocol{"fuchsia.logger.LogSink"}},
            .source = ParentRef(),
            .targets = {ChildRef{"hello_world"}}});
  // Route the Echo FIDL protocol, this allows the Dart echo server to
  // communicate with the Realm Builder
  realm_builder.AddRoute(
      Route{.capabilities = {Protocol{"flutter.example.echo.Echo"}},
            .source = ChildRef{"hello_world"},
            .targets = {ParentRef()}});
  // Build the Realm with the provided child and protocols
  auto realm = realm_builder.Build(dispatcher());
  FML_LOG(INFO) << "Realm built: " << realm.GetChildName();
  // Connect to the Dart echo server
  auto echo = realm.ConnectSync<flutter::example::echo::Echo>();
  fidl::StringPtr response;
  // Attempt to ping the Dart echo server for a response
  echo->EchoString("hello", &response);
  ASSERT_EQ(response, "hello");
}

}  // namespace
}  // namespace dart_jit_runner_testing::testing
