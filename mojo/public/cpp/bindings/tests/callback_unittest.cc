// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/bindings/callback.h"
#include "mojo/public/cpp/bindings/map.h"
#include "mojo/public/cpp/bindings/string.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace test {
namespace {

struct RunnableNoArgs {
  explicit RunnableNoArgs(int* calls) : calls(calls) {}

  void Run() const { (*calls)++; }
  int* calls;
};

struct RunnableOneArg {
  explicit RunnableOneArg(int* calls) : calls(calls) {}

  void Run(int increment) const { (*calls) += increment; }

  int* calls;
};

struct RunnableStringArgByConstRef {
  explicit RunnableStringArgByConstRef(int* calls) : calls(calls) {}

  void Run(const String& s) const { (*calls)++; }

  int* calls;
};

using ExampleMoveOnlyType = Map<int, int>;

struct RunnableMoveOnlyParam {
  explicit RunnableMoveOnlyParam(int* calls) : calls(calls) {}

  void Run(ExampleMoveOnlyType m) const { (*calls)++; }

  int* calls;
};

int* g_calls = nullptr;

void FunctionNoArgs() {
  (*g_calls)++;
}

void FunctionOneArg(int increment) {
  (*g_calls) += increment;
}

void FunctionStringArgByConstRef(const String& s) {
  (*g_calls)++;
}

void FunctionMoveOnlyType(ExampleMoveOnlyType m) {
  (*g_calls)++;
}

static_assert(!internal::HasCompatibleCallOperator<RunnableNoArgs>::value,
              "HasCompatibleCallOperator<Runnable>");
static_assert(!internal::HasCompatibleCallOperator<RunnableOneArg, int>::value,
              "HasCompatibleCallOperator<RunnableOneArg, int>");
static_assert(!internal::HasCompatibleCallOperator<RunnableStringArgByConstRef,
                                                   String>::value,
              "HasCompatibleCallOperator<RunnableStringArgByConstRef, String>");
static_assert(!internal::HasCompatibleCallOperator<RunnableMoveOnlyParam,
                                                   ExampleMoveOnlyType>::value,
              "HasCompatibleCallOperator<RunnableMoveOnlyParam, String>");

auto lambda_one = []() {};
static_assert(internal::HasCompatibleCallOperator<decltype(lambda_one)>::value,
              "HasCompatibleCallOperator<lambda []() {}>");

auto lambda_two = [](int x) {};
static_assert(
    internal::HasCompatibleCallOperator<decltype(lambda_two), int>::value,
    "HasCompatibleCallOperator<lambda [](int x) {}, int>");

auto lambda_three = [](const String& s) {};
static_assert(
    internal::HasCompatibleCallOperator<decltype(lambda_three), String>::value,
    "HasCompatibleCallOperator<lambda [](const String& s) {}, String>");

auto lambda_four = [](ExampleMoveOnlyType m) {};
static_assert(internal::HasCompatibleCallOperator<decltype(lambda_four),
                                                  ExampleMoveOnlyType>::value,
              "HasCompatibleCallOperator<lambda [](ExampleMoveOnlyType) {}, "
              "ExampleMoveOnlyType>");

// Tests constructing and invoking a mojo::Callback from objects with a
// compatible Run() method (called 'runnables'), from lambdas, and from function
// pointers.
TEST(Callback, Create) {
  int calls = 0;

  RunnableNoArgs f(&calls);
  // Construct from a runnable object.
  mojo::Callback<void()> cb = f;
  cb.Run();
  EXPECT_EQ(1, calls);

  // Construct from a parameterless lambda that captures one variable.
  cb = [&calls]() { calls++; };
  cb.Run();
  EXPECT_EQ(2, calls);

  // Construct from a runnable object with one primitive parameter.
  mojo::Callback<void(int)> cb_with_param = RunnableOneArg(&calls);
  cb_with_param.Run(1);
  EXPECT_EQ(3, calls);

  // Construct from a lambda that takes one parameter and captures one variable.
  cb_with_param = [&calls](int increment) { calls += increment; };
  cb_with_param.Run(1);
  EXPECT_EQ(4, calls);

  // Construct from a runnable object with one string parameter.
  mojo::Callback<void(String)> cb_with_string_param =
      RunnableStringArgByConstRef(&calls);
  cb_with_string_param.Run(String("hello world"));
  EXPECT_EQ(5, calls);

  // Construct from a lambda that takes one string parameter.
  cb_with_string_param = [&calls](const String& s) { calls++; };
  cb_with_string_param.Run(String("world"));
  EXPECT_EQ(6, calls);

  ExampleMoveOnlyType m;
  mojo::Callback<void(ExampleMoveOnlyType)> cb_with_move_only_param =
      RunnableMoveOnlyParam(&calls);
  cb_with_move_only_param.Run(m.Clone());
  EXPECT_EQ(7, calls);

  cb_with_move_only_param = [&calls](ExampleMoveOnlyType m) { calls++; };
  cb_with_move_only_param.Run(m.Clone());
  EXPECT_EQ(8, calls);

  // Construct from a function pointer.
  g_calls = &calls;

  cb = &FunctionNoArgs;
  cb.Run();
  EXPECT_EQ(9, calls);

  cb_with_param = &FunctionOneArg;
  cb_with_param.Run(1);
  EXPECT_EQ(10, calls);

  cb_with_string_param = &FunctionStringArgByConstRef;
  cb_with_string_param.Run(String("hello"));
  EXPECT_EQ(11, calls);

  cb_with_move_only_param = &FunctionMoveOnlyType;
  cb_with_move_only_param.Run(m.Clone());
  EXPECT_EQ(12, calls);

  g_calls = nullptr;
}

bool g_overloaded_function_with_int_param_called = false;

void OverloadedFunction(int param) {
  g_overloaded_function_with_int_param_called = true;
}

bool g_overloaded_function_with_double_param_called = false;

void OverloadedFunction(double param) {
  g_overloaded_function_with_double_param_called = true;
}

// Tests constructing and invoking a mojo::Callback from pointers to overloaded
// functions.
TEST(Callback, CreateFromOverloadedFunctionPtr) {
  g_overloaded_function_with_int_param_called = false;
  mojo::Callback<void(int)> cb_with_int_param = &OverloadedFunction;
  cb_with_int_param.Run(123);
  EXPECT_TRUE(g_overloaded_function_with_int_param_called);
  g_overloaded_function_with_int_param_called = false;

  g_overloaded_function_with_double_param_called = false;
  mojo::Callback<void(double)> cb_with_double_param = &OverloadedFunction;
  cb_with_double_param.Run(123);
  EXPECT_TRUE(g_overloaded_function_with_double_param_called);
  g_overloaded_function_with_double_param_called = false;
}

}  // namespace
}  // namespace test
}  // namespace mojo
