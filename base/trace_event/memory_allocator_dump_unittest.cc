// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/trace_event/memory_allocator_dump.h"

#include "base/format_macros.h"
#include "base/strings/stringprintf.h"
#include "base/trace_event/memory_allocator_dump_guid.h"
#include "base/trace_event/memory_dump_provider.h"
#include "base/trace_event/memory_dump_session_state.h"
#include "base/trace_event/process_memory_dump.h"
#include "base/trace_event/trace_event_argument.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {
namespace trace_event {

namespace {

class FakeMemoryAllocatorDumpProvider : public MemoryDumpProvider {
 public:
  bool OnMemoryDump(ProcessMemoryDump* pmd) override {
    MemoryAllocatorDump* root_heap =
        pmd->CreateAllocatorDump("foobar_allocator");

    root_heap->AddScalar(MemoryAllocatorDump::kNameSize,
                         MemoryAllocatorDump::kUnitsBytes, 4096);
    root_heap->AddScalar(MemoryAllocatorDump::kNameObjectsCount,
                         MemoryAllocatorDump::kUnitsObjects, 42);
    root_heap->AddScalar("attr1", "units1", 1234);
    root_heap->AddString("attr2", "units2", "string_value");
    root_heap->AddScalarF("attr3", "units3", 42.5f);

    MemoryAllocatorDump* sub_heap =
        pmd->CreateAllocatorDump("foobar_allocator/sub_heap");
    sub_heap->AddScalar(MemoryAllocatorDump::kNameSize,
                        MemoryAllocatorDump::kUnitsBytes, 1);
    sub_heap->AddScalar(MemoryAllocatorDump::kNameObjectsCount,
                        MemoryAllocatorDump::kUnitsObjects, 3);

    pmd->CreateAllocatorDump("foobar_allocator/sub_heap/empty");
    // Leave the rest of sub heap deliberately uninitialized, to check that
    // CreateAllocatorDump returns a properly zero-initialized object.

    return true;
  }
};

bool CheckAttribute(const MemoryAllocatorDump* dump,
                    const std::string& name,
                    const char* expected_type,
                    const char* expected_units,
                    const Value** out_value) {
  const char* attr_type;
  const char* attr_units;
  bool res = dump->Get(name, &attr_type, &attr_units, out_value);
  EXPECT_TRUE(res);
  if (!res)
    return false;
  EXPECT_EQ(expected_type, std::string(attr_type));
  EXPECT_EQ(expected_units, std::string(attr_units));
  return true;
}

void CheckString(const MemoryAllocatorDump* dump,
                 const std::string& name,
                 const char* expected_type,
                 const char* expected_units,
                 const std::string& expected_value) {
  const Value* attr_value = nullptr;
  std::string attr_str_value;
  bool res =
      CheckAttribute(dump, name, expected_type, expected_units, &attr_value);
  if (!res)
    return;
  EXPECT_TRUE(attr_value->GetAsString(&attr_str_value));
  EXPECT_EQ(expected_value, attr_str_value);
}

void CheckScalar(const MemoryAllocatorDump* dump,
                 const std::string& name,
                 const char* expected_units,
                 uint64 expected_value) {
  CheckString(dump, name, MemoryAllocatorDump::kTypeScalar, expected_units,
              StringPrintf("%" PRIx64, expected_value));
}

void CheckScalarF(const MemoryAllocatorDump* dump,
                  const std::string& name,
                  const char* expected_units,
                  double expected_value) {
  const Value* attr_value = nullptr;
  double attr_double_value;
  bool res = CheckAttribute(dump, name, MemoryAllocatorDump::kTypeScalar,
                            expected_units, &attr_value);
  if (!res)
    return;
  EXPECT_TRUE(attr_value->GetAsDouble(&attr_double_value));
  EXPECT_EQ(expected_value, attr_double_value);
}

}  // namespace

TEST(MemoryAllocatorDumpTest, GuidGeneration) {
  scoped_ptr<MemoryAllocatorDump> mad(
      new MemoryAllocatorDump("foo", nullptr, MemoryAllocatorDumpGuid(0x42u)));
  ASSERT_EQ("42", mad->guid().ToString());

  // If the dumper does not provide a Guid, the MAD will make one up on the
  // flight. Furthermore that Guid will stay stable across across multiple
  // snapshots if the |absolute_name| of the dump doesn't change
  mad.reset(new MemoryAllocatorDump("bar", nullptr));
  const MemoryAllocatorDumpGuid guid_bar = mad->guid();
  ASSERT_FALSE(guid_bar.empty());
  ASSERT_FALSE(guid_bar.ToString().empty());
  ASSERT_EQ(guid_bar, mad->guid());

  mad.reset(new MemoryAllocatorDump("bar", nullptr));
  const MemoryAllocatorDumpGuid guid_bar_2 = mad->guid();
  ASSERT_EQ(guid_bar, guid_bar_2);

  mad.reset(new MemoryAllocatorDump("baz", nullptr));
  const MemoryAllocatorDumpGuid guid_baz = mad->guid();
  ASSERT_NE(guid_bar, guid_baz);
}

TEST(MemoryAllocatorDumpTest, DumpIntoProcessMemoryDump) {
  FakeMemoryAllocatorDumpProvider fmadp;
  ProcessMemoryDump pmd(make_scoped_refptr(new MemoryDumpSessionState()));

  fmadp.OnMemoryDump(&pmd);

  ASSERT_EQ(3u, pmd.allocator_dumps().size());

  const MemoryAllocatorDump* root_heap =
      pmd.GetAllocatorDump("foobar_allocator");
  ASSERT_NE(nullptr, root_heap);
  EXPECT_EQ("foobar_allocator", root_heap->absolute_name());
  CheckScalar(root_heap, MemoryAllocatorDump::kNameSize,
              MemoryAllocatorDump::kUnitsBytes, 4096);
  CheckScalar(root_heap, MemoryAllocatorDump::kNameObjectsCount,
              MemoryAllocatorDump::kUnitsObjects, 42);
  CheckScalar(root_heap, "attr1", "units1", 1234);
  CheckString(root_heap, "attr2", MemoryAllocatorDump::kTypeString, "units2",
              "string_value");
  CheckScalarF(root_heap, "attr3", "units3", 42.5f);

  const MemoryAllocatorDump* sub_heap =
      pmd.GetAllocatorDump("foobar_allocator/sub_heap");
  ASSERT_NE(nullptr, sub_heap);
  EXPECT_EQ("foobar_allocator/sub_heap", sub_heap->absolute_name());
  CheckScalar(sub_heap, MemoryAllocatorDump::kNameSize,
              MemoryAllocatorDump::kUnitsBytes, 1);
  CheckScalar(sub_heap, MemoryAllocatorDump::kNameObjectsCount,
              MemoryAllocatorDump::kUnitsObjects, 3);

  const MemoryAllocatorDump* empty_sub_heap =
      pmd.GetAllocatorDump("foobar_allocator/sub_heap/empty");
  ASSERT_NE(nullptr, empty_sub_heap);
  EXPECT_EQ("foobar_allocator/sub_heap/empty", empty_sub_heap->absolute_name());
  ASSERT_FALSE(empty_sub_heap->Get(MemoryAllocatorDump::kNameSize, nullptr,
                                   nullptr, nullptr));
  ASSERT_FALSE(empty_sub_heap->Get(MemoryAllocatorDump::kNameObjectsCount,
                                   nullptr, nullptr, nullptr));

  // Check that the AsValueInfo doesn't hit any DCHECK.
  scoped_refptr<TracedValue> traced_value(new TracedValue());
  pmd.AsValueInto(traced_value.get());
}

// DEATH tests are not supported in Android / iOS.
#if !defined(NDEBUG) && !defined(OS_ANDROID) && !defined(OS_IOS)
TEST(MemoryAllocatorDumpTest, ForbidDuplicatesDeathTest) {
  FakeMemoryAllocatorDumpProvider fmadp;
  ProcessMemoryDump pmd(make_scoped_refptr(new MemoryDumpSessionState()));
  pmd.CreateAllocatorDump("foo_allocator");
  pmd.CreateAllocatorDump("bar_allocator/heap");
  ASSERT_DEATH(pmd.CreateAllocatorDump("foo_allocator"), "");
  ASSERT_DEATH(pmd.CreateAllocatorDump("bar_allocator/heap"), "");
  ASSERT_DEATH(pmd.CreateAllocatorDump(""), "");
}
#endif

}  // namespace trace_event
}  // namespace base
