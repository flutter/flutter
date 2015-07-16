// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/template_util.h"

#include "base/basictypes.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {
namespace {

struct AStruct {};
class AClass {};
enum AnEnum {};

class Parent {};
class Child : public Parent {};

// is_pointer<Type>
COMPILE_ASSERT(!is_pointer<int>::value, IsPointer);
COMPILE_ASSERT(!is_pointer<int&>::value, IsPointer);
COMPILE_ASSERT(is_pointer<int*>::value, IsPointer);
COMPILE_ASSERT(is_pointer<const int*>::value, IsPointer);

// is_array<Type>
COMPILE_ASSERT(!is_array<int>::value, IsArray);
COMPILE_ASSERT(!is_array<int*>::value, IsArray);
COMPILE_ASSERT(!is_array<int(*)[3]>::value, IsArray);
COMPILE_ASSERT(is_array<int[]>::value, IsArray);
COMPILE_ASSERT(is_array<const int[]>::value, IsArray);
COMPILE_ASSERT(is_array<int[3]>::value, IsArray);

// is_non_const_reference<Type>
COMPILE_ASSERT(!is_non_const_reference<int>::value, IsNonConstReference);
COMPILE_ASSERT(!is_non_const_reference<const int&>::value, IsNonConstReference);
COMPILE_ASSERT(is_non_const_reference<int&>::value, IsNonConstReference);

// is_convertible<From, To>

// Extra parens needed to make preprocessor macro parsing happy. Otherwise,
// it sees the equivalent of:
//
//     (is_convertible < Child), (Parent > ::value)
//
// Silly C++.
COMPILE_ASSERT( (is_convertible<Child, Parent>::value), IsConvertible);
COMPILE_ASSERT(!(is_convertible<Parent, Child>::value), IsConvertible);
COMPILE_ASSERT(!(is_convertible<Parent, AStruct>::value), IsConvertible);
COMPILE_ASSERT( (is_convertible<int, double>::value), IsConvertible);
COMPILE_ASSERT( (is_convertible<int*, void*>::value), IsConvertible);
COMPILE_ASSERT(!(is_convertible<void*, int*>::value), IsConvertible);

// Array types are an easy corner case.  Make sure to test that
// it does indeed compile.
COMPILE_ASSERT(!(is_convertible<int[10], double>::value), IsConvertible);
COMPILE_ASSERT(!(is_convertible<double, int[10]>::value), IsConvertible);
COMPILE_ASSERT( (is_convertible<int[10], int*>::value), IsConvertible);

// is_same<Type1, Type2>
COMPILE_ASSERT(!(is_same<Child, Parent>::value), IsSame);
COMPILE_ASSERT(!(is_same<Parent, Child>::value), IsSame);
COMPILE_ASSERT( (is_same<Parent, Parent>::value), IsSame);
COMPILE_ASSERT( (is_same<int*, int*>::value), IsSame);
COMPILE_ASSERT( (is_same<int, int>::value), IsSame);
COMPILE_ASSERT( (is_same<void, void>::value), IsSame);
COMPILE_ASSERT(!(is_same<int, double>::value), IsSame);


// is_class<Type>
COMPILE_ASSERT(is_class<AStruct>::value, IsClass);
COMPILE_ASSERT(is_class<AClass>::value, IsClass);
COMPILE_ASSERT(!is_class<AnEnum>::value, IsClass);
COMPILE_ASSERT(!is_class<int>::value, IsClass);
COMPILE_ASSERT(!is_class<char*>::value, IsClass);
COMPILE_ASSERT(!is_class<int&>::value, IsClass);
COMPILE_ASSERT(!is_class<char[3]>::value, IsClass);


COMPILE_ASSERT(!is_member_function_pointer<int>::value,
               IsMemberFunctionPointer);
COMPILE_ASSERT(!is_member_function_pointer<int*>::value,
               IsMemberFunctionPointer);
COMPILE_ASSERT(!is_member_function_pointer<void*>::value,
               IsMemberFunctionPointer);
COMPILE_ASSERT(!is_member_function_pointer<AStruct>::value,
               IsMemberFunctionPointer);
COMPILE_ASSERT(!is_member_function_pointer<AStruct*>::value,
               IsMemberFunctionPointer);
COMPILE_ASSERT(!is_member_function_pointer<void(*)()>::value,
               IsMemberFunctionPointer);
COMPILE_ASSERT(!is_member_function_pointer<int(*)(int)>::value,
               IsMemberFunctionPointer);
COMPILE_ASSERT(!is_member_function_pointer<int(*)(int, int)>::value,
               IsMemberFunctionPointer);

COMPILE_ASSERT(is_member_function_pointer<void (AStruct::*)()>::value,
               IsMemberFunctionPointer);
COMPILE_ASSERT(is_member_function_pointer<void (AStruct::*)(int)>::value,
               IsMemberFunctionPointer);
COMPILE_ASSERT(is_member_function_pointer<int (AStruct::*)(int)>::value,
               IsMemberFunctionPointer);
COMPILE_ASSERT(is_member_function_pointer<int (AStruct::*)(int) const>::value,
               IsMemberFunctionPointer);
COMPILE_ASSERT(is_member_function_pointer<int (AStruct::*)(int, int)>::value,
               IsMemberFunctionPointer);

}  // namespace
}  // namespace base
