// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/toolkit/interop/tracing.h"

#include <cinttypes>
#include <cstdio>
#include <cstdlib>
#include <cstring>

#include "flutter/fml/build_config.h"

#if FML_OS_ANDROID
#include <fcntl.h>
#include <sys/system_properties.h>
#include <unistd.h>

#include <atomic>
#include <memory>
#include <mutex>

#include "flutter/fml/native_library.h"
#include "impeller/toolkit/android/proc_table.h"
#endif  // FML_OS_ANDROID

namespace impeller::interop {

namespace {

std::string MakeSectionName(const char* label,
                            intptr_t argument_count,
                            const char** argument_names,
                            const char** argument_values) {
  std::string name(label);
  name.append("(");
  for (intptr_t i = 0; i < argument_count; i++) {
    if (i != 0) {
      name.append(", ");
    }
    name.append(argument_names[i] ? argument_names[i] : "");
    name.append("=");
    name.append(argument_values[i] ? argument_values[i] : "");
  }
  name.append(")");
  return name;
}

void BeginSection(SystemTracer& tracer,
                  const char* label,
                  intptr_t argument_count,
                  const char** argument_names,
                  const char** argument_values) {
  if (argument_count == 0) {
    tracer.BeginSection(label);
  } else {
    tracer.BeginSection(
        MakeSectionName(label, argument_count, argument_names, argument_values)
            .c_str());
  }
}

//------------------------------------------------------------------------------
/// Tracks which of the (possibly nested) sections begun on the current thread
/// were forwarded to the tracer. Since tracing can start or stop at any time,
/// this keeps the forwarded begin and end events balanced. Otherwise, a section
/// whose begin event was skipped could end an unrelated enclosing section of
/// the host when tracing starts in the middle of it.
///
class SectionStack {
 public:
  /// Returns if the begin event of the section should be forwarded.
  bool Push(bool enabled) {
    const uint32_t depth = depth_++;
    if (depth >= kMaxDepth) {
      // Too deeply nested. Drop both the begin and end events.
      return false;
    }
    const uint64_t bit = uint64_t{1} << depth;
    forwarded_ = enabled ? (forwarded_ | bit) : (forwarded_ & ~bit);
    return enabled;
  }

  /// Returns if the end event of the section should be forwarded.
  bool Pop() {
    if (depth_ == 0) {
      // The section began before the handler was installed.
      return false;
    }
    const uint32_t depth = --depth_;
    if (depth >= kMaxDepth) {
      return false;
    }
    return forwarded_ & (uint64_t{1} << depth);
  }

