// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/bind.h"

#include "base/callback.h"
#include "base/memory/ref_counted.h"
#include "base/memory/scoped_ptr.h"
#include "base/memory/weak_ptr.h"
#include "testing/gmock/include/gmock/gmock.h"
#include "testing/gtest/include/gtest/gtest.h"

using ::testing::Mock;
using ::testing::Return;
using ::testing::StrictMock;

namespace base {
namespace {

class IncompleteType;

class NoRef {
 public:
  NoRef() {}

  MOCK_METHOD0(VoidMethod0, void(void));
  MOCK_CONST_METHOD0(VoidConstMethod0, void(void));

  MOCK_METHOD0(IntMethod0, int(void));
  MOCK_CONST_METHOD0(IntConstMethod0, int(void));

 private:
  // Particularly important in this test to ensure no copies are made.
  DISALLOW_COPY_AND_ASSIGN(NoRef);
};

class HasRef : public NoRef {
 public:
  HasRef() {}

  MOCK_CONST_METHOD0(AddRef, void(void));
  MOCK_CONST_METHOD0(Release, bool(void));

 private:
  // Particularly important in this test to ensure no copies are made.
  DISALLOW_COPY_AND_ASSIGN(HasRef);
};

class HasRefPrivateDtor : public HasRef {
 private:
  ~HasRefPrivateDtor() {}
};

static const int kParentValue = 1;
static const int kChildValue = 2;

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
  void VirtualSet() override { value = kChildValue; }
  void NonVirtualSet() { value = kChildValue; }
};

class NoRefParent {
 public:
  virtual void VirtualSet() { value = kParentValue; }
  void NonVirtualSet() { value = kParentValue; }
  int value;
};

class NoRefChild : public NoRefParent {
  void VirtualSet() override { value = kChildValue; }
  void NonVirtualSet() { value = kChildValue; }
};

// Used for probing the number of copies that occur if a type must be coerced
// during argument forwarding in the Run() methods.
struct DerivedCopyCounter {
  DerivedCopyCounter(int* copies, int* assigns)
      : copies_(copies), assigns_(assigns) {
  }
  int* copies_;
  int* assigns_;
};

// Used for probing the number of copies in an argument.
class CopyCounter {
 public:
  CopyCounter(int* copies, int* assigns)
      : copies_(copies), assigns_(assigns) {
  }

  CopyCounter(const CopyCounter& other)
      : copies_(other.copies_),
        assigns_(other.assigns_) {
    (*copies_)++;
  }

  // Probing for copies from coercion.
  explicit CopyCounter(const DerivedCopyCounter& other)
      : copies_(other.copies_),
        assigns_(other.assigns_) {
    (*copies_)++;
  }

  const CopyCounter& operator=(const CopyCounter& rhs) {
    copies_ = rhs.copies_;
    assigns_ = rhs.assigns_;

    if (assigns_) {
      (*assigns_)++;
    }

    return *this;
  }

  int copies() const {
    return *copies_;
  }

 private:
  int* copies_;
  int* assigns_;
};

class DeleteCounter {
 public:
  explicit DeleteCounter(int* deletes)
      : deletes_(deletes) {
  }

  ~DeleteCounter() {
    (*deletes_)++;
  }

  void VoidMethod0() {}

