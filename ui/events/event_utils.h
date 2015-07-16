// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_EVENT_UTILS_H_
#define UI_EVENTS_EVENT_UTILS_H_

#include "base/basictypes.h"
#include "base/event_types.h"
#include "base/strings/string16.h"
#include "ui/events/events_export.h"

namespace base {
class TimeDelta;
}

namespace ui {

// Create a timestamp based on the current time.
EVENTS_EXPORT base::TimeDelta EventTimeForNow();

// Returns a control character sequences from a |windows_key_code|.
EVENTS_EXPORT base::char16 GetControlCharacterForKeycode(int windows_key_code,
                                                         bool shift);

}  // namespace ui

#endif  // UI_EVENTS_EVENT_UTILS_H_
