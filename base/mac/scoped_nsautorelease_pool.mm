// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/mac/scoped_nsautorelease_pool.h"

#import <Foundation/Foundation.h>

#include "base/logging.h"

namespace base {
namespace mac {

ScopedNSAutoreleasePool::ScopedNSAutoreleasePool()
    : autorelease_pool_([[NSAutoreleasePool alloc] init]) {
  DCHECK(autorelease_pool_);
}

ScopedNSAutoreleasePool::~ScopedNSAutoreleasePool() {
  [autorelease_pool_ drain];
}

// Cycle the internal pool, allowing everything there to get cleaned up and
// start anew.
void ScopedNSAutoreleasePool::Recycle() {
  [autorelease_pool_ drain];
  autorelease_pool_ = [[NSAutoreleasePool alloc] init];
  DCHECK(autorelease_pool_);
}

}  // namespace mac
}  // namespace base
