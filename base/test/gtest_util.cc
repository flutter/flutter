// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/gtest_util.h"

#include "base/files/file_path.h"
#include "base/json/json_file_value_serializer.h"
#include "base/values.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

std::string FormatFullTestName(const std::string& test_case_name,
                               const std::string& test_name) {
  return test_case_name + "." + test_name;
}

std::vector<SplitTestName> GetCompiledInTests() {
  testing::UnitTest* const unit_test = testing::UnitTest::GetInstance();

  std::vector<SplitTestName> tests;
  for (int i = 0; i < unit_test->total_test_case_count(); ++i) {
    const testing::TestCase* test_case = unit_test->GetTestCase(i);
    for (int j = 0; j < test_case->total_test_count(); ++j) {
      const testing::TestInfo* test_info = test_case->GetTestInfo(j);
      tests.push_back(std::make_pair(test_case->name(), test_info->name()));
    }
  }
  return tests;
}

bool WriteCompiledInTestsToFile(const FilePath& path) {
  std::vector<SplitTestName> tests(GetCompiledInTests());

  ListValue root;
  for (size_t i = 0; i < tests.size(); ++i) {
    DictionaryValue* test_info = new DictionaryValue;
    test_info->SetString("test_case_name", tests[i].first);
    test_info->SetString("test_name", tests[i].second);
    root.Append(test_info);
  }

  JSONFileValueSerializer serializer(path);
  return serializer.Serialize(root);
}

bool ReadTestNamesFromFile(const FilePath& path,
                           std::vector<SplitTestName>* output) {
  JSONFileValueDeserializer deserializer(path);
  int error_code = 0;
  std::string error_message;
  scoped_ptr<base::Value> value(
      deserializer.Deserialize(&error_code, &error_message));
  if (!value.get())
    return false;

  base::ListValue* tests = nullptr;
  if (!value->GetAsList(&tests))
    return false;

  std::vector<base::SplitTestName> result;
  for (base::ListValue::iterator i = tests->begin(); i != tests->end(); ++i) {
    base::DictionaryValue* test = nullptr;
    if (!(*i)->GetAsDictionary(&test))
      return false;

    std::string test_case_name;
    if (!test->GetStringASCII("test_case_name", &test_case_name))
      return false;

    std::string test_name;
    if (!test->GetStringASCII("test_name", &test_name))
      return false;

    result.push_back(std::make_pair(test_case_name, test_name));
  }

  output->swap(result);
  return true;
}

}  // namespace base
