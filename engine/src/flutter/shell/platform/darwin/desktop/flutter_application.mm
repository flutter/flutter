// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/desktop/flutter_application.h"

#include "base/auto_reset.h"
#include "base/logging.h"

@implementation FlutterApplication {
  BOOL handlingSendEvent_;
}

+ (void)initialize {
  if (self == [FlutterApplication class]) {
    NSApplication* app = [FlutterApplication sharedApplication];
    DCHECK([app conformsToProtocol:@protocol(CrAppControlProtocol)])
        << "Existing NSApp (class " << [[app className] UTF8String]
        << ") does not conform to required protocol.";
    DCHECK(base::MessagePumpMac::UsingCrApp())
        << "MessagePumpMac::Create() was called before "
        << "+[FlutterApplication initialize]";
  }
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
