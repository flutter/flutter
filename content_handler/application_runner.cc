// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "application_runner.h"

#include <zircon/types.h>

#include <sstream>
#include <utility>

#include "flutter/lib/ui/text/font_collection.h"
#include "fuchsia_font_manager.h"
#include "lib/icu_data/cpp/icu_data.h"
#include "third_party/skia/include/core/SkGraphics.h"

namespace flutter {

static void SetProcessName(const std::string& process_name) {
  zx::process::self().set_property(ZX_PROP_NAME, process_name.c_str(),
                                   process_name.size());
}

static void SetThreadName(const std::string& thread_name) {
  zx::thread::self().set_property(ZX_PROP_NAME, thread_name.c_str(),
                                  thread_name.size());
}

static void SetProcessName(const std::string& label, size_t app_count) {
  // Format: "flutter.<label_truncated_to_fit>+<app_count>"
  //         "flutter" in case of error.

  const std::string prefix = "flutter.";
  const std::string suffix =
      app_count == 0 ? "" : "+" + std::to_string(app_count);

  if ((prefix.size() + suffix.size()) > ZX_MAX_NAME_LEN) {
    SetProcessName("flutter");
    return;
  }

  auto truncated_label =
      label.substr(0, ZX_MAX_NAME_LEN - 1 - (prefix.size() + suffix.size()));

  SetProcessName(prefix + truncated_label + suffix);
}

ApplicationRunner::ApplicationRunner(fxl::Closure on_termination_callback)
    : on_termination_callback_(std::move(on_termination_callback)),
      host_context_(component::ApplicationContext::CreateFromStartupInfo()) {
  SkGraphics::Init();

  SetupICU();

  SetupGlobalFonts();

  SetProcessName("application_runner", 0);

  SetThreadName("io.flutter.application_runner");

  host_context_->outgoing_services()->AddService<component::ApplicationRunner>(
      std::bind(&ApplicationRunner::RegisterApplication, this,
                std::placeholders::_1));

  active_applications_bindings_.set_empty_set_handler(
      [this]() { FireTerminationCallbackIfNecessary(); });
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
  auto thread_application_pair =
      Application::Create(*this,                    // delegate
                          std::move(package),       // application pacakge
                          std::move(startup_info),  // startup info
                          std::move(controller)     // controller request
      );

  // Update the process label so that "ps" will will list the last appication
  // started by the runner plus the count of applications hosted by this runner.
  SetProcessName(thread_application_pair.second->GetDebugLabel(),
                 active_applications_.size());

  active_applications_[thread_application_pair.second.get()] =
      std::move(thread_application_pair);
}

void ApplicationRunner::OnApplicationTerminate(const Application* application) {
  active_applications_.erase(application);
  FireTerminationCallbackIfNecessary();
}

void ApplicationRunner::SetupICU() {
  if (!icu_data::Initialize(host_context_.get())) {
    FXL_LOG(ERROR) << "Could not initialize ICU data.";
  }
}

void ApplicationRunner::SetupGlobalFonts() {
  fonts::FontProviderPtr font_provider(
      host_context_->ConnectToEnvironmentService<fonts::FontProvider>());
  auto font_manager =
      sk_make_sp<txt::FuchsiaFontManager>(std::move(font_provider));
  blink::FontCollection::ForProcess()
      .GetFontCollection()
      ->SetDefaultFontManager(std::move(font_manager));
}

void ApplicationRunner::FireTerminationCallbackIfNecessary() {
  // We have no reason to exist if:
  // 1: No previously launched applications are running.
  // 2: No bindings exist that may require launching more applications.
  if (on_termination_callback_ && active_applications_.size() == 0 &&
      active_applications_bindings_.size() == 0) {
    on_termination_callback_();
  }
}

}  // namespace flutter
