// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <math.h>
#include <cstdlib>

#include "base/bind.h"
#include "base/command_line.h"
#include "base/json/json_reader.h"
#include "base/json/json_writer.h"
#include "base/location.h"
#include "base/memory/ref_counted_memory.h"
#include "base/memory/scoped_ptr.h"
#include "base/memory/singleton.h"
#include "base/process/process_handle.h"
#include "base/single_thread_task_runner.h"
#include "base/strings/stringprintf.h"
#include "base/synchronization/waitable_event.h"
#include "base/threading/platform_thread.h"
#include "base/threading/thread.h"
#include "base/time/time.h"
#include "base/trace_event/trace_event.h"
#include "base/trace_event/trace_event_synthetic_delay.h"
#include "base/values.h"
#include "testing/gmock/include/gmock/gmock.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {
namespace trace_event {

namespace {

enum CompareOp {
  IS_EQUAL,
  IS_NOT_EQUAL,
};

struct JsonKeyValue {
  const char* key;
  const char* value;
  CompareOp op;
};

const int kThreadId = 42;
const int kAsyncId = 5;
const char kAsyncIdStr[] = "0x5";
const int kAsyncId2 = 6;
const char kAsyncId2Str[] = "0x6";

const  char kRecordAllCategoryFilter[] = "*";

class TraceEventTestFixture : public testing::Test {
 public:
  void OnTraceDataCollected(
      WaitableEvent* flush_complete_event,
      const scoped_refptr<base::RefCountedString>& events_str,
      bool has_more_events);
  void OnWatchEventMatched() {
    ++event_watch_notification_;
  }
  DictionaryValue* FindMatchingTraceEntry(const JsonKeyValue* key_values);
  DictionaryValue* FindNamePhase(const char* name, const char* phase);
  DictionaryValue* FindNamePhaseKeyValue(const char* name,
                                         const char* phase,
                                         const char* key,
                                         const char* value);
  void DropTracedMetadataRecords();
  bool FindMatchingValue(const char* key,
                         const char* value);
  bool FindNonMatchingValue(const char* key,
                            const char* value);
  void Clear() {
    trace_parsed_.Clear();
    json_output_.json_output.clear();
  }

  void BeginTrace() {
    BeginSpecificTrace("*");
  }

  void BeginSpecificTrace(const std::string& filter) {
    event_watch_notification_ = 0;
    TraceLog::GetInstance()->SetEnabled(TraceConfig(filter, ""),
                                        TraceLog::RECORDING_MODE);
  }

  void EndTraceAndFlush() {
    WaitableEvent flush_complete_event(false, false);
    EndTraceAndFlushAsync(&flush_complete_event);
    flush_complete_event.Wait();
  }

  // Used when testing thread-local buffers which requires the thread initiating
  // flush to have a message loop.
  void EndTraceAndFlushInThreadWithMessageLoop() {
    WaitableEvent flush_complete_event(false, false);
    Thread flush_thread("flush");
    flush_thread.Start();
    flush_thread.task_runner()->PostTask(
        FROM_HERE, base::Bind(&TraceEventTestFixture::EndTraceAndFlushAsync,
                              base::Unretained(this), &flush_complete_event));
    flush_complete_event.Wait();
  }

  void EndTraceAndFlushAsync(WaitableEvent* flush_complete_event) {
    TraceLog::GetInstance()->SetDisabled();
    TraceLog::GetInstance()->Flush(
        base::Bind(&TraceEventTestFixture::OnTraceDataCollected,
                   base::Unretained(static_cast<TraceEventTestFixture*>(this)),
                   base::Unretained(flush_complete_event)));
  }

  void FlushMonitoring() {
    WaitableEvent flush_complete_event(false, false);
    FlushMonitoring(&flush_complete_event);
    flush_complete_event.Wait();
  }

  void FlushMonitoring(WaitableEvent* flush_complete_event) {
    TraceLog::GetInstance()->FlushButLeaveBufferIntact(
        base::Bind(&TraceEventTestFixture::OnTraceDataCollected,
                   base::Unretained(static_cast<TraceEventTestFixture*>(this)),
                   base::Unretained(flush_complete_event)));
  }

  void SetUp() override {
    const char* name = PlatformThread::GetName();
    old_thread_name_ = name ? strdup(name) : NULL;

    TraceLog::DeleteForTesting();
    TraceLog* tracelog = TraceLog::GetInstance();
    ASSERT_TRUE(tracelog);
    ASSERT_FALSE(tracelog->IsEnabled());
    trace_buffer_.SetOutputCallback(json_output_.GetCallback());
    event_watch_notification_ = 0;
  }
  void TearDown() override {
    if (TraceLog::GetInstance())
      EXPECT_FALSE(TraceLog::GetInstance()->IsEnabled());
    PlatformThread::SetName(old_thread_name_ ? old_thread_name_ : "");
    free(old_thread_name_);
    old_thread_name_ = NULL;
    // We want our singleton torn down after each test.
    TraceLog::DeleteForTesting();
  }

  char* old_thread_name_;
  ListValue trace_parsed_;
  TraceResultBuffer trace_buffer_;
  TraceResultBuffer::SimpleOutput json_output_;
  int event_watch_notification_;

