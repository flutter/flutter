// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/message_loop/message_pump.h"

namespace base {

MessagePump::MessagePump() {
}

MessagePump::~MessagePump() {
}

void MessagePump::SetTimerSlack(TimerSlack) {
}

}  // namespace base