 private:
  static constexpr uint32_t kMaxDepth = 64u;
  uint64_t forwarded_ = 0;
  uint32_t depth_ = 0;
};

thread_local SectionStack tSectionStack;

// Like `fnmatch(pattern, text, FNM_NOESCAPE)` but only supports the `*` and `?`
// wildcards.
bool MatchesGlob(const char* pattern, const char* text) {
  const char* star = nullptr;
  const char* star_text = nullptr;
  while (*text != '\0') {
    if (*pattern == '*') {
      star = pattern++;
      star_text = text;
    } else if (*pattern == '?' || *pattern == *text) {
      pattern++;
      text++;
    } else if (star != nullptr) {
      // Backtrack and let the last star consume one more character.
      pattern = star + 1;
      text = ++star_text;
    } else {
      return false;
    }
  }
  while (*pattern == '*') {
    pattern++;
  }
  return *pattern == '\0';
}

}  // namespace

SystemTracer::~SystemTracer() = default;

void ForwardTimelineEventToSystemTracer(SystemTracer& tracer,
                                        const char* label,
                                        int64_t timestamp1_or_async_id,
                                        Dart_Timeline_Event_Type type,
                                        intptr_t argument_count,
                                        const char** argument_names,
                                        const char** argument_values) {
  // Sections need to stay balanced even if tracing is started or stopped while
  // they are open.
  if (type == Dart_Timeline_Event_Begin) {
    if (tSectionStack.Push(tracer.IsEnabled())) {
      BeginSection(tracer, label, argument_count, argument_names,
                   argument_values);
    }
    return;
  }
  if (type == Dart_Timeline_Event_End) {
    if (tSectionStack.Pop()) {
      tracer.EndSection();
    }
    return;
  }

  // Tracing is strictly on-demand. Do no work unless a trace is being recorded.
  if (!tracer.IsEnabled()) {
    return;
  }

  switch (type) {
    case Dart_Timeline_Event_Instant:
      // There are no instant events in ATrace. Use a zero length section.
      BeginSection(tracer, label, argument_count, argument_names,
                   argument_values);
      tracer.EndSection();
      break;
    case Dart_Timeline_Event_Async_Begin:
      tracer.BeginAsyncSection(label,
                               static_cast<int32_t>(timestamp1_or_async_id));
      break;
    case Dart_Timeline_Event_Async_End:
      tracer.EndAsyncSection(label,
                             static_cast<int32_t>(timestamp1_or_async_id));
      break;
    case Dart_Timeline_Event_Counter:
      for (intptr_t i = 0; i < argument_count; i++) {
        if (!argument_values[i]) {
          continue;
        }
        const int64_t value = std::strtoll(argument_values[i], nullptr, 10);
        if (argument_count == 1 || !argument_names[i]) {
          tracer.SetCounter(label, value);
        } else {
          tracer.SetCounter(
              (std::string(label) + " " + argument_names[i]).c_str(), value);
        }
      }
      break;
    default:
      // Durations, async instants, and flows have no ATrace equivalent.
      break;
  }
}

size_t FormatTraceMarkerRecord(char* buffer,
                               size_t buffer_size,
                               char phase,
                               int pid,
                               const char* name,
                               int64_t value) {
  if (buffer == nullptr || buffer_size == 0) {
    return 0;
  }
  const int prefix_length =
      std::snprintf(buffer, buffer_size, "%c|%d", phase, pid);
  if (prefix_length < 0 || static_cast<size_t>(prefix_length) >= buffer_size) {
    buffer[0] = '\0';
    return 0;
  }
  size_t length = static_cast<size_t>(prefix_length);
  if (phase == 'E') {
    return length;
  }

  char suffix[32] = {};
  size_t suffix_length = 0;
  if (phase == 'S' || phase == 'F' || phase == 'C') {
    suffix_length = static_cast<size_t>(
        std::snprintf(suffix, sizeof(suffix), "|%" PRId64, value));
  }

  // The separator, the suffix, and the terminating NUL must fit.
  if (length + 1u + suffix_length + 1u > buffer_size) {
    buffer[0] = '\0';
    return 0;
  }
  buffer[length++] = '|';

  const size_t name_end = buffer_size - suffix_length - 1u;
  for (size_t i = 0; name != nullptr && name[i] != '\0' && length < name_end;
       i++) {
    const char c = name[i];
    // Pipes delimit fields and newlines delimit records.
    buffer[length++] = (c == '|' || c == '\n' || c == '\r') ? ' ' : c;
  }

  std::memcpy(buffer + length, suffix, suffix_length);
  length += suffix_length;
  buffer[length] = '\0';
  return length;
}

bool ShouldTraceProcess(const std::string& enable_flags,
                        const std::vector<std::string>& traced_apps,
                        const std::string& cmdline) {
  // From `<cutils/trace.h>`.
  constexpr uint64_t kATraceTagGraphics = 1ull << 1;

  char* end = nullptr;
  const uint64_t tags = std::strtoull(enable_flags.c_str(), &end, 0);
  if (!enable_flags.empty() && *end == '\0' && (tags & kATraceTagGraphics)) {
    return true;
  }

  for (const auto& app : traced_apps) {
    if (MatchesGlob(app.c_str(), cmdline.c_str())) {
      return true;
    }
  }
  return false;
}

#if FML_OS_ANDROID

namespace {

//------------------------------------------------------------------------------
/// Forwards events to `ATrace_*` in `libandroid.so`.
///
class ATraceSystemTracer final : public SystemTracer {
 public:
  static std::unique_ptr<ATraceSystemTracer> Create() {
    // Avoid the validation errors logged by the proc table if `libandroid.so`
    // is not available in this linker namespace.
    if (!fml::NativeLibrary::Create("libandroid.so")) {
      return nullptr;
    }
    const auto& procs = android::GetProcTable();
    if (!procs.ATrace_isEnabled || !procs.ATrace_beginSection ||
        !procs.ATrace_endSection) {
      return nullptr;
    }
    return std::unique_ptr<ATraceSystemTracer>(new ATraceSystemTracer(procs));
  }

