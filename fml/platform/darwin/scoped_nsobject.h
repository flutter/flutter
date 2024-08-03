// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_PLATFORM_DARWIN_SCOPED_NSOBJECT_H_
#define FLUTTER_FML_PLATFORM_DARWIN_SCOPED_NSOBJECT_H_

#include <type_traits>
#include <utility>

// Include NSObject.h directly because Foundation.h pulls in many dependencies.
// (Approx 100k lines of code versus 1.5k for NSObject.h). scoped_nsobject gets
// singled out because it is most typically included from other header files.
#import <Foundation/NSObject.h>

#include "flutter/fml/macros.h"
#include "flutter/fml/platform/darwin/scoped_typeref.h"

#if !defined(__has_feature) || !__has_feature(objc_arc)
@class NSAutoreleasePool;
#endif

namespace fml {

// scoped_nsobject<> is patterned after scoped_ptr<>, but maintains ownership
// of an NSObject subclass object.  Style deviations here are solely for
// compatibility with scoped_ptr<>'s interface, with which everyone is already
// familiar.
//
// scoped_nsobject<> takes ownership of an object (in the constructor or in
// reset()) by taking over the caller's existing ownership claim.  The caller
// must own the object it gives to scoped_nsobject<>, and relinquishes an
// ownership claim to that object.  scoped_nsobject<> does not call -retain,
// callers have to call this manually if appropriate.
//
// scoped_nsprotocol<> has the same behavior as scoped_nsobject, but can be used
// with protocols.
//
// scoped_nsobject<> is not to be used for NSAutoreleasePools. For
// NSAutoreleasePools use ScopedNSAutoreleasePool from
// scoped_nsautorelease_pool.h instead.
// We check for bad uses of scoped_nsobject and NSAutoreleasePool at compile
// time with a template specialization (see below).
//
// If Automatic Reference Counting (aka ARC) is enabled then the ownership
// policy is not controllable by the user as ARC make it really difficult to
// transfer ownership (the reference passed to scoped_nsobject constructor is
// sunk by ARC and __attribute((ns_consumed)) appears to not work correctly
// with Objective-C++ see https://llvm.org/bugs/show_bug.cgi?id=27887). Due to
// that, the policy is always to |RETAIN| when using ARC.

namespace internal {

id ScopedNSProtocolTraitsRetain(__unsafe_unretained id obj)
    __attribute((ns_returns_not_retained));
id ScopedNSProtocolTraitsAutoRelease(__unsafe_unretained id obj)
    __attribute((ns_returns_not_retained));
void ScopedNSProtocolTraitsRelease(__unsafe_unretained id obj);

// Traits for ScopedTypeRef<>. As this class may be compiled from file with
// Automatic Reference Counting enable or not all methods have annotation to
// enforce the same code generation in both case (in particular, the Retain
// method uses ns_returns_not_retained to prevent ARC to insert a -release
// call on the returned value and thus defeating the -retain).
template <typename NST>
struct ScopedNSProtocolTraits {
  static NST InvalidValue() __attribute((ns_returns_not_retained)) {
    return nil;
  }
  static NST Retain(__unsafe_unretained NST nst)
      __attribute((ns_returns_not_retained)) {
    return ScopedNSProtocolTraitsRetain(nst);
  }
  static void Release(__unsafe_unretained NST nst) {
    ScopedNSProtocolTraitsRelease(nst);
  }
};

}  // namespace internal

template <typename NST>
class scoped_nsprotocol
    : public ScopedTypeRef<NST, internal::ScopedNSProtocolTraits<NST>> {
 public:
  using Traits = internal::ScopedNSProtocolTraits<NST>;

#if !defined(__has_feature) || !__has_feature(objc_arc)
  explicit scoped_nsprotocol(NST object = Traits::InvalidValue(),
                             scoped_policy::OwnershipPolicy policy =
                                 scoped_policy::OwnershipPolicy::kAssume)
      : ScopedTypeRef<NST, Traits>(object, policy) {}
#else
  explicit scoped_nsprotocol(NST object = Traits::InvalidValue())
      : ScopedTypeRef<NST, Traits>(object,
                                   scoped_policy::OwnershipPolicy::kRetain) {}
#endif

  // NOLINTNEXTLINE(google-explicit-constructor)
  scoped_nsprotocol(const scoped_nsprotocol<NST>& that)
      : ScopedTypeRef<NST, Traits>(that) {}

  template <typename NSR>
  explicit scoped_nsprotocol(const scoped_nsprotocol<NSR>& that_as_subclass)
      : ScopedTypeRef<NST, Traits>(that_as_subclass) {}

  // NOLINTNEXTLINE(google-explicit-constructor)
  scoped_nsprotocol(scoped_nsprotocol<NST>&& that)
      : ScopedTypeRef<NST, Traits>(std::move(that)) {}

  scoped_nsprotocol& operator=(const scoped_nsprotocol<NST>& that) {
    ScopedTypeRef<NST, Traits>::operator=(that);
    return *this;
  }

#if !defined(__has_feature) || !__has_feature(objc_arc)
  void reset(NST object = Traits::InvalidValue(),
             scoped_policy::OwnershipPolicy policy =
                 scoped_policy::OwnershipPolicy::kAssume) {
    ScopedTypeRef<NST, Traits>::reset(object, policy);
  }
#else
  void reset(NST object = Traits::InvalidValue()) {
    ScopedTypeRef<NST, Traits>::reset(object,
                                      scoped_policy::OwnershipPolicy::kRetain);
  }
#endif

  // Shift reference to the autorelease pool to be released later.
  NST autorelease() __attribute((ns_returns_not_retained)) {
    return internal::ScopedNSProtocolTraitsAutoRelease(this->release());
  }
};

// Free functions
template <class C>
void swap(scoped_nsprotocol<C>& p1, scoped_nsprotocol<C>& p2) {
  p1.swap(p2);
}

template <class C>
bool operator==(C p1, const scoped_nsprotocol<C>& p2) {
  return p1 == p2.get();
}

template <class C>
bool operator!=(C p1, const scoped_nsprotocol<C>& p2) {
  return p1 != p2.get();
}

template <typename NST>
class scoped_nsobject : public scoped_nsprotocol<NST*> {
 public:
  using Traits = typename scoped_nsprotocol<NST*>::Traits;

#if !defined(__has_feature) || !__has_feature(objc_arc)
  explicit scoped_nsobject(NST* object = Traits::InvalidValue(),
                           scoped_policy::OwnershipPolicy policy =
                               scoped_policy::OwnershipPolicy::kAssume)
      : scoped_nsprotocol<NST*>(object, policy) {}
#else
  explicit scoped_nsobject(NST* object = Traits::InvalidValue())
      : scoped_nsprotocol<NST*>(object) {}
#endif

