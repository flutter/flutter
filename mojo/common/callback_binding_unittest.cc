// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/bind.h"
#include "mojo/public/cpp/bindings/callback.h"
#include "mojo/public/cpp/bindings/map.h"
#include "mojo/public/cpp/bindings/string.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace {

struct RunnableNoArgs {
  RunnableNoArgs(int* calls) : calls(calls) {}
  void Run() const { (*calls)++; }

  int* calls;
};

TEST(CallbackBindingTest, BaseBindToMojoCallbackNoParams) {
  mojo::Callback<void()> cb;
  int calls = 0;
  RunnableNoArgs r(&calls);
  cb = r;
  cb.Run();
  EXPECT_EQ(1, calls);

  cb = base::Bind(&RunnableNoArgs::Run, base::Unretained(&r));
  cb.Run();
  EXPECT_EQ(2, calls);
}

struct RunnableOnePrimitiveArg {
  explicit RunnableOnePrimitiveArg(int* calls) : calls(calls) {}
  void Run(int a) const { (*calls)++; }

  int* calls;
};

TEST(CallbackBindingTest, BaseBindToMojoCallbackPrimitiveParam) {
  mojo::Callback<void(int)> mojo_callback;
  int calls = 0;
  RunnableOnePrimitiveArg r(&calls);
  mojo_callback = r;
  mojo_callback.Run(0);
  EXPECT_EQ(1, calls);

  base::Callback<void(int)> base_callback =
      base::Bind(&RunnableOnePrimitiveArg::Run, base::Unretained(&r));
  mojo_callback = base_callback;
  mojo_callback.Run(0);
  EXPECT_EQ(2, calls);
}

struct RunnableOneMojoStringParam {
  explicit RunnableOneMojoStringParam(int* calls) : calls(calls) {}
  void Run(const mojo::String& s) const { (*calls)++; }

  int* calls;
};

TEST(CallbackBindingTest, BaseBindToMojoCallbackMojoStringParam) {
  // The mojo type is a callback on mojo::String, but it'll expect to invoke
  // callbacks with a parameter of type 'const Mojo::String&'.
  mojo::Callback<void(mojo::String)> mojo_callback;
  int calls = 0;
  RunnableOneMojoStringParam r(&calls);
  mojo_callback = r;
  mojo_callback.Run(0);
  EXPECT_EQ(1, calls);

  base::Callback<void(const mojo::String&)> base_callback =
      base::Bind(&RunnableOneMojoStringParam::Run, base::Unretained(&r));
  mojo_callback = base_callback;
  mojo_callback.Run(0);
  EXPECT_EQ(2, calls);
}

using ExampleMoveOnlyType = mojo::Map<int, int>;

struct RunnableOneMoveOnlyParam {
  explicit RunnableOneMoveOnlyParam(int* calls) : calls(calls) {}

  void Run(ExampleMoveOnlyType m) const { (*calls)++; }
  int* calls;
};

TEST(CallbackBindingTest, BaseBindToMoveOnlyParam) {
  mojo::Callback<void(ExampleMoveOnlyType)> mojo_callback;
  int calls = 0;
  RunnableOneMoveOnlyParam r(&calls);
  mojo_callback = r;
  ExampleMoveOnlyType m;
  mojo_callback.Run(m.Clone());
  EXPECT_EQ(1, calls);

  base::Callback<void(ExampleMoveOnlyType)> base_callback =
      base::Bind(&RunnableOneMoveOnlyParam::Run, base::Unretained(&r));
  mojo_callback = base_callback;
  mojo_callback.Run(m.Clone());
  EXPECT_EQ(2, calls);
}

}  // namespace