 private:
  // We want our singleton torn down after each test.
  ShadowingAtExitManager at_exit_manager_;
  Lock lock_;
};

void TraceEventTestFixture::OnTraceDataCollected(
    WaitableEvent* flush_complete_event,
    const scoped_refptr<base::RefCountedString>& events_str,
    bool has_more_events) {
  AutoLock lock(lock_);
  json_output_.json_output.clear();
  trace_buffer_.Start();
  trace_buffer_.AddFragment(events_str->data());
  trace_buffer_.Finish();

  scoped_ptr<Value> root;
  root.reset(base::JSONReader::DeprecatedRead(
      json_output_.json_output, JSON_PARSE_RFC | JSON_DETACHABLE_CHILDREN));

  if (!root.get()) {
    LOG(ERROR) << json_output_.json_output;
  }

  ListValue* root_list = NULL;
  ASSERT_TRUE(root.get());
  ASSERT_TRUE(root->GetAsList(&root_list));

  // Move items into our aggregate collection
  while (root_list->GetSize()) {
    scoped_ptr<Value> item;
    root_list->Remove(0, &item);
    trace_parsed_.Append(item.release());
  }

  if (!has_more_events)
    flush_complete_event->Signal();
}

static bool CompareJsonValues(const std::string& lhs,
                              const std::string& rhs,
                              CompareOp op) {
  switch (op) {
    case IS_EQUAL:
      return lhs == rhs;
    case IS_NOT_EQUAL:
      return lhs != rhs;
    default:
      CHECK(0);
  }
  return false;
}

static bool IsKeyValueInDict(const JsonKeyValue* key_value,
                             DictionaryValue* dict) {
  Value* value = NULL;
  std::string value_str;
  if (dict->Get(key_value->key, &value) &&
      value->GetAsString(&value_str) &&
      CompareJsonValues(value_str, key_value->value, key_value->op))
    return true;

  // Recurse to test arguments
  DictionaryValue* args_dict = NULL;
  dict->GetDictionary("args", &args_dict);
  if (args_dict)
    return IsKeyValueInDict(key_value, args_dict);

  return false;
}

static bool IsAllKeyValueInDict(const JsonKeyValue* key_values,
                                DictionaryValue* dict) {
  // Scan all key_values, they must all be present and equal.
  while (key_values && key_values->key) {
    if (!IsKeyValueInDict(key_values, dict))
      return false;
    ++key_values;
  }
  return true;
}

DictionaryValue* TraceEventTestFixture::FindMatchingTraceEntry(
    const JsonKeyValue* key_values) {
  // Scan all items
  size_t trace_parsed_count = trace_parsed_.GetSize();
  for (size_t i = 0; i < trace_parsed_count; i++) {
    Value* value = NULL;
    trace_parsed_.Get(i, &value);
    if (!value || value->GetType() != Value::TYPE_DICTIONARY)
      continue;
    DictionaryValue* dict = static_cast<DictionaryValue*>(value);

    if (IsAllKeyValueInDict(key_values, dict))
      return dict;
  }
  return NULL;
}

void TraceEventTestFixture::DropTracedMetadataRecords() {
  scoped_ptr<ListValue> old_trace_parsed(trace_parsed_.DeepCopy());
  size_t old_trace_parsed_size = old_trace_parsed->GetSize();
  trace_parsed_.Clear();

  for (size_t i = 0; i < old_trace_parsed_size; i++) {
    Value* value = NULL;
    old_trace_parsed->Get(i, &value);
    if (!value || value->GetType() != Value::TYPE_DICTIONARY) {
      trace_parsed_.Append(value->DeepCopy());
      continue;
    }
    DictionaryValue* dict = static_cast<DictionaryValue*>(value);
    std::string tmp;
    if (dict->GetString("ph", &tmp) && tmp == "M")
      continue;

    trace_parsed_.Append(value->DeepCopy());
  }
}

DictionaryValue* TraceEventTestFixture::FindNamePhase(const char* name,
                                                      const char* phase) {
  JsonKeyValue key_values[] = {
    {"name", name, IS_EQUAL},
    {"ph", phase, IS_EQUAL},
    {0, 0, IS_EQUAL}
  };
  return FindMatchingTraceEntry(key_values);
}

DictionaryValue* TraceEventTestFixture::FindNamePhaseKeyValue(
    const char* name,
    const char* phase,
    const char* key,
    const char* value) {
  JsonKeyValue key_values[] = {
    {"name", name, IS_EQUAL},
    {"ph", phase, IS_EQUAL},
    {key, value, IS_EQUAL},
    {0, 0, IS_EQUAL}
  };
  return FindMatchingTraceEntry(key_values);
}

bool TraceEventTestFixture::FindMatchingValue(const char* key,
                                              const char* value) {
  JsonKeyValue key_values[] = {
    {key, value, IS_EQUAL},
    {0, 0, IS_EQUAL}
  };
  return FindMatchingTraceEntry(key_values);
}

bool TraceEventTestFixture::FindNonMatchingValue(const char* key,
                                                 const char* value) {
  JsonKeyValue key_values[] = {
    {key, value, IS_NOT_EQUAL},
    {0, 0, IS_EQUAL}
  };
  return FindMatchingTraceEntry(key_values);
}

bool IsStringInDict(const char* string_to_match, const DictionaryValue* dict) {
  for (DictionaryValue::Iterator it(*dict); !it.IsAtEnd(); it.Advance()) {
    if (it.key().find(string_to_match) != std::string::npos)
      return true;

    std::string value_str;
    it.value().GetAsString(&value_str);
    if (value_str.find(string_to_match) != std::string::npos)
      return true;
  }

  // Recurse to test arguments
  const DictionaryValue* args_dict = NULL;
  dict->GetDictionary("args", &args_dict);
  if (args_dict)
    return IsStringInDict(string_to_match, args_dict);

  return false;
}

const DictionaryValue* FindTraceEntry(
    const ListValue& trace_parsed,
    const char* string_to_match,
    const DictionaryValue* match_after_this_item = NULL) {
  // Scan all items
  size_t trace_parsed_count = trace_parsed.GetSize();
  for (size_t i = 0; i < trace_parsed_count; i++) {
    const Value* value = NULL;
    trace_parsed.Get(i, &value);
    if (match_after_this_item) {
      if (value == match_after_this_item)
         match_after_this_item = NULL;
      continue;
    }
    if (!value || value->GetType() != Value::TYPE_DICTIONARY)
      continue;
    const DictionaryValue* dict = static_cast<const DictionaryValue*>(value);

    if (IsStringInDict(string_to_match, dict))
      return dict;
  }
  return NULL;
}

std::vector<const DictionaryValue*> FindTraceEntries(
    const ListValue& trace_parsed,
    const char* string_to_match) {
  std::vector<const DictionaryValue*> hits;
  size_t trace_parsed_count = trace_parsed.GetSize();
  for (size_t i = 0; i < trace_parsed_count; i++) {
    const Value* value = NULL;
    trace_parsed.Get(i, &value);
    if (!value || value->GetType() != Value::TYPE_DICTIONARY)
      continue;
    const DictionaryValue* dict = static_cast<const DictionaryValue*>(value);

    if (IsStringInDict(string_to_match, dict))
      hits.push_back(dict);
  }
  return hits;
}

const char kControlCharacters[] = "\001\002\003\n\r";

void TraceWithAllMacroVariants(WaitableEvent* task_complete_event) {
  {
    TRACE_EVENT_BEGIN_ETW("TRACE_EVENT_BEGIN_ETW call", 0x1122, "extrastring1");
    TRACE_EVENT_END_ETW("TRACE_EVENT_END_ETW call", 0x3344, "extrastring2");
    TRACE_EVENT_INSTANT_ETW("TRACE_EVENT_INSTANT_ETW call",
                            0x5566, "extrastring3");

    TRACE_EVENT0("all", "TRACE_EVENT0 call");
    TRACE_EVENT1("all", "TRACE_EVENT1 call", "name1", "value1");
    TRACE_EVENT2("all", "TRACE_EVENT2 call",
                 "name1", "\"value1\"",
                 "name2", "value\\2");

    TRACE_EVENT_INSTANT0("all", "TRACE_EVENT_INSTANT0 call",
                         TRACE_EVENT_SCOPE_GLOBAL);
    TRACE_EVENT_INSTANT1("all", "TRACE_EVENT_INSTANT1 call",
                         TRACE_EVENT_SCOPE_PROCESS, "name1", "value1");
    TRACE_EVENT_INSTANT2("all", "TRACE_EVENT_INSTANT2 call",
                         TRACE_EVENT_SCOPE_THREAD,
                         "name1", "value1",
                         "name2", "value2");

    TRACE_EVENT_BEGIN0("all", "TRACE_EVENT_BEGIN0 call");
    TRACE_EVENT_BEGIN1("all", "TRACE_EVENT_BEGIN1 call", "name1", "value1");
    TRACE_EVENT_BEGIN2("all", "TRACE_EVENT_BEGIN2 call",
                       "name1", "value1",
                       "name2", "value2");

    TRACE_EVENT_END0("all", "TRACE_EVENT_END0 call");
    TRACE_EVENT_END1("all", "TRACE_EVENT_END1 call", "name1", "value1");
    TRACE_EVENT_END2("all", "TRACE_EVENT_END2 call",
                     "name1", "value1",
                     "name2", "value2");

    TRACE_EVENT_ASYNC_BEGIN0("all", "TRACE_EVENT_ASYNC_BEGIN0 call", kAsyncId);
    TRACE_EVENT_ASYNC_BEGIN1("all", "TRACE_EVENT_ASYNC_BEGIN1 call", kAsyncId,
                             "name1", "value1");
    TRACE_EVENT_ASYNC_BEGIN2("all", "TRACE_EVENT_ASYNC_BEGIN2 call", kAsyncId,
                             "name1", "value1",
                             "name2", "value2");

    TRACE_EVENT_ASYNC_STEP_INTO0("all", "TRACE_EVENT_ASYNC_STEP_INTO0 call",
                                 kAsyncId, "step_begin1");
    TRACE_EVENT_ASYNC_STEP_INTO1("all", "TRACE_EVENT_ASYNC_STEP_INTO1 call",
                                 kAsyncId, "step_begin2", "name1", "value1");

    TRACE_EVENT_ASYNC_END0("all", "TRACE_EVENT_ASYNC_END0 call", kAsyncId);
    TRACE_EVENT_ASYNC_END1("all", "TRACE_EVENT_ASYNC_END1 call", kAsyncId,
                           "name1", "value1");
    TRACE_EVENT_ASYNC_END2("all", "TRACE_EVENT_ASYNC_END2 call", kAsyncId,
                           "name1", "value1",
                           "name2", "value2");

    TRACE_EVENT_BEGIN_ETW("TRACE_EVENT_BEGIN_ETW0 call", kAsyncId, NULL);
    TRACE_EVENT_BEGIN_ETW("TRACE_EVENT_BEGIN_ETW1 call", kAsyncId, "value");
    TRACE_EVENT_END_ETW("TRACE_EVENT_END_ETW0 call", kAsyncId, NULL);
    TRACE_EVENT_END_ETW("TRACE_EVENT_END_ETW1 call", kAsyncId, "value");
    TRACE_EVENT_INSTANT_ETW("TRACE_EVENT_INSTANT_ETW0 call", kAsyncId, NULL);
    TRACE_EVENT_INSTANT_ETW("TRACE_EVENT_INSTANT_ETW1 call", kAsyncId, "value");

    TRACE_COUNTER1("all", "TRACE_COUNTER1 call", 31415);
    TRACE_COUNTER2("all", "TRACE_COUNTER2 call",
                   "a", 30000,
                   "b", 1415);

    TRACE_COUNTER_ID1("all", "TRACE_COUNTER_ID1 call", 0x319009, 31415);
    TRACE_COUNTER_ID2("all", "TRACE_COUNTER_ID2 call", 0x319009,
                      "a", 30000, "b", 1415);

    TRACE_EVENT_COPY_BEGIN_WITH_ID_TID_AND_TIMESTAMP0("all",
        "TRACE_EVENT_COPY_BEGIN_WITH_ID_TID_AND_TIMESTAMP0 call",
        kAsyncId, kThreadId, 12345);
    TRACE_EVENT_COPY_END_WITH_ID_TID_AND_TIMESTAMP0("all",
        "TRACE_EVENT_COPY_END_WITH_ID_TID_AND_TIMESTAMP0 call",
        kAsyncId, kThreadId, 23456);

    TRACE_EVENT_BEGIN_WITH_ID_TID_AND_TIMESTAMP0("all",
        "TRACE_EVENT_BEGIN_WITH_ID_TID_AND_TIMESTAMP0 call",
        kAsyncId2, kThreadId, 34567);
    TRACE_EVENT_ASYNC_STEP_PAST0("all", "TRACE_EVENT_ASYNC_STEP_PAST0 call",
                                 kAsyncId2, "step_end1");
    TRACE_EVENT_ASYNC_STEP_PAST1("all", "TRACE_EVENT_ASYNC_STEP_PAST1 call",
                                 kAsyncId2, "step_end2", "name1", "value1");

    TRACE_EVENT_END_WITH_ID_TID_AND_TIMESTAMP0("all",
        "TRACE_EVENT_END_WITH_ID_TID_AND_TIMESTAMP0 call",
        kAsyncId2, kThreadId, 45678);

    TRACE_EVENT_OBJECT_CREATED_WITH_ID("all", "tracked object 1", 0x42);
    TRACE_EVENT_OBJECT_SNAPSHOT_WITH_ID(
        "all", "tracked object 1", 0x42, "hello");
    TRACE_EVENT_OBJECT_DELETED_WITH_ID("all", "tracked object 1", 0x42);

    TraceScopedTrackableObject<int> trackable("all", "tracked object 2",
                                              0x2128506);
    trackable.snapshot("world");

    TRACE_EVENT1(kControlCharacters, kControlCharacters,
                 kControlCharacters, kControlCharacters);
  }  // Scope close causes TRACE_EVENT0 etc to send their END events.

  if (task_complete_event)
    task_complete_event->Signal();
}

void ValidateAllTraceMacrosCreatedData(const ListValue& trace_parsed) {
  const DictionaryValue* item = NULL;

#define EXPECT_FIND_(string) \
    item = FindTraceEntry(trace_parsed, string); \
    EXPECT_TRUE(item);
#define EXPECT_NOT_FIND_(string) \
    item = FindTraceEntry(trace_parsed, string); \
    EXPECT_FALSE(item);
#define EXPECT_SUB_FIND_(string) \
    if (item) \
      EXPECT_TRUE(IsStringInDict(string, item));

  EXPECT_FIND_("ETW Trace Event");
  EXPECT_FIND_("all");
  EXPECT_FIND_("TRACE_EVENT_BEGIN_ETW call");
  {
    std::string str_val;
    EXPECT_TRUE(item && item->GetString("args.id", &str_val));
    EXPECT_STREQ("0x1122", str_val.c_str());
  }
  EXPECT_SUB_FIND_("extrastring1");
  EXPECT_FIND_("TRACE_EVENT_END_ETW call");
  EXPECT_FIND_("TRACE_EVENT_INSTANT_ETW call");
  EXPECT_FIND_("TRACE_EVENT0 call");
  {
    std::string ph;
    std::string ph_end;
    EXPECT_TRUE((item = FindTraceEntry(trace_parsed, "TRACE_EVENT0 call")));
    EXPECT_TRUE((item && item->GetString("ph", &ph)));
    EXPECT_EQ("X", ph);
    item = FindTraceEntry(trace_parsed, "TRACE_EVENT0 call", item);
    EXPECT_FALSE(item);
  }
  EXPECT_FIND_("TRACE_EVENT1 call");
  EXPECT_SUB_FIND_("name1");
  EXPECT_SUB_FIND_("value1");
  EXPECT_FIND_("TRACE_EVENT2 call");
  EXPECT_SUB_FIND_("name1");
  EXPECT_SUB_FIND_("\"value1\"");
  EXPECT_SUB_FIND_("name2");
  EXPECT_SUB_FIND_("value\\2");

  EXPECT_FIND_("TRACE_EVENT_INSTANT0 call");
  {
    std::string scope;
    EXPECT_TRUE((item && item->GetString("s", &scope)));
    EXPECT_EQ("g", scope);
  }
  EXPECT_FIND_("TRACE_EVENT_INSTANT1 call");
  {
    std::string scope;
    EXPECT_TRUE((item && item->GetString("s", &scope)));
    EXPECT_EQ("p", scope);
  }
  EXPECT_SUB_FIND_("name1");
  EXPECT_SUB_FIND_("value1");
  EXPECT_FIND_("TRACE_EVENT_INSTANT2 call");
  {
    std::string scope;
    EXPECT_TRUE((item && item->GetString("s", &scope)));
    EXPECT_EQ("t", scope);
  }
  EXPECT_SUB_FIND_("name1");
  EXPECT_SUB_FIND_("value1");
  EXPECT_SUB_FIND_("name2");
  EXPECT_SUB_FIND_("value2");

  EXPECT_FIND_("TRACE_EVENT_BEGIN0 call");
  EXPECT_FIND_("TRACE_EVENT_BEGIN1 call");
  EXPECT_SUB_FIND_("name1");
  EXPECT_SUB_FIND_("value1");
  EXPECT_FIND_("TRACE_EVENT_BEGIN2 call");
  EXPECT_SUB_FIND_("name1");
  EXPECT_SUB_FIND_("value1");
  EXPECT_SUB_FIND_("name2");
  EXPECT_SUB_FIND_("value2");

  EXPECT_FIND_("TRACE_EVENT_END0 call");
  EXPECT_FIND_("TRACE_EVENT_END1 call");
  EXPECT_SUB_FIND_("name1");
  EXPECT_SUB_FIND_("value1");
  EXPECT_FIND_("TRACE_EVENT_END2 call");
  EXPECT_SUB_FIND_("name1");
  EXPECT_SUB_FIND_("value1");
  EXPECT_SUB_FIND_("name2");
  EXPECT_SUB_FIND_("value2");

  EXPECT_FIND_("TRACE_EVENT_ASYNC_BEGIN0 call");
  EXPECT_SUB_FIND_("id");
  EXPECT_SUB_FIND_(kAsyncIdStr);
  EXPECT_FIND_("TRACE_EVENT_ASYNC_BEGIN1 call");
  EXPECT_SUB_FIND_("id");
  EXPECT_SUB_FIND_(kAsyncIdStr);
  EXPECT_SUB_FIND_("name1");
  EXPECT_SUB_FIND_("value1");
  EXPECT_FIND_("TRACE_EVENT_ASYNC_BEGIN2 call");
  EXPECT_SUB_FIND_("id");
  EXPECT_SUB_FIND_(kAsyncIdStr);
  EXPECT_SUB_FIND_("name1");
  EXPECT_SUB_FIND_("value1");
  EXPECT_SUB_FIND_("name2");
  EXPECT_SUB_FIND_("value2");

  EXPECT_FIND_("TRACE_EVENT_ASYNC_STEP_INTO0 call");
  EXPECT_SUB_FIND_("id");
  EXPECT_SUB_FIND_(kAsyncIdStr);
  EXPECT_SUB_FIND_("step_begin1");
  EXPECT_FIND_("TRACE_EVENT_ASYNC_STEP_INTO1 call");
  EXPECT_SUB_FIND_("id");
  EXPECT_SUB_FIND_(kAsyncIdStr);
  EXPECT_SUB_FIND_("step_begin2");
  EXPECT_SUB_FIND_("name1");
  EXPECT_SUB_FIND_("value1");

  EXPECT_FIND_("TRACE_EVENT_ASYNC_END0 call");
  EXPECT_SUB_FIND_("id");
  EXPECT_SUB_FIND_(kAsyncIdStr);
  EXPECT_FIND_("TRACE_EVENT_ASYNC_END1 call");
  EXPECT_SUB_FIND_("id");
  EXPECT_SUB_FIND_(kAsyncIdStr);
  EXPECT_SUB_FIND_("name1");
  EXPECT_SUB_FIND_("value1");
  EXPECT_FIND_("TRACE_EVENT_ASYNC_END2 call");
  EXPECT_SUB_FIND_("id");
  EXPECT_SUB_FIND_(kAsyncIdStr);
  EXPECT_SUB_FIND_("name1");
  EXPECT_SUB_FIND_("value1");
  EXPECT_SUB_FIND_("name2");
  EXPECT_SUB_FIND_("value2");

  EXPECT_FIND_("TRACE_EVENT_BEGIN_ETW0 call");
  EXPECT_SUB_FIND_("id");
  EXPECT_SUB_FIND_(kAsyncIdStr);
  EXPECT_SUB_FIND_("extra");
  EXPECT_SUB_FIND_("NULL");
  EXPECT_FIND_("TRACE_EVENT_BEGIN_ETW1 call");
  EXPECT_SUB_FIND_("id");
  EXPECT_SUB_FIND_(kAsyncIdStr);
  EXPECT_SUB_FIND_("extra");
  EXPECT_SUB_FIND_("value");
  EXPECT_FIND_("TRACE_EVENT_END_ETW0 call");
  EXPECT_SUB_FIND_("id");
  EXPECT_SUB_FIND_(kAsyncIdStr);
  EXPECT_SUB_FIND_("extra");
  EXPECT_SUB_FIND_("NULL");
  EXPECT_FIND_("TRACE_EVENT_END_ETW1 call");
  EXPECT_SUB_FIND_("id");
  EXPECT_SUB_FIND_(kAsyncIdStr);
  EXPECT_SUB_FIND_("extra");
  EXPECT_SUB_FIND_("value");
  EXPECT_FIND_("TRACE_EVENT_INSTANT_ETW0 call");
  EXPECT_SUB_FIND_("id");
  EXPECT_SUB_FIND_(kAsyncIdStr);
  EXPECT_SUB_FIND_("extra");
  EXPECT_SUB_FIND_("NULL");
  EXPECT_FIND_("TRACE_EVENT_INSTANT_ETW1 call");
  EXPECT_SUB_FIND_("id");
  EXPECT_SUB_FIND_(kAsyncIdStr);
  EXPECT_SUB_FIND_("extra");
  EXPECT_SUB_FIND_("value");

  EXPECT_FIND_("TRACE_COUNTER1 call");
  {
    std::string ph;
    EXPECT_TRUE((item && item->GetString("ph", &ph)));
    EXPECT_EQ("C", ph);

    int value;
    EXPECT_TRUE((item && item->GetInteger("args.value", &value)));
    EXPECT_EQ(31415, value);
  }

  EXPECT_FIND_("TRACE_COUNTER2 call");
  {
    std::string ph;
    EXPECT_TRUE((item && item->GetString("ph", &ph)));
    EXPECT_EQ("C", ph);

    int value;
    EXPECT_TRUE((item && item->GetInteger("args.a", &value)));
    EXPECT_EQ(30000, value);

    EXPECT_TRUE((item && item->GetInteger("args.b", &value)));
    EXPECT_EQ(1415, value);
  }

  EXPECT_FIND_("TRACE_COUNTER_ID1 call");
  {
    std::string id;
    EXPECT_TRUE((item && item->GetString("id", &id)));
    EXPECT_EQ("0x319009", id);

    std::string ph;
    EXPECT_TRUE((item && item->GetString("ph", &ph)));
    EXPECT_EQ("C", ph);

    int value;
    EXPECT_TRUE((item && item->GetInteger("args.value", &value)));
    EXPECT_EQ(31415, value);
  }

  EXPECT_FIND_("TRACE_COUNTER_ID2 call");
  {
    std::string id;
    EXPECT_TRUE((item && item->GetString("id", &id)));
    EXPECT_EQ("0x319009", id);

    std::string ph;
    EXPECT_TRUE((item && item->GetString("ph", &ph)));
    EXPECT_EQ("C", ph);

    int value;
    EXPECT_TRUE((item && item->GetInteger("args.a", &value)));
    EXPECT_EQ(30000, value);

    EXPECT_TRUE((item && item->GetInteger("args.b", &value)));
    EXPECT_EQ(1415, value);
  }

  EXPECT_FIND_("TRACE_EVENT_COPY_BEGIN_WITH_ID_TID_AND_TIMESTAMP0 call");
  {
    int val;
    EXPECT_TRUE((item && item->GetInteger("ts", &val)));
    EXPECT_EQ(12345, val);
    EXPECT_TRUE((item && item->GetInteger("tid", &val)));
    EXPECT_EQ(kThreadId, val);
    std::string id;
    EXPECT_TRUE((item && item->GetString("id", &id)));
    EXPECT_EQ(kAsyncIdStr, id);
  }

  EXPECT_FIND_("TRACE_EVENT_COPY_END_WITH_ID_TID_AND_TIMESTAMP0 call");
  {
    int val;
    EXPECT_TRUE((item && item->GetInteger("ts", &val)));
    EXPECT_EQ(23456, val);
    EXPECT_TRUE((item && item->GetInteger("tid", &val)));
    EXPECT_EQ(kThreadId, val);
    std::string id;
    EXPECT_TRUE((item && item->GetString("id", &id)));
    EXPECT_EQ(kAsyncIdStr, id);
  }

  EXPECT_FIND_("TRACE_EVENT_BEGIN_WITH_ID_TID_AND_TIMESTAMP0 call");
  {
    int val;
    EXPECT_TRUE((item && item->GetInteger("ts", &val)));
    EXPECT_EQ(34567, val);
    EXPECT_TRUE((item && item->GetInteger("tid", &val)));
    EXPECT_EQ(kThreadId, val);
    std::string id;
    EXPECT_TRUE((item && item->GetString("id", &id)));
    EXPECT_EQ(kAsyncId2Str, id);
  }

  EXPECT_FIND_("TRACE_EVENT_ASYNC_STEP_PAST0 call");
  {
    EXPECT_SUB_FIND_("id");
    EXPECT_SUB_FIND_(kAsyncId2Str);
    EXPECT_SUB_FIND_("step_end1");
    EXPECT_FIND_("TRACE_EVENT_ASYNC_STEP_PAST1 call");
    EXPECT_SUB_FIND_("id");
    EXPECT_SUB_FIND_(kAsyncId2Str);
    EXPECT_SUB_FIND_("step_end2");
    EXPECT_SUB_FIND_("name1");
    EXPECT_SUB_FIND_("value1");
  }

  EXPECT_FIND_("TRACE_EVENT_END_WITH_ID_TID_AND_TIMESTAMP0 call");
  {
    int val;
    EXPECT_TRUE((item && item->GetInteger("ts", &val)));
    EXPECT_EQ(45678, val);
    EXPECT_TRUE((item && item->GetInteger("tid", &val)));
    EXPECT_EQ(kThreadId, val);
    std::string id;
    EXPECT_TRUE((item && item->GetString("id", &id)));
    EXPECT_EQ(kAsyncId2Str, id);
  }

  EXPECT_FIND_("tracked object 1");
  {
    std::string phase;
    std::string id;
    std::string snapshot;

    EXPECT_TRUE((item && item->GetString("ph", &phase)));
    EXPECT_EQ("N", phase);
    EXPECT_TRUE((item && item->GetString("id", &id)));
    EXPECT_EQ("0x42", id);

    item = FindTraceEntry(trace_parsed, "tracked object 1", item);
    EXPECT_TRUE(item);
    EXPECT_TRUE(item && item->GetString("ph", &phase));
    EXPECT_EQ("O", phase);
    EXPECT_TRUE(item && item->GetString("id", &id));
    EXPECT_EQ("0x42", id);
    EXPECT_TRUE(item && item->GetString("args.snapshot", &snapshot));
    EXPECT_EQ("hello", snapshot);

    item = FindTraceEntry(trace_parsed, "tracked object 1", item);
    EXPECT_TRUE(item);
    EXPECT_TRUE(item && item->GetString("ph", &phase));
    EXPECT_EQ("D", phase);
    EXPECT_TRUE(item && item->GetString("id", &id));
    EXPECT_EQ("0x42", id);
  }

  EXPECT_FIND_("tracked object 2");
  {
    std::string phase;
    std::string id;
    std::string snapshot;

    EXPECT_TRUE(item && item->GetString("ph", &phase));
    EXPECT_EQ("N", phase);
    EXPECT_TRUE(item && item->GetString("id", &id));
    EXPECT_EQ("0x2128506", id);

    item = FindTraceEntry(trace_parsed, "tracked object 2", item);
    EXPECT_TRUE(item);
    EXPECT_TRUE(item && item->GetString("ph", &phase));
    EXPECT_EQ("O", phase);
    EXPECT_TRUE(item && item->GetString("id", &id));
    EXPECT_EQ("0x2128506", id);
    EXPECT_TRUE(item && item->GetString("args.snapshot", &snapshot));
    EXPECT_EQ("world", snapshot);

    item = FindTraceEntry(trace_parsed, "tracked object 2", item);
    EXPECT_TRUE(item);
    EXPECT_TRUE(item && item->GetString("ph", &phase));
    EXPECT_EQ("D", phase);
    EXPECT_TRUE(item && item->GetString("id", &id));
    EXPECT_EQ("0x2128506", id);
  }

  EXPECT_FIND_(kControlCharacters);
  EXPECT_SUB_FIND_(kControlCharacters);
}

void TraceManyInstantEvents(int thread_id, int num_events,
                            WaitableEvent* task_complete_event) {
  for (int i = 0; i < num_events; i++) {
    TRACE_EVENT_INSTANT2("all", "multi thread event",
                         TRACE_EVENT_SCOPE_THREAD,
                         "thread", thread_id,
                         "event", i);
  }

  if (task_complete_event)
    task_complete_event->Signal();
}

void ValidateInstantEventPresentOnEveryThread(const ListValue& trace_parsed,
                                              int num_threads,
                                              int num_events) {
  std::map<int, std::map<int, bool> > results;

  size_t trace_parsed_count = trace_parsed.GetSize();
  for (size_t i = 0; i < trace_parsed_count; i++) {
    const Value* value = NULL;
    trace_parsed.Get(i, &value);
    if (!value || value->GetType() != Value::TYPE_DICTIONARY)
      continue;
    const DictionaryValue* dict = static_cast<const DictionaryValue*>(value);
    std::string name;
    dict->GetString("name", &name);
    if (name != "multi thread event")
      continue;

    int thread = 0;
    int event = 0;
    EXPECT_TRUE(dict->GetInteger("args.thread", &thread));
    EXPECT_TRUE(dict->GetInteger("args.event", &event));
    results[thread][event] = true;
  }

  EXPECT_FALSE(results[-1][-1]);
  for (int thread = 0; thread < num_threads; thread++) {
    for (int event = 0; event < num_events; event++) {
      EXPECT_TRUE(results[thread][event]);
    }
  }
}

}  // namespace

// Simple Test for emitting data and validating it was received.
TEST_F(TraceEventTestFixture, DataCaptured) {
  TraceLog::GetInstance()->SetEnabled(TraceConfig(kRecordAllCategoryFilter, ""),
                                      TraceLog::RECORDING_MODE);

  TraceWithAllMacroVariants(NULL);

  EndTraceAndFlush();

  ValidateAllTraceMacrosCreatedData(trace_parsed_);
}

class MockEnabledStateChangedObserver :
      public TraceLog::EnabledStateObserver {
 public:
  MOCK_METHOD0(OnTraceLogEnabled, void());
  MOCK_METHOD0(OnTraceLogDisabled, void());
};

TEST_F(TraceEventTestFixture, EnabledObserverFiresOnEnable) {
  MockEnabledStateChangedObserver observer;
  TraceLog::GetInstance()->AddEnabledStateObserver(&observer);

  EXPECT_CALL(observer, OnTraceLogEnabled())
      .Times(1);
  TraceLog::GetInstance()->SetEnabled(TraceConfig(kRecordAllCategoryFilter, ""),
                                      TraceLog::RECORDING_MODE);
  testing::Mock::VerifyAndClear(&observer);
  EXPECT_TRUE(TraceLog::GetInstance()->IsEnabled());

  // Cleanup.
  TraceLog::GetInstance()->RemoveEnabledStateObserver(&observer);
  TraceLog::GetInstance()->SetDisabled();
}

TEST_F(TraceEventTestFixture, EnabledObserverDoesntFireOnSecondEnable) {
  TraceLog::GetInstance()->SetEnabled(TraceConfig(kRecordAllCategoryFilter, ""),
                                      TraceLog::RECORDING_MODE);

  testing::StrictMock<MockEnabledStateChangedObserver> observer;
  TraceLog::GetInstance()->AddEnabledStateObserver(&observer);

  EXPECT_CALL(observer, OnTraceLogEnabled())
      .Times(0);
  EXPECT_CALL(observer, OnTraceLogDisabled())
      .Times(0);
  TraceLog::GetInstance()->SetEnabled(TraceConfig(kRecordAllCategoryFilter, ""),
                                      TraceLog::RECORDING_MODE);
  testing::Mock::VerifyAndClear(&observer);
  EXPECT_TRUE(TraceLog::GetInstance()->IsEnabled());

  // Cleanup.
  TraceLog::GetInstance()->RemoveEnabledStateObserver(&observer);
  TraceLog::GetInstance()->SetDisabled();
  TraceLog::GetInstance()->SetDisabled();
}

TEST_F(TraceEventTestFixture, EnabledObserverFiresOnFirstDisable) {
  TraceConfig tc_inc_all("*", "");
  TraceLog::GetInstance()->SetEnabled(tc_inc_all, TraceLog::RECORDING_MODE);
  TraceLog::GetInstance()->SetEnabled(tc_inc_all, TraceLog::RECORDING_MODE);

  testing::StrictMock<MockEnabledStateChangedObserver> observer;
  TraceLog::GetInstance()->AddEnabledStateObserver(&observer);

  EXPECT_CALL(observer, OnTraceLogEnabled())
      .Times(0);
  EXPECT_CALL(observer, OnTraceLogDisabled())
      .Times(1);
  TraceLog::GetInstance()->SetDisabled();
  testing::Mock::VerifyAndClear(&observer);

  // Cleanup.
  TraceLog::GetInstance()->RemoveEnabledStateObserver(&observer);
  TraceLog::GetInstance()->SetDisabled();
}

TEST_F(TraceEventTestFixture, EnabledObserverFiresOnDisable) {
  TraceLog::GetInstance()->SetEnabled(TraceConfig(kRecordAllCategoryFilter, ""),
                                      TraceLog::RECORDING_MODE);

  MockEnabledStateChangedObserver observer;
  TraceLog::GetInstance()->AddEnabledStateObserver(&observer);

  EXPECT_CALL(observer, OnTraceLogDisabled())
      .Times(1);
  TraceLog::GetInstance()->SetDisabled();
  testing::Mock::VerifyAndClear(&observer);

  // Cleanup.
  TraceLog::GetInstance()->RemoveEnabledStateObserver(&observer);
}

// Tests the IsEnabled() state of TraceLog changes before callbacks.
class AfterStateChangeEnabledStateObserver
    : public TraceLog::EnabledStateObserver {
 public:
  AfterStateChangeEnabledStateObserver() {}
  virtual ~AfterStateChangeEnabledStateObserver() {}

  // TraceLog::EnabledStateObserver overrides:
  void OnTraceLogEnabled() override {
    EXPECT_TRUE(TraceLog::GetInstance()->IsEnabled());
  }

  void OnTraceLogDisabled() override {
    EXPECT_FALSE(TraceLog::GetInstance()->IsEnabled());
  }
};

TEST_F(TraceEventTestFixture, ObserversFireAfterStateChange) {
  AfterStateChangeEnabledStateObserver observer;
  TraceLog::GetInstance()->AddEnabledStateObserver(&observer);

  TraceLog::GetInstance()->SetEnabled(TraceConfig(kRecordAllCategoryFilter, ""),
                                      TraceLog::RECORDING_MODE);
  EXPECT_TRUE(TraceLog::GetInstance()->IsEnabled());

  TraceLog::GetInstance()->SetDisabled();
  EXPECT_FALSE(TraceLog::GetInstance()->IsEnabled());

  TraceLog::GetInstance()->RemoveEnabledStateObserver(&observer);
}

// Tests that a state observer can remove itself during a callback.
class SelfRemovingEnabledStateObserver
    : public TraceLog::EnabledStateObserver {
 public:
  SelfRemovingEnabledStateObserver() {}
  virtual ~SelfRemovingEnabledStateObserver() {}

  // TraceLog::EnabledStateObserver overrides:
  void OnTraceLogEnabled() override {}

  void OnTraceLogDisabled() override {
    TraceLog::GetInstance()->RemoveEnabledStateObserver(this);
  }
};

TEST_F(TraceEventTestFixture, SelfRemovingObserver) {
  ASSERT_EQ(0u, TraceLog::GetInstance()->GetObserverCountForTest());

  SelfRemovingEnabledStateObserver observer;
  TraceLog::GetInstance()->AddEnabledStateObserver(&observer);
  EXPECT_EQ(1u, TraceLog::GetInstance()->GetObserverCountForTest());

  TraceLog::GetInstance()->SetEnabled(TraceConfig(kRecordAllCategoryFilter, ""),
                                      TraceLog::RECORDING_MODE);
  TraceLog::GetInstance()->SetDisabled();
  // The observer removed itself on disable.
  EXPECT_EQ(0u, TraceLog::GetInstance()->GetObserverCountForTest());
}

bool IsNewTrace() {
  bool is_new_trace;
  TRACE_EVENT_IS_NEW_TRACE(&is_new_trace);
  return is_new_trace;
}

TEST_F(TraceEventTestFixture, NewTraceRecording) {
  ASSERT_FALSE(IsNewTrace());
  TraceLog::GetInstance()->SetEnabled(TraceConfig(kRecordAllCategoryFilter, ""),
                                      TraceLog::RECORDING_MODE);
  // First call to IsNewTrace() should succeed. But, the second shouldn't.
  ASSERT_TRUE(IsNewTrace());
  ASSERT_FALSE(IsNewTrace());
  EndTraceAndFlush();

  // IsNewTrace() should definitely be false now.
  ASSERT_FALSE(IsNewTrace());

  // Start another trace. IsNewTrace() should become true again, briefly, as
  // before.
  TraceLog::GetInstance()->SetEnabled(TraceConfig(kRecordAllCategoryFilter, ""),
                                      TraceLog::RECORDING_MODE);
  ASSERT_TRUE(IsNewTrace());
  ASSERT_FALSE(IsNewTrace());

  // Cleanup.
  EndTraceAndFlush();
}


// Test that categories work.
TEST_F(TraceEventTestFixture, Categories) {
  // Test that categories that are used can be retrieved whether trace was
  // enabled or disabled when the trace event was encountered.
  TRACE_EVENT_INSTANT0("c1", "name", TRACE_EVENT_SCOPE_THREAD);
  TRACE_EVENT_INSTANT0("c2", "name", TRACE_EVENT_SCOPE_THREAD);
  BeginTrace();
  TRACE_EVENT_INSTANT0("c3", "name", TRACE_EVENT_SCOPE_THREAD);
  TRACE_EVENT_INSTANT0("c4", "name", TRACE_EVENT_SCOPE_THREAD);
  // Category groups containing more than one category.
  TRACE_EVENT_INSTANT0("c5,c6", "name", TRACE_EVENT_SCOPE_THREAD);
  TRACE_EVENT_INSTANT0("c7,c8", "name", TRACE_EVENT_SCOPE_THREAD);
  TRACE_EVENT_INSTANT0(TRACE_DISABLED_BY_DEFAULT("c9"), "name",
                       TRACE_EVENT_SCOPE_THREAD);

  EndTraceAndFlush();
  std::vector<std::string> cat_groups;
  TraceLog::GetInstance()->GetKnownCategoryGroups(&cat_groups);
  EXPECT_TRUE(std::find(cat_groups.begin(),
                        cat_groups.end(), "c1") != cat_groups.end());
  EXPECT_TRUE(std::find(cat_groups.begin(),
                        cat_groups.end(), "c2") != cat_groups.end());
  EXPECT_TRUE(std::find(cat_groups.begin(),
                        cat_groups.end(), "c3") != cat_groups.end());
  EXPECT_TRUE(std::find(cat_groups.begin(),
                        cat_groups.end(), "c4") != cat_groups.end());
  EXPECT_TRUE(std::find(cat_groups.begin(),
                        cat_groups.end(), "c5,c6") != cat_groups.end());
  EXPECT_TRUE(std::find(cat_groups.begin(),
                        cat_groups.end(), "c7,c8") != cat_groups.end());
  EXPECT_TRUE(std::find(cat_groups.begin(),
                        cat_groups.end(),
                        "disabled-by-default-c9") != cat_groups.end());
  // Make sure metadata isn't returned.
  EXPECT_TRUE(std::find(cat_groups.begin(),
                        cat_groups.end(), "__metadata") == cat_groups.end());

  const std::vector<std::string> empty_categories;
  std::vector<std::string> included_categories;
  std::vector<std::string> excluded_categories;

  // Test that category filtering works.

  // Include nonexistent category -> no events
  Clear();
  included_categories.clear();
  TraceLog::GetInstance()->SetEnabled(TraceConfig("not_found823564786", ""),
                                      TraceLog::RECORDING_MODE);
  TRACE_EVENT_INSTANT0("cat1", "name", TRACE_EVENT_SCOPE_THREAD);
  TRACE_EVENT_INSTANT0("cat2", "name", TRACE_EVENT_SCOPE_THREAD);
  EndTraceAndFlush();
  DropTracedMetadataRecords();
  EXPECT_TRUE(trace_parsed_.empty());

  // Include existent category -> only events of that category
  Clear();
  included_categories.clear();
  TraceLog::GetInstance()->SetEnabled(TraceConfig("inc", ""),
                                      TraceLog::RECORDING_MODE);
  TRACE_EVENT_INSTANT0("inc", "name", TRACE_EVENT_SCOPE_THREAD);
  TRACE_EVENT_INSTANT0("inc2", "name", TRACE_EVENT_SCOPE_THREAD);
  EndTraceAndFlush();
  DropTracedMetadataRecords();
  EXPECT_TRUE(FindMatchingValue("cat", "inc"));
  EXPECT_FALSE(FindNonMatchingValue("cat", "inc"));

  // Include existent wildcard -> all categories matching wildcard
  Clear();
  included_categories.clear();
  TraceLog::GetInstance()->SetEnabled(
      TraceConfig("inc_wildcard_*,inc_wildchar_?_end", ""),
      TraceLog::RECORDING_MODE);
  TRACE_EVENT_INSTANT0("inc_wildcard_abc", "included",
      TRACE_EVENT_SCOPE_THREAD);
  TRACE_EVENT_INSTANT0("inc_wildcard_", "included", TRACE_EVENT_SCOPE_THREAD);
  TRACE_EVENT_INSTANT0("inc_wildchar_x_end", "included",
      TRACE_EVENT_SCOPE_THREAD);
  TRACE_EVENT_INSTANT0("inc_wildchar_bla_end", "not_inc",
      TRACE_EVENT_SCOPE_THREAD);
  TRACE_EVENT_INSTANT0("cat1", "not_inc", TRACE_EVENT_SCOPE_THREAD);
  TRACE_EVENT_INSTANT0("cat2", "not_inc", TRACE_EVENT_SCOPE_THREAD);
  TRACE_EVENT_INSTANT0("inc_wildcard_category,other_category", "included",
      TRACE_EVENT_SCOPE_THREAD);
  TRACE_EVENT_INSTANT0(
      "non_included_category,inc_wildcard_category", "included",
      TRACE_EVENT_SCOPE_THREAD);
  EndTraceAndFlush();
  EXPECT_TRUE(FindMatchingValue("cat", "inc_wildcard_abc"));
  EXPECT_TRUE(FindMatchingValue("cat", "inc_wildcard_"));
  EXPECT_TRUE(FindMatchingValue("cat", "inc_wildchar_x_end"));
  EXPECT_FALSE(FindMatchingValue("name", "not_inc"));
  EXPECT_TRUE(FindMatchingValue("cat", "inc_wildcard_category,other_category"));
  EXPECT_TRUE(FindMatchingValue("cat",
                                "non_included_category,inc_wildcard_category"));

  included_categories.clear();

  // Exclude nonexistent category -> all events
  Clear();
  TraceLog::GetInstance()->SetEnabled(TraceConfig("-not_found823564786", ""),
                                      TraceLog::RECORDING_MODE);
  TRACE_EVENT_INSTANT0("cat1", "name", TRACE_EVENT_SCOPE_THREAD);
  TRACE_EVENT_INSTANT0("cat2", "name", TRACE_EVENT_SCOPE_THREAD);
  TRACE_EVENT_INSTANT0("category1,category2", "name", TRACE_EVENT_SCOPE_THREAD);
  EndTraceAndFlush();
  EXPECT_TRUE(FindMatchingValue("cat", "cat1"));
  EXPECT_TRUE(FindMatchingValue("cat", "cat2"));
  EXPECT_TRUE(FindMatchingValue("cat", "category1,category2"));

  // Exclude existent category -> only events of other categories
  Clear();
  TraceLog::GetInstance()->SetEnabled(TraceConfig("-inc", ""),
                                      TraceLog::RECORDING_MODE);
  TRACE_EVENT_INSTANT0("inc", "name", TRACE_EVENT_SCOPE_THREAD);
  TRACE_EVENT_INSTANT0("inc2", "name", TRACE_EVENT_SCOPE_THREAD);
  TRACE_EVENT_INSTANT0("inc2,inc", "name", TRACE_EVENT_SCOPE_THREAD);
  TRACE_EVENT_INSTANT0("inc,inc2", "name", TRACE_EVENT_SCOPE_THREAD);
  EndTraceAndFlush();
  EXPECT_TRUE(FindMatchingValue("cat", "inc2"));
  EXPECT_FALSE(FindMatchingValue("cat", "inc"));
  EXPECT_TRUE(FindMatchingValue("cat", "inc2,inc"));
  EXPECT_TRUE(FindMatchingValue("cat", "inc,inc2"));

  // Exclude existent wildcard -> all categories not matching wildcard
  Clear();
  TraceLog::GetInstance()->SetEnabled(
      TraceConfig("-inc_wildcard_*,-inc_wildchar_?_end", ""),
      TraceLog::RECORDING_MODE);
  TRACE_EVENT_INSTANT0("inc_wildcard_abc", "not_inc",
      TRACE_EVENT_SCOPE_THREAD);
  TRACE_EVENT_INSTANT0("inc_wildcard_", "not_inc",
      TRACE_EVENT_SCOPE_THREAD);
  TRACE_EVENT_INSTANT0("inc_wildchar_x_end", "not_inc",
      TRACE_EVENT_SCOPE_THREAD);
  TRACE_EVENT_INSTANT0("inc_wildchar_bla_end", "included",
      TRACE_EVENT_SCOPE_THREAD);
  TRACE_EVENT_INSTANT0("cat1", "included", TRACE_EVENT_SCOPE_THREAD);
  TRACE_EVENT_INSTANT0("cat2", "included", TRACE_EVENT_SCOPE_THREAD);
  EndTraceAndFlush();
  EXPECT_TRUE(FindMatchingValue("cat", "inc_wildchar_bla_end"));
  EXPECT_TRUE(FindMatchingValue("cat", "cat1"));
  EXPECT_TRUE(FindMatchingValue("cat", "cat2"));
  EXPECT_FALSE(FindMatchingValue("name", "not_inc"));
}


// Test EVENT_WATCH_NOTIFICATION
TEST_F(TraceEventTestFixture, EventWatchNotification) {
  // Basic one occurrence.
  BeginTrace();
  TraceLog::WatchEventCallback callback =
      base::Bind(&TraceEventTestFixture::OnWatchEventMatched,
                 base::Unretained(this));
  TraceLog::GetInstance()->SetWatchEvent("cat", "event", callback);
  TRACE_EVENT_INSTANT0("cat", "event", TRACE_EVENT_SCOPE_THREAD);
  EndTraceAndFlush();
  EXPECT_EQ(event_watch_notification_, 1);

  // Auto-reset after end trace.
  BeginTrace();
  TraceLog::GetInstance()->SetWatchEvent("cat", "event", callback);
  EndTraceAndFlush();
  BeginTrace();
  TRACE_EVENT_INSTANT0("cat", "event", TRACE_EVENT_SCOPE_THREAD);
  EndTraceAndFlush();
  EXPECT_EQ(event_watch_notification_, 0);

  // Multiple occurrence.
  BeginTrace();
  int num_occurrences = 5;
  TraceLog::GetInstance()->SetWatchEvent("cat", "event", callback);
  for (int i = 0; i < num_occurrences; ++i)
    TRACE_EVENT_INSTANT0("cat", "event", TRACE_EVENT_SCOPE_THREAD);
  EndTraceAndFlush();
  EXPECT_EQ(event_watch_notification_, num_occurrences);

  // Wrong category.
  BeginTrace();
  TraceLog::GetInstance()->SetWatchEvent("cat", "event", callback);
  TRACE_EVENT_INSTANT0("wrong_cat", "event", TRACE_EVENT_SCOPE_THREAD);
  EndTraceAndFlush();
  EXPECT_EQ(event_watch_notification_, 0);

  // Wrong name.
  BeginTrace();
  TraceLog::GetInstance()->SetWatchEvent("cat", "event", callback);
  TRACE_EVENT_INSTANT0("cat", "wrong_event", TRACE_EVENT_SCOPE_THREAD);
  EndTraceAndFlush();
  EXPECT_EQ(event_watch_notification_, 0);

  // Canceled.
  BeginTrace();
  TraceLog::GetInstance()->SetWatchEvent("cat", "event", callback);
  TraceLog::GetInstance()->CancelWatchEvent();
  TRACE_EVENT_INSTANT0("cat", "event", TRACE_EVENT_SCOPE_THREAD);
  EndTraceAndFlush();
  EXPECT_EQ(event_watch_notification_, 0);
}

// Test ASYNC_BEGIN/END events
TEST_F(TraceEventTestFixture, AsyncBeginEndEvents) {
  BeginTrace();

  unsigned long long id = 0xfeedbeeffeedbeefull;
  TRACE_EVENT_ASYNC_BEGIN0("cat", "name1", id);
  TRACE_EVENT_ASYNC_STEP_INTO0("cat", "name1", id, "step1");
  TRACE_EVENT_ASYNC_END0("cat", "name1", id);
  TRACE_EVENT_BEGIN0("cat", "name2");
  TRACE_EVENT_ASYNC_BEGIN0("cat", "name3", 0);
  TRACE_EVENT_ASYNC_STEP_PAST0("cat", "name3", 0, "step2");

  EndTraceAndFlush();

  EXPECT_TRUE(FindNamePhase("name1", "S"));
  EXPECT_TRUE(FindNamePhase("name1", "T"));
  EXPECT_TRUE(FindNamePhase("name1", "F"));

  std::string id_str;
  StringAppendF(&id_str, "0x%llx", id);

  EXPECT_TRUE(FindNamePhaseKeyValue("name1", "S", "id", id_str.c_str()));
  EXPECT_TRUE(FindNamePhaseKeyValue("name1", "T", "id", id_str.c_str()));
  EXPECT_TRUE(FindNamePhaseKeyValue("name1", "F", "id", id_str.c_str()));
  EXPECT_TRUE(FindNamePhaseKeyValue("name3", "S", "id", "0x0"));
  EXPECT_TRUE(FindNamePhaseKeyValue("name3", "p", "id", "0x0"));

  // BEGIN events should not have id
  EXPECT_FALSE(FindNamePhaseKeyValue("name2", "B", "id", "0"));
}

// Test ASYNC_BEGIN/END events
TEST_F(TraceEventTestFixture, AsyncBeginEndPointerMangling) {
  void* ptr = this;

  TraceLog::GetInstance()->SetProcessID(100);
  BeginTrace();
  TRACE_EVENT_ASYNC_BEGIN0("cat", "name1", ptr);
  TRACE_EVENT_ASYNC_BEGIN0("cat", "name2", ptr);
  EndTraceAndFlush();

  TraceLog::GetInstance()->SetProcessID(200);
  BeginTrace();
  TRACE_EVENT_ASYNC_END0("cat", "name1", ptr);
  EndTraceAndFlush();

  DictionaryValue* async_begin = FindNamePhase("name1", "S");
  DictionaryValue* async_begin2 = FindNamePhase("name2", "S");
  DictionaryValue* async_end = FindNamePhase("name1", "F");
  EXPECT_TRUE(async_begin);
  EXPECT_TRUE(async_begin2);
  EXPECT_TRUE(async_end);

  Value* value = NULL;
  std::string async_begin_id_str;
  std::string async_begin2_id_str;
  std::string async_end_id_str;
  ASSERT_TRUE(async_begin->Get("id", &value));
  ASSERT_TRUE(value->GetAsString(&async_begin_id_str));
  ASSERT_TRUE(async_begin2->Get("id", &value));
  ASSERT_TRUE(value->GetAsString(&async_begin2_id_str));
  ASSERT_TRUE(async_end->Get("id", &value));
  ASSERT_TRUE(value->GetAsString(&async_end_id_str));

  EXPECT_STREQ(async_begin_id_str.c_str(), async_begin2_id_str.c_str());
  EXPECT_STRNE(async_begin_id_str.c_str(), async_end_id_str.c_str());
}

// Test that static strings are not copied.
TEST_F(TraceEventTestFixture, StaticStringVsString) {
  TraceLog* tracer = TraceLog::GetInstance();
  // Make sure old events are flushed:
  EXPECT_EQ(0u, tracer->GetStatus().event_count);
  const unsigned char* category_group_enabled =
      TRACE_EVENT_API_GET_CATEGORY_GROUP_ENABLED("cat");

  {
    BeginTrace();
    // Test that string arguments are copied.
    TraceEventHandle handle1 =
        trace_event_internal::AddTraceEvent(
            TRACE_EVENT_PHASE_INSTANT, category_group_enabled, "name1", 0, 0,
            "arg1", std::string("argval"), "arg2", std::string("argval"));
    // Test that static TRACE_STR_COPY string arguments are copied.
    TraceEventHandle handle2 =
        trace_event_internal::AddTraceEvent(
            TRACE_EVENT_PHASE_INSTANT, category_group_enabled, "name2", 0, 0,
            "arg1", TRACE_STR_COPY("argval"),
            "arg2", TRACE_STR_COPY("argval"));
    EXPECT_GT(tracer->GetStatus().event_count, 1u);
    const TraceEvent* event1 = tracer->GetEventByHandle(handle1);
    const TraceEvent* event2 = tracer->GetEventByHandle(handle2);
    ASSERT_TRUE(event1);
    ASSERT_TRUE(event2);
    EXPECT_STREQ("name1", event1->name());
    EXPECT_STREQ("name2", event2->name());
    EXPECT_TRUE(event1->parameter_copy_storage() != NULL);
    EXPECT_TRUE(event2->parameter_copy_storage() != NULL);
    EXPECT_GT(event1->parameter_copy_storage()->size(), 0u);
    EXPECT_GT(event2->parameter_copy_storage()->size(), 0u);
    EndTraceAndFlush();
  }

  {
    BeginTrace();
    // Test that static literal string arguments are not copied.
    TraceEventHandle handle1 =
        trace_event_internal::AddTraceEvent(
            TRACE_EVENT_PHASE_INSTANT, category_group_enabled, "name1", 0, 0,
            "arg1", "argval", "arg2", "argval");
    // Test that static TRACE_STR_COPY NULL string arguments are not copied.
    const char* str1 = NULL;
    const char* str2 = NULL;
    TraceEventHandle handle2 =
        trace_event_internal::AddTraceEvent(
            TRACE_EVENT_PHASE_INSTANT, category_group_enabled, "name2", 0, 0,
            "arg1", TRACE_STR_COPY(str1),
            "arg2", TRACE_STR_COPY(str2));
    EXPECT_GT(tracer->GetStatus().event_count, 1u);
    const TraceEvent* event1 = tracer->GetEventByHandle(handle1);
    const TraceEvent* event2 = tracer->GetEventByHandle(handle2);
    ASSERT_TRUE(event1);
    ASSERT_TRUE(event2);
    EXPECT_STREQ("name1", event1->name());
    EXPECT_STREQ("name2", event2->name());
    EXPECT_TRUE(event1->parameter_copy_storage() == NULL);
    EXPECT_TRUE(event2->parameter_copy_storage() == NULL);
    EndTraceAndFlush();
  }
}

// Test that data sent from other threads is gathered
TEST_F(TraceEventTestFixture, DataCapturedOnThread) {
  BeginTrace();

  Thread thread("1");
  WaitableEvent task_complete_event(false, false);
  thread.Start();

  thread.task_runner()->PostTask(
      FROM_HERE, base::Bind(&TraceWithAllMacroVariants, &task_complete_event));
  task_complete_event.Wait();
  thread.Stop();

  EndTraceAndFlush();
  ValidateAllTraceMacrosCreatedData(trace_parsed_);
}

// Test that data sent from multiple threads is gathered
TEST_F(TraceEventTestFixture, DataCapturedManyThreads) {
  BeginTrace();

  const int num_threads = 4;
  const int num_events = 4000;
  Thread* threads[num_threads];
  WaitableEvent* task_complete_events[num_threads];
  for (int i = 0; i < num_threads; i++) {
    threads[i] = new Thread(StringPrintf("Thread %d", i));
    task_complete_events[i] = new WaitableEvent(false, false);
    threads[i]->Start();
    threads[i]->task_runner()->PostTask(
        FROM_HERE, base::Bind(&TraceManyInstantEvents, i, num_events,
                              task_complete_events[i]));
  }

  for (int i = 0; i < num_threads; i++) {
    task_complete_events[i]->Wait();
  }

  // Let half of the threads end before flush.
  for (int i = 0; i < num_threads / 2; i++) {
    threads[i]->Stop();
    delete threads[i];
    delete task_complete_events[i];
  }

  EndTraceAndFlushInThreadWithMessageLoop();
  ValidateInstantEventPresentOnEveryThread(trace_parsed_,
                                           num_threads, num_events);

  // Let the other half of the threads end after flush.
  for (int i = num_threads / 2; i < num_threads; i++) {
    threads[i]->Stop();
    delete threads[i];
    delete task_complete_events[i];
  }
}

// Test that thread and process names show up in the trace
TEST_F(TraceEventTestFixture, ThreadNames) {
  // Create threads before we enable tracing to make sure
  // that tracelog still captures them.
  const int kNumThreads = 4;
  const int kNumEvents = 10;
  Thread* threads[kNumThreads];
  PlatformThreadId thread_ids[kNumThreads];
  for (int i = 0; i < kNumThreads; i++)
    threads[i] = new Thread(StringPrintf("Thread %d", i));

  // Enable tracing.
  BeginTrace();

  // Now run some trace code on these threads.
  WaitableEvent* task_complete_events[kNumThreads];
  for (int i = 0; i < kNumThreads; i++) {
    task_complete_events[i] = new WaitableEvent(false, false);
    threads[i]->Start();
    thread_ids[i] = threads[i]->thread_id();
    threads[i]->task_runner()->PostTask(
        FROM_HERE, base::Bind(&TraceManyInstantEvents, i, kNumEvents,
                              task_complete_events[i]));
  }
  for (int i = 0; i < kNumThreads; i++) {
    task_complete_events[i]->Wait();
  }

  // Shut things down.
  for (int i = 0; i < kNumThreads; i++) {
    threads[i]->Stop();
    delete threads[i];
    delete task_complete_events[i];
  }

  EndTraceAndFlush();

  std::string tmp;
  int tmp_int;
  const DictionaryValue* item;

  // Make sure we get thread name metadata.
  // Note, the test suite may have created a ton of threads.
  // So, we'll have thread names for threads we didn't create.
  std::vector<const DictionaryValue*> items =
      FindTraceEntries(trace_parsed_, "thread_name");
  for (int i = 0; i < static_cast<int>(items.size()); i++) {
    item = items[i];
    ASSERT_TRUE(item);
    EXPECT_TRUE(item->GetInteger("tid", &tmp_int));

    // See if this thread name is one of the threads we just created
    for (int j = 0; j < kNumThreads; j++) {
      if (static_cast<int>(thread_ids[j]) != tmp_int)
        continue;

      std::string expected_name = StringPrintf("Thread %d", j);
      EXPECT_TRUE(item->GetString("ph", &tmp) && tmp == "M");
      EXPECT_TRUE(item->GetInteger("pid", &tmp_int) &&
                  tmp_int == static_cast<int>(base::GetCurrentProcId()));
      // If the thread name changes or the tid gets reused, the name will be
      // a comma-separated list of thread names, so look for a substring.
      EXPECT_TRUE(item->GetString("args.name", &tmp) &&
                  tmp.find(expected_name) != std::string::npos);
    }
  }
}

TEST_F(TraceEventTestFixture, ThreadNameChanges) {
  BeginTrace();

  PlatformThread::SetName("");
  TRACE_EVENT_INSTANT0("drink", "water", TRACE_EVENT_SCOPE_THREAD);

  PlatformThread::SetName("cafe");
  TRACE_EVENT_INSTANT0("drink", "coffee", TRACE_EVENT_SCOPE_THREAD);

  PlatformThread::SetName("shop");
  // No event here, so won't appear in combined name.

  PlatformThread::SetName("pub");
  TRACE_EVENT_INSTANT0("drink", "beer", TRACE_EVENT_SCOPE_THREAD);
  TRACE_EVENT_INSTANT0("drink", "wine", TRACE_EVENT_SCOPE_THREAD);

  PlatformThread::SetName(" bar");
  TRACE_EVENT_INSTANT0("drink", "whisky", TRACE_EVENT_SCOPE_THREAD);

  EndTraceAndFlush();

  std::vector<const DictionaryValue*> items =
      FindTraceEntries(trace_parsed_, "thread_name");
  EXPECT_EQ(1u, items.size());
  ASSERT_GT(items.size(), 0u);
  const DictionaryValue* item = items[0];
  ASSERT_TRUE(item);
  int tid;
  EXPECT_TRUE(item->GetInteger("tid", &tid));
  EXPECT_EQ(PlatformThread::CurrentId(), static_cast<PlatformThreadId>(tid));

  std::string expected_name = "cafe,pub, bar";
  std::string tmp;
  EXPECT_TRUE(item->GetString("args.name", &tmp));
  EXPECT_EQ(expected_name, tmp);
}

// Test that the disabled trace categories are included/excluded from the
// trace output correctly.
TEST_F(TraceEventTestFixture, DisabledCategories) {
  BeginTrace();
  TRACE_EVENT_INSTANT0(TRACE_DISABLED_BY_DEFAULT("cc"), "first",
                       TRACE_EVENT_SCOPE_THREAD);
  TRACE_EVENT_INSTANT0("included", "first", TRACE_EVENT_SCOPE_THREAD);
  EndTraceAndFlush();
  {
    const DictionaryValue* item = NULL;
    ListValue& trace_parsed = trace_parsed_;
    EXPECT_NOT_FIND_("disabled-by-default-cc");
    EXPECT_FIND_("included");
  }
  Clear();

  BeginSpecificTrace("disabled-by-default-cc");
  TRACE_EVENT_INSTANT0(TRACE_DISABLED_BY_DEFAULT("cc"), "second",
                       TRACE_EVENT_SCOPE_THREAD);
  TRACE_EVENT_INSTANT0("other_included", "second", TRACE_EVENT_SCOPE_THREAD);
  EndTraceAndFlush();

  {
    const DictionaryValue* item = NULL;
    ListValue& trace_parsed = trace_parsed_;
    EXPECT_FIND_("disabled-by-default-cc");
    EXPECT_FIND_("other_included");
  }

  Clear();

  BeginSpecificTrace("other_included");
  TRACE_EVENT_INSTANT0(TRACE_DISABLED_BY_DEFAULT("cc") ",other_included",
                       "first", TRACE_EVENT_SCOPE_THREAD);
  TRACE_EVENT_INSTANT0("other_included," TRACE_DISABLED_BY_DEFAULT("cc"),
                       "second", TRACE_EVENT_SCOPE_THREAD);
  EndTraceAndFlush();

  {
    const DictionaryValue* item = NULL;
    ListValue& trace_parsed = trace_parsed_;
    EXPECT_FIND_("disabled-by-default-cc,other_included");
    EXPECT_FIND_("other_included,disabled-by-default-cc");
  }
}

TEST_F(TraceEventTestFixture, NormallyNoDeepCopy) {
  // Test that the TRACE_EVENT macros do not deep-copy their string. If they
  // do so it may indicate a performance regression, but more-over it would
  // make the DEEP_COPY overloads redundant.
  std::string name_string("event name");

  BeginTrace();
  TRACE_EVENT_INSTANT0("category", name_string.c_str(),
                       TRACE_EVENT_SCOPE_THREAD);

  // Modify the string in place (a wholesale reassignment may leave the old
  // string intact on the heap).
  name_string[0] = '@';

  EndTraceAndFlush();

  EXPECT_FALSE(FindTraceEntry(trace_parsed_, "event name"));
  EXPECT_TRUE(FindTraceEntry(trace_parsed_, name_string.c_str()));
}

TEST_F(TraceEventTestFixture, DeepCopy) {
  static const char kOriginalName1[] = "name1";
  static const char kOriginalName2[] = "name2";
  static const char kOriginalName3[] = "name3";
  std::string name1(kOriginalName1);
  std::string name2(kOriginalName2);
  std::string name3(kOriginalName3);
  std::string arg1("arg1");
  std::string arg2("arg2");
  std::string val1("val1");
  std::string val2("val2");

  BeginTrace();
  TRACE_EVENT_COPY_INSTANT0("category", name1.c_str(),
                            TRACE_EVENT_SCOPE_THREAD);
  TRACE_EVENT_COPY_BEGIN1("category", name2.c_str(),
                          arg1.c_str(), 5);
  TRACE_EVENT_COPY_END2("category", name3.c_str(),
                        arg1.c_str(), val1,
                        arg2.c_str(), val2);

  // As per NormallyNoDeepCopy, modify the strings in place.
  name1[0] = name2[0] = name3[0] = arg1[0] = arg2[0] = val1[0] = val2[0] = '@';

  EndTraceAndFlush();

  EXPECT_FALSE(FindTraceEntry(trace_parsed_, name1.c_str()));
  EXPECT_FALSE(FindTraceEntry(trace_parsed_, name2.c_str()));
  EXPECT_FALSE(FindTraceEntry(trace_parsed_, name3.c_str()));

  const DictionaryValue* entry1 = FindTraceEntry(trace_parsed_, kOriginalName1);
  const DictionaryValue* entry2 = FindTraceEntry(trace_parsed_, kOriginalName2);
  const DictionaryValue* entry3 = FindTraceEntry(trace_parsed_, kOriginalName3);
  ASSERT_TRUE(entry1);
  ASSERT_TRUE(entry2);
  ASSERT_TRUE(entry3);

  int i;
  EXPECT_FALSE(entry2->GetInteger("args.@rg1", &i));
  EXPECT_TRUE(entry2->GetInteger("args.arg1", &i));
  EXPECT_EQ(5, i);

  std::string s;
  EXPECT_TRUE(entry3->GetString("args.arg1", &s));
  EXPECT_EQ("val1", s);
  EXPECT_TRUE(entry3->GetString("args.arg2", &s));
  EXPECT_EQ("val2", s);
}

// Test that TraceResultBuffer outputs the correct result whether it is added
// in chunks or added all at once.
TEST_F(TraceEventTestFixture, TraceResultBuffer) {
  Clear();

  trace_buffer_.Start();
  trace_buffer_.AddFragment("bla1");
  trace_buffer_.AddFragment("bla2");
  trace_buffer_.AddFragment("bla3,bla4");
  trace_buffer_.Finish();
  EXPECT_STREQ(json_output_.json_output.c_str(), "[bla1,bla2,bla3,bla4]");

  Clear();

  trace_buffer_.Start();
  trace_buffer_.AddFragment("bla1,bla2,bla3,bla4");
  trace_buffer_.Finish();
  EXPECT_STREQ(json_output_.json_output.c_str(), "[bla1,bla2,bla3,bla4]");
}

// Test that trace_event parameters are not evaluated if the tracing
// system is disabled.
TEST_F(TraceEventTestFixture, TracingIsLazy) {
  BeginTrace();

  int a = 0;
  TRACE_EVENT_INSTANT1("category", "test", TRACE_EVENT_SCOPE_THREAD, "a", a++);
  EXPECT_EQ(1, a);

  TraceLog::GetInstance()->SetDisabled();

  TRACE_EVENT_INSTANT1("category", "test", TRACE_EVENT_SCOPE_THREAD, "a", a++);
  EXPECT_EQ(1, a);

  EndTraceAndFlush();
}

TEST_F(TraceEventTestFixture, TraceEnableDisable) {
  TraceLog* trace_log = TraceLog::GetInstance();
  TraceConfig tc_inc_all("*", "");
  trace_log->SetEnabled(tc_inc_all, TraceLog::RECORDING_MODE);
  EXPECT_TRUE(trace_log->IsEnabled());
  trace_log->SetDisabled();
  EXPECT_FALSE(trace_log->IsEnabled());

  trace_log->SetEnabled(tc_inc_all, TraceLog::RECORDING_MODE);
  EXPECT_TRUE(trace_log->IsEnabled());
  const std::vector<std::string> empty;
  trace_log->SetEnabled(TraceConfig(), TraceLog::RECORDING_MODE);
  EXPECT_TRUE(trace_log->IsEnabled());
  trace_log->SetDisabled();
  EXPECT_FALSE(trace_log->IsEnabled());
  trace_log->SetDisabled();
  EXPECT_FALSE(trace_log->IsEnabled());
}

TEST_F(TraceEventTestFixture, TraceCategoriesAfterNestedEnable) {
  TraceLog* trace_log = TraceLog::GetInstance();
  trace_log->SetEnabled(TraceConfig("foo,bar", ""), TraceLog::RECORDING_MODE);
  EXPECT_TRUE(*trace_log->GetCategoryGroupEnabled("foo"));
  EXPECT_TRUE(*trace_log->GetCategoryGroupEnabled("bar"));
  EXPECT_FALSE(*trace_log->GetCategoryGroupEnabled("baz"));
  trace_log->SetEnabled(TraceConfig("foo2", ""), TraceLog::RECORDING_MODE);
  EXPECT_TRUE(*trace_log->GetCategoryGroupEnabled("foo2"));
  EXPECT_FALSE(*trace_log->GetCategoryGroupEnabled("baz"));
  // The "" becomes the default catergory set when applied.
  trace_log->SetEnabled(TraceConfig(), TraceLog::RECORDING_MODE);
  EXPECT_TRUE(*trace_log->GetCategoryGroupEnabled("foo"));
  EXPECT_TRUE(*trace_log->GetCategoryGroupEnabled("baz"));
  EXPECT_STREQ(
    "-*Debug,-*Test",
    trace_log->GetCurrentTraceConfig().ToCategoryFilterString().c_str());
  trace_log->SetDisabled();
  trace_log->SetDisabled();
  trace_log->SetDisabled();
  EXPECT_FALSE(*trace_log->GetCategoryGroupEnabled("foo"));
  EXPECT_FALSE(*trace_log->GetCategoryGroupEnabled("baz"));

  trace_log->SetEnabled(TraceConfig("-foo,-bar", ""), TraceLog::RECORDING_MODE);
  EXPECT_FALSE(*trace_log->GetCategoryGroupEnabled("foo"));
  EXPECT_TRUE(*trace_log->GetCategoryGroupEnabled("baz"));
  trace_log->SetEnabled(TraceConfig("moo", ""), TraceLog::RECORDING_MODE);
  EXPECT_TRUE(*trace_log->GetCategoryGroupEnabled("baz"));
  EXPECT_TRUE(*trace_log->GetCategoryGroupEnabled("moo"));
  EXPECT_FALSE(*trace_log->GetCategoryGroupEnabled("foo"));
  EXPECT_STREQ(
    "-foo,-bar",
    trace_log->GetCurrentTraceConfig().ToCategoryFilterString().c_str());
  trace_log->SetDisabled();
  trace_log->SetDisabled();

  // Make sure disabled categories aren't cleared if we set in the second.
  trace_log->SetEnabled(TraceConfig("disabled-by-default-cc,foo", ""),
                        TraceLog::RECORDING_MODE);
  EXPECT_FALSE(*trace_log->GetCategoryGroupEnabled("bar"));
  trace_log->SetEnabled(TraceConfig("disabled-by-default-gpu", ""),
                        TraceLog::RECORDING_MODE);
  EXPECT_TRUE(*trace_log->GetCategoryGroupEnabled("disabled-by-default-cc"));
  EXPECT_TRUE(*trace_log->GetCategoryGroupEnabled("disabled-by-default-gpu"));
  EXPECT_TRUE(*trace_log->GetCategoryGroupEnabled("bar"));
  EXPECT_STREQ(
    "disabled-by-default-cc,disabled-by-default-gpu",
    trace_log->GetCurrentTraceConfig().ToCategoryFilterString().c_str());
  trace_log->SetDisabled();
  trace_log->SetDisabled();
}

TEST_F(TraceEventTestFixture, TraceSampling) {
  TraceLog::GetInstance()->SetEnabled(
    TraceConfig(kRecordAllCategoryFilter, "record-until-full,enable-sampling"),
    TraceLog::RECORDING_MODE);

  TRACE_EVENT_SET_SAMPLING_STATE_FOR_BUCKET(1, "cc", "Stuff");
  TraceLog::GetInstance()->WaitSamplingEventForTesting();
  TRACE_EVENT_SET_SAMPLING_STATE_FOR_BUCKET(1, "cc", "Things");
  TraceLog::GetInstance()->WaitSamplingEventForTesting();

  EndTraceAndFlush();

  // Make sure we hit at least once.
  EXPECT_TRUE(FindNamePhase("Stuff", "P"));
  EXPECT_TRUE(FindNamePhase("Things", "P"));
}

TEST_F(TraceEventTestFixture, TraceSamplingScope) {
  TraceLog::GetInstance()->SetEnabled(
    TraceConfig(kRecordAllCategoryFilter, "record-until-full,enable-sampling"),
    TraceLog::RECORDING_MODE);

  TRACE_EVENT_SCOPED_SAMPLING_STATE("AAA", "name");
  TraceLog::GetInstance()->WaitSamplingEventForTesting();
  {
    EXPECT_STREQ(TRACE_EVENT_GET_SAMPLING_STATE(), "AAA");
    TRACE_EVENT_SCOPED_SAMPLING_STATE("BBB", "name");
    TraceLog::GetInstance()->WaitSamplingEventForTesting();
    EXPECT_STREQ(TRACE_EVENT_GET_SAMPLING_STATE(), "BBB");
  }
  TraceLog::GetInstance()->WaitSamplingEventForTesting();
  {
    EXPECT_STREQ(TRACE_EVENT_GET_SAMPLING_STATE(), "AAA");
    TRACE_EVENT_SCOPED_SAMPLING_STATE("CCC", "name");
    TraceLog::GetInstance()->WaitSamplingEventForTesting();
    EXPECT_STREQ(TRACE_EVENT_GET_SAMPLING_STATE(), "CCC");
  }
  TraceLog::GetInstance()->WaitSamplingEventForTesting();
  {
    EXPECT_STREQ(TRACE_EVENT_GET_SAMPLING_STATE(), "AAA");
    TRACE_EVENT_SET_SAMPLING_STATE("DDD", "name");
    TraceLog::GetInstance()->WaitSamplingEventForTesting();
    EXPECT_STREQ(TRACE_EVENT_GET_SAMPLING_STATE(), "DDD");
  }
  TraceLog::GetInstance()->WaitSamplingEventForTesting();
  EXPECT_STREQ(TRACE_EVENT_GET_SAMPLING_STATE(), "DDD");

  EndTraceAndFlush();
}

TEST_F(TraceEventTestFixture, TraceContinuousSampling) {
  TraceLog::GetInstance()->SetEnabled(
    TraceConfig(kRecordAllCategoryFilter, "record-until-full,enable-sampling"),
    TraceLog::MONITORING_MODE);

  TRACE_EVENT_SET_SAMPLING_STATE_FOR_BUCKET(1, "category", "AAA");
  TraceLog::GetInstance()->WaitSamplingEventForTesting();
  TRACE_EVENT_SET_SAMPLING_STATE_FOR_BUCKET(1, "category", "BBB");
  TraceLog::GetInstance()->WaitSamplingEventForTesting();

  FlushMonitoring();

  // Make sure we can get the profiled data.
  EXPECT_TRUE(FindNamePhase("AAA", "P"));
  EXPECT_TRUE(FindNamePhase("BBB", "P"));

  Clear();
  TraceLog::GetInstance()->WaitSamplingEventForTesting();

  TRACE_EVENT_SET_SAMPLING_STATE_FOR_BUCKET(1, "category", "CCC");
  TraceLog::GetInstance()->WaitSamplingEventForTesting();
  TRACE_EVENT_SET_SAMPLING_STATE_FOR_BUCKET(1, "category", "DDD");
  TraceLog::GetInstance()->WaitSamplingEventForTesting();

  FlushMonitoring();

  // Make sure the profiled data is accumulated.
  EXPECT_TRUE(FindNamePhase("AAA", "P"));
  EXPECT_TRUE(FindNamePhase("BBB", "P"));
  EXPECT_TRUE(FindNamePhase("CCC", "P"));
  EXPECT_TRUE(FindNamePhase("DDD", "P"));

  Clear();

  TraceLog::GetInstance()->SetDisabled();

  // Make sure disabling the continuous sampling thread clears
  // the profiled data.
  EXPECT_FALSE(FindNamePhase("AAA", "P"));
  EXPECT_FALSE(FindNamePhase("BBB", "P"));
  EXPECT_FALSE(FindNamePhase("CCC", "P"));
  EXPECT_FALSE(FindNamePhase("DDD", "P"));

  Clear();
}

class MyData : public ConvertableToTraceFormat {
 public:
  MyData() {}

