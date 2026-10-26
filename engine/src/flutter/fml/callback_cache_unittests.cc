// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/callback_cache.h"

#include "flutter/fml/file.h"
#include "gtest/gtest.h"

namespace fml::testing {

TEST(CallbackCacheTest, StoresAndReloadsCallbacksFromDisk) {
  fml::ScopedTemporaryDirectory temp_dir;
  ASSERT_TRUE(temp_dir.fd().is_valid());

  CallbackCache::ClearCacheForTesting();
  CallbackCache::SetCachePath(temp_dir.path());
  EXPECT_FALSE(CallbackCache::GetCachePath().empty());

  const int64_t handle = CallbackCache::GetCallbackHandle(
      "callbackName", "CallbackClass", "package:example/main.dart");
  EXPECT_NE(handle, 0);

  auto info = CallbackCache::GetCallbackInformation(handle);
  ASSERT_NE(info, nullptr);
  EXPECT_EQ(info->name, "callbackName");
  EXPECT_EQ(info->class_name, "CallbackClass");
  EXPECT_EQ(info->library_path, "package:example/main.dart");

  // Clear in-memory cache and reload from disk.
  CallbackCache::ClearCacheForTesting();
  EXPECT_EQ(CallbackCache::GetCallbackInformation(handle), nullptr);

  CallbackCache::LoadCacheFromDisk();
  auto reloaded = CallbackCache::GetCallbackInformation(handle);
  ASSERT_NE(reloaded, nullptr);
  EXPECT_EQ(reloaded->name, "callbackName");
  EXPECT_EQ(reloaded->class_name, "CallbackClass");
  EXPECT_EQ(reloaded->library_path, "package:example/main.dart");
}

}  // namespace fml::testing
