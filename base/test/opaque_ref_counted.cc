// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/opaque_ref_counted.h"

#include "base/macros.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

class OpaqueRefCounted : public RefCounted<OpaqueRefCounted> {
 public:
  OpaqueRefCounted() {}

  int Return42() { return 42; }

 private:
  virtual ~OpaqueRefCounted() {}

  friend RefCounted<OpaqueRefCounted>;
  DISALLOW_COPY_AND_ASSIGN(OpaqueRefCounted);
};

scoped_refptr<OpaqueRefCounted> MakeOpaqueRefCounted() {
  return new OpaqueRefCounted();
}

void TestOpaqueRefCounted(scoped_refptr<OpaqueRefCounted> p) {
  EXPECT_EQ(42, p->Return42());
}

}  // namespace base

template class scoped_refptr<base::OpaqueRefCounted>;
