// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/jni/jni_mock.h"

#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

TEST(JNIMock, FlutterViewHandlePlatformMessage) {
  JNIMock mock;

  auto message =
      fml::MakeRefCounted<PlatformMessage>("<channel-name>", nullptr);
  auto response_id = 1;

  EXPECT_CALL(mock, FlutterViewHandlePlatformMessage(message, response_id));

  mock.FlutterViewHandlePlatformMessage(message, response_id);
}

}  // namespace testing
}  // namespace flutter
