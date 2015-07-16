// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Scopers help you manage ownership of a pointer, helping you easily manage a
// pointer within a scope, and automatically destroying the pointer at the end
// of a scope.  There are two main classes you will use, which correspond to the
// operators new/delete and new[]/delete[].
//
// Example usage (scoped_ptr<T>):
//   {
//     scoped_ptr<Foo> foo(new Foo("wee"));
//   }  // foo goes out of scope, releasing the pointer with it.
//
//   {
//     scoped_ptr<Foo> foo;          // No pointer managed.
//     foo.reset(new Foo("wee"));    // Now a pointer is managed.
//     foo.reset(new Foo("wee2"));   // Foo("wee") was destroyed.
//     foo.reset(new Foo("wee3"));   // Foo("wee2") was destroyed.
//     foo->Method();                // Foo::Method() called.
//     foo.get()->Method();          // Foo::Method() called.
//     SomeFunc(foo.release());      // SomeFunc takes ownership, foo no longer
//                                   // manages a pointer.
//     foo.reset(new Foo("wee4"));   // foo manages a pointer again.
//     foo.reset();                  // Foo("wee4") destroyed, foo no longer
//                                   // manages a pointer.
//   }  // foo wasn't managing a pointer, so nothing was destroyed.
//
// Example usage (scoped_ptr<T[]>):
//   {
//     scoped_ptr<Foo[]> foo(new Foo[100]);
//     foo.get()->Method();  // Foo::Method on the 0th element.
//     foo[10].Method();     // Foo::Method on the 10th element.
//   }
//
// These scopers also implement part of the functionality of C++11 unique_ptr
// in that they are "movable but not copyable."  You can use the scopers in
// the parameter and return types of functions to signify ownership transfer
// in to and out of a function.  When calling a function that has a scoper
// as the argument type, it must be called with the result of an analogous
// scoper's Pass() function or another function that generates a temporary;
// passing by copy will NOT work.  Here is an example using scoped_ptr:
//
//   void TakesOwnership(scoped_ptr<Foo> arg) {
//     // Do something with arg
//   }
//   scoped_ptr<Foo> CreateFoo() {
//     // No need for calling Pass() because we are constructing a temporary
//     // for the return value.
//     return scoped_ptr<Foo>(new Foo("new"));
//   }
//   scoped_ptr<Foo> PassThru(scoped_ptr<Foo> arg) {
//     return arg.Pass();
//   }
//
//   {
//     scoped_ptr<Foo> ptr(new Foo("yay"));  // ptr manages Foo("yay").
//     TakesOwnership(ptr.Pass());           // ptr no longer owns Foo("yay").
//     scoped_ptr<Foo> ptr2 = CreateFoo();   // ptr2 owns the return Foo.
//     scoped_ptr<Foo> ptr3 =                // ptr3 now owns what was in ptr2.
//         PassThru(ptr2.Pass());            // ptr2 is correspondingly nullptr.
//   }
//
// Notice that if you do not call Pass() when returning from PassThru(), or
// when invoking TakesOwnership(), the code will not compile because scopers
// are not copyable; they only implement move semantics which require calling
// the Pass() function to signify a destructive transfer of state. CreateFoo()
// is different though because we are constructing a temporary on the return
// line and thus can avoid needing to call Pass().
//
// Pass() properly handles upcast in initialization, i.e. you can use a
// scoped_ptr<Child> to initialize a scoped_ptr<Parent>:
//
//   scoped_ptr<Foo> foo(new Foo());
//   scoped_ptr<FooParent> parent(foo.Pass());

#ifndef BASE_MEMORY_SCOPED_PTR_H_
#define BASE_MEMORY_SCOPED_PTR_H_

// This is an implementation designed to match the anticipated future TR2
// implementation of the scoped_ptr class.

#include <assert.h>
#include <stddef.h>
#include <stdlib.h>

#include <algorithm>  // For std::swap().
#include <iosfwd>

#include "base/basictypes.h"
#include "base/compiler_specific.h"
#include "base/move.h"
#include "base/template_util.h"

