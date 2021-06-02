// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/platform_view_android_delegate/platform_view_android_delegate.h"

#include "flutter/shell/platform/android/jni/jni_mock.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

TEST(PlatformViewShell, UpdateSemanticsDoesFlutterViewUpdateSemantics) {
  auto jni_mock = std::make_shared<JNIMock>();
  auto delegate = std::make_unique<PlatformViewAndroidDelegate>(jni_mock);

  flutter::SemanticsNodeUpdates update;
  flutter::SemanticsNode node0;
  node0.id = 0;
  node0.label = "label";
  update.insert(std::make_pair(0, std::move(node0)));

  std::vector<uint8_t> expected_buffer(164);
  size_t position = 0;
  int32_t* buffer_int32 = reinterpret_cast<int32_t*>(&expected_buffer[0]);
  float* buffer_float32 = reinterpret_cast<float*>(&expected_buffer[0]);
  std::vector<std::string> expected_strings;
  buffer_int32[position++] = node0.id;
  buffer_int32[position++] = node0.flags;
  buffer_int32[position++] = node0.actions;
  buffer_int32[position++] = node0.maxValueLength;
  buffer_int32[position++] = node0.currentValueLength;
  buffer_int32[position++] = node0.textSelectionBase;
  buffer_int32[position++] = node0.textSelectionExtent;
  buffer_int32[position++] = node0.platformViewId;
  buffer_int32[position++] = node0.scrollChildren;
  buffer_int32[position++] = node0.scrollIndex;
  buffer_float32[position++] = static_cast<float>(node0.scrollPosition);
  buffer_float32[position++] = static_cast<float>(node0.scrollExtentMax);
  buffer_float32[position++] = static_cast<float>(node0.scrollExtentMin);
  buffer_int32[position++] = expected_strings.size();  // node0.label
  expected_strings.push_back(node0.label);
  buffer_int32[position++] = -1;  // node0.value
  buffer_int32[position++] = -1;  // node0.increasedValue
  buffer_int32[position++] = -1;  // node0.decreasedValue
  buffer_int32[position++] = -1;  // node0.hint
  buffer_int32[position++] = node0.textDirection;
  buffer_float32[position++] = node0.rect.left();
  buffer_float32[position++] = node0.rect.top();
  buffer_float32[position++] = node0.rect.right();
  buffer_float32[position++] = node0.rect.bottom();
  node0.transform.getColMajor(&buffer_float32[position]);
  position += 16;
  buffer_int32[position++] = 0;  // node0.childrenInTraversalOrder.size();
  buffer_int32[position++] = 0;  // node0.customAccessibilityActions.size();

  EXPECT_CALL(*jni_mock,
              FlutterViewUpdateSemantics(expected_buffer, expected_strings));
  // Creates empty custom actions.
  flutter::CustomAccessibilityActionUpdates actions;
  delegate->UpdateSemantics(update, actions);
}

TEST(PlatformViewShell,
     UpdateSemanticsDoesFlutterViewUpdateCustomAccessibilityActions) {
  auto jni_mock = std::make_shared<JNIMock>();
  auto delegate = std::make_unique<PlatformViewAndroidDelegate>(jni_mock);

  flutter::CustomAccessibilityActionUpdates actions;
  flutter::CustomAccessibilityAction action0;
  action0.id = 0;
  action0.overrideId = 1;
  action0.label = "label";
  action0.hint = "hint";
  actions.insert(std::make_pair(0, std::move(action0)));

  std::vector<uint8_t> expected_actions_buffer(16);
  int32_t* actions_buffer_int32 =
      reinterpret_cast<int32_t*>(&expected_actions_buffer[0]);
  std::vector<std::string> expected_action_strings;
  actions_buffer_int32[0] = action0.id;
  actions_buffer_int32[1] = action0.overrideId;
  actions_buffer_int32[2] = expected_action_strings.size();
  expected_action_strings.push_back(action0.label);
  actions_buffer_int32[3] = expected_action_strings.size();
  expected_action_strings.push_back(action0.hint);

  EXPECT_CALL(*jni_mock, FlutterViewUpdateCustomAccessibilityActions(
                             expected_actions_buffer, expected_action_strings));
  // Creates empty update.
  flutter::SemanticsNodeUpdates update;
  delegate->UpdateSemantics(update, actions);
}

}  // namespace testing
}  // namespace flutter
