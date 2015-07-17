// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/trace_event/trace_event_impl.h"

#include <fcntl.h>

#include "base/format_macros.h"
#include "base/logging.h"
#include "base/strings/stringprintf.h"
#include "base/synchronization/waitable_event.h"
#include "base/trace_event/trace_event.h"

namespace base {
namespace trace_event {

namespace {

int g_atrace_fd = -1;
const char kATraceMarkerFile[] = "/sys/kernel/debug/tracing/trace_marker";

void WriteEvent(
    char phase,
    const char* category_group,
    const char* name,
    unsigned long long id,
    const char** arg_names,
    const unsigned char* arg_types,
    const TraceEvent::TraceValue* arg_values,
    const scoped_refptr<ConvertableToTraceFormat>* convertable_values,
    unsigned int flags) {
  std::string out = StringPrintf("%c|%d|%s", phase, getpid(), name);
  if (flags & TRACE_EVENT_FLAG_HAS_ID)
    StringAppendF(&out, "-%" PRIx64, static_cast<uint64>(id));
  out += '|';

  for (int i = 0; i < kTraceMaxNumArgs && arg_names[i];
       ++i) {
    if (i)
      out += ';';
    out += arg_names[i];
    out += '=';
    std::string::size_type value_start = out.length();
    if (arg_types[i] == TRACE_VALUE_TYPE_CONVERTABLE)
      convertable_values[i]->AppendAsTraceFormat(&out);
    else
      TraceEvent::AppendValueAsJSON(arg_types[i], arg_values[i], &out);

    // Remove the quotes which may confuse the atrace script.
    ReplaceSubstringsAfterOffset(&out, value_start, "\\\"", "'");
    ReplaceSubstringsAfterOffset(&out, value_start, "\"", "");
    // Replace chars used for separators with similar chars in the value.
    std::replace(out.begin() + value_start, out.end(), ';', ',');
    std::replace(out.begin() + value_start, out.end(), '|', '!');
  }

  out += '|';
  out += category_group;
  write(g_atrace_fd, out.c_str(), out.size());
}

void NoOpOutputCallback(WaitableEvent* complete_event,
                        const scoped_refptr<RefCountedString>&,
                        bool has_more_events) {
  if (!has_more_events)
    complete_event->Signal();
}

void EndChromeTracing(TraceLog* trace_log,
                      WaitableEvent* complete_event) {
  trace_log->SetDisabled();
  // Delete the buffered trace events as they have been sent to atrace.
  trace_log->Flush(Bind(&NoOpOutputCallback, complete_event));
}

}  // namespace

// These functions support Android systrace.py when 'webview' category is
// traced. With the new adb_profile_chrome, we may have two phases:
// - before WebView is ready for combined tracing, we can use adb_profile_chrome
//   to trace android categories other than 'webview' and chromium categories.
//   In this way we can avoid the conflict between StartATrace/StopATrace and
//   the intents.
// - TODO(wangxianzhu): after WebView is ready for combined tracing, remove
//   StartATrace, StopATrace and SendToATrace, and perhaps send Java traces
//   directly to atrace in trace_event_binding.cc.

void TraceLog::StartATrace() {
  if (g_atrace_fd != -1)
    return;

  g_atrace_fd = open(kATraceMarkerFile, O_WRONLY);
  if (g_atrace_fd == -1) {
    PLOG(WARNING) << "Couldn't open " << kATraceMarkerFile;
    return;
  }
  TraceConfig trace_config;
  trace_config.SetTraceRecordMode(RECORD_CONTINUOUSLY);
  SetEnabled(trace_config, TraceLog::RECORDING_MODE);
}

void TraceLog::StopATrace() {
  if (g_atrace_fd == -1)
    return;

  close(g_atrace_fd);
  g_atrace_fd = -1;

  // TraceLog::Flush() requires the current thread to have a message loop, but
  // this thread called from Java may not have one, so flush in another thread.
  Thread end_chrome_tracing_thread("end_chrome_tracing");
  WaitableEvent complete_event(false, false);
  end_chrome_tracing_thread.Start();
  end_chrome_tracing_thread.task_runner()->PostTask(
      FROM_HERE, base::Bind(&EndChromeTracing, Unretained(this),
                            Unretained(&complete_event)));
  complete_event.Wait();
}

void TraceEvent::SendToATrace() {
  if (g_atrace_fd == -1)
    return;

  const char* category_group =
      TraceLog::GetCategoryGroupName(category_group_enabled_);

  switch (phase_) {
    case TRACE_EVENT_PHASE_BEGIN:
      WriteEvent('B', category_group, name_, id_,
                 arg_names_, arg_types_, arg_values_, convertable_values_,
                 flags_);
      break;

    case TRACE_EVENT_PHASE_COMPLETE:
      WriteEvent(duration_.ToInternalValue() == -1 ? 'B' : 'E',
                 category_group, name_, id_,
                 arg_names_, arg_types_, arg_values_, convertable_values_,
                 flags_);
      break;

    case TRACE_EVENT_PHASE_END:
      // Though a single 'E' is enough, here append pid, name and
      // category_group etc. So that unpaired events can be found easily.
      WriteEvent('E', category_group, name_, id_,
                 arg_names_, arg_types_, arg_values_, convertable_values_,
                 flags_);
      break;

    case TRACE_EVENT_PHASE_INSTANT:
      // Simulate an instance event with a pair of begin/end events.
      WriteEvent('B', category_group, name_, id_,
                 arg_names_, arg_types_, arg_values_, convertable_values_,
                 flags_);
      write(g_atrace_fd, "E", 1);
      break;

    case TRACE_EVENT_PHASE_COUNTER:
      for (int i = 0; i < kTraceMaxNumArgs && arg_names_[i]; ++i) {
        DCHECK(arg_types_[i] == TRACE_VALUE_TYPE_INT);
        std::string out = base::StringPrintf(
            "C|%d|%s-%s", getpid(), name_, arg_names_[i]);
        if (flags_ & TRACE_EVENT_FLAG_HAS_ID)
          StringAppendF(&out, "-%" PRIx64, static_cast<uint64>(id_));
        StringAppendF(&out, "|%d|%s",
                      static_cast<int>(arg_values_[i].as_int), category_group);
        write(g_atrace_fd, out.c_str(), out.size());
      }
      break;

    default:
      // Do nothing.
      break;
  }
}

void TraceLog::AddClockSyncMetadataEvent() {
  int atrace_fd = open(kATraceMarkerFile, O_WRONLY | O_APPEND);
  if (atrace_fd == -1) {
    PLOG(WARNING) << "Couldn't open " << kATraceMarkerFile;
    return;
  }

  // Android's kernel trace system has a trace_marker feature: this is a file on
  // debugfs that takes the written data and pushes it onto the trace
  // buffer. So, to establish clock sync, we write our monotonic clock into that
  // trace buffer.
  double now_in_seconds = (TraceTicks::Now() - TraceTicks()).InSecondsF();
  std::string marker = StringPrintf(
      "trace_event_clock_sync: parent_ts=%f\n", now_in_seconds);
  if (write(atrace_fd, marker.c_str(), marker.size()) == -1)
    PLOG(WARNING) << "Couldn't write to " << kATraceMarkerFile;
  close(atrace_fd);
}

}  // namespace trace_event
}  // namespace base
