// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TEST_OPAQUE_REF_COUNTED_H_
#define BASE_TEST_OPAQUE_REF_COUNTED_H_

#include "base/memory/ref_counted.h"

namespace base {

// OpaqueRefCounted is a test class for scoped_refptr to ensure it still works
// when the pointed-to type is opaque (i.e., incomplete).
class OpaqueRefCounted;

// Test functions that return and accept scoped_refptr<OpaqueRefCounted> values.
scoped_refptr<OpaqueRefCounted> MakeOpaqueRefCounted();
void TestOpaqueRefCounted(scoped_refptr<OpaqueRefCounted> p);

}  // namespace base

extern template class scoped_refptr<base::OpaqueRefCounted>;

#endif  // BASE_TEST_OPAQUE_REF_COUNTED_H_
