// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/bind.h"
#include "base/synchronization/waitable_event.h"
#include "base/test/trace_event_analyzer.h"
#include "base/threading/platform_thread.h"
#include "testing/gmock/include/gmock/gmock.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace trace_analyzer {

namespace {

class TraceEventAnalyzerTest : public testing::Test {
 public:
  void ManualSetUp();
  void OnTraceDataCollected(
      base::WaitableEvent* flush_complete_event,
      const scoped_refptr<base::RefCountedString>& json_events_str,
      bool has_more_events);
  void BeginTracing();
  void EndTracing();

  base::trace_event::TraceResultBuffer::SimpleOutput output_;
  base::trace_event::TraceResultBuffer buffer_;
};

void TraceEventAnalyzerTest::ManualSetUp() {
  ASSERT_TRUE(base::trace_event::TraceLog::GetInstance());
  buffer_.SetOutputCallback(output_.GetCallback());
  output_.json_output.clear();
}

void TraceEventAnalyzerTest::OnTraceDataCollected(
    base::WaitableEvent* flush_complete_event,
    const scoped_refptr<base::RefCountedString>& json_events_str,
    bool has_more_events) {
  buffer_.AddFragment(json_events_str->data());
  if (!has_more_events)
    flush_complete_event->Signal();
}

void TraceEventAnalyzerTest::BeginTracing() {
  output_.json_output.clear();
  buffer_.Start();
  base::trace_event::TraceLog::GetInstance()->SetEnabled(
      base::trace_event::TraceConfig("*", ""),
      base::trace_event::TraceLog::RECORDING_MODE);
}

void TraceEventAnalyzerTest::EndTracing() {
  base::trace_event::TraceLog::GetInstance()->SetDisabled();
  base::WaitableEvent flush_complete_event(false, false);
  base::trace_event::TraceLog::GetInstance()->Flush(
      base::Bind(&TraceEventAnalyzerTest::OnTraceDataCollected,
                 base::Unretained(this),
                 base::Unretained(&flush_complete_event)));
  flush_complete_event.Wait();
  buffer_.Finish();
}

}  // namespace

TEST_F(TraceEventAnalyzerTest, NoEvents) {
  ManualSetUp();

  // Create an empty JSON event string:
  buffer_.Start();
  buffer_.Finish();

  scoped_ptr<TraceAnalyzer>
      analyzer(TraceAnalyzer::Create(output_.json_output));
  ASSERT_TRUE(analyzer.get());

  // Search for all events and verify that nothing is returned.
  TraceEventVector found;
  analyzer->FindEvents(Query::Bool(true), &found);
  EXPECT_EQ(0u, found.size());
}

TEST_F(TraceEventAnalyzerTest, TraceEvent) {
  ManualSetUp();

  int int_num = 2;
  double double_num = 3.5;
  const char str[] = "the string";

  TraceEvent event;
  event.arg_numbers["false"] = 0.0;
  event.arg_numbers["true"] = 1.0;
  event.arg_numbers["int"] = static_cast<double>(int_num);
  event.arg_numbers["double"] = double_num;
  event.arg_strings["string"] = str;

  ASSERT_TRUE(event.HasNumberArg("false"));
  ASSERT_TRUE(event.HasNumberArg("true"));
  ASSERT_TRUE(event.HasNumberArg("int"));
  ASSERT_TRUE(event.HasNumberArg("double"));
  ASSERT_TRUE(event.HasStringArg("string"));
  ASSERT_FALSE(event.HasNumberArg("notfound"));
  ASSERT_FALSE(event.HasStringArg("notfound"));

  EXPECT_FALSE(event.GetKnownArgAsBool("false"));
  EXPECT_TRUE(event.GetKnownArgAsBool("true"));
  EXPECT_EQ(int_num, event.GetKnownArgAsInt("int"));
  EXPECT_EQ(double_num, event.GetKnownArgAsDouble("double"));
  EXPECT_STREQ(str, event.GetKnownArgAsString("string").c_str());
}

