// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_COMMON_TIME_H_
#define GPU_COMMAND_BUFFER_COMMON_TIME_H_

#if !defined(__native_client__)

#include "base/time/time.h"

namespace gpu {

inline uint64 MicrosecondsSinceOriginOfTime() {
  return (base::TimeTicks::Now() - base::TimeTicks()).InMicroseconds();
}

} // namespace gpu

#else

namespace gpu {

inline uint64 MicrosecondsSinceOriginOfTime() {
  return 0;
}

} // namespace gpu

#endif  // __native_client__

#endif  // GPU_COMMAND_BUFFER_COMMON_TIME_H_
