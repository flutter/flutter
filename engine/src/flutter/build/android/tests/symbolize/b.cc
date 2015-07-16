// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class B {
 public:
  B();
  void Baz(float f);
  void Qux(double d);
};

B::B() {}
void B::Baz(float f) {}
void B::Qux(double d) {}