TEST_F(TraceEventAnalyzerTest, QueryEventMember) {
  ManualSetUp();

  TraceEvent event;
  event.thread.process_id = 3;
  event.thread.thread_id = 4;
  event.timestamp = 1.5;
  event.phase = TRACE_EVENT_PHASE_BEGIN;
  event.category = "category";
  event.name = "name";
  event.id = "1";
  event.arg_numbers["num"] = 7.0;
  event.arg_strings["str"] = "the string";

  // Other event with all different members:
  TraceEvent other;
  other.thread.process_id = 5;
  other.thread.thread_id = 6;
  other.timestamp = 2.5;
  other.phase = TRACE_EVENT_PHASE_END;
  other.category = "category2";
  other.name = "name2";
  other.id = "2";
  other.arg_numbers["num2"] = 8.0;
  other.arg_strings["str2"] = "the string 2";

  event.other_event = &other;
  ASSERT_TRUE(event.has_other_event());
  double duration = event.GetAbsTimeToOtherEvent();

  Query event_pid = Query::EventPidIs(event.thread.process_id);
  Query event_tid = Query::EventTidIs(event.thread.thread_id);
  Query event_time = Query::EventTimeIs(event.timestamp);
  Query event_duration = Query::EventDurationIs(duration);
  Query event_phase = Query::EventPhaseIs(event.phase);
  Query event_category = Query::EventCategoryIs(event.category);
  Query event_name = Query::EventNameIs(event.name);
  Query event_id = Query::EventIdIs(event.id);
  Query event_has_arg1 = Query::EventHasNumberArg("num");
  Query event_has_arg2 = Query::EventHasStringArg("str");
  Query event_arg1 =
      (Query::EventArg("num") == Query::Double(event.arg_numbers["num"]));
  Query event_arg2 =
      (Query::EventArg("str") == Query::String(event.arg_strings["str"]));
  Query event_has_other = Query::EventHasOther();
  Query other_pid = Query::OtherPidIs(other.thread.process_id);
  Query other_tid = Query::OtherTidIs(other.thread.thread_id);
  Query other_time = Query::OtherTimeIs(other.timestamp);
  Query other_phase = Query::OtherPhaseIs(other.phase);
  Query other_category = Query::OtherCategoryIs(other.category);
  Query other_name = Query::OtherNameIs(other.name);
  Query other_id = Query::OtherIdIs(other.id);
  Query other_has_arg1 = Query::OtherHasNumberArg("num2");
  Query other_has_arg2 = Query::OtherHasStringArg("str2");
  Query other_arg1 =
      (Query::OtherArg("num2") == Query::Double(other.arg_numbers["num2"]));
  Query other_arg2 =
      (Query::OtherArg("str2") == Query::String(other.arg_strings["str2"]));

  EXPECT_TRUE(event_pid.Evaluate(event));
  EXPECT_TRUE(event_tid.Evaluate(event));
  EXPECT_TRUE(event_time.Evaluate(event));
  EXPECT_TRUE(event_duration.Evaluate(event));
  EXPECT_TRUE(event_phase.Evaluate(event));
  EXPECT_TRUE(event_category.Evaluate(event));
  EXPECT_TRUE(event_name.Evaluate(event));
  EXPECT_TRUE(event_id.Evaluate(event));
  EXPECT_TRUE(event_has_arg1.Evaluate(event));
  EXPECT_TRUE(event_has_arg2.Evaluate(event));
  EXPECT_TRUE(event_arg1.Evaluate(event));
  EXPECT_TRUE(event_arg2.Evaluate(event));
  EXPECT_TRUE(event_has_other.Evaluate(event));
  EXPECT_TRUE(other_pid.Evaluate(event));
  EXPECT_TRUE(other_tid.Evaluate(event));
  EXPECT_TRUE(other_time.Evaluate(event));
  EXPECT_TRUE(other_phase.Evaluate(event));
  EXPECT_TRUE(other_category.Evaluate(event));
  EXPECT_TRUE(other_name.Evaluate(event));
  EXPECT_TRUE(other_id.Evaluate(event));
  EXPECT_TRUE(other_has_arg1.Evaluate(event));
  EXPECT_TRUE(other_has_arg2.Evaluate(event));
  EXPECT_TRUE(other_arg1.Evaluate(event));
  EXPECT_TRUE(other_arg2.Evaluate(event));

  // Evaluate event queries against other to verify the queries fail when the
  // event members are wrong.
  EXPECT_FALSE(event_pid.Evaluate(other));
  EXPECT_FALSE(event_tid.Evaluate(other));
  EXPECT_FALSE(event_time.Evaluate(other));
  EXPECT_FALSE(event_duration.Evaluate(other));
  EXPECT_FALSE(event_phase.Evaluate(other));
  EXPECT_FALSE(event_category.Evaluate(other));
  EXPECT_FALSE(event_name.Evaluate(other));
  EXPECT_FALSE(event_id.Evaluate(other));
  EXPECT_FALSE(event_has_arg1.Evaluate(other));
  EXPECT_FALSE(event_has_arg2.Evaluate(other));
  EXPECT_FALSE(event_arg1.Evaluate(other));
  EXPECT_FALSE(event_arg2.Evaluate(other));
  EXPECT_FALSE(event_has_other.Evaluate(other));
}

