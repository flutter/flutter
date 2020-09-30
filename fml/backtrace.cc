// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/backtrace.h"

#include <cxxabi.h>
#include <dlfcn.h>
#include <execinfo.h>

#include <csignal>
#include <sstream>

#if OS_WIN
#include <crtdbg.h>
#include <debugapi.h>
#endif

#include "flutter/fml/logging.h"

namespace fml {

static std::string kKUnknownFrameName = "Unknown";

static std::string DemangleSymbolName(const std::string& mangled) {
  if (mangled == kKUnknownFrameName) {
    return kKUnknownFrameName;
  }

  int status = 0;
  size_t length = 0;
  char* demangled = __cxxabiv1::__cxa_demangle(
      mangled.data(),  // mangled name
      nullptr,         // output buffer (malloc-ed if nullptr)
      &length,         // demangled length
      &status);

  if (demangled == nullptr || status != 0) {
    return mangled;
  }

  auto demangled_string = std::string{demangled, length};
  free(demangled);
  return demangled_string;
}

static std::string GetSymbolName(void* symbol) {
  Dl_info info = {};

  if (::dladdr(symbol, &info) == 0) {
    return kKUnknownFrameName;
  }

  return DemangleSymbolName({info.dli_sname});
}

std::string BacktraceHere(size_t offset) {
  constexpr size_t kMaxFrames = 256;
  void* symbols[kMaxFrames];
  const auto available_frames = ::backtrace(symbols, kMaxFrames);
  if (available_frames <= 0) {
    return "";
  }

  std::stringstream stream;
  for (int i = 1 + offset; i < available_frames; ++i) {
    stream << "Frame " << i - 1 - offset << ": " << symbols[i] << " "
           << GetSymbolName(symbols[i]) << std::endl;
  }
  return stream.str();
}

static size_t kKnownSignalHandlers[] = {
    SIGABRT,  // abort program
    SIGFPE,   // floating-point exception
    SIGBUS,   // bus error
    SIGSEGV,  // segmentation violation
    SIGSYS,   // non-existent system call invoked
    SIGPIPE,  // write on a pipe with no reader
    SIGALRM,  // real-time timer expired
    SIGTERM,  // software termination signal
};

static std::string SignalNameToString(int signal) {
  switch (signal) {
    case SIGABRT:
      return "SIGABRT";
    case SIGFPE:
      return "SIGFPE";
    case SIGBUS:
      return "SIGBUS";
    case SIGSEGV:
      return "SIGSEGV";
    case SIGSYS:
      return "SIGSYS";
    case SIGPIPE:
      return "SIGPIPE";
    case SIGALRM:
      return "SIGALRM";
    case SIGTERM:
      return "SIGTERM";
  };
  return std::to_string(signal);
}

static void ToggleSignalHandlers(bool set);

static void SignalHandler(int signal) {
  // We are a crash signal handler. This can only happen once. Since we don't
  // want to catch crashes while we are generating the crash reports, disable
  // all set signal handlers to their default values before reporting the crash
  // and re-raising the signal.
  ToggleSignalHandlers(false);

  FML_LOG(ERROR) << "Caught signal " << SignalNameToString(signal)
                 << " during program execution." << std::endl
                 << BacktraceHere(3);

  ::raise(signal);
}

static void ToggleSignalHandlers(bool set) {
  for (size_t i = 0; i < sizeof(kKnownSignalHandlers) / sizeof(size_t); ++i) {
    auto signal_name = kKnownSignalHandlers[i];
    auto handler = set ? &SignalHandler : SIG_DFL;

    if (::signal(signal_name, handler) == SIG_ERR) {
      FML_LOG(ERROR) << "Could not attach signal handler for " << signal_name;
    }
  }
}

void InstallCrashHandler() {
#if OS_WIN
  if (!IsDebuggerPresent()) {
    _CrtSetReportMode(_CRT_ASSERT, _CRTDBG_MODE_FILE | _CRTDBG_MODE_DEBUG);
    _CrtSetReportFile(_CRT_ASSERT, _CRTDBG_FILE_STDERR);
  }
#endif
  ToggleSignalHandlers(true);
}

bool IsCrashHandlingSupported() {
  return true;
}

}  // namespace fml
