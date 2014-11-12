// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_VIEWER_CC_SKY_VIEWER_CC_EXPORT_H_
#define SKY_VIEWER_CC_SKY_VIEWER_CC_EXPORT_H_

#if defined(COMPONENT_BUILD)
#if defined(WIN32)

#if defined(SKY_VIEWER_CC_IMPLEMENTATION)
#define SKY_VIEWER_CC_EXPORT __declspec(dllexport)
#else
#define SKY_VIEWER_CC_EXPORT __declspec(dllimport)
#endif  // defined(SKY_VIEWER_CC_IMPLEMENTATION)

#else  // defined(WIN32)
#if defined(SKY_VIEWER_CC_IMPLEMENTATION)
#define SKY_VIEWER_CC_EXPORT __attribute__((visibility("default")))
#else
#define SKY_VIEWER_CC_EXPORT
#endif
#endif

#else  // defined(COMPONENT_BUILD)
#define SKY_VIEWER_CC_EXPORT
#endif

#endif  // SKY_VIEWER_CC_SKY_VIEWER_CC_EXPORT_H_
