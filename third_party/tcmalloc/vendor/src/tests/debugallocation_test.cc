// Copyright (c) 2007, Google Inc.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// ---
// Author: Fred Akalin

#include <stdio.h>
#include <stdlib.h>
#include <vector>
#include "gperftools/malloc_extension.h"
#include "base/logging.h"

using std::vector;

vector<void (*)()> g_testlist;  // the tests to run

#define TEST(a, b)                                      \
  struct Test_##a##_##b {                               \
    Test_##a##_##b() { g_testlist.push_back(&Run); }    \
    static void Run();                                  \
  };                                                    \
  static Test_##a##_##b g_test_##a##_##b;               \
  void Test_##a##_##b::Run()


static int RUN_ALL_TESTS() {
  vector<void (*)()>::const_iterator it;
  for (it = g_testlist.begin(); it != g_testlist.end(); ++it) {
    (*it)();   // The test will error-exit if there's a problem.
  }
  fprintf(stderr, "\nPassed %d tests\n\nPASS\n",
          static_cast<int>(g_testlist.size()));
  return 0;
}

// The death tests are meant to be run from a shell-script driver, which
// passes in an integer saying which death test to run.  We store that
// test-to-run here, and in the macro use a counter to see when we get
// to that test, so we can run it.
static int test_to_run = 0;     // set in main() based on argv
static int test_counter = 0;    // incremented every time the macro is called
#define IF_DEBUG_EXPECT_DEATH(statement, regex) do {    \
  if (test_counter++ == test_to_run) {                  \
    fprintf(stderr, "Expected regex:%s\n", regex);      \
    statement;                                          \
  }                                                     \
} while (false)

// This flag won't be compiled in in opt mode.
DECLARE_int32(max_free_queue_size);

// Test match as well as mismatch rules.  But do not test on OS X; on
// OS X the OS converts new/new[] to malloc before it gets to us, so
// we are unable to catch these mismatch errors.
#ifndef __APPLE__
TEST(DebugAllocationTest, DeallocMismatch) {
  // malloc can be matched only by free
  // new can be matched only by delete and delete(nothrow)
  // new[] can be matched only by delete[] and delete[](nothrow)
  // new(nothrow) can be matched only by delete and delete(nothrow)
  // new(nothrow)[] can be matched only by delete[] and delete[](nothrow)

  // Allocate with malloc.
  {
    int* x = static_cast<int*>(malloc(sizeof(*x)));
    IF_DEBUG_EXPECT_DEATH(delete x, "mismatch.*being dealloc.*delete");
    IF_DEBUG_EXPECT_DEATH(delete [] x, "mismatch.*being dealloc.*delete *[[]");
    // Should work fine.
    free(x);
  }

  // Allocate with new.
  {
    int* x = new int;
    int* y = new int;
    IF_DEBUG_EXPECT_DEATH(free(x), "mismatch.*being dealloc.*free");
    IF_DEBUG_EXPECT_DEATH(delete [] x, "mismatch.*being dealloc.*delete *[[]");
    delete x;
    ::operator delete(y, std::nothrow);
  }

  // Allocate with new[].
  {
    int* x = new int[1];
    int* y = new int[1];
    IF_DEBUG_EXPECT_DEATH(free(x), "mismatch.*being dealloc.*free");
    IF_DEBUG_EXPECT_DEATH(delete x, "mismatch.*being dealloc.*delete");
    delete [] x;
    ::operator delete[](y, std::nothrow);
  }

  // Allocate with new(nothrow).
  {
    int* x = new(std::nothrow) int;
    int* y = new(std::nothrow) int;
    IF_DEBUG_EXPECT_DEATH(free(x), "mismatch.*being dealloc.*free");
    IF_DEBUG_EXPECT_DEATH(delete [] x, "mismatch.*being dealloc.*delete *[[]");
    delete x;
    ::operator delete(y, std::nothrow);
  }

  // Allocate with new(nothrow)[].
  {
    int* x = new(std::nothrow) int[1];
    int* y = new(std::nothrow) int[1];
    IF_DEBUG_EXPECT_DEATH(free(x), "mismatch.*being dealloc.*free");
    IF_DEBUG_EXPECT_DEATH(delete x, "mismatch.*being dealloc.*delete");
    delete [] x;
    ::operator delete[](y, std::nothrow);
  }
}
#endif  // #ifdef OS_MACOSX

TEST(DebugAllocationTest, DoubleFree) {
  int* pint = new int;
  delete pint;
  IF_DEBUG_EXPECT_DEATH(delete pint, "has been already deallocated");
}

TEST(DebugAllocationTest, StompBefore) {
  int* pint = new int;
#ifndef NDEBUG   // don't stomp memory if we're not in a position to detect it
  pint[-1] = 5;
  IF_DEBUG_EXPECT_DEATH(delete pint, "a word before object");
#endif
}

TEST(DebugAllocationTest, StompAfter) {
  int* pint = new int;
#ifndef NDEBUG   // don't stomp memory if we're not in a position to detect it
  pint[1] = 5;
  IF_DEBUG_EXPECT_DEATH(delete pint, "a word after object");
#endif
}

