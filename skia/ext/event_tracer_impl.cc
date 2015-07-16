// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/trace_event/trace_event.h"
#include "skia/ext/event_tracer_impl.h"
#include "third_party/skia/include/utils/SkEventTracer.h"

namespace skia {

class SkChromiumEventTracer: public SkEventTracer {
  const uint8_t* getCategoryGroupEnabled(const char* name) override;
  const char* getCategoryGroupName(const uint8_t* categoryEnabledFlag) override;
  SkEventTracer::Handle addTraceEvent(char phase,
                                      const uint8_t* categoryEnabledFlag,
                                      const char* name,
                                      uint64_t id,
                                      int32_t numArgs,
                                      const char** argNames,
                                      const uint8_t* argTypes,
                                      const uint64_t* argValues,
                                      uint8_t flags) override;
  void updateTraceEventDuration(const uint8_t* categoryEnabledFlag,
                                const char* name,
                                SkEventTracer::Handle handle) override;
};

const uint8_t*
  SkChromiumEventTracer::getCategoryGroupEnabled(const char* name) {
    return TRACE_EVENT_API_GET_CATEGORY_GROUP_ENABLED(name);
}

const char* SkChromiumEventTracer::getCategoryGroupName(
      const uint8_t* categoryEnabledFlag) {
  return base::trace_event::TraceLog::GetCategoryGroupName(categoryEnabledFlag);
}

SkEventTracer::Handle
    SkChromiumEventTracer::addTraceEvent(char phase,
                                         const uint8_t* categoryEnabledFlag,
                                         const char* name,
                                         uint64_t id,
                                         int32_t numArgs,
                                         const char** argNames,
                                         const uint8_t* argTypes,
                                         const uint64_t* argValues,
                                         uint8_t flags) {
  base::trace_event::TraceEventHandle handle = TRACE_EVENT_API_ADD_TRACE_EVENT(
      phase, categoryEnabledFlag, name, id, numArgs, argNames, argTypes,
      (const long long unsigned int*)argValues, NULL, flags);
      SkEventTracer::Handle result;
      memcpy(&result, &handle, sizeof(result));
      return result;
}

void
    SkChromiumEventTracer::updateTraceEventDuration(
        const uint8_t* categoryEnabledFlag,
        const char *name,
        SkEventTracer::Handle handle) {
  base::trace_event::TraceEventHandle traceEventHandle;
      memcpy(&traceEventHandle, &handle, sizeof(handle));
      TRACE_EVENT_API_UPDATE_TRACE_EVENT_DURATION(
          categoryEnabledFlag, name, traceEventHandle);
}

}  // namespace skia


void InitSkiaEventTracer() {
  // Initialize the binding to Skia's tracing events. Skia will
  // take ownership of and clean up the memory allocated here.
  SkEventTracer::SetInstance(new skia::SkChromiumEventTracer());
}
