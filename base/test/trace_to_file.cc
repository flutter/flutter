// Copyright (c) 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/trace_to_file.h"

#include "base/base_switches.h"
#include "base/bind.h"
#include "base/command_line.h"
#include "base/files/file_util.h"
#include "base/run_loop.h"
#include "base/trace_event/trace_event_impl.h"

namespace base {
namespace test {

TraceToFile::TraceToFile() : started_(false) {
}

TraceToFile::~TraceToFile() {
  EndTracingIfNeeded();
}

void TraceToFile::BeginTracingFromCommandLineOptions() {
  DCHECK(CommandLine::InitializedForCurrentProcess());
  DCHECK(!started_);

  if (!CommandLine::ForCurrentProcess()->HasSwitch(switches::kTraceToFile))
    return;

  // Empty filter (i.e. just --trace-to-file) turns into default categories in
  // TraceEventImpl
  std::string filter = CommandLine::ForCurrentProcess()->GetSwitchValueASCII(
      switches::kTraceToFile);

  FilePath path;
  if (CommandLine::ForCurrentProcess()->HasSwitch(switches::kTraceToFileName)) {
    path = FilePath(CommandLine::ForCurrentProcess()
                        ->GetSwitchValuePath(switches::kTraceToFileName));
  } else {
    path = FilePath(FILE_PATH_LITERAL("trace.json"));
  }

  BeginTracing(path, filter);
}

void TraceToFile::BeginTracing(const FilePath& path,
                               const std::string& categories) {
  DCHECK(!started_);
  started_ = true;
  path_ = path;
  WriteFileHeader();

  trace_event::TraceLog::GetInstance()->SetEnabled(
      trace_event::TraceConfig(categories, trace_event::RECORD_UNTIL_FULL),
      trace_event::TraceLog::RECORDING_MODE);
}

void TraceToFile::WriteFileHeader() {
  const char str[] = "{\"traceEvents\": [";
  WriteFile(path_, str, static_cast<int>(strlen(str)));
}

void TraceToFile::AppendFileFooter() {
  const char str[] = "]}";
  AppendToFile(path_, str, static_cast<int>(strlen(str)));
}

void TraceToFile::TraceOutputCallback(const std::string& data) {
  bool ret = AppendToFile(path_, data.c_str(), static_cast<int>(data.size()));
  DCHECK(ret);
}

static void OnTraceDataCollected(
    Closure quit_closure,
    trace_event::TraceResultBuffer* buffer,
    const scoped_refptr<RefCountedString>& json_events_str,
    bool has_more_events) {
  buffer->AddFragment(json_events_str->data());
  if (!has_more_events)
    quit_closure.Run();
}

void TraceToFile::EndTracingIfNeeded() {
  if (!started_)
    return;
  started_ = false;

  trace_event::TraceLog::GetInstance()->SetDisabled();

  trace_event::TraceResultBuffer buffer;
  buffer.SetOutputCallback(
      Bind(&TraceToFile::TraceOutputCallback, Unretained(this)));

  RunLoop run_loop;
  trace_event::TraceLog::GetInstance()->Flush(
      Bind(&OnTraceDataCollected, run_loop.QuitClosure(), Unretained(&buffer)));
  run_loop.Run();

  AppendFileFooter();
}

}  // namespace test
}  // namespace base
