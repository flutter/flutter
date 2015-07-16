// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TEST_GTEST_XML_UNITTEST_RESULT_PRINTER_H_
#define BASE_TEST_GTEST_XML_UNITTEST_RESULT_PRINTER_H_

#include <stdio.h>

#include "base/compiler_specific.h"
#include "base/macros.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

class FilePath;

// Generates an XML output file. Format is very close to GTest, but has
// extensions needed by the test launcher.
class XmlUnitTestResultPrinter : public testing::EmptyTestEventListener {
 public:
  XmlUnitTestResultPrinter();
  ~XmlUnitTestResultPrinter() override;

  // Must be called before adding as a listener. Returns true on success.
  bool Initialize(const FilePath& output_file_path) WARN_UNUSED_RESULT;

 private:
  // testing::EmptyTestEventListener:
  void OnTestCaseStart(const testing::TestCase& test_case) override;
  void OnTestStart(const testing::TestInfo& test_info) override;
  void OnTestEnd(const testing::TestInfo& test_info) override;
  void OnTestCaseEnd(const testing::TestCase& test_case) override;

  FILE* output_file_;

  DISALLOW_COPY_AND_ASSIGN(XmlUnitTestResultPrinter);
};

}  // namespace base

#endif  // BASE_TEST_GTEST_XML_UNITTEST_RESULT_PRINTER_H_
