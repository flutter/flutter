// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef VIRTUAL_METHODS_H_
#define VIRTUAL_METHODS_H_

// Note: This is not actual windows.h but the stub file in system/windows.h
#include <windows.h>

#define CR_BEGIN_MSG_MAP_EX(theClass) virtual int f() { return 4; }
#define BEGIN_SAFE_MSG_MAP_EX(theClass) virtual int g() { return 4; }

// Should warn about virtual method usage.
class VirtualMethodsInHeaders {
 public:
  // Don't complain about these.
  virtual void MethodIsAbstract() = 0;
  virtual void MethodHasNoArguments();
  virtual void MethodHasEmptyDefaultImpl() {}

  // But complain about this:
  virtual bool ComplainAboutThis() { return true; }

  SYSTEM_INLINE_VIRTUAL
  CR_BEGIN_MSG_MAP_EX(Sub)
  BEGIN_SAFE_MSG_MAP_EX(Sub)
};

// Complain on missing 'virtual' keyword in overrides.
class WarnOnMissingVirtual : public VirtualMethodsInHeaders {
 public:
  void MethodHasNoArguments() override;
};

// Don't complain about things in a 'testing' namespace.
namespace testing {
struct TestStruct {};
}  // namespace testing

class VirtualMethodsInHeadersTesting : public VirtualMethodsInHeaders {
 public:
  // Don't complain about no virtual testing methods.
  void MethodHasNoArguments();

 private:
  testing::TestStruct tester_;
};

#endif  // VIRTUAL_METHODS_H_