TEST_F(TraceEventAnalyzerTest, BooleanOperators) {
  ManualSetUp();

  BeginTracing();
  {
    TRACE_EVENT_INSTANT1("cat1", "name1", TRACE_EVENT_SCOPE_THREAD, "num", 1);
    TRACE_EVENT_INSTANT1("cat1", "name2", TRACE_EVENT_SCOPE_THREAD, "num", 2);
    TRACE_EVENT_INSTANT1("cat2", "name3", TRACE_EVENT_SCOPE_THREAD, "num", 3);
    TRACE_EVENT_INSTANT1("cat2", "name4", TRACE_EVENT_SCOPE_THREAD, "num", 4);
  }
  EndTracing();

  scoped_ptr<TraceAnalyzer>
      analyzer(TraceAnalyzer::Create(output_.json_output));
  ASSERT_TRUE(analyzer);
  analyzer->SetIgnoreMetadataEvents(true);

  TraceEventVector found;

  // ==

  analyzer->FindEvents(Query::EventCategory() == Query::String("cat1"), &found);
  ASSERT_EQ(2u, found.size());
  EXPECT_STREQ("name1", found[0]->name.c_str());
  EXPECT_STREQ("name2", found[1]->name.c_str());

  analyzer->FindEvents(Query::EventArg("num") == Query::Int(2), &found);
  ASSERT_EQ(1u, found.size());
  EXPECT_STREQ("name2", found[0]->name.c_str());

  // !=

  analyzer->FindEvents(Query::EventCategory() != Query::String("cat1"), &found);
  ASSERT_EQ(2u, found.size());
  EXPECT_STREQ("name3", found[0]->name.c_str());
  EXPECT_STREQ("name4", found[1]->name.c_str());

  analyzer->FindEvents(Query::EventArg("num") != Query::Int(2), &found);
  ASSERT_EQ(3u, found.size());
  EXPECT_STREQ("name1", found[0]->name.c_str());
  EXPECT_STREQ("name3", found[1]->name.c_str());
  EXPECT_STREQ("name4", found[2]->name.c_str());

  // <
  analyzer->FindEvents(Query::EventArg("num") < Query::Int(2), &found);
  ASSERT_EQ(1u, found.size());
  EXPECT_STREQ("name1", found[0]->name.c_str());

  // <=
  analyzer->FindEvents(Query::EventArg("num") <= Query::Int(2), &found);
  ASSERT_EQ(2u, found.size());
  EXPECT_STREQ("name1", found[0]->name.c_str());
  EXPECT_STREQ("name2", found[1]->name.c_str());

  // >
  analyzer->FindEvents(Query::EventArg("num") > Query::Int(3), &found);
  ASSERT_EQ(1u, found.size());
  EXPECT_STREQ("name4", found[0]->name.c_str());

  // >=
  analyzer->FindEvents(Query::EventArg("num") >= Query::Int(4), &found);
  ASSERT_EQ(1u, found.size());
  EXPECT_STREQ("name4", found[0]->name.c_str());

  // &&
  analyzer->FindEvents(Query::EventName() != Query::String("name1") &&
                       Query::EventArg("num") < Query::Int(3), &found);
  ASSERT_EQ(1u, found.size());
  EXPECT_STREQ("name2", found[0]->name.c_str());

  // ||
  analyzer->FindEvents(Query::EventName() == Query::String("name1") ||
                       Query::EventArg("num") == Query::Int(3), &found);
  ASSERT_EQ(2u, found.size());
  EXPECT_STREQ("name1", found[0]->name.c_str());
  EXPECT_STREQ("name3", found[1]->name.c_str());

  // !
  analyzer->FindEvents(!(Query::EventName() == Query::String("name1") ||
                         Query::EventArg("num") == Query::Int(3)), &found);
  ASSERT_EQ(2u, found.size());
  EXPECT_STREQ("name2", found[0]->name.c_str());
  EXPECT_STREQ("name4", found[1]->name.c_str());
}

TEST_F(TraceEventAnalyzerTest, ArithmeticOperators) {
  ManualSetUp();

  BeginTracing();
  {
    // These events are searched for:
    TRACE_EVENT_INSTANT2("cat1", "math1", TRACE_EVENT_SCOPE_THREAD,
                         "a", 10, "b", 5);
    TRACE_EVENT_INSTANT2("cat1", "math2", TRACE_EVENT_SCOPE_THREAD,
                         "a", 10, "b", 10);
    // Extra events that never match, for noise:
    TRACE_EVENT_INSTANT2("noise", "math3", TRACE_EVENT_SCOPE_THREAD,
                         "a", 1,  "b", 3);
    TRACE_EVENT_INSTANT2("noise", "math4", TRACE_EVENT_SCOPE_THREAD,
                         "c", 10, "d", 5);
  }
  EndTracing();

  scoped_ptr<TraceAnalyzer>
      analyzer(TraceAnalyzer::Create(output_.json_output));
  ASSERT_TRUE(analyzer.get());

  TraceEventVector found;

  // Verify that arithmetic operators function:

  // +
  analyzer->FindEvents(Query::EventArg("a") + Query::EventArg("b") ==
                       Query::Int(20), &found);
  EXPECT_EQ(1u, found.size());
  EXPECT_STREQ("math2", found.front()->name.c_str());

  // -
  analyzer->FindEvents(Query::EventArg("a") - Query::EventArg("b") ==
                       Query::Int(5), &found);
  EXPECT_EQ(1u, found.size());
  EXPECT_STREQ("math1", found.front()->name.c_str());

  // *
  analyzer->FindEvents(Query::EventArg("a") * Query::EventArg("b") ==
                       Query::Int(50), &found);
  EXPECT_EQ(1u, found.size());
  EXPECT_STREQ("math1", found.front()->name.c_str());

  // /
  analyzer->FindEvents(Query::EventArg("a") / Query::EventArg("b") ==
                       Query::Int(2), &found);
  EXPECT_EQ(1u, found.size());
  EXPECT_STREQ("math1", found.front()->name.c_str());

  // %
  analyzer->FindEvents(Query::EventArg("a") % Query::EventArg("b") ==
                       Query::Int(0), &found);
  EXPECT_EQ(2u, found.size());

  // - (negate)
  analyzer->FindEvents(-Query::EventArg("b") == Query::Int(-10), &found);
  EXPECT_EQ(1u, found.size());
  EXPECT_STREQ("math2", found.front()->name.c_str());
}

