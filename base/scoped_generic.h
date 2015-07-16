// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_SCOPED_GENERIC_H_
#define BASE_SCOPED_GENERIC_H_

#include <stdlib.h>

#include <algorithm>

#include "base/compiler_specific.h"
#include "base/move.h"

namespace base {

// This class acts like ScopedPtr with a custom deleter (although is slightly
// less fancy in some of the more escoteric respects) except that it keeps a
// copy of the object rather than a pointer, and we require that the contained
// object has some kind of "invalid" value.
//
// Defining a scoper based on this class allows you to get a scoper for
// non-pointer types without having to write custom code for set, reset, and
// move, etc. and get almost identical semantics that people are used to from
// scoped_ptr.
//
// It is intended that you will typedef this class with an appropriate deleter
// to implement clean up tasks for objects that act like pointers from a
// resource management standpoint but aren't, such as file descriptors and
// various types of operating system handles. Using scoped_ptr for these
// things requires that you keep a pointer to the handle valid for the lifetime
// of the scoper (which is easy to mess up).
//
// For an object to be able to be put into a ScopedGeneric, it must support
// standard copyable semantics and have a specific "invalid" value. The traits
// must define a free function and also the invalid value to assign for
// default-constructed and released objects.
//
//   struct FooScopedTraits {
//     // It's assumed that this is a fast inline function with little-to-no
//     // penalty for duplicate calls. This must be a static function even
//     // for stateful traits.
//     static int InvalidValue() {
//       return 0;
//     }
//
//     // This free function will not be called if f == InvalidValue()!
//     static void Free(int f) {
//       ::FreeFoo(f);
//     }
//   };
//
//   typedef ScopedGeneric<int, FooScopedTraits> ScopedFoo;
template<typename T, typename Traits>
class ScopedGeneric {
  MOVE_ONLY_TYPE_WITH_MOVE_CONSTRUCTOR_FOR_CPP_03(ScopedGeneric)

 private:
  // This must be first since it's used inline below.
  //
  // Use the empty base class optimization to allow us to have a D
  // member, while avoiding any space overhead for it when D is an
  // empty class.  See e.g. http://www.cantrip.org/emptyopt.html for a good
  // discussion of this technique.
  struct Data : public Traits {
    explicit Data(const T& in) : generic(in) {}
    Data(const T& in, const Traits& other) : Traits(other), generic(in) {}
    T generic;
  };

 public:
  typedef T element_type;
  typedef Traits traits_type;

  ScopedGeneric() : data_(traits_type::InvalidValue()) {}

  // Constructor. Takes responsibility for freeing the resource associated with
  // the object T.
  explicit ScopedGeneric(const element_type& value) : data_(value) {}

  // Constructor. Allows initialization of a stateful traits object.
  ScopedGeneric(const element_type& value, const traits_type& traits)
      : data_(value, traits) {
  }

  // Move constructor. Allows initialization from a ScopedGeneric rvalue.
  ScopedGeneric(ScopedGeneric<T, Traits>&& rvalue)
      : data_(rvalue.release(), rvalue.get_traits()) {
  }

  ~ScopedGeneric() {
    FreeIfNecessary();
  }

  // operator=. Allows assignment from a ScopedGeneric rvalue.
  ScopedGeneric& operator=(ScopedGeneric<T, Traits>&& rvalue) {
    reset(rvalue.release());
    return *this;
  }

  // Frees the currently owned object, if any. Then takes ownership of a new
  // object, if given. Self-resets are not allowd as on scoped_ptr. See
  // http://crbug.com/162971
  void reset(const element_type& value = traits_type::InvalidValue()) {
    if (data_.generic != traits_type::InvalidValue() && data_.generic == value)
      abort();
    FreeIfNecessary();
    data_.generic = value;
  }

  void swap(ScopedGeneric& other) {
    // Standard swap idiom: 'using std::swap' ensures that std::swap is
    // present in the overload set, but we call swap unqualified so that
    // any more-specific overloads can be used, if available.
    using std::swap;
    swap(static_cast<Traits&>(data_), static_cast<Traits&>(other.data_));
    swap(data_.generic, other.data_.generic);
  }

  // Release the object. The return value is the current object held by this
  // object. After this operation, this object will hold a null value, and
  // will not own the object any more.
  element_type release() WARN_UNUSED_RESULT {
    element_type old_generic = data_.generic;
    data_.generic = traits_type::InvalidValue();
    return old_generic;
  }

  const element_type& get() const { return data_.generic; }

  // Returns true if this object doesn't hold the special null value for the
  // associated data type.
  bool is_valid() const { return data_.generic != traits_type::InvalidValue(); }

  bool operator==(const element_type& value) const {
    return data_.generic == value;
  }
  bool operator!=(const element_type& value) const {
    return data_.generic != value;
  }

  Traits& get_traits() { return data_; }
  const Traits& get_traits() const { return data_; }

 private:
  void FreeIfNecessary() {
    if (data_.generic != traits_type::InvalidValue()) {
      data_.Free(data_.generic);
      data_.generic = traits_type::InvalidValue();
    }
  }

  // Forbid comparison. If U != T, it totally doesn't make sense, and if U ==
  // T, it still doesn't make sense because you should never have the same
  // object owned by two different ScopedGenerics.
  template <typename T2, typename Traits2> bool operator==(
      const ScopedGeneric<T2, Traits2>& p2) const;
  template <typename T2, typename Traits2> bool operator!=(
      const ScopedGeneric<T2, Traits2>& p2) const;

  Data data_;
};

template<class T, class Traits>
void swap(const ScopedGeneric<T, Traits>& a,
          const ScopedGeneric<T, Traits>& b) {
  a.swap(b);
}

template<class T, class Traits>
bool operator==(const T& value, const ScopedGeneric<T, Traits>& scoped) {
  return value == scoped.get();
}

template<class T, class Traits>
bool operator!=(const T& value, const ScopedGeneric<T, Traits>& scoped) {
  return value != scoped.get();
}

}  // namespace base

#endif  // BASE_SCOPED_GENERIC_H_
