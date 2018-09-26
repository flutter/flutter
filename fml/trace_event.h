// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_TRACE_EVENT_H_
#define FLUTTER_FML_TRACE_EVENT_H_

#include "flutter/fml/build_config.h"

#if defined(OS_FUCHSIA)

// Forward to the system tracing mechanism on Fuchsia.

#include <trace/event.h>

#define FML_TRACE_COUNTER(category_group, name, count) \
  TRACE_COUNTER(category_group, name, 0u, name, count)
#define TRACE_EVENT0(a, b) TRACE_DURATION(a, b)
#define TRACE_EVENT1(a, b, c, d) TRACE_DURATION(a, b, c, d)
#define TRACE_EVENT2(a, b, c, d, e, f) TRACE_DURATION(a, b, c, d, e, f)
#define TRACE_EVENT_ASYNC_BEGIN0(a, b, c) TRACE_ASYNC_BEGIN(a, b, c)
#define TRACE_EVENT_ASYNC_END0(a, b, c) TRACE_ASYNC_END(a, b, c)
#define TRACE_EVENT_ASYNC_BEGIN1(a, b, c, d, e) TRACE_ASYNC_BEGIN(a, b, c, d, e)
#define TRACE_EVENT_ASYNC_END1(a, b, c, d, e) TRACE_ASYNC_END(a, b, c, d, e)

#endif  // defined(OS_FUCHSIA)

#include <cstddef>
#include <cstdint>
#include <string>

#include "flutter/fml/macros.h"

#if !defined(OS_FUCHSIA)

#ifndef TRACE_EVENT_HIDE_MACROS

#define __FML__TOKEN_CAT__(x, y) x##y
#define __FML__TOKEN_CAT__2(x, y) __FML__TOKEN_CAT__(x, y)
#define __FML__AUTO_TRACE_END(name)                                  \
  ::fml::tracing::ScopedInstantEnd __FML__TOKEN_CAT__2(__trace_end_, \
                                                       __LINE__)(name);

// This macro has the FML_ prefix so that it does not collide with the macros
// from trace/event.h on Fuchsia.
//
// TODO(chinmaygarde): All macros here should have the FML prefix.
#define FML_TRACE_COUNTER(category_group, name, count) \
  ::fml::tracing::TraceCounter(category_group, name, count);

#define TRACE_EVENT0(category_group, name)           \
  ::fml::tracing::TraceEvent0(category_group, name); \
  __FML__AUTO_TRACE_END(name)

#define TRACE_EVENT1(category_group, name, arg1_name, arg1_val)           \
  ::fml::tracing::TraceEvent1(category_group, name, arg1_name, arg1_val); \
  __FML__AUTO_TRACE_END(name)

#define TRACE_EVENT2(category_group, name, arg1_name, arg1_val, arg2_name, \
                     arg2_val)                                             \
  ::fml::tracing::TraceEvent2(category_group, name, arg1_name, arg1_val,   \
                              arg2_name, arg2_val);                        \
  __FML__AUTO_TRACE_END(name)

#define TRACE_EVENT_ASYNC_BEGIN0(category_group, name, id) \
  ::fml::tracing::TraceEventAsyncBegin0(category_group, name, id);

#define TRACE_EVENT_ASYNC_END0(category_group, name, id) \
  ::fml::tracing::TraceEventAsyncEnd0(category_group, name, id);

#define TRACE_EVENT_ASYNC_BEGIN1(category_group, name, id, arg1_name,        \
                                 arg1_val)                                   \
  ::fml::tracing::TraceEventAsyncBegin1(category_group, name, id, arg1_name, \
                                        arg1_val);

#define TRACE_EVENT_ASYNC_END1(category_group, name, id, arg1_name, arg1_val) \
  ::fml::tracing::TraceEventAsyncEnd1(category_group, name, id, arg1_name,    \
                                      arg1_val);

#define TRACE_EVENT_INSTANT0(category_group, name) \
  ::fml::tracing::TraceEventInstant0(category_group, name);

#define TRACE_FLOW_BEGIN(category, name, id) \
  ::fml::tracing::TraceEventFlowBegin0(category, name, id);

#define TRACE_FLOW_STEP(category, name, id) \
  ::fml::tracing::TraceEventFlowStep0(category, name, id);

#define TRACE_FLOW_END(category, name, id) \
  ::fml::tracing::TraceEventFlowEnd0(category, name, id);

#endif  // TRACE_EVENT_HIDE_MACROS

#endif  // !defined(OS_FUCHSIA)

namespace fml {
namespace tracing {

using TraceArg = const char*;
using TraceIDArg = int64_t;

void TraceCounter(TraceArg category_group, TraceArg name, TraceIDArg count);

void TraceEvent0(TraceArg category_group, TraceArg name);

void TraceEvent1(TraceArg category_group,
                 TraceArg name,
                 TraceArg arg1_name,
                 TraceArg arg1_val);

void TraceEvent2(TraceArg category_group,
                 TraceArg name,
                 TraceArg arg1_name,
                 TraceArg arg1_val,
                 TraceArg arg2_name,
                 TraceArg arg2_val);

void TraceEventEnd(TraceArg name);

void TraceEventAsyncBegin0(TraceArg category_group,
                           TraceArg name,
                           TraceIDArg id);

void TraceEventAsyncEnd0(TraceArg category_group, TraceArg name, TraceIDArg id);

void TraceEventAsyncBegin1(TraceArg category_group,
                           TraceArg name,
                           TraceIDArg id,
                           TraceArg arg1_name,
                           TraceArg arg1_val);

void TraceEventAsyncEnd1(TraceArg category_group,
                         TraceArg name,
                         TraceIDArg id,
                         TraceArg arg1_name,
                         TraceArg arg1_val);

void TraceEventInstant0(TraceArg category_group, TraceArg name);

void TraceEventFlowBegin0(TraceArg category_group,
                          TraceArg name,
                          TraceIDArg id);

void TraceEventFlowStep0(TraceArg category_group, TraceArg name, TraceIDArg id);

void TraceEventFlowEnd0(TraceArg category_group, TraceArg name, TraceIDArg id);

class ScopedInstantEnd {
 public:
  ScopedInstantEnd(std::string str) : label_(std::move(str)) {}

  ~ScopedInstantEnd() { TraceEventEnd(label_.c_str()); }

 private:
  const std::string label_;

  FML_DISALLOW_COPY_AND_ASSIGN(ScopedInstantEnd);
};

}  // namespace tracing
}  // namespace fml

#endif  // FLUTTER_FML_TRACE_EVENT_H_
