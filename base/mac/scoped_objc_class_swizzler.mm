// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "base/mac/scoped_objc_class_swizzler.h"

#include <string.h>

#include "base/logging.h"

namespace base {
namespace mac {

ScopedObjCClassSwizzler::ScopedObjCClassSwizzler(Class target,
                                                 Class source,
                                                 SEL selector)
    : old_selector_impl_(NULL), new_selector_impl_(NULL) {
  Init(target, source, selector, selector);
}

ScopedObjCClassSwizzler::ScopedObjCClassSwizzler(Class target,
                                                 SEL original,
                                                 SEL alternate)
    : old_selector_impl_(NULL), new_selector_impl_(NULL) {
  Init(target, target, original, alternate);
}

ScopedObjCClassSwizzler::~ScopedObjCClassSwizzler() {
  if (old_selector_impl_ && new_selector_impl_)
    method_exchangeImplementations(old_selector_impl_, new_selector_impl_);
}

IMP ScopedObjCClassSwizzler::GetOriginalImplementation() {
  // Note that while the swizzle is in effect the "new" method is actually
  // pointing to the original implementation, since they have been swapped.
  return method_getImplementation(new_selector_impl_);
}

void ScopedObjCClassSwizzler::Init(Class target,
                                   Class source,
                                   SEL original,
                                   SEL alternate) {
  old_selector_impl_ = class_getInstanceMethod(target, original);
  new_selector_impl_ = class_getInstanceMethod(source, alternate);
  if (!old_selector_impl_ && !new_selector_impl_) {
    // Try class methods.
    old_selector_impl_ = class_getClassMethod(target, original);
    new_selector_impl_ = class_getClassMethod(source, alternate);
  }

  DCHECK(old_selector_impl_);
  DCHECK(new_selector_impl_);
  if (!old_selector_impl_ || !new_selector_impl_)
    return;

  // The argument and return types must match exactly.
  const char* old_types = method_getTypeEncoding(old_selector_impl_);
  const char* new_types = method_getTypeEncoding(new_selector_impl_);
  DCHECK(old_types);
  DCHECK(new_types);
  DCHECK_EQ(0, strcmp(old_types, new_types));
  if (!old_types || !new_types || strcmp(old_types, new_types)) {
    old_selector_impl_ = new_selector_impl_ = NULL;
    return;
  }

  method_exchangeImplementations(old_selector_impl_, new_selector_impl_);
}

}  // namespace mac
}  // namespace base
