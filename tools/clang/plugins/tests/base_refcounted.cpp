// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base_refcounted.h"

#include <cstddef>

namespace {

// Unsafe; should error.
class AnonymousDerivedProtectedToPublicInImpl
    : public ProtectedRefCountedVirtualDtorInHeader {
 public:
  AnonymousDerivedProtectedToPublicInImpl() {}
  ~AnonymousDerivedProtectedToPublicInImpl() override {}
};

// Unsafe; but we should only warn on the base class.
class AnonymousDerivedProtectedOnDerived
    : public ProtectedRefCountedDtorInHeader {
 protected:
  ~AnonymousDerivedProtectedOnDerived() {}
};

}  // namespace

// Unsafe; should error.
class PublicRefCountedDtorInImpl
    : public base::RefCounted<PublicRefCountedDtorInImpl> {
 public:
  PublicRefCountedDtorInImpl() {}
  ~PublicRefCountedDtorInImpl() {}

 private:
  friend class base::RefCounted<PublicRefCountedDtorInImpl>;
};

class Foo {
 public:
  class BarInterface {
   protected:
    virtual ~BarInterface() {}
  };

  typedef base::RefCounted<BarInterface> RefCountedBar;
  typedef RefCountedBar AnotherTypedef;
};

class Baz {
 public:
  typedef typename Foo::AnotherTypedef MyLocalTypedef;
};

// Unsafe; should error.
class UnsafeTypedefChainInImpl : public Baz::MyLocalTypedef {
 public:
  UnsafeTypedefChainInImpl() {}
  ~UnsafeTypedefChainInImpl() {}
};

int main() {
  PublicRefCountedDtorInHeader bad;
  PublicRefCountedDtorInImpl also_bad;

  ProtectedRefCountedDtorInHeader* even_badder = NULL;
  PrivateRefCountedDtorInHeader* private_ok = NULL;

  DerivedProtectedToPublicInHeader still_bad;
  PublicRefCountedThreadSafeDtorInHeader another_bad_variation;
  AnonymousDerivedProtectedToPublicInImpl and_this_is_bad_too;
  ImplicitDerivedProtectedToPublicInHeader bad_yet_again;
  UnsafeTypedefChainInImpl and_again_this_is_bad;

  WebKitPublicDtorInHeader ignored;
  WebKitDerivedPublicDtorInHeader still_ignored;

  return 0;
}