namespace base {

namespace subtle {
class RefCountedBase;
class RefCountedThreadSafeBase;
}  // namespace subtle

// Function object which deletes its parameter, which must be a pointer.
// If C is an array type, invokes 'delete[]' on the parameter; otherwise,
// invokes 'delete'. The default deleter for scoped_ptr<T>.
template <class T>
struct DefaultDeleter {
  DefaultDeleter() {}
  template <typename U> DefaultDeleter(const DefaultDeleter<U>& other) {
    // IMPLEMENTATION NOTE: C++11 20.7.1.1.2p2 only provides this constructor
    // if U* is implicitly convertible to T* and U is not an array type.
    //
    // Correct implementation should use SFINAE to disable this
    // constructor. However, since there are no other 1-argument constructors,
    // using a COMPILE_ASSERT() based on is_convertible<> and requiring
    // complete types is simpler and will cause compile failures for equivalent
    // misuses.
    //
    // Note, the is_convertible<U*, T*> check also ensures that U is not an
    // array. T is guaranteed to be a non-array, so any U* where U is an array
    // cannot convert to T*.
    enum { T_must_be_complete = sizeof(T) };
    enum { U_must_be_complete = sizeof(U) };
    COMPILE_ASSERT((base::is_convertible<U*, T*>::value),
                   U_ptr_must_implicitly_convert_to_T_ptr);
  }
  inline void operator()(T* ptr) const {
    enum { type_must_be_complete = sizeof(T) };
    delete ptr;
  }
};

// Specialization of DefaultDeleter for array types.
template <class T>
struct DefaultDeleter<T[]> {
  inline void operator()(T* ptr) const {
    enum { type_must_be_complete = sizeof(T) };
    delete[] ptr;
  }

 private:
  // Disable this operator for any U != T because it is undefined to execute
  // an array delete when the static type of the array mismatches the dynamic
  // type.
  //
  // References:
  //   C++98 [expr.delete]p3
  //   http://cplusplus.github.com/LWG/lwg-defects.html#938
  template <typename U> void operator()(U* array) const;
};

template <class T, int n>
struct DefaultDeleter<T[n]> {
  // Never allow someone to declare something like scoped_ptr<int[10]>.
  COMPILE_ASSERT(sizeof(T) == -1, do_not_use_array_with_size_as_type);
};

// Function object which invokes 'free' on its parameter, which must be
// a pointer. Can be used to store malloc-allocated pointers in scoped_ptr:
//
// scoped_ptr<int, base::FreeDeleter> foo_ptr(
//     static_cast<int*>(malloc(sizeof(int))));
struct FreeDeleter {
  inline void operator()(void* ptr) const {
    free(ptr);
  }
};

namespace internal {

template <typename T> struct IsNotRefCounted {
  enum {
    value = !base::is_convertible<T*, base::subtle::RefCountedBase*>::value &&
        !base::is_convertible<T*, base::subtle::RefCountedThreadSafeBase*>::
            value
  };
};

template <typename T>
struct ShouldAbortOnSelfReset {
  template <typename U>
  static NoType Test(const typename U::AllowSelfReset*);

  template <typename U>
  static YesType Test(...);

  static const bool value = sizeof(Test<T>(0)) == sizeof(YesType);
};

// Minimal implementation of the core logic of scoped_ptr, suitable for
// reuse in both scoped_ptr and its specializations.
template <class T, class D>
class scoped_ptr_impl {
 public:
  explicit scoped_ptr_impl(T* p) : data_(p) {}

  // Initializer for deleters that have data parameters.
  scoped_ptr_impl(T* p, const D& d) : data_(p, d) {}

  // Templated constructor that destructively takes the value from another
  // scoped_ptr_impl.
  template <typename U, typename V>
  scoped_ptr_impl(scoped_ptr_impl<U, V>* other)
      : data_(other->release(), other->get_deleter()) {
    // We do not support move-only deleters.  We could modify our move
    // emulation to have base::subtle::move() and base::subtle::forward()
    // functions that are imperfect emulations of their C++11 equivalents,
    // but until there's a requirement, just assume deleters are copyable.
  }

  template <typename U, typename V>
  void TakeState(scoped_ptr_impl<U, V>* other) {
    // See comment in templated constructor above regarding lack of support
    // for move-only deleters.
    reset(other->release());
    get_deleter() = other->get_deleter();
  }

  ~scoped_ptr_impl() {
    if (data_.ptr != nullptr) {
      // Not using get_deleter() saves one function call in non-optimized
      // builds.
      static_cast<D&>(data_)(data_.ptr);
    }
  }

  void reset(T* p) {
    // This is a self-reset, which is no longer allowed for default deleters:
    // https://crbug.com/162971
    assert(!ShouldAbortOnSelfReset<D>::value || p == nullptr || p != data_.ptr);

    // Note that running data_.ptr = p can lead to undefined behavior if
    // get_deleter()(get()) deletes this. In order to prevent this, reset()
    // should update the stored pointer before deleting its old value.
    //
    // However, changing reset() to use that behavior may cause current code to
    // break in unexpected ways. If the destruction of the owned object
    // dereferences the scoped_ptr when it is destroyed by a call to reset(),
    // then it will incorrectly dispatch calls to |p| rather than the original
    // value of |data_.ptr|.
    //
    // During the transition period, set the stored pointer to nullptr while
    // deleting the object. Eventually, this safety check will be removed to
    // prevent the scenario initially described from occuring and
    // http://crbug.com/176091 can be closed.
    T* old = data_.ptr;
    data_.ptr = nullptr;
    if (old != nullptr)
      static_cast<D&>(data_)(old);
    data_.ptr = p;
  }

