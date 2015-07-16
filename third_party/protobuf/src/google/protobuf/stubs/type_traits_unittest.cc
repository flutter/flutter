// Copyright (c) 2006, Google Inc.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// ----
// Author: Matt Austern

#include <google/protobuf/stubs/type_traits.h>

#include <stdlib.h>   // for exit()
#include <stdio.h>
#include <string>
#include <vector>

#include <google/protobuf/testing/googletest.h>
#include <gtest/gtest.h>

typedef int int32;
typedef long int64;

using std::string;
using std::vector;
using std::pair;


// This assertion produces errors like "error: invalid use of
// incomplete type 'struct <unnamed>::AssertTypesEq<const int, int>'"
// when it fails.
template<typename T, typename U> struct AssertTypesEq;
template<typename T> struct AssertTypesEq<T, T> {};
#define COMPILE_ASSERT_TYPES_EQ(T, U) static_cast<void>(AssertTypesEq<T, U>())

// A user-defined POD type.
struct A {
  int n_;
};

// A user-defined non-POD type with a trivial copy constructor.
class B {
 public:
  explicit B(int n) : n_(n) { }
 private:
  int n_;
};

// Another user-defined non-POD type with a trivial copy constructor.
// We will explicitly declare C to have a trivial copy constructor
// by specializing has_trivial_copy.
class C {
 public:
  explicit C(int n) : n_(n) { }
 private:
  int n_;
};

namespace google {
namespace protobuf {
namespace internal {
template<> struct has_trivial_copy<C> : true_type { };
}  // namespace internal
}  // namespace protobuf
}  // namespace google

// Another user-defined non-POD type with a trivial assignment operator.
// We will explicitly declare C to have a trivial assignment operator
// by specializing has_trivial_assign.
class D {
 public:
  explicit D(int n) : n_(n) { }
 private:
  int n_;
};

namespace google {
namespace protobuf {
namespace internal {
template<> struct has_trivial_assign<D> : true_type { };
}  // namespace internal
}  // namespace protobuf
}  // namespace google

// Another user-defined non-POD type with a trivial constructor.
// We will explicitly declare E to have a trivial constructor
// by specializing has_trivial_constructor.
class E {
 public:
  int n_;
};

namespace google {
namespace protobuf {
namespace internal {
template<> struct has_trivial_constructor<E> : true_type { };
}  // namespace internal
}  // namespace protobuf
}  // namespace google

// Another user-defined non-POD type with a trivial destructor.
// We will explicitly declare E to have a trivial destructor
// by specializing has_trivial_destructor.
class F {
 public:
  explicit F(int n) : n_(n) { }
 private:
  int n_;
};

namespace google {
namespace protobuf {
namespace internal {
template<> struct has_trivial_destructor<F> : true_type { };
}  // namespace internal
}  // namespace protobuf
}  // namespace google

enum G {};

union H {};

class I {
 public:
  operator int() const;
};

class J {
 private:
  operator int() const;
};

