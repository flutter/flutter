// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <cstdlib>
#include "platform_utils.h"

namespace tonic {

void PlatformExit(int status) {
  exit(status);
}

}  // namespace tonic
