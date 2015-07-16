// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/nix/xdg_util.h"

#include "base/environment.h"
#include "testing/gmock/include/gmock/gmock.h"
#include "testing/gtest/include/gtest/gtest.h"

using ::testing::_;
using ::testing::Return;
using ::testing::SetArgumentPointee;
using ::testing::StrEq;

namespace base {
namespace nix {

namespace {

class MockEnvironment : public Environment {
 public:
  MOCK_METHOD2(GetVar, bool(const char*, std::string* result));
  MOCK_METHOD2(SetVar, bool(const char*, const std::string& new_value));
  MOCK_METHOD1(UnSetVar, bool(const char*));
};

// Needs to be const char* to make gmock happy.
const char* const kDesktopGnome = "gnome";
const char* const kDesktopGnomeFallback = "gnome-fallback";
const char* const kDesktopMATE = "mate";
const char* const kDesktopKDE4 = "kde4";
const char* const kDesktopKDE = "kde";
const char* const kDesktopXFCE = "xfce";
const char* const kXdgDesktopGNOME = "GNOME";
const char* const kXdgDesktopKDE = "KDE";
const char* const kXdgDesktopUnity = "Unity";

const char kDesktopSession[] = "DESKTOP_SESSION";
const char kXdgDesktop[] = "XDG_CURRENT_DESKTOP";

}  // namespace

TEST(XDGUtilTest, GetDesktopEnvironmentGnome) {
  MockEnvironment getter;
  EXPECT_CALL(getter, GetVar(_, _)).WillRepeatedly(Return(false));
  EXPECT_CALL(getter, GetVar(StrEq(kDesktopSession), _))
      .WillOnce(DoAll(SetArgumentPointee<1>(kDesktopGnome), Return(true)));

  EXPECT_EQ(DESKTOP_ENVIRONMENT_GNOME, GetDesktopEnvironment(&getter));
}

TEST(XDGUtilTest, GetDesktopEnvironmentMATE) {
  MockEnvironment getter;
  EXPECT_CALL(getter, GetVar(_, _)).WillRepeatedly(Return(false));
  EXPECT_CALL(getter, GetVar(StrEq(kDesktopSession), _))
      .WillOnce(DoAll(SetArgumentPointee<1>(kDesktopMATE), Return(true)));

  EXPECT_EQ(DESKTOP_ENVIRONMENT_GNOME, GetDesktopEnvironment(&getter));
}

TEST(XDGUtilTest, GetDesktopEnvironmentKDE4) {
  MockEnvironment getter;
  EXPECT_CALL(getter, GetVar(_, _)).WillRepeatedly(Return(false));
  EXPECT_CALL(getter, GetVar(StrEq(kDesktopSession), _))
      .WillOnce(DoAll(SetArgumentPointee<1>(kDesktopKDE4), Return(true)));

  EXPECT_EQ(DESKTOP_ENVIRONMENT_KDE4, GetDesktopEnvironment(&getter));
}

TEST(XDGUtilTest, GetDesktopEnvironmentKDE3) {
  MockEnvironment getter;
  EXPECT_CALL(getter, GetVar(_, _)).WillRepeatedly(Return(false));
  EXPECT_CALL(getter, GetVar(StrEq(kDesktopSession), _))
      .WillOnce(DoAll(SetArgumentPointee<1>(kDesktopKDE), Return(true)));

  EXPECT_EQ(DESKTOP_ENVIRONMENT_KDE3, GetDesktopEnvironment(&getter));
}

TEST(XDGUtilTest, GetDesktopEnvironmentXFCE) {
  MockEnvironment getter;
  EXPECT_CALL(getter, GetVar(_, _)).WillRepeatedly(Return(false));
  EXPECT_CALL(getter, GetVar(StrEq(kDesktopSession), _))
      .WillOnce(DoAll(SetArgumentPointee<1>(kDesktopXFCE), Return(true)));

  EXPECT_EQ(DESKTOP_ENVIRONMENT_XFCE, GetDesktopEnvironment(&getter));
}

TEST(XDGUtilTest, GetXdgDesktopGnome) {
  MockEnvironment getter;
  EXPECT_CALL(getter, GetVar(_, _)).WillRepeatedly(Return(false));
  EXPECT_CALL(getter, GetVar(StrEq(kXdgDesktop), _))
      .WillOnce(DoAll(SetArgumentPointee<1>(kXdgDesktopGNOME), Return(true)));

  EXPECT_EQ(DESKTOP_ENVIRONMENT_GNOME, GetDesktopEnvironment(&getter));
}

TEST(XDGUtilTest, GetXdgDesktopGnomeFallback) {
  MockEnvironment getter;
  EXPECT_CALL(getter, GetVar(_, _)).WillRepeatedly(Return(false));
  EXPECT_CALL(getter, GetVar(StrEq(kXdgDesktop), _))
      .WillOnce(DoAll(SetArgumentPointee<1>(kXdgDesktopUnity), Return(true)));
  EXPECT_CALL(getter, GetVar(StrEq(kDesktopSession), _))
      .WillOnce(DoAll(SetArgumentPointee<1>(kDesktopGnomeFallback),
                      Return(true)));

  EXPECT_EQ(DESKTOP_ENVIRONMENT_GNOME, GetDesktopEnvironment(&getter));
}

TEST(XDGUtilTest, GetXdgDesktopKDE4) {
  MockEnvironment getter;
  EXPECT_CALL(getter, GetVar(_, _)).WillRepeatedly(Return(false));
  EXPECT_CALL(getter, GetVar(StrEq(kXdgDesktop), _))
      .WillOnce(DoAll(SetArgumentPointee<1>(kXdgDesktopKDE), Return(true)));

  EXPECT_EQ(DESKTOP_ENVIRONMENT_KDE4, GetDesktopEnvironment(&getter));
}

TEST(XDGUtilTest, GetXdgDesktopUnity) {
  MockEnvironment getter;
  EXPECT_CALL(getter, GetVar(_, _)).WillRepeatedly(Return(false));
  EXPECT_CALL(getter, GetVar(StrEq(kXdgDesktop), _))
      .WillOnce(DoAll(SetArgumentPointee<1>(kXdgDesktopUnity), Return(true)));

  EXPECT_EQ(DESKTOP_ENVIRONMENT_UNITY, GetDesktopEnvironment(&getter));
}

}  // namespace nix
}  // namespace base
