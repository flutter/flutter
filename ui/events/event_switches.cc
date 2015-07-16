// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/events/event_switches.h"

namespace switches {

// Enable scroll prediction for scroll update events.
const char kEnableScrollPrediction[] = "enable-scroll-prediction";

// Enable support for touch events.
const char kTouchEvents[] = "touch-events";

// The values the kTouchEvents switch may have, as in --touch-events=disabled.
//   auto: enabled at startup when an attached touchscreen is present.
const char kTouchEventsAuto[] = "auto";
//   enabled: touch events always enabled.
const char kTouchEventsEnabled[] = "enabled";
//   disabled: touch events are disabled.
const char kTouchEventsDisabled[] = "disabled";

// Enable compensation for unstable pinch zoom. Some touch screens display
// significant amount of wobble when moving a finger in a straight line. This
// makes two finger scroll trigger an oscillating pinch zoom. See
// crbug.com/394380 for details.
const char kCompensateForUnstablePinchZoom[] =
    "compensate-for-unstable-pinch-zoom";

#if defined(OS_LINUX)
// Tells chrome to interpret events from these devices as touch events. Only
// available with XInput 2 (i.e. X server 1.8 or above). The id's of the
// devices can be retrieved from 'xinput list'.
const char kTouchDevices[] = "touch-devices";
#endif

#if defined(USE_XI2_MT) || defined(USE_OZONE)
// The calibration factors given as "<left>,<right>,<top>,<bottom>".
const char kTouchCalibration[] = "touch-calibration";
#endif

}  // namespace switches
