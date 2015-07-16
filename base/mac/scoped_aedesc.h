// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_MAC_SCOPED_AEDESC_H_
#define BASE_MAC_SCOPED_AEDESC_H_

#import <CoreServices/CoreServices.h>

#include "base/basictypes.h"

namespace base {
namespace mac {

// The ScopedAEDesc is used to scope AppleEvent descriptors.  On creation,
// it will store a NULL descriptor.  On destruction, it will dispose of the
// descriptor.
//
// This class is parameterized for additional type safety checks.  You can use
// the generic AEDesc type by not providing a template parameter:
//  ScopedAEDesc<> desc;
template <typename AEDescType = AEDesc>
class ScopedAEDesc {
 public:
  ScopedAEDesc() {
    AECreateDesc(typeNull, NULL, 0, &desc_);
  }

  ~ScopedAEDesc() {
    AEDisposeDesc(&desc_);
  }

  // Used for in parameters.
  operator const AEDescType*() {
    return &desc_;
  }

  // Used for out parameters.
  AEDescType* OutPointer() {
    return &desc_;
  }

 private:
  AEDescType desc_;

  DISALLOW_COPY_AND_ASSIGN(ScopedAEDesc);
};

}  // namespace mac
}  // namespace base

#endif  // BASE_MAC_SCOPED_AEDESC_H_