 private:
  int* deletes_;
};

template <typename T>
T PassThru(T scoper) {
  return scoper.Pass();
}

// Some test functions that we can Bind to.
template <typename T>
T PolymorphicIdentity(T t) {
  return t;
}

template <typename T>
void VoidPolymorphic1(T t) {
}

int Identity(int n) {
  return n;
}

int ArrayGet(const int array[], int n) {
  return array[n];
}

int Sum(int a, int b, int c, int d, int e, int f) {
  return a + b + c + d + e + f;
}

const char* CStringIdentity(const char* s) {
  return s;
}

int GetCopies(const CopyCounter& counter) {
  return counter.copies();
}

int UnwrapNoRefParent(NoRefParent p) {
  return p.value;
}

int UnwrapNoRefParentPtr(NoRefParent* p) {
  return p->value;
}

int UnwrapNoRefParentConstRef(const NoRefParent& p) {
  return p.value;
}

void RefArgSet(int &n) {
  n = 2;
}

void PtrArgSet(int *n) {
  *n = 2;
}

int FunctionWithWeakFirstParam(WeakPtr<NoRef> o, int n) {
  return n;
}

int FunctionWithScopedRefptrFirstParam(const scoped_refptr<HasRef>& o, int n) {
  return n;
}

void TakesACallback(const Closure& callback) {
  callback.Run();
}

class BindTest : public ::testing::Test {
 public:
  BindTest() {
    const_has_ref_ptr_ = &has_ref_;
    const_no_ref_ptr_ = &no_ref_;
    static_func_mock_ptr = &static_func_mock_;
  }

  virtual ~BindTest() {
  }

  static void VoidFunc0(void) {
    static_func_mock_ptr->VoidMethod0();
  }

  static int IntFunc0(void) { return static_func_mock_ptr->IntMethod0(); }

 protected:
  StrictMock<NoRef> no_ref_;
  StrictMock<HasRef> has_ref_;
  const HasRef* const_has_ref_ptr_;
  const NoRef* const_no_ref_ptr_;
  StrictMock<NoRef> static_func_mock_;

  // Used by the static functions to perform expectations.
  static StrictMock<NoRef>* static_func_mock_ptr;

