// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This is a unittest set for type_profiler.  It is independent from other
// tests and executed manually like allocator_unittests since type_profiler_map
// used in type_profiler is a singleton (like TCMalloc's heap-profiler), and
// it requires RTTI and different compiling/linking options from others
//
// It tests that the profiler doesn't fail in suspicous cases.  For example,
// 'new' is not profiled, but 'delete' for the created object is profiled.

#if defined(TYPE_PROFILING)

#include "base/allocator/type_profiler.h"
#include "base/allocator/type_profiler_control.h"
#include "base/allocator/type_profiler_tcmalloc.h"
#include "base/basictypes.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "third_party/tcmalloc/chromium/src/gperftools/type_profiler_map.h"

namespace base {
namespace type_profiler {

class TypeProfilerTest : public testing::Test {
 public:
  TypeProfilerTest() {}

  void SetInterceptFunctions() {
    InterceptFunctions::SetFunctions(NewInterceptForTCMalloc,
                                     DeleteInterceptForTCMalloc);
  }

  void ResetInterceptFunctions() {
    InterceptFunctions::ResetFunctions();
  }

  void SetUp() {
    SetInterceptFunctions();
  }

  void TearDown() {
    ResetInterceptFunctions();
  }

 protected:
  static const size_t kDummyArraySize;
  static const void* const kConstNull;

 private:
  DISALLOW_COPY_AND_ASSIGN(TypeProfilerTest);
};

const size_t TypeProfilerTest::kDummyArraySize = 10;
const void* const TypeProfilerTest::kConstNull = static_cast<const void*>(NULL);

TEST_F(TypeProfilerTest, TestNormalProfiling) {
  int* dummy = new int(48);
  const std::type_info* type;

  type = LookupType(dummy);
  ASSERT_NE(kConstNull, type);
  EXPECT_STREQ(typeid(int).name(), type->name());
  delete dummy;

  type = LookupType(dummy);
  EXPECT_EQ(kConstNull, type);
}

TEST_F(TypeProfilerTest, TestNormalArrayProfiling) {
  int* dummy = new int[kDummyArraySize];
  const std::type_info* type;

  type = LookupType(dummy);
  ASSERT_NE(kConstNull, type);
  // For an array, the profiler remembers its base type.
  EXPECT_STREQ(typeid(int).name(), type->name());
  delete[] dummy;

  type = LookupType(dummy);
  EXPECT_EQ(kConstNull, type);
}

TEST_F(TypeProfilerTest, TestRepeatedNewAndDelete) {
  int *dummy[kDummyArraySize];
  const std::type_info* type;
  for (int i = 0; i < kDummyArraySize; ++i)
    dummy[i] = new int(i);

  for (int i = 0; i < kDummyArraySize; ++i) {
    type = LookupType(dummy[i]);
    ASSERT_NE(kConstNull, type);
    EXPECT_STREQ(typeid(int).name(), type->name());
  }

  for (int i = 0; i < kDummyArraySize; ++i) {
    delete dummy[i];
    type = LookupType(dummy[i]);
    ASSERT_EQ(kConstNull, type);
  }
}

TEST_F(TypeProfilerTest, TestMultipleNewWithDroppingDelete) {
  static const size_t large_size = 256 * 1024;

  char* dummy_char = new char[large_size / sizeof(*dummy_char)];
  const std::type_info* type;

  type = LookupType(dummy_char);
  ASSERT_NE(kConstNull, type);
  EXPECT_STREQ(typeid(char).name(), type->name());

  // Call "::operator delete" directly to drop __op_delete_intercept__.
  ::operator delete[](dummy_char);

  type = LookupType(dummy_char);
  ASSERT_NE(kConstNull, type);
  EXPECT_STREQ(typeid(char).name(), type->name());

  // Allocates a little different size.
  int* dummy_int = new int[large_size / sizeof(*dummy_int) - 1];

  // We expect that tcmalloc returns the same address for these large (over 32k)
  // allocation calls.  It usually happens, but maybe probablistic.
  ASSERT_EQ(static_cast<void*>(dummy_char), static_cast<void*>(dummy_int)) <<
      "two new (malloc) calls didn't return the same address; retry it.";

  type = LookupType(dummy_int);
  ASSERT_NE(kConstNull, type);
  EXPECT_STREQ(typeid(int).name(), type->name());

  delete[] dummy_int;

  type = LookupType(dummy_int);
  EXPECT_EQ(kConstNull, type);
}

TEST_F(TypeProfilerTest, TestProfileDeleteWithoutProfiledNew) {
  // 'dummy' should be new'ed in this test before intercept functions are set.
  ResetInterceptFunctions();

  int* dummy = new int(48);
  const std::type_info* type;

  // Set intercept functions again after 'dummy' is new'ed.
  SetInterceptFunctions();

  delete dummy;

  type = LookupType(dummy);
  EXPECT_EQ(kConstNull, type);

  ResetInterceptFunctions();
}

TEST_F(TypeProfilerTest, TestProfileNewWithoutProfiledDelete) {
  int* dummy = new int(48);
  const std::type_info* type;

  EXPECT_TRUE(Controller::IsProfiling());

  // Stop profiling before deleting 'dummy'.
  Controller::Stop();
  EXPECT_FALSE(Controller::IsProfiling());

  delete dummy;

  // NOTE: We accept that a profile entry remains when a profiled object is
  // deleted after Controller::Stop().
  type = LookupType(dummy);
  ASSERT_NE(kConstNull, type);
  EXPECT_STREQ(typeid(int).name(), type->name());

  Controller::Restart();
  EXPECT_TRUE(Controller::IsProfiling());

  // Remove manually since 'dummy' is not removed from type_profiler_map.
  EraseType(dummy);
}

}  // namespace type_profiler
}  // namespace base

#endif  // defined(TYPE_PROFILING)

int main(int argc, char** argv) {
  testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
