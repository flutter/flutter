// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_MAC_SCOPED_OBJC_CLASS_SWIZZLER_H_
#define BASE_MAC_SCOPED_OBJC_CLASS_SWIZZLER_H_

#import <objc/runtime.h>

#include "base/base_export.h"
#include "base/macros.h"

namespace base {
namespace mac {

// Within a given scope, swaps method implementations of a class interface, or
// between two class interfaces. The argument and return types must match.
class BASE_EXPORT ScopedObjCClassSwizzler {
 public:
  // Given two classes that each respond to |selector|, swap the implementations
  // of those methods.
  ScopedObjCClassSwizzler(Class target, Class source, SEL selector);

  // Given two selectors on the same class interface, |target| (e.g. via
  // inheritance or categories), swap the implementations of methods |original|
  // and |alternate|.
  ScopedObjCClassSwizzler(Class target, SEL original, SEL alternate);

  ~ScopedObjCClassSwizzler();

  // Return a callable function pointer for the replaced method. To call this
  // from the replacing function, the first two arguments should be |self| and
  // |_cmd|. These are followed by the (variadic) method arguments.
  IMP GetOriginalImplementation();

 private:
  // Delegated constructor.
  void Init(Class target, Class source, SEL original, SEL alternate);

  Method old_selector_impl_;
  Method new_selector_impl_;

  DISALLOW_COPY_AND_ASSIGN(ScopedObjCClassSwizzler);
};

}  // namespace mac
}  // namespace base

#endif  // BASE_MAC_SCOPED_OBJC_CLASS_SWIZZLER_H_
