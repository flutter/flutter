// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <lib/sys/cpp/outgoing_directory.h>

#include "echo_server.h"

#include <fuchsia/io/c/fidl.h>
#include <fuchsia/io/cpp/fidl.h>
#include <lib/fdio/directory.h>
#include <lib/fidl/cpp/message_buffer.h>
#include <lib/gtest/real_loop_fixture.h>
#include <lib/zx/channel.h>

#include "gtest/gtest.h"

namespace {

using OutgoingDirectorySetupTest = gtest::RealLoopFixture;

class OutgoingDirectoryTest : public gtest::RealLoopFixture {
 protected:
  void SetUp() override {
    gtest::RealLoopFixture::SetUp();
    zx::channel svc_server;
    ASSERT_EQ(ZX_OK, zx::channel::create(0, &svc_client_, &svc_server));

    ASSERT_EQ(ZX_OK, outgoing_.Serve(std::move(svc_server), dispatcher()));
  }

  void TestCanAccessEchoService(const char* service_path,
                                bool succeeds = true) {
    fidl::examples::echo::EchoPtr echo;
    fdio_service_connect_at(
        svc_client_.get(), service_path,
        echo.NewRequest(dispatcher()).TakeChannel().release());

    std::string result = "no callback";
    echo->EchoString("hello",
                     [&result](fidl::StringPtr value) { result = *value; });

    RunLoopUntilIdle();
    EXPECT_EQ(succeeds ? "hello" : "no callback", result);
  }

  void AddEchoService(vfs::PseudoDir* dir) {
    ASSERT_EQ(ZX_OK, dir->AddEntry(fidl::examples::echo::Echo::Name_,
                                   std::make_unique<vfs::Service>(
                                       echo_impl_.GetHandler(dispatcher()))));
  }

  EchoImpl echo_impl_;
  zx::channel svc_client_;
  sys::OutgoingDirectory outgoing_;
};

TEST_F(OutgoingDirectoryTest, Control) {
  ASSERT_EQ(ZX_OK,
            outgoing_.AddPublicService(echo_impl_.GetHandler(dispatcher())));

  TestCanAccessEchoService("public/fidl.examples.echo.Echo");

  // Ensure GetOrCreateDirectory refers to the same "public" directory.
  outgoing_.GetOrCreateDirectory("public")->RemoveEntry(
      "fidl.examples.echo.Echo");
  TestCanAccessEchoService("public/fidl.examples.echo.Echo", false);
}

TEST_F(OutgoingDirectoryTest, AddAndRemove) {
  ASSERT_EQ(ZX_ERR_NOT_FOUND,
            outgoing_.RemovePublicService<fidl::examples::echo::Echo>());

  ASSERT_EQ(ZX_OK,
            outgoing_.AddPublicService(echo_impl_.GetHandler(dispatcher())));

  ASSERT_EQ(ZX_ERR_ALREADY_EXISTS,
            outgoing_.AddPublicService(echo_impl_.GetHandler(dispatcher())));

  TestCanAccessEchoService("public/fidl.examples.echo.Echo");

  ASSERT_EQ(ZX_OK, outgoing_.RemovePublicService<fidl::examples::echo::Echo>());
  ASSERT_EQ(ZX_ERR_NOT_FOUND,
            outgoing_.RemovePublicService<fidl::examples::echo::Echo>());

  TestCanAccessEchoService("public/fidl.examples.echo.Echo", false);
}

TEST_F(OutgoingDirectoryTest, DebugDir) {
  AddEchoService(outgoing_.debug_dir());

  TestCanAccessEchoService("debug/fidl.examples.echo.Echo");
  outgoing_.GetOrCreateDirectory("debug")->RemoveEntry(
      "fidl.examples.echo.Echo");
  TestCanAccessEchoService("debug/fidl.examples.echo.Echo", false);
}

TEST_F(OutgoingDirectoryTest, CtrlDir) {
  AddEchoService(outgoing_.ctrl_dir());

  TestCanAccessEchoService("ctrl/fidl.examples.echo.Echo");
  outgoing_.GetOrCreateDirectory("ctrl")->RemoveEntry(
      "fidl.examples.echo.Echo");
  TestCanAccessEchoService("ctrl/fidl.examples.echo.Echo", false);
}

TEST_F(OutgoingDirectoryTest, GetOrCreateDirectory) {
  outgoing_.GetOrCreateDirectory("objects")->AddEntry(
      "test_svc_a",
      std::make_unique<vfs::Service>(echo_impl_.GetHandler(dispatcher())));
  outgoing_.GetOrCreateDirectory("objects")->AddEntry(
      "test_svc_b",
      std::make_unique<vfs::Service>(echo_impl_.GetHandler(dispatcher())));
  TestCanAccessEchoService("objects/test_svc_a");
  TestCanAccessEchoService("objects/test_svc_b");
}

TEST_F(OutgoingDirectorySetupTest, Invalid) {
  sys::OutgoingDirectory outgoing;
  // TODO: This should return ZX_ERR_BAD_HANDLE.
  ASSERT_EQ(ZX_OK, outgoing.Serve(zx::channel(), dispatcher()));
}

TEST_F(OutgoingDirectorySetupTest, AccessDenied) {
  zx::channel svc_client, svc_server;
  ASSERT_EQ(ZX_OK, zx::channel::create(0, &svc_client, &svc_server));

  svc_server.replace(ZX_RIGHT_NONE, &svc_server);

  sys::OutgoingDirectory outgoing;
  ASSERT_EQ(ZX_ERR_ACCESS_DENIED,
            outgoing.Serve(std::move(svc_server), dispatcher()));
}

}  // namespace
