// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file implements the functions declared in
// //mojo/edk/platform/time_ticks.h.

#include "mojo/edk/platform/time_ticks.h"

#include "base/time/time.h"

namespace mojo {
namespace platform {

MojoTimeTicks GetTimeTicks() {
  return base::TimeTicks::Now().ToInternalValue();
}

}  // namespace platform
}  // namespace mojo