  void AppendAsTraceFormat(std::string* out) const override {
    out->append("{\"foo\":1}");
  }

 private:
  ~MyData() override {}
  DISALLOW_COPY_AND_ASSIGN(MyData);
};

TEST_F(TraceEventTestFixture, ConvertableTypes) {
  TraceLog::GetInstance()->SetEnabled(TraceConfig(kRecordAllCategoryFilter, ""),
                                      TraceLog::RECORDING_MODE);

  scoped_refptr<ConvertableToTraceFormat> data(new MyData());
  scoped_refptr<ConvertableToTraceFormat> data1(new MyData());
  scoped_refptr<ConvertableToTraceFormat> data2(new MyData());
  TRACE_EVENT1("foo", "bar", "data", data);
  TRACE_EVENT2("foo", "baz",
               "data1", data1,
               "data2", data2);


  scoped_refptr<ConvertableToTraceFormat> convertData1(new MyData());
  scoped_refptr<ConvertableToTraceFormat> convertData2(new MyData());
  TRACE_EVENT2(
      "foo",
      "string_first",
      "str",
      "string value 1",
      "convert",
      convertData1);
  TRACE_EVENT2(
      "foo",
      "string_second",
      "convert",
      convertData2,
      "str",
      "string value 2");
  EndTraceAndFlush();

  // One arg version.
  DictionaryValue* dict = FindNamePhase("bar", "X");
  ASSERT_TRUE(dict);

  const DictionaryValue* args_dict = NULL;
  dict->GetDictionary("args", &args_dict);
  ASSERT_TRUE(args_dict);

  const Value* value = NULL;
  const DictionaryValue* convertable_dict = NULL;
  EXPECT_TRUE(args_dict->Get("data", &value));
  ASSERT_TRUE(value->GetAsDictionary(&convertable_dict));

  int foo_val;
  EXPECT_TRUE(convertable_dict->GetInteger("foo", &foo_val));
  EXPECT_EQ(1, foo_val);

  // Two arg version.
  dict = FindNamePhase("baz", "X");
  ASSERT_TRUE(dict);

  args_dict = NULL;
  dict->GetDictionary("args", &args_dict);
  ASSERT_TRUE(args_dict);

  value = NULL;
  convertable_dict = NULL;
  EXPECT_TRUE(args_dict->Get("data1", &value));
  ASSERT_TRUE(value->GetAsDictionary(&convertable_dict));

  value = NULL;
  convertable_dict = NULL;
  EXPECT_TRUE(args_dict->Get("data2", &value));
  ASSERT_TRUE(value->GetAsDictionary(&convertable_dict));

  // Convertable with other types.
  dict = FindNamePhase("string_first", "X");
  ASSERT_TRUE(dict);

  args_dict = NULL;
  dict->GetDictionary("args", &args_dict);
  ASSERT_TRUE(args_dict);

  std::string str_value;
  EXPECT_TRUE(args_dict->GetString("str", &str_value));
  EXPECT_STREQ("string value 1", str_value.c_str());

  value = NULL;
  convertable_dict = NULL;
  foo_val = 0;
  EXPECT_TRUE(args_dict->Get("convert", &value));
  ASSERT_TRUE(value->GetAsDictionary(&convertable_dict));
  EXPECT_TRUE(convertable_dict->GetInteger("foo", &foo_val));
  EXPECT_EQ(1, foo_val);

  dict = FindNamePhase("string_second", "X");
  ASSERT_TRUE(dict);

  args_dict = NULL;
  dict->GetDictionary("args", &args_dict);
  ASSERT_TRUE(args_dict);

  EXPECT_TRUE(args_dict->GetString("str", &str_value));
  EXPECT_STREQ("string value 2", str_value.c_str());

  value = NULL;
  convertable_dict = NULL;
  foo_val = 0;
  EXPECT_TRUE(args_dict->Get("convert", &value));
  ASSERT_TRUE(value->GetAsDictionary(&convertable_dict));
  EXPECT_TRUE(convertable_dict->GetInteger("foo", &foo_val));
  EXPECT_EQ(1, foo_val);
}

TEST_F(TraceEventTestFixture, PrimitiveArgs) {
  TraceLog::GetInstance()->SetEnabled(TraceConfig(kRecordAllCategoryFilter, ""),
                                      TraceLog::RECORDING_MODE);

  TRACE_EVENT1("foo", "event1", "int_one", 1);
  TRACE_EVENT1("foo", "event2", "int_neg_ten", -10);
  TRACE_EVENT1("foo", "event3", "float_one", 1.0f);
  TRACE_EVENT1("foo", "event4", "float_half", .5f);
  TRACE_EVENT1("foo", "event5", "float_neghalf", -.5f);
  TRACE_EVENT1("foo", "event6", "float_infinity",
      std::numeric_limits<float>::infinity());
  TRACE_EVENT1("foo", "event6b", "float_neg_infinity",
      -std::numeric_limits<float>::infinity());
  TRACE_EVENT1("foo", "event7", "double_nan",
      std::numeric_limits<double>::quiet_NaN());
  void* p = 0;
  TRACE_EVENT1("foo", "event8", "pointer_null", p);
  p = reinterpret_cast<void*>(0xbadf00d);
  TRACE_EVENT1("foo", "event9", "pointer_badf00d", p);
  TRACE_EVENT1("foo", "event10", "bool_true", true);
  TRACE_EVENT1("foo", "event11", "bool_false", false);
  TRACE_EVENT1("foo", "event12", "time_null",
      base::Time());
  TRACE_EVENT1("foo", "event13", "time_one",
      base::Time::FromInternalValue(1));
  TRACE_EVENT1("foo", "event14", "timeticks_null",
      base::TimeTicks());
  TRACE_EVENT1("foo", "event15", "timeticks_one",
      base::TimeTicks::FromInternalValue(1));
  EndTraceAndFlush();

  const DictionaryValue* args_dict = NULL;
  DictionaryValue* dict = NULL;
  const Value* value = NULL;
  std::string str_value;
  int int_value;
  double double_value;
  bool bool_value;

  dict = FindNamePhase("event1", "X");
  ASSERT_TRUE(dict);
  dict->GetDictionary("args", &args_dict);
  ASSERT_TRUE(args_dict);
  EXPECT_TRUE(args_dict->GetInteger("int_one", &int_value));
  EXPECT_EQ(1, int_value);

  dict = FindNamePhase("event2", "X");
  ASSERT_TRUE(dict);
  dict->GetDictionary("args", &args_dict);
  ASSERT_TRUE(args_dict);
  EXPECT_TRUE(args_dict->GetInteger("int_neg_ten", &int_value));
  EXPECT_EQ(-10, int_value);

  // 1f must be serlized to JSON as "1.0" in order to be a double, not an int.
  dict = FindNamePhase("event3", "X");
  ASSERT_TRUE(dict);
  dict->GetDictionary("args", &args_dict);
  ASSERT_TRUE(args_dict);
  EXPECT_TRUE(args_dict->Get("float_one", &value));
  EXPECT_TRUE(value->IsType(Value::TYPE_DOUBLE));
  EXPECT_TRUE(value->GetAsDouble(&double_value));
  EXPECT_EQ(1, double_value);

  // .5f must be serlized to JSON as "0.5".
  dict = FindNamePhase("event4", "X");
  ASSERT_TRUE(dict);
  dict->GetDictionary("args", &args_dict);
  ASSERT_TRUE(args_dict);
  EXPECT_TRUE(args_dict->Get("float_half", &value));
  EXPECT_TRUE(value->IsType(Value::TYPE_DOUBLE));
  EXPECT_TRUE(value->GetAsDouble(&double_value));
  EXPECT_EQ(0.5, double_value);

  // -.5f must be serlized to JSON as "-0.5".
  dict = FindNamePhase("event5", "X");
  ASSERT_TRUE(dict);
  dict->GetDictionary("args", &args_dict);
  ASSERT_TRUE(args_dict);
  EXPECT_TRUE(args_dict->Get("float_neghalf", &value));
  EXPECT_TRUE(value->IsType(Value::TYPE_DOUBLE));
  EXPECT_TRUE(value->GetAsDouble(&double_value));
  EXPECT_EQ(-0.5, double_value);

  // Infinity is serialized to JSON as a string.
  dict = FindNamePhase("event6", "X");
  ASSERT_TRUE(dict);
  dict->GetDictionary("args", &args_dict);
  ASSERT_TRUE(args_dict);
  EXPECT_TRUE(args_dict->GetString("float_infinity", &str_value));
  EXPECT_STREQ("Infinity", str_value.c_str());
  dict = FindNamePhase("event6b", "X");
  ASSERT_TRUE(dict);
  dict->GetDictionary("args", &args_dict);
  ASSERT_TRUE(args_dict);
  EXPECT_TRUE(args_dict->GetString("float_neg_infinity", &str_value));
  EXPECT_STREQ("-Infinity", str_value.c_str());

  // NaN is serialized to JSON as a string.
  dict = FindNamePhase("event7", "X");
  ASSERT_TRUE(dict);
  dict->GetDictionary("args", &args_dict);
  ASSERT_TRUE(args_dict);
  EXPECT_TRUE(args_dict->GetString("double_nan", &str_value));
  EXPECT_STREQ("NaN", str_value.c_str());

  // NULL pointers should be serialized as "0x0".
  dict = FindNamePhase("event8", "X");
  ASSERT_TRUE(dict);
  dict->GetDictionary("args", &args_dict);
  ASSERT_TRUE(args_dict);
  EXPECT_TRUE(args_dict->GetString("pointer_null", &str_value));
  EXPECT_STREQ("0x0", str_value.c_str());

  // Other pointers should be serlized as a hex string.
  dict = FindNamePhase("event9", "X");
  ASSERT_TRUE(dict);
  dict->GetDictionary("args", &args_dict);
  ASSERT_TRUE(args_dict);
  EXPECT_TRUE(args_dict->GetString("pointer_badf00d", &str_value));
  EXPECT_STREQ("0xbadf00d", str_value.c_str());

  dict = FindNamePhase("event10", "X");
  ASSERT_TRUE(dict);
  dict->GetDictionary("args", &args_dict);
  ASSERT_TRUE(args_dict);
  EXPECT_TRUE(args_dict->GetBoolean("bool_true", &bool_value));
  EXPECT_TRUE(bool_value);

  dict = FindNamePhase("event11", "X");
  ASSERT_TRUE(dict);
  dict->GetDictionary("args", &args_dict);
  ASSERT_TRUE(args_dict);
  EXPECT_TRUE(args_dict->GetBoolean("bool_false", &bool_value));
  EXPECT_FALSE(bool_value);

  dict = FindNamePhase("event12", "X");
  ASSERT_TRUE(dict);
  dict->GetDictionary("args", &args_dict);
  ASSERT_TRUE(args_dict);
  EXPECT_TRUE(args_dict->GetInteger("time_null", &int_value));
  EXPECT_EQ(0, int_value);

  dict = FindNamePhase("event13", "X");
  ASSERT_TRUE(dict);
  dict->GetDictionary("args", &args_dict);
  ASSERT_TRUE(args_dict);
  EXPECT_TRUE(args_dict->GetInteger("time_one", &int_value));
  EXPECT_EQ(1, int_value);

  dict = FindNamePhase("event14", "X");
  ASSERT_TRUE(dict);
  dict->GetDictionary("args", &args_dict);
  ASSERT_TRUE(args_dict);
  EXPECT_TRUE(args_dict->GetInteger("timeticks_null", &int_value));
  EXPECT_EQ(0, int_value);

  dict = FindNamePhase("event15", "X");
  ASSERT_TRUE(dict);
  dict->GetDictionary("args", &args_dict);
  ASSERT_TRUE(args_dict);
  EXPECT_TRUE(args_dict->GetInteger("timeticks_one", &int_value));
  EXPECT_EQ(1, int_value);
}

namespace {

bool IsTraceEventArgsWhitelisted(const char* category_group_name,
                                 const char* event_name) {
  if (MatchPattern(category_group_name, "toplevel") &&
      MatchPattern(event_name, "*")) {
    return true;
  }

  return false;
}

}  // namespace

TEST_F(TraceEventTestFixture, ArgsWhitelisting) {
  TraceLog::GetInstance()->SetArgumentFilterPredicate(
      base::Bind(&IsTraceEventArgsWhitelisted));

  TraceLog::GetInstance()->SetEnabled(
    TraceConfig(kRecordAllCategoryFilter, "enable-argument-filter"),
    TraceLog::RECORDING_MODE);

  TRACE_EVENT1("toplevel", "event1", "int_one", 1);
  TRACE_EVENT1("whitewashed", "event2", "int_two", 1);
  EndTraceAndFlush();

  const DictionaryValue* args_dict = NULL;
  DictionaryValue* dict = NULL;
  int int_value;

  dict = FindNamePhase("event1", "X");
  ASSERT_TRUE(dict);
  dict->GetDictionary("args", &args_dict);
  ASSERT_TRUE(args_dict);
  EXPECT_TRUE(args_dict->GetInteger("int_one", &int_value));
  EXPECT_EQ(1, int_value);

  dict = FindNamePhase("event2", "X");
  ASSERT_TRUE(dict);
  dict->GetDictionary("args", &args_dict);
  ASSERT_TRUE(args_dict);
  EXPECT_FALSE(args_dict->GetInteger("int_two", &int_value));
  EXPECT_TRUE(args_dict->GetInteger("stripped", &int_value));
}

class TraceEventCallbackTest : public TraceEventTestFixture {
 public:
  void SetUp() override {
    TraceEventTestFixture::SetUp();
    ASSERT_EQ(NULL, s_instance);
    s_instance = this;
  }
  void TearDown() override {
    TraceLog::GetInstance()->SetDisabled();
    ASSERT_TRUE(s_instance);
    s_instance = NULL;
    TraceEventTestFixture::TearDown();
  }

