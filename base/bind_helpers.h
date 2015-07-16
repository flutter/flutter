// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This defines a set of argument wrappers and related factory methods that
// can be used specify the refcounting and reference semantics of arguments
// that are bound by the Bind() function in base/bind.h.
//
// It also defines a set of simple functions and utilities that people want
// when using Callback<> and Bind().
//
//
// ARGUMENT BINDING WRAPPERS
//
// The wrapper functions are base::Unretained(), base::Owned(), base::Passed(),
// base::ConstRef(), and base::IgnoreResult().
//
// Unretained() allows Bind() to bind a non-refcounted class, and to disable
// refcounting on arguments that are refcounted objects.
//
// Owned() transfers ownership of an object to the Callback resulting from
// bind; the object will be deleted when the Callback is deleted.
//
// Passed() is for transferring movable-but-not-copyable types (eg. scoped_ptr)
// through a Callback. Logically, this signifies a destructive transfer of
// the state of the argument into the target function.  Invoking
// Callback::Run() twice on a Callback that was created with a Passed()
// argument will CHECK() because the first invocation would have already
// transferred ownership to the target function.
//
// ConstRef() allows binding a constant reference to an argument rather
// than a copy.
//
// IgnoreResult() is used to adapt a function or Callback with a return type to
// one with a void return. This is most useful if you have a function with,
// say, a pesky ignorable bool return that you want to use with PostTask or
// something else that expect a Callback with a void return.
//
// EXAMPLE OF Unretained():
//
//   class Foo {
//    public:
//     void func() { cout << "Foo:f" << endl; }
//   };
//
//   // In some function somewhere.
//   Foo foo;
//   Closure foo_callback =
//       Bind(&Foo::func, Unretained(&foo));
//   foo_callback.Run();  // Prints "Foo:f".
//
// Without the Unretained() wrapper on |&foo|, the above call would fail
// to compile because Foo does not support the AddRef() and Release() methods.
//
//
// EXAMPLE OF Owned():
//
//   void foo(int* arg) { cout << *arg << endl }
//
//   int* pn = new int(1);
//   Closure foo_callback = Bind(&foo, Owned(pn));
//
//   foo_callback.Run();  // Prints "1"
//   foo_callback.Run();  // Prints "1"
//   *n = 2;
//   foo_callback.Run();  // Prints "2"
//
//   foo_callback.Reset();  // |pn| is deleted.  Also will happen when
//                          // |foo_callback| goes out of scope.
//
// Without Owned(), someone would have to know to delete |pn| when the last
// reference to the Callback is deleted.
//
//
// EXAMPLE OF ConstRef():
//
//   void foo(int arg) { cout << arg << endl }
//
//   int n = 1;
//   Closure no_ref = Bind(&foo, n);
//   Closure has_ref = Bind(&foo, ConstRef(n));
//
//   no_ref.Run();  // Prints "1"
//   has_ref.Run();  // Prints "1"
//
//   n = 2;
//   no_ref.Run();  // Prints "1"
//   has_ref.Run();  // Prints "2"
//
// Note that because ConstRef() takes a reference on |n|, |n| must outlive all
// its bound callbacks.
//
//
// EXAMPLE OF IgnoreResult():
//
//   int DoSomething(int arg) { cout << arg << endl; }
//
//   // Assign to a Callback with a void return type.
//   Callback<void(int)> cb = Bind(IgnoreResult(&DoSomething));
//   cb->Run(1);  // Prints "1".
//
//   // Prints "1" on |ml|.
//   ml->PostTask(FROM_HERE, Bind(IgnoreResult(&DoSomething), 1);
//
//
// EXAMPLE OF Passed():
//
//   void TakesOwnership(scoped_ptr<Foo> arg) { }
//   scoped_ptr<Foo> CreateFoo() { return scoped_ptr<Foo>(new Foo()); }
//
//   scoped_ptr<Foo> f(new Foo());
//
//   // |cb| is given ownership of Foo(). |f| is now NULL.
//   // You can use f.Pass() in place of &f, but it's more verbose.
//   Closure cb = Bind(&TakesOwnership, Passed(&f));
//
//   // Run was never called so |cb| still owns Foo() and deletes
//   // it on Reset().
//   cb.Reset();
//
//   // |cb| is given a new Foo created by CreateFoo().
//   cb = Bind(&TakesOwnership, Passed(CreateFoo()));
//
//   // |arg| in TakesOwnership() is given ownership of Foo(). |cb|
//   // no longer owns Foo() and, if reset, would not delete Foo().
//   cb.Run();  // Foo() is now transferred to |arg| and deleted.
//   cb.Run();  // This CHECK()s since Foo() already been used once.
//
// Passed() is particularly useful with PostTask() when you are transferring
// ownership of an argument into a task, but don't necessarily know if the
// task will always be executed. This can happen if the task is cancellable
// or if it is posted to a TaskRunner.
//
//
// SIMPLE FUNCTIONS AND UTILITIES.
//
//   DoNothing() - Useful for creating a Closure that does nothing when called.
//   DeletePointer<T>() - Useful for creating a Closure that will delete a
//                        pointer when invoked. Only use this when necessary.
//                        In most cases MessageLoop::DeleteSoon() is a better
//                        fit.

