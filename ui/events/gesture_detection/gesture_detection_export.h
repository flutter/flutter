// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_GESTURE_DETECTION_GESTURE_DETECTION_EXPORT_H_
#define UI_EVENTS_GESTURE_DETECTION_GESTURE_DETECTION_EXPORT_H_

#if defined(COMPONENT_BUILD)
#if defined(WIN32)

#if defined(GESTURE_DETECTION_IMPLEMENTATION)
#define GESTURE_DETECTION_EXPORT __declspec(dllexport)
#else
#define GESTURE_DETECTION_EXPORT __declspec(dllimport)
#endif  // defined(GESTURES_IMPLEMENTATION)

#else  // defined(WIN32)
#if defined(GESTURE_DETECTION_IMPLEMENTATION)
#define GESTURE_DETECTION_EXPORT __attribute__((visibility("default")))
#else
#define GESTURE_DETECTION_EXPORT
#endif
#endif

#else  // defined(COMPONENT_BUILD)
#define GESTURE_DETECTION_EXPORT
#endif

#endif  // UI_EVENTS_GESTURE_DETECTION_GESTURE_DETECTION_EXPORT_H_
