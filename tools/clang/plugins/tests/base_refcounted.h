// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_REFCOUNTED_H_
#define BASE_REFCOUNTED_H_

namespace base {

template <typename T>
class RefCounted {
 public:
  RefCounted() {}
 protected:
  ~RefCounted() {}
};

template <typename T>
class RefCountedThreadSafe {
 public:
  RefCountedThreadSafe() {}
 protected:
  ~RefCountedThreadSafe() {}
};

}  // namespace base

// Ignore classes whose inheritance tree ends in WebKit's RefCounted base
// class. Though prone to error, this pattern is very prevalent in WebKit
// code, so do not issue any warnings.
namespace WebKit {

template <typename T>
class RefCounted {
 public:
  RefCounted() {}
  ~RefCounted() {}
};

}  // namespace WebKit

// Unsafe; should error.
class PublicRefCountedDtorInHeader
    : public base::RefCounted<PublicRefCountedDtorInHeader> {
 public:
  PublicRefCountedDtorInHeader() {}
  ~PublicRefCountedDtorInHeader() {}

 private:
  friend class base::RefCounted<PublicRefCountedDtorInHeader>;
};

// Unsafe; should error.
class PublicRefCountedThreadSafeDtorInHeader
    : public base::RefCountedThreadSafe<
          PublicRefCountedThreadSafeDtorInHeader> {
 public:
  PublicRefCountedThreadSafeDtorInHeader() {}
  ~PublicRefCountedThreadSafeDtorInHeader() {}

 private:
  friend class base::RefCountedThreadSafe<
      PublicRefCountedThreadSafeDtorInHeader>;
};

// Unsafe; should error.
class ProtectedRefCountedDtorInHeader
    : public base::RefCounted<ProtectedRefCountedDtorInHeader> {
 public:
  ProtectedRefCountedDtorInHeader() {}

 protected:
  ~ProtectedRefCountedDtorInHeader() {}

 private:
  friend class base::RefCounted<ProtectedRefCountedDtorInHeader>;
};

// Safe; should not have errors
class ProtectedRefCountedVirtualDtorInHeader
    : public base::RefCounted<ProtectedRefCountedVirtualDtorInHeader> {
 public:
  ProtectedRefCountedVirtualDtorInHeader() {}

 protected:
  virtual ~ProtectedRefCountedVirtualDtorInHeader() {}

 private:
  friend class base::RefCounted<ProtectedRefCountedVirtualDtorInHeader>;
};


// Safe; should not have errors.
class PrivateRefCountedDtorInHeader
    : public base::RefCounted<PrivateRefCountedDtorInHeader> {
 public:
  PrivateRefCountedDtorInHeader() {}

 private:
  ~PrivateRefCountedDtorInHeader() {}
  friend class base::RefCounted<PrivateRefCountedDtorInHeader>;
};

// Unsafe; A grandchild class ends up exposing their parent and grandparent's
// destructors.
class DerivedProtectedToPublicInHeader
    : public ProtectedRefCountedVirtualDtorInHeader {
 public:
  DerivedProtectedToPublicInHeader() {}
  ~DerivedProtectedToPublicInHeader() override {}
};

// Unsafe; A grandchild ends up implicitly exposing their parent and
// grantparent's destructors.
class ImplicitDerivedProtectedToPublicInHeader
    : public ProtectedRefCountedVirtualDtorInHeader {
 public:
  ImplicitDerivedProtectedToPublicInHeader() {}
};

// Unsafe-but-ignored; should not have errors.
class WebKitPublicDtorInHeader
    : public WebKit::RefCounted<WebKitPublicDtorInHeader> {
 public:
  WebKitPublicDtorInHeader() {}
  ~WebKitPublicDtorInHeader() {}
};

// Unsafe-but-ignored; should not have errors.
class WebKitDerivedPublicDtorInHeader
    : public WebKitPublicDtorInHeader {
 public:
  WebKitDerivedPublicDtorInHeader() {}
  ~WebKitDerivedPublicDtorInHeader() {}
};

class APublicInterface {
 public:
  virtual ~APublicInterface() {}
  virtual void DoFoo() = 0;
};

// Unsafe. "ImplementsAPublicInterface* foo" can be deleted via
// "delete (APublicInterface*)foo;".
class ImplementsAPublicInterface
    : public APublicInterface,
      public base::RefCounted<ImplementsAPublicInterface> {
 public:
  void DoFoo() override {}

 protected:
  ~ImplementsAPublicInterface() override {}

 private:
  friend class base::RefCounted<ImplementsAPublicInterface>;
};

class AnImplicitInterface {
 public:
  virtual void DoBar() {}
};

// Unsafe.
class ImplementsAnImplicitInterface
    : public AnImplicitInterface,
      public base::RefCounted<ImplementsAnImplicitInterface> {
 public:
  void DoBar() override {}

 private:
  friend class base::RefCounted<ImplementsAnImplicitInterface>;
  ~ImplementsAnImplicitInterface() {}
};

// Safe. Private inheritance does not expose the base destructor.
class PrivatelyImplementsAPublicInterface
    : private APublicInterface,
      public base::RefCounted<PrivatelyImplementsAPublicInterface> {
 public:
  void DoFoo() override {}

 private:
  friend class base::RefCounted<PrivatelyImplementsAPublicInterface>;
  ~PrivatelyImplementsAPublicInterface() override {}
};

// Unsafe.
class BaseInterface {
 public:
  virtual ~BaseInterface() {}
  virtual void DoFoo() {}
};
class DerivedInterface : public BaseInterface {
 protected:
  ~DerivedInterface() override {}
};
class SomeOtherInterface {
 public:
  virtual ~SomeOtherInterface() {}
  virtual void DoBar() {}
};
class RefcountedType : public base::RefCounted<RefcountedType> {
 protected:
  ~RefcountedType() {}
 private:
  friend class base::RefCounted<RefcountedType>;
};
class UnsafeInheritanceChain
    : public DerivedInterface,
      public SomeOtherInterface,
      public RefcountedType {
 public:
  // DerivedInterface
  void DoFoo() override {}

  // SomeOtherInterface
  void DoBar() override {}

 protected:
  ~UnsafeInheritanceChain() override {}
};

#endif  // BASE_REFCOUNTED_H_
