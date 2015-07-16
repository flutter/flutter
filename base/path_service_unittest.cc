// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/path_service.h"

#include "base/basictypes.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/files/scoped_temp_dir.h"
#include "base/strings/string_util.h"
#include "build/build_config.h"
#include "testing/gtest/include/gtest/gtest-spi.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "testing/platform_test.h"

#if defined(OS_WIN)
#include "base/win/windows_version.h"
#endif

namespace {

// Returns true if PathService::Get returns true and sets the path parameter
// to non-empty for the given PathService::DirType enumeration value.
bool ReturnsValidPath(int dir_type) {
  base::FilePath path;
  bool result = PathService::Get(dir_type, &path);

  // Some paths might not exist on some platforms in which case confirming
  // |result| is true and !path.empty() is the best we can do.
  bool check_path_exists = true;
#if defined(OS_POSIX)
  // If chromium has never been started on this account, the cache path may not
  // exist.
  if (dir_type == base::DIR_CACHE)
    check_path_exists = false;
#endif
#if defined(OS_LINUX)
  // On the linux try-bots: a path is returned (e.g. /home/chrome-bot/Desktop),
  // but it doesn't exist.
  if (dir_type == base::DIR_USER_DESKTOP)
    check_path_exists = false;
#endif
#if defined(OS_WIN)
  if (dir_type == base::DIR_TASKBAR_PINS) {
    // There is no pinned-to-taskbar shortcuts prior to Win7.
    if (base::win::GetVersion() < base::win::VERSION_WIN7)
      check_path_exists = false;
  }
#endif
#if defined(OS_MACOSX)
  if (dir_type != base::DIR_EXE && dir_type != base::DIR_MODULE &&
      dir_type != base::FILE_EXE && dir_type != base::FILE_MODULE) {
    if (path.ReferencesParent())
      return false;
  }
#else
  if (path.ReferencesParent())
    return false;
#endif
  return result && !path.empty() && (!check_path_exists ||
                                     base::PathExists(path));
}

#if defined(OS_WIN)
// Function to test any directory keys that are not supported on some versions
// of Windows. Checks that the function fails and that the returned path is
// empty.
bool ReturnsInvalidPath(int dir_type) {
  base::FilePath path;
  bool result = PathService::Get(dir_type, &path);
  return !result && path.empty();
}
#endif

}  // namespace

// On the Mac this winds up using some autoreleased objects, so we need to
// be a PlatformTest.
typedef PlatformTest PathServiceTest;

// Test that all PathService::Get calls return a value and a true result
// in the development environment.  (This test was created because a few
// later changes to Get broke the semantics of the function and yielded the
// correct value while returning false.)
TEST_F(PathServiceTest, Get) {
  for (int key = base::PATH_START + 1; key < base::PATH_END; ++key) {
#if defined(OS_ANDROID)
    if (key == base::FILE_MODULE || key == base::DIR_USER_DESKTOP ||
        key == base::DIR_HOME)
      continue;  // Android doesn't implement these.
#elif defined(OS_IOS)
    if (key == base::DIR_USER_DESKTOP)
      continue;  // iOS doesn't implement DIR_USER_DESKTOP;
#endif
    EXPECT_PRED1(ReturnsValidPath, key);
  }
#if defined(OS_WIN)
  for (int key = base::PATH_WIN_START + 1; key < base::PATH_WIN_END; ++key) {
    bool valid = true;
    if (key == base::DIR_APP_SHORTCUTS)
      valid = base::win::GetVersion() >= base::win::VERSION_WIN8;

    if (valid)
      EXPECT_TRUE(ReturnsValidPath(key)) << key;
    else
      EXPECT_TRUE(ReturnsInvalidPath(key)) << key;
  }
#elif defined(OS_MACOSX)
  for (int key = base::PATH_MAC_START + 1; key < base::PATH_MAC_END; ++key) {
    EXPECT_PRED1(ReturnsValidPath, key);
  }
#elif defined(OS_ANDROID)
  for (int key = base::PATH_ANDROID_START + 1; key < base::PATH_ANDROID_END;
       ++key) {
    EXPECT_PRED1(ReturnsValidPath, key);
  }
#elif defined(OS_POSIX)
  for (int key = base::PATH_POSIX_START + 1; key < base::PATH_POSIX_END;
       ++key) {
    EXPECT_PRED1(ReturnsValidPath, key);
  }
#endif
}