  T* get() const { return data_.ptr; }

  D& get_deleter() { return data_; }
  const D& get_deleter() const { return data_; }

  void swap(scoped_ptr_impl& p2) {
    // Standard swap idiom: 'using std::swap' ensures that std::swap is
    // present in the overload set, but we call swap unqualified so that
    // any more-specific overloads can be used, if available.
    using std::swap;
    swap(static_cast<D&>(data_), static_cast<D&>(p2.data_));
    swap(data_.ptr, p2.data_.ptr);
  }

  T* release() {
    T* old_ptr = data_.ptr;
    data_.ptr = nullptr;
    return old_ptr;
  }

 private:
  // Needed to allow type-converting constructor.
  template <typename U, typename V> friend class scoped_ptr_impl;

  // Use the empty base class optimization to allow us to have a D
  // member, while avoiding any space overhead for it when D is an
  // empty class.  See e.g. http://www.cantrip.org/emptyopt.html for a good
  // discussion of this technique.
  struct Data : public D {
    explicit Data(T* ptr_in) : ptr(ptr_in) {}
    Data(T* ptr_in, const D& other) : D(other), ptr(ptr_in) {}
    T* ptr;
  };

  Data data_;

  DISALLOW_COPY_AND_ASSIGN(scoped_ptr_impl);
};

}  // namespace internal

}  // namespace base

// A scoped_ptr<T> is like a T*, except that the destructor of scoped_ptr<T>
// automatically deletes the pointer it holds (if any).
// That is, scoped_ptr<T> owns the T object that it points to.
// Like a T*, a scoped_ptr<T> may hold either nullptr or a pointer to a T
// object. Also like T*, scoped_ptr<T> is thread-compatible, and once you
// dereference it, you get the thread safety guarantees of T.
//
// The size of scoped_ptr is small. On most compilers, when using the
// DefaultDeleter, sizeof(scoped_ptr<T>) == sizeof(T*). Custom deleters will
// increase the size proportional to whatever state they need to have. See
// comments inside scoped_ptr_impl<> for details.
//
// Current implementation targets having a strict subset of  C++11's
// unique_ptr<> features. Known deficiencies include not supporting move-only
// deleteres, function pointers as deleters, and deleters with reference
// types.
template <class T, class D = base::DefaultDeleter<T> >
class scoped_ptr {
  MOVE_ONLY_TYPE_WITH_MOVE_CONSTRUCTOR_FOR_CPP_03(scoped_ptr)

  COMPILE_ASSERT(base::internal::IsNotRefCounted<T>::value,
                 T_is_refcounted_type_and_needs_scoped_refptr);

 public:
  // The element and deleter types.
  typedef T element_type;
  typedef D deleter_type;

  // Constructor.  Defaults to initializing with nullptr.
  scoped_ptr() : impl_(nullptr) {}

  // Constructor.  Takes ownership of p.
  explicit scoped_ptr(element_type* p) : impl_(p) {}

  // Constructor.  Allows initialization of a stateful deleter.
  scoped_ptr(element_type* p, const D& d) : impl_(p, d) {}

  // Constructor.  Allows construction from a nullptr.
  scoped_ptr(decltype(nullptr)) : impl_(nullptr) {}

  // Constructor.  Allows construction from a scoped_ptr rvalue for a
  // convertible type and deleter.
  //
  // IMPLEMENTATION NOTE: C++11 unique_ptr<> keeps this constructor distinct
  // from the normal move constructor. By C++11 20.7.1.2.1.21, this constructor
  // has different post-conditions if D is a reference type. Since this
  // implementation does not support deleters with reference type,
  // we do not need a separate move constructor allowing us to avoid one
  // use of SFINAE. You only need to care about this if you modify the
  // implementation of scoped_ptr.
  template <typename U, typename V>
  scoped_ptr(scoped_ptr<U, V>&& other)
      : impl_(&other.impl_) {
    COMPILE_ASSERT(!base::is_array<U>::value, U_cannot_be_an_array);
  }