TEST_F(TraceEventAnalyzerTest, StringPattern) {
  ManualSetUp();

  BeginTracing();
  {
    TRACE_EVENT_INSTANT0("cat1", "name1", TRACE_EVENT_SCOPE_THREAD);
    TRACE_EVENT_INSTANT0("cat1", "name2", TRACE_EVENT_SCOPE_THREAD);
    TRACE_EVENT_INSTANT0("cat1", "no match", TRACE_EVENT_SCOPE_THREAD);
    TRACE_EVENT_INSTANT0("cat1", "name3x", TRACE_EVENT_SCOPE_THREAD);
  }
  EndTracing();

  scoped_ptr<TraceAnalyzer>
      analyzer(TraceAnalyzer::Create(output_.json_output));
  ASSERT_TRUE(analyzer.get());
  analyzer->SetIgnoreMetadataEvents(true);

  TraceEventVector found;

  analyzer->FindEvents(Query::EventName() == Query::Pattern("name?"), &found);
  ASSERT_EQ(2u, found.size());
  EXPECT_STREQ("name1", found[0]->name.c_str());
  EXPECT_STREQ("name2", found[1]->name.c_str());

  analyzer->FindEvents(Query::EventName() == Query::Pattern("name*"), &found);
  ASSERT_EQ(3u, found.size());
  EXPECT_STREQ("name1", found[0]->name.c_str());
  EXPECT_STREQ("name2", found[1]->name.c_str());
  EXPECT_STREQ("name3x", found[2]->name.c_str());

  analyzer->FindEvents(Query::EventName() != Query::Pattern("name*"), &found);
  ASSERT_EQ(1u, found.size());
  EXPECT_STREQ("no match", found[0]->name.c_str());
}

// Test that duration queries work.
TEST_F(TraceEventAnalyzerTest, BeginEndDuration) {
  ManualSetUp();

  const base::TimeDelta kSleepTime = base::TimeDelta::FromMilliseconds(200);
  // We will search for events that have a duration of greater than 90% of the
  // sleep time, so that there is no flakiness.
  int64 duration_cutoff_us = (kSleepTime.InMicroseconds() * 9) / 10;

  BeginTracing();
  {
    TRACE_EVENT_BEGIN0("cat1", "name1"); // found by duration query
    TRACE_EVENT_BEGIN0("noise", "name2"); // not searched for, just noise
    {
      TRACE_EVENT_BEGIN0("cat2", "name3"); // found by duration query
      // next event not searched for, just noise
      TRACE_EVENT_INSTANT0("noise", "name4", TRACE_EVENT_SCOPE_THREAD);
      base::PlatformThread::Sleep(kSleepTime);
      TRACE_EVENT_BEGIN0("cat2", "name5"); // not found (duration too short)
      TRACE_EVENT_END0("cat2", "name5"); // not found (duration too short)
      TRACE_EVENT_END0("cat2", "name3"); // found by duration query
    }
    TRACE_EVENT_END0("noise", "name2"); // not searched for, just noise
    TRACE_EVENT_END0("cat1", "name1"); // found by duration query
  }
  EndTracing();

  scoped_ptr<TraceAnalyzer>
      analyzer(TraceAnalyzer::Create(output_.json_output));
  ASSERT_TRUE(analyzer.get());
  analyzer->AssociateBeginEndEvents();

  TraceEventVector found;
  analyzer->FindEvents(
      Query::MatchBeginWithEnd() &&
      Query::EventDuration() >
          Query::Int(static_cast<int>(duration_cutoff_us)) &&
      (Query::EventCategory() == Query::String("cat1") ||
       Query::EventCategory() == Query::String("cat2") ||
       Query::EventCategory() == Query::String("cat3")),
      &found);
  ASSERT_EQ(2u, found.size());
  EXPECT_STREQ("name1", found[0]->name.c_str());
  EXPECT_STREQ("name3", found[1]->name.c_str());
}

// Test that duration queries work.
TEST_F(TraceEventAnalyzerTest, CompleteDuration) {
  ManualSetUp();

  const base::TimeDelta kSleepTime = base::TimeDelta::FromMilliseconds(200);
  // We will search for events that have a duration of greater than 90% of the
  // sleep time, so that there is no flakiness.
  int64 duration_cutoff_us = (kSleepTime.InMicroseconds() * 9) / 10;

  BeginTracing();
  {
    TRACE_EVENT0("cat1", "name1"); // found by duration query
    TRACE_EVENT0("noise", "name2"); // not searched for, just noise
    {
      TRACE_EVENT0("cat2", "name3"); // found by duration query
      // next event not searched for, just noise
      TRACE_EVENT_INSTANT0("noise", "name4", TRACE_EVENT_SCOPE_THREAD);
      base::PlatformThread::Sleep(kSleepTime);
      TRACE_EVENT0("cat2", "name5"); // not found (duration too short)
    }
  }
  EndTracing();

  scoped_ptr<TraceAnalyzer>
      analyzer(TraceAnalyzer::Create(output_.json_output));
  ASSERT_TRUE(analyzer.get());
  analyzer->AssociateBeginEndEvents();

  TraceEventVector found;
  analyzer->FindEvents(
      Query::EventCompleteDuration() >
          Query::Int(static_cast<int>(duration_cutoff_us)) &&
      (Query::EventCategory() == Query::String("cat1") ||
       Query::EventCategory() == Query::String("cat2") ||
       Query::EventCategory() == Query::String("cat3")),
      &found);
  ASSERT_EQ(2u, found.size());
  EXPECT_STREQ("name1", found[0]->name.c_str());
  EXPECT_STREQ("name3", found[1]->name.c_str());
}

