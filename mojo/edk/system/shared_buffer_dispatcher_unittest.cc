// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/shared_buffer_dispatcher.h"

#include <limits>
#include <memory>

#include "mojo/edk/embedder/simple_platform_support.h"
#include "mojo/edk/platform/platform_shared_buffer.h"
#include "mojo/edk/system/dispatcher.h"
#include "mojo/public/cpp/system/macros.h"
#include "testing/gtest/include/gtest/gtest.h"

using mojo::platform::PlatformSharedBufferMapping;
using mojo::util::RefPtr;

namespace mojo {
namespace system {
namespace {

// NOTE(vtl): There's currently not much to test for in
// |SharedBufferDispatcher::ValidateCreateOptions()|, but the tests should be
// expanded if/when options are added, so I've kept the general form of the
// tests from data_pipe_unittest.cc.

const uint32_t kSizeOfCreateOptions = sizeof(MojoCreateSharedBufferOptions);

// Does a cursory sanity check of |validated_options|. Calls
// |ValidateCreateOptions()| on already-validated options. The validated options
// should be valid, and the revalidated copy should be the same.
void RevalidateCreateOptions(
    const MojoCreateSharedBufferOptions& validated_options) {
  EXPECT_EQ(kSizeOfCreateOptions, validated_options.struct_size);
  // Nothing to check for flags.

  MojoCreateSharedBufferOptions revalidated_options = {};
  EXPECT_EQ(MOJO_RESULT_OK,
            SharedBufferDispatcher::ValidateCreateOptions(
                MakeUserPointer(&validated_options), &revalidated_options));
  EXPECT_EQ(validated_options.struct_size, revalidated_options.struct_size);
  EXPECT_EQ(validated_options.flags, revalidated_options.flags);
}

class SharedBufferDispatcherTest : public testing::Test {
 public:
  SharedBufferDispatcherTest()
      : platform_support_(embedder::CreateSimplePlatformSupport()) {}
  ~SharedBufferDispatcherTest() override {}

  embedder::PlatformSupport* platform_support() {
    return platform_support_.get();
  }

 private:
  std::unique_ptr<embedder::PlatformSupport> platform_support_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(SharedBufferDispatcherTest);
};

// Tests valid inputs to |ValidateCreateOptions()|.
TEST_F(SharedBufferDispatcherTest, ValidateCreateOptionsValid) {
  // Default options.
  {
    MojoCreateSharedBufferOptions validated_options = {};
    EXPECT_EQ(MOJO_RESULT_OK, SharedBufferDispatcher::ValidateCreateOptions(
                                  NullUserPointer(), &validated_options));
    RevalidateCreateOptions(validated_options);
  }

  // Different flags.
  MojoCreateSharedBufferOptionsFlags flags_values[] = {
      MOJO_CREATE_SHARED_BUFFER_OPTIONS_FLAG_NONE};
  for (size_t i = 0; i < MOJO_ARRAYSIZE(flags_values); i++) {
    const MojoCreateSharedBufferOptionsFlags flags = flags_values[i];

    // Different capacities (size 1).
    for (uint32_t capacity = 1; capacity <= 100 * 1000 * 1000; capacity *= 10) {
      MojoCreateSharedBufferOptions options = {
          kSizeOfCreateOptions,  // |struct_size|.
          flags                  // |flags|.
      };
      MojoCreateSharedBufferOptions validated_options = {};
      EXPECT_EQ(MOJO_RESULT_OK,
                SharedBufferDispatcher::ValidateCreateOptions(
                    MakeUserPointer(&options), &validated_options))
          << capacity;
      RevalidateCreateOptions(validated_options);
      EXPECT_EQ(options.flags, validated_options.flags);
    }
  }
}

TEST_F(SharedBufferDispatcherTest, ValidateCreateOptionsInvalid) {
  // Invalid |struct_size|.
  {
    MojoCreateSharedBufferOptions options = {
        1,                                           // |struct_size|.
        MOJO_CREATE_SHARED_BUFFER_OPTIONS_FLAG_NONE  // |flags|.
    };
    MojoCreateSharedBufferOptions unused;
    EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
              SharedBufferDispatcher::ValidateCreateOptions(
                  MakeUserPointer(&options), &unused));
  }

