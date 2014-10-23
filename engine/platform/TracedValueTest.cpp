// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"

#include "platform/TracedValue.h"

#include <gtest/gtest.h>

using namespace blink;

namespace {

TEST(TracedValueTest, FlatDictionary)
{
    RefPtr<TracedValue> value = TracedValue::create();
    value->setInteger("int", 2014);
    value->setDouble("double", 0.0);
    value->setBoolean("bool", true);
    value->setString("string", "string");
    String json = value->asTraceFormat();
    EXPECT_EQ("{\"int\":2014,\"double\":0,\"bool\":true,\"string\":\"string\"}", json);
}

TEST(TracedValueTest, Hierarchy)
{
    RefPtr<TracedValue> value = TracedValue::create();
    value->setInteger("i0", 2014);
    value->beginDictionary("dict1");
    value->setInteger("i1", 2014);
    value->beginDictionary("dict2");
    value->setBoolean("b2", false);
    value->endDictionary();
    value->setString("s1", "foo");
    value->endDictionary();
    value->setDouble("d0", 0.0);
    value->setBoolean("b0", true);
    value->beginArray("a1");
    value->pushInteger(1);
    value->pushBoolean(true);
    value->beginDictionary();
    value->setInteger("i2", 3);
    value->endDictionary();
    value->endArray();
    value->setString("s0", "foo");
    String json = value->asTraceFormat();
    EXPECT_EQ("{\"i0\":2014,\"dict1\":{\"i1\":2014,\"dict2\":{\"b2\":false},\"s1\":\"foo\"},\"d0\":0,\"b0\":true,\"a1\":[1,true,{\"i2\":3}],\"s0\":\"foo\"}", json);
}

}