// Test AssociateBeginEndEvents
TEST_F(TraceEventAnalyzerTest, BeginEndAssocations) {
  ManualSetUp();

  BeginTracing();
  {
    TRACE_EVENT_END0("cat1", "name1"); // does not match out of order begin
    TRACE_EVENT_BEGIN0("cat1", "name2");
    TRACE_EVENT_INSTANT0("cat1", "name3", TRACE_EVENT_SCOPE_THREAD);
    TRACE_EVENT_BEGIN0("cat1", "name1");
    TRACE_EVENT_END0("cat1", "name2");
  }
  EndTracing();

  scoped_ptr<TraceAnalyzer>
      analyzer(TraceAnalyzer::Create(output_.json_output));
  ASSERT_TRUE(analyzer.get());
  analyzer->AssociateBeginEndEvents();

  TraceEventVector found;
  analyzer->FindEvents(Query::MatchBeginWithEnd(), &found);
  ASSERT_EQ(1u, found.size());
  EXPECT_STREQ("name2", found[0]->name.c_str());
}

// Test MergeAssociatedEventArgs
TEST_F(TraceEventAnalyzerTest, MergeAssociatedEventArgs) {
  ManualSetUp();

  const char arg_string[] = "arg_string";
  BeginTracing();
  {
    TRACE_EVENT_BEGIN0("cat1", "name1");
    TRACE_EVENT_END1("cat1", "name1", "arg", arg_string);
  }
  EndTracing();

  scoped_ptr<TraceAnalyzer>
      analyzer(TraceAnalyzer::Create(output_.json_output));
  ASSERT_TRUE(analyzer.get());
  analyzer->AssociateBeginEndEvents();

  TraceEventVector found;
  analyzer->FindEvents(Query::MatchBeginName("name1"), &found);
  ASSERT_EQ(1u, found.size());
  std::string arg_actual;
  EXPECT_FALSE(found[0]->GetArgAsString("arg", &arg_actual));

  analyzer->MergeAssociatedEventArgs();
  EXPECT_TRUE(found[0]->GetArgAsString("arg", &arg_actual));
  EXPECT_STREQ(arg_string, arg_actual.c_str());
}

// Test AssociateAsyncBeginEndEvents
TEST_F(TraceEventAnalyzerTest, AsyncBeginEndAssocations) {
  ManualSetUp();

  BeginTracing();
  {
    TRACE_EVENT_ASYNC_END0("cat1", "name1", 0xA); // no match / out of order
    TRACE_EVENT_ASYNC_BEGIN0("cat1", "name1", 0xB);
    TRACE_EVENT_ASYNC_BEGIN0("cat1", "name1", 0xC);
    TRACE_EVENT_INSTANT0("cat1", "name1", TRACE_EVENT_SCOPE_THREAD); // noise
    TRACE_EVENT0("cat1", "name1"); // noise
    TRACE_EVENT_ASYNC_END0("cat1", "name1", 0xB);
    TRACE_EVENT_ASYNC_END0("cat1", "name1", 0xC);
    TRACE_EVENT_ASYNC_BEGIN0("cat1", "name1", 0xA); // no match / out of order
  }
  EndTracing();

  scoped_ptr<TraceAnalyzer>
      analyzer(TraceAnalyzer::Create(output_.json_output));
  ASSERT_TRUE(analyzer.get());
  analyzer->AssociateAsyncBeginEndEvents();

  TraceEventVector found;
  analyzer->FindEvents(Query::MatchAsyncBeginWithNext(), &found);
  ASSERT_EQ(2u, found.size());
  EXPECT_STRCASEEQ("0xb", found[0]->id.c_str());
  EXPECT_STRCASEEQ("0xc", found[1]->id.c_str());
}