  // Unknown |flags|.
  {
    MojoCreateSharedBufferOptions options = {
        kSizeOfCreateOptions,  // |struct_size|.
        ~0u                    // |flags|.
    };
    MojoCreateSharedBufferOptions unused;
    EXPECT_EQ(MOJO_RESULT_UNIMPLEMENTED,
              SharedBufferDispatcher::ValidateCreateOptions(
                  MakeUserPointer(&options), &unused));
  }
}

TEST_F(SharedBufferDispatcherTest, CreateAndMapBuffer) {
  const uint64_t kSize = 100u;

  MojoResult result = MOJO_RESULT_INTERNAL;
  auto dispatcher = SharedBufferDispatcher::Create(
      platform_support(), SharedBufferDispatcher::kDefaultCreateOptions, kSize,
      &result);
  EXPECT_EQ(MOJO_RESULT_OK, result);

  ASSERT_TRUE(dispatcher);
  EXPECT_EQ(Dispatcher::Type::SHARED_BUFFER, dispatcher->GetType());

  // Get information about the buffer (in particular the size) and check it.
  MojoBufferInformation info = {};
  EXPECT_EQ(MOJO_RESULT_OK,
            dispatcher->GetBufferInformation(
                MakeUserPointer(&info), static_cast<uint32_t>(sizeof(info))));
  EXPECT_EQ(sizeof(MojoBufferInformation), info.struct_size);
  EXPECT_EQ(MOJO_BUFFER_INFORMATION_FLAG_NONE, info.flags);
  EXPECT_EQ(kSize, info.num_bytes);

  // Also check that some invalid calls to |GetBufferInformation()| fail in the
  // expected way.
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
            dispatcher->GetBufferInformation(MakeUserPointer(&info), 0u));
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
            dispatcher->GetBufferInformation(MakeUserPointer(&info), 15u));

  // It's also valid to call it with a larger-than-required |info_num_bytes|.
  // (Note: The pointer must be aligned, so we use an array of two
  // |MojoBufferInformation|s.)
  MojoBufferInformation infos[2] = {};
  EXPECT_EQ(MOJO_RESULT_OK, dispatcher->GetBufferInformation(
                                MakeUserPointer(&infos[0]),
                                static_cast<uint32_t>(sizeof(infos[0]) + 1)));
  EXPECT_EQ(kSize, infos[0].num_bytes);

  // Make a couple of mappings.
  std::unique_ptr<PlatformSharedBufferMapping> mapping1;
  EXPECT_EQ(
      MOJO_RESULT_OK,
      dispatcher->MapBuffer(0u, kSize, MOJO_MAP_BUFFER_FLAG_NONE, &mapping1));
  ASSERT_TRUE(mapping1);
  ASSERT_TRUE(mapping1->GetBase());
  EXPECT_EQ(kSize, mapping1->GetLength());
  // Write something.
  static_cast<char*>(mapping1->GetBase())[50] = 'x';

  std::unique_ptr<PlatformSharedBufferMapping> mapping2;
  EXPECT_EQ(MOJO_RESULT_OK,
            dispatcher->MapBuffer(kSize / 2, kSize / 2,
                                  MOJO_MAP_BUFFER_FLAG_NONE, &mapping2));
  ASSERT_TRUE(mapping2);
  ASSERT_TRUE(mapping2->GetBase());
  EXPECT_EQ(kSize / 2, mapping2->GetLength());
  EXPECT_EQ('x', static_cast<char*>(mapping2->GetBase())[0]);

  EXPECT_EQ(MOJO_RESULT_OK, dispatcher->Close());

  // Check that we can still read/write to mappings after the dispatcher has
  // gone away.
  static_cast<char*>(mapping2->GetBase())[1] = 'y';
  EXPECT_EQ('y', static_cast<char*>(mapping1->GetBase())[kSize / 2 + 1]);
}

TEST_F(SharedBufferDispatcherTest, SupportsEntrypointClass) {
  MojoResult result = MOJO_RESULT_INTERNAL;
  auto d = SharedBufferDispatcher::Create(
      platform_support(), SharedBufferDispatcher::kDefaultCreateOptions, 100u,
      &result);
  ASSERT_TRUE(d);
  EXPECT_EQ(MOJO_RESULT_OK, result);

  EXPECT_TRUE(d->SupportsEntrypointClass(EntrypointClass::NONE));
  EXPECT_FALSE(d->SupportsEntrypointClass(EntrypointClass::MESSAGE_PIPE));
  EXPECT_FALSE(d->SupportsEntrypointClass(EntrypointClass::DATA_PIPE_PRODUCER));
  EXPECT_FALSE(d->SupportsEntrypointClass(EntrypointClass::DATA_PIPE_CONSUMER));
  EXPECT_TRUE(d->SupportsEntrypointClass(EntrypointClass::BUFFER));

  // TODO(vtl): Check that it actually returns |MOJO_RESULT_INVALID_ARGUMENT|
  // for methods in unsupported entrypoint classes.

  EXPECT_EQ(MOJO_RESULT_OK, d->Close());
}

