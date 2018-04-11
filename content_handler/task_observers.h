// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "lib/fxl/functional/closure.h"

namespace flutter {

void CurrentMessageLoopAddAfterTaskObserver(intptr_t key,
                                            fxl::Closure observer);

void CurrentMessageLoopRemoveAfterTaskObserver(intptr_t key);

}  // namespace flutter