 private:
  DISALLOW_COPY_AND_ASSIGN(BindTest);
};

StrictMock<NoRef>* BindTest::static_func_mock_ptr;

// Sanity check that we can instantiate a callback for each arity.
TEST_F(BindTest, ArityTest) {
  Callback<int(void)> c0 = Bind(&Sum, 32, 16, 8, 4, 2, 1);
  EXPECT_EQ(63, c0.Run());

  Callback<int(int)> c1 = Bind(&Sum, 32, 16, 8, 4, 2);
  EXPECT_EQ(75, c1.Run(13));

  Callback<int(int,int)> c2 = Bind(&Sum, 32, 16, 8, 4);
  EXPECT_EQ(85, c2.Run(13, 12));

  Callback<int(int,int,int)> c3 = Bind(&Sum, 32, 16, 8);
  EXPECT_EQ(92, c3.Run(13, 12, 11));

  Callback<int(int,int,int,int)> c4 = Bind(&Sum, 32, 16);
  EXPECT_EQ(94, c4.Run(13, 12, 11, 10));

  Callback<int(int,int,int,int,int)> c5 = Bind(&Sum, 32);
  EXPECT_EQ(87, c5.Run(13, 12, 11, 10, 9));

  Callback<int(int,int,int,int,int,int)> c6 = Bind(&Sum);
  EXPECT_EQ(69, c6.Run(13, 12, 11, 10, 9, 14));
}

// Test the Currying ability of the Callback system.
TEST_F(BindTest, CurryingTest) {
  Callback<int(int,int,int,int,int,int)> c6 = Bind(&Sum);
  EXPECT_EQ(69, c6.Run(13, 12, 11, 10, 9, 14));

  Callback<int(int,int,int,int,int)> c5 = Bind(c6, 32);
  EXPECT_EQ(87, c5.Run(13, 12, 11, 10, 9));

  Callback<int(int,int,int,int)> c4 = Bind(c5, 16);
  EXPECT_EQ(94, c4.Run(13, 12, 11, 10));

  Callback<int(int,int,int)> c3 = Bind(c4, 8);
  EXPECT_EQ(92, c3.Run(13, 12, 11));

  Callback<int(int,int)> c2 = Bind(c3, 4);
  EXPECT_EQ(85, c2.Run(13, 12));

  Callback<int(int)> c1 = Bind(c2, 2);
  EXPECT_EQ(75, c1.Run(13));

  Callback<int(void)> c0 = Bind(c1, 1);
  EXPECT_EQ(63, c0.Run());
}

// Test that currying the rvalue result of another Bind() works correctly.
//   - rvalue should be usable as argument to Bind().
//   - multiple runs of resulting Callback remain valid.
TEST_F(BindTest, CurryingRvalueResultOfBind) {
  int n = 0;
  Closure cb = base::Bind(&TakesACallback, base::Bind(&PtrArgSet, &n));

  // If we implement Bind() such that the return value has auto_ptr-like
  // semantics, the second call here will fail because ownership of
  // the internal BindState<> would have been transfered to a *temporary*
  // constructon of a Callback object on the first call.
  cb.Run();
  EXPECT_EQ(2, n);

  n = 0;
  cb.Run();
  EXPECT_EQ(2, n);
}

// Function type support.
//   - Normal function.
//   - Normal function bound with non-refcounted first argument.
//   - Method bound to non-const object.
//   - Method bound to scoped_refptr.
//   - Const method bound to non-const object.
//   - Const method bound to const object.
//   - Derived classes can be used with pointers to non-virtual base functions.
//   - Derived classes can be used with pointers to virtual base functions (and
//     preserve virtual dispatch).
TEST_F(BindTest, FunctionTypeSupport) {
  EXPECT_CALL(static_func_mock_, VoidMethod0());
  EXPECT_CALL(has_ref_, AddRef()).Times(5);
  EXPECT_CALL(has_ref_, Release()).Times(5);
  EXPECT_CALL(has_ref_, VoidMethod0()).Times(2);
  EXPECT_CALL(has_ref_, VoidConstMethod0()).Times(2);

  Closure normal_cb = Bind(&VoidFunc0);
  Callback<NoRef*(void)> normal_non_refcounted_cb =
      Bind(&PolymorphicIdentity<NoRef*>, &no_ref_);
  normal_cb.Run();
  EXPECT_EQ(&no_ref_, normal_non_refcounted_cb.Run());

  Closure method_cb = Bind(&HasRef::VoidMethod0, &has_ref_);
  Closure method_refptr_cb = Bind(&HasRef::VoidMethod0,
                                  make_scoped_refptr(&has_ref_));
  Closure const_method_nonconst_obj_cb = Bind(&HasRef::VoidConstMethod0,
                                              &has_ref_);
  Closure const_method_const_obj_cb = Bind(&HasRef::VoidConstMethod0,
                                           const_has_ref_ptr_);
  method_cb.Run();
  method_refptr_cb.Run();
  const_method_nonconst_obj_cb.Run();
  const_method_const_obj_cb.Run();

  Child child;
  child.value = 0;
  Closure virtual_set_cb = Bind(&Parent::VirtualSet, &child);
  virtual_set_cb.Run();
  EXPECT_EQ(kChildValue, child.value);

  child.value = 0;
  Closure non_virtual_set_cb = Bind(&Parent::NonVirtualSet, &child);
  non_virtual_set_cb.Run();
  EXPECT_EQ(kParentValue, child.value);
}

// Return value support.
//   - Function with return value.
//   - Method with return value.
//   - Const method with return value.
TEST_F(BindTest, ReturnValues) {
  EXPECT_CALL(static_func_mock_, IntMethod0()).WillOnce(Return(1337));
  EXPECT_CALL(has_ref_, AddRef()).Times(3);
  EXPECT_CALL(has_ref_, Release()).Times(3);
  EXPECT_CALL(has_ref_, IntMethod0()).WillOnce(Return(31337));
  EXPECT_CALL(has_ref_, IntConstMethod0())
      .WillOnce(Return(41337))
      .WillOnce(Return(51337));

  Callback<int(void)> normal_cb = Bind(&IntFunc0);
  Callback<int(void)> method_cb = Bind(&HasRef::IntMethod0, &has_ref_);
  Callback<int(void)> const_method_nonconst_obj_cb =
      Bind(&HasRef::IntConstMethod0, &has_ref_);
  Callback<int(void)> const_method_const_obj_cb =
      Bind(&HasRef::IntConstMethod0, const_has_ref_ptr_);
  EXPECT_EQ(1337, normal_cb.Run());
  EXPECT_EQ(31337, method_cb.Run());
  EXPECT_EQ(41337, const_method_nonconst_obj_cb.Run());
  EXPECT_EQ(51337, const_method_const_obj_cb.Run());
}

// IgnoreResult adapter test.
//   - Function with return value.
//   - Method with return value.
//   - Const Method with return.
//   - Method with return value bound to WeakPtr<>.
//   - Const Method with return bound to WeakPtr<>.
TEST_F(BindTest, IgnoreResult) {
  EXPECT_CALL(static_func_mock_, IntMethod0()).WillOnce(Return(1337));
  EXPECT_CALL(has_ref_, AddRef()).Times(2);
  EXPECT_CALL(has_ref_, Release()).Times(2);
  EXPECT_CALL(has_ref_, IntMethod0()).WillOnce(Return(10));
  EXPECT_CALL(has_ref_, IntConstMethod0()).WillOnce(Return(11));
  EXPECT_CALL(no_ref_, IntMethod0()).WillOnce(Return(12));
  EXPECT_CALL(no_ref_, IntConstMethod0()).WillOnce(Return(13));

  Closure normal_func_cb = Bind(IgnoreResult(&IntFunc0));
  normal_func_cb.Run();

  Closure non_void_method_cb =
      Bind(IgnoreResult(&HasRef::IntMethod0), &has_ref_);
  non_void_method_cb.Run();

  Closure non_void_const_method_cb =
      Bind(IgnoreResult(&HasRef::IntConstMethod0), &has_ref_);
  non_void_const_method_cb.Run();

  WeakPtrFactory<NoRef> weak_factory(&no_ref_);
  WeakPtrFactory<const NoRef> const_weak_factory(const_no_ref_ptr_);

  Closure non_void_weak_method_cb  =
      Bind(IgnoreResult(&NoRef::IntMethod0), weak_factory.GetWeakPtr());
  non_void_weak_method_cb.Run();

  Closure non_void_weak_const_method_cb =
      Bind(IgnoreResult(&NoRef::IntConstMethod0), weak_factory.GetWeakPtr());
  non_void_weak_const_method_cb.Run();

  weak_factory.InvalidateWeakPtrs();
  non_void_weak_const_method_cb.Run();
  non_void_weak_method_cb.Run();
}

// Argument binding tests.
//   - Argument binding to primitive.
//   - Argument binding to primitive pointer.
//   - Argument binding to a literal integer.
//   - Argument binding to a literal string.
//   - Argument binding with template function.
//   - Argument binding to an object.
//   - Argument binding to pointer to incomplete type.
//   - Argument gets type converted.
//   - Pointer argument gets converted.
//   - Const Reference forces conversion.
TEST_F(BindTest, ArgumentBinding) {
  int n = 2;

  Callback<int(void)> bind_primitive_cb = Bind(&Identity, n);
  EXPECT_EQ(n, bind_primitive_cb.Run());

  Callback<int*(void)> bind_primitive_pointer_cb =
      Bind(&PolymorphicIdentity<int*>, &n);
  EXPECT_EQ(&n, bind_primitive_pointer_cb.Run());

  Callback<int(void)> bind_int_literal_cb = Bind(&Identity, 3);
  EXPECT_EQ(3, bind_int_literal_cb.Run());

  Callback<const char*(void)> bind_string_literal_cb =
      Bind(&CStringIdentity, "hi");
  EXPECT_STREQ("hi", bind_string_literal_cb.Run());

  Callback<int(void)> bind_template_function_cb =
      Bind(&PolymorphicIdentity<int>, 4);
  EXPECT_EQ(4, bind_template_function_cb.Run());

  NoRefParent p;
  p.value = 5;
  Callback<int(void)> bind_object_cb = Bind(&UnwrapNoRefParent, p);
  EXPECT_EQ(5, bind_object_cb.Run());

  IncompleteType* incomplete_ptr = reinterpret_cast<IncompleteType*>(123);
  Callback<IncompleteType*(void)> bind_incomplete_ptr_cb =
      Bind(&PolymorphicIdentity<IncompleteType*>, incomplete_ptr);
  EXPECT_EQ(incomplete_ptr, bind_incomplete_ptr_cb.Run());

  NoRefChild c;
  c.value = 6;
  Callback<int(void)> bind_promotes_cb = Bind(&UnwrapNoRefParent, c);
  EXPECT_EQ(6, bind_promotes_cb.Run());

  c.value = 7;
  Callback<int(void)> bind_pointer_promotes_cb =
      Bind(&UnwrapNoRefParentPtr, &c);
  EXPECT_EQ(7, bind_pointer_promotes_cb.Run());

  c.value = 8;
  Callback<int(void)> bind_const_reference_promotes_cb =
      Bind(&UnwrapNoRefParentConstRef, c);
  EXPECT_EQ(8, bind_const_reference_promotes_cb.Run());
}

// Unbound argument type support tests.
//   - Unbound value.
//   - Unbound pointer.
//   - Unbound reference.
//   - Unbound const reference.
//   - Unbound unsized array.
//   - Unbound sized array.
//   - Unbound array-of-arrays.
TEST_F(BindTest, UnboundArgumentTypeSupport) {
  Callback<void(int)> unbound_value_cb = Bind(&VoidPolymorphic1<int>);
  Callback<void(int*)> unbound_pointer_cb = Bind(&VoidPolymorphic1<int*>);
  Callback<void(int&)> unbound_ref_cb = Bind(&VoidPolymorphic1<int&>);
  Callback<void(const int&)> unbound_const_ref_cb =
      Bind(&VoidPolymorphic1<const int&>);
  Callback<void(int[])> unbound_unsized_array_cb =
      Bind(&VoidPolymorphic1<int[]>);
  Callback<void(int[2])> unbound_sized_array_cb =
      Bind(&VoidPolymorphic1<int[2]>);
  Callback<void(int[][2])> unbound_array_of_arrays_cb =
      Bind(&VoidPolymorphic1<int[][2]>);
}

// Function with unbound reference parameter.
//   - Original parameter is modified by callback.
TEST_F(BindTest, UnboundReferenceSupport) {
  int n = 0;
  Callback<void(int&)> unbound_ref_cb = Bind(&RefArgSet);
  unbound_ref_cb.Run(n);
  EXPECT_EQ(2, n);
}

// Functions that take reference parameters.
//  - Forced reference parameter type still stores a copy.
//  - Forced const reference parameter type still stores a copy.
TEST_F(BindTest, ReferenceArgumentBinding) {
  int n = 1;
  int& ref_n = n;
  const int& const_ref_n = n;

  Callback<int(void)> ref_copies_cb = Bind(&Identity, ref_n);
  EXPECT_EQ(n, ref_copies_cb.Run());
  n++;
  EXPECT_EQ(n - 1, ref_copies_cb.Run());

  Callback<int(void)> const_ref_copies_cb = Bind(&Identity, const_ref_n);
  EXPECT_EQ(n, const_ref_copies_cb.Run());
  n++;
  EXPECT_EQ(n - 1, const_ref_copies_cb.Run());
}

// Check that we can pass in arrays and have them be stored as a pointer.
//  - Array of values stores a pointer.
//  - Array of const values stores a pointer.
TEST_F(BindTest, ArrayArgumentBinding) {
  int array[4] = {1, 1, 1, 1};
  const int (*const_array_ptr)[4] = &array;

  Callback<int(void)> array_cb = Bind(&ArrayGet, array, 1);
  EXPECT_EQ(1, array_cb.Run());

  Callback<int(void)> const_array_cb = Bind(&ArrayGet, *const_array_ptr, 1);
  EXPECT_EQ(1, const_array_cb.Run());

  array[1] = 3;
  EXPECT_EQ(3, array_cb.Run());
  EXPECT_EQ(3, const_array_cb.Run());
}

// Verify SupportsAddRefAndRelease correctly introspects the class type for
// AddRef() and Release().
//  - Class with AddRef() and Release()
//  - Class without AddRef() and Release()
//  - Derived Class with AddRef() and Release()
//  - Derived Class without AddRef() and Release()
//  - Derived Class with AddRef() and Release() and a private destructor.
TEST_F(BindTest, SupportsAddRefAndRelease) {
  EXPECT_TRUE(internal::SupportsAddRefAndRelease<HasRef>::value);
  EXPECT_FALSE(internal::SupportsAddRefAndRelease<NoRef>::value);

  // StrictMock<T> is a derived class of T.  So, we use StrictMock<HasRef> and
  // StrictMock<NoRef> to test that SupportsAddRefAndRelease works over
  // inheritance.
  EXPECT_TRUE(internal::SupportsAddRefAndRelease<StrictMock<HasRef> >::value);
  EXPECT_FALSE(internal::SupportsAddRefAndRelease<StrictMock<NoRef> >::value);

  // This matters because the implementation creates a dummy class that
  // inherits from the template type.
  EXPECT_TRUE(internal::SupportsAddRefAndRelease<HasRefPrivateDtor>::value);
}

// Unretained() wrapper support.
//   - Method bound to Unretained() non-const object.
//   - Const method bound to Unretained() non-const object.
//   - Const method bound to Unretained() const object.
TEST_F(BindTest, Unretained) {
  EXPECT_CALL(no_ref_, VoidMethod0());
  EXPECT_CALL(no_ref_, VoidConstMethod0()).Times(2);

  Callback<void(void)> method_cb =
      Bind(&NoRef::VoidMethod0, Unretained(&no_ref_));
  method_cb.Run();

  Callback<void(void)> const_method_cb =
      Bind(&NoRef::VoidConstMethod0, Unretained(&no_ref_));
  const_method_cb.Run();

  Callback<void(void)> const_method_const_ptr_cb =
      Bind(&NoRef::VoidConstMethod0, Unretained(const_no_ref_ptr_));
  const_method_const_ptr_cb.Run();
}

// WeakPtr() support.
//   - Method bound to WeakPtr<> to non-const object.
//   - Const method bound to WeakPtr<> to non-const object.
//   - Const method bound to WeakPtr<> to const object.
//   - Normal Function with WeakPtr<> as P1 can have return type and is
//     not canceled.
TEST_F(BindTest, WeakPtr) {
  EXPECT_CALL(no_ref_, VoidMethod0());
  EXPECT_CALL(no_ref_, VoidConstMethod0()).Times(2);

  WeakPtrFactory<NoRef> weak_factory(&no_ref_);
  WeakPtrFactory<const NoRef> const_weak_factory(const_no_ref_ptr_);

  Closure method_cb =
      Bind(&NoRef::VoidMethod0, weak_factory.GetWeakPtr());
  method_cb.Run();

  Closure const_method_cb =
      Bind(&NoRef::VoidConstMethod0, const_weak_factory.GetWeakPtr());
  const_method_cb.Run();

  Closure const_method_const_ptr_cb =
      Bind(&NoRef::VoidConstMethod0, const_weak_factory.GetWeakPtr());
  const_method_const_ptr_cb.Run();

  Callback<int(int)> normal_func_cb =
      Bind(&FunctionWithWeakFirstParam, weak_factory.GetWeakPtr());
  EXPECT_EQ(1, normal_func_cb.Run(1));

  weak_factory.InvalidateWeakPtrs();
  const_weak_factory.InvalidateWeakPtrs();

  method_cb.Run();
  const_method_cb.Run();
  const_method_const_ptr_cb.Run();

  // Still runs even after the pointers are invalidated.
  EXPECT_EQ(2, normal_func_cb.Run(2));
}

// ConstRef() wrapper support.
//   - Binding w/o ConstRef takes a copy.
//   - Binding a ConstRef takes a reference.
//   - Binding ConstRef to a function ConstRef does not copy on invoke.
TEST_F(BindTest, ConstRef) {
  int n = 1;

  Callback<int(void)> copy_cb = Bind(&Identity, n);
  Callback<int(void)> const_ref_cb = Bind(&Identity, ConstRef(n));
  EXPECT_EQ(n, copy_cb.Run());
  EXPECT_EQ(n, const_ref_cb.Run());
  n++;
  EXPECT_EQ(n - 1, copy_cb.Run());
  EXPECT_EQ(n, const_ref_cb.Run());

  int copies = 0;
  int assigns = 0;
  CopyCounter counter(&copies, &assigns);
  Callback<int(void)> all_const_ref_cb =
      Bind(&GetCopies, ConstRef(counter));
  EXPECT_EQ(0, all_const_ref_cb.Run());
  EXPECT_EQ(0, copies);
  EXPECT_EQ(0, assigns);
}

TEST_F(BindTest, ScopedRefptr) {
  // BUG: The scoped_refptr should cause the only AddRef()/Release() pair. But
  // due to a bug in base::Bind(), there's an extra call when invoking the
  // callback.
  // https://code.google.com/p/chromium/issues/detail?id=251937
  EXPECT_CALL(has_ref_, AddRef()).Times(2);
  EXPECT_CALL(has_ref_, Release()).Times(2);

  const scoped_refptr<StrictMock<HasRef> > refptr(&has_ref_);

  Callback<int(void)> scoped_refptr_const_ref_cb =
      Bind(&FunctionWithScopedRefptrFirstParam, base::ConstRef(refptr), 1);
  EXPECT_EQ(1, scoped_refptr_const_ref_cb.Run());
}

// Test Owned() support.
TEST_F(BindTest, Owned) {
  int deletes = 0;
  DeleteCounter* counter = new DeleteCounter(&deletes);

  // If we don't capture, delete happens on Callback destruction/reset.
  // return the same value.
  Callback<DeleteCounter*(void)> no_capture_cb =
      Bind(&PolymorphicIdentity<DeleteCounter*>, Owned(counter));
  ASSERT_EQ(counter, no_capture_cb.Run());
  ASSERT_EQ(counter, no_capture_cb.Run());
  EXPECT_EQ(0, deletes);
  no_capture_cb.Reset();  // This should trigger a delete.
  EXPECT_EQ(1, deletes);

  deletes = 0;
  counter = new DeleteCounter(&deletes);
  base::Closure own_object_cb =
      Bind(&DeleteCounter::VoidMethod0, Owned(counter));
  own_object_cb.Run();
  EXPECT_EQ(0, deletes);
  own_object_cb.Reset();
  EXPECT_EQ(1, deletes);
}

// Passed() wrapper support.
//   - Passed() can be constructed from a pointer to scoper.
//   - Passed() can be constructed from a scoper rvalue.
//   - Using Passed() gives Callback Ownership.
//   - Ownership is transferred from Callback to callee on the first Run().
//   - Callback supports unbound arguments.
TEST_F(BindTest, ScopedPtr) {
  int deletes = 0;

  // Tests the Passed() function's support for pointers.
  scoped_ptr<DeleteCounter> ptr(new DeleteCounter(&deletes));
  Callback<scoped_ptr<DeleteCounter>(void)> unused_callback =
      Bind(&PassThru<scoped_ptr<DeleteCounter> >, Passed(&ptr));
  EXPECT_FALSE(ptr.get());
  EXPECT_EQ(0, deletes);

  // If we never invoke the Callback, it retains ownership and deletes.
  unused_callback.Reset();
  EXPECT_EQ(1, deletes);

  // Tests the Passed() function's support for rvalues.
  deletes = 0;
  DeleteCounter* counter = new DeleteCounter(&deletes);
  Callback<scoped_ptr<DeleteCounter>(void)> callback =
      Bind(&PassThru<scoped_ptr<DeleteCounter> >,
           Passed(scoped_ptr<DeleteCounter>(counter)));
  EXPECT_FALSE(ptr.get());
  EXPECT_EQ(0, deletes);

  // Check that ownership can be transferred back out.
  scoped_ptr<DeleteCounter> result = callback.Run();
  ASSERT_EQ(counter, result.get());
  EXPECT_EQ(0, deletes);

  // Resetting does not delete since ownership was transferred.
  callback.Reset();
  EXPECT_EQ(0, deletes);

  // Ensure that we actually did get ownership.
  result.reset();
  EXPECT_EQ(1, deletes);

  // Test unbound argument forwarding.
  Callback<scoped_ptr<DeleteCounter>(scoped_ptr<DeleteCounter>)> cb_unbound =
      Bind(&PassThru<scoped_ptr<DeleteCounter> >);
  ptr.reset(new DeleteCounter(&deletes));
  cb_unbound.Run(ptr.Pass());
}

// Argument Copy-constructor usage for non-reference parameters.
//   - Bound arguments are only copied once.
//   - Forwarded arguments are only copied once.
//   - Forwarded arguments with coercions are only copied twice (once for the
//     coercion, and one for the final dispatch).
TEST_F(BindTest, ArgumentCopies) {
  int copies = 0;
  int assigns = 0;

  CopyCounter counter(&copies, &assigns);

  Callback<void(void)> copy_cb =
      Bind(&VoidPolymorphic1<CopyCounter>, counter);
  EXPECT_GE(1, copies);
  EXPECT_EQ(0, assigns);

  copies = 0;
  assigns = 0;
  Callback<void(CopyCounter)> forward_cb =
      Bind(&VoidPolymorphic1<CopyCounter>);
  forward_cb.Run(counter);
  EXPECT_GE(1, copies);
  EXPECT_EQ(0, assigns);

  copies = 0;
  assigns = 0;
  DerivedCopyCounter derived(&copies, &assigns);
  Callback<void(CopyCounter)> coerce_cb =
      Bind(&VoidPolymorphic1<CopyCounter>);
  coerce_cb.Run(CopyCounter(derived));
  EXPECT_GE(2, copies);
  EXPECT_EQ(0, assigns);
}

// Callback construction and assignment tests.
//   - Construction from an InvokerStorageHolder should not cause ref/deref.
//   - Assignment from other callback should only cause one ref
//
// TODO(ajwong): Is there actually a way to test this?

#if defined(OS_WIN)
int __fastcall FastCallFunc(int n) {
  return n;
}

int __stdcall StdCallFunc(int n) {
  return n;
}

// Windows specific calling convention support.
//   - Can bind a __fastcall function.
//   - Can bind a __stdcall function.
TEST_F(BindTest, WindowsCallingConventions) {
  Callback<int(void)> fastcall_cb = Bind(&FastCallFunc, 1);
  EXPECT_EQ(1, fastcall_cb.Run());

  Callback<int(void)> stdcall_cb = Bind(&StdCallFunc, 2);
  EXPECT_EQ(2, stdcall_cb.Run());
}
#endif

#if (!defined(NDEBUG) || defined(DCHECK_ALWAYS_ON)) && GTEST_HAS_DEATH_TEST

// Test null callbacks cause a DCHECK.
TEST(BindDeathTest, NullCallback) {
  base::Callback<void(int)> null_cb;
  ASSERT_TRUE(null_cb.is_null());
  EXPECT_DEATH(base::Bind(null_cb, 42), "");
}

#endif  // (!defined(NDEBUG) || defined(DCHECK_ALWAYS_ON)) &&
        //     GTEST_HAS_DEATH_TEST

}  // namespace
}  // namespace base