TEST_F(SharedBufferDispatcherTest, DuplicateDispatcher) {
  const uint64_t kSize = 100u;

  MojoResult result = MOJO_RESULT_INTERNAL;
  auto dispatcher1 = SharedBufferDispatcher::Create(
      platform_support(), SharedBufferDispatcher::kDefaultCreateOptions, kSize,
      &result);
  EXPECT_EQ(MOJO_RESULT_OK, result);

  // Map and write something.
  std::unique_ptr<PlatformSharedBufferMapping> mapping;
  EXPECT_EQ(
      MOJO_RESULT_OK,
      dispatcher1->MapBuffer(0u, kSize, MOJO_MAP_BUFFER_FLAG_NONE, &mapping));
  static_cast<char*>(mapping->GetBase())[0] = 'x';
  mapping.reset();

  // Duplicate |dispatcher1| and then close it.
  RefPtr<Dispatcher> dispatcher2;
  EXPECT_EQ(MOJO_RESULT_OK, dispatcher1->DuplicateDispatcher(&dispatcher2));
  ASSERT_TRUE(dispatcher2);
  EXPECT_EQ(Dispatcher::Type::SHARED_BUFFER, dispatcher2->GetType());

  EXPECT_EQ(MOJO_RESULT_OK, dispatcher1->Close());

  // Make sure that |dispatcher2| still reports the right information.
  MojoBufferInformation info = {};
  EXPECT_EQ(MOJO_RESULT_OK,
            dispatcher2->GetBufferInformation(
                MakeUserPointer(&info), static_cast<uint32_t>(sizeof(info))));
  EXPECT_EQ(sizeof(MojoBufferInformation), info.struct_size);
  EXPECT_EQ(MOJO_BUFFER_INFORMATION_FLAG_NONE, info.flags);
  EXPECT_EQ(kSize, info.num_bytes);

  // Map |dispatcher2| and read something.
  EXPECT_EQ(
      MOJO_RESULT_OK,
      dispatcher2->MapBuffer(0u, kSize, MOJO_MAP_BUFFER_FLAG_NONE, &mapping));
  EXPECT_EQ('x', static_cast<char*>(mapping->GetBase())[0]);

  EXPECT_EQ(MOJO_RESULT_OK, dispatcher2->Close());
}

TEST_F(SharedBufferDispatcherTest, DuplicateBufferHandle) {
  const uint64_t kSize = 100u;

  MojoResult result = MOJO_RESULT_INTERNAL;
  auto dispatcher1 = SharedBufferDispatcher::Create(
      platform_support(), SharedBufferDispatcher::kDefaultCreateOptions, kSize,
      &result);
  EXPECT_EQ(MOJO_RESULT_OK, result);

  // Map and write something.
  std::unique_ptr<PlatformSharedBufferMapping> mapping;
  EXPECT_EQ(
      MOJO_RESULT_OK,
      dispatcher1->MapBuffer(0u, kSize, MOJO_MAP_BUFFER_FLAG_NONE, &mapping));
  static_cast<char*>(mapping->GetBase())[0] = 'x';
  mapping.reset();

  // Duplicate |dispatcher1| and then close it.
  RefPtr<Dispatcher> dispatcher2;
  EXPECT_EQ(MOJO_RESULT_OK, dispatcher1->DuplicateBufferHandle(
                                NullUserPointer(), &dispatcher2));
  ASSERT_TRUE(dispatcher2);
  EXPECT_EQ(Dispatcher::Type::SHARED_BUFFER, dispatcher2->GetType());

  EXPECT_EQ(MOJO_RESULT_OK, dispatcher1->Close());

  // Make sure that |dispatcher2| still reports the right information.
  MojoBufferInformation info = {};
  EXPECT_EQ(MOJO_RESULT_OK,
            dispatcher2->GetBufferInformation(
                MakeUserPointer(&info), static_cast<uint32_t>(sizeof(info))));
  EXPECT_EQ(sizeof(MojoBufferInformation), info.struct_size);
  EXPECT_EQ(MOJO_BUFFER_INFORMATION_FLAG_NONE, info.flags);
  EXPECT_EQ(kSize, info.num_bytes);

  // Map |dispatcher2| and read something.
  EXPECT_EQ(
      MOJO_RESULT_OK,
      dispatcher2->MapBuffer(0u, kSize, MOJO_MAP_BUFFER_FLAG_NONE, &mapping));
  EXPECT_EQ('x', static_cast<char*>(mapping->GetBase())[0]);

  EXPECT_EQ(MOJO_RESULT_OK, dispatcher2->Close());
}

