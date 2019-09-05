// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <lib/sys/cpp/testing/component_context_provider.h>

#include "echo_server.h"

#include <lib/gtest/real_loop_fixture.h>

#include "gtest/gtest.h"

namespace {

class ComponentContextProviderTests : public gtest::RealLoopFixture {
 protected:
  void PublishOutgoingService() {
    ASSERT_EQ(ZX_OK, provider_.context()->outgoing()->AddPublicService(
                         echo_impl_.GetHandler(dispatcher())));
  }

  void PublishIncomingService() {
    ASSERT_EQ(ZX_OK, provider_.service_directory_provider()->AddService(
                         echo_impl_.GetHandler(dispatcher())));
  }

  EchoImpl echo_impl_;
  sys::testing::ComponentContextProvider provider_;
};

TEST_F(ComponentContextProviderTests, TestOutgoingPublicServices) {
  PublishOutgoingService();

  auto echo = provider_.ConnectToPublicService<fidl::examples::echo::Echo>();

  std::string result;
  echo->EchoString("hello",
                   [&result](fidl::StringPtr value) { result = *value; });

  RunLoopUntilIdle();
  EXPECT_EQ("hello", result);
}

TEST_F(ComponentContextProviderTests, TestIncomingServices) {
  PublishIncomingService();

  fidl::examples::echo::EchoPtr echo;

  auto services = provider_.service_directory_provider()->service_directory();

  services->Connect(echo.NewRequest());

  std::string result;
  echo->EchoString("hello",
                   [&result](fidl::StringPtr value) { result = *value; });

  RunLoopUntilIdle();
  EXPECT_EQ("hello", result);
}

}  // namespace
