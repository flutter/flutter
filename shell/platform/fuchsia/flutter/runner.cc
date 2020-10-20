// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "runner.h"

#include <fcntl.h>
#include <fuchsia/mem/cpp/fidl.h>
#include <lib/async/cpp/task.h>
#include <lib/trace-engine/instrumentation.h>
#include <zircon/status.h>
#include <zircon/types.h>

#include <cstdint>
#include <sstream>
#include <utility>

#include "flutter/fml/make_copyable.h"
#include "flutter/lib/ui/text/font_collection.h"
#include "flutter/runtime/dart_vm.h"
#include "lib/sys/cpp/component_context.h"
#include "runtime/dart/utils/files.h"
#include "runtime/dart/utils/vmo.h"
#include "runtime/dart/utils/vmservice_object.h"
#include "third_party/icu/source/common/unicode/udata.h"
#include "third_party/skia/include/core/SkGraphics.h"

namespace flutter_runner {

namespace {

static constexpr char kIcuDataPath[] = "/pkg/data/icudtl.dat";

// Environment variable containing the path to the directory containing the
// timezone files.
static constexpr char kICUTZEnv[] = "ICU_TIMEZONE_FILES_DIR";

// The data directory containing ICU timezone data files.
static constexpr char kICUTZDataDir[] = "/config/data/tzdata/icu/44/le";

// Map the memory into the process and return a pointer to the memory.
uintptr_t GetICUData(const fuchsia::mem::Buffer& icu_data) {
  uint64_t data_size = icu_data.size;
  if (data_size > std::numeric_limits<size_t>::max())
    return 0u;

  uintptr_t data = 0u;
  zx_status_t status =
      zx::vmar::root_self()->map(ZX_VM_PERM_READ, 0, icu_data.vmo, 0,
                                 static_cast<size_t>(data_size), &data);
  if (status == ZX_OK) {
    return data;
  }

  return 0u;
}

// Initializes the timezone data if available.  Timezone data file in Fuchsia
// is at a fixed directory path.  Returns true on success.  As a side effect
// sets the value of the environment variable "ICU_TIMEZONE_FILES_DIR" to a
// fixed value which is fuchsia-specific.
bool InitializeTZData() {
  // We need the ability to change the env variable for testing, so not
  // overwriting if set.
  setenv(kICUTZEnv, kICUTZDataDir, 0 /* No overwrite */);

  const std::string tzdata_dir = getenv(kICUTZEnv);
  // Try opening the path to check if present.  No need to verify that it is a
  // directory since ICU loading will return an error if the TZ data path is
  // wrong.
  int fd = openat(AT_FDCWD, tzdata_dir.c_str(), O_RDONLY);
  if (fd < 0) {
    FML_LOG(INFO) << "Could not open: '" << tzdata_dir
                  << "', proceeding without loading the timezone database: "
                  << strerror(errno);
    return false;
  }
  if (close(fd)) {
    FML_LOG(WARNING) << "Could not close: " << tzdata_dir << ": "
                     << strerror(errno);
  }
  return true;
}

// Return value indicates if initialization was successful.
bool InitializeICU() {
  const char* data_path = kIcuDataPath;

  fuchsia::mem::Buffer icu_data;
  if (!dart_utils::VmoFromFilename(data_path, false, &icu_data)) {
    return false;
  }

  uintptr_t data = GetICUData(icu_data);
  if (!data) {
    return false;
  }

  // If the loading fails, soldier on.  The loading is optional as we don't
  // want to crash the engine in transition.
  InitializeTZData();

  // Pass the data to ICU.
  UErrorCode err = U_ZERO_ERROR;
  udata_setCommonData(reinterpret_cast<const char*>(data), &err);
  if (err != U_ZERO_ERROR) {
    FML_LOG(ERROR) << "error loading ICU data: " << err;
    return false;
  }
  return true;
}

}  // namespace

static void SetProcessName() {
  std::stringstream stream;
#if defined(DART_PRODUCT)
  stream << "io.flutter.product_runner.";
#else
  stream << "io.flutter.runner.";
#endif
  if (flutter::DartVM::IsRunningPrecompiledCode()) {
    stream << "aot";
  } else {
    stream << "jit";
  }
  const auto name = stream.str();
  zx::process::self()->set_property(ZX_PROP_NAME, name.c_str(), name.size());
}

static void SetThreadName(const std::string& thread_name) {
  zx::thread::self()->set_property(ZX_PROP_NAME, thread_name.c_str(),
                                   thread_name.size());
}

#if !defined(DART_PRODUCT)
// Register native symbol information for the Dart VM's profiler.
static void RegisterProfilerSymbols(const char* symbols_path,
                                    const char* dso_name) {
  std::string* symbols = new std::string();
  if (dart_utils::ReadFileToString(symbols_path, symbols)) {
    Dart_AddSymbols(dso_name, symbols->data(), symbols->size());
  } else {
    FML_LOG(ERROR) << "Failed to load " << symbols_path;
  }
}
#endif  // !defined(DART_PRODUCT)

Runner::Runner(async::Loop* loop, sys::ComponentContext* context)
    : loop_(loop), context_(context) {
#if !defined(DART_PRODUCT)
  // The VM service isolate uses the process-wide namespace. It writes the
  // vm service protocol port under /tmp. The VMServiceObject exposes that
  // port number to The Hub.
  context_->outgoing()->debug_dir()->AddEntry(
      dart_utils::VMServiceObject::kPortDirName,
      std::make_unique<dart_utils::VMServiceObject>());

  SetupTraceObserver();
#endif  // !defined(DART_PRODUCT)

  SkGraphics::Init();

  SetupICU();

  SetProcessName();

  SetThreadName("io.flutter.runner.main");

  context_->outgoing()->AddPublicService<fuchsia::sys::Runner>(
      std::bind(&Runner::RegisterApplication, this, std::placeholders::_1));

#if !defined(DART_PRODUCT)
  if (Dart_IsPrecompiledRuntime()) {
    RegisterProfilerSymbols("pkg/data/flutter_aot_runner.dartprofilersymbols",
                            "");
  } else {
    RegisterProfilerSymbols("pkg/data/flutter_jit_runner.dartprofilersymbols",
                            "");
  }
#endif  // !defined(DART_PRODUCT)
}

Runner::~Runner() {
  context_->outgoing()->RemovePublicService<fuchsia::sys::Runner>();

#if !defined(DART_PRODUCT)
  trace_observer_->Stop();
#endif  // !defined(DART_PRODUCT)
}

void Runner::RegisterApplication(
    fidl::InterfaceRequest<fuchsia::sys::Runner> request) {
  active_applications_bindings_.AddBinding(this, std::move(request));
}

void Runner::StartComponent(
    fuchsia::sys::Package package,
    fuchsia::sys::StartupInfo startup_info,
    fidl::InterfaceRequest<fuchsia::sys::ComponentController> controller) {
  // TRACE_DURATION currently requires that the string data does not change
  // in the traced scope. Since |package| gets moved in the Application::Create
  // call below, we cannot ensure that |package.resolved_url| does not move or
  // change, so we make a copy to pass to TRACE_DURATION.
  // TODO(PT-169): Remove this copy when TRACE_DURATION reads string arguments
  // eagerly.
  std::string url_copy = package.resolved_url;
  TRACE_EVENT1("flutter", "StartComponent", "url", url_copy.c_str());
  // Notes on application termination: Application typically terminate on the
  // thread on which they were created. This usually means the thread was
  // specifically created to host the application. But we want to ensure that
  // access to the active applications collection is made on the same thread. So
  // we capture the runner in the termination callback. There is no risk of
  // there being multiple application runner instance in the process at the same
  // time. So it is safe to use the raw pointer.
  Application::TerminationCallback termination_callback =
      [task_runner = loop_->dispatcher(),  //
       application_runner = this           //
  ](const Application* application) {
        async::PostTask(task_runner, [application_runner, application]() {
          application_runner->OnApplicationTerminate(application);
        });
      };

  auto active_application = Application::Create(
      std::move(termination_callback),  // termination callback
      std::move(package),               // application package
      std::move(startup_info),          // startup info
      context_->svc(),                  // runner incoming services
      std::move(controller)             // controller request
  );

  auto key = active_application.application.get();
  active_applications_[key] = std::move(active_application);
}

void Runner::OnApplicationTerminate(const Application* application) {
  auto app = active_applications_.find(application);
  if (app == active_applications_.end()) {
    FML_LOG(INFO)
        << "The remote end of the application runner tried to terminate an "
           "application that has already been terminated, possibly because we "
           "initiated the termination";
    return;
  }
  auto& active_application = app->second;

  // Grab the items out of the entry because we will have to rethread the
  // destruction.
  auto application_to_destroy = std::move(active_application.application);
  auto application_thread = std::move(active_application.thread);

  // Delegate the entry.
  active_applications_.erase(application);

  // Post the task to destroy the application and quit its message loop.
  async::PostTask(
      application_thread->dispatcher(),
      fml::MakeCopyable([instance = std::move(application_to_destroy),
                         thread = application_thread.get()]() mutable {
        instance.reset();
        thread->Quit();
      }));

  // This works because just posted the quit task on the hosted thread.
  application_thread->Join();
}

void Runner::SetupICU() {
  // Exposes the TZ data setup for testing.  Failing here is not fatal.
  Runner::SetupTZDataInternal();
  if (!Runner::SetupICUInternal()) {
    FML_LOG(ERROR) << "Could not initialize ICU data.";
  }
}

// static
bool Runner::SetupICUInternal() {
  return InitializeICU();
}

// static
bool Runner::SetupTZDataInternal() {
  return InitializeTZData();
}

#if !defined(DART_PRODUCT)
void Runner::SetupTraceObserver() {
  trace_observer_ = std::make_unique<trace::TraceObserver>();
  trace_observer_->Start(loop_->dispatcher(), [runner = this]() {
    if (!trace_is_category_enabled("dart:profiler")) {
      return;
    }
    if (trace_state() == TRACE_STARTED) {
      runner->prolonged_context_ = trace_acquire_prolonged_context();
      Dart_StartProfiling();
    } else if (trace_state() == TRACE_STOPPING) {
      for (auto& it : runner->active_applications_) {
        fml::AutoResetWaitableEvent latch;
        async::PostTask(it.second.thread->dispatcher(), [&]() {
          it.second.application->WriteProfileToTrace();
          latch.Signal();
        });
        latch.Wait();
      }
      Dart_StopProfiling();
      trace_release_prolonged_context(runner->prolonged_context_);
    }
  });
}
#endif  // !defined(DART_PRODUCT)

}  // namespace flutter_runner