TEST_F(SharedBufferDispatcherTest, DuplicateBufferHandleOptionsValid) {
  MojoResult result = MOJO_RESULT_INTERNAL;
  auto dispatcher1 = SharedBufferDispatcher::Create(
      platform_support(), SharedBufferDispatcher::kDefaultCreateOptions, 100,
      &result);
  EXPECT_EQ(MOJO_RESULT_OK, result);

  MojoDuplicateBufferHandleOptions options[] = {
      {sizeof(MojoDuplicateBufferHandleOptions),
       MOJO_DUPLICATE_BUFFER_HANDLE_OPTIONS_FLAG_NONE},
      {sizeof(MojoDuplicateBufferHandleOptionsFlags), ~0u}};
  for (size_t i = 0; i < MOJO_ARRAYSIZE(options); i++) {
    RefPtr<Dispatcher> dispatcher2;
    EXPECT_EQ(MOJO_RESULT_OK, dispatcher1->DuplicateBufferHandle(
                                  MakeUserPointer(&options[i]), &dispatcher2));
    ASSERT_TRUE(dispatcher2);
    EXPECT_EQ(Dispatcher::Type::SHARED_BUFFER, dispatcher2->GetType());
    EXPECT_EQ(MOJO_RESULT_OK, dispatcher2->Close());
  }

  EXPECT_EQ(MOJO_RESULT_OK, dispatcher1->Close());
}

TEST_F(SharedBufferDispatcherTest, DuplicateBufferHandleOptionsInvalid) {
  MojoResult result = MOJO_RESULT_INTERNAL;
  auto dispatcher1 = SharedBufferDispatcher::Create(
      platform_support(), SharedBufferDispatcher::kDefaultCreateOptions, 100,
      &result);
  EXPECT_EQ(MOJO_RESULT_OK, result);

  // Invalid |struct_size|.
  {
    MojoDuplicateBufferHandleOptions options = {
        1u, MOJO_DUPLICATE_BUFFER_HANDLE_OPTIONS_FLAG_NONE};
    RefPtr<Dispatcher> dispatcher2;
    EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
              dispatcher1->DuplicateBufferHandle(MakeUserPointer(&options),
                                                 &dispatcher2));
    EXPECT_FALSE(dispatcher2);
  }

  // Unknown |flags|.
  {
    MojoDuplicateBufferHandleOptions options = {
        sizeof(MojoDuplicateBufferHandleOptions), ~0u};
    RefPtr<Dispatcher> dispatcher2;
    EXPECT_EQ(MOJO_RESULT_UNIMPLEMENTED,
              dispatcher1->DuplicateBufferHandle(MakeUserPointer(&options),
                                                 &dispatcher2));
    EXPECT_FALSE(dispatcher2);
  }

  EXPECT_EQ(MOJO_RESULT_OK, dispatcher1->Close());
}

TEST_F(SharedBufferDispatcherTest, CreateInvalidNumBytes) {
  // Size too big.
  MojoResult result = MOJO_RESULT_INTERNAL;
  auto dispatcher = SharedBufferDispatcher::Create(
      platform_support(), SharedBufferDispatcher::kDefaultCreateOptions,
      std::numeric_limits<uint64_t>::max(), &result);
  EXPECT_EQ(MOJO_RESULT_RESOURCE_EXHAUSTED, result);
  EXPECT_FALSE(dispatcher);

  // Zero size.
  result = MOJO_RESULT_INTERNAL;
  dispatcher = SharedBufferDispatcher::Create(
      platform_support(), SharedBufferDispatcher::kDefaultCreateOptions, 0,
      &result);
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT, result);
  EXPECT_FALSE(dispatcher);
}

TEST_F(SharedBufferDispatcherTest, MapBufferInvalidArguments) {
  MojoResult result = MOJO_RESULT_INTERNAL;
  auto dispatcher = SharedBufferDispatcher::Create(
      platform_support(), SharedBufferDispatcher::kDefaultCreateOptions, 100,
      &result);
  EXPECT_EQ(MOJO_RESULT_OK, result);

  std::unique_ptr<PlatformSharedBufferMapping> mapping;
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
            dispatcher->MapBuffer(0, 101, MOJO_MAP_BUFFER_FLAG_NONE, &mapping));
  EXPECT_FALSE(mapping);

  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
            dispatcher->MapBuffer(1, 100, MOJO_MAP_BUFFER_FLAG_NONE, &mapping));
  EXPECT_FALSE(mapping);

  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
            dispatcher->MapBuffer(0, 0, MOJO_MAP_BUFFER_FLAG_NONE, &mapping));
  EXPECT_FALSE(mapping);

  EXPECT_EQ(MOJO_RESULT_OK, dispatcher->Close());
}

}  // namespace
}  // namespace system
}  // namespace mojo
