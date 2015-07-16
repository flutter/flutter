// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MISSING_CTOR_H_
#define MISSING_CTOR_H_

struct MyString {
  MyString();
  MyString(const MyString&);
  MyString(MyString&&);
};

template <class T>
struct MyVector {
  MyVector();
  MyVector(const MyVector&);
  MyVector(MyVector&&);
};

// For now, this should only warn on the missing constructor, not on the missing
// copy and move constructors on dllexported classes.
class __declspec(dllexport) MissingCtorsArentOKInHeader {
 public:

 private:
  MyVector<int> one_;
  MyVector<MyString> two_;
};

class __declspec(dllexport) InlineImplicitMoveCtorOK {
 public:
  InlineImplicitMoveCtorOK();

 private:
  // ctor weight = 12, dtor weight = 9.
  MyString one_;
  MyString two_;
  MyString three_;
  int four_;
  int five_;
  int six_;
};

class __declspec(dllexport) ExplicitlyDefaultedInlineAlsoWarns {
 public:
  ExplicitlyDefaultedInlineAlsoWarns() = default;
  ~ExplicitlyDefaultedInlineAlsoWarns() = default;
  ExplicitlyDefaultedInlineAlsoWarns(
      const ExplicitlyDefaultedInlineAlsoWarns&) = default;
  ExplicitlyDefaultedInlineAlsoWarns(ExplicitlyDefaultedInlineAlsoWarns&&) =
      default;

 private:
  MyVector<int> one_;
  MyVector<MyString> two_;

};

#endif  // MISSING_CTOR_H_
