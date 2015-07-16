// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/trace_event/trace_event_memory.h"

#include <sstream>
#include <string>

#include "base/trace_event/trace_event_impl.h"
#include "testing/gtest/include/gtest/gtest.h"

#if defined(TCMALLOC_TRACE_MEMORY_SUPPORTED)
#include "third_party/tcmalloc/chromium/src/gperftools/heap-profiler.h"
#endif

namespace base {
namespace trace_event {

// Tests for the trace event memory tracking system. Exists as a class so it
// can be a friend of TraceMemoryController.
class TraceMemoryTest : public testing::Test {
 public:
  TraceMemoryTest() {}
  ~TraceMemoryTest() override {}

 private:
  DISALLOW_COPY_AND_ASSIGN(TraceMemoryTest);
};

//////////////////////////////////////////////////////////////////////////////

#if defined(TCMALLOC_TRACE_MEMORY_SUPPORTED)

TEST_F(TraceMemoryTest, TraceMemoryController) {
  MessageLoop message_loop;

  // Start with no observers of the TraceLog.
  EXPECT_EQ(0u, TraceLog::GetInstance()->GetObserverCountForTest());

  // Creating a controller adds it to the TraceLog observer list.
  scoped_ptr<TraceMemoryController> controller(new TraceMemoryController(
      message_loop.task_runner(), ::HeapProfilerWithPseudoStackStart,
      ::HeapProfilerStop, ::GetHeapProfile));
  EXPECT_EQ(1u, TraceLog::GetInstance()->GetObserverCountForTest());
  EXPECT_TRUE(
      TraceLog::GetInstance()->HasEnabledStateObserver(controller.get()));

  // By default the observer isn't dumping memory profiles.
  EXPECT_FALSE(controller->IsTimerRunningForTest());

  // Simulate enabling tracing.
  controller->StartProfiling();
  message_loop.RunUntilIdle();
  EXPECT_TRUE(controller->IsTimerRunningForTest());

  // Simulate disabling tracing.
  controller->StopProfiling();
  message_loop.RunUntilIdle();
  EXPECT_FALSE(controller->IsTimerRunningForTest());

  // Deleting the observer removes it from the TraceLog observer list.
  controller.reset();
  EXPECT_EQ(0u, TraceLog::GetInstance()->GetObserverCountForTest());
}

TEST_F(TraceMemoryTest, ScopedTraceMemory) {
  ScopedTraceMemory::InitForTest();

  // Start with an empty stack.
  EXPECT_EQ(0, ScopedTraceMemory::GetStackDepthForTest());

  {
    // Push an item.
    ScopedTraceMemory scope1("cat1", "name1");
    EXPECT_EQ(1, ScopedTraceMemory::GetStackDepthForTest());
    EXPECT_EQ("cat1", ScopedTraceMemory::GetScopeDataForTest(0).category);
    EXPECT_EQ("name1", ScopedTraceMemory::GetScopeDataForTest(0).name);

    {
      // One more item.
      ScopedTraceMemory scope2("cat2", "name2");
      EXPECT_EQ(2, ScopedTraceMemory::GetStackDepthForTest());
      EXPECT_EQ("cat2", ScopedTraceMemory::GetScopeDataForTest(1).category);
      EXPECT_EQ("name2", ScopedTraceMemory::GetScopeDataForTest(1).name);
    }

    // Ended scope 2.
    EXPECT_EQ(1, ScopedTraceMemory::GetStackDepthForTest());
  }

  // Ended scope 1.
  EXPECT_EQ(0, ScopedTraceMemory::GetStackDepthForTest());

  ScopedTraceMemory::CleanupForTest();
}

void TestDeepScopeNesting(int current, int depth) {
  EXPECT_EQ(current, ScopedTraceMemory::GetStackDepthForTest());
  ScopedTraceMemory scope("category", "name");
  if (current < depth)
    TestDeepScopeNesting(current + 1, depth);
  EXPECT_EQ(current + 1, ScopedTraceMemory::GetStackDepthForTest());
}

TEST_F(TraceMemoryTest, DeepScopeNesting) {
  ScopedTraceMemory::InitForTest();

  // Ensure really deep scopes don't crash.
  TestDeepScopeNesting(0, 100);

  ScopedTraceMemory::CleanupForTest();
}

#endif  // defined(TRACE_MEMORY_SUPPORTED)

/////////////////////////////////////////////////////////////////////////////

TEST_F(TraceMemoryTest, AppendHeapProfileTotalsAsTraceFormat) {
  // Empty input gives empty output.
  std::string empty_output;
  AppendHeapProfileTotalsAsTraceFormat("", &empty_output);
  EXPECT_EQ("", empty_output);

  // Typical case.
  const char input[] =
      "heap profile:    357:    55227 [ 14653:  2624014] @ heapprofile";
  const std::string kExpectedOutput =
      "{\"current_allocs\": 357, \"current_bytes\": 55227, \"trace\": \"\"}";
  std::string output;
  AppendHeapProfileTotalsAsTraceFormat(input, &output);
  EXPECT_EQ(kExpectedOutput, output);
}

TEST_F(TraceMemoryTest, AppendHeapProfileLineAsTraceFormat) {
  // Empty input gives empty output.
  std::string empty_output;
  EXPECT_FALSE(AppendHeapProfileLineAsTraceFormat("", &empty_output));
  EXPECT_EQ("", empty_output);

  // Invalid input returns false.
  std::string junk_output;
  EXPECT_FALSE(AppendHeapProfileLineAsTraceFormat("junk", &junk_output));

  // Input with normal category and name entries.
  const char kCategory[] = "category";
  const char kName[] = "name";
  std::ostringstream input;
  input << "   68:     4195 [  1087:    98009] @ " << &kCategory << " "
        << &kName;
  const std::string kExpectedOutput =
      ",\n"
      "{"
      "\"current_allocs\": 68, "
      "\"current_bytes\": 4195, "
      "\"trace\": \"name \""
      "}";
  std::string output;
  EXPECT_TRUE(
      AppendHeapProfileLineAsTraceFormat(input.str().c_str(), &output));
  EXPECT_EQ(kExpectedOutput, output);

  // Input with with the category "toplevel".
  // TODO(jamescook): Eliminate this special case and move the logic to the
  // trace viewer code.
  const char kTaskCategory[] = "toplevel";
  const char kTaskName[] = "TaskName";
  std::ostringstream input2;
  input2 << "   68:     4195 [  1087:    98009] @ " << &kTaskCategory << " "
        << &kTaskName;
  const std::string kExpectedOutput2 =
      ",\n"
      "{"
      "\"current_allocs\": 68, "
      "\"current_bytes\": 4195, "
      "\"trace\": \"TaskName->PostTask \""
      "}";
  std::string output2;
  EXPECT_TRUE(
      AppendHeapProfileLineAsTraceFormat(input2.str().c_str(), &output2));
  EXPECT_EQ(kExpectedOutput2, output2);

  // Zero current allocations is skipped.
  std::ostringstream zero_input;
  zero_input << "   0:     0 [  1087:    98009] @ " << &kCategory << " "
             << &kName;
  std::string zero_output;
  EXPECT_FALSE(AppendHeapProfileLineAsTraceFormat(zero_input.str().c_str(),
                                                  &zero_output));
  EXPECT_EQ("", zero_output);
}

TEST_F(TraceMemoryTest, AppendHeapProfileAsTraceFormat) {
  // Empty input gives empty output.
  std::string empty_output;
  AppendHeapProfileAsTraceFormat("", &empty_output);
  EXPECT_EQ("", empty_output);

  // Typical case.
  const char input[] =
      "heap profile:    357:    55227 [ 14653:  2624014] @ heapprofile\n"
      "   95:    40940 [   649:   114260] @\n"
      "   77:    32546 [   742:   106234] @ 0x0 0x0\n"
      "    0:        0 [   132:     4236] @ 0x0\n"
      "\n"
      "MAPPED_LIBRARIES:\n"
      "1be411fc1000-1be4139e4000 rw-p 00000000 00:00 0\n"
      "1be4139e4000-1be4139e5000 ---p 00000000 00:00 0\n";
  const std::string kExpectedOutput =
      "[{"
      "\"current_allocs\": 357, "
      "\"current_bytes\": 55227, "
      "\"trace\": \"\"},\n"
      "{\"current_allocs\": 95, "
      "\"current_bytes\": 40940, "
      "\"trace\": \"\"},\n"
      "{\"current_allocs\": 77, "
      "\"current_bytes\": 32546, "
      "\"trace\": \"null \""
      "}]\n";
  std::string output;
  AppendHeapProfileAsTraceFormat(input, &output);
  EXPECT_EQ(kExpectedOutput, output);
}

TEST_F(TraceMemoryTest, StringFromHexAddress) {
  EXPECT_STREQ("null", StringFromHexAddress("0x0"));
  EXPECT_STREQ("error", StringFromHexAddress("not an address"));
  const char kHello[] = "hello";
  std::ostringstream hex_address;
  hex_address << &kHello;
  EXPECT_STREQ(kHello, StringFromHexAddress(hex_address.str()));
}

}  // namespace trace_event
}  // namespace base
