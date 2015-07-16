// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_MAC_SCOPED_CFTYPEREF_H_
#define BASE_MAC_SCOPED_CFTYPEREF_H_

#include <CoreFoundation/CoreFoundation.h>

#include "base/mac/scoped_typeref.h"

namespace base {

// ScopedCFTypeRef<> is patterned after scoped_ptr<>, but maintains ownership
// of a CoreFoundation object: any object that can be represented as a
// CFTypeRef.  Style deviations here are solely for compatibility with
// scoped_ptr<>'s interface, with which everyone is already familiar.
//
// By default, ScopedCFTypeRef<> takes ownership of an object (in the
// constructor or in reset()) by taking over the caller's existing ownership
// claim.  The caller must own the object it gives to ScopedCFTypeRef<>, and
// relinquishes an ownership claim to that object.  ScopedCFTypeRef<> does not
// call CFRetain(). This behavior is parameterized by the |OwnershipPolicy|
// enum. If the value |RETAIN| is passed (in the constructor or in reset()),
// then ScopedCFTypeRef<> will call CFRetain() on the object, and the initial
// ownership is not changed.

namespace internal {

struct ScopedCFTypeRefTraits {
  static void Retain(CFTypeRef object) {
    CFRetain(object);
  }
  static void Release(CFTypeRef object) {
    CFRelease(object);
  }
};

}  // namespace internal

template<typename CFT>
class ScopedCFTypeRef
    : public ScopedTypeRef<CFT, internal::ScopedCFTypeRefTraits> {
 public:
  typedef CFT element_type;

  explicit ScopedCFTypeRef(
      CFT object = NULL,
      base::scoped_policy::OwnershipPolicy policy = base::scoped_policy::ASSUME)
      : ScopedTypeRef<CFT,
                      internal::ScopedCFTypeRefTraits>(object, policy) {}

  ScopedCFTypeRef(const ScopedCFTypeRef<CFT>& that)
      : ScopedTypeRef<CFT, internal::ScopedCFTypeRefTraits>(that) {}
};

}  // namespace base

#endif  // BASE_MAC_SCOPED_CFTYPEREF_H_