  // |SystemTracer|
  bool IsEnabled() override { return procs_.ATrace_isEnabled(); }

  // |SystemTracer|
  void BeginSection(const char* name) override {
    procs_.ATrace_beginSection(name);
  }

  // |SystemTracer|
  void EndSection() override { procs_.ATrace_endSection(); }

  // |SystemTracer|
  void BeginAsyncSection(const char* name, int32_t cookie) override {
    if (procs_.ATrace_beginAsyncSection) {
      procs_.ATrace_beginAsyncSection(name, cookie);
    }
  }

  // |SystemTracer|
  void EndAsyncSection(const char* name, int32_t cookie) override {
    if (procs_.ATrace_endAsyncSection) {
      procs_.ATrace_endAsyncSection(name, cookie);
    }
  }

  // |SystemTracer|
  void SetCounter(const char* name, int64_t value) override {
    if (procs_.ATrace_setCounter) {
      procs_.ATrace_setCounter(name, value);
    }
  }

 private:
  const android::ProcTable& procs_;

  explicit ATraceSystemTracer(const android::ProcTable& procs)
      : procs_(procs) {}
};

std::string GetSystemProperty(const char* name) {
  char value[PROP_VALUE_MAX] = {};
  __system_property_get(name, value);
  return value;
}

std::string ReadProcessName() {
  const int fd = ::open("/proc/self/cmdline", O_RDONLY | O_CLOEXEC);
  if (fd < 0) {
    return {};
  }
  char cmdline[256] = {};
  const ssize_t length = ::read(fd, cmdline, sizeof(cmdline) - 1);
  ::close(fd);
  if (length <= 0) {
    return {};
  }
  // Only the first argument (which is NUL terminated) is the process name.
  return cmdline;
}

//------------------------------------------------------------------------------
/// Writes events to the kernel `trace_marker` file directly. This is what
/// `ATrace_*` does under the hood, and is used when `libandroid.so` isn't
/// available in the linker namespace of the process (e.g. native binaries on
/// the product or vendor partitions).
///
class TraceMarkerSystemTracer final : public SystemTracer {
 public:
  static std::unique_ptr<TraceMarkerSystemTracer> Create() {
    int fd = ::open("/sys/kernel/tracing/trace_marker", O_WRONLY | O_CLOEXEC);
    if (fd < 0) {
      fd = ::open("/sys/kernel/debug/tracing/trace_marker",
                  O_WRONLY | O_CLOEXEC);
    }
    if (fd < 0) {
      return nullptr;
    }
    return std::unique_ptr<TraceMarkerSystemTracer>(
        new TraceMarkerSystemTracer(fd));
  }

  ~TraceMarkerSystemTracer() override { ::close(fd_); }

  // |SystemTracer|
  bool IsEnabled() override {
    // The serial of the system properties area changes when any property
    // changes. When nothing has changed, this is a single relaxed load from
    // shared memory, without allocations or syscalls.
    const uint32_t serial = __system_property_area_serial();
    if (serial != serial_.load(std::memory_order_acquire)) {
      Refresh(serial);
    }
    return enabled_.load(std::memory_order_relaxed);
  }