TEST(DebugAllocationTest, FreeQueueTest) {
  // Verify that the allocator doesn't return blocks that were recently freed.
  int* x = new int;
  int* old_x = x;
  delete x;
  x = new int;
  #if 1
    // This check should not be read as a universal guarantee of behavior.  If
    // other threads are executing, it would be theoretically possible for this
    // check to fail despite the efforts of debugallocation.cc to the contrary.
    // It should always hold under the controlled conditions of this unittest,
    // however.
    EXPECT_NE(x, old_x);  // Allocator shouldn't return recently freed blocks
  #else
    // The below check passes, but since it isn't *required* to pass, I've left
    // it commented out.
    // EXPECT_EQ(x, old_x);
  #endif
  old_x = NULL;  // avoid breaking opt build with an unused variable warning.
  delete x;
}

TEST(DebugAllocationTest, DanglingPointerWriteTest) {
  // This test can only be run if debugging.
  //
  // If not debugging, the 'new' following the dangling write might not be
  // safe.  When debugging, we expect the (trashed) deleted block to be on the
  // list of recently-freed blocks, so the following 'new' will be safe.
#if 1
  int* x = new int;
  delete x;
  int poisoned_x_value = *x;
  *x = 1;  // a dangling write.

  char* s = new char[FLAGS_max_free_queue_size];
  // When we delete s, we push the storage that was previously allocated to x
  // off the end of the free queue.  At that point, the write to that memory
  // will be detected.
  IF_DEBUG_EXPECT_DEATH(delete [] s, "Memory was written to after being freed.");

  // restore the poisoned value of x so that we can delete s without causing a
  // crash.
  *x = poisoned_x_value;
  delete [] s;
#endif
}

TEST(DebugAllocationTest, DanglingWriteAtExitTest) {
  int *x = new int;
  delete x;
  int old_x_value = *x;
  *x = 1;
  // verify that dangling writes are caught at program termination if the
  // corrupted block never got pushed off of the end of the free queue.
  IF_DEBUG_EXPECT_DEATH(exit(0), "Memory was written to after being freed.");
  *x = old_x_value;  // restore x so that the test can exit successfully.
}

TEST(DebugAllocationTest, StackTraceWithDanglingWriteAtExitTest) {
  int *x = new int;
  delete x;
  int old_x_value = *x;
  *x = 1;
  // verify that we also get a stack trace when we have a dangling write.
  // The " @ " is part of the stack trace output.
  IF_DEBUG_EXPECT_DEATH(exit(0), " @ .*main");
  *x = old_x_value;  // restore x so that the test can exit successfully.
}

static size_t CurrentlyAllocatedBytes() {
  size_t value;
  CHECK(MallocExtension::instance()->GetNumericProperty(
            "generic.current_allocated_bytes", &value));
  return value;
}

TEST(DebugAllocationTest, CurrentlyAllocated) {
  // Clear the free queue
#if 1
  FLAGS_max_free_queue_size = 0;
  // Force a round-trip through the queue management code so that the
  // new size is seen and the queue of recently-freed blocks is flushed.
  free(malloc(1));
  FLAGS_max_free_queue_size = 1048576;
#endif

  // Free something and check that it disappears from allocated bytes
  // immediately.
  char* p = new char[1000];
  size_t after_malloc = CurrentlyAllocatedBytes();
  delete[] p;
  size_t after_free = CurrentlyAllocatedBytes();
  EXPECT_LE(after_free, after_malloc - 1000);
}

TEST(DebugAllocationTest, GetAllocatedSizeTest) {
#if 1
  // When debug_allocation is in effect, GetAllocatedSize should return
  // exactly requested size, since debug_allocation doesn't allow users
  // to write more than that.
  for (int i = 0; i < 10; ++i) {
    void *p = malloc(i);
    EXPECT_EQ(i, MallocExtension::instance()->GetAllocatedSize(p));
    free(p);
  }
#endif
  void* a = malloc(1000);
  EXPECT_GE(MallocExtension::instance()->GetAllocatedSize(a), 1000);
  // This is just a sanity check.  If we allocated too much, alloc is broken
  EXPECT_LE(MallocExtension::instance()->GetAllocatedSize(a), 5000);
  EXPECT_GE(MallocExtension::instance()->GetEstimatedAllocatedSize(1000), 1000);
  free(a);
}

TEST(DebugAllocationTest, HugeAlloc) {
  // This must not be a const variable so it doesn't form an
  // integral-constant-expression which can be *statically* rejected by the
  // compiler as too large for the allocation.
  size_t kTooBig = ~static_cast<size_t>(0);
  void* a = NULL;

#ifndef NDEBUG

  a = malloc(kTooBig);
  EXPECT_EQ(NULL, a);

  // kAlsoTooBig is small enough not to get caught by debugallocation's check,
  // but will still fall through to tcmalloc's check. This must also be
  // a non-const variable. See kTooBig for more details.
  size_t kAlsoTooBig = kTooBig - 1024;

  a = malloc(kAlsoTooBig);
  EXPECT_EQ(NULL, a);
#endif
}

int main(int argc, char** argv) {
  // If you run without args, we run the non-death parts of the test.
  // Otherwise, argv[1] should be a number saying which death-test
  // to run.  We will output a regexp we expect the death-message
  // to include, and then run the given death test (which hopefully
  // will produce that error message).  If argv[1] > the number of
  // death tests, we will run only the non-death parts.  One way to
  // tell when you are done with all tests is when no 'expected
  // regexp' message is printed for a given argv[1].
  if (argc < 2) {
    test_to_run = -1;   // will never match
  } else {
    test_to_run = atoi(argv[1]);
  }
  return RUN_ALL_TESTS();
}