 protected:
  // For TraceEventCallbackAndRecordingX tests.
  void VerifyCallbackAndRecordedEvents(size_t expected_callback_count,
                                       size_t expected_recorded_count) {
    // Callback events.
    EXPECT_EQ(expected_callback_count, collected_events_names_.size());
    for (size_t i = 0; i < collected_events_names_.size(); ++i) {
      EXPECT_EQ("callback", collected_events_categories_[i]);
      EXPECT_EQ("yes", collected_events_names_[i]);
    }

    // Recorded events.
    EXPECT_EQ(expected_recorded_count, trace_parsed_.GetSize());
    EXPECT_TRUE(FindTraceEntry(trace_parsed_, "recording"));
    EXPECT_FALSE(FindTraceEntry(trace_parsed_, "callback"));
    EXPECT_TRUE(FindTraceEntry(trace_parsed_, "yes"));
    EXPECT_FALSE(FindTraceEntry(trace_parsed_, "no"));
  }

  void VerifyCollectedEvent(size_t i,
                            unsigned phase,
                            const std::string& category,
                            const std::string& name) {
    EXPECT_EQ(phase, collected_events_phases_[i]);
    EXPECT_EQ(category, collected_events_categories_[i]);
    EXPECT_EQ(name, collected_events_names_[i]);
  }

