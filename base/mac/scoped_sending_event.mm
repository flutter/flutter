// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "base/mac/scoped_sending_event.h"

#include "base/logging.h"

namespace base {
namespace mac {

ScopedSendingEvent::ScopedSendingEvent()
    : app_(static_cast<NSObject<CrAppControlProtocol>*>(NSApp)) {
  DCHECK([app_ conformsToProtocol:@protocol(CrAppControlProtocol)]);
  handling_ = [app_ isHandlingSendEvent];
  [app_ setHandlingSendEvent:YES];
}

ScopedSendingEvent::~ScopedSendingEvent() {
  [app_ setHandlingSendEvent:handling_];
}

}  // namespace mac
}  // namespace base
