// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TEST_MOCK_CHROME_APPLICATION_MAC_H_
#define BASE_TEST_MOCK_CHROME_APPLICATION_MAC_H_

#if defined(__OBJC__)

#import <AppKit/AppKit.h>

#include "base/mac/scoped_sending_event.h"
#include "base/message_loop/message_pump_mac.h"

// A basic implementation of CrAppProtocol and
// CrAppControlProtocol. This can be used in tests that need an
// NSApplication and use a runloop, or which need a ScopedSendingEvent
// when handling a nested event loop.
@interface MockCrApp : NSApplication<CrAppProtocol,
                                     CrAppControlProtocol> {
 @private
  BOOL handlingSendEvent_;
}
@end

#endif

// To be used to instantiate MockCrApp from C++ code.
namespace mock_cr_app {
void RegisterMockCrApp();
}  // namespace mock_cr_app

#endif  // BASE_TEST_MOCK_CHROME_APPLICATION_MAC_H_
