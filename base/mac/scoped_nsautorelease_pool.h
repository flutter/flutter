// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_MAC_SCOPED_NSAUTORELEASE_POOL_H_
#define BASE_MAC_SCOPED_NSAUTORELEASE_POOL_H_

#include "base/base_export.h"
#include "base/basictypes.h"

#if defined(__OBJC__)
@class NSAutoreleasePool;
#else  // __OBJC__
class NSAutoreleasePool;
#endif  // __OBJC__

namespace base {
namespace mac {

// ScopedNSAutoreleasePool allocates an NSAutoreleasePool when instantiated and
// sends it a -drain message when destroyed.  This allows an autorelease pool to
// be maintained in ordinary C++ code without bringing in any direct Objective-C
// dependency.

class BASE_EXPORT ScopedNSAutoreleasePool {
 public:
  ScopedNSAutoreleasePool();
  ~ScopedNSAutoreleasePool();

  // Clear out the pool in case its position on the stack causes it to be
  // alive for long periods of time (such as the entire length of the app).
  // Only use then when you're certain the items currently in the pool are
  // no longer needed.
  void Recycle();
 private:
  NSAutoreleasePool* autorelease_pool_;

 private:
  DISALLOW_COPY_AND_ASSIGN(ScopedNSAutoreleasePool);
};

}  // namespace mac
}  // namespace base

#endif  // BASE_MAC_SCOPED_NSAUTORELEASE_POOL_H_
