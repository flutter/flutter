// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file contains the Windows-specific exporting to ETW.
#ifndef BASE_TRACE_EVENT_TRACE_EVENT_ETW_EXPORT_WIN_H_
#define BASE_TRACE_EVENT_TRACE_EVENT_ETW_EXPORT_WIN_H_

#include "base/base_export.h"
#include "base/trace_event/trace_event_impl.h"

// Fwd.
template <typename Type>
struct StaticMemorySingletonTraits;

namespace base {
namespace trace_event {

class BASE_EXPORT TraceEventETWExport {
 public:
  ~TraceEventETWExport();

  // Retrieves the singleton.
  // Note that this may return NULL post-AtExit processing.
  static TraceEventETWExport* GetInstance();

  // Enables/disables exporting of events to ETW. If disabled,
  // AddEvent and AddCustomEvent will simply return when called.
  static void EnableETWExport();
  static void DisableETWExport();

  static bool isETWExportEnabled() {
    return (GetInstance() && GetInstance()->ETWExportEnabled_);
  }

  // Exports an event to ETW. This is mainly used in
  // TraceLog::AddTraceEventWithThreadIdAndTimestamp to export internal events.
  static void AddEvent(
      char phase,
      const unsigned char* category_group_enabled,
      const char* name,
      unsigned long long id,
      int num_args,
      const char** arg_names,
      const unsigned char* arg_types,
      const unsigned long long* arg_values,
      const scoped_refptr<ConvertableToTraceFormat>* convertable_values);

  // Exports an event to ETW. This should be used when exporting an event only
  // to ETW. Supports three arguments to be passed to ETW.
  // TODO(georgesak): Allow different providers.
  static void AddCustomEvent(const char* name,
                             char const* phase,
                             const char* arg_name_1,
                             const char* arg_value_1,
                             const char* arg_name_2,
                             const char* arg_value_2,
                             const char* arg_name_3,
                             const char* arg_value_3);

  void Resurrect();

 private:
  bool ETWExportEnabled_;
  // Ensure only the provider can construct us.
  friend struct StaticMemorySingletonTraits<TraceEventETWExport>;
  TraceEventETWExport();

  DISALLOW_COPY_AND_ASSIGN(TraceEventETWExport);
};

}  // namespace trace_event
}  // namespace base

#endif  // BASE_TRACE_EVENT_TRACE_EVENT_ETW_EXPORT_WIN_H_
