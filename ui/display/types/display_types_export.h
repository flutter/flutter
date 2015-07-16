// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_DISPLAY_DISPLAY_TYPES_EXPORT_H_
#define UI_DISPLAY_DISPLAY_TYPES_EXPORT_H_

// Defines DISPLAY_TYPES_EXPORT so that functionality implemented by the
// DISPLAY_TYPES module can be exported to consumers.

#if defined(COMPONENT_BUILD)

#if defined(WIN32)

#if defined(DISPLAY_TYPES_IMPLEMENTATION)
#define DISPLAY_TYPES_EXPORT __declspec(dllexport)
#else
#define DISPLAY_TYPES_EXPORT __declspec(dllimport)
#endif

#else  // !defined(WIN32)

#if defined(DISPLAY_TYPES_IMPLEMENTATION)
#define DISPLAY_TYPES_EXPORT __attribute__((visibility("default")))
#else
#define DISPLAY_TYPES_EXPORT
#endif

#endif

#else  // !defined(COMPONENT_BUILD)

#define DISPLAY_TYPES_EXPORT

#endif

#endif  // UI_DISPLAY_DISPLAY_TYPES_EXPORT_H_