// Test AssociateAsyncBeginEndEvents
TEST_F(TraceEventAnalyzerTest, AsyncBeginEndAssocationsWithSteps) {
  ManualSetUp();

  BeginTracing();
  {
    TRACE_EVENT_ASYNC_STEP_INTO0("c", "n", 0xA, "s1");
    TRACE_EVENT_ASYNC_END0("c", "n", 0xA);
    TRACE_EVENT_ASYNC_BEGIN0("c", "n", 0xB);
    TRACE_EVENT_ASYNC_BEGIN0("c", "n", 0xC);
    TRACE_EVENT_ASYNC_STEP_PAST0("c", "n", 0xB, "s1");
    TRACE_EVENT_ASYNC_STEP_INTO0("c", "n", 0xC, "s1");
    TRACE_EVENT_ASYNC_STEP_INTO1("c", "n", 0xC, "s2", "a", 1);
    TRACE_EVENT_ASYNC_END0("c", "n", 0xB);
    TRACE_EVENT_ASYNC_END0("c", "n", 0xC);
    TRACE_EVENT_ASYNC_BEGIN0("c", "n", 0xA);
    TRACE_EVENT_ASYNC_STEP_INTO0("c", "n", 0xA, "s2");
  }
  EndTracing();

  scoped_ptr<TraceAnalyzer>
      analyzer(TraceAnalyzer::Create(output_.json_output));
  ASSERT_TRUE(analyzer.get());
  analyzer->AssociateAsyncBeginEndEvents();

  TraceEventVector found;
  analyzer->FindEvents(Query::MatchAsyncBeginWithNext(), &found);
  ASSERT_EQ(3u, found.size());

  EXPECT_STRCASEEQ("0xb", found[0]->id.c_str());
  EXPECT_EQ(TRACE_EVENT_PHASE_ASYNC_STEP_PAST, found[0]->other_event->phase);
  EXPECT_TRUE(found[0]->other_event->other_event);
  EXPECT_EQ(TRACE_EVENT_PHASE_ASYNC_END,
            found[0]->other_event->other_event->phase);

  EXPECT_STRCASEEQ("0xc", found[1]->id.c_str());
  EXPECT_EQ(TRACE_EVENT_PHASE_ASYNC_STEP_INTO, found[1]->other_event->phase);
  EXPECT_TRUE(found[1]->other_event->other_event);
  EXPECT_EQ(TRACE_EVENT_PHASE_ASYNC_STEP_INTO,
            found[1]->other_event->other_event->phase);
  double arg_actual = 0;
  EXPECT_TRUE(found[1]->other_event->other_event->GetArgAsNumber(
                  "a", &arg_actual));
  EXPECT_EQ(1.0, arg_actual);
  EXPECT_TRUE(found[1]->other_event->other_event->other_event);
  EXPECT_EQ(TRACE_EVENT_PHASE_ASYNC_END,
            found[1]->other_event->other_event->other_event->phase);

  EXPECT_STRCASEEQ("0xa", found[2]->id.c_str());
  EXPECT_EQ(TRACE_EVENT_PHASE_ASYNC_STEP_INTO, found[2]->other_event->phase);
}

// Test that the TraceAnalyzer custom associations work.
TEST_F(TraceEventAnalyzerTest, CustomAssociations) {
  ManualSetUp();

  // Add events that begin/end in pipelined ordering with unique ID parameter
  // to match up the begin/end pairs.
  BeginTracing();
  {
    // no begin match
    TRACE_EVENT_INSTANT1("cat1", "end", TRACE_EVENT_SCOPE_THREAD, "id", 1);
    // end is cat4
    TRACE_EVENT_INSTANT1("cat2", "begin", TRACE_EVENT_SCOPE_THREAD, "id", 2);
    // end is cat5
    TRACE_EVENT_INSTANT1("cat3", "begin", TRACE_EVENT_SCOPE_THREAD, "id", 3);
    TRACE_EVENT_INSTANT1("cat4", "end", TRACE_EVENT_SCOPE_THREAD, "id", 2);
    TRACE_EVENT_INSTANT1("cat5", "end", TRACE_EVENT_SCOPE_THREAD, "id", 3);
    // no end match
    TRACE_EVENT_INSTANT1("cat6", "begin", TRACE_EVENT_SCOPE_THREAD, "id", 1);
  }
  EndTracing();

  scoped_ptr<TraceAnalyzer>
      analyzer(TraceAnalyzer::Create(output_.json_output));
  ASSERT_TRUE(analyzer.get());

  // begin, end, and match queries to find proper begin/end pairs.
  Query begin(Query::EventName() == Query::String("begin"));
  Query end(Query::EventName() == Query::String("end"));
  Query match(Query::EventArg("id") == Query::OtherArg("id"));
  analyzer->AssociateEvents(begin, end, match);

  TraceEventVector found;

  // cat1 has no other_event.
  analyzer->FindEvents(Query::EventCategory() == Query::String("cat1") &&
                       Query::EventHasOther(), &found);
  EXPECT_EQ(0u, found.size());

  // cat1 has no other_event.
  analyzer->FindEvents(Query::EventCategory() == Query::String("cat1") &&
                       !Query::EventHasOther(), &found);
  EXPECT_EQ(1u, found.size());

  // cat6 has no other_event.
  analyzer->FindEvents(Query::EventCategory() == Query::String("cat6") &&
                       !Query::EventHasOther(), &found);
  EXPECT_EQ(1u, found.size());

  // cat2 and cat4 are associated.
  analyzer->FindEvents(Query::EventCategory() == Query::String("cat2") &&
                       Query::OtherCategory() == Query::String("cat4"), &found);
  EXPECT_EQ(1u, found.size());

  // cat4 and cat2 are not associated.
  analyzer->FindEvents(Query::EventCategory() == Query::String("cat4") &&
                       Query::OtherCategory() == Query::String("cat2"), &found);
  EXPECT_EQ(0u, found.size());

  // cat3 and cat5 are associated.
  analyzer->FindEvents(Query::EventCategory() == Query::String("cat3") &&
                       Query::OtherCategory() == Query::String("cat5"), &found);
  EXPECT_EQ(1u, found.size());

  // cat5 and cat3 are not associated.
  analyzer->FindEvents(Query::EventCategory() == Query::String("cat5") &&
                       Query::OtherCategory() == Query::String("cat3"), &found);
  EXPECT_EQ(0u, found.size());
}

