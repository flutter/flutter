// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/trace_event/trace_event_win.h"

#include "base/logging.h"
#include "base/memory/singleton.h"
#include <initguid.h>  // NOLINT

namespace base {
namespace trace_event {

using base::win::EtwEventType;
using base::win::EtwMofEvent;

// {3DADA31D-19EF-4dc1-B345-037927193422}
const GUID kChromeTraceProviderName = {
    0x3dada31d, 0x19ef, 0x4dc1, 0xb3, 0x45, 0x3, 0x79, 0x27, 0x19, 0x34, 0x22 };

// {B967AE67-BB22-49d7-9406-55D91EE1D560}
const GUID kTraceEventClass32 = {
    0xb967ae67, 0xbb22, 0x49d7, 0x94, 0x6, 0x55, 0xd9, 0x1e, 0xe1, 0xd5, 0x60 };

// {97BE602D-2930-4ac3-8046-B6763B631DFE}
const GUID kTraceEventClass64 = {
    0x97be602d, 0x2930, 0x4ac3, 0x80, 0x46, 0xb6, 0x76, 0x3b, 0x63, 0x1d, 0xfe};


TraceEventETWProvider::TraceEventETWProvider() :
    EtwTraceProvider(kChromeTraceProviderName) {
  Register();
}

TraceEventETWProvider* TraceEventETWProvider::GetInstance() {
  return Singleton<TraceEventETWProvider,
      StaticMemorySingletonTraits<TraceEventETWProvider> >::get();
}

bool TraceEventETWProvider::StartTracing() {
  return true;
}

void TraceEventETWProvider::TraceEvent(const char* name,
                                       size_t name_len,
                                       char type,
                                       const void* id,
                                       const char* extra,
                                       size_t extra_len) {
  // Make sure we don't touch NULL.
  if (name == NULL)
    name = "";
  if (extra == NULL)
    extra = "";

  EtwEventType etw_type = 0;
  switch (type) {
    case TRACE_EVENT_PHASE_BEGIN:
      etw_type = kTraceEventTypeBegin;
      break;
    case TRACE_EVENT_PHASE_END:
      etw_type = kTraceEventTypeEnd;
      break;

    case TRACE_EVENT_PHASE_INSTANT:
      etw_type = kTraceEventTypeInstant;
      break;

    default:
      NOTREACHED() << "Unknown event type";
      etw_type = kTraceEventTypeInstant;
      break;
  }

  EtwMofEvent<5> event(kTraceEventClass32,
                       etw_type,
                       TRACE_LEVEL_INFORMATION);
  event.SetField(0, name_len + 1, name);
  event.SetField(1, sizeof(id), &id);
  event.SetField(2, extra_len + 1, extra);

  // These variables are declared here so that they are not out of scope when
  // the event is logged.
  DWORD depth;
  void* backtrace[32];

  // See whether we're to capture a backtrace.
  if (enable_flags() & CAPTURE_STACK_TRACE) {
    depth = CaptureStackBackTrace(0,
                                  arraysize(backtrace),
                                  backtrace,
                                  NULL);
    event.SetField(3, sizeof(depth), &depth);
    event.SetField(4, sizeof(backtrace[0]) * depth, backtrace);
  }

  // Trace the event.
  Log(event.get());
}

void TraceEventETWProvider::Trace(const char* name,
                                  size_t name_len,
                                  char type,
                                  const void* id,
                                  const char* extra,
                                  size_t extra_len) {
  TraceEventETWProvider* provider = TraceEventETWProvider::GetInstance();
  if (provider && provider->IsTracing()) {
    // Compute the name & extra lengths if not supplied already.
    if (name_len == kUseStrlen)
      name_len = (name == NULL) ? 0 : strlen(name);
    if (extra_len == kUseStrlen)
      extra_len = (extra == NULL) ? 0 : strlen(extra);

    provider->TraceEvent(name, name_len, type, id, extra, extra_len);
  }
}

void TraceEventETWProvider::Resurrect() {
  StaticMemorySingletonTraits<TraceEventETWProvider>::Resurrect();
}

}  // namespace trace_event
}  // namespace base