  // NOLINTNEXTLINE(google-explicit-constructor)
  scoped_nsobject(const scoped_nsobject<NST>& that)
      : scoped_nsprotocol<NST*>(that) {}

  template <typename NSR>
  explicit scoped_nsobject(const scoped_nsobject<NSR>& that_as_subclass)
      : scoped_nsprotocol<NST*>(that_as_subclass) {}

  // NOLINTNEXTLINE(google-explicit-constructor)
  scoped_nsobject(scoped_nsobject<NST>&& that)
      : scoped_nsprotocol<NST*>(std::move(that)) {}

  scoped_nsobject& operator=(const scoped_nsobject<NST>& that) {
    scoped_nsprotocol<NST*>::operator=(that);
    return *this;
  }

#if !defined(__has_feature) || !__has_feature(objc_arc)
  void reset(NST* object = Traits::InvalidValue(),
             scoped_policy::OwnershipPolicy policy =
                 scoped_policy::OwnershipPolicy::kAssume) {
    scoped_nsprotocol<NST*>::reset(object, policy);
  }
#else
  void reset(NST* object = Traits::InvalidValue()) {
    scoped_nsprotocol<NST*>::reset(object);
  }
#endif

#if !defined(__has_feature) || !__has_feature(objc_arc)
  static_assert(std::is_same<NST, NSAutoreleasePool>::value == false,
                "Use ScopedNSAutoreleasePool instead");
#endif
};

// Specialization to make scoped_nsobject<id> work.
template <>
class scoped_nsobject<id> : public scoped_nsprotocol<id> {
 public:
  using Traits = typename scoped_nsprotocol<id>::Traits;

#if !defined(__has_feature) || !__has_feature(objc_arc)
  explicit scoped_nsobject(id object = Traits::InvalidValue(),
                           scoped_policy::OwnershipPolicy policy =
                               scoped_policy::OwnershipPolicy::kAssume)
      : scoped_nsprotocol<id>(object, policy) {}
#else
  explicit scoped_nsobject(id object = Traits::InvalidValue())
      : scoped_nsprotocol<id>(object) {}
#endif

  // NOLINTNEXTLINE(google-explicit-constructor)
  scoped_nsobject(const scoped_nsobject<id>& that)
      : scoped_nsprotocol<id>(that) {}

  template <typename NSR>
  explicit scoped_nsobject(const scoped_nsobject<NSR>& that_as_subclass)
      : scoped_nsprotocol<id>(that_as_subclass) {}

  // NOLINTNEXTLINE(google-explicit-constructor)
  scoped_nsobject(scoped_nsobject<id>&& that)
      : scoped_nsprotocol<id>(std::move(that)) {}

  scoped_nsobject& operator=(const scoped_nsobject<id>& that) {
    scoped_nsprotocol<id>::operator=(that);
    return *this;
  }

#if !defined(__has_feature) || !__has_feature(objc_arc)
  void reset(id object = Traits::InvalidValue(),
             scoped_policy::OwnershipPolicy policy =
                 scoped_policy::OwnershipPolicy::kAssume) {
    scoped_nsprotocol<id>::reset(object, policy);
  }
#else
  void reset(id object = Traits::InvalidValue()) {
    scoped_nsprotocol<id>::reset(object);
  }
#endif
};

}  // namespace fml

#endif  // FLUTTER_FML_PLATFORM_DARWIN_SCOPED_NSOBJECT_H_
