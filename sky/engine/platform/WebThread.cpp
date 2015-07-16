// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/public/platform/WebThread.h"

#include "sky/engine/wtf/Assertions.h"

#include <unistd.h>

namespace {
COMPILE_ASSERT(sizeof(blink::PlatformThreadId) >= sizeof(pid_t), Size_of_platform_thread_id_is_too_small);
}
