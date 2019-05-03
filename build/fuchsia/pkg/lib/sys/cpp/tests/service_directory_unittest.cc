// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <lib/sys/cpp/service_directory.h>

#include <fidl/examples/echo/cpp/fidl.h>
#include <fuchsia/io/c/fidl.h>
#include <lib/fidl/cpp/message_buffer.h>
#include <lib/zx/channel.h>

#include "gtest/gtest.h"

TEST(ServiceDirectoryTest, Control) {
  zx::channel svc_client, svc_server;
  ASSERT_EQ(ZX_OK, zx::channel::create(0, &svc_client, &svc_server));

  sys::ServiceDirectory directory(std::move(svc_client));

  fidl::InterfaceHandle<fidl::examples::echo::Echo> echo;
  EXPECT_EQ(ZX_OK, directory.Connect(echo.NewRequest()));

  fidl::MessageBuffer buffer;
  auto message = buffer.CreateEmptyMessage();
  message.Read(svc_server.get(), 0);

  EXPECT_TRUE(message.has_header());
  EXPECT_EQ(fuchsia_io_DirectoryOpenOrdinal, message.ordinal());
}

TEST(ServiceDirectoryTest, CreateWithRequest) {
  zx::channel svc_server;

  auto directory = sys::ServiceDirectory::CreateWithRequest(&svc_server);

  fidl::InterfaceHandle<fidl::examples::echo::Echo> echo;
  EXPECT_EQ(ZX_OK, directory->Connect(echo.NewRequest()));

  fidl::MessageBuffer buffer;
  auto message = buffer.CreateEmptyMessage();
  message.Read(svc_server.get(), 0);

  EXPECT_TRUE(message.has_header());
  EXPECT_EQ(fuchsia_io_DirectoryOpenOrdinal, message.ordinal());
}

TEST(ServiceDirectoryTest, Clone) {
  zx::channel svc_server;

  auto directory = sys::ServiceDirectory::CreateWithRequest(&svc_server);

  fidl::InterfaceHandle<fidl::examples::echo::Echo> echo;
  EXPECT_TRUE(directory->CloneChannel().is_valid());

  fidl::MessageBuffer buffer;
  auto message = buffer.CreateEmptyMessage();
  message.Read(svc_server.get(), 0);

  EXPECT_TRUE(message.has_header());
  EXPECT_EQ(fuchsia_io_DirectoryCloneOrdinal, message.ordinal());
}

TEST(ServiceDirectoryTest, Invalid) {
  sys::ServiceDirectory directory((zx::channel()));

  fidl::InterfaceHandle<fidl::examples::echo::Echo> echo;
  EXPECT_EQ(ZX_ERR_UNAVAILABLE, directory.Connect(echo.NewRequest()));
}

TEST(ServiceDirectoryTest, AccessDenied) {
  zx::channel svc_client, svc_server;
  ASSERT_EQ(ZX_OK, zx::channel::create(0, &svc_client, &svc_server));

  svc_client.replace(ZX_RIGHT_NONE, &svc_client);

  sys::ServiceDirectory directory(std::move(svc_client));

  fidl::InterfaceHandle<fidl::examples::echo::Echo> echo;
  EXPECT_EQ(ZX_ERR_ACCESS_DENIED, directory.Connect(echo.NewRequest()));
}