namespace google {
namespace protobuf {
namespace internal {
namespace {

// A base class and a derived class that inherits from it, used for
// testing conversion type traits.
class Base {
 public:
  virtual ~Base() { }
};

class Derived : public Base {
};

TEST(TypeTraitsTest, TestIsInteger) {
  // Verify that is_integral is true for all integer types.
  EXPECT_TRUE(is_integral<bool>::value);
  EXPECT_TRUE(is_integral<char>::value);
  EXPECT_TRUE(is_integral<unsigned char>::value);
  EXPECT_TRUE(is_integral<signed char>::value);
  EXPECT_TRUE(is_integral<wchar_t>::value);
  EXPECT_TRUE(is_integral<int>::value);
  EXPECT_TRUE(is_integral<unsigned int>::value);
  EXPECT_TRUE(is_integral<short>::value);
  EXPECT_TRUE(is_integral<unsigned short>::value);
  EXPECT_TRUE(is_integral<long>::value);
  EXPECT_TRUE(is_integral<unsigned long>::value);

  // Verify that is_integral is false for a few non-integer types.
  EXPECT_FALSE(is_integral<void>::value);
  EXPECT_FALSE(is_integral<float>::value);
  EXPECT_FALSE(is_integral<string>::value);
  EXPECT_FALSE(is_integral<int*>::value);
  EXPECT_FALSE(is_integral<A>::value);
  EXPECT_FALSE((is_integral<pair<int, int> >::value));

  // Verify that cv-qualified integral types are still integral, and
  // cv-qualified non-integral types are still non-integral.
  EXPECT_TRUE(is_integral<const char>::value);
  EXPECT_TRUE(is_integral<volatile bool>::value);
  EXPECT_TRUE(is_integral<const volatile unsigned int>::value);
  EXPECT_FALSE(is_integral<const float>::value);
  EXPECT_FALSE(is_integral<int* volatile>::value);
  EXPECT_FALSE(is_integral<const volatile string>::value);
}

TEST(TypeTraitsTest, TestIsFloating) {
  // Verify that is_floating_point is true for all floating-point types.
  EXPECT_TRUE(is_floating_point<float>::value);
  EXPECT_TRUE(is_floating_point<double>::value);
  EXPECT_TRUE(is_floating_point<long double>::value);

  // Verify that is_floating_point is false for a few non-float types.
  EXPECT_FALSE(is_floating_point<void>::value);
  EXPECT_FALSE(is_floating_point<long>::value);
  EXPECT_FALSE(is_floating_point<string>::value);
  EXPECT_FALSE(is_floating_point<float*>::value);
  EXPECT_FALSE(is_floating_point<A>::value);
  EXPECT_FALSE((is_floating_point<pair<int, int> >::value));

  // Verify that cv-qualified floating point types are still floating, and
  // cv-qualified non-floating types are still non-floating.
  EXPECT_TRUE(is_floating_point<const float>::value);
  EXPECT_TRUE(is_floating_point<volatile double>::value);
  EXPECT_TRUE(is_floating_point<const volatile long double>::value);
  EXPECT_FALSE(is_floating_point<const int>::value);
  EXPECT_FALSE(is_floating_point<volatile string>::value);
  EXPECT_FALSE(is_floating_point<const volatile char>::value);
}

TEST(TypeTraitsTest, TestIsPointer) {
  // Verify that is_pointer is true for some pointer types.
  EXPECT_TRUE(is_pointer<int*>::value);
  EXPECT_TRUE(is_pointer<void*>::value);
  EXPECT_TRUE(is_pointer<string*>::value);
  EXPECT_TRUE(is_pointer<const void*>::value);
  EXPECT_TRUE(is_pointer<volatile float* const*>::value);

  // Verify that is_pointer is false for some non-pointer types.
  EXPECT_FALSE(is_pointer<void>::value);
  EXPECT_FALSE(is_pointer<float&>::value);
  EXPECT_FALSE(is_pointer<long>::value);
  EXPECT_FALSE(is_pointer<vector<int*> >::value);
  EXPECT_FALSE(is_pointer<int[5]>::value);

  // A function pointer is a pointer, but a function type, or a function
  // reference type, is not.
  EXPECT_TRUE(is_pointer<int (*)(int x)>::value);
  EXPECT_FALSE(is_pointer<void(char x)>::value);
  EXPECT_FALSE(is_pointer<double (&)(string x)>::value);

  // Verify that is_pointer<T> is true for some cv-qualified pointer types,
  // and false for some cv-qualified non-pointer types.
  EXPECT_TRUE(is_pointer<int* const>::value);
  EXPECT_TRUE(is_pointer<const void* volatile>::value);
  EXPECT_TRUE(is_pointer<char** const volatile>::value);
  EXPECT_FALSE(is_pointer<const int>::value);
  EXPECT_FALSE(is_pointer<volatile vector<int*> >::value);
  EXPECT_FALSE(is_pointer<const volatile double>::value);
}

TEST(TypeTraitsTest, TestIsEnum) {
// is_enum isn't supported on MSVC or gcc 3.x
#if !defined(_MSC_VER) && !(defined(__GNUC__) && __GNUC__ <= 3)
  // Verify that is_enum is true for enum types.
  EXPECT_TRUE(is_enum<G>::value);
  EXPECT_TRUE(is_enum<const G>::value);
  EXPECT_TRUE(is_enum<volatile G>::value);
  EXPECT_TRUE(is_enum<const volatile G>::value);

  // Verify that is_enum is false for a few non-enum types.
  EXPECT_FALSE(is_enum<void>::value);
  EXPECT_FALSE(is_enum<G&>::value);
  EXPECT_FALSE(is_enum<G[1]>::value);
  EXPECT_FALSE(is_enum<const G[1]>::value);
  EXPECT_FALSE(is_enum<G[]>::value);
  EXPECT_FALSE(is_enum<int>::value);
  EXPECT_FALSE(is_enum<float>::value);
  EXPECT_FALSE(is_enum<A>::value);
  EXPECT_FALSE(is_enum<A*>::value);
  EXPECT_FALSE(is_enum<const A>::value);
  EXPECT_FALSE(is_enum<H>::value);
  EXPECT_FALSE(is_enum<I>::value);
  EXPECT_FALSE(is_enum<J>::value);
  EXPECT_FALSE(is_enum<void()>::value);
  EXPECT_FALSE(is_enum<void(*)()>::value);
  EXPECT_FALSE(is_enum<int A::*>::value);
  EXPECT_FALSE(is_enum<void (A::*)()>::value);
#endif
}

TEST(TypeTraitsTest, TestIsReference) {
  // Verifies that is_reference is true for all reference types.
  typedef float& RefFloat;
  EXPECT_TRUE(is_reference<float&>::value);
  EXPECT_TRUE(is_reference<const int&>::value);
  EXPECT_TRUE(is_reference<const int*&>::value);
  EXPECT_TRUE(is_reference<int (&)(bool)>::value);
  EXPECT_TRUE(is_reference<RefFloat>::value);
  EXPECT_TRUE(is_reference<const RefFloat>::value);
  EXPECT_TRUE(is_reference<volatile RefFloat>::value);
  EXPECT_TRUE(is_reference<const volatile RefFloat>::value);


  // Verifies that is_reference is false for all non-reference types.
  EXPECT_FALSE(is_reference<float>::value);
  EXPECT_FALSE(is_reference<const float>::value);
  EXPECT_FALSE(is_reference<volatile float>::value);
  EXPECT_FALSE(is_reference<const volatile float>::value);
  EXPECT_FALSE(is_reference<const int*>::value);
  EXPECT_FALSE(is_reference<int()>::value);
  EXPECT_FALSE(is_reference<void(*)(const char&)>::value);
}

TEST(TypeTraitsTest, TestAddReference) {
  COMPILE_ASSERT_TYPES_EQ(int&, add_reference<int>::type);
  COMPILE_ASSERT_TYPES_EQ(const int&, add_reference<const int>::type);
  COMPILE_ASSERT_TYPES_EQ(volatile int&,
                          add_reference<volatile int>::type);
  COMPILE_ASSERT_TYPES_EQ(const volatile int&,
                          add_reference<const volatile int>::type);
  COMPILE_ASSERT_TYPES_EQ(int&, add_reference<int&>::type);
  COMPILE_ASSERT_TYPES_EQ(const int&, add_reference<const int&>::type);
  COMPILE_ASSERT_TYPES_EQ(volatile int&,
                          add_reference<volatile int&>::type);
  COMPILE_ASSERT_TYPES_EQ(const volatile int&,
                          add_reference<const volatile int&>::type);
}

TEST(TypeTraitsTest, TestIsPod) {
  // Verify that arithmetic types and pointers are marked as PODs.
  EXPECT_TRUE(is_pod<bool>::value);
  EXPECT_TRUE(is_pod<char>::value);
  EXPECT_TRUE(is_pod<unsigned char>::value);
  EXPECT_TRUE(is_pod<signed char>::value);
  EXPECT_TRUE(is_pod<wchar_t>::value);
  EXPECT_TRUE(is_pod<int>::value);
  EXPECT_TRUE(is_pod<unsigned int>::value);
  EXPECT_TRUE(is_pod<short>::value);
  EXPECT_TRUE(is_pod<unsigned short>::value);
  EXPECT_TRUE(is_pod<long>::value);
  EXPECT_TRUE(is_pod<unsigned long>::value);
  EXPECT_TRUE(is_pod<float>::value);
  EXPECT_TRUE(is_pod<double>::value);
  EXPECT_TRUE(is_pod<long double>::value);
  EXPECT_TRUE(is_pod<string*>::value);
  EXPECT_TRUE(is_pod<A*>::value);
  EXPECT_TRUE(is_pod<const B*>::value);
  EXPECT_TRUE(is_pod<C**>::value);
  EXPECT_TRUE(is_pod<const int>::value);
  EXPECT_TRUE(is_pod<char* volatile>::value);
  EXPECT_TRUE(is_pod<const volatile double>::value);
#if !defined(_MSC_VER) && !(defined(__GNUC__) && __GNUC__ <= 3)
  EXPECT_TRUE(is_pod<G>::value);
  EXPECT_TRUE(is_pod<const G>::value);
  EXPECT_TRUE(is_pod<volatile G>::value);
  EXPECT_TRUE(is_pod<const volatile G>::value);
#endif

  // Verify that some non-POD types are not marked as PODs.
  EXPECT_FALSE(is_pod<void>::value);
  EXPECT_FALSE(is_pod<string>::value);
  EXPECT_FALSE((is_pod<pair<int, int> >::value));
  EXPECT_FALSE(is_pod<A>::value);
  EXPECT_FALSE(is_pod<B>::value);
  EXPECT_FALSE(is_pod<C>::value);
  EXPECT_FALSE(is_pod<const string>::value);
  EXPECT_FALSE(is_pod<volatile A>::value);
  EXPECT_FALSE(is_pod<const volatile B>::value);
}

TEST(TypeTraitsTest, TestHasTrivialConstructor) {
  // Verify that arithmetic types and pointers have trivial constructors.
  EXPECT_TRUE(has_trivial_constructor<bool>::value);
  EXPECT_TRUE(has_trivial_constructor<char>::value);
  EXPECT_TRUE(has_trivial_constructor<unsigned char>::value);
  EXPECT_TRUE(has_trivial_constructor<signed char>::value);
  EXPECT_TRUE(has_trivial_constructor<wchar_t>::value);
  EXPECT_TRUE(has_trivial_constructor<int>::value);
  EXPECT_TRUE(has_trivial_constructor<unsigned int>::value);
  EXPECT_TRUE(has_trivial_constructor<short>::value);
  EXPECT_TRUE(has_trivial_constructor<unsigned short>::value);
  EXPECT_TRUE(has_trivial_constructor<long>::value);
  EXPECT_TRUE(has_trivial_constructor<unsigned long>::value);
  EXPECT_TRUE(has_trivial_constructor<float>::value);
  EXPECT_TRUE(has_trivial_constructor<double>::value);
  EXPECT_TRUE(has_trivial_constructor<long double>::value);
  EXPECT_TRUE(has_trivial_constructor<string*>::value);
  EXPECT_TRUE(has_trivial_constructor<A*>::value);
  EXPECT_TRUE(has_trivial_constructor<const B*>::value);
  EXPECT_TRUE(has_trivial_constructor<C**>::value);

  // Verify that pairs and arrays of such types have trivial
  // constructors.
  typedef int int10[10];
  EXPECT_TRUE((has_trivial_constructor<pair<int, char*> >::value));
  EXPECT_TRUE(has_trivial_constructor<int10>::value);

  // Verify that pairs of types without trivial constructors
  // are not marked as trivial.
  EXPECT_FALSE((has_trivial_constructor<pair<int, string> >::value));
  EXPECT_FALSE((has_trivial_constructor<pair<string, int> >::value));

  // Verify that types without trivial constructors are
  // correctly marked as such.
  EXPECT_FALSE(has_trivial_constructor<string>::value);
  EXPECT_FALSE(has_trivial_constructor<vector<int> >::value);

  // Verify that E, which we have declared to have a trivial
  // constructor, is correctly marked as such.
  EXPECT_TRUE(has_trivial_constructor<E>::value);
}

TEST(TypeTraitsTest, TestHasTrivialCopy) {
  // Verify that arithmetic types and pointers have trivial copy
  // constructors.
  EXPECT_TRUE(has_trivial_copy<bool>::value);
  EXPECT_TRUE(has_trivial_copy<char>::value);
  EXPECT_TRUE(has_trivial_copy<unsigned char>::value);
  EXPECT_TRUE(has_trivial_copy<signed char>::value);
  EXPECT_TRUE(has_trivial_copy<wchar_t>::value);
  EXPECT_TRUE(has_trivial_copy<int>::value);
  EXPECT_TRUE(has_trivial_copy<unsigned int>::value);
  EXPECT_TRUE(has_trivial_copy<short>::value);
  EXPECT_TRUE(has_trivial_copy<unsigned short>::value);
  EXPECT_TRUE(has_trivial_copy<long>::value);
  EXPECT_TRUE(has_trivial_copy<unsigned long>::value);
  EXPECT_TRUE(has_trivial_copy<float>::value);
  EXPECT_TRUE(has_trivial_copy<double>::value);
  EXPECT_TRUE(has_trivial_copy<long double>::value);
  EXPECT_TRUE(has_trivial_copy<string*>::value);
  EXPECT_TRUE(has_trivial_copy<A*>::value);
  EXPECT_TRUE(has_trivial_copy<const B*>::value);
  EXPECT_TRUE(has_trivial_copy<C**>::value);

  // Verify that pairs and arrays of such types have trivial
  // copy constructors.
  typedef int int10[10];
  EXPECT_TRUE((has_trivial_copy<pair<int, char*> >::value));
  EXPECT_TRUE(has_trivial_copy<int10>::value);

  // Verify that pairs of types without trivial copy constructors
  // are not marked as trivial.
  EXPECT_FALSE((has_trivial_copy<pair<int, string> >::value));
  EXPECT_FALSE((has_trivial_copy<pair<string, int> >::value));

  // Verify that types without trivial copy constructors are
  // correctly marked as such.
  EXPECT_FALSE(has_trivial_copy<string>::value);
  EXPECT_FALSE(has_trivial_copy<vector<int> >::value);

  // Verify that C, which we have declared to have a trivial
  // copy constructor, is correctly marked as such.
  EXPECT_TRUE(has_trivial_copy<C>::value);
}

TEST(TypeTraitsTest, TestHasTrivialAssign) {
  // Verify that arithmetic types and pointers have trivial assignment
  // operators.
  EXPECT_TRUE(has_trivial_assign<bool>::value);
  EXPECT_TRUE(has_trivial_assign<char>::value);
  EXPECT_TRUE(has_trivial_assign<unsigned char>::value);
  EXPECT_TRUE(has_trivial_assign<signed char>::value);
  EXPECT_TRUE(has_trivial_assign<wchar_t>::value);
  EXPECT_TRUE(has_trivial_assign<int>::value);
  EXPECT_TRUE(has_trivial_assign<unsigned int>::value);
  EXPECT_TRUE(has_trivial_assign<short>::value);
  EXPECT_TRUE(has_trivial_assign<unsigned short>::value);
  EXPECT_TRUE(has_trivial_assign<long>::value);
  EXPECT_TRUE(has_trivial_assign<unsigned long>::value);
  EXPECT_TRUE(has_trivial_assign<float>::value);
  EXPECT_TRUE(has_trivial_assign<double>::value);
  EXPECT_TRUE(has_trivial_assign<long double>::value);
  EXPECT_TRUE(has_trivial_assign<string*>::value);
  EXPECT_TRUE(has_trivial_assign<A*>::value);
  EXPECT_TRUE(has_trivial_assign<const B*>::value);
  EXPECT_TRUE(has_trivial_assign<C**>::value);

  // Verify that pairs and arrays of such types have trivial
  // assignment operators.
  typedef int int10[10];
  EXPECT_TRUE((has_trivial_assign<pair<int, char*> >::value));
  EXPECT_TRUE(has_trivial_assign<int10>::value);

  // Verify that pairs of types without trivial assignment operators
  // are not marked as trivial.
  EXPECT_FALSE((has_trivial_assign<pair<int, string> >::value));
  EXPECT_FALSE((has_trivial_assign<pair<string, int> >::value));

  // Verify that types without trivial assignment operators are
  // correctly marked as such.
  EXPECT_FALSE(has_trivial_assign<string>::value);
  EXPECT_FALSE(has_trivial_assign<vector<int> >::value);

  // Verify that D, which we have declared to have a trivial
  // assignment operator, is correctly marked as such.
  EXPECT_TRUE(has_trivial_assign<D>::value);
}

TEST(TypeTraitsTest, TestHasTrivialDestructor) {
  // Verify that arithmetic types and pointers have trivial destructors.
  EXPECT_TRUE(has_trivial_destructor<bool>::value);
  EXPECT_TRUE(has_trivial_destructor<char>::value);
  EXPECT_TRUE(has_trivial_destructor<unsigned char>::value);
  EXPECT_TRUE(has_trivial_destructor<signed char>::value);
  EXPECT_TRUE(has_trivial_destructor<wchar_t>::value);
  EXPECT_TRUE(has_trivial_destructor<int>::value);
  EXPECT_TRUE(has_trivial_destructor<unsigned int>::value);
  EXPECT_TRUE(has_trivial_destructor<short>::value);
  EXPECT_TRUE(has_trivial_destructor<unsigned short>::value);
  EXPECT_TRUE(has_trivial_destructor<long>::value);
  EXPECT_TRUE(has_trivial_destructor<unsigned long>::value);
  EXPECT_TRUE(has_trivial_destructor<float>::value);
  EXPECT_TRUE(has_trivial_destructor<double>::value);
  EXPECT_TRUE(has_trivial_destructor<long double>::value);
  EXPECT_TRUE(has_trivial_destructor<string*>::value);
  EXPECT_TRUE(has_trivial_destructor<A*>::value);
  EXPECT_TRUE(has_trivial_destructor<const B*>::value);
  EXPECT_TRUE(has_trivial_destructor<C**>::value);

  // Verify that pairs and arrays of such types have trivial
  // destructors.
  typedef int int10[10];
  EXPECT_TRUE((has_trivial_destructor<pair<int, char*> >::value));
  EXPECT_TRUE(has_trivial_destructor<int10>::value);

  // Verify that pairs of types without trivial destructors
  // are not marked as trivial.
  EXPECT_FALSE((has_trivial_destructor<pair<int, string> >::value));
  EXPECT_FALSE((has_trivial_destructor<pair<string, int> >::value));

  // Verify that types without trivial destructors are
  // correctly marked as such.
  EXPECT_FALSE(has_trivial_destructor<string>::value);
  EXPECT_FALSE(has_trivial_destructor<vector<int> >::value);

  // Verify that F, which we have declared to have a trivial
  // destructor, is correctly marked as such.
  EXPECT_TRUE(has_trivial_destructor<F>::value);
}

// Tests remove_pointer.
TEST(TypeTraitsTest, TestRemovePointer) {
  COMPILE_ASSERT_TYPES_EQ(int, remove_pointer<int>::type);
  COMPILE_ASSERT_TYPES_EQ(int, remove_pointer<int*>::type);
  COMPILE_ASSERT_TYPES_EQ(const int, remove_pointer<const int*>::type);
  COMPILE_ASSERT_TYPES_EQ(int, remove_pointer<int* const>::type);
  COMPILE_ASSERT_TYPES_EQ(int, remove_pointer<int* volatile>::type);
}

TEST(TypeTraitsTest, TestRemoveConst) {
  COMPILE_ASSERT_TYPES_EQ(int, remove_const<int>::type);
  COMPILE_ASSERT_TYPES_EQ(int, remove_const<const int>::type);
  COMPILE_ASSERT_TYPES_EQ(int *, remove_const<int * const>::type);
  // TR1 examples.
  COMPILE_ASSERT_TYPES_EQ(const int *, remove_const<const int *>::type);
  COMPILE_ASSERT_TYPES_EQ(volatile int,
                          remove_const<const volatile int>::type);
}

TEST(TypeTraitsTest, TestRemoveVolatile) {
  COMPILE_ASSERT_TYPES_EQ(int, remove_volatile<int>::type);
  COMPILE_ASSERT_TYPES_EQ(int, remove_volatile<volatile int>::type);
  COMPILE_ASSERT_TYPES_EQ(int *, remove_volatile<int * volatile>::type);
  // TR1 examples.
  COMPILE_ASSERT_TYPES_EQ(volatile int *,
                          remove_volatile<volatile int *>::type);
  COMPILE_ASSERT_TYPES_EQ(const int,
                          remove_volatile<const volatile int>::type);
}

TEST(TypeTraitsTest, TestRemoveCV) {
  COMPILE_ASSERT_TYPES_EQ(int, remove_cv<int>::type);
  COMPILE_ASSERT_TYPES_EQ(int, remove_cv<volatile int>::type);
  COMPILE_ASSERT_TYPES_EQ(int, remove_cv<const int>::type);
  COMPILE_ASSERT_TYPES_EQ(int *, remove_cv<int * const volatile>::type);
  // TR1 examples.
  COMPILE_ASSERT_TYPES_EQ(const volatile int *,
                          remove_cv<const volatile int *>::type);
  COMPILE_ASSERT_TYPES_EQ(int,
                          remove_cv<const volatile int>::type);
}

TEST(TypeTraitsTest, TestRemoveReference) {
  COMPILE_ASSERT_TYPES_EQ(int, remove_reference<int>::type);
  COMPILE_ASSERT_TYPES_EQ(int, remove_reference<int&>::type);
  COMPILE_ASSERT_TYPES_EQ(const int, remove_reference<const int&>::type);
  COMPILE_ASSERT_TYPES_EQ(int*, remove_reference<int * &>::type);
}

TEST(TypeTraitsTest, TestIsSame) {
  EXPECT_TRUE((is_same<int32, int32>::value));
  EXPECT_FALSE((is_same<int32, int64>::value));
  EXPECT_FALSE((is_same<int64, int32>::value));
  EXPECT_FALSE((is_same<int, const int>::value));

  EXPECT_TRUE((is_same<void, void>::value));
  EXPECT_FALSE((is_same<void, int>::value));
  EXPECT_FALSE((is_same<int, void>::value));

  EXPECT_TRUE((is_same<int*, int*>::value));
  EXPECT_TRUE((is_same<void*, void*>::value));
  EXPECT_FALSE((is_same<int*, void*>::value));
  EXPECT_FALSE((is_same<void*, int*>::value));
  EXPECT_FALSE((is_same<void*, const void*>::value));
  EXPECT_FALSE((is_same<void*, void* const>::value));

  EXPECT_TRUE((is_same<Base*, Base*>::value));
  EXPECT_TRUE((is_same<Derived*, Derived*>::value));
  EXPECT_FALSE((is_same<Base*, Derived*>::value));
  EXPECT_FALSE((is_same<Derived*, Base*>::value));
}

TEST(TypeTraitsTest, TestConvertible) {
#if !defined(_MSC_VER) && !(defined(__GNUC__) && __GNUC__ <= 3)
  EXPECT_TRUE((is_convertible<int, int>::value));
  EXPECT_TRUE((is_convertible<int, long>::value));
  EXPECT_TRUE((is_convertible<long, int>::value));

  EXPECT_TRUE((is_convertible<int*, void*>::value));
  EXPECT_FALSE((is_convertible<void*, int*>::value));

  EXPECT_TRUE((is_convertible<Derived*, Base*>::value));
  EXPECT_FALSE((is_convertible<Base*, Derived*>::value));
  EXPECT_TRUE((is_convertible<Derived*, const Base*>::value));
  EXPECT_FALSE((is_convertible<const Derived*, Base*>::value));
#endif
}

}  // anonymous namespace
}  // namespace internal
}  // namespace protobuf
}  // namespace google
