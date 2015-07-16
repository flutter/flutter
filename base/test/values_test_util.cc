// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/values_test_util.h"

#include "base/json/json_reader.h"
#include "base/memory/scoped_ptr.h"
#include "base/strings/string_number_conversions.h"
#include "base/values.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

void ExpectDictBooleanValue(bool expected_value,
                            const DictionaryValue& value,
                            const std::string& key) {
  bool boolean_value = false;
  EXPECT_TRUE(value.GetBoolean(key, &boolean_value)) << key;
  EXPECT_EQ(expected_value, boolean_value) << key;
}

void ExpectDictDictionaryValue(const DictionaryValue& expected_value,
                               const DictionaryValue& value,
                               const std::string& key) {
  const DictionaryValue* dict_value = NULL;
  EXPECT_TRUE(value.GetDictionary(key, &dict_value)) << key;
  EXPECT_TRUE(Value::Equals(dict_value, &expected_value)) << key;
}

void ExpectDictIntegerValue(int expected_value,
                            const DictionaryValue& value,
                            const std::string& key) {
  int integer_value = 0;
  EXPECT_TRUE(value.GetInteger(key, &integer_value)) << key;
  EXPECT_EQ(expected_value, integer_value) << key;
}

void ExpectDictListValue(const ListValue& expected_value,
                         const DictionaryValue& value,
                         const std::string& key) {
  const ListValue* list_value = NULL;
  EXPECT_TRUE(value.GetList(key, &list_value)) << key;
  EXPECT_TRUE(Value::Equals(list_value, &expected_value)) << key;
}

void ExpectDictStringValue(const std::string& expected_value,
                           const DictionaryValue& value,
                           const std::string& key) {
  std::string string_value;
  EXPECT_TRUE(value.GetString(key, &string_value)) << key;
  EXPECT_EQ(expected_value, string_value) << key;
}

void ExpectStringValue(const std::string& expected_str,
                       StringValue* actual) {
  scoped_ptr<StringValue> scoped_actual(actual);
  std::string actual_str;
  EXPECT_TRUE(scoped_actual->GetAsString(&actual_str));
  EXPECT_EQ(expected_str, actual_str);
}

namespace test {

scoped_ptr<Value> ParseJson(base::StringPiece json) {
  std::string error_msg;
  scoped_ptr<Value> result = base::JSONReader::ReadAndReturnError(
      json, base::JSON_ALLOW_TRAILING_COMMAS, NULL, &error_msg);
  if (!result) {
    ADD_FAILURE() << "Failed to parse \"" << json << "\": " << error_msg;
    result = Value::CreateNullValue();
  }
  return result.Pass();
}

}  // namespace test
}  // namespace base
