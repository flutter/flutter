// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "virtual_bodies.h"

// Shouldn't warn about method usage in the implementation file.
class VirtualMethodsInImplementation {
 public:
  virtual void MethodIsAbstract() = 0;
  virtual void MethodHasNoArguments();
  virtual void MethodHasEmptyDefaultImpl() {}
  virtual bool ComplainAboutThis() { return true; }
};

// Stubs to fill in the abstract method
class ConcreteVirtualMethodsInHeaders : public VirtualMethodsInHeaders {
 public:
  void MethodIsAbstract() override {}
};

class ConcreteVirtualMethodsInImplementation
    : public VirtualMethodsInImplementation {
 public:
  void MethodIsAbstract() override {}
};

// Fill in the implementations
void VirtualMethodsInHeaders::MethodHasNoArguments() {
}
void WarnOnMissingVirtual::MethodHasNoArguments() {
}
void VirtualMethodsInImplementation::MethodHasNoArguments() {
}

int main() {
  ConcreteVirtualMethodsInHeaders one;
  ConcreteVirtualMethodsInImplementation two;
}
