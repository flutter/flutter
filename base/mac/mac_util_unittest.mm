// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Cocoa/Cocoa.h>

#include "base/mac/mac_util.h"

#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/files/scoped_temp_dir.h"
#include "base/mac/foundation_util.h"
#include "base/mac/scoped_cftyperef.h"
#include "base/mac/scoped_nsobject.h"
#include "base/sys_info.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "testing/platform_test.h"

#include <errno.h>
#include <sys/xattr.h>

namespace base {
namespace mac {

namespace {

typedef PlatformTest MacUtilTest;

TEST_F(MacUtilTest, TestFSRef) {
  FSRef ref;
  std::string path("/System/Library");

  ASSERT_TRUE(FSRefFromPath(path, &ref));
  EXPECT_EQ(path, PathFromFSRef(ref));
}

TEST_F(MacUtilTest, GetUserDirectoryTest) {
  // Try a few keys, make sure they come back with non-empty paths.
  FilePath caches_dir;
  EXPECT_TRUE(GetUserDirectory(NSCachesDirectory, &caches_dir));
  EXPECT_FALSE(caches_dir.empty());

  FilePath application_support_dir;
  EXPECT_TRUE(GetUserDirectory(NSApplicationSupportDirectory,
                               &application_support_dir));
  EXPECT_FALSE(application_support_dir.empty());

  FilePath library_dir;
  EXPECT_TRUE(GetUserDirectory(NSLibraryDirectory, &library_dir));
  EXPECT_FALSE(library_dir.empty());
}

TEST_F(MacUtilTest, TestLibraryPath) {
  FilePath library_dir = GetUserLibraryPath();
  // Make sure the string isn't empty.
  EXPECT_FALSE(library_dir.value().empty());
}

TEST_F(MacUtilTest, TestGetAppBundlePath) {
  FilePath out;

  // Make sure it doesn't crash.
  out = GetAppBundlePath(FilePath());
  EXPECT_TRUE(out.empty());

  // Some more invalid inputs.
  const char* const invalid_inputs[] = {
    "/", "/foo", "foo", "/foo/bar.", "foo/bar.", "/foo/bar./bazquux",
    "foo/bar./bazquux", "foo/.app", "//foo",
  };
  for (size_t i = 0; i < arraysize(invalid_inputs); i++) {
    out = GetAppBundlePath(FilePath(invalid_inputs[i]));
    EXPECT_TRUE(out.empty()) << "loop: " << i;
  }

  // Some valid inputs; this and |expected_outputs| should be in sync.
  struct {
    const char *in;
    const char *expected_out;
  } valid_inputs[] = {
    { "FooBar.app/", "FooBar.app" },
    { "/FooBar.app", "/FooBar.app" },
    { "/FooBar.app/", "/FooBar.app" },
    { "//FooBar.app", "//FooBar.app" },
    { "/Foo/Bar.app", "/Foo/Bar.app" },
    { "/Foo/Bar.app/", "/Foo/Bar.app" },
    { "/F/B.app", "/F/B.app" },
    { "/F/B.app/", "/F/B.app" },
    { "/Foo/Bar.app/baz", "/Foo/Bar.app" },
    { "/Foo/Bar.app/baz/", "/Foo/Bar.app" },
    { "/Foo/Bar.app/baz/quux.app/quuux", "/Foo/Bar.app" },
    { "/Applications/Google Foo.app/bar/Foo Helper.app/quux/Foo Helper",
        "/Applications/Google Foo.app" },
  };
  for (size_t i = 0; i < arraysize(valid_inputs); i++) {
    out = GetAppBundlePath(FilePath(valid_inputs[i].in));
    EXPECT_FALSE(out.empty()) << "loop: " << i;
    EXPECT_STREQ(valid_inputs[i].expected_out,
        out.value().c_str()) << "loop: " << i;
  }
}

// http://crbug.com/425745
TEST_F(MacUtilTest, DISABLED_TestExcludeFileFromBackups) {
  // The file must already exist in order to set its exclusion property.
  ScopedTempDir temp_dir_;
  ASSERT_TRUE(temp_dir_.CreateUniqueTempDir());
  FilePath dummy_file_path = temp_dir_.path().Append("DummyFile");
  const char dummy_data[] = "All your base are belong to us!";
  // Dump something real into the file.
  ASSERT_EQ(static_cast<int>(arraysize(dummy_data)),
            WriteFile(dummy_file_path, dummy_data, arraysize(dummy_data)));
  NSString* fileURLString =
      [NSString stringWithUTF8String:dummy_file_path.value().c_str()];
  NSURL* fileURL = [NSURL URLWithString:fileURLString];
  // Initial state should be non-excluded.
  EXPECT_FALSE(CSBackupIsItemExcluded(base::mac::NSToCFCast(fileURL), NULL));
  // Exclude the file.
  EXPECT_TRUE(SetFileBackupExclusion(dummy_file_path));
  // SetFileBackupExclusion never excludes by path.
  Boolean excluded_by_path = FALSE;
  Boolean excluded =
      CSBackupIsItemExcluded(base::mac::NSToCFCast(fileURL), &excluded_by_path);
  EXPECT_TRUE(excluded);
  EXPECT_FALSE(excluded_by_path);
}

TEST_F(MacUtilTest, NSObjectRetainRelease) {
  base::scoped_nsobject<NSArray> array(
      [[NSArray alloc] initWithObjects:@"foo", nil]);
  EXPECT_EQ(1U, [array retainCount]);

  NSObjectRetain(array);
  EXPECT_EQ(2U, [array retainCount]);

  NSObjectRelease(array);
  EXPECT_EQ(1U, [array retainCount]);
}

TEST_F(MacUtilTest, IsOSEllipsis) {
  int32 major, minor, bugfix;
  base::SysInfo::OperatingSystemVersionNumbers(&major, &minor, &bugfix);

  if (major == 10) {
    if (minor == 6) {
      EXPECT_TRUE(IsOSSnowLeopard());
      EXPECT_FALSE(IsOSLion());
      EXPECT_TRUE(IsOSLionOrEarlier());
      EXPECT_FALSE(IsOSLionOrLater());
      EXPECT_FALSE(IsOSMountainLion());
      EXPECT_TRUE(IsOSMountainLionOrEarlier());
      EXPECT_FALSE(IsOSMountainLionOrLater());
      EXPECT_FALSE(IsOSMavericks());
      EXPECT_TRUE(IsOSMavericksOrEarlier());
      EXPECT_FALSE(IsOSMavericksOrLater());
      EXPECT_FALSE(IsOSYosemite());
      EXPECT_FALSE(IsOSYosemiteOrLater());
      EXPECT_FALSE(IsOSLaterThanYosemite_DontCallThis());
    } else if (minor == 7) {
      EXPECT_FALSE(IsOSSnowLeopard());
      EXPECT_TRUE(IsOSLion());
      EXPECT_TRUE(IsOSLionOrEarlier());
      EXPECT_TRUE(IsOSLionOrLater());
      EXPECT_FALSE(IsOSMountainLion());
      EXPECT_TRUE(IsOSMountainLionOrEarlier());
      EXPECT_FALSE(IsOSMountainLionOrLater());
      EXPECT_FALSE(IsOSMavericks());
      EXPECT_TRUE(IsOSMavericksOrEarlier());
      EXPECT_FALSE(IsOSMavericksOrLater());
      EXPECT_FALSE(IsOSYosemite());
      EXPECT_FALSE(IsOSYosemiteOrLater());
      EXPECT_FALSE(IsOSLaterThanYosemite_DontCallThis());
    } else if (minor == 8) {
      EXPECT_FALSE(IsOSSnowLeopard());
      EXPECT_FALSE(IsOSLion());
      EXPECT_FALSE(IsOSLionOrEarlier());
      EXPECT_TRUE(IsOSLionOrLater());
      EXPECT_TRUE(IsOSMountainLion());
      EXPECT_TRUE(IsOSMountainLionOrEarlier());
      EXPECT_TRUE(IsOSMountainLionOrLater());
      EXPECT_FALSE(IsOSMavericks());
      EXPECT_TRUE(IsOSMavericksOrEarlier());
      EXPECT_FALSE(IsOSMavericksOrLater());
      EXPECT_FALSE(IsOSYosemite());
      EXPECT_FALSE(IsOSYosemiteOrLater());
      EXPECT_FALSE(IsOSLaterThanYosemite_DontCallThis());
    } else if (minor == 9) {
      EXPECT_FALSE(IsOSSnowLeopard());
      EXPECT_FALSE(IsOSLion());
      EXPECT_FALSE(IsOSLionOrEarlier());
      EXPECT_TRUE(IsOSLionOrLater());
      EXPECT_FALSE(IsOSMountainLion());
      EXPECT_FALSE(IsOSMountainLionOrEarlier());
      EXPECT_TRUE(IsOSMountainLionOrLater());
      EXPECT_TRUE(IsOSMavericks());
      EXPECT_TRUE(IsOSMavericksOrEarlier());
      EXPECT_TRUE(IsOSMavericksOrLater());
      EXPECT_FALSE(IsOSYosemite());
      EXPECT_FALSE(IsOSYosemiteOrLater());
      EXPECT_FALSE(IsOSLaterThanYosemite_DontCallThis());
    } else if (minor == 10) {
      EXPECT_FALSE(IsOSSnowLeopard());
      EXPECT_FALSE(IsOSLion());
      EXPECT_FALSE(IsOSLionOrEarlier());
      EXPECT_TRUE(IsOSLionOrLater());
      EXPECT_FALSE(IsOSMountainLion());
      EXPECT_FALSE(IsOSMountainLionOrEarlier());
      EXPECT_TRUE(IsOSMountainLionOrLater());
      EXPECT_FALSE(IsOSMavericks());
      EXPECT_FALSE(IsOSMavericksOrEarlier());
      EXPECT_TRUE(IsOSMavericksOrLater());
      EXPECT_TRUE(IsOSYosemite());
      EXPECT_TRUE(IsOSYosemiteOrLater());
      EXPECT_FALSE(IsOSLaterThanYosemite_DontCallThis());
    } else {
      // Not six, seven, eight, nine, or ten. Ah, ah, ah.
      EXPECT_TRUE(false);
    }
  } else {
    // Not ten. What you gonna do?
    EXPECT_FALSE(true);
  }
}

TEST_F(MacUtilTest, ParseModelIdentifier) {
  std::string model;
  int32 major = 1, minor = 2;

  EXPECT_FALSE(ParseModelIdentifier("", &model, &major, &minor));
  EXPECT_EQ(0U, model.length());
  EXPECT_EQ(1, major);
  EXPECT_EQ(2, minor);
  EXPECT_FALSE(ParseModelIdentifier("FooBar", &model, &major, &minor));

  EXPECT_TRUE(ParseModelIdentifier("MacPro4,1", &model, &major, &minor));
  EXPECT_EQ(model, "MacPro");
  EXPECT_EQ(4, major);
  EXPECT_EQ(1, minor);

  EXPECT_TRUE(ParseModelIdentifier("MacBookPro6,2", &model, &major, &minor));
  EXPECT_EQ(model, "MacBookPro");
  EXPECT_EQ(6, major);
  EXPECT_EQ(2, minor);
}

TEST_F(MacUtilTest, TestRemoveQuarantineAttribute) {
  ScopedTempDir temp_dir_;
  ASSERT_TRUE(temp_dir_.CreateUniqueTempDir());
  FilePath dummy_folder_path = temp_dir_.path().Append("DummyFolder");
  ASSERT_TRUE(base::CreateDirectory(dummy_folder_path));
  const char* quarantine_str = "0000;4b392bb2;Chromium;|org.chromium.Chromium";
  const char* file_path_str = dummy_folder_path.value().c_str();
  EXPECT_EQ(0, setxattr(file_path_str, "com.apple.quarantine",
      quarantine_str, strlen(quarantine_str), 0, 0));
  EXPECT_EQ(static_cast<long>(strlen(quarantine_str)),
      getxattr(file_path_str, "com.apple.quarantine",
          NULL, 0, 0, 0));
  EXPECT_TRUE(RemoveQuarantineAttribute(dummy_folder_path));
  EXPECT_EQ(-1, getxattr(file_path_str, "com.apple.quarantine", NULL, 0, 0, 0));
  EXPECT_EQ(ENOATTR, errno);
}

TEST_F(MacUtilTest, TestRemoveQuarantineAttributeTwice) {
  ScopedTempDir temp_dir_;
  ASSERT_TRUE(temp_dir_.CreateUniqueTempDir());
  FilePath dummy_folder_path = temp_dir_.path().Append("DummyFolder");
  const char* file_path_str = dummy_folder_path.value().c_str();
  ASSERT_TRUE(base::CreateDirectory(dummy_folder_path));
  EXPECT_EQ(-1, getxattr(file_path_str, "com.apple.quarantine", NULL, 0, 0, 0));
  // No quarantine attribute to begin with, but RemoveQuarantineAttribute still
  // succeeds because in the end the folder still doesn't have the quarantine
  // attribute set.
  EXPECT_TRUE(RemoveQuarantineAttribute(dummy_folder_path));
  EXPECT_TRUE(RemoveQuarantineAttribute(dummy_folder_path));
  EXPECT_EQ(ENOATTR, errno);
}

TEST_F(MacUtilTest, TestRemoveQuarantineAttributeNonExistentPath) {
  ScopedTempDir temp_dir_;
  ASSERT_TRUE(temp_dir_.CreateUniqueTempDir());
  FilePath non_existent_path = temp_dir_.path().Append("DummyPath");
  ASSERT_FALSE(PathExists(non_existent_path));
  EXPECT_FALSE(RemoveQuarantineAttribute(non_existent_path));
}

}  // namespace

}  // namespace mac
}  // namespace base
