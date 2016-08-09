// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define VIRTUAL virtual
#define VIRTUAL_VOID virtual void

class A {
 public:
  VIRTUAL void F() final {}
  // Make sure an out-of-place virtual doesn't cause an incorrect fixit removal
  // to be emitted.
  void VIRTUAL G() final {}
  // Make sure a fixit removal isn't generated for macros that expand to more
  // than just 'virtual'.
  VIRTUAL_VOID H() final {}
};