// Verify that Query literals and types are properly casted.
TEST_F(TraceEventAnalyzerTest, Literals) {
  ManualSetUp();

  // Since these queries don't refer to the event data, the dummy event below
  // will never be accessed.
  TraceEvent dummy;
  char char_num = 5;
  short short_num = -5;
  EXPECT_TRUE((Query::Double(5.0) == Query::Int(char_num)).Evaluate(dummy));
  EXPECT_TRUE((Query::Double(-5.0) == Query::Int(short_num)).Evaluate(dummy));
  EXPECT_TRUE((Query::Double(1.0) == Query::Uint(1u)).Evaluate(dummy));
  EXPECT_TRUE((Query::Double(1.0) == Query::Int(1)).Evaluate(dummy));
  EXPECT_TRUE((Query::Double(-1.0) == Query::Int(-1)).Evaluate(dummy));
  EXPECT_TRUE((Query::Double(1.0) == Query::Double(1.0f)).Evaluate(dummy));
  EXPECT_TRUE((Query::Bool(true) == Query::Int(1)).Evaluate(dummy));
  EXPECT_TRUE((Query::Bool(false) == Query::Int(0)).Evaluate(dummy));
  EXPECT_TRUE((Query::Bool(true) == Query::Double(1.0f)).Evaluate(dummy));
  EXPECT_TRUE((Query::Bool(false) == Query::Double(0.0f)).Evaluate(dummy));
}

// Test GetRateStats.
TEST_F(TraceEventAnalyzerTest, RateStats) {
  std::vector<TraceEvent> events;
  events.reserve(100);
  TraceEventVector event_ptrs;
  TraceEvent event;
  event.timestamp = 0.0;
  double little_delta = 1.0;
  double big_delta = 10.0;
  double tiny_delta = 0.1;
  RateStats stats;
  RateStatsOptions options;

  // Insert 10 events, each apart by little_delta.
  for (int i = 0; i < 10; ++i) {
    event.timestamp += little_delta;
    events.push_back(event);
    event_ptrs.push_back(&events.back());
  }

  ASSERT_TRUE(GetRateStats(event_ptrs, &stats, NULL));
  EXPECT_EQ(little_delta, stats.mean_us);
  EXPECT_EQ(little_delta, stats.min_us);
  EXPECT_EQ(little_delta, stats.max_us);
  EXPECT_EQ(0.0, stats.standard_deviation_us);

  // Add an event apart by big_delta.
  event.timestamp += big_delta;
  events.push_back(event);
  event_ptrs.push_back(&events.back());

  ASSERT_TRUE(GetRateStats(event_ptrs, &stats, NULL));
  EXPECT_LT(little_delta, stats.mean_us);
  EXPECT_EQ(little_delta, stats.min_us);
  EXPECT_EQ(big_delta, stats.max_us);
  EXPECT_LT(0.0, stats.standard_deviation_us);

  // Trim off the biggest delta and verify stats.
  options.trim_min = 0;
  options.trim_max = 1;
  ASSERT_TRUE(GetRateStats(event_ptrs, &stats, &options));
  EXPECT_EQ(little_delta, stats.mean_us);
  EXPECT_EQ(little_delta, stats.min_us);
  EXPECT_EQ(little_delta, stats.max_us);
  EXPECT_EQ(0.0, stats.standard_deviation_us);

  // Add an event apart by tiny_delta.
  event.timestamp += tiny_delta;
  events.push_back(event);
  event_ptrs.push_back(&events.back());

  // Trim off both the biggest and tiniest delta and verify stats.
  options.trim_min = 1;
  options.trim_max = 1;
  ASSERT_TRUE(GetRateStats(event_ptrs, &stats, &options));
  EXPECT_EQ(little_delta, stats.mean_us);
  EXPECT_EQ(little_delta, stats.min_us);
  EXPECT_EQ(little_delta, stats.max_us);
  EXPECT_EQ(0.0, stats.standard_deviation_us);

  // Verify smallest allowed number of events.
  TraceEventVector few_event_ptrs;
  few_event_ptrs.push_back(&event);
  few_event_ptrs.push_back(&event);
  ASSERT_FALSE(GetRateStats(few_event_ptrs, &stats, NULL));
  few_event_ptrs.push_back(&event);
  ASSERT_TRUE(GetRateStats(few_event_ptrs, &stats, NULL));

  // Trim off more than allowed and verify failure.
  options.trim_min = 0;
  options.trim_max = 1;
  ASSERT_FALSE(GetRateStats(few_event_ptrs, &stats, &options));
}

