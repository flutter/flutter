// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/platform/darwin/scoped_nsobject.h"

namespace fml {

namespace internal {

id ScopedNSProtocolTraitsRetain(id obj) {
  return [obj retain];
}

id ScopedNSProtocolTraitsAutoRelease(id obj) {
  return [obj autorelease];
}

void ScopedNSProtocolTraitsRelease(id obj) {
  return [obj release];
}

}  // namespace internal
}  // namespace fml
