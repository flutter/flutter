// Copyright (c) 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/trace_event/trace_event_argument.h"
#include "base/values.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {
namespace trace_event {

TEST(TraceEventArgumentTest, FlatDictionary) {
  scoped_refptr<TracedValue> value = new TracedValue();
  value->SetInteger("int", 2014);
  value->SetDouble("double", 0.0);
  value->SetBoolean("bool", true);
  value->SetString("string", "string");
  std::string json = "PREFIX";
  value->AppendAsTraceFormat(&json);
  EXPECT_EQ(
      "PREFIX{\"bool\":true,\"double\":0.0,\"int\":2014,\"string\":\"string\"}",
      json);
}

TEST(TraceEventArgumentTest, Hierarchy) {
  scoped_refptr<TracedValue> value = new TracedValue();
  value->SetInteger("i0", 2014);
  value->BeginDictionary("dict1");
  value->SetInteger("i1", 2014);
  value->BeginDictionary("dict2");
  value->SetBoolean("b2", false);
  value->EndDictionary();
  value->SetString("s1", "foo");
  value->EndDictionary();
  value->SetDouble("d0", 0.0);
  value->SetBoolean("b0", true);
  value->BeginArray("a1");
  value->AppendInteger(1);
  value->AppendBoolean(true);
  value->BeginDictionary();
  value->SetInteger("i2", 3);
  value->EndDictionary();
  value->EndArray();
  value->SetString("s0", "foo");
  std::string json;
  value->AppendAsTraceFormat(&json);
  EXPECT_EQ(
      "{\"a1\":[1,true,{\"i2\":3}],\"b0\":true,\"d0\":0.0,\"dict1\":{\"dict2\":"
      "{\"b2\":false},\"i1\":2014,\"s1\":\"foo\"},\"i0\":2014,\"s0\":"
      "\"foo\"}",
      json);
}

TEST(TraceEventArgumentTest, LongStrings) {
  std::string kLongString = "supercalifragilisticexpialidocious";
  std::string kLongString2 = "0123456789012345678901234567890123456789";
  char kLongString3[4096];
  for (size_t i = 0; i < sizeof(kLongString3); ++i)
    kLongString3[i] = 'a' + (i % 25);
  kLongString3[sizeof(kLongString3) - 1] = '\0';

  scoped_refptr<TracedValue> value = new TracedValue();
  value->SetString("a", "short");
  value->SetString("b", kLongString);
  value->BeginArray("c");
  value->AppendString(kLongString2);
  value->AppendString("");
  value->BeginDictionary();
  value->SetString("a", kLongString3);
  value->EndDictionary();
  value->EndArray();

  std::string json;
  value->AppendAsTraceFormat(&json);
  EXPECT_EQ("{\"a\":\"short\",\"b\":\"" + kLongString + "\",\"c\":[\"" +
                kLongString2 + "\",\"\",{\"a\":\"" + kLongString3 + "\"}]}",
            json);
}

TEST(TraceEventArgumentTest, PassBaseValue) {
  FundamentalValue int_value(42);
  FundamentalValue bool_value(true);
  FundamentalValue double_value(42.0f);

  auto dict_value = make_scoped_ptr(new DictionaryValue);
  dict_value->SetBoolean("bool", true);
  dict_value->SetInteger("int", 42);
  dict_value->SetDouble("double", 42.0f);
  dict_value->SetString("string", std::string("a") + "b");
  dict_value->SetString("string", std::string("a") + "b");

  auto list_value = make_scoped_ptr(new ListValue);
  list_value->AppendBoolean(false);
  list_value->AppendInteger(1);
  list_value->AppendString("in_list");
  list_value->Append(dict_value.Pass());

  scoped_refptr<TracedValue> value = new TracedValue();
  value->BeginDictionary("outer_dict");
  value->SetValue("inner_list", list_value.Pass());
  value->EndDictionary();

  dict_value.reset();
  list_value.reset();

  std::string json;
  value->AppendAsTraceFormat(&json);
  EXPECT_EQ(
      "{\"outer_dict\":{\"inner_list\":[false,1,\"in_list\",{\"bool\":true,"
      "\"double\":42.0,\"int\":42,\"string\":\"ab\"}]}}",
      json);
}

TEST(TraceEventArgumentTest, PassTracedValue) {
  auto dict_value = make_scoped_refptr(new TracedValue);
  dict_value->SetInteger("a", 1);

  auto nested_dict_value = make_scoped_refptr(new TracedValue);
  nested_dict_value->SetInteger("b", 2);
  nested_dict_value->BeginArray("c");
  nested_dict_value->AppendString("foo");
  nested_dict_value->EndArray();

  dict_value->SetValue("e", *nested_dict_value);

  // Check the merged result.
  std::string json;
  dict_value->AppendAsTraceFormat(&json);
  EXPECT_EQ("{\"a\":1,\"e\":{\"b\":2,\"c\":[\"foo\"]}}", json);

  // Check that the passed nestd dict was left unouthced.
  json = "";
  nested_dict_value->AppendAsTraceFormat(&json);
  EXPECT_EQ("{\"b\":2,\"c\":[\"foo\"]}", json);

  // And that it is still usable.
  nested_dict_value->SetInteger("f", 3);
  nested_dict_value->BeginDictionary("g");
  nested_dict_value->EndDictionary();
  json = "";
  nested_dict_value->AppendAsTraceFormat(&json);
  EXPECT_EQ("{\"b\":2,\"c\":[\"foo\"],\"f\":3,\"g\":{}}", json);
}

}  // namespace trace_event
}  // namespace base