#ifndef BASE_BIND_HELPERS_H_
#define BASE_BIND_HELPERS_H_

#include "base/basictypes.h"
#include "base/callback.h"
#include "base/memory/weak_ptr.h"
#include "base/template_util.h"

namespace base {
namespace internal {

// Use the Substitution Failure Is Not An Error (SFINAE) trick to inspect T
// for the existence of AddRef() and Release() functions of the correct
// signature.
//
// http://en.wikipedia.org/wiki/Substitution_failure_is_not_an_error
// http://stackoverflow.com/questions/257288/is-it-possible-to-write-a-c-template-to-check-for-a-functions-existence
// http://stackoverflow.com/questions/4358584/sfinae-approach-comparison
// http://stackoverflow.com/questions/1966362/sfinae-to-check-for-inherited-member-functions
//
// The last link in particular show the method used below.
//
// For SFINAE to work with inherited methods, we need to pull some extra tricks
// with multiple inheritance.  In the more standard formulation, the overloads
// of Check would be:
//
//   template <typename C>
//   Yes NotTheCheckWeWant(Helper<&C::TargetFunc>*);
//
//   template <typename C>
//   No NotTheCheckWeWant(...);
//
//   static const bool value = sizeof(NotTheCheckWeWant<T>(0)) == sizeof(Yes);
//
// The problem here is that template resolution will not match
// C::TargetFunc if TargetFunc does not exist directly in C.  That is, if
// TargetFunc in inherited from an ancestor, &C::TargetFunc will not match,
// |value| will be false.  This formulation only checks for whether or
// not TargetFunc exist directly in the class being introspected.
//
// To get around this, we play a dirty trick with multiple inheritance.
// First, We create a class BaseMixin that declares each function that we
// want to probe for.  Then we create a class Base that inherits from both T
// (the class we wish to probe) and BaseMixin.  Note that the function
// signature in BaseMixin does not need to match the signature of the function
// we are probing for; thus it's easiest to just use void(void).
//
// Now, if TargetFunc exists somewhere in T, then &Base::TargetFunc has an
// ambiguous resolution between BaseMixin and T.  This lets us write the
// following:
//
//   template <typename C>
//   No GoodCheck(Helper<&C::TargetFunc>*);
//
//   template <typename C>
//   Yes GoodCheck(...);
//
//   static const bool value = sizeof(GoodCheck<Base>(0)) == sizeof(Yes);
//
// Notice here that the variadic version of GoodCheck() returns Yes here
// instead of No like the previous one. Also notice that we calculate |value|
// by specializing GoodCheck() on Base instead of T.
//
// We've reversed the roles of the variadic, and Helper overloads.
// GoodCheck(Helper<&C::TargetFunc>*), when C = Base, fails to be a valid
// substitution if T::TargetFunc exists. Thus GoodCheck<Base>(0) will resolve
// to the variadic version if T has TargetFunc.  If T::TargetFunc does not
// exist, then &C::TargetFunc is not ambiguous, and the overload resolution
// will prefer GoodCheck(Helper<&C::TargetFunc>*).
//
// This method of SFINAE will correctly probe for inherited names, but it cannot
// typecheck those names.  It's still a good enough sanity check though.
//
// Works on gcc-4.2, gcc-4.4, and Visual Studio 2008.
//
// TODO(ajwong): Move to ref_counted.h or template_util.h when we've vetted
// this works well.
//
// TODO(ajwong): Make this check for Release() as well.
// See http://crbug.com/82038.
template <typename T>
class SupportsAddRefAndRelease {
  typedef char Yes[1];
  typedef char No[2];

