// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/platform_handle_dispatcher.h"

#include <stdio.h>

#include <utility>

#include "mojo/edk/platform/platform_handle_utils_posix.h"
#include "mojo/edk/system/test/scoped_test_dir.h"
#include "mojo/edk/util/scoped_file.h"
#include "testing/gtest/include/gtest/gtest.h"

using mojo::platform::FILEFromPlatformHandle;
using mojo::platform::PlatformHandleFromFILE;
using mojo::platform::ScopedPlatformHandle;
using mojo::util::RefPtr;

namespace mojo {
namespace system {
namespace {

TEST(PlatformHandleDispatcherTest, Basic) {
  test::ScopedTestDir test_dir;

  static const char kHelloWorld[] = "hello world";

  util::ScopedFILE fp(test_dir.CreateFile());
  ASSERT_TRUE(fp);
  EXPECT_EQ(sizeof(kHelloWorld),
            fwrite(kHelloWorld, 1, sizeof(kHelloWorld), fp.get()));

  ScopedPlatformHandle h(PlatformHandleFromFILE(std::move(fp)));
  EXPECT_FALSE(fp);
  ASSERT_TRUE(h.is_valid());

  auto dispatcher = PlatformHandleDispatcher::Create(h.Pass());
  EXPECT_FALSE(h.is_valid());
  EXPECT_EQ(Dispatcher::Type::PLATFORM_HANDLE, dispatcher->GetType());

  h = dispatcher->PassPlatformHandle();
  EXPECT_TRUE(h.is_valid());

  fp = FILEFromPlatformHandle(h.Pass(), "rb");
  EXPECT_FALSE(h.is_valid());
  EXPECT_TRUE(fp);

  rewind(fp.get());
  char read_buffer[1000] = {};
  EXPECT_EQ(sizeof(kHelloWorld),
            fread(read_buffer, 1, sizeof(read_buffer), fp.get()));
  EXPECT_STREQ(kHelloWorld, read_buffer);

  // Try getting the handle again. (It should fail cleanly.)
  h = dispatcher->PassPlatformHandle();
  EXPECT_FALSE(h.is_valid());

  EXPECT_EQ(MOJO_RESULT_OK, dispatcher->Close());
}

TEST(PlatformHandleDispatcherTest, CreateEquivalentDispatcherAndClose) {
  test::ScopedTestDir test_dir;

  static const char kFooBar[] = "foo bar";

  util::ScopedFILE fp(test_dir.CreateFile());
  EXPECT_EQ(sizeof(kFooBar), fwrite(kFooBar, 1, sizeof(kFooBar), fp.get()));

  auto dispatcher =
      PlatformHandleDispatcher::Create(PlatformHandleFromFILE(std::move(fp)));

  DispatcherTransport transport(
      test::DispatcherTryStartTransport(dispatcher.get()));
  EXPECT_TRUE(transport.is_valid());
  EXPECT_EQ(Dispatcher::Type::PLATFORM_HANDLE, transport.GetType());
  EXPECT_FALSE(transport.IsBusy());

  auto generic_dispatcher = transport.CreateEquivalentDispatcherAndClose();
  ASSERT_TRUE(generic_dispatcher);

  transport.End();
  EXPECT_TRUE(dispatcher->HasOneRef());
  dispatcher = nullptr;

  ASSERT_EQ(Dispatcher::Type::PLATFORM_HANDLE, generic_dispatcher->GetType());
  dispatcher = RefPtr<PlatformHandleDispatcher>(
      static_cast<PlatformHandleDispatcher*>(generic_dispatcher.get()));

  fp = FILEFromPlatformHandle(dispatcher->PassPlatformHandle(), "rb");
  EXPECT_TRUE(fp);

  rewind(fp.get());
  char read_buffer[1000] = {};
  EXPECT_EQ(sizeof(kFooBar),
            fread(read_buffer, 1, sizeof(read_buffer), fp.get()));
  EXPECT_STREQ(kFooBar, read_buffer);

  EXPECT_EQ(MOJO_RESULT_OK, dispatcher->Close());
}

}  // namespace
}  // namespace system
}  // namespace mojo