  // |SystemTracer|
  void BeginSection(const char* name) override { Write('B', name, 0); }

  // |SystemTracer|
  void EndSection() override { Write('E', nullptr, 0); }

  // |SystemTracer|
  void BeginAsyncSection(const char* name, int32_t cookie) override {
    Write('S', name, cookie);
  }

  // |SystemTracer|
  void EndAsyncSection(const char* name, int32_t cookie) override {
    Write('F', name, cookie);
  }

  // |SystemTracer|
  void SetCounter(const char* name, int64_t value) override {
    Write('C', name, value);
  }

 private:
  // Same as the maximum length of a record written by `libcutils`.
  static constexpr size_t kMaxRecordLength = 1024u;

  const int fd_;
  const int pid_;
  const std::string process_name_;
  std::mutex refresh_mutex_;
  std::atomic<uint32_t> serial_{UINT32_MAX};
  std::atomic<bool> enabled_{false};

  explicit TraceMarkerSystemTracer(int fd)
      : fd_(fd), pid_(::getpid()), process_name_(ReadProcessName()) {}

  void Refresh(uint32_t serial) {
    std::scoped_lock lock(refresh_mutex_);
    if (serial_.load(std::memory_order_relaxed) == serial) {
      return;
    }
    std::vector<std::string> traced_apps;
    const int app_count =
        std::atoi(GetSystemProperty("debug.atrace.app_number").c_str());
    for (int i = 0; i < app_count; i++) {
      const std::string property = "debug.atrace.app_" + std::to_string(i);
      traced_apps.push_back(GetSystemProperty(property.c_str()));
    }
    enabled_.store(
        ShouldTraceProcess(GetSystemProperty("debug.atrace.tags.enableflags"),
                           traced_apps, process_name_),
        std::memory_order_relaxed);
    serial_.store(serial, std::memory_order_release);
  }

  void Write(char phase, const char* name, int64_t value) {
    char record[kMaxRecordLength];
    const size_t length = FormatTraceMarkerRecord(record, sizeof(record), phase,
                                                  pid_, name, value);
    if (length > 0) {
      [[maybe_unused]] auto result = ::write(fd_, record, length);
    }
  }
};

std::atomic<SystemTracer*> gSystemTracer{nullptr};

void SystemTracerTimelineEventHandler(const char* label,
                                      int64_t timestamp0,
                                      int64_t timestamp1_or_async_id,
                                      intptr_t flow_id_count,
                                      const int64_t* flow_ids,
                                      Dart_Timeline_Event_Type type,
                                      intptr_t argument_count,
                                      const char** argument_names,
                                      const char** argument_values) {
  SystemTracer* tracer = gSystemTracer.load(std::memory_order_acquire);
  if (!tracer) {
    return;
  }
  ForwardTimelineEventToSystemTracer(*tracer, label, timestamp1_or_async_id,
                                     type, argument_count, argument_names,
                                     argument_values);
}

}  // namespace

#endif  // FML_OS_ANDROID

void SetupPlatformTracingIfNecessary() {
#if FML_OS_ANDROID
  static std::once_flag sOnceFlag;
  std::call_once(sOnceFlag, []() {
    // Don't clobber a handler installed by the host (e.g. the Dart VM).
    if (fml::tracing::TraceHasTimelineEventHandler()) {
      return;
    }
    std::unique_ptr<SystemTracer> tracer = ATraceSystemTracer::Create();
    if (!tracer) {
      tracer = TraceMarkerSystemTracer::Create();
    }
    if (!tracer) {
      return;
    }
    // The tracer is intentionally leaked as the handler can be invoked from
    // any thread till the process exits.
    gSystemTracer.store(tracer.release(), std::memory_order_release);
    fml::tracing::TraceSetTimelineEventHandler(
        &SystemTracerTimelineEventHandler);
  });
#endif  // FML_OS_ANDROID
}

}  // namespace impeller::interop