  struct BaseMixin {
    void AddRef();
  };

// MSVC warns when you try to use Base if T has a private destructor, the
// common pattern for refcounted types. It does this even though no attempt to
// instantiate Base is made.  We disable the warning for this definition.
#if defined(OS_WIN)
#pragma warning(push)
#pragma warning(disable:4624)
#endif
  struct Base : public T, public BaseMixin {
  };
#if defined(OS_WIN)
#pragma warning(pop)
#endif

  template <void(BaseMixin::*)(void)> struct Helper {};

  template <typename C>
  static No& Check(Helper<&C::AddRef>*);

  template <typename >
  static Yes& Check(...);

 public:
  enum { value = sizeof(Check<Base>(0)) == sizeof(Yes) };
};

// Helpers to assert that arguments of a recounted type are bound with a
// scoped_refptr.
template <bool IsClasstype, typename T>
struct UnsafeBindtoRefCountedArgHelper : false_type {
};

template <typename T>
struct UnsafeBindtoRefCountedArgHelper<true, T>
    : integral_constant<bool, SupportsAddRefAndRelease<T>::value> {
};

template <typename T>
struct UnsafeBindtoRefCountedArg : false_type {
};

template <typename T>
struct UnsafeBindtoRefCountedArg<T*>
    : UnsafeBindtoRefCountedArgHelper<is_class<T>::value, T> {
};

template <typename T>
class HasIsMethodTag {
  typedef char Yes[1];
  typedef char No[2];

  template <typename U>
  static Yes& Check(typename U::IsMethod*);

  template <typename U>
  static No& Check(...);

 public:
  enum { value = sizeof(Check<T>(0)) == sizeof(Yes) };
};

template <typename T>
class UnretainedWrapper {
 public:
  explicit UnretainedWrapper(T* o) : ptr_(o) {}
  T* get() const { return ptr_; }
 private:
  T* ptr_;
};

template <typename T>
class ConstRefWrapper {
 public:
  explicit ConstRefWrapper(const T& o) : ptr_(&o) {}
  const T& get() const { return *ptr_; }
 private:
  const T* ptr_;
};

template <typename T>
struct IgnoreResultHelper {
  explicit IgnoreResultHelper(T functor) : functor_(functor) {}

  T functor_;
};

template <typename T>
struct IgnoreResultHelper<Callback<T> > {
  explicit IgnoreResultHelper(const Callback<T>& functor) : functor_(functor) {}

  const Callback<T>& functor_;
};

// An alternate implementation is to avoid the destructive copy, and instead
// specialize ParamTraits<> for OwnedWrapper<> to change the StorageType to
// a class that is essentially a scoped_ptr<>.
//
// The current implementation has the benefit though of leaving ParamTraits<>
// fully in callback_internal.h as well as avoiding type conversions during
// storage.
template <typename T>
class OwnedWrapper {
 public:
  explicit OwnedWrapper(T* o) : ptr_(o) {}
  ~OwnedWrapper() { delete ptr_; }
  T* get() const { return ptr_; }
  OwnedWrapper(const OwnedWrapper& other) {
    ptr_ = other.ptr_;
    other.ptr_ = NULL;
  }

