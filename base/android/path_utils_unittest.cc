// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/android/path_utils.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"

#include "testing/gtest/include/gtest/gtest.h"

namespace base {
namespace android {

typedef testing::Test PathUtilsTest;

TEST_F(PathUtilsTest, TestGetDataDirectory) {
  // The string comes from the Java side and depends on the APK
  // we are running in. Assumes that we are packaged in
  // org.chromium.native_test
  FilePath path;
  GetDataDirectory(&path);
  EXPECT_STREQ("/data/data/org.chromium.native_test/app_chrome",
               path.value().c_str());
}

TEST_F(PathUtilsTest, TestGetCacheDirectory) {
  // The string comes from the Java side and depends on the APK
  // we are running in. Assumes that we are packaged in
  // org.chromium.native_test
  FilePath path;
  GetCacheDirectory(&path);
  EXPECT_STREQ("/data/data/org.chromium.native_test/cache",
               path.value().c_str());
}

TEST_F(PathUtilsTest, TestGetNativeLibraryDirectory) {
  // The string comes from the Java side and depends on the APK
  // we are running in. Assumes that the directory contains
  // the base tests shared object.
  FilePath path;
  GetNativeLibraryDirectory(&path);
  EXPECT_TRUE(base::PathExists(path.Append(("libbase_unittests.so"))) ||
              base::PathExists(path.Append(("libbase_unittests.cr.so"))));
}

}  // namespace android
}  // namespace base
