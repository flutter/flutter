// Copyright (c) 2011, Google Inc.
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

// ----
// Author: llib@google.com (Bill Clarke)

#include "config_for_unittests.h"
#include <assert.h>
#include <stdio.h>
#ifdef HAVE_MMAP
#include <sys/mman.h>
#endif
#ifdef HAVE_UNISTD_H
#include <unistd.h>    // for sleep()
#endif
#include <algorithm>
#include <string>
#include <vector>
#include <gperftools/malloc_hook.h>
#include "malloc_hook-inl.h"
#include "base/logging.h"
#include "base/simple_mutex.h"
#include "base/sysinfo.h"
#include "tests/testutil.h"

// On systems (like freebsd) that don't define MAP_ANONYMOUS, use the old
// form of the name instead.
#ifndef MAP_ANONYMOUS
# define MAP_ANONYMOUS MAP_ANON
#endif

namespace {

using std::string;
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

void Sleep(int seconds) {
#ifdef _MSC_VER
  _sleep(seconds * 1000);   // Windows's _sleep takes milliseconds argument
#else
  sleep(seconds);
#endif
}

using std::min;
using base::internal::kHookListMaxValues;

// Since HookList is a template and is defined in malloc_hook.cc, we can only
// use an instantiation of it from malloc_hook.cc.  We then reinterpret those
// values as integers for testing.
typedef base::internal::HookList<MallocHook::NewHook> TestHookList;

int TestHookList_Traverse(const TestHookList& list, int* output_array, int n) {
  MallocHook::NewHook values_as_hooks[kHookListMaxValues];
  int result = list.Traverse(values_as_hooks, min(n, kHookListMaxValues));
  for (int i = 0; i < result; ++i) {
    output_array[i] = reinterpret_cast<const int&>(values_as_hooks[i]);
  }
  return result;
}

bool TestHookList_Add(TestHookList* list, int val) {
  return list->Add(reinterpret_cast<MallocHook::NewHook>(val));
}

bool TestHookList_Remove(TestHookList* list, int val) {
  return list->Remove(reinterpret_cast<MallocHook::NewHook>(val));
}

// Note that this is almost the same as INIT_HOOK_LIST in malloc_hook.cc without
// the cast.
#define INIT_HOOK_LIST(initial_value) { 1, { initial_value } }

TEST(HookListTest, InitialValueExists) {
  TestHookList list = INIT_HOOK_LIST(69);
  int values[2] = { 0, 0 };
  EXPECT_EQ(1, TestHookList_Traverse(list, values, 2));
  EXPECT_EQ(69, values[0]);
  EXPECT_EQ(1, list.priv_end);
}

TEST(HookListTest, CanRemoveInitialValue) {
  TestHookList list = INIT_HOOK_LIST(69);
  ASSERT_TRUE(TestHookList_Remove(&list, 69));
  EXPECT_EQ(0, list.priv_end);

  int values[2] = { 0, 0 };
  EXPECT_EQ(0, TestHookList_Traverse(list, values, 2));
}

TEST(HookListTest, AddAppends) {
  TestHookList list = INIT_HOOK_LIST(69);
  ASSERT_TRUE(TestHookList_Add(&list, 42));
  EXPECT_EQ(2, list.priv_end);

  int values[2] = { 0, 0 };
  EXPECT_EQ(2, TestHookList_Traverse(list, values, 2));
  EXPECT_EQ(69, values[0]);
  EXPECT_EQ(42, values[1]);
}

TEST(HookListTest, RemoveWorksAndWillClearSize) {
  TestHookList list = INIT_HOOK_LIST(69);
  ASSERT_TRUE(TestHookList_Add(&list, 42));

  ASSERT_TRUE(TestHookList_Remove(&list, 69));
  EXPECT_EQ(2, list.priv_end);

  int values[2] = { 0, 0 };
  EXPECT_EQ(1, TestHookList_Traverse(list, values, 2));
  EXPECT_EQ(42, values[0]);

  ASSERT_TRUE(TestHookList_Remove(&list, 42));
  EXPECT_EQ(0, list.priv_end);
  EXPECT_EQ(0, TestHookList_Traverse(list, values, 2));
}

TEST(HookListTest, AddPrependsAfterRemove) {
  TestHookList list = INIT_HOOK_LIST(69);
  ASSERT_TRUE(TestHookList_Add(&list, 42));

  ASSERT_TRUE(TestHookList_Remove(&list, 69));
  EXPECT_EQ(2, list.priv_end);

  ASSERT_TRUE(TestHookList_Add(&list, 7));
  EXPECT_EQ(2, list.priv_end);

  int values[2] = { 0, 0 };
  EXPECT_EQ(2, TestHookList_Traverse(list, values, 2));
  EXPECT_EQ(7, values[0]);
  EXPECT_EQ(42, values[1]);
}

TEST(HookListTest, InvalidAddRejected) {
  TestHookList list = INIT_HOOK_LIST(69);
  EXPECT_FALSE(TestHookList_Add(&list, 0));

  int values[2] = { 0, 0 };
  EXPECT_EQ(1, TestHookList_Traverse(list, values, 2));
  EXPECT_EQ(69, values[0]);
  EXPECT_EQ(1, list.priv_end);
}

TEST(HookListTest, FillUpTheList) {
  TestHookList list = INIT_HOOK_LIST(69);
  int num_inserts = 0;
  while (TestHookList_Add(&list, ++num_inserts))
    ;
  EXPECT_EQ(kHookListMaxValues, num_inserts);
  EXPECT_EQ(kHookListMaxValues, list.priv_end);

  int values[kHookListMaxValues + 1];
  EXPECT_EQ(kHookListMaxValues, TestHookList_Traverse(list, values,
                                                      kHookListMaxValues));
  EXPECT_EQ(69, values[0]);
  for (int i = 1; i < kHookListMaxValues; ++i) {
    EXPECT_EQ(i, values[i]);
  }
}

void MultithreadedTestThread(TestHookList* list, int shift,
                             int thread_num) {
  string message;
  char buf[64];
  for (int i = 1; i < 1000; ++i) {
    // In each loop, we insert a unique value, check it exists, remove it, and
    // check it doesn't exist.  We also record some stats to log at the end of
    // each thread.  Each insertion location and the length of the list is
    // non-deterministic (except for the very first one, over all threads, and
    // after the very last one the list should be empty).
    int value = (i << shift) + thread_num;
    EXPECT_TRUE(TestHookList_Add(list, value));
    sched_yield();  // Ensure some more interleaving.
    int values[kHookListMaxValues + 1];
    int num_values = TestHookList_Traverse(*list, values, kHookListMaxValues);
    EXPECT_LT(0, num_values);
    int value_index;
    for (value_index = 0;
         value_index < num_values && values[value_index] != value;
         ++value_index)
      ;
    EXPECT_LT(value_index, num_values);  // Should have found value.
    snprintf(buf, sizeof(buf), "[%d/%d; ", value_index, num_values);
    message += buf;
    sched_yield();
    EXPECT_TRUE(TestHookList_Remove(list, value));
    sched_yield();
    num_values = TestHookList_Traverse(*list, values, kHookListMaxValues);
    for (value_index = 0;
         value_index < num_values && values[value_index] != value;
         ++value_index)
      ;
    EXPECT_EQ(value_index, num_values);  // Should not have found value.
    snprintf(buf, sizeof(buf), "%d]", num_values);
    message += buf;
    sched_yield();
  }
  fprintf(stderr, "thread %d: %s\n", thread_num, message.c_str());
}

static volatile int num_threads_remaining;
static TestHookList list = INIT_HOOK_LIST(69);
static Mutex threadcount_lock;

void MultithreadedTestThreadRunner(int thread_num) {
  // Wait for all threads to start running.
  {
    MutexLock ml(&threadcount_lock);
    assert(num_threads_remaining > 0);
    --num_threads_remaining;

    // We should use condvars and the like, but for this test, we'll
    // go simple and busy-wait.
    while (num_threads_remaining > 0) {
      threadcount_lock.Unlock();
      Sleep(1);
      threadcount_lock.Lock();
    }
  }

  // shift is the smallest number such that (1<<shift) > kHookListMaxValues
  int shift = 0;
  for (int i = kHookListMaxValues; i > 0; i >>= 1)
    shift += 1;

  MultithreadedTestThread(&list, shift, thread_num);
}


TEST(HookListTest, MultithreadedTest) {
  ASSERT_TRUE(TestHookList_Remove(&list, 69));
  ASSERT_EQ(0, list.priv_end);

  // Run kHookListMaxValues thread, each running MultithreadedTestThread.
  // First, we need to set up the rest of the globals.
  num_threads_remaining = kHookListMaxValues;   // a global var
  RunManyThreadsWithId(&MultithreadedTestThreadRunner, num_threads_remaining,
                       1 << 15);

  int values[kHookListMaxValues + 1];
  EXPECT_EQ(0, TestHookList_Traverse(list, values, kHookListMaxValues));
  EXPECT_EQ(0, list.priv_end);
}

// We only do mmap-hooking on (some) linux systems.
#if defined(HAVE_MMAP) && defined(__linux) && \
    (defined(__i386__) || defined(__x86_64__) || defined(__PPC__))

int mmap_calls = 0;
int mmap_matching_calls = 0;
int munmap_calls = 0;
int munmap_matching_calls = 0;
const int kMmapMagicFd = 1;
void* const kMmapMagicPointer = reinterpret_cast<void*>(1);

int MmapReplacement(const void* start,
                     size_t size,
                     int protection,
                     int flags,
                     int fd,
                     off_t offset,
                     void** result) {
  ++mmap_calls;
  if (fd == kMmapMagicFd) {
    ++mmap_matching_calls;
    *result = kMmapMagicPointer;
    return true;
  }
  return false;
}

int MunmapReplacement(const void* ptr, size_t size, int* result) {
  ++munmap_calls;
  if (ptr == kMmapMagicPointer) {
    ++munmap_matching_calls;
    *result = 0;
    return true;
  }
  return false;
}

TEST(MallocMookTest, MmapReplacements) {
  mmap_calls = mmap_matching_calls = munmap_calls = munmap_matching_calls = 0;
  MallocHook::SetMmapReplacement(&MmapReplacement);
  MallocHook::SetMunmapReplacement(&MunmapReplacement);
  EXPECT_EQ(kMmapMagicPointer, mmap(NULL, 1, PROT_READ, MAP_PRIVATE,
                                    kMmapMagicFd, 0));
  EXPECT_EQ(1, mmap_matching_calls);

  char* ptr = reinterpret_cast<char*>(
      mmap(NULL, 1, PROT_READ | PROT_WRITE,
           MAP_PRIVATE | MAP_ANONYMOUS, -1, 0));
  EXPECT_EQ(2, mmap_calls);
  EXPECT_EQ(1, mmap_matching_calls);
  ASSERT_NE(MAP_FAILED, ptr);
  *ptr = 'a';

  EXPECT_EQ(0, munmap(kMmapMagicPointer, 1));
  EXPECT_EQ(1, munmap_calls);
  EXPECT_EQ(1, munmap_matching_calls);

  EXPECT_EQ(0, munmap(ptr, 1));
  EXPECT_EQ(2, munmap_calls);
  EXPECT_EQ(1, munmap_matching_calls);

  // The DEATH test below is flaky, because we've just munmapped the memory,
  // making it available for mmap()ing again. There is no guarantee that it
  // will stay unmapped, and in fact it gets reused ~10% of the time.
  // It the area is reused, then not only we don't die, but we also corrupt
  // whoever owns that memory now.
  // EXPECT_DEATH(*ptr = 'a', "SIGSEGV");
}
#endif  // #ifdef HAVE_MMAP && linux && ...

}  // namespace

int main(int argc, char** argv) {
  return RUN_ALL_TESTS();
}
