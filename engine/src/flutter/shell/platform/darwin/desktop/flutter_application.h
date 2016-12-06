// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef __SHELL_PLATFORM_DARWIN_DESKTOP_FLUTTER_APPLICATION__
#define __SHELL_PLATFORM_DARWIN_DESKTOP_FLUTTER_APPLICATION__

#import <AppKit/AppKit.h>

#include "base/mac/scoped_sending_event.h"
#include "base/message_loop/message_pump_mac.h"

// A specific subclass of NSApplication is necessary on Mac in order to
// interact correctly with the main runloop.
@interface FlutterApplication : NSApplication<CrAppProtocol, CrAppControlProtocol>
@end

#endif /* defined(__SHELL_PLATFORM_DARWIN_DESKTOP_FLUTTER_APPLICATION__) */
