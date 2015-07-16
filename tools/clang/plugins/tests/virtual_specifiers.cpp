// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Tests for chromium style checks for virtual/override/final specifiers on
// virtual methods.

// Note: This is not actual windows.h but the stub file in system/windows.h
#include <windows.h>

// Purposely use macros to test that the FixIt hints don't try to remove the
// macro body.
#define OVERRIDE override
#define FINAL final

// Base class can only use virtual.
class Base {
 public:
  virtual ~Base() {}
  virtual void F() = 0;
};

// Derived classes correctly use only override or final specifier.
class CorrectOverride : public Base {
 public:
  ~CorrectOverride() OVERRIDE {}
  void F() OVERRIDE {}
};

class CorrectFinal : public CorrectOverride {
 public:
  ~CorrectFinal() FINAL {}
  void F() FINAL {}
};

// No override on an overridden method should trigger a diagnostic.
class MissingOverride : public Base {
 public:
  ~MissingOverride() {}
  void F() {}
};

// Redundant specifiers should trigger a diagnostic.
class VirtualAndOverride : public Base {
 public:
  virtual ~VirtualAndOverride() OVERRIDE {}
  virtual void F() OVERRIDE {}
};

class VirtualAndFinal : public Base {
 public:
  virtual ~VirtualAndFinal() FINAL {}
  virtual void F() FINAL {}
};

class VirtualAndOverrideFinal : public Base {
 public:
  virtual ~VirtualAndOverrideFinal() OVERRIDE FINAL {}
  virtual void F() OVERRIDE FINAL {}
};

class OverrideAndFinal : public Base {
 public:
  ~OverrideAndFinal() OVERRIDE FINAL {}
  void F() OVERRIDE FINAL {}
};

// Also warn on pure functions.
class CorrectPureVirtual : public Base {
  virtual void F() = 0;
};

class Pure : public Base {
  void F() = 0;
};

class PureOverride : public Base {
  void F() override = 0;
};

class PureVirtualOverride : public Base {
  virtual void F() override = 0;
};

// Test that the redundant virtual warning is suppressed when the virtual
// keyword comes from a macro in a system header.
class COMIsAwesome : public Base {
  STDMETHOD(F)() override = 0;
};

// Some tests that overrides in the testing namespace
// don't trigger warnings, except for testing::Test.
namespace testing {

class Test {
 public:
  virtual ~Test();
  virtual void SetUp();
};

class NotTest {
 public:
  virtual ~NotTest();
  virtual void SetUp();
};

}  // namespace

class MyTest : public testing::Test {
 public:
  virtual ~MyTest();
  virtual void SetUp() override;
};

class MyNotTest : public testing::NotTest {
 public:
  virtual ~MyNotTest();
  virtual void SetUp() override;
};

class MacroBase {
 public:
  virtual void AddRef() = 0;
  virtual void Virtual() {}
};

class Sub : public MacroBase {
  // Shouldn't warn.
  END_COM_MAP()
  SYSTEM_REDUNDANT1;
  SYSTEM_REDUNDANT2;
};