 private:
  mutable T* ptr_;
};

// PassedWrapper is a copyable adapter for a scoper that ignores const.
//
// It is needed to get around the fact that Bind() takes a const reference to
// all its arguments.  Because Bind() takes a const reference to avoid
// unnecessary copies, it is incompatible with movable-but-not-copyable
// types; doing a destructive "move" of the type into Bind() would violate
// the const correctness.
//
// This conundrum cannot be solved without either C++11 rvalue references or
// a O(2^n) blowup of Bind() templates to handle each combination of regular
// types and movable-but-not-copyable types.  Thus we introduce a wrapper type
// that is copyable to transmit the correct type information down into
// BindState<>. Ignoring const in this type makes sense because it is only
// created when we are explicitly trying to do a destructive move.
//
// Two notes:
//  1) PassedWrapper supports any type that has a "Pass()" function.
//     This is intentional. The whitelisting of which specific types we
//     support is maintained by CallbackParamTraits<>.
//  2) is_valid_ is distinct from NULL because it is valid to bind a "NULL"
//     scoper to a Callback and allow the Callback to execute once.
template <typename T>
class PassedWrapper {
 public:
  explicit PassedWrapper(T scoper) : is_valid_(true), scoper_(scoper.Pass()) {}
  PassedWrapper(const PassedWrapper& other)
      : is_valid_(other.is_valid_), scoper_(other.scoper_.Pass()) {
  }
  T Pass() const {
    CHECK(is_valid_);
    is_valid_ = false;
    return scoper_.Pass();
  }

