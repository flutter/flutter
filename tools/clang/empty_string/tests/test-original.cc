// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Test file for the empty string clang tool.

#include <string>

// Tests for std::string declarations.
void TestDeclarations() { std::string a(""), b("abc"), c(""); }

// Tests for std::string allocated with new.
void TestNew() {
  std::string* a = new std::string(""),
              *b = new std::string("abc"),
              *c = new std::string(""),
              *d = new std::string();
}

// Tests for std::string construction in initializer lists.
class TestInitializers {
 public:
  TestInitializers() : a("") {}
  TestInitializers(bool) : a(""), b("") {}
  TestInitializers(double) : a(""), b("cat"), c() {}

 private:
  std::string a;
  std::string b;
  std::string c;
};

// Tests for temporary std::strings.
void TestTemporaries(const std::string& reference_argument,
                     const std::string value_argument) {
  TestTemporaries("", "");
  TestTemporaries(std::string(""), std::string(""));
}

// Tests for temporary std::wstrings.
void TestWideTemporaries(const std::wstring& reference_argument,
                         const std::wstring value_argument) {
  TestWideTemporaries(L"", L"");
  TestWideTemporaries(std::wstring(L""), std::wstring(L""));
}

