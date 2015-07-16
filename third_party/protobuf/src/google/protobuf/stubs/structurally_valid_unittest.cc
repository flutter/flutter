// Copyright 2008 Google Inc. All Rights Reserved.
// Author: xpeng@google.com (Peter Peng)

#include <google/protobuf/stubs/common.h>
#include <gtest/gtest.h>

namespace google {
namespace protobuf {
namespace internal {
namespace {

TEST(StructurallyValidTest, ValidUTF8String) {
  // On GCC, this string can be written as:
  //   "abcd 1234 - \u2014\u2013\u2212"
  // MSVC seems to interpret \u differently.
  string valid_str("abcd 1234 - \342\200\224\342\200\223\342\210\222 - xyz789");
  EXPECT_TRUE(IsStructurallyValidUTF8(valid_str.data(),
                                      valid_str.size()));
  // Additional check for pointer alignment
  for (int i = 1; i < 8; ++i) {
    EXPECT_TRUE(IsStructurallyValidUTF8(valid_str.data() + i,
                                        valid_str.size() - i));
  }
}

TEST(StructurallyValidTest, InvalidUTF8String) {
  const string invalid_str("abcd\xA0\xB0\xA0\xB0\xA0\xB0 - xyz789");
  EXPECT_FALSE(IsStructurallyValidUTF8(invalid_str.data(),
                                       invalid_str.size()));
  // Additional check for pointer alignment
  for (int i = 1; i < 8; ++i) {
    EXPECT_FALSE(IsStructurallyValidUTF8(invalid_str.data() + i,
                                         invalid_str.size() - i));
  }
}

}  // namespace
}  // namespace internal
}  // namespace protobuf
}  // namespace google