 private:
  mutable bool is_valid_;
  mutable T scoper_;
};

// Unwrap the stored parameters for the wrappers above.
template <typename T>
struct UnwrapTraits {
  typedef const T& ForwardType;
  static ForwardType Unwrap(const T& o) { return o; }
};

template <typename T>
struct UnwrapTraits<UnretainedWrapper<T> > {
  typedef T* ForwardType;
  static ForwardType Unwrap(UnretainedWrapper<T> unretained) {
    return unretained.get();
  }
};

template <typename T>
struct UnwrapTraits<ConstRefWrapper<T> > {
  typedef const T& ForwardType;
  static ForwardType Unwrap(ConstRefWrapper<T> const_ref) {
    return const_ref.get();
  }
};

template <typename T>
struct UnwrapTraits<scoped_refptr<T> > {
  typedef T* ForwardType;
  static ForwardType Unwrap(const scoped_refptr<T>& o) { return o.get(); }
};

template <typename T>
struct UnwrapTraits<WeakPtr<T> > {
  typedef const WeakPtr<T>& ForwardType;
  static ForwardType Unwrap(const WeakPtr<T>& o) { return o; }
};

template <typename T>
struct UnwrapTraits<OwnedWrapper<T> > {
  typedef T* ForwardType;
  static ForwardType Unwrap(const OwnedWrapper<T>& o) {
    return o.get();
  }
};

template <typename T>
struct UnwrapTraits<PassedWrapper<T> > {
  typedef T ForwardType;
  static T Unwrap(PassedWrapper<T>& o) {
    return o.Pass();
  }
};

// Utility for handling different refcounting semantics in the Bind()
// function.
template <bool is_method, typename... T>
struct MaybeScopedRefPtr;

template <bool is_method>
struct MaybeScopedRefPtr<is_method> {
  MaybeScopedRefPtr() {}
};

template <typename T, typename... Rest>
struct MaybeScopedRefPtr<false, T, Rest...> {
  MaybeScopedRefPtr(const T&, const Rest&...) {}
};

template <typename T, size_t n, typename... Rest>
struct MaybeScopedRefPtr<false, T[n], Rest...> {
  MaybeScopedRefPtr(const T*, const Rest&...) {}
};

template <typename T, typename... Rest>
struct MaybeScopedRefPtr<true, T, Rest...> {
  MaybeScopedRefPtr(const T& o, const Rest&...) {}
};

template <typename T, typename... Rest>
struct MaybeScopedRefPtr<true, T*, Rest...> {
  MaybeScopedRefPtr(T* o, const Rest&...) : ref_(o) {}
  scoped_refptr<T> ref_;
};

// No need to additionally AddRef() and Release() since we are storing a
// scoped_refptr<> inside the storage object already.
template <typename T, typename... Rest>
struct MaybeScopedRefPtr<true, scoped_refptr<T>, Rest...> {
  MaybeScopedRefPtr(const scoped_refptr<T>&, const Rest&...) {}
};

template <typename T, typename... Rest>
struct MaybeScopedRefPtr<true, const T*, Rest...> {
  MaybeScopedRefPtr(const T* o, const Rest&...) : ref_(o) {}
  scoped_refptr<const T> ref_;
};

// IsWeakMethod is a helper that determine if we are binding a WeakPtr<> to a
// method.  It is used internally by Bind() to select the correct
// InvokeHelper that will no-op itself in the event the WeakPtr<> for
// the target object is invalidated.
//
// The first argument should be the type of the object that will be received by
// the method.
template <bool IsMethod, typename... Args>
struct IsWeakMethod : public false_type {};

template <typename T, typename... Args>
struct IsWeakMethod<true, WeakPtr<T>, Args...> : public true_type {};

template <typename T, typename... Args>
struct IsWeakMethod<true, ConstRefWrapper<WeakPtr<T>>, Args...>
    : public true_type {};


// Packs a list of types to hold them in a single type.
template <typename... Types>
struct TypeList {};

// Used for DropTypeListItem implementation.
template <size_t n, typename List>
struct DropTypeListItemImpl;

// Do not use enable_if and SFINAE here to avoid MSVC2013 compile failure.
template <size_t n, typename T, typename... List>
struct DropTypeListItemImpl<n, TypeList<T, List...>>
    : DropTypeListItemImpl<n - 1, TypeList<List...>> {};

template <typename T, typename... List>
struct DropTypeListItemImpl<0, TypeList<T, List...>> {
  typedef TypeList<T, List...> Type;
};

template <>
struct DropTypeListItemImpl<0, TypeList<>> {
  typedef TypeList<> Type;
};

// A type-level function that drops |n| list item from given TypeList.
template <size_t n, typename List>
using DropTypeListItem = typename DropTypeListItemImpl<n, List>::Type;

// Used for ConcatTypeLists implementation.
template <typename List1, typename List2>
struct ConcatTypeListsImpl;

template <typename... Types1, typename... Types2>
struct ConcatTypeListsImpl<TypeList<Types1...>, TypeList<Types2...>> {
  typedef TypeList<Types1..., Types2...> Type;
};

// A type-level function that concats two TypeLists.
template <typename List1, typename List2>
using ConcatTypeLists = typename ConcatTypeListsImpl<List1, List2>::Type;

// Used for MakeFunctionType implementation.
template <typename R, typename ArgList>
struct MakeFunctionTypeImpl;

template <typename R, typename... Args>
struct MakeFunctionTypeImpl<R, TypeList<Args...>> {
  typedef R(Type)(Args...);
};

// A type-level function that constructs a function type that has |R| as its
// return type and has TypeLists items as its arguments.
template <typename R, typename ArgList>
using MakeFunctionType = typename MakeFunctionTypeImpl<R, ArgList>::Type;

}  // namespace internal

template <typename T>
static inline internal::UnretainedWrapper<T> Unretained(T* o) {
  return internal::UnretainedWrapper<T>(o);
}

template <typename T>
static inline internal::ConstRefWrapper<T> ConstRef(const T& o) {
  return internal::ConstRefWrapper<T>(o);
}

template <typename T>
static inline internal::OwnedWrapper<T> Owned(T* o) {
  return internal::OwnedWrapper<T>(o);
}

// We offer 2 syntaxes for calling Passed().  The first takes a temporary and
// is best suited for use with the return value of a function. The second
// takes a pointer to the scoper and is just syntactic sugar to avoid having
// to write Passed(scoper.Pass()).
template <typename T>
static inline internal::PassedWrapper<T> Passed(T scoper) {
  return internal::PassedWrapper<T>(scoper.Pass());
}
template <typename T>
static inline internal::PassedWrapper<T> Passed(T* scoper) {
  return internal::PassedWrapper<T>(scoper->Pass());
}

template <typename T>
static inline internal::IgnoreResultHelper<T> IgnoreResult(T data) {
  return internal::IgnoreResultHelper<T>(data);
}

template <typename T>
static inline internal::IgnoreResultHelper<Callback<T> >
IgnoreResult(const Callback<T>& data) {
  return internal::IgnoreResultHelper<Callback<T> >(data);
}

BASE_EXPORT void DoNothing();

template<typename T>
void DeletePointer(T* obj) {
  delete obj;
}

}  // namespace base

#endif  // BASE_BIND_HELPERS_H_