// Test that all versions of the Override function of PathService do what they
// are supposed to do.
TEST_F(PathServiceTest, Override) {
  int my_special_key = 666;
  base::ScopedTempDir temp_dir;
  ASSERT_TRUE(temp_dir.CreateUniqueTempDir());
  base::FilePath fake_cache_dir(temp_dir.path().AppendASCII("cache"));
  // PathService::Override should always create the path provided if it doesn't
  // exist.
  EXPECT_TRUE(PathService::Override(my_special_key, fake_cache_dir));
  EXPECT_TRUE(base::PathExists(fake_cache_dir));

  base::FilePath fake_cache_dir2(temp_dir.path().AppendASCII("cache2"));
  // PathService::OverrideAndCreateIfNeeded should obey the |create| parameter.
  PathService::OverrideAndCreateIfNeeded(my_special_key,
                                         fake_cache_dir2,
                                         false,
                                         false);
  EXPECT_FALSE(base::PathExists(fake_cache_dir2));
  EXPECT_TRUE(PathService::OverrideAndCreateIfNeeded(my_special_key,
                                                     fake_cache_dir2,
                                                     false,
                                                     true));
  EXPECT_TRUE(base::PathExists(fake_cache_dir2));

#if defined(OS_POSIX)
  base::FilePath non_existent(
      base::MakeAbsoluteFilePath(temp_dir.path()).AppendASCII("non_existent"));
  EXPECT_TRUE(non_existent.IsAbsolute());
  EXPECT_FALSE(base::PathExists(non_existent));
#if !defined(OS_ANDROID)
  // This fails because MakeAbsoluteFilePath fails for non-existent files.
  // Earlier versions of Bionic libc don't fail for non-existent files, so
  // skip this check on Android.
  EXPECT_FALSE(PathService::OverrideAndCreateIfNeeded(my_special_key,
                                                      non_existent,
                                                      false,
                                                      false));
#endif
  // This works because indicating that |non_existent| is absolute skips the
  // internal MakeAbsoluteFilePath call.
  EXPECT_TRUE(PathService::OverrideAndCreateIfNeeded(my_special_key,
                                                     non_existent,
                                                     true,
                                                     false));
  // Check that the path has been overridden and no directory was created.
  EXPECT_FALSE(base::PathExists(non_existent));
  base::FilePath path;
  EXPECT_TRUE(PathService::Get(my_special_key, &path));
  EXPECT_EQ(non_existent, path);
#endif
}

// Check if multiple overrides can co-exist.
TEST_F(PathServiceTest, OverrideMultiple) {
  int my_special_key = 666;
  base::ScopedTempDir temp_dir;
  ASSERT_TRUE(temp_dir.CreateUniqueTempDir());
  base::FilePath fake_cache_dir1(temp_dir.path().AppendASCII("1"));
  EXPECT_TRUE(PathService::Override(my_special_key, fake_cache_dir1));
  EXPECT_TRUE(base::PathExists(fake_cache_dir1));
  ASSERT_EQ(1, base::WriteFile(fake_cache_dir1.AppendASCII("t1"), ".", 1));

  base::FilePath fake_cache_dir2(temp_dir.path().AppendASCII("2"));
  EXPECT_TRUE(PathService::Override(my_special_key + 1, fake_cache_dir2));
  EXPECT_TRUE(base::PathExists(fake_cache_dir2));
  ASSERT_EQ(1, base::WriteFile(fake_cache_dir2.AppendASCII("t2"), ".", 1));

  base::FilePath result;
  EXPECT_TRUE(PathService::Get(my_special_key, &result));
  // Override might have changed the path representation but our test file
  // should be still there.
  EXPECT_TRUE(base::PathExists(result.AppendASCII("t1")));
  EXPECT_TRUE(PathService::Get(my_special_key + 1, &result));
  EXPECT_TRUE(base::PathExists(result.AppendASCII("t2")));
}

