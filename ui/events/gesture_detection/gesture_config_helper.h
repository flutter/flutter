// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_GESTURE_DETECTION_GESTURE_CONFIG_HELPER_H_
#define UI_EVENTS_GESTURE_DETECTION_GESTURE_CONFIG_HELPER_H_

#include "ui/events/gesture_detection/gesture_detection_export.h"
#include "ui/events/gesture_detection/gesture_detector.h"
#include "ui/events/gesture_detection/gesture_provider.h"
#include "ui/events/gesture_detection/scale_gesture_detector.h"

namespace ui {

GESTURE_DETECTION_EXPORT GestureProvider::Config
DefaultGestureProviderConfig();

}  // namespace ui

#endif  // UI_EVENTS_GESTURE_DETECTION_GESTURE_CONFIG_HELPER_H_
