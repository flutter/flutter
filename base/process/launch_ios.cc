// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/process/launch.h"

namespace base {

void RaiseProcessToHighPriority() {
  // Impossible on iOS. Do nothing.
}

}  // namespace base
