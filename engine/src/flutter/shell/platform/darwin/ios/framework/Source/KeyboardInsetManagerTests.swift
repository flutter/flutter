// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Testing

@testable import InternalFlutterSwift

struct KeyboardInsetManagerTests {
  @Test func staleKeyboardAnimationTimestampIsIgnored() {
    #expect(keyboardAnimationElapsedTime(targetTime: 9.0, animationStartTime: 10.0) == nil)
  }

  @Test func keyboardAnimationTimestampAtStartHasNoElapsedTime() {
    #expect(keyboardAnimationElapsedTime(targetTime: 10.0, animationStartTime: 10.0) == 0.0)
  }

  @Test func keyboardAnimationTimestampAfterStartHasPositiveElapsedTime() {
    #expect(keyboardAnimationElapsedTime(targetTime: 10.25, animationStartTime: 10.0) == 0.25)
  }
}
