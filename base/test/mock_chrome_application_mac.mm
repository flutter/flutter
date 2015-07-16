// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/mock_chrome_application_mac.h"

#include "base/auto_reset.h"
#include "base/logging.h"

@implementation MockCrApp

+ (NSApplication*)sharedApplication {
  NSApplication* app = [super sharedApplication];
  DCHECK([app conformsToProtocol:@protocol(CrAppControlProtocol)])
      << "Existing NSApp (class " << [[app className] UTF8String]
      << ") does not conform to required protocol.";
  DCHECK(base::MessagePumpMac::UsingCrApp())
      << "MessagePumpMac::Create() was called before "
      << "+[MockCrApp sharedApplication]";
  return app;
}

- (void)sendEvent:(NSEvent*)event {
  base::AutoReset<BOOL> scoper(&handlingSendEvent_, YES);
  [super sendEvent:event];
}

- (void)setHandlingSendEvent:(BOOL)handlingSendEvent {
  handlingSendEvent_ = handlingSendEvent;
}

- (BOOL)isHandlingSendEvent {
  return handlingSendEvent_;
}

@end

namespace mock_cr_app {

void RegisterMockCrApp() {
  [MockCrApp sharedApplication];
}

}  // namespace mock_cr_app
