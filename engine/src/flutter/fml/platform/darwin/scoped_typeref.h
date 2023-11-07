// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_PLATFORM_DARWIN_SCOPED_TYPEREF_H_
#define FLUTTER_FML_PLATFORM_DARWIN_SCOPED_TYPEREF_H_

#include "flutter/fml/compiler_specific.h"
#include "flutter/fml/platform/darwin/scoped_policy.h"

namespace fml {

// ScopedTypeRef<> is patterned after std::unique_ptr<>, but maintains ownership
// of a reference to any type that is maintained by Retain and Release methods.
//
// The Traits structure must provide the Retain and Release methods for type T.
// A default ScopedTypeRefTraits is used but not defined, and should be defined
// for each type to use this interface. For example, an appropriate definition
// of ScopedTypeRefTraits for CGLContextObj would be:
//
//   template<>
//   struct ScopedTypeRefTraits<CGLContextObj> {
//     static CGLContextObj InvalidValue() { return nullptr; }
//     static CGLContextObj Retain(CGLContextObj object) {
//       CGLContextRetain(object);
//       return object;
//     }
//     static void Release(CGLContextObj object) { CGLContextRelease(object); }
//   };
//
// For the many types that have pass-by-pointer create functions, the function
// InitializeInto() is provided to allow direct initialization and assumption
// of ownership of the object. For example, continuing to use the above
// CGLContextObj specialization:
//
//   fml::ScopedTypeRef<CGLContextObj> context;
//   CGLCreateContext(pixel_format, share_group, context.InitializeInto());
//
// For initialization with an existing object, the caller may specify whether
// the ScopedTypeRef<> being initialized is assuming the caller's existing
// ownership of the object (and should not call Retain in initialization) or if
// it should not assume this ownership and must create its own (by calling
// Retain in initialization). This behavior is based on the |policy| parameter,
// with |kAssume| for the former and |kRetain| for the latter. The default
// policy is to |kAssume|.

template <typename T>
struct ScopedTypeRefTraits;

template <typename T, typename Traits = ScopedTypeRefTraits<T>>
class ScopedTypeRef {
 public:
  typedef T element_type;

  explicit ScopedTypeRef(
      __unsafe_unretained T object = Traits::InvalidValue(),
      fml::scoped_policy::OwnershipPolicy policy = fml::scoped_policy::kAssume)
      : object_(object) {
    if (object_ && policy == fml::scoped_policy::kRetain) {
      object_ = Traits::Retain(object_);
    }
  }

  // NOLINTNEXTLINE(google-explicit-constructor)
  ScopedTypeRef(const ScopedTypeRef<T, Traits>& that) : object_(that.object_) {
    if (object_) {
      object_ = Traits::Retain(object_);
    }
  }

  // This allows passing an object to a function that takes its superclass.
  template <typename R, typename RTraits>
  explicit ScopedTypeRef(const ScopedTypeRef<R, RTraits>& that_as_subclass)
      : object_(that_as_subclass.get()) {
    if (object_) {
      object_ = Traits::Retain(object_);
    }
  }

  // NOLINTNEXTLINE(google-explicit-constructor)
  ScopedTypeRef(ScopedTypeRef<T, Traits>&& that) : object_(that.object_) {
    that.object_ = Traits::InvalidValue();
  }

  ~ScopedTypeRef() {
    if (object_) {
      Traits::Release(object_);
    }
  }

  ScopedTypeRef& operator=(const ScopedTypeRef<T, Traits>& that) {
    reset(that.get(), fml::scoped_policy::kRetain);
    return *this;
  }

  // This is to be used only to take ownership of objects that are created
  // by pass-by-pointer create functions. To enforce this, require that the
  // object be reset to NULL before this may be used.
  [[nodiscard]] T* InitializeInto() {
    FML_DCHECK(!object_);
    return &object_;
  }

  void reset(__unsafe_unretained T object = Traits::InvalidValue(),
             fml::scoped_policy::OwnershipPolicy policy =
                 fml::scoped_policy::kAssume) {
    if (object && policy == fml::scoped_policy::kRetain) {
      object = Traits::Retain(object);
    }
    if (object_) {
      Traits::Release(object_);
    }
    object_ = object;
  }

  bool operator==(__unsafe_unretained T that) const { return object_ == that; }

  bool operator!=(__unsafe_unretained T that) const { return object_ != that; }

  // NOLINTNEXTLINE(google-explicit-constructor)
  operator T() const __attribute((ns_returns_not_retained)) { return object_; }

  T get() const __attribute((ns_returns_not_retained)) { return object_; }

  void swap(ScopedTypeRef& that) {
    __unsafe_unretained T temp = that.object_;
    that.object_ = object_;
    object_ = temp;
  }

 protected:
  // ScopedTypeRef<>::release() is like std::unique_ptr<>::release.  It is NOT
  // a wrapper for Release().  To force a ScopedTypeRef<> object to call
  // Release(), use ScopedTypeRef<>::reset().
  [[nodiscard]] T release() __attribute((ns_returns_not_retained)) {
    __unsafe_unretained T temp = object_;
    object_ = Traits::InvalidValue();
    return temp;
  }

 private:
  __unsafe_unretained T object_;
};

}  // namespace fml

#endif  // FLUTTER_FML_PLATFORM_DARWIN_SCOPED_TYPEREF_H_
