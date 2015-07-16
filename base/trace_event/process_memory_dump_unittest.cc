// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/trace_event/process_memory_dump.h"

#include "base/memory/scoped_ptr.h"
#include "base/trace_event/memory_allocator_dump_guid.h"
#include "base/trace_event/trace_event_argument.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {
namespace trace_event {

TEST(ProcessMemoryDumpTest, Clear) {
  scoped_ptr<ProcessMemoryDump> pmd1(new ProcessMemoryDump(nullptr));
  pmd1->CreateAllocatorDump("mad1");
  pmd1->CreateAllocatorDump("mad2");
  ASSERT_FALSE(pmd1->allocator_dumps().empty());

  pmd1->process_totals()->set_resident_set_bytes(42);
  pmd1->set_has_process_totals();

  pmd1->process_mmaps()->AddVMRegion(ProcessMemoryMaps::VMRegion());
  pmd1->set_has_process_mmaps();

  pmd1->AddOwnershipEdge(MemoryAllocatorDumpGuid(42),
                         MemoryAllocatorDumpGuid(4242));

  MemoryAllocatorDumpGuid shared_mad_guid(1);
  pmd1->CreateSharedGlobalAllocatorDump(shared_mad_guid);

  pmd1->Clear();
  ASSERT_TRUE(pmd1->allocator_dumps().empty());
  ASSERT_TRUE(pmd1->allocator_dumps_edges().empty());
  ASSERT_EQ(nullptr, pmd1->GetAllocatorDump("mad1"));
  ASSERT_EQ(nullptr, pmd1->GetAllocatorDump("mad2"));
  ASSERT_FALSE(pmd1->has_process_totals());
  ASSERT_FALSE(pmd1->has_process_mmaps());
  ASSERT_TRUE(pmd1->process_mmaps()->vm_regions().empty());
  ASSERT_EQ(nullptr, pmd1->GetSharedGlobalAllocatorDump(shared_mad_guid));

  // Check that calling AsValueInto() doesn't cause a crash.
  scoped_refptr<TracedValue> traced_value(new TracedValue());
  pmd1->AsValueInto(traced_value.get());

  // Check that the pmd can be reused and behaves as expected.
  auto mad1 = pmd1->CreateAllocatorDump("mad1");
  auto mad3 = pmd1->CreateAllocatorDump("mad3");
  auto shared_mad = pmd1->CreateSharedGlobalAllocatorDump(shared_mad_guid);
  ASSERT_EQ(3u, pmd1->allocator_dumps().size());
  ASSERT_EQ(mad1, pmd1->GetAllocatorDump("mad1"));
  ASSERT_EQ(nullptr, pmd1->GetAllocatorDump("mad2"));
  ASSERT_EQ(mad3, pmd1->GetAllocatorDump("mad3"));
  ASSERT_EQ(shared_mad, pmd1->GetSharedGlobalAllocatorDump(shared_mad_guid));

  traced_value = new TracedValue();
  pmd1->AsValueInto(traced_value.get());

  pmd1.reset();
}

TEST(ProcessMemoryDumpTest, TakeAllDumpsFrom) {
  scoped_refptr<TracedValue> traced_value(new TracedValue());

  scoped_ptr<ProcessMemoryDump> pmd1(new ProcessMemoryDump(nullptr));
  auto mad1_1 = pmd1->CreateAllocatorDump("pmd1/mad1");
  auto mad1_2 = pmd1->CreateAllocatorDump("pmd1/mad2");
  pmd1->AddOwnershipEdge(mad1_1->guid(), mad1_2->guid());

  scoped_ptr<ProcessMemoryDump> pmd2(new ProcessMemoryDump(nullptr));
  auto mad2_1 = pmd2->CreateAllocatorDump("pmd2/mad1");
  auto mad2_2 = pmd2->CreateAllocatorDump("pmd2/mad2");
  pmd1->AddOwnershipEdge(mad2_1->guid(), mad2_2->guid());

  MemoryAllocatorDumpGuid shared_mad_guid(1);
  auto shared_mad = pmd2->CreateSharedGlobalAllocatorDump(shared_mad_guid);

  pmd1->TakeAllDumpsFrom(pmd2.get());

  // Make sure that pmd2 is empty but still usable after it has been emptied.
  ASSERT_TRUE(pmd2->allocator_dumps().empty());
  ASSERT_TRUE(pmd2->allocator_dumps_edges().empty());
  pmd2->CreateAllocatorDump("pmd2/this_mad_stays_with_pmd2");
  ASSERT_EQ(1u, pmd2->allocator_dumps().size());
  ASSERT_EQ(1u, pmd2->allocator_dumps().count("pmd2/this_mad_stays_with_pmd2"));
  pmd2->AddOwnershipEdge(MemoryAllocatorDumpGuid(42),
                         MemoryAllocatorDumpGuid(4242));

  // Check that calling AsValueInto() doesn't cause a crash.
  pmd2->AsValueInto(traced_value.get());

  // Free the |pmd2| to check that the memory ownership of the two MAD(s)
  // has been transferred to |pmd1|.
  pmd2.reset();

  // Now check that |pmd1| has been effectively merged.
  ASSERT_EQ(5u, pmd1->allocator_dumps().size());
  ASSERT_EQ(1u, pmd1->allocator_dumps().count("pmd1/mad1"));
  ASSERT_EQ(1u, pmd1->allocator_dumps().count("pmd1/mad2"));
  ASSERT_EQ(1u, pmd1->allocator_dumps().count("pmd2/mad1"));
  ASSERT_EQ(1u, pmd1->allocator_dumps().count("pmd1/mad2"));
  ASSERT_EQ(2u, pmd1->allocator_dumps_edges().size());
  ASSERT_EQ(shared_mad, pmd1->GetSharedGlobalAllocatorDump(shared_mad_guid));

  // Check that calling AsValueInto() doesn't cause a crash.
  traced_value = new TracedValue();
  pmd1->AsValueInto(traced_value.get());

  pmd1.reset();
}

TEST(ProcessMemoryDumpTest, Suballocations) {
  scoped_ptr<ProcessMemoryDump> pmd(new ProcessMemoryDump(nullptr));
  const std::string allocator_dump_name = "fakealloc/allocated_objects";
  pmd->CreateAllocatorDump(allocator_dump_name);

  // Create one allocation with an auto-assigned guid and mark it as a
  // suballocation of "fakealloc/allocated_objects".
  auto pic1_dump = pmd->CreateAllocatorDump("picturemanager/picture1");
  pmd->AddSuballocation(pic1_dump->guid(), allocator_dump_name);

  // Same here, but this time create an allocation with an explicit guid.
  auto pic2_dump = pmd->CreateAllocatorDump("picturemanager/picture2",
                                            MemoryAllocatorDumpGuid(0x42));
  pmd->AddSuballocation(pic2_dump->guid(), allocator_dump_name);

  // Now check that AddSuballocation() has created anonymous child dumps under
  // "fakealloc/allocated_objects".
  auto anon_node_1_it = pmd->allocator_dumps().find(
      allocator_dump_name + "/__" + pic1_dump->guid().ToString());
  ASSERT_NE(pmd->allocator_dumps().end(), anon_node_1_it);

  auto anon_node_2_it =
      pmd->allocator_dumps().find(allocator_dump_name + "/__42");
  ASSERT_NE(pmd->allocator_dumps().end(), anon_node_2_it);

  // Finally check that AddSuballocation() has created also the
  // edges between the pictures and the anonymous allocator child dumps.
  bool found_edge[2]{false, false};
  for (const auto& e : pmd->allocator_dumps_edges()) {
    found_edge[0] |= (e.source == pic1_dump->guid() &&
                      e.target == anon_node_1_it->second->guid());
    found_edge[1] |= (e.source == pic2_dump->guid() &&
                      e.target == anon_node_2_it->second->guid());
  }
  ASSERT_TRUE(found_edge[0]);
  ASSERT_TRUE(found_edge[1]);

  // Check that calling AsValueInto() doesn't cause a crash.
  scoped_refptr<TracedValue> traced_value(new TracedValue());
  pmd->AsValueInto(traced_value.get());

  pmd.reset();
}

}  // namespace trace_event
}  // namespace base
