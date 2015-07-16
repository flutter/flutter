// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class A {
 public:
  A();
  void Foo(int i);
  void Bar(const char* c);
};

A::A() {}
void A::Foo(int i) {}
void A::Bar(const char* c) {}
