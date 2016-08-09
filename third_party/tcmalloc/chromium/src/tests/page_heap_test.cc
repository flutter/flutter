// Copyright 2009 Google Inc. All Rights Reserved.
// Author: fikes@google.com (Andrew Fikes)

#include "config_for_unittests.h"
#include "page_heap.h"
#include <stdio.h>
#include "base/logging.h"
#include "common.h"

namespace {

static void CheckStats(const tcmalloc::PageHeap* ph,
                       uint64_t system_pages,
                       uint64_t free_pages,
                       uint64_t unmapped_pages) {
  tcmalloc::PageHeap::Stats stats = ph->stats();
  EXPECT_EQ(system_pages, stats.system_bytes >> kPageShift);
  EXPECT_EQ(free_pages, stats.free_bytes >> kPageShift);
  EXPECT_EQ(unmapped_pages, stats.unmapped_bytes >> kPageShift);
}

static void TestPageHeap_Stats() {
  tcmalloc::PageHeap* ph = new tcmalloc::PageHeap();

  // Empty page heap
  CheckStats(ph, 0, 0, 0);

  // Allocate a span 's1'
  tcmalloc::Span* s1 = ph->New(256);
  CheckStats(ph, 256, 0, 0);

  // Split span 's1' into 's1', 's2'.  Delete 's2'
  tcmalloc::Span* s2 = ph->Split(s1, 128);
  Length s2_len = s2->length;
  ph->Delete(s2);
  CheckStats(ph, 256, 128, 0);

  // Unmap deleted span 's2'
  EXPECT_EQ(s2_len, ph->ReleaseAtLeastNPages(1));
  CheckStats(ph, 256, 0, 128);

  // Delete span 's1'
  ph->Delete(s1);
  CheckStats(ph, 256, 128, 128);

  delete ph;
}

}  // namespace

int main(int argc, char **argv) {
  TestPageHeap_Stats();
  printf("PASS\n");
  return 0;
}
