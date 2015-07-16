// Copyright 2009 Google Inc. All Rights Reserved.
// Author: fikes@google.com (Andrew Fikes)

#include "config_for_unittests.h"
#include <stdio.h>   // for puts()
#include "stack_trace_table.h"
#include "base/logging.h"
#include "base/spinlock.h"
#include "static_vars.h"

#undef ARRAYSIZE   // may be defined on, eg, windows
#define ARRAYSIZE(a)  ( sizeof(a) / sizeof(*(a)) )

static void CheckTracesAndReset(tcmalloc::StackTraceTable* table,
                        const uintptr_t* expected, int len) {
  void** entries = table->ReadStackTracesAndClear();
  for (int i = 0; i < len; ++i) {
    CHECK_EQ(reinterpret_cast<uintptr_t>(entries[i]), expected[i]);
  }
  delete[] entries;
}

static void AddTrace(tcmalloc::StackTraceTable* table,
                     const tcmalloc::StackTrace& t) {
  // Normally we'd need this lock, but since the test is single-threaded
  // we don't.  I comment it out on windows because the DLL-decl thing
  // is really annoying in this case.
#ifndef _MSC_VER
  SpinLockHolder h(tcmalloc::Static::pageheap_lock());
#endif
  table->AddTrace(t);
}

int main(int argc, char **argv) {
  tcmalloc::StackTraceTable table;

  // Empty table
  CHECK_EQ(table.depth_total(), 0);
  CHECK_EQ(table.bucket_total(), 0);
  static const uintptr_t k1[] = {0};
  CheckTracesAndReset(&table, k1, ARRAYSIZE(k1));

  tcmalloc::StackTrace t1;
  t1.size = static_cast<uintptr_t>(1024);
  t1.depth = static_cast<uintptr_t>(2);
  t1.stack[0] = reinterpret_cast<void*>(1);
  t1.stack[1] = reinterpret_cast<void*>(2);


  tcmalloc::StackTrace t2;
  t2.size = static_cast<uintptr_t>(512);
  t2.depth = static_cast<uintptr_t>(2);
  t2.stack[0] = reinterpret_cast<void*>(2);
  t2.stack[1] = reinterpret_cast<void*>(1);

  // Table w/ just t1
  AddTrace(&table, t1);
  CHECK_EQ(table.depth_total(), 2);
  CHECK_EQ(table.bucket_total(), 1);
  static const uintptr_t k2[] = {1, 1024, 2, 1, 2, 0};
  CheckTracesAndReset(&table, k2, ARRAYSIZE(k2));

  // Table w/ t1, t2
  AddTrace(&table, t1);
  AddTrace(&table, t2);
  CHECK_EQ(table.depth_total(), 4);
  CHECK_EQ(table.bucket_total(), 2);
  static const uintptr_t k3[] = {1, 1024, 2, 1, 2, 1,  512, 2, 2, 1, 0};
  CheckTracesAndReset(&table, k3, ARRAYSIZE(k3));

  // Table w/ 2 x t1, 1 x t2
  AddTrace(&table, t1);
  AddTrace(&table, t2);
  AddTrace(&table, t1);
  CHECK_EQ(table.depth_total(), 4);
  CHECK_EQ(table.bucket_total(), 2);
  static const uintptr_t k4[] = {2, 2048, 2, 1, 2, 1,  512, 2, 2, 1, 0};
  CheckTracesAndReset(&table, k4, ARRAYSIZE(k4));

  // Same stack as t1, but w/ different size
  tcmalloc::StackTrace t3;
  t3.size = static_cast<uintptr_t>(2);
  t3.depth = static_cast<uintptr_t>(2);
  t3.stack[0] = reinterpret_cast<void*>(1);
  t3.stack[1] = reinterpret_cast<void*>(2);

  // Table w/ t1, t3
  AddTrace(&table, t1);
  AddTrace(&table, t3);
  CHECK_EQ(table.depth_total(), 2);
  CHECK_EQ(table.bucket_total(), 1);
  static const uintptr_t k5[] = {2, 1026, 2, 1, 2, 0};
  CheckTracesAndReset(&table, k5, ARRAYSIZE(k5));

  puts("PASS");
  return 0;
}
