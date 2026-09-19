// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_MOCK_TSF_BRIDGE_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_MOCK_TSF_BRIDGE_H_

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/windows/tsf_bridge.h"
#include "gmock/gmock.h"

namespace flutter {
namespace testing {

class MockTsfBridge : public TsfBridge {
 public:
  MockTsfBridge() = default;
  ~MockTsfBridge() override = default;

  MOCK_METHOD(bool, available, (), (const, override));
  MOCK_METHOD(void,
              FocusEditable,
              (HWND hwnd, TsfTextStoreDelegate* delegate),
              (override));
  MOCK_METHOD(void, FocusNonEditable, (HWND hwnd), (override));
  MOCK_METHOD(void, ClearFocus, (), (override));
  MOCK_METHOD(void, AbortComposition, (), (override));
  MOCK_METHOD(void, NotifyTextChanged, (), (override));
  MOCK_METHOD(void, NotifySelectionChanged, (), (override));
  MOCK_METHOD(void, NotifyLayoutChanged, (), (override));

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(MockTsfBridge);
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_MOCK_TSF_BRIDGE_H_