  // operator=.  Allows assignment from a scoped_ptr rvalue for a convertible
  // type and deleter.
  //
  // IMPLEMENTATION NOTE: C++11 unique_ptr<> keeps this operator= distinct from
  // the normal move assignment operator. By C++11 20.7.1.2.3.4, this templated
  // form has different requirements on for move-only Deleters. Since this
  // implementation does not support move-only Deleters, we do not need a
  // separate move assignment operator allowing us to avoid one use of SFINAE.
  // You only need to care about this if you modify the implementation of
  // scoped_ptr.
  template <typename U, typename V>
  scoped_ptr& operator=(scoped_ptr<U, V>&& rhs) {
    COMPILE_ASSERT(!base::is_array<U>::value, U_cannot_be_an_array);
    impl_.TakeState(&rhs.impl_);
    return *this;
  }

  // operator=.  Allows assignment from a nullptr. Deletes the currently owned
  // object, if any.
  scoped_ptr& operator=(decltype(nullptr)) {
    reset();
    return *this;
  }

  // Reset.  Deletes the currently owned object, if any.
  // Then takes ownership of a new object, if given.
  void reset(element_type* p = nullptr) { impl_.reset(p); }

  // Accessors to get the owned object.
  // operator* and operator-> will assert() if there is no current object.
  element_type& operator*() const {
    assert(impl_.get() != nullptr);
    return *impl_.get();
  }
  element_type* operator->() const  {
    assert(impl_.get() != nullptr);
    return impl_.get();
  }
  element_type* get() const { return impl_.get(); }

  // Access to the deleter.
  deleter_type& get_deleter() { return impl_.get_deleter(); }
  const deleter_type& get_deleter() const { return impl_.get_deleter(); }

  // Allow scoped_ptr<element_type> to be used in boolean expressions, but not
  // implicitly convertible to a real bool (which is dangerous).
  //
  // Note that this trick is only safe when the == and != operators
  // are declared explicitly, as otherwise "scoped_ptr1 ==
  // scoped_ptr2" will compile but do the wrong thing (i.e., convert
  // to Testable and then do the comparison).
 private:
  typedef base::internal::scoped_ptr_impl<element_type, deleter_type>
      scoped_ptr::*Testable;

 public:
  operator Testable() const {
    return impl_.get() ? &scoped_ptr::impl_ : nullptr;
  }

  // Comparison operators.
  // These return whether two scoped_ptr refer to the same object, not just to
  // two different but equal objects.
  bool operator==(const element_type* p) const { return impl_.get() == p; }
  bool operator!=(const element_type* p) const { return impl_.get() != p; }

  // Swap two scoped pointers.
  void swap(scoped_ptr& p2) {
    impl_.swap(p2.impl_);
  }

  // Release a pointer.
  // The return value is the current pointer held by this object. If this object
  // holds a nullptr, the return value is nullptr. After this operation, this
  // object will hold a nullptr, and will not own the object any more.
  element_type* release() WARN_UNUSED_RESULT {
    return impl_.release();
  }

 private:
  // Needed to reach into |impl_| in the constructor.
  template <typename U, typename V> friend class scoped_ptr;
  base::internal::scoped_ptr_impl<element_type, deleter_type> impl_;

  // Forbidden for API compatibility with std::unique_ptr.
  explicit scoped_ptr(int disallow_construction_from_null);

  // Forbid comparison of scoped_ptr types.  If U != T, it totally
  // doesn't make sense, and if U == T, it still doesn't make sense
  // because you should never have the same object owned by two different
  // scoped_ptrs.
  template <class U> bool operator==(scoped_ptr<U> const& p2) const;
  template <class U> bool operator!=(scoped_ptr<U> const& p2) const;
};

template <class T, class D>
class scoped_ptr<T[], D> {
  MOVE_ONLY_TYPE_WITH_MOVE_CONSTRUCTOR_FOR_CPP_03(scoped_ptr)

 public:
  // The element and deleter types.
  typedef T element_type;
  typedef D deleter_type;

  // Constructor.  Defaults to initializing with nullptr.
  scoped_ptr() : impl_(nullptr) {}

  // Constructor. Stores the given array. Note that the argument's type
  // must exactly match T*. In particular:
  // - it cannot be a pointer to a type derived from T, because it is
  //   inherently unsafe in the general case to access an array through a
  //   pointer whose dynamic type does not match its static type (eg., if
  //   T and the derived types had different sizes access would be
  //   incorrectly calculated). Deletion is also always undefined
  //   (C++98 [expr.delete]p3). If you're doing this, fix your code.
  // - it cannot be const-qualified differently from T per unique_ptr spec
  //   (http://cplusplus.github.com/LWG/lwg-active.html#2118). Users wanting
  //   to work around this may use implicit_cast<const T*>().
  //   However, because of the first bullet in this comment, users MUST
  //   NOT use implicit_cast<Base*>() to upcast the static type of the array.
  explicit scoped_ptr(element_type* array) : impl_(array) {}

