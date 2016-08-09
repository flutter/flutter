// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TOOLS_CLANG_PLUGINS_TESTS_SYSTEM_WINDOWS_H_
#define TOOLS_CLANG_PLUGINS_TESTS_SYSTEM_WINDOWS_H_

#define STDMETHOD(x) virtual void x

#define END_COM_MAP() virtual void AddRef() = 0;

#define SYSTEM_REDUNDANT1 virtual void NonVirtualFinal() final
#define SYSTEM_REDUNDANT2 virtual void Virtual() override final

#define SYSTEM_INLINE_VIRTUAL virtual int Foo() { return 4; }

#endif  // TOOLS_CLANG_PLUGINS_TESTS_SYSTEM_WINDOWS_H_
