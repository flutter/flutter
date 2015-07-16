// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/callback.h"
#include "base/bind.h"
#include "base/memory/ref_counted.h"

namespace base {

// Do not put everything inside an anonymous namespace.  If you do, many of the
// helper function declarations will generate unused definition warnings.

static const int kParentValue = 1;
static const int kChildValue = 2;

class NoRef {
 public:
  void VoidMethod0() {}
  void VoidConstMethod0() const {}
  int IntMethod0() { return 1; }
};

class HasRef : public NoRef, public base::RefCounted<HasRef> {
};

class Parent {
 public:
  void AddRef(void) const {}
  void Release(void) const {}
  virtual void VirtualSet() { value = kParentValue; }
  void NonVirtualSet() { value = kParentValue; }
  int value;
};

class Child : public Parent {
 public:
  virtual void VirtualSet() { value = kChildValue; }
  void NonVirtualSet() { value = kChildValue; }
};

class NoRefParent {
 public:
  virtual void VirtualSet() { value = kParentValue; }
  void NonVirtualSet() { value = kParentValue; }
  int value;
};

class NoRefChild : public NoRefParent {
  virtual void VirtualSet() { value = kChildValue; }
  void NonVirtualSet() { value = kChildValue; }
};

template <typename T>
T PolymorphicIdentity(T t) {
  return t;
}

int UnwrapParentRef(Parent& p) {
  return p.value;
}

template <typename T>
void VoidPolymorphic1(T t) {
}

#if defined(NCTEST_METHOD_ON_CONST_OBJECT)  // [r"fatal error: cannot initialize a parameter of type 'base::NoRef \*' with an lvalue of type 'typename enable_if<!IsMoveOnlyType<const HasRef \*const>::value, const HasRef \*const>::type' \(aka 'const base::HasRef \*const'\)"]

// Method bound to const-object.
//
// Only const methods should be allowed to work with const objects.
void WontCompile() {
  HasRef has_ref;
  const HasRef* const_has_ref_ptr_ = &has_ref;
  Callback<void(void)> method_to_const_cb =
      Bind(&HasRef::VoidMethod0, const_has_ref_ptr_);
  method_to_const_cb.Run();
}

#elif defined(NCTEST_METHOD_BIND_NEEDS_REFCOUNTED_OBJECT)  // [r"fatal error: no member named 'AddRef' in 'base::NoRef'"]

// Method bound to non-refcounted object.
//
// We require refcounts unless you have Unretained().
void WontCompile() {
  NoRef no_ref;
  Callback<void(void)> no_ref_cb =
      Bind(&NoRef::VoidMethod0, &no_ref);
  no_ref_cb.Run();
}

#elif defined(NCTEST_CONST_METHOD_NEEDS_REFCOUNTED_OBJECT)  // [r"fatal error: no member named 'AddRef' in 'base::NoRef'"]

// Const Method bound to non-refcounted object.
//
// We require refcounts unless you have Unretained().
void WontCompile() {
  NoRef no_ref;
  Callback<void(void)> no_ref_const_cb =
      Bind(&NoRef::VoidConstMethod0, &no_ref);
  no_ref_const_cb.Run();
}

#elif defined(NCTEST_CONST_POINTER)  // [r"fatal error: reference to type 'base::NoRef \*const' could not bind to an lvalue of type 'typename enable_if<!IsMoveOnlyType<const NoRef \*const>::value, const NoRef \*const>::type' \(aka 'const base::NoRef \*const'\)"]

// Const argument used with non-const pointer parameter of same type.
//
// This is just a const-correctness check.
void WontCompile() {
  const NoRef* const_no_ref_ptr;
  Callback<NoRef*(void)> pointer_same_cb =
      Bind(&PolymorphicIdentity<NoRef*>, const_no_ref_ptr);
  pointer_same_cb.Run();
}

#elif defined(NCTEST_CONST_POINTER_SUBTYPE)  // [r"fatal error: reference to type 'base::NoRefParent \*const' could not bind to an lvalue of type 'typename enable_if<!IsMoveOnlyType<const NoRefChild \*const>::value, const NoRefChild \*const>::type' \(aka 'const base::NoRefChild \*const'\)"]

// Const argument used with non-const pointer parameter of super type.
//
// This is just a const-correctness check.
void WontCompile() {
  const NoRefChild* const_child_ptr;
  Callback<NoRefParent*(void)> pointer_super_cb =
    Bind(&PolymorphicIdentity<NoRefParent*>, const_child_ptr);
  pointer_super_cb.Run();
}

#elif defined(DISABLED_NCTEST_DISALLOW_NON_CONST_REF_PARAM)  // [r"fatal error: no member named 'AddRef' in 'base::NoRef'"]
// TODO(dcheng): I think there's a type safety promotion issue here where we can
// pass a const ref to a non const-ref function, or vice versa accidentally. Or
// we make a copy accidentally. Check.

// Functions with reference parameters, unsupported.
//
// First, non-const reference parameters are disallowed by the Google
// style guide. Second, since we are doing argument forwarding it becomes
// very tricky to avoid copies, maintain const correctness, and not
// accidentally have the function be modifying a temporary, or a copy.
void WontCompile() {
  Parent p;
  Callback<int(Parent&)> ref_arg_cb = Bind(&UnwrapParentRef);
  ref_arg_cb.Run(p);
}

#elif defined(NCTEST_DISALLOW_BIND_TO_NON_CONST_REF_PARAM)  // [r"fatal error: static_assert failed \"do_not_bind_functions_with_nonconst_ref\""]

// Binding functions with reference parameters, unsupported.
//
// See comment in NCTEST_DISALLOW_NON_CONST_REF_PARAM
void WontCompile() {
  Parent p;
  Callback<int(void)> ref_cb = Bind(&UnwrapParentRef, p);
  ref_cb.Run();
}

#elif defined(NCTEST_NO_IMPLICIT_ARRAY_PTR_CONVERSION)  // [r"fatal error: static_assert failed \"first_bound_argument_to_method_cannot_be_array\""]

// A method should not be bindable with an array of objects.
//
// This is likely not wanted behavior. We specifically check for it though
// because it is possible, depending on how you implement prebinding, to
// implicitly convert an array type to a pointer type.
void WontCompile() {
  HasRef p[10];
  Callback<void(void)> method_bound_to_array_cb =
      Bind(&HasRef::VoidMethod0, p);
  method_bound_to_array_cb.Run();
}

#elif defined(NCTEST_NO_RAW_PTR_FOR_REFCOUNTED_TYPES)  // [r"fatal error: static_assert failed \"a_parameter_is_refcounted_type_and_needs_scoped_refptr\""]

// Refcounted types should not be bound as a raw pointer.
void WontCompile() {
  HasRef for_raw_ptr;
  int a;
  Callback<void(void)> ref_count_as_raw_ptr_a =
      Bind(&VoidPolymorphic1<int*>, &a);
  Callback<void(void)> ref_count_as_raw_ptr =
      Bind(&VoidPolymorphic1<HasRef*>, &for_raw_ptr);
}

#elif defined(NCTEST_WEAKPTR_BIND_MUST_RETURN_VOID)  // [r"fatal error: static_assert failed \"weak_ptrs_can_only_bind_to_methods_without_return_values\""]

// WeakPtrs cannot be bound to methods with return types.
void WontCompile() {
  NoRef no_ref;
  WeakPtrFactory<NoRef> weak_factory(&no_ref);
  Callback<int(void)> weak_ptr_with_non_void_return_type =
      Bind(&NoRef::IntMethod0, weak_factory.GetWeakPtr());
  weak_ptr_with_non_void_return_type.Run();
}

#elif defined(NCTEST_DISALLOW_ASSIGN_DIFFERENT_TYPES)  // [r"fatal error: no viable conversion from 'Callback<typename internal::BindState<typename internal::FunctorTraits<void \(\*\)\(int\)>::RunnableType, typename internal::FunctorTraits<void \(\*\)\(int\)>::RunType, internal::TypeList<> >::UnboundRunType>' to 'Callback<void \(\)>'"]

// Bind result cannot be assigned to Callbacks with a mismatching type.
void WontCompile() {
  Closure callback_mismatches_bind_type = Bind(&VoidPolymorphic1<int>);
}

#endif

}  // namespace base
