// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/sky/shell/platform/mac/platform_view_mac.h"

#include <AppKit/AppKit.h>

#include "base/command_line.h"
#include "base/trace_event/trace_event.h"
#include "flutter/sky/shell/switches.h"
#include "flutter/sky/shell/platform/mac/view_service_provider.h"
#include "flutter/sky/shell/platform/mac/platform_mac.h"
#include "flutter/sky/shell/platform/mac/platform_service_provider.h"
#include "lib/ftl/synchronization/waitable_event.h"

namespace sky {
namespace shell {

static void IgnoreRequest(
    mojo::InterfaceRequest<flutter::platform::ApplicationMessages>) {}

static void DynamicServiceResolve(const mojo::String& service_name,
                                  mojo::ScopedMessagePipeHandle handle) {}

PlatformViewMac::PlatformViewMac(NSOpenGLView* gl_view)
    : opengl_view_([gl_view retain]),
      resource_loading_context_([[NSOpenGLContext alloc]
          initWithFormat:gl_view.pixelFormat
            shareContext:gl_view.openGLContext]),
      weak_factory_(this) {}

PlatformViewMac::~PlatformViewMac() = default;

void PlatformViewMac::ConnectToEngineAndSetupServices() {
  ConnectToEngine(mojo::GetProxy(&sky_engine_));

  mojo::ServiceProviderPtr service_provider;
  new PlatformServiceProvider(mojo::GetProxy(&service_provider),
                              base::Bind(DynamicServiceResolve));

  mojo::ServiceProviderPtr view_service_provider;
  new ViewServiceProvider(IgnoreRequest,
                          mojo::GetProxy(&view_service_provider));

  sky::ServicesDataPtr services = sky::ServicesData::New();
  services->incoming_services = service_provider.Pass();
  services->view_services = view_service_provider.Pass();
  sky_engine_->SetServices(services.Pass());
}

void PlatformViewMac::SetupAndLoadDart() {
  ConnectToEngineAndSetupServices();

  if (AttemptLaunchFromCommandLineSwitches(sky_engine_)) {
    // This attempts launching from an FLX bundle that does not contain a
    // dart snapshot.
    return;
  }

  base::CommandLine& command_line = *base::CommandLine::ForCurrentProcess();

  std::string bundle_path = command_line.GetSwitchValueASCII(switches::kFLX);
  if (!bundle_path.empty()) {
    std::string script_uri = std::string("file://") + bundle_path;
    sky_engine_->RunFromBundle(script_uri, bundle_path);
    return;
  }

  auto args = command_line.GetArgs();
  if (args.size() > 0) {
    auto packages = command_line.GetSwitchValueASCII(switches::kPackages);
    sky_engine_->RunFromFile(args[0], packages, "");
    return;
  }
}

void PlatformViewMac::SetupAndLoadFromSource(
    const std::string& main,
    const std::string& packages,
    const std::string& assets_directory) {
  ConnectToEngineAndSetupServices();

  sky_engine_->RunFromFile(main, packages, assets_directory);
}

SkyEnginePtr& PlatformViewMac::engineProxy() {
  return sky_engine_;
}

ftl::WeakPtr<PlatformView> PlatformViewMac::GetWeakViewPtr() {
  return weak_factory_.GetWeakPtr();
}

uint64_t PlatformViewMac::DefaultFramebuffer() const {
  // Default window bound framebuffer FBO 0.
  return 0;
}

bool PlatformViewMac::ContextMakeCurrent() {
  if (!IsValid()) {
    return false;
  }

  [opengl_view_.get().openGLContext makeCurrentContext];
  return true;
}

bool PlatformViewMac::ResourceContextMakeCurrent() {
  NSOpenGLContext* context = resource_loading_context_.get();

  if (context == nullptr) {
    return false;
  }

  [context makeCurrentContext];
  return true;
}

bool PlatformViewMac::SwapBuffers() {
  TRACE_EVENT0("flutter", "PlatformViewMac::SwapBuffers");

  if (!IsValid()) {
    return false;
  }

  [opengl_view_.get().openGLContext flushBuffer];
  return true;
}

bool PlatformViewMac::IsValid() const {
  if (opengl_view_ == nullptr) {
    return false;
  }

  auto context = opengl_view_.get().openGLContext;

  if (context == nullptr) {
    return false;
  }

  return true;
}

void PlatformViewMac::RunFromSource(const std::string& main,
                                    const std::string& packages,
                                    const std::string& assets_directory) {
  auto latch = new ftl::ManualResetWaitableEvent();

  dispatch_async(dispatch_get_main_queue(), ^{
    SetupAndLoadFromSource(main, packages, assets_directory);
    latch->Signal();
  });

  latch->Wait();
  delete latch;
}

}  // namespace shell
}  // namespace sky
