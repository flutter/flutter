// Copyright (c) 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/trace_event/trace_event_argument.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {
namespace trace_event {

TEST(TraceEventArgumentTest, FlatDictionary) {
  scoped_refptr<TracedValue> value = new TracedValue();
  value->SetInteger("int", 2014);
  value->SetDouble("double", 0.0);
  value->SetBoolean("bool", true);
  value->SetString("string", "string");
  std::string json;
  value->AppendAsTraceFormat(&json);
  EXPECT_EQ("{\"bool\":true,\"double\":0.0,\"int\":2014,\"string\":\"string\"}",
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

}  // namespace trace_event
}  // namespace base
