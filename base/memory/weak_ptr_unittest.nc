// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/memory/weak_ptr.h"

namespace base {

struct Producer : SupportsWeakPtr<Producer> {};
struct DerivedProducer : Producer {};
struct OtherDerivedProducer : Producer {};
struct MultiplyDerivedProducer : Producer,
                                 SupportsWeakPtr<MultiplyDerivedProducer> {};
struct Unrelated {};
struct DerivedUnrelated : Unrelated {};

#if defined(NCTEST_AUTO_DOWNCAST)  // [r"fatal error: cannot initialize a member subobject of type 'base::DerivedProducer \*' with an lvalue of type 'base::Producer \*const'"]

void WontCompile() {
  Producer f;
  WeakPtr<Producer> ptr = f.AsWeakPtr();
  WeakPtr<DerivedProducer> derived_ptr = ptr;
}

#elif defined(NCTEST_STATIC_DOWNCAST)  // [r"fatal error: cannot initialize a member subobject of type 'base::DerivedProducer \*' with an lvalue of type 'base::Producer \*const'"]

void WontCompile() {
  Producer f;
  WeakPtr<Producer> ptr = f.AsWeakPtr();
  WeakPtr<DerivedProducer> derived_ptr =
      static_cast<WeakPtr<DerivedProducer> >(ptr);
}

#elif defined(NCTEST_AUTO_REF_DOWNCAST)  // [r"fatal error: non-const lvalue reference to type 'WeakPtr<base::DerivedProducer>' cannot bind to a value of unrelated type 'WeakPtr<base::Producer>'"]

void WontCompile() {
  Producer f;
  WeakPtr<Producer> ptr = f.AsWeakPtr();
  WeakPtr<DerivedProducer>& derived_ptr = ptr;
}

#elif defined(NCTEST_STATIC_REF_DOWNCAST)  // [r"fatal error: non-const lvalue reference to type 'WeakPtr<base::DerivedProducer>' cannot bind to a value of unrelated type 'WeakPtr<base::Producer>'"]

void WontCompile() {
  Producer f;
  WeakPtr<Producer> ptr = f.AsWeakPtr();
  WeakPtr<DerivedProducer>& derived_ptr =
      static_cast<WeakPtr<DerivedProducer>&>(ptr);
}

#elif defined(NCTEST_STATIC_ASWEAKPTR_DOWNCAST)  // [r"no matching function"]

void WontCompile() {
  Producer f;
  WeakPtr<DerivedProducer> ptr =
      SupportsWeakPtr<Producer>::StaticAsWeakPtr<DerivedProducer>(&f);
}

#elif defined(NCTEST_UNSAFE_HELPER_DOWNCAST)  // [r"fatal error: cannot initialize a member subobject of type 'base::DerivedProducer \*' with an lvalue of type 'base::Producer \*const'"]

void WontCompile() {
  Producer f;
  WeakPtr<DerivedProducer> ptr = AsWeakPtr(&f);
}

#elif defined(NCTEST_UNSAFE_INSTANTIATED_HELPER_DOWNCAST)  // [r"no matching function"]

void WontCompile() {
  Producer f;
  WeakPtr<DerivedProducer> ptr = AsWeakPtr<DerivedProducer>(&f);
}

#elif defined(NCTEST_UNSAFE_WRONG_INSANTIATED_HELPER_DOWNCAST)  // [r"fatal error: cannot initialize a member subobject of type 'base::DerivedProducer \*' with an lvalue of type 'base::Producer \*const'"]

void WontCompile() {
  Producer f; 
  WeakPtr<DerivedProducer> ptr = AsWeakPtr<Producer>(&f);
}

#elif defined(NCTEST_UNSAFE_HELPER_CAST)  // [r"fatal error: cannot initialize a member subobject of type 'base::OtherDerivedProducer \*' with an lvalue of type 'base::DerivedProducer \*const'"]

void WontCompile() {
  DerivedProducer f;
  WeakPtr<OtherDerivedProducer> ptr = AsWeakPtr(&f);
}

#elif defined(NCTEST_UNSAFE_INSTANTIATED_HELPER_SIDECAST)  // [r"fatal error: no matching function for call to 'AsWeakPtr'"]

void WontCompile() {
  DerivedProducer f;
  WeakPtr<OtherDerivedProducer> ptr = AsWeakPtr<OtherDerivedProducer>(&f);
}

#elif defined(NCTEST_UNSAFE_WRONG_INSTANTIATED_HELPER_SIDECAST)  // [r"fatal error: cannot initialize a member subobject of type 'base::OtherDerivedProducer \*' with an lvalue of type 'base::DerivedProducer \*const'"]

void WontCompile() {
  DerivedProducer f;
  WeakPtr<OtherDerivedProducer> ptr = AsWeakPtr<DerivedProducer>(&f);
}

#elif defined(NCTEST_UNRELATED_HELPER)  // [r"fatal error: cannot initialize a member subobject of type 'base::Unrelated \*' with an lvalue of type 'base::DerivedProducer \*const'"]

void WontCompile() {
  DerivedProducer f;
  WeakPtr<Unrelated> ptr = AsWeakPtr(&f);
}

#elif defined(NCTEST_UNRELATED_INSTANTIATED_HELPER)  // [r"no matching function"]

void WontCompile() {
  DerivedProducer f;
  WeakPtr<Unrelated> ptr = AsWeakPtr<Unrelated>(&f);
}

#elif defined(NCTEST_COMPLETELY_UNRELATED_HELPER)  // [r"fatal error: static_assert failed \"AsWeakPtr_argument_inherits_from_SupportsWeakPtr\""]

void WontCompile() {
  Unrelated f;
  WeakPtr<Unrelated> ptr = AsWeakPtr(&f);
}

#elif defined(NCTEST_DERIVED_COMPLETELY_UNRELATED_HELPER)  // [r"fatal error: static_assert failed \"AsWeakPtr_argument_inherits_from_SupportsWeakPtr\""]

void WontCompile() {
  DerivedUnrelated f;
  WeakPtr<Unrelated> ptr = AsWeakPtr(&f);
}

#elif defined(NCTEST_AMBIGUOUS_ANCESTORS)  // [r"fatal error: ambiguous conversion from derived class 'base::MultiplyDerivedProducer' to base class 'base::internal::SupportsWeakPtrBase':"]

void WontCompile() {
  MultiplyDerivedProducer f;
  WeakPtr<MultiplyDerivedProducer> ptr = AsWeakPtr(&f);
}

#endif

}
