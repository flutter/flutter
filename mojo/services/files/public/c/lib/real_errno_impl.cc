// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "files/public/c/lib/real_errno_impl.h"

#include <errno.h>

namespace mojio {

int RealErrnoImpl::Get() const {
  return errno;
}

void RealErrnoImpl::Set(int error) {
  errno = error;
}

}  // namespace mojio
