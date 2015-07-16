// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "scoped_refptr.h"

struct Foo {
  int dummy;
};

struct HasAScopedRefptr {
  scoped_refptr<Foo> member;

  const scoped_refptr<Foo>& GetMemberAsScopedRefptr() const { return member; }

  Foo* GetMemberAsRawPtr() const { return member; }
};

void ExpectsRawPtr(Foo* param) {
  Foo* temp = param;
}

void ExpectsScopedRefptr(const scoped_refptr<Foo>& param) {
  Foo* temp = param.get();
}

void CallsRawWithMemberScopedRefptr() {
  HasAScopedRefptr object;
  ExpectsRawPtr(object.GetMemberAsScopedRefptr());
}

void CallsRawWithMemberRawPtr() {
  HasAScopedRefptr object;
  ExpectsRawPtr(object.GetMemberAsRawPtr());
}

void CallsScopedWithMemberScopedRefptr() {
  HasAScopedRefptr object;
  ExpectsScopedRefptr(object.GetMemberAsScopedRefptr());
}

void CallsScopedWithMemberRawPtr() {
  HasAScopedRefptr object;
  ExpectsScopedRefptr(object.GetMemberAsScopedRefptr());
}
