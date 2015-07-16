// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/common/common_type_converters.h"

#include "base/bind.h"
#include "base/strings/utf_string_conversions.h"
#include "mojo/public/cpp/bindings/callback.h"
#include "mojo/public/cpp/bindings/map.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "url/gurl.h"

namespace mojo {
namespace common {
namespace test {
namespace {

void ExpectEqualsStringPiece(const std::string& expected,
                             const base::StringPiece& str) {
  EXPECT_EQ(expected, str.as_string());
}

void ExpectEqualsMojoString(const std::string& expected,
                            const String& str) {
  EXPECT_EQ(expected, str.get());
}

void ExpectEqualsString16(const base::string16& expected,
                          const base::string16& actual) {
  EXPECT_EQ(expected, actual);
}

void ExpectEqualsMojoString(const base::string16& expected,
                            const String& str) {
  EXPECT_EQ(expected, str.To<base::string16>());
}

TEST(CommonTypeConvertersTest, StringPiece) {
  std::string kText("hello world");

  base::StringPiece string_piece(kText);
  String mojo_string(String::From(string_piece));

  ExpectEqualsMojoString(kText, mojo_string);
  ExpectEqualsStringPiece(kText, mojo_string.To<base::StringPiece>());

  // Test implicit construction and conversion:
  ExpectEqualsMojoString(kText, String::From(string_piece));
  ExpectEqualsStringPiece(kText, mojo_string.To<base::StringPiece>());

  // Test null String:
  base::StringPiece empty_string_piece = String().To<base::StringPiece>();
  EXPECT_TRUE(empty_string_piece.empty());
}

TEST(CommonTypeConvertersTest, String16) {
  const base::string16 string16(base::ASCIIToUTF16("hello world"));
  const String mojo_string(String::From(string16));

  ExpectEqualsMojoString(string16, mojo_string);
  EXPECT_EQ(string16, mojo_string.To<base::string16>());

  // Test implicit construction and conversion:
  ExpectEqualsMojoString(string16, String::From(string16));
  ExpectEqualsString16(string16, mojo_string.To<base::string16>());

  // Test empty string conversion.
  ExpectEqualsMojoString(base::string16(), String::From(base::string16()));
}

TEST(CommonTypeConvertersTest, URL) {
  GURL url("mojo:foo");
  String mojo_string(String::From(url));

  ASSERT_EQ(url.spec(), mojo_string);
  EXPECT_EQ(url.spec(), mojo_string.To<GURL>().spec());
  EXPECT_EQ(url.spec(), String::From(url));

  GURL invalid = String().To<GURL>();
  ASSERT_TRUE(invalid.spec().empty());

  String string_from_invalid = String::From(invalid);
  EXPECT_FALSE(string_from_invalid.is_null());
  ASSERT_EQ(0U, string_from_invalid.size());
}

TEST(CommonTypeConvertersTest, ArrayUint8ToStdString) {
  Array<uint8_t> data(4);
  data[0] = 'd';
  data[1] = 'a';
  data[2] = 't';
  data[3] = 'a';

  EXPECT_EQ("data", data.To<std::string>());
}

TEST(CommonTypeConvertersTest, StdStringToArrayUint8) {
  std::string input("data");
  Array<uint8_t> data = Array<uint8_t>::From(input);

  ASSERT_EQ(4ul, data.size());
  EXPECT_EQ('d', data[0]);
  EXPECT_EQ('a', data[1]);
  EXPECT_EQ('t', data[2]);
  EXPECT_EQ('a', data[3]);
}

struct RunnableNoArgs {
  RunnableNoArgs(int* calls) : calls(calls) {}
  void Run() const { (*calls)++; }

  int* calls;
};

TEST(CommonTypeConvertersTest, BaseBindToMojoCallbackNoParams) {
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

TEST(CommonTypeConvertersTest, BaseBindToMojoCallbackPrimitiveParam) {
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
  void Run(const String& s) const { (*calls)++; }

  int* calls;
};

TEST(CommonTypeConvertersTest, BaseBindToMojoCallbackMojoStringParam) {
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

using ExampleMoveOnlyType = Map<int, int>;

struct RunnableOneMoveOnlyParam {
  explicit RunnableOneMoveOnlyParam(int* calls) : calls(calls) {}

  void Run(ExampleMoveOnlyType m) const { (*calls)++; }
  int* calls;
};

TEST(CommonTypeConvertersTest, BaseBindToMoveOnlyParam) {
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
}  // namespace test
}  // namespace common
}  // namespace mojo
