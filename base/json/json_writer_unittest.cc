// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/json/json_writer.h"
#include "base/values.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

TEST(JSONWriterTest, BasicTypes) {
  std::string output_js;

  // Test null.
  EXPECT_TRUE(JSONWriter::Write(*Value::CreateNullValue(), &output_js));
  EXPECT_EQ("null", output_js);

  // Test empty dict.
  EXPECT_TRUE(JSONWriter::Write(DictionaryValue(), &output_js));
  EXPECT_EQ("{}", output_js);

  // Test empty list.
  EXPECT_TRUE(JSONWriter::Write(ListValue(), &output_js));
  EXPECT_EQ("[]", output_js);

  // Test integer values.
  EXPECT_TRUE(JSONWriter::Write(FundamentalValue(42), &output_js));
  EXPECT_EQ("42", output_js);

  // Test boolean values.
  EXPECT_TRUE(JSONWriter::Write(FundamentalValue(true), &output_js));
  EXPECT_EQ("true", output_js);

  // Test Real values should always have a decimal or an 'e'.
  EXPECT_TRUE(JSONWriter::Write(FundamentalValue(1.0), &output_js));
  EXPECT_EQ("1.0", output_js);

  // Test Real values in the the range (-1, 1) must have leading zeros
  EXPECT_TRUE(JSONWriter::Write(FundamentalValue(0.2), &output_js));
  EXPECT_EQ("0.2", output_js);

  // Test Real values in the the range (-1, 1) must have leading zeros
  EXPECT_TRUE(JSONWriter::Write(FundamentalValue(-0.8), &output_js));
  EXPECT_EQ("-0.8", output_js);

  // Test String values.
  EXPECT_TRUE(JSONWriter::Write(StringValue("foo"), &output_js));
  EXPECT_EQ("\"foo\"", output_js);
}

TEST(JSONWriterTest, NestedTypes) {
  std::string output_js;

  // Writer unittests like empty list/dict nesting,
  // list list nesting, etc.
  DictionaryValue root_dict;
  scoped_ptr<ListValue> list(new ListValue());
  scoped_ptr<DictionaryValue> inner_dict(new DictionaryValue());
  inner_dict->SetInteger("inner int", 10);
  list->Append(inner_dict.Pass());
  list->Append(make_scoped_ptr(new ListValue()));
  list->AppendBoolean(true);
  root_dict.Set("list", list.Pass());

  // Test the pretty-printer.
  EXPECT_TRUE(JSONWriter::Write(root_dict, &output_js));
  EXPECT_EQ("{\"list\":[{\"inner int\":10},[],true]}", output_js);
  EXPECT_TRUE(JSONWriter::WriteWithOptions(
      root_dict, JSONWriter::OPTIONS_PRETTY_PRINT, &output_js));

  // The pretty-printer uses a different newline style on Windows than on
  // other platforms.
#if defined(OS_WIN)
#define JSON_NEWLINE "\r\n"
#else
#define JSON_NEWLINE "\n"
#endif
  EXPECT_EQ("{" JSON_NEWLINE
            "   \"list\": [ {" JSON_NEWLINE
            "      \"inner int\": 10" JSON_NEWLINE
            "   }, [  ], true ]" JSON_NEWLINE
            "}" JSON_NEWLINE,
            output_js);
#undef JSON_NEWLINE
}

TEST(JSONWriterTest, KeysWithPeriods) {
  std::string output_js;

  DictionaryValue period_dict;
  period_dict.SetIntegerWithoutPathExpansion("a.b", 3);
  period_dict.SetIntegerWithoutPathExpansion("c", 2);
  scoped_ptr<DictionaryValue> period_dict2(new DictionaryValue());
  period_dict2->SetIntegerWithoutPathExpansion("g.h.i.j", 1);
  period_dict.SetWithoutPathExpansion("d.e.f", period_dict2.Pass());
  EXPECT_TRUE(JSONWriter::Write(period_dict, &output_js));
  EXPECT_EQ("{\"a.b\":3,\"c\":2,\"d.e.f\":{\"g.h.i.j\":1}}", output_js);

  DictionaryValue period_dict3;
  period_dict3.SetInteger("a.b", 2);
  period_dict3.SetIntegerWithoutPathExpansion("a.b", 1);
  EXPECT_TRUE(JSONWriter::Write(period_dict3, &output_js));
  EXPECT_EQ("{\"a\":{\"b\":2},\"a.b\":1}", output_js);
}

TEST(JSONWriterTest, BinaryValues) {
  std::string output_js;

  // Binary values should return errors unless suppressed via the
  // OPTIONS_OMIT_BINARY_VALUES flag.
  scoped_ptr<Value> root(BinaryValue::CreateWithCopiedBuffer("asdf", 4));
  EXPECT_FALSE(JSONWriter::Write(*root, &output_js));
  EXPECT_TRUE(JSONWriter::WriteWithOptions(
      *root, JSONWriter::OPTIONS_OMIT_BINARY_VALUES, &output_js));
  EXPECT_TRUE(output_js.empty());

  ListValue binary_list;
  binary_list.Append(BinaryValue::CreateWithCopiedBuffer("asdf", 4));
  binary_list.Append(make_scoped_ptr(new FundamentalValue(5)));
  binary_list.Append(BinaryValue::CreateWithCopiedBuffer("asdf", 4));
  binary_list.Append(make_scoped_ptr(new FundamentalValue(2)));
  binary_list.Append(BinaryValue::CreateWithCopiedBuffer("asdf", 4));
  EXPECT_FALSE(JSONWriter::Write(binary_list, &output_js));
  EXPECT_TRUE(JSONWriter::WriteWithOptions(
      binary_list, JSONWriter::OPTIONS_OMIT_BINARY_VALUES, &output_js));
  EXPECT_EQ("[5,2]", output_js);

  DictionaryValue binary_dict;
  binary_dict.Set(
      "a", make_scoped_ptr(BinaryValue::CreateWithCopiedBuffer("asdf", 4)));
  binary_dict.SetInteger("b", 5);
  binary_dict.Set(
      "c", make_scoped_ptr(BinaryValue::CreateWithCopiedBuffer("asdf", 4)));
  binary_dict.SetInteger("d", 2);
  binary_dict.Set(
      "e", make_scoped_ptr(BinaryValue::CreateWithCopiedBuffer("asdf", 4)));
  EXPECT_FALSE(JSONWriter::Write(binary_dict, &output_js));
  EXPECT_TRUE(JSONWriter::WriteWithOptions(
      binary_dict, JSONWriter::OPTIONS_OMIT_BINARY_VALUES, &output_js));
  EXPECT_EQ("{\"b\":5,\"d\":2}", output_js);
}

TEST(JSONWriterTest, DoublesAsInts) {
  std::string output_js;

  // Test allowing a double with no fractional part to be written as an integer.
  FundamentalValue double_value(1e10);
  EXPECT_TRUE(JSONWriter::WriteWithOptions(
      double_value, JSONWriter::OPTIONS_OMIT_DOUBLE_TYPE_PRESERVATION,
      &output_js));
  EXPECT_EQ("10000000000", output_js);
}

}  // namespace base