TEST_F(PathServiceTest, RemoveOverride) {
  // Before we start the test we have to call RemoveOverride at least once to
  // clear any overrides that might have been left from other tests.
  PathService::RemoveOverride(base::DIR_TEMP);

  base::FilePath original_user_data_dir;
  EXPECT_TRUE(PathService::Get(base::DIR_TEMP, &original_user_data_dir));
  EXPECT_FALSE(PathService::RemoveOverride(base::DIR_TEMP));

  base::ScopedTempDir temp_dir;
  ASSERT_TRUE(temp_dir.CreateUniqueTempDir());
  EXPECT_TRUE(PathService::Override(base::DIR_TEMP, temp_dir.path()));
  base::FilePath new_user_data_dir;
  EXPECT_TRUE(PathService::Get(base::DIR_TEMP, &new_user_data_dir));
  EXPECT_NE(original_user_data_dir, new_user_data_dir);

  EXPECT_TRUE(PathService::RemoveOverride(base::DIR_TEMP));
  EXPECT_TRUE(PathService::Get(base::DIR_TEMP, &new_user_data_dir));
  EXPECT_EQ(original_user_data_dir, new_user_data_dir);
}

#if defined(OS_WIN)
TEST_F(PathServiceTest, GetProgramFiles) {
  base::FilePath programfiles_dir;
#if defined(_WIN64)
  // 64-bit on 64-bit.
  EXPECT_TRUE(PathService::Get(base::DIR_PROGRAM_FILES,
      &programfiles_dir));
  EXPECT_EQ(programfiles_dir.value(),
      FILE_PATH_LITERAL("C:\\Program Files"));
  EXPECT_TRUE(PathService::Get(base::DIR_PROGRAM_FILESX86,
      &programfiles_dir));
  EXPECT_EQ(programfiles_dir.value(),
      FILE_PATH_LITERAL("C:\\Program Files (x86)"));
  EXPECT_TRUE(PathService::Get(base::DIR_PROGRAM_FILES6432,
      &programfiles_dir));
  EXPECT_EQ(programfiles_dir.value(),
      FILE_PATH_LITERAL("C:\\Program Files"));
#else
  if (base::win::OSInfo::GetInstance()->wow64_status() ==
      base::win::OSInfo::WOW64_ENABLED) {
    // 32-bit on 64-bit.
    EXPECT_TRUE(PathService::Get(base::DIR_PROGRAM_FILES,
        &programfiles_dir));
    EXPECT_EQ(programfiles_dir.value(),
        FILE_PATH_LITERAL("C:\\Program Files (x86)"));
    EXPECT_TRUE(PathService::Get(base::DIR_PROGRAM_FILESX86,
        &programfiles_dir));
    EXPECT_EQ(programfiles_dir.value(),
        FILE_PATH_LITERAL("C:\\Program Files (x86)"));
    EXPECT_TRUE(PathService::Get(base::DIR_PROGRAM_FILES6432,
        &programfiles_dir));
    EXPECT_EQ(programfiles_dir.value(),
        FILE_PATH_LITERAL("C:\\Program Files"));
  } else {
    // 32-bit on 32-bit.
    EXPECT_TRUE(PathService::Get(base::DIR_PROGRAM_FILES,
        &programfiles_dir));
    EXPECT_EQ(programfiles_dir.value(),
        FILE_PATH_LITERAL("C:\\Program Files"));
    EXPECT_TRUE(PathService::Get(base::DIR_PROGRAM_FILESX86,
        &programfiles_dir));
    EXPECT_EQ(programfiles_dir.value(),
        FILE_PATH_LITERAL("C:\\Program Files"));
    EXPECT_TRUE(PathService::Get(base::DIR_PROGRAM_FILES6432,
        &programfiles_dir));
    EXPECT_EQ(programfiles_dir.value(),
        FILE_PATH_LITERAL("C:\\Program Files"));
  }
#endif
}
#endif
