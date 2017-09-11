// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/skia_event_tracer_impl.h"

#define TRACE_EVENT_HIDE_MACROS
#include "flutter/fml/trace_event.h"

#include <vector>

#include "lib/fxl/logging.h"
#include "third_party/skia/include/utils/SkEventTracer.h"
#include "third_party/skia/src/core/SkTraceEventCommon.h"

namespace skia {

class FlutterEventTracer : public SkEventTracer {
 public:
  static constexpr const char* kSkiaTag = "skia";

  FlutterEventTracer() = default;

  SkEventTracer::Handle addTraceEvent(char phase,
                                      const uint8_t* category_enabled_flag,
                                      const char* name,
                                      uint64_t id,
                                      int num_args,
                                      const char** p_arg_names,
                                      const uint8_t* p_arg_types,
                                      const uint64_t* p_arg_values,
                                      uint8_t flags) override {
    switch (phase) {
      case TRACE_EVENT_PHASE_BEGIN:
      case TRACE_EVENT_PHASE_COMPLETE:
        fml::tracing::TraceEvent0(kSkiaTag, name);
        break;
      case TRACE_EVENT_PHASE_END:
        fml::tracing::TraceEventEnd(name);
        break;
      case TRACE_EVENT_PHASE_INSTANT:
        fml::tracing::TraceEventInstant0(kSkiaTag, name);
        break;
      case TRACE_EVENT_PHASE_ASYNC_BEGIN:
        fml::tracing::TraceEventAsyncBegin0(kSkiaTag, name, id);
        break;
      case TRACE_EVENT_PHASE_ASYNC_END:
        fml::tracing::TraceEventAsyncEnd0(kSkiaTag, name, id);
        break;
      default:
        break;
    }
    return 0;
  }

  void updateTraceEventDuration(const uint8_t* category_enabled_flag,
                                const char* name,
                                SkEventTracer::Handle handle) override {
    // This is only ever called from a scoped trace event so we will just end
    // the section.
    fml::tracing::TraceEventEnd(name);
  }

  const uint8_t* getCategoryGroupEnabled(const char* name) override {
    static const uint8_t kYes = 1;
    return &kYes;
  }

  const char* getCategoryGroupName(
      const uint8_t* category_enabled_flag) override {
    return kSkiaTag;
  }

 private:
  FXL_DISALLOW_COPY_AND_ASSIGN(FlutterEventTracer);
};

}  // namespace skia

void InitSkiaEventTracer() {
  // Initialize the binding to Skia's tracing events. Skia will
  // take ownership of and clean up the memory allocated here.
  SkEventTracer::SetInstance(new skia::FlutterEventTracer());
}
