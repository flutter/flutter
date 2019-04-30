// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <lib/sys/cpp/file_descriptor.h>

#include "gtest/gtest.h"

namespace {

TEST(FileDescriptorTest, CloneStdin) {
  auto file_descriptor = sys::CloneFileDescriptor(0);
  EXPECT_NE(nullptr, file_descriptor);
  EXPECT_TRUE(file_descriptor->handle0.is_valid());
  EXPECT_FALSE(file_descriptor->handle1.is_valid());
  EXPECT_FALSE(file_descriptor->handle2.is_valid());
}

TEST(FileDescriptorTest, CloneBogus) {
  auto file_descriptor = sys::CloneFileDescriptor(53);
  EXPECT_EQ(nullptr, file_descriptor);
}

}  // namespace
