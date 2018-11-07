// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/trace_event.h"

#include "third_party/dart/runtime/include/dart_tools_api.h"

namespace fml {
namespace tracing {

void TraceCounter(TraceArg category_group, TraceArg name, TraceIDArg count) {
  auto count_string = std::to_string(count);
  const char* arg_names[] = {name};
  const char* arg_values[] = {count_string.c_str()};
  Dart_TimelineEvent(name,                         // label
                     Dart_TimelineGetMicros(),     // timestamp0
                     0,                            // timestamp1_or_async_id
                     Dart_Timeline_Event_Counter,  // event type
                     1,                            // argument_count
                     arg_names,                    // argument_names
                     arg_values                    // argument_values
  );
}

void TraceEvent0(TraceArg category_group, TraceArg name) {
  Dart_TimelineEvent(name,                       // label
                     Dart_TimelineGetMicros(),   // timestamp0
                     0,                          // timestamp1_or_async_id
                     Dart_Timeline_Event_Begin,  // event type
                     0,                          // argument_count
                     nullptr,                    // argument_names
                     nullptr                     // argument_values
  );
}

void TraceEvent1(TraceArg category_group,
                 TraceArg name,
                 TraceArg arg1_name,
                 TraceArg arg1_val) {
  const char* arg_names[] = {arg1_name};
  const char* arg_values[] = {arg1_val};
  Dart_TimelineEvent(name,                       // label
                     Dart_TimelineGetMicros(),   // timestamp0
                     0,                          // timestamp1_or_async_id
                     Dart_Timeline_Event_Begin,  // event type
                     1,                          // argument_count
                     arg_names,                  // argument_names
                     arg_values                  // argument_values
  );
}

void TraceEvent2(TraceArg category_group,
                 TraceArg name,
                 TraceArg arg1_name,
                 TraceArg arg1_val,
                 TraceArg arg2_name,
                 TraceArg arg2_val) {
  const char* arg_names[] = {arg1_name, arg2_name};
  const char* arg_values[] = {arg1_val, arg2_val};
  Dart_TimelineEvent(name,                       // label
                     Dart_TimelineGetMicros(),   // timestamp0
                     0,                          // timestamp1_or_async_id
                     Dart_Timeline_Event_Begin,  // event type
                     2,                          // argument_count
                     arg_names,                  // argument_names
                     arg_values                  // argument_values
  );
}

void TraceEventEnd(TraceArg name) {
  Dart_TimelineEvent(name,                      // label
                     Dart_TimelineGetMicros(),  // timestamp0
                     0,                         // timestamp1_or_async_id
                     Dart_Timeline_Event_End,   // event type
                     0,                         // argument_count
                     nullptr,                   // argument_names
                     nullptr                    // argument_values
  );
}

void TraceEventAsyncBegin0(TraceArg category_group,
                           TraceArg name,
                           TraceIDArg id) {
  Dart_TimelineEvent(name,                             // label
                     Dart_TimelineGetMicros(),         // timestamp0
                     id,                               // timestamp1_or_async_id
                     Dart_Timeline_Event_Async_Begin,  // event type
                     0,                                // argument_count
                     nullptr,                          // argument_names
                     nullptr                           // argument_values
  );
}

void TraceEventAsyncEnd0(TraceArg category_group,
                         TraceArg name,
                         TraceIDArg id) {
  Dart_TimelineEvent(name,                           // label
                     Dart_TimelineGetMicros(),       // timestamp0
                     id,                             // timestamp1_or_async_id
                     Dart_Timeline_Event_Async_End,  // event type
                     0,                              // argument_count
                     nullptr,                        // argument_names
                     nullptr                         // argument_values
  );
}

void TraceEventAsyncBegin1(TraceArg category_group,
                           TraceArg name,
                           TraceIDArg id,
                           TraceArg arg1_name,
                           TraceArg arg1_val) {
  const char* arg_names[] = {arg1_name};
  const char* arg_values[] = {arg1_val};
  Dart_TimelineEvent(name,                             // label
                     Dart_TimelineGetMicros(),         // timestamp0
                     id,                               // timestamp1_or_async_id
                     Dart_Timeline_Event_Async_Begin,  // event type
                     1,                                // argument_count
                     arg_names,                        // argument_names
                     arg_values                        // argument_values
  );
}

void TraceEventAsyncEnd1(TraceArg category_group,
                         TraceArg name,
                         TraceIDArg id,
                         TraceArg arg1_name,
                         TraceArg arg1_val) {
  const char* arg_names[] = {arg1_name};
  const char* arg_values[] = {arg1_val};
  Dart_TimelineEvent(name,                           // label
                     Dart_TimelineGetMicros(),       // timestamp0
                     id,                             // timestamp1_or_async_id
                     Dart_Timeline_Event_Async_End,  // event type
                     1,                              // argument_count
                     arg_names,                      // argument_names
                     arg_values                      // argument_values
  );
}

void TraceEventInstant0(TraceArg category_group, TraceArg name) {
  Dart_TimelineEvent(name,                         // label
                     Dart_TimelineGetMicros(),     // timestamp0
                     0,                            // timestamp1_or_async_id
                     Dart_Timeline_Event_Instant,  // event type
                     0,                            // argument_count
                     nullptr,                      // argument_names
                     nullptr                       // argument_values
  );
}

void TraceEventFlowBegin0(TraceArg category_group,
                          TraceArg name,
                          TraceIDArg id) {
  Dart_TimelineEvent(name,                            // label
                     Dart_TimelineGetMicros(),        // timestamp0
                     id,                              // timestamp1_or_async_id
                     Dart_Timeline_Event_Flow_Begin,  // event type
                     0,                               // argument_count
                     nullptr,                         // argument_names
                     nullptr                          // argument_values
  );
}

void TraceEventFlowStep0(TraceArg category_group,
                         TraceArg name,
                         TraceIDArg id) {
  Dart_TimelineEvent(name,                           // label
                     Dart_TimelineGetMicros(),       // timestamp0
                     id,                             // timestamp1_or_async_id
                     Dart_Timeline_Event_Flow_Step,  // event type
                     0,                              // argument_count
                     nullptr,                        // argument_names
                     nullptr                         // argument_values
  );
}

void TraceEventFlowEnd0(TraceArg category_group, TraceArg name, TraceIDArg id) {
  Dart_TimelineEvent(name,                          // label
                     Dart_TimelineGetMicros(),      // timestamp0
                     id,                            // timestamp1_or_async_id
                     Dart_Timeline_Event_Flow_End,  // event type
                     0,                             // argument_count
                     nullptr,                       // argument_names
                     nullptr                        // argument_values
  );
}

}  // namespace tracing
}  // namespace fml