// Test FindFirstOf and FindLastOf.
TEST_F(TraceEventAnalyzerTest, FindOf) {
  size_t num_events = 100;
  size_t index = 0;
  TraceEventVector event_ptrs;
  EXPECT_FALSE(FindFirstOf(event_ptrs, Query::Bool(true), 0, &index));
  EXPECT_FALSE(FindFirstOf(event_ptrs, Query::Bool(true), 10, &index));
  EXPECT_FALSE(FindLastOf(event_ptrs, Query::Bool(true), 0, &index));
  EXPECT_FALSE(FindLastOf(event_ptrs, Query::Bool(true), 10, &index));

  std::vector<TraceEvent> events;
  events.resize(num_events);
  for (size_t i = 0; i < events.size(); ++i)
    event_ptrs.push_back(&events[i]);
  size_t bam_index = num_events/2;
  events[bam_index].name = "bam";
  Query query_bam = Query::EventName() == Query::String(events[bam_index].name);

  // FindFirstOf
  EXPECT_FALSE(FindFirstOf(event_ptrs, Query::Bool(false), 0, &index));
  EXPECT_TRUE(FindFirstOf(event_ptrs, Query::Bool(true), 0, &index));
  EXPECT_EQ(0u, index);
  EXPECT_TRUE(FindFirstOf(event_ptrs, Query::Bool(true), 5, &index));
  EXPECT_EQ(5u, index);

  EXPECT_FALSE(FindFirstOf(event_ptrs, query_bam, bam_index + 1, &index));
  EXPECT_TRUE(FindFirstOf(event_ptrs, query_bam, 0, &index));
  EXPECT_EQ(bam_index, index);
  EXPECT_TRUE(FindFirstOf(event_ptrs, query_bam, bam_index, &index));
  EXPECT_EQ(bam_index, index);

  // FindLastOf
  EXPECT_FALSE(FindLastOf(event_ptrs, Query::Bool(false), 1000, &index));
  EXPECT_TRUE(FindLastOf(event_ptrs, Query::Bool(true), 1000, &index));
  EXPECT_EQ(num_events - 1, index);
  EXPECT_TRUE(FindLastOf(event_ptrs, Query::Bool(true), num_events - 5,
                         &index));
  EXPECT_EQ(num_events - 5, index);

  EXPECT_FALSE(FindLastOf(event_ptrs, query_bam, bam_index - 1, &index));
  EXPECT_TRUE(FindLastOf(event_ptrs, query_bam, num_events, &index));
  EXPECT_EQ(bam_index, index);
  EXPECT_TRUE(FindLastOf(event_ptrs, query_bam, bam_index, &index));
  EXPECT_EQ(bam_index, index);
}

// Test FindClosest.
TEST_F(TraceEventAnalyzerTest, FindClosest) {
  size_t index_1 = 0;
  size_t index_2 = 0;
  TraceEventVector event_ptrs;
  EXPECT_FALSE(FindClosest(event_ptrs, Query::Bool(true), 0,
                           &index_1, &index_2));

  size_t num_events = 5;
  std::vector<TraceEvent> events;
  events.resize(num_events);
  for (size_t i = 0; i < events.size(); ++i) {
    // timestamps go up exponentially so the lower index is always closer in
    // time than the higher index.
    events[i].timestamp = static_cast<double>(i) * static_cast<double>(i);
    event_ptrs.push_back(&events[i]);
  }
  events[0].name = "one";
  events[2].name = "two";
  events[4].name = "three";
  Query query_named = Query::EventName() != Query::String(std::string());
  Query query_one = Query::EventName() == Query::String("one");

  // Only one event matches query_one, so two closest can't be found.
  EXPECT_FALSE(FindClosest(event_ptrs, query_one, 0, &index_1, &index_2));

  EXPECT_TRUE(FindClosest(event_ptrs, query_one, 3, &index_1, NULL));
  EXPECT_EQ(0u, index_1);

  EXPECT_TRUE(FindClosest(event_ptrs, query_named, 1, &index_1, &index_2));
  EXPECT_EQ(0u, index_1);
  EXPECT_EQ(2u, index_2);

  EXPECT_TRUE(FindClosest(event_ptrs, query_named, 4, &index_1, &index_2));
  EXPECT_EQ(4u, index_1);
  EXPECT_EQ(2u, index_2);

  EXPECT_TRUE(FindClosest(event_ptrs, query_named, 3, &index_1, &index_2));
  EXPECT_EQ(2u, index_1);
  EXPECT_EQ(0u, index_2);
}

// Test CountMatches.
TEST_F(TraceEventAnalyzerTest, CountMatches) {
  TraceEventVector event_ptrs;
  EXPECT_EQ(0u, CountMatches(event_ptrs, Query::Bool(true), 0, 10));

  size_t num_events = 5;
  size_t num_named = 3;
  std::vector<TraceEvent> events;
  events.resize(num_events);
  for (size_t i = 0; i < events.size(); ++i)
    event_ptrs.push_back(&events[i]);
  events[0].name = "one";
  events[2].name = "two";
  events[4].name = "three";
  Query query_named = Query::EventName() != Query::String(std::string());
  Query query_one = Query::EventName() == Query::String("one");

  EXPECT_EQ(0u, CountMatches(event_ptrs, Query::Bool(false)));
  EXPECT_EQ(num_events, CountMatches(event_ptrs, Query::Bool(true)));
  EXPECT_EQ(num_events - 1, CountMatches(event_ptrs, Query::Bool(true),
                                         1, num_events));
  EXPECT_EQ(1u, CountMatches(event_ptrs, query_one));
  EXPECT_EQ(num_events - 1, CountMatches(event_ptrs, !query_one));
  EXPECT_EQ(num_named, CountMatches(event_ptrs, query_named));
}


}  // namespace trace_analyzer