  // Constructor.  Allows construction from a nullptr.
  scoped_ptr(decltype(nullptr)) : impl_(nullptr) {}

  // Constructor.  Allows construction from a scoped_ptr rvalue.
  scoped_ptr(scoped_ptr&& other) : impl_(&other.impl_) {}

  // operator=.  Allows assignment from a scoped_ptr rvalue.
  scoped_ptr& operator=(scoped_ptr&& rhs) {
    impl_.TakeState(&rhs.impl_);
    return *this;
  }

  // operator=.  Allows assignment from a nullptr. Deletes the currently owned
  // array, if any.
  scoped_ptr& operator=(decltype(nullptr)) {
    reset();
    return *this;
  }

  // Reset.  Deletes the currently owned array, if any.
  // Then takes ownership of a new object, if given.
  void reset(element_type* array = nullptr) { impl_.reset(array); }

  // Accessors to get the owned array.
  element_type& operator[](size_t i) const {
    assert(impl_.get() != nullptr);
    return impl_.get()[i];
  }
  element_type* get() const { return impl_.get(); }

  // Access to the deleter.
  deleter_type& get_deleter() { return impl_.get_deleter(); }
  const deleter_type& get_deleter() const { return impl_.get_deleter(); }

  // Allow scoped_ptr<element_type> to be used in boolean expressions, but not
  // implicitly convertible to a real bool (which is dangerous).
 private:
  typedef base::internal::scoped_ptr_impl<element_type, deleter_type>
      scoped_ptr::*Testable;

 public:
  operator Testable() const {
    return impl_.get() ? &scoped_ptr::impl_ : nullptr;
  }

  // Comparison operators.
  // These return whether two scoped_ptr refer to the same object, not just to
  // two different but equal objects.
  bool operator==(element_type* array) const { return impl_.get() == array; }
  bool operator!=(element_type* array) const { return impl_.get() != array; }

  // Swap two scoped pointers.
  void swap(scoped_ptr& p2) {
    impl_.swap(p2.impl_);
  }

  // Release a pointer.
  // The return value is the current pointer held by this object. If this object
  // holds a nullptr, the return value is nullptr. After this operation, this
  // object will hold a nullptr, and will not own the object any more.
  element_type* release() WARN_UNUSED_RESULT {
    return impl_.release();
  }

 private:
  // Force element_type to be a complete type.
  enum { type_must_be_complete = sizeof(element_type) };

  // Actually hold the data.
  base::internal::scoped_ptr_impl<element_type, deleter_type> impl_;

  // Disable initialization from any type other than element_type*, by
  // providing a constructor that matches such an initialization, but is
  // private and has no definition. This is disabled because it is not safe to
  // call delete[] on an array whose static type does not match its dynamic
  // type.
  template <typename U> explicit scoped_ptr(U* array);
  explicit scoped_ptr(int disallow_construction_from_null);

  // Disable reset() from any type other than element_type*, for the same
  // reasons as the constructor above.
  template <typename U> void reset(U* array);
  void reset(int disallow_reset_from_null);

  // Forbid comparison of scoped_ptr types.  If U != T, it totally
  // doesn't make sense, and if U == T, it still doesn't make sense
  // because you should never have the same object owned by two different
  // scoped_ptrs.
  template <class U> bool operator==(scoped_ptr<U> const& p2) const;
  template <class U> bool operator!=(scoped_ptr<U> const& p2) const;
};

// Free functions
template <class T, class D>
void swap(scoped_ptr<T, D>& p1, scoped_ptr<T, D>& p2) {
  p1.swap(p2);
}

template <class T, class D>
bool operator==(T* p1, const scoped_ptr<T, D>& p2) {
  return p1 == p2.get();
}

template <class T, class D>
bool operator!=(T* p1, const scoped_ptr<T, D>& p2) {
  return p1 != p2.get();
}

// A function to convert T* into scoped_ptr<T>
// Doing e.g. make_scoped_ptr(new FooBarBaz<type>(arg)) is a shorter notation
// for scoped_ptr<FooBarBaz<type> >(new FooBarBaz<type>(arg))
template <typename T>
scoped_ptr<T> make_scoped_ptr(T* ptr) {
  return scoped_ptr<T>(ptr);
}

template <typename T>
std::ostream& operator<<(std::ostream& out, const scoped_ptr<T>& p) {
  return out << p.get();
}

#endif  // BASE_MEMORY_SCOPED_PTR_H_
