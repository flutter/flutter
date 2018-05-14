// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "application_runner.h"

#include <zircon/types.h>

#include <sstream>
#include <utility>

#include "flutter/lib/ui/text/font_collection.h"
#include "fuchsia_font_manager.h"
#include "lib/fxl/functional/make_copyable.h"
#include "lib/icu_data/cpp/icu_data.h"
#include "third_party/flutter/runtime/dart_vm.h"
#include "third_party/skia/include/core/SkGraphics.h"

namespace flutter {

static void SetProcessName() {
  std::stringstream stream;
  stream << "io.flutter.runner.";
  if (blink::DartVM::IsRunningPrecompiledCode()) {
    stream << "aot";
  } else {
    stream << "jit";
  }
  const auto name = stream.str();
  zx::process::self().set_property(ZX_PROP_NAME, name.c_str(), name.size());
}

static void SetThreadName(const std::string& thread_name) {
  zx::thread::self().set_property(ZX_PROP_NAME, thread_name.c_str(),
                                  thread_name.size());
}

ApplicationRunner::ApplicationRunner()
    : host_context_(component::ApplicationContext::CreateFromStartupInfo()) {
  SkGraphics::Init();

  SetupICU();

  SetupGlobalFonts();

  SetProcessName();

  SetThreadName("io.flutter.runner.main");

  host_context_->outgoing_services()->AddService<component::ApplicationRunner>(
      std::bind(&ApplicationRunner::RegisterApplication, this,
                std::placeholders::_1));
}

ApplicationRunner::~ApplicationRunner() {
  host_context_->outgoing_services()
      ->RemoveService<component::ApplicationRunner>();
}

void ApplicationRunner::RegisterApplication(
    fidl::InterfaceRequest<component::ApplicationRunner> request) {
  active_applications_bindings_.AddBinding(this, std::move(request));
}

void ApplicationRunner::StartApplication(
    component::ApplicationPackage package,
    component::ApplicationStartupInfo startup_info,
    fidl::InterfaceRequest<component::ApplicationController> controller) {
  // Notes on application termination: Application typically terminate on the
  // thread on which they were created. This usually means the thread was
  // specifically created to host the application. But we want to ensure that
  // access to the active applications collection is made on the same thread. So
  // we capture the runner in the termination callback. There is no risk of
  // there being multiple application runner instance in the process at the same
  // time. So it is safe to use the raw pointer.
  Application::TerminationCallback termination_callback =
      [task_runner = fsl::MessageLoop::GetCurrent()->task_runner(),  //
       application_runner = this                                     //
  ](const Application* application) {
        task_runner->PostTask([application_runner, application]() {
          application_runner->OnApplicationTerminate(application);
        });
      };

  auto thread_application_pair =
      Application::Create(termination_callback,     // termination callback
                          std::move(package),       // application pacakge
                          std::move(startup_info),  // startup info
                          std::move(controller)     // controller request
      );

  auto key = thread_application_pair.second.get();

  active_applications_[key] = std::move(thread_application_pair);
}

void ApplicationRunner::OnApplicationTerminate(const Application* application) {
  auto& active_application = active_applications_.at(application);

  // Grab the items out of the entry because we will have to rethread the
  // destruction.
  auto application_to_destroy = std::move(active_application.application);
  auto application_destruction_thread = std::move(active_application.thread);

  // Delegate the entry.
  active_applications_.erase(application);

  // Post the task to destroy the application and quit its message loop.
  auto runner = application_destruction_thread->TaskRunner();
  runner->PostTask(fxl::MakeCopyable(
      [instance = std::move(application_to_destroy)]() mutable {
        instance.reset();

        fsl::MessageLoop::GetCurrent()->PostQuitTask();
      }));

  // This works because just posted the quit task on the hosted thread.
  application_destruction_thread->Join();
}

void ApplicationRunner::SetupICU() {
  if (!icu_data::Initialize(host_context_.get())) {
    FXL_LOG(ERROR) << "Could not initialize ICU data.";
  }
}

void ApplicationRunner::SetupGlobalFonts() {
  // Fuchsia does not have per application (shell) fonts. Instead, all fonts
  // must be obtained from the font provider.
  auto process_font_collection =
      blink::FontCollection::ForProcess().GetFontCollection();

  // Connect to the system font provider.
  fonts::FontProviderSyncPtr sync_font_provider;
  host_context_->ConnectToEnvironmentService(sync_font_provider.NewRequest());

  // Set the default font manager.
  process_font_collection->SetDefaultFontManager(
      sk_make_sp<txt::FuchsiaFontManager>(std::move(sync_font_provider)));
}

}  // namespace flutter
