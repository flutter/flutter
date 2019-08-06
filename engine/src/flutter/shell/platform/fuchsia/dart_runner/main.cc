// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <lib/async-loop/cpp/loop.h>
#include <lib/trace-provider/provider.h>
#include <lib/trace/event.h>

#include "dart_runner.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "logging.h"
#include "runtime/dart/utils/files.h"
#include "runtime/dart/utils/tempfs.h"
#include "third_party/dart/runtime/include/dart_api.h"

#if !defined(FUCHSIA_SDK)
#include <lib/syslog/cpp/logger.h>
#endif  //  !defined(FUCHSIA_SDK)

#if !defined(DART_PRODUCT)
// Register native symbol information for the Dart VM's profiler.
static void RegisterProfilerSymbols(const char* symbols_path,
                                    const char* dso_name) {
  std::string* symbols = new std::string();
  if (dart_utils::ReadFileToString(symbols_path, symbols)) {
    Dart_AddSymbols(dso_name, symbols->data(), symbols->size());
  } else {
    FML_LOG(ERROR) << "Failed to load " << symbols_path;
    FML_CHECK(false);
  }
}
#endif  // !defined(DART_PRODUCT)

int main(int argc, const char** argv) {
  async::Loop loop(&kAsyncLoopConfigAttachToThread);

#if !defined(FUCHSIA_SDK)
  syslog::InitLogger();

  std::unique_ptr<trace::TraceProviderWithFdio> provider;
  {
    TRACE_EVENT0("dart", "CreateTraceProvider");
    bool already_started;
    // Use CreateSynchronously to prevent loss of early events.
    trace::TraceProviderWithFdio::CreateSynchronously(
        loop.dispatcher(), "dart_runner", &provider, &already_started);
  }
#endif  //  !defined(FUCHSIA_SDK)

#if !defined(DART_PRODUCT)
#if defined(AOT_RUNTIME)
  RegisterProfilerSymbols(
      "pkg/data/libdart_precompiled_runtime.dartprofilersymbols",
      "libdart_precompiled_runtime.so");
  RegisterProfilerSymbols("pkg/data/dart_aot_runner.dartprofilersymbols", "");
#else
  RegisterProfilerSymbols("pkg/data/libdart_jit.dartprofilersymbols",
                          "libdart_jit.so");
  RegisterProfilerSymbols("pkg/data/dart_jit_runner.dartprofilersymbols", "");
#endif  // defined(AOT_RUNTIME)
#endif  // !defined(DART_PRODUCT)

  dart_utils::SetupRunnerTemp();

  dart_runner::DartRunner runner;
  loop.Run();
  return 0;
}
