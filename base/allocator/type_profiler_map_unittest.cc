// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This is a unittest set for type_profiler_map in third_party/tcmalloc.  It is
// independent from other tests and executed manually like allocator_unittests
// since type_profiler_map is a singleton (like TCMalloc's heap-profiler), and
// it requires RTTI and different compiling/linking options from others.

#if defined(TYPE_PROFILING)

#include "base/memory/scoped_ptr.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "third_party/tcmalloc/chromium/src/gperftools/type_profiler_map.h"

namespace base {
namespace type_profiler {

static const void* const g_const_null = static_cast<const void*>(NULL);

TEST(TypeProfilerMapTest, NormalOperation) {
  // Allocate an object just to get a valid address.
  // This 'new' is not profiled by type_profiler.
  scoped_ptr<int> dummy(new int(48));
  const std::type_info* type;

  type = LookupType(dummy.get());
  EXPECT_EQ(g_const_null, type);

  InsertType(dummy.get(), 12, typeid(int));
  type = LookupType(dummy.get());
  ASSERT_NE(g_const_null, type);
  EXPECT_STREQ(typeid(int).name(), type->name());

  EraseType(dummy.get());
  type = LookupType(dummy.get());
  EXPECT_EQ(g_const_null, type);
}

TEST(TypeProfilerMapTest, EraseWithoutInsert) {
  scoped_ptr<int> dummy(new int(48));
  const std::type_info* type;

  for (int i = 0; i < 10; ++i) {
    EraseType(dummy.get());
    type = LookupType(dummy.get());
    EXPECT_EQ(g_const_null, type);
  }
}

TEST(TypeProfilerMapTest, InsertThenMultipleErase) {
  scoped_ptr<int> dummy(new int(48));
  const std::type_info* type;

  InsertType(dummy.get(), 12, typeid(int));
  type = LookupType(dummy.get());
  ASSERT_NE(g_const_null, type);
  EXPECT_STREQ(typeid(int).name(), type->name());

  for (int i = 0; i < 10; ++i) {
    EraseType(dummy.get());
    type = LookupType(dummy.get());
    EXPECT_EQ(g_const_null, type);
  }
}

TEST(TypeProfilerMapTest, MultipleInsertWithoutErase) {
  scoped_ptr<int> dummy(new int(48));
  const std::type_info* type;

  InsertType(dummy.get(), 12, typeid(int));
  type = LookupType(dummy.get());
  ASSERT_NE(g_const_null, type);
  EXPECT_STREQ(typeid(int).name(), type->name());

  InsertType(dummy.get(), 5, typeid(char));
  type = LookupType(dummy.get());
  ASSERT_NE(g_const_null, type);
  EXPECT_STREQ(typeid(char).name(), type->name());

  InsertType(dummy.get(), 129, typeid(long));
  type = LookupType(dummy.get());
  ASSERT_NE(g_const_null, type);
  EXPECT_STREQ(typeid(long).name(), type->name());

  EraseType(dummy.get());
  type = LookupType(dummy.get());
  EXPECT_EQ(g_const_null, type);
}

}  // namespace type_profiler
}  // namespace base

#endif  // defined(TYPE_PROFILING)

int main(int argc, char** argv) {
  testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
