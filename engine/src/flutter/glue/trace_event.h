// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#if defined(__Fuchsia__)
#define TRACE_EVENT0(a, b)
#define TRACE_EVENT1(a, b, c, d)
#define TRACE_EVENT2(a, b, c, d, e, f)
#define TRACE_EVENT_ASYNC_BEGIN0(a, b, c)
#define TRACE_EVENT_ASYNC_END0(a, b, c)
#define TRACE_EVENT_ASYNC_BEGIN1(a, b, c, d, e)
#define TRACE_EVENT_ASYNC_END1(a, b, c, d, e)
#else
#include "base/trace_event/trace_event.h"
#endif  // defined(__Fuchsia__)
