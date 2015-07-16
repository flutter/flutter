// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_EVENT_TYPES_H_
#define BASE_EVENT_TYPES_H_

#include "build/build_config.h"

#if defined(OS_WIN)
#include <windows.h>
#elif defined(USE_X11)
typedef union _XEvent XEvent;
#elif defined(OS_MACOSX)
#if defined(__OBJC__)
@class NSEvent;
#else  // __OBJC__
class NSEvent;
#endif // __OBJC__
#endif

namespace base {

// Cross platform typedefs for native event types.
#if defined(OS_WIN)
typedef MSG NativeEvent;
#elif defined(USE_X11)
typedef XEvent* NativeEvent;
#elif defined(OS_MACOSX)
typedef NSEvent* NativeEvent;
#else
typedef void* NativeEvent;
#endif

} // namespace base

#endif  // BASE_EVENT_TYPES_H_
