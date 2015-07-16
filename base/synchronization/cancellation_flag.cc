// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/synchronization/cancellation_flag.h"

#include "base/logging.h"

namespace base {

void CancellationFlag::Set() {
#if !defined(NDEBUG)
  DCHECK_EQ(set_on_, PlatformThread::CurrentId());
#endif
  base::subtle::Release_Store(&flag_, 1);
}

bool CancellationFlag::IsSet() const {
  return base::subtle::Acquire_Load(&flag_) != 0;
}

void CancellationFlag::UnsafeResetForTesting() {
  base::subtle::Release_Store(&flag_, 0);
}

}  // namespace base
