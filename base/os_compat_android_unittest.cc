// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/os_compat_android.h"

#include "base/files/file_util.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

typedef testing::Test OsCompatAndroidTest;

// Keep this Unittest DISABLED_ , because it actually creates a directory in the
// device and it may be source of flakyness. For any changes in the mkdtemp
// function, you should run this unittest in your local machine to check if it
// passes.
TEST_F(OsCompatAndroidTest, DISABLED_TestMkdTemp) {
  FilePath tmp_dir;
  EXPECT_TRUE(base::GetTempDir(&tmp_dir));

  // Not six XXXXXX at the suffix of the path.
  FilePath sub_dir = tmp_dir.Append("XX");
  std::string sub_dir_string = sub_dir.value();
  // this should be OK since mkdtemp just replaces characters in place
  char* buffer = const_cast<char*>(sub_dir_string.c_str());
  EXPECT_EQ(NULL, mkdtemp(buffer));

  // Directory does not exist
  char invalid_path2[] = "doesntoexist/foobarXXXXXX";
  EXPECT_EQ(NULL, mkdtemp(invalid_path2));

  // Successfully create a tmp dir.
  FilePath sub_dir2 = tmp_dir.Append("XXXXXX");
  std::string sub_dir2_string = sub_dir2.value();
  // this should be OK since mkdtemp just replaces characters in place
  char* buffer2 = const_cast<char*>(sub_dir2_string.c_str());
  EXPECT_TRUE(mkdtemp(buffer2) != NULL);
}

}  // namespace base
