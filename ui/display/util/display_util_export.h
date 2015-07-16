// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_DISPLAY_UTIL_DISPLAY_UTIL_EXPORT_H_
#define UI_DISPLAY_UTIL_DISPLAY_UTIL_EXPORT_H_

// Defines DISPLAY_UTIL_EXPORT so that functionality implemented by the
// display_util module can be exported to consumers.

#if defined(COMPONENT_BUILD)

#if defined(WIN32)

#if defined(DISPLAY_UTIL_IMPLEMENTATION)
#define DISPLAY_UTIL_EXPORT __declspec(dllexport)
#else
#define DISPLAY_UTIL_EXPORT __declspec(dllimport)
#endif

#else  // !defined(WIN32)

#if defined(DISPLAY_UTIL_IMPLEMENTATION)
#define DISPLAY_UTIL_EXPORT __attribute__((visibility("default")))
#else
#define DISPLAY_UTIL_EXPORT
#endif

#endif

#else  // !defined(COMPONENT_BUILD)

#define DISPLAY_UTIL_EXPORT

#endif

#endif  // UI_DISPLAY_UTIL_DISPLAY_UTIL_EXPORT_H_