  std::vector<std::string> collected_events_categories_;
  std::vector<std::string> collected_events_names_;
  std::vector<unsigned char> collected_events_phases_;
  std::vector<TraceTicks> collected_events_timestamps_;

  static TraceEventCallbackTest* s_instance;
  static void Callback(TraceTicks timestamp,
                       char phase,
                       const unsigned char* category_group_enabled,
                       const char* name,
                       unsigned long long id,
                       int num_args,
                       const char* const arg_names[],
                       const unsigned char arg_types[],
                       const unsigned long long arg_values[],
                       unsigned char flags) {
    s_instance->collected_events_phases_.push_back(phase);
    s_instance->collected_events_categories_.push_back(
        TraceLog::GetCategoryGroupName(category_group_enabled));
    s_instance->collected_events_names_.push_back(name);
    s_instance->collected_events_timestamps_.push_back(timestamp);
  }
};

TraceEventCallbackTest* TraceEventCallbackTest::s_instance;

TEST_F(TraceEventCallbackTest, TraceEventCallback) {
  TRACE_EVENT_INSTANT0("all", "before enable", TRACE_EVENT_SCOPE_THREAD);
  TraceLog::GetInstance()->SetEventCallbackEnabled(
      TraceConfig(kRecordAllCategoryFilter, ""), Callback);
  TRACE_EVENT_INSTANT0("all", "event1", TRACE_EVENT_SCOPE_GLOBAL);
  TRACE_EVENT_INSTANT0("all", "event2", TRACE_EVENT_SCOPE_GLOBAL);
  {
    TRACE_EVENT0("all", "duration");
    TRACE_EVENT_INSTANT0("all", "event3", TRACE_EVENT_SCOPE_GLOBAL);
  }
  TraceLog::GetInstance()->SetEventCallbackDisabled();
  TRACE_EVENT_INSTANT0("all", "after callback removed",
                       TRACE_EVENT_SCOPE_GLOBAL);
  ASSERT_EQ(5u, collected_events_names_.size());
  EXPECT_EQ("event1", collected_events_names_[0]);
  EXPECT_EQ(TRACE_EVENT_PHASE_INSTANT, collected_events_phases_[0]);
  EXPECT_EQ("event2", collected_events_names_[1]);
  EXPECT_EQ(TRACE_EVENT_PHASE_INSTANT, collected_events_phases_[1]);
  EXPECT_EQ("duration", collected_events_names_[2]);
  EXPECT_EQ(TRACE_EVENT_PHASE_BEGIN, collected_events_phases_[2]);
  EXPECT_EQ("event3", collected_events_names_[3]);
  EXPECT_EQ(TRACE_EVENT_PHASE_INSTANT, collected_events_phases_[3]);
  EXPECT_EQ("duration", collected_events_names_[4]);
  EXPECT_EQ(TRACE_EVENT_PHASE_END, collected_events_phases_[4]);
  for (size_t i = 1; i < collected_events_timestamps_.size(); i++) {
    EXPECT_LE(collected_events_timestamps_[i - 1],
              collected_events_timestamps_[i]);
  }
}

TEST_F(TraceEventCallbackTest, TraceEventCallbackWhileFull) {
  TraceLog::GetInstance()->SetEnabled(TraceConfig(kRecordAllCategoryFilter, ""),
                                      TraceLog::RECORDING_MODE);
  do {
    TRACE_EVENT_INSTANT0("all", "badger badger", TRACE_EVENT_SCOPE_GLOBAL);
  } while (!TraceLog::GetInstance()->BufferIsFull());
  TraceLog::GetInstance()->SetEventCallbackEnabled(
      TraceConfig(kRecordAllCategoryFilter, ""), Callback);
  TRACE_EVENT_INSTANT0("all", "a snake", TRACE_EVENT_SCOPE_GLOBAL);
  TraceLog::GetInstance()->SetEventCallbackDisabled();
  ASSERT_EQ(1u, collected_events_names_.size());
  EXPECT_EQ("a snake", collected_events_names_[0]);
}

// 1: Enable callback, enable recording, disable callback, disable recording.
TEST_F(TraceEventCallbackTest, TraceEventCallbackAndRecording1) {
  TRACE_EVENT_INSTANT0("recording", "no", TRACE_EVENT_SCOPE_GLOBAL);
  TRACE_EVENT_INSTANT0("callback", "no", TRACE_EVENT_SCOPE_GLOBAL);
  TraceLog::GetInstance()->SetEventCallbackEnabled(TraceConfig("callback", ""),
                                                   Callback);
  TRACE_EVENT_INSTANT0("recording", "no", TRACE_EVENT_SCOPE_GLOBAL);
  TRACE_EVENT_INSTANT0("callback", "yes", TRACE_EVENT_SCOPE_GLOBAL);
  TraceLog::GetInstance()->SetEnabled(TraceConfig("recording", ""),
                                      TraceLog::RECORDING_MODE);
  TRACE_EVENT_INSTANT0("recording", "yes", TRACE_EVENT_SCOPE_GLOBAL);
  TRACE_EVENT_INSTANT0("callback", "yes", TRACE_EVENT_SCOPE_GLOBAL);
  TraceLog::GetInstance()->SetEventCallbackDisabled();
  TRACE_EVENT_INSTANT0("recording", "yes", TRACE_EVENT_SCOPE_GLOBAL);
  TRACE_EVENT_INSTANT0("callback", "no", TRACE_EVENT_SCOPE_GLOBAL);
  EndTraceAndFlush();
  TRACE_EVENT_INSTANT0("recording", "no", TRACE_EVENT_SCOPE_GLOBAL);
  TRACE_EVENT_INSTANT0("callback", "no", TRACE_EVENT_SCOPE_GLOBAL);

  DropTracedMetadataRecords();
  VerifyCallbackAndRecordedEvents(2, 2);
}

// 2: Enable callback, enable recording, disable recording, disable callback.
TEST_F(TraceEventCallbackTest, TraceEventCallbackAndRecording2) {
  TRACE_EVENT_INSTANT0("recording", "no", TRACE_EVENT_SCOPE_GLOBAL);
  TRACE_EVENT_INSTANT0("callback", "no", TRACE_EVENT_SCOPE_GLOBAL);
  TraceLog::GetInstance()->SetEventCallbackEnabled(TraceConfig("callback", ""),
                                                   Callback);
  TRACE_EVENT_INSTANT0("recording", "no", TRACE_EVENT_SCOPE_GLOBAL);
  TRACE_EVENT_INSTANT0("callback", "yes", TRACE_EVENT_SCOPE_GLOBAL);
  TraceLog::GetInstance()->SetEnabled(TraceConfig("recording", ""),
                                      TraceLog::RECORDING_MODE);
  TRACE_EVENT_INSTANT0("recording", "yes", TRACE_EVENT_SCOPE_GLOBAL);
  TRACE_EVENT_INSTANT0("callback", "yes", TRACE_EVENT_SCOPE_GLOBAL);
  EndTraceAndFlush();
  TRACE_EVENT_INSTANT0("recording", "no", TRACE_EVENT_SCOPE_GLOBAL);
  TRACE_EVENT_INSTANT0("callback", "yes", TRACE_EVENT_SCOPE_GLOBAL);
  TraceLog::GetInstance()->SetEventCallbackDisabled();
  TRACE_EVENT_INSTANT0("recording", "no", TRACE_EVENT_SCOPE_GLOBAL);
  TRACE_EVENT_INSTANT0("callback", "no", TRACE_EVENT_SCOPE_GLOBAL);

  DropTracedMetadataRecords();
  VerifyCallbackAndRecordedEvents(3, 1);
}

// 3: Enable recording, enable callback, disable callback, disable recording.
TEST_F(TraceEventCallbackTest, TraceEventCallbackAndRecording3) {
  TRACE_EVENT_INSTANT0("recording", "no", TRACE_EVENT_SCOPE_GLOBAL);
  TRACE_EVENT_INSTANT0("callback", "no", TRACE_EVENT_SCOPE_GLOBAL);
  TraceLog::GetInstance()->SetEnabled(TraceConfig("recording", ""),
                                      TraceLog::RECORDING_MODE);
  TRACE_EVENT_INSTANT0("recording", "yes", TRACE_EVENT_SCOPE_GLOBAL);
  TRACE_EVENT_INSTANT0("callback", "no", TRACE_EVENT_SCOPE_GLOBAL);
  TraceLog::GetInstance()->SetEventCallbackEnabled(TraceConfig("callback", ""),
                                                   Callback);
  TRACE_EVENT_INSTANT0("recording", "yes", TRACE_EVENT_SCOPE_GLOBAL);
  TRACE_EVENT_INSTANT0("callback", "yes", TRACE_EVENT_SCOPE_GLOBAL);
  TraceLog::GetInstance()->SetEventCallbackDisabled();
  TRACE_EVENT_INSTANT0("recording", "yes", TRACE_EVENT_SCOPE_GLOBAL);
  TRACE_EVENT_INSTANT0("callback", "no", TRACE_EVENT_SCOPE_GLOBAL);
  EndTraceAndFlush();
  TRACE_EVENT_INSTANT0("recording", "no", TRACE_EVENT_SCOPE_GLOBAL);
  TRACE_EVENT_INSTANT0("callback", "no", TRACE_EVENT_SCOPE_GLOBAL);

  DropTracedMetadataRecords();
  VerifyCallbackAndRecordedEvents(1, 3);
}

// 4: Enable recording, enable callback, disable recording, disable callback.
TEST_F(TraceEventCallbackTest, TraceEventCallbackAndRecording4) {
  TRACE_EVENT_INSTANT0("recording", "no", TRACE_EVENT_SCOPE_GLOBAL);
  TRACE_EVENT_INSTANT0("callback", "no", TRACE_EVENT_SCOPE_GLOBAL);
  TraceLog::GetInstance()->SetEnabled(TraceConfig("recording", ""),
                                      TraceLog::RECORDING_MODE);
  TRACE_EVENT_INSTANT0("recording", "yes", TRACE_EVENT_SCOPE_GLOBAL);
  TRACE_EVENT_INSTANT0("callback", "no", TRACE_EVENT_SCOPE_GLOBAL);
  TraceLog::GetInstance()->SetEventCallbackEnabled(TraceConfig("callback", ""),
                                                   Callback);
  TRACE_EVENT_INSTANT0("recording", "yes", TRACE_EVENT_SCOPE_GLOBAL);
  TRACE_EVENT_INSTANT0("callback", "yes", TRACE_EVENT_SCOPE_GLOBAL);
  EndTraceAndFlush();
  TRACE_EVENT_INSTANT0("recording", "no", TRACE_EVENT_SCOPE_GLOBAL);
  TRACE_EVENT_INSTANT0("callback", "yes", TRACE_EVENT_SCOPE_GLOBAL);
  TraceLog::GetInstance()->SetEventCallbackDisabled();
  TRACE_EVENT_INSTANT0("recording", "no", TRACE_EVENT_SCOPE_GLOBAL);
  TRACE_EVENT_INSTANT0("callback", "no", TRACE_EVENT_SCOPE_GLOBAL);

  DropTracedMetadataRecords();
  VerifyCallbackAndRecordedEvents(2, 2);
}

TEST_F(TraceEventCallbackTest, TraceEventCallbackAndRecordingDuration) {
  TraceLog::GetInstance()->SetEventCallbackEnabled(
      TraceConfig(kRecordAllCategoryFilter, ""), Callback);
  {
    TRACE_EVENT0("callback", "duration1");
    TraceLog::GetInstance()->SetEnabled(
        TraceConfig(kRecordAllCategoryFilter, ""), TraceLog::RECORDING_MODE);
    TRACE_EVENT0("callback", "duration2");
    EndTraceAndFlush();
    TRACE_EVENT0("callback", "duration3");
  }
  TraceLog::GetInstance()->SetEventCallbackDisabled();

  ASSERT_EQ(6u, collected_events_names_.size());
  VerifyCollectedEvent(0, TRACE_EVENT_PHASE_BEGIN, "callback", "duration1");
  VerifyCollectedEvent(1, TRACE_EVENT_PHASE_BEGIN, "callback", "duration2");
  VerifyCollectedEvent(2, TRACE_EVENT_PHASE_BEGIN, "callback", "duration3");
  VerifyCollectedEvent(3, TRACE_EVENT_PHASE_END, "callback", "duration3");
  VerifyCollectedEvent(4, TRACE_EVENT_PHASE_END, "callback", "duration2");
  VerifyCollectedEvent(5, TRACE_EVENT_PHASE_END, "callback", "duration1");
}

TEST_F(TraceEventTestFixture, TraceBufferVectorReportFull) {
  TraceLog* trace_log = TraceLog::GetInstance();
  trace_log->SetEnabled(
      TraceConfig(kRecordAllCategoryFilter, ""), TraceLog::RECORDING_MODE);
  trace_log->logged_events_.reset(
      trace_log->CreateTraceBufferVectorOfSize(100));
  do {
    TRACE_EVENT_BEGIN_WITH_ID_TID_AND_TIMESTAMP0(
        "all", "with_timestamp", 0, 0, TraceTicks::Now().ToInternalValue());
    TRACE_EVENT_END_WITH_ID_TID_AND_TIMESTAMP0(
        "all", "with_timestamp", 0, 0, TraceTicks::Now().ToInternalValue());
  } while (!trace_log->BufferIsFull());

  EndTraceAndFlush();

  const DictionaryValue* trace_full_metadata = NULL;

  trace_full_metadata = FindTraceEntry(trace_parsed_,
                                       "overflowed_at_ts");
  std::string phase;
  double buffer_limit_reached_timestamp = 0;

  EXPECT_TRUE(trace_full_metadata);
  EXPECT_TRUE(trace_full_metadata->GetString("ph", &phase));
  EXPECT_EQ("M", phase);
  EXPECT_TRUE(trace_full_metadata->GetDouble(
      "args.overflowed_at_ts", &buffer_limit_reached_timestamp));
  EXPECT_DOUBLE_EQ(
      static_cast<double>(
          trace_log->buffer_limit_reached_timestamp_.ToInternalValue()),
      buffer_limit_reached_timestamp);

  // Test that buffer_limit_reached_timestamp's value is between the timestamp
  // of the last trace event and current time.
  DropTracedMetadataRecords();
  const DictionaryValue* last_trace_event = NULL;
  double last_trace_event_timestamp = 0;
  EXPECT_TRUE(trace_parsed_.GetDictionary(trace_parsed_.GetSize() - 1,
                                          &last_trace_event));
  EXPECT_TRUE(last_trace_event->GetDouble("ts", &last_trace_event_timestamp));
  EXPECT_LE(last_trace_event_timestamp, buffer_limit_reached_timestamp);
  EXPECT_LE(buffer_limit_reached_timestamp,
            trace_log->OffsetNow().ToInternalValue());
}

TEST_F(TraceEventTestFixture, TraceBufferRingBufferGetReturnChunk) {
  TraceLog::GetInstance()->SetEnabled(
      TraceConfig(kRecordAllCategoryFilter, RECORD_CONTINUOUSLY),
      TraceLog::RECORDING_MODE);
  TraceBuffer* buffer = TraceLog::GetInstance()->trace_buffer();
  size_t capacity = buffer->Capacity();
  size_t num_chunks = capacity / TraceBufferChunk::kTraceBufferChunkSize;
  uint32 last_seq = 0;
  size_t chunk_index;
  EXPECT_EQ(0u, buffer->Size());

  scoped_ptr<TraceBufferChunk*[]> chunks(new TraceBufferChunk*[num_chunks]);
  for (size_t i = 0; i < num_chunks; ++i) {
    chunks[i] = buffer->GetChunk(&chunk_index).release();
    EXPECT_TRUE(chunks[i]);
    EXPECT_EQ(i, chunk_index);
    EXPECT_GT(chunks[i]->seq(), last_seq);
    EXPECT_EQ((i + 1) * TraceBufferChunk::kTraceBufferChunkSize,
              buffer->Size());
    last_seq = chunks[i]->seq();
  }

  // Ring buffer is never full.
  EXPECT_FALSE(buffer->IsFull());

  // Return all chunks in original order.
  for (size_t i = 0; i < num_chunks; ++i)
    buffer->ReturnChunk(i, scoped_ptr<TraceBufferChunk>(chunks[i]));

  // Should recycle the chunks in the returned order.
  for (size_t i = 0; i < num_chunks; ++i) {
    chunks[i] = buffer->GetChunk(&chunk_index).release();
    EXPECT_TRUE(chunks[i]);
    EXPECT_EQ(i, chunk_index);
    EXPECT_GT(chunks[i]->seq(), last_seq);
    last_seq = chunks[i]->seq();
  }

  // Return all chunks in reverse order.
  for (size_t i = 0; i < num_chunks; ++i) {
    buffer->ReturnChunk(
        num_chunks - i - 1,
        scoped_ptr<TraceBufferChunk>(chunks[num_chunks - i - 1]));
  }

  // Should recycle the chunks in the returned order.
  for (size_t i = 0; i < num_chunks; ++i) {
    chunks[i] = buffer->GetChunk(&chunk_index).release();
    EXPECT_TRUE(chunks[i]);
    EXPECT_EQ(num_chunks - i - 1, chunk_index);
    EXPECT_GT(chunks[i]->seq(), last_seq);
    last_seq = chunks[i]->seq();
  }

  for (size_t i = 0; i < num_chunks; ++i)
    buffer->ReturnChunk(i, scoped_ptr<TraceBufferChunk>(chunks[i]));

  TraceLog::GetInstance()->SetDisabled();
}

TEST_F(TraceEventTestFixture, TraceBufferRingBufferHalfIteration) {
  TraceLog::GetInstance()->SetEnabled(
      TraceConfig(kRecordAllCategoryFilter, RECORD_CONTINUOUSLY),
      TraceLog::RECORDING_MODE);
  TraceBuffer* buffer = TraceLog::GetInstance()->trace_buffer();
  size_t capacity = buffer->Capacity();
  size_t num_chunks = capacity / TraceBufferChunk::kTraceBufferChunkSize;
  size_t chunk_index;
  EXPECT_EQ(0u, buffer->Size());
  EXPECT_FALSE(buffer->NextChunk());

  size_t half_chunks = num_chunks / 2;
  scoped_ptr<TraceBufferChunk*[]> chunks(new TraceBufferChunk*[half_chunks]);

  for (size_t i = 0; i < half_chunks; ++i) {
    chunks[i] = buffer->GetChunk(&chunk_index).release();
    EXPECT_TRUE(chunks[i]);
    EXPECT_EQ(i, chunk_index);
  }
  for (size_t i = 0; i < half_chunks; ++i)
    buffer->ReturnChunk(i, scoped_ptr<TraceBufferChunk>(chunks[i]));

  for (size_t i = 0; i < half_chunks; ++i)
    EXPECT_EQ(chunks[i], buffer->NextChunk());
  EXPECT_FALSE(buffer->NextChunk());
  TraceLog::GetInstance()->SetDisabled();
}

TEST_F(TraceEventTestFixture, TraceBufferRingBufferFullIteration) {
  TraceLog::GetInstance()->SetEnabled(
      TraceConfig(kRecordAllCategoryFilter, RECORD_CONTINUOUSLY),
      TraceLog::RECORDING_MODE);
  TraceBuffer* buffer = TraceLog::GetInstance()->trace_buffer();
  size_t capacity = buffer->Capacity();
  size_t num_chunks = capacity / TraceBufferChunk::kTraceBufferChunkSize;
  size_t chunk_index;
  EXPECT_EQ(0u, buffer->Size());
  EXPECT_FALSE(buffer->NextChunk());

  scoped_ptr<TraceBufferChunk*[]> chunks(new TraceBufferChunk*[num_chunks]);

  for (size_t i = 0; i < num_chunks; ++i) {
    chunks[i] = buffer->GetChunk(&chunk_index).release();
    EXPECT_TRUE(chunks[i]);
    EXPECT_EQ(i, chunk_index);
  }
  for (size_t i = 0; i < num_chunks; ++i)
    buffer->ReturnChunk(i, scoped_ptr<TraceBufferChunk>(chunks[i]));

  for (size_t i = 0; i < num_chunks; ++i)
    EXPECT_TRUE(chunks[i] == buffer->NextChunk());
  EXPECT_FALSE(buffer->NextChunk());
  TraceLog::GetInstance()->SetDisabled();
}

TEST_F(TraceEventTestFixture, TraceRecordAsMuchAsPossibleMode) {
  TraceLog::GetInstance()->SetEnabled(
    TraceConfig(kRecordAllCategoryFilter, RECORD_AS_MUCH_AS_POSSIBLE),
    TraceLog::RECORDING_MODE);
  TraceBuffer* buffer = TraceLog::GetInstance()->trace_buffer();
  EXPECT_EQ(512000000UL, buffer->Capacity());
  TraceLog::GetInstance()->SetDisabled();
}

void BlockUntilStopped(WaitableEvent* task_start_event,
                       WaitableEvent* task_stop_event) {
  task_start_event->Signal();
  task_stop_event->Wait();
}

TEST_F(TraceEventTestFixture, SetCurrentThreadBlocksMessageLoopBeforeTracing) {
  BeginTrace();

  Thread thread("1");
  WaitableEvent task_complete_event(false, false);
  thread.Start();
  thread.task_runner()->PostTask(
      FROM_HERE, Bind(&TraceLog::SetCurrentThreadBlocksMessageLoop,
                      Unretained(TraceLog::GetInstance())));

  thread.task_runner()->PostTask(
      FROM_HERE, Bind(&TraceWithAllMacroVariants, &task_complete_event));
  task_complete_event.Wait();

  WaitableEvent task_start_event(false, false);
  WaitableEvent task_stop_event(false, false);
  thread.task_runner()->PostTask(
      FROM_HERE, Bind(&BlockUntilStopped, &task_start_event, &task_stop_event));
  task_start_event.Wait();

  EndTraceAndFlush();
  ValidateAllTraceMacrosCreatedData(trace_parsed_);

  task_stop_event.Signal();
  thread.Stop();
}

TEST_F(TraceEventTestFixture, ConvertTraceConfigToInternalOptions) {
  TraceLog* trace_log = TraceLog::GetInstance();
  EXPECT_EQ(TraceLog::kInternalRecordUntilFull,
            trace_log->GetInternalOptionsFromTraceConfig(
                TraceConfig(kRecordAllCategoryFilter, RECORD_UNTIL_FULL)));

  EXPECT_EQ(TraceLog::kInternalRecordContinuously,
            trace_log->GetInternalOptionsFromTraceConfig(
                TraceConfig(kRecordAllCategoryFilter, RECORD_CONTINUOUSLY)));

  EXPECT_EQ(TraceLog::kInternalEchoToConsole,
            trace_log->GetInternalOptionsFromTraceConfig(
                TraceConfig(kRecordAllCategoryFilter, ECHO_TO_CONSOLE)));

  EXPECT_EQ(
      TraceLog::kInternalRecordUntilFull | TraceLog::kInternalEnableSampling,
      trace_log->GetInternalOptionsFromTraceConfig(
          TraceConfig(kRecordAllCategoryFilter,
                      "record-until-full,enable-sampling")));

  EXPECT_EQ(
      TraceLog::kInternalRecordContinuously | TraceLog::kInternalEnableSampling,
      trace_log->GetInternalOptionsFromTraceConfig(
          TraceConfig(kRecordAllCategoryFilter,
                      "record-continuously,enable-sampling")));

  EXPECT_EQ(
      TraceLog::kInternalEchoToConsole | TraceLog::kInternalEnableSampling,
      trace_log->GetInternalOptionsFromTraceConfig(
          TraceConfig(kRecordAllCategoryFilter,
                      "trace-to-console,enable-sampling")));

  EXPECT_EQ(
      TraceLog::kInternalEchoToConsole | TraceLog::kInternalEnableSampling,
      trace_log->GetInternalOptionsFromTraceConfig(
          TraceConfig("*",
                      "trace-to-console,enable-sampling,enable-systrace")));
}

void SetBlockingFlagAndBlockUntilStopped(WaitableEvent* task_start_event,
                                         WaitableEvent* task_stop_event) {
  TraceLog::GetInstance()->SetCurrentThreadBlocksMessageLoop();
  BlockUntilStopped(task_start_event, task_stop_event);
}

TEST_F(TraceEventTestFixture, SetCurrentThreadBlocksMessageLoopAfterTracing) {
  BeginTrace();

  Thread thread("1");
  WaitableEvent task_complete_event(false, false);
  thread.Start();

  thread.task_runner()->PostTask(
      FROM_HERE, Bind(&TraceWithAllMacroVariants, &task_complete_event));
  task_complete_event.Wait();

  WaitableEvent task_start_event(false, false);
  WaitableEvent task_stop_event(false, false);
  thread.task_runner()->PostTask(
      FROM_HERE, Bind(&SetBlockingFlagAndBlockUntilStopped, &task_start_event,
                      &task_stop_event));
  task_start_event.Wait();

  EndTraceAndFlush();
  ValidateAllTraceMacrosCreatedData(trace_parsed_);

  task_stop_event.Signal();
  thread.Stop();
}

TEST_F(TraceEventTestFixture, ThreadOnceBlocking) {
  BeginTrace();

  Thread thread("1");
  WaitableEvent task_complete_event(false, false);
  thread.Start();

  thread.task_runner()->PostTask(
      FROM_HERE, Bind(&TraceWithAllMacroVariants, &task_complete_event));
  task_complete_event.Wait();
  task_complete_event.Reset();

  WaitableEvent task_start_event(false, false);
  WaitableEvent task_stop_event(false, false);
  thread.task_runner()->PostTask(
      FROM_HERE, Bind(&BlockUntilStopped, &task_start_event, &task_stop_event));
  task_start_event.Wait();

  // The thread will timeout in this flush.
  EndTraceAndFlushInThreadWithMessageLoop();
  Clear();

  // Let the thread's message loop continue to spin.
  task_stop_event.Signal();

  // The following sequence ensures that the FlushCurrentThread task has been
  // executed in the thread before continuing.
  task_start_event.Reset();
  task_stop_event.Reset();
  thread.task_runner()->PostTask(
      FROM_HERE, Bind(&BlockUntilStopped, &task_start_event, &task_stop_event));
  task_start_event.Wait();
  task_stop_event.Signal();
  Clear();

  // TraceLog should discover the generation mismatch and recover the thread
  // local buffer for the thread without any error.
  BeginTrace();
  thread.task_runner()->PostTask(
      FROM_HERE, Bind(&TraceWithAllMacroVariants, &task_complete_event));
  task_complete_event.Wait();
  task_complete_event.Reset();
  EndTraceAndFlushInThreadWithMessageLoop();
  ValidateAllTraceMacrosCreatedData(trace_parsed_);
}

std::string* g_log_buffer = NULL;
bool MockLogMessageHandler(int, const char*, int, size_t,
                           const std::string& str) {
  if (!g_log_buffer)
    g_log_buffer = new std::string();
  g_log_buffer->append(str);
  return false;
}

TEST_F(TraceEventTestFixture, EchoToConsole) {
  logging::LogMessageHandlerFunction old_log_message_handler =
      logging::GetLogMessageHandler();
  logging::SetLogMessageHandler(MockLogMessageHandler);

  TraceLog::GetInstance()->SetEnabled(
      TraceConfig(kRecordAllCategoryFilter, ECHO_TO_CONSOLE),
      TraceLog::RECORDING_MODE);
  TRACE_EVENT_BEGIN0("a", "begin_end");
  {
    TRACE_EVENT0("b", "duration");
    TRACE_EVENT0("b1", "duration1");
  }
  TRACE_EVENT_INSTANT0("c", "instant", TRACE_EVENT_SCOPE_GLOBAL);
  TRACE_EVENT_END0("a", "begin_end");

  EXPECT_NE(std::string::npos, g_log_buffer->find("begin_end[a]\x1b"));
  EXPECT_NE(std::string::npos, g_log_buffer->find("| duration[b]\x1b"));
  EXPECT_NE(std::string::npos, g_log_buffer->find("| | duration1[b1]\x1b"));
  EXPECT_NE(std::string::npos, g_log_buffer->find("| | duration1[b1] ("));
  EXPECT_NE(std::string::npos, g_log_buffer->find("| duration[b] ("));
  EXPECT_NE(std::string::npos, g_log_buffer->find("| instant[c]\x1b"));
  EXPECT_NE(std::string::npos, g_log_buffer->find("begin_end[a] ("));

  EndTraceAndFlush();
  delete g_log_buffer;
  logging::SetLogMessageHandler(old_log_message_handler);
  g_log_buffer = NULL;
}

bool LogMessageHandlerWithTraceEvent(int, const char*, int, size_t,
                                     const std::string&) {
  TRACE_EVENT0("log", "trace_event");
  return false;
}

TEST_F(TraceEventTestFixture, EchoToConsoleTraceEventRecursion) {
  logging::LogMessageHandlerFunction old_log_message_handler =
      logging::GetLogMessageHandler();
  logging::SetLogMessageHandler(LogMessageHandlerWithTraceEvent);

  TraceLog::GetInstance()->SetEnabled(
      TraceConfig(kRecordAllCategoryFilter, ECHO_TO_CONSOLE),
      TraceLog::RECORDING_MODE);
  {
    // This should not cause deadlock or infinite recursion.
    TRACE_EVENT0("b", "duration");
  }

  EndTraceAndFlush();
  logging::SetLogMessageHandler(old_log_message_handler);
}

TEST_F(TraceEventTestFixture, TimeOffset) {
  BeginTrace();
  // Let TraceLog timer start from 0.
  TimeDelta time_offset = TraceTicks::Now() - TraceTicks();
  TraceLog::GetInstance()->SetTimeOffset(time_offset);

  {
    TRACE_EVENT0("all", "duration1");
    TRACE_EVENT0("all", "duration2");
  }
  TRACE_EVENT_BEGIN_WITH_ID_TID_AND_TIMESTAMP0(
      "all", "with_timestamp", 0, 0, TraceTicks::Now().ToInternalValue());
  TRACE_EVENT_END_WITH_ID_TID_AND_TIMESTAMP0(
      "all", "with_timestamp", 0, 0, TraceTicks::Now().ToInternalValue());

  EndTraceAndFlush();
  DropTracedMetadataRecords();

  double end_time = static_cast<double>(
      (TraceTicks::Now() - time_offset).ToInternalValue());
  double last_timestamp = 0;
  for (size_t i = 0; i < trace_parsed_.GetSize(); ++i) {
    const DictionaryValue* item;
    EXPECT_TRUE(trace_parsed_.GetDictionary(i, &item));
    double timestamp;
    EXPECT_TRUE(item->GetDouble("ts", &timestamp));
    EXPECT_GE(timestamp, last_timestamp);
    EXPECT_LE(timestamp, end_time);
    last_timestamp = timestamp;
  }
}

TEST_F(TraceEventTestFixture, ConfigureSyntheticDelays) {
  BeginSpecificTrace("DELAY(test.Delay;0.05)");

  base::TimeTicks start = base::TimeTicks::Now();
  {
    TRACE_EVENT_SYNTHETIC_DELAY("test.Delay");
  }
  base::TimeDelta duration = base::TimeTicks::Now() - start;
  EXPECT_GE(duration.InMilliseconds(), 50);

  EndTraceAndFlush();
}

TEST_F(TraceEventTestFixture, BadSyntheticDelayConfigurations) {
  const char* const filters[] = {
    "",
    "DELAY(",
    "DELAY(;",
    "DELAY(;)",
    "DELAY(test.Delay)",
    "DELAY(test.Delay;)"
  };
  for (size_t i = 0; i < arraysize(filters); i++) {
    BeginSpecificTrace(filters[i]);
    EndTraceAndFlush();
    TraceConfig trace_config = TraceLog::GetInstance()->GetCurrentTraceConfig();
    EXPECT_EQ(0u, trace_config.GetSyntheticDelayValues().size());
  }
}

TEST_F(TraceEventTestFixture, SyntheticDelayConfigurationMerging) {
  TraceConfig config1("DELAY(test.Delay1;16)", "");
  TraceConfig config2("DELAY(test.Delay2;32)", "");
  config1.Merge(config2);
  EXPECT_EQ(2u, config1.GetSyntheticDelayValues().size());
}

TEST_F(TraceEventTestFixture, SyntheticDelayConfigurationToString) {
  const char filter[] = "DELAY(test.Delay;16;oneshot)";
  TraceConfig config(filter, "");
  EXPECT_EQ(filter, config.ToCategoryFilterString());
}

}  // namespace trace_event
}  // namespace base
