// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/platform_handle_dispatcher.h"

#include <stdio.h>

#include <utility>

#include "mojo/edk/platform/platform_handle_utils_posix.h"
#include "mojo/edk/system/handle.h"
#include "mojo/edk/system/handle_transport.h"
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

TEST(PlatformHandleDispatcher, SupportsEntrypointClass) {
  test::ScopedTestDir test_dir;

  util::ScopedFILE fp(test_dir.CreateFile());
  ASSERT_TRUE(fp);

  ScopedPlatformHandle h(PlatformHandleFromFILE(std::move(fp)));
  EXPECT_FALSE(fp);
  ASSERT_TRUE(h.is_valid());

  auto d = PlatformHandleDispatcher::Create(h.Pass());
  ASSERT_TRUE(d);
  EXPECT_FALSE(h.is_valid());

  EXPECT_TRUE(d->SupportsEntrypointClass(EntrypointClass::NONE));
  EXPECT_FALSE(d->SupportsEntrypointClass(EntrypointClass::MESSAGE_PIPE));
  EXPECT_FALSE(d->SupportsEntrypointClass(EntrypointClass::DATA_PIPE_PRODUCER));
  EXPECT_FALSE(d->SupportsEntrypointClass(EntrypointClass::DATA_PIPE_CONSUMER));
  EXPECT_FALSE(d->SupportsEntrypointClass(EntrypointClass::BUFFER));

  // TODO(vtl): Check that it actually returns |MOJO_RESULT_INVALID_ARGUMENT|
  // for methods in unsupported entrypoint classes.

  EXPECT_EQ(MOJO_RESULT_OK, d->Close());
}

TEST(PlatformHandleDispatcherTest, CreateEquivalentDispatcherAndClose) {
  test::ScopedTestDir test_dir;

  static const char kFooBar[] = "foo bar";

  util::ScopedFILE fp(test_dir.CreateFile());
  EXPECT_EQ(sizeof(kFooBar), fwrite(kFooBar, 1, sizeof(kFooBar), fp.get()));

  auto dispatcher =
      PlatformHandleDispatcher::Create(PlatformHandleFromFILE(std::move(fp)));
  Handle handle(std::move(dispatcher),
                PlatformHandleDispatcher::kDefaultHandleRights);

  HandleTransport transport(test::HandleTryStartTransport(handle));
  EXPECT_TRUE(transport.is_valid());
  EXPECT_EQ(Dispatcher::Type::PLATFORM_HANDLE, transport.GetType());

  Handle equivalent_handle =
      transport.CreateEquivalentHandleAndClose(nullptr, 0u);
  ASSERT_TRUE(equivalent_handle.dispatcher);
  EXPECT_EQ(PlatformHandleDispatcher::kDefaultHandleRights,
            equivalent_handle.rights);

  transport.End();
  EXPECT_TRUE(handle.dispatcher->HasOneRef());
  handle.reset();

  ASSERT_EQ(Dispatcher::Type::PLATFORM_HANDLE,
            equivalent_handle.dispatcher->GetType());
  dispatcher =
      RefPtr<PlatformHandleDispatcher>(static_cast<PlatformHandleDispatcher*>(
          equivalent_handle.dispatcher.get()));

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
