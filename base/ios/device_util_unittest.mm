// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

#include "base/ios/device_util.h"
#include "base/strings/sys_string_conversions.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "testing/gtest_mac.h"
#include "testing/platform_test.h"

namespace {
// The behavior of most of these utility functions depends on what they are run
// on, so there is not much to unittest them. The APIs are run to make sure they
// don't choke. Additional checks are added for particular APIs when needed.

typedef PlatformTest DeviceUtilTest;

void CleanNSUserDefaultsForDeviceId() {
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  [defaults removeObjectForKey:@"ChromeClientID"];
  [defaults removeObjectForKey:@"ChromiumClientID"];
  [defaults removeObjectForKey:@"ClientIDGenerationHardwareType"];
  [defaults synchronize];
}

TEST_F(DeviceUtilTest, GetPlatform) {
  GTEST_ASSERT_GT(ios::device_util::GetPlatform().length(), 0U);
}

TEST_F(DeviceUtilTest, IsSingleCoreDevice) {
  ios::device_util::IsSingleCoreDevice();
}

TEST_F(DeviceUtilTest, GetMacAddress) {
  GTEST_ASSERT_GT(ios::device_util::GetMacAddress("en0").length(), 0U);
}

TEST_F(DeviceUtilTest, GetRandomId) {
  GTEST_ASSERT_GT(ios::device_util::GetRandomId().length(), 0U);
}

TEST_F(DeviceUtilTest, GetDeviceIdentifier) {
  CleanNSUserDefaultsForDeviceId();

  std::string default_id = ios::device_util::GetDeviceIdentifier(NULL);
  std::string other_id = ios::device_util::GetDeviceIdentifier("ForTest");
  EXPECT_NE(default_id, other_id);

  CleanNSUserDefaultsForDeviceId();

  std::string new_default_id = ios::device_util::GetDeviceIdentifier(NULL);
  if (![[[[UIDevice currentDevice] identifierForVendor] UUIDString]
          isEqualToString:@"00000000-0000-0000-0000-000000000000"]) {
    EXPECT_EQ(default_id, new_default_id);
  } else {
    EXPECT_NE(default_id, new_default_id);
  }

  CleanNSUserDefaultsForDeviceId();
}

TEST_F(DeviceUtilTest, CheckMigration) {
  CleanNSUserDefaultsForDeviceId();

  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:@"10000000-0000-0000-0000-000000000000"
               forKey:@"ChromeClientID"];
  [defaults synchronize];
  std::string expected_id = ios::device_util::GetDeviceIdentifier(NULL);
  [defaults removeObjectForKey:@"ChromeClientID"];
  [defaults setObject:@"10000000-0000-0000-0000-000000000000"
               forKey:@"ChromiumClientID"];
  [defaults synchronize];
  std::string new_id = ios::device_util::GetDeviceIdentifier(NULL);
  EXPECT_EQ(expected_id, new_id);

  CleanNSUserDefaultsForDeviceId();
}

TEST_F(DeviceUtilTest, CheckMigrationFromZero) {
  CleanNSUserDefaultsForDeviceId();

  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:@"00000000-0000-0000-0000-000000000000"
               forKey:@"ChromeClientID"];
  [defaults synchronize];
  std::string zero_id = ios::device_util::GetDeviceIdentifier(NULL);
  [defaults removeObjectForKey:@"ChromeClientID"];
  [defaults setObject:@"00000000-0000-0000-0000-000000000000"
               forKey:@"ChromiumClientID"];
  [defaults synchronize];
  std::string new_id = ios::device_util::GetDeviceIdentifier(NULL);
  EXPECT_NE(zero_id, new_id);

  CleanNSUserDefaultsForDeviceId();
}

TEST_F(DeviceUtilTest, GetSaltedStringEquals) {
  std::string string1("The quick brown fox jumps over the lazy dog");
  std::string string2("The quick brown fox jumps over the lazy dog");
  std::string salt("salt");
  // Same string and same salt should result in the same salted string.
  EXPECT_EQ(ios::device_util::GetSaltedString(string1, salt),
            ios::device_util::GetSaltedString(string2, salt));
}

TEST_F(DeviceUtilTest, GetSaltedStringNotEquals) {
  std::string string1("The quick brown fox jumps over the lazy dog");
  std::string string2("The lazy brown fox jumps over the quick dog");
  std::string salt("salt");
  // Different string and same salt should result in different salted strings.
  EXPECT_NE(ios::device_util::GetSaltedString(string1, salt),
            ios::device_util::GetSaltedString(string2, salt));
}

TEST_F(DeviceUtilTest, GetSaltedStringDifferentSalt) {
  std::string string1("The quick brown fox jumps over the lazy dog");
  std::string salt1("salt");
  std::string salt2("pepper");
  // Same string with different salt should result in different salted strings.
  EXPECT_NE(ios::device_util::GetSaltedString(string1, salt1),
            ios::device_util::GetSaltedString(string1, salt2));
}

TEST_F(DeviceUtilTest, CheckDeviceMigration) {
  CleanNSUserDefaultsForDeviceId();

  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:@"10000000-0000-0000-0000-000000000000"
               forKey:@"ChromeClientID"];
  [defaults synchronize];
  std::string base_id = ios::device_util::GetDeviceIdentifier(NULL);
  [defaults setObject:@"Foo" forKey:@"ClientIDGenerationHardwareType"];
  [defaults synchronize];
  std::string new_id = ios::device_util::GetDeviceIdentifier(NULL);
  EXPECT_NE(new_id, base_id);

  CleanNSUserDefaultsForDeviceId();
}

}  // namespace
