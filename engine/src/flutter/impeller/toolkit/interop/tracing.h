// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_TOOLKIT_INTEROP_TRACING_H_
#define FLUTTER_IMPELLER_TOOLKIT_INTEROP_TRACING_H_

#include <cstddef>
#include <cstdint>
#include <string>
#include <vector>

#include "flutter/fml/trace_event.h"

namespace impeller::interop {

//------------------------------------------------------------------------------
/// @brief      Route the FML timeline events (`TRACE_EVENT0`, etc.) emitted by
///             Impeller to the platform's system tracer.
///
///             Unlike the Flutter engine, users of the standalone Impeller SDK
///             don't have a Dart VM to install an FML timeline event handler.
///             Without one, all trace events emitted by Impeller are dropped.
///
///             On Android, this installs a handler that forwards events to
///             `ATrace` (via `libandroid.so`) so they show up in Perfetto and
///             Systrace. Native processes whose linker namespace doesn't
///             expose `libandroid.so` (e.g. binaries on the product or vendor
///             partitions) fall back to writing the same records to the kernel
///             `trace_marker` file directly. Either way, the handler does no
///             work unless a trace is actively being recorded.
///
///             On other platforms, this is a no-op.
///
///             The handler is installed at most once per process, and only if
///             no other handler (e.g. the Dart VM's) has been installed.
///
void SetupPlatformTracingIfNecessary();

//------------------------------------------------------------------------------
/// @brief      A system tracer that FML timeline events can be forwarded to.
///             This is the subset of the Android `ATrace` API that is needed.
///
class SystemTracer {
 public:
  virtual ~SystemTracer();

  //----------------------------------------------------------------------------
  /// @brief      If a trace is being recorded. Must be cheap since it is
  ///             checked for every event.
  ///
  virtual bool IsEnabled() = 0;

  virtual void BeginSection(const char* name) = 0;

  virtual void EndSection() = 0;

  virtual void BeginAsyncSection(const char* name, int32_t cookie) = 0;

  virtual void EndAsyncSection(const char* name, int32_t cookie) = 0;

  virtual void SetCounter(const char* name, int64_t value) = 0;
};

//------------------------------------------------------------------------------
/// @brief      Forward a single FML timeline event to the given tracer. The
///             arguments are those of `fml::tracing::TimelineEventHandler`.
///
///             Does nothing if the tracer is not enabled. Sections that are
///             open on the calling thread when tracing starts or stops are
///             handled such that begin and end events stay balanced.
///
void ForwardTimelineEventToSystemTracer(SystemTracer& tracer,
                                        const char* label,
                                        int64_t timestamp1_or_async_id,
                                        Dart_Timeline_Event_Type type,
                                        intptr_t argument_count,
                                        const char** argument_names,
                                        const char** argument_values);

//------------------------------------------------------------------------------
/// @brief      Formats a record in the format expected by the kernel
///             `trace_marker` file (and parsed by Perfetto and Systrace). For
///             example `B|<pid>|<name>`, `E|<pid>`, `S|<pid>|<name>|<cookie>`,
///             `F|<pid>|<name>|<cookie>`, or `C|<pid>|<name>|<value>`.
///
///             Pipe and newline characters in the name would corrupt the
///             record and are replaced with spaces. Long names are truncated.
///
/// @param[in]  buffer       The buffer to write the record to.
/// @param[in]  buffer_size  The size of the buffer.
/// @param[in]  phase        One of 'B', 'E', 'S', 'F', or 'C'.
/// @param[in]  pid          The process ID.
/// @param[in]  name         The name of the section or counter. May be null for
///                          'E' records.
/// @param[in]  value        The cookie or counter value for 'S', 'F', and 'C'
///                          records. Ignored otherwise.
///
/// @return     The length of the record (excluding the terminating NUL), or 0
///             if the buffer is too small for the fixed parts of the record.
///
size_t FormatTraceMarkerRecord(char* buffer,
                               size_t buffer_size,
                               char phase,
                               int pid,
                               const char* name,
                               int64_t value);

//------------------------------------------------------------------------------
/// @brief      If the `trace_marker` fallback should record events for a
///             process. Mirrors the logic `libcutils` uses for
///             `ATRACE_TAG_GRAPHICS` and `ATRACE_TAG_APP`.
///
/// @param[in]  enable_flags  The value of `debug.atrace.tags.enableflags`.
/// @param[in]  traced_apps   The values of `debug.atrace.app_<N>`. These may
///                           contain `*` and `?` wildcards.
/// @param[in]  cmdline       The process name (the first entry of
///                           `/proc/self/cmdline`).
///
bool ShouldTraceProcess(const std::string& enable_flags,
                        const std::vector<std::string>& traced_apps,
                        const std::string& cmdline);

}  // namespace impeller::interop

#endif  // FLUTTER_IMPELLER_TOOLKIT_INTEROP_TRACING_H_
