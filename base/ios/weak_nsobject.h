// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_IOS_WEAK_NSOBJECT_H_
#define BASE_IOS_WEAK_NSOBJECT_H_

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#include "base/basictypes.h"
#include "base/compiler_specific.h"
#include "base/logging.h"
#include "base/memory/ref_counted.h"
#include "base/threading/non_thread_safe.h"
#include "base/threading/thread_checker.h"

// WeakNSObject<> is patterned after scoped_nsobject<>, but instead of
// maintaining ownership of an NSObject subclass object, it will nil itself out
// when the object is deallocated.
//
// WeakNSProtocol<> has the same behavior as WeakNSObject, but can be used
// with protocols.
//
// Example usage (base::WeakNSObject<T>):
//   scoped_nsobject<Foo> foo([[Foo alloc] init]);
//   WeakNSObject<Foo> weak_foo;  // No pointer
//   weak_foo.reset(foo)  // Now a weak reference is kept.
//   [weak_foo description];  // Returns [foo description].
//   foo.reset();  // The reference is released.
//   [weak_foo description];  // Returns nil, as weak_foo is pointing to nil.
//
//
// Implementation wise a WeakNSObject keeps a reference to a refcounted
// WeakContainer. There is one unique instance of a WeakContainer per watched
// NSObject, this relationship is maintained via the ObjectiveC associated
// object API, indirectly via an ObjectiveC CRBWeakNSProtocolSentinel class.
//
// Threading restrictions:
// - Several WeakNSObject pointing to the same underlying object must all be
//   created and dereferenced on the same thread;
// - thread safety is enforced by the implementation, except in two cases:
//   (1) it is allowed to copy a WeakNSObject on a different thread. However,
//       that copy must return to the original thread before being dereferenced,
//   (2) it is allowed to destroy a WeakNSObject on any thread;
// - the implementation assumes that the tracked object will be released on the
//   same thread that the WeakNSObject is created on.
namespace base {

// WeakContainer keeps a weak pointer to an object and clears it when it
// receives nullify() from the object's sentinel.
class WeakContainer : public base::RefCountedThreadSafe<WeakContainer> {
 public:
  explicit WeakContainer(id object) : object_(object) {}

  id object() {
    DCHECK(checker_.CalledOnValidThread());
    return object_;
  }

  void nullify() {
    DCHECK(checker_.CalledOnValidThread());
    object_ = nil;
  }

 private:
  friend base::RefCountedThreadSafe<WeakContainer>;
  ~WeakContainer() {}
  base::ThreadChecker checker_;
  id object_;
};

}  // namespace base

// Sentinel for observing the object contained in the weak pointer. The object
// will be deleted when the weak object is deleted and will notify its
// container.
@interface CRBWeakNSProtocolSentinel : NSObject
// Return the only associated container for this object. There can be only one.
// Will return null if object is nil .
+ (scoped_refptr<base::WeakContainer>)containerForObject:(id)object;
@end

namespace base {

// Base class for all WeakNSObject derivatives.
template <typename NST>
class WeakNSProtocol {
 public:
  explicit WeakNSProtocol(NST object = nil) {
    container_ = [CRBWeakNSProtocolSentinel containerForObject:object];
  }

  WeakNSProtocol(const WeakNSProtocol<NST>& that) {
    // A WeakNSProtocol object can be copied on one thread and used on
    // another.
    checker_.DetachFromThread();
    container_ = that.container_;
  }

  ~WeakNSProtocol() {
    // A WeakNSProtocol object can be used on one thread and released on
    // another. This is not the case for the contained object.
    checker_.DetachFromThread();
  }

  void reset(NST object = nil) {
    DCHECK(checker_.CalledOnValidThread());
    container_ = [CRBWeakNSProtocolSentinel containerForObject:object];
  }

  NST get() const {
    DCHECK(checker_.CalledOnValidThread());
    if (!container_.get())
      return nil;
    return container_->object();
  }

  WeakNSProtocol& operator=(const WeakNSProtocol<NST>& that) {
    // A WeakNSProtocol object can be copied on one thread and used on
    // another.
    checker_.DetachFromThread();
    container_ = that.container_;
    return *this;
  }

  bool operator==(NST that) const {
    DCHECK(checker_.CalledOnValidThread());
    return get() == that;
  }

  bool operator!=(NST that) const {
    DCHECK(checker_.CalledOnValidThread());
    return get() != that;
  }

  operator NST() const {
    DCHECK(checker_.CalledOnValidThread());
    return get();
  }

 private:
  // Refecounted reference to the container tracking the ObjectiveC object this
  // class encapsulates.
  scoped_refptr<base::WeakContainer> container_;
  base::ThreadChecker checker_;
};

// Free functions
template <class NST>
bool operator==(NST p1, const WeakNSProtocol<NST>& p2) {
  return p1 == p2.get();
}

template <class NST>
bool operator!=(NST p1, const WeakNSProtocol<NST>& p2) {
  return p1 != p2.get();
}

template <typename NST>
class WeakNSObject : public WeakNSProtocol<NST*> {
 public:
  explicit WeakNSObject(NST* object = nil) : WeakNSProtocol<NST*>(object) {}

  WeakNSObject(const WeakNSObject<NST>& that) : WeakNSProtocol<NST*>(that) {}

  WeakNSObject& operator=(const WeakNSObject<NST>& that) {
    WeakNSProtocol<NST*>::operator=(that);
    return *this;
  }
};

// Specialization to make WeakNSObject<id> work.
template <>
class WeakNSObject<id> : public WeakNSProtocol<id> {
 public:
  explicit WeakNSObject(id object = nil) : WeakNSProtocol<id>(object) {}

  WeakNSObject(const WeakNSObject<id>& that) : WeakNSProtocol<id>(that) {}

  WeakNSObject& operator=(const WeakNSObject<id>& that) {
    WeakNSProtocol<id>::operator=(that);
    return *this;
  }
};

}  // namespace base

#endif  // BASE_IOS_WEAK_NSOBJECT_H_
