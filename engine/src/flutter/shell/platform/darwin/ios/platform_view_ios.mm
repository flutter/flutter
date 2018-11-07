// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/platform_view_ios.h"

#import <QuartzCore/CAEAGLLayer.h>

#include <utility>

#include "flutter/common/task_runners.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/trace_event.h"
#include "flutter/shell/common/io_manager.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/vsync_waiter_ios.h"
#include "flutter/shell/platform/darwin/ios/ios_external_texture_gl.h"

namespace shell {

PlatformViewIOS::PlatformViewIOS(PlatformView::Delegate& delegate, blink::TaskRunners task_runners)
    : PlatformView(delegate, std::move(task_runners)) {}

PlatformViewIOS::~PlatformViewIOS() = default;

PlatformMessageRouter& PlatformViewIOS::GetPlatformMessageRouter() {
  return platform_message_router_;
}

// |shell::PlatformView|
void PlatformViewIOS::HandlePlatformMessage(fml::RefPtr<blink::PlatformMessage> message) {
  platform_message_router_.HandlePlatformMessage(std::move(message));
}

fml::WeakPtr<FlutterViewController> PlatformViewIOS::GetOwnerViewController() const {
  return owner_controller_;
}

void PlatformViewIOS::SetOwnerViewController(fml::WeakPtr<FlutterViewController> owner_controller) {
  if (ios_surface_ || !owner_controller) {
    NotifyDestroyed();
    ios_surface_.reset();
    accessibility_bridge_.reset();
  }
  owner_controller_ = owner_controller;
  if (owner_controller_) {
    ios_surface_ = static_cast<FlutterView*>(owner_controller.get().view).createSurface;
    FML_DCHECK(ios_surface_ != nullptr);

    if (accessibility_bridge_) {
      accessibility_bridge_.reset(
          new AccessibilityBridge(static_cast<FlutterView*>(owner_controller_.get().view), this));
    }
    // Do not call `NotifyCreated()` here - let FlutterViewController take care
    // of that when its Viewport is sized.  If `NotifyCreated()` is called here,
    // it can occasionally get invoked before the viewport is sized resulting in
    // a framebuffer that will not be able to completely attach.
  }
}

void PlatformViewIOS::RegisterExternalTexture(int64_t texture_id,
                                              NSObject<FlutterTexture>* texture) {
  RegisterTexture(std::make_shared<IOSExternalTextureGL>(texture_id, texture));
}

// |shell::PlatformView|
std::unique_ptr<Surface> PlatformViewIOS::CreateRenderingSurface() {
  if (!ios_surface_) {
    FML_DLOG(INFO) << "Could not CreateRenderingSurface, this PlatformViewIOS "
                      "has no ViewController.";
    return nullptr;
  }
  return ios_surface_->CreateGPUSurface();
}

// |shell::PlatformView|
sk_sp<GrContext> PlatformViewIOS::CreateResourceContext() const {
  if (!ios_surface_ || !ios_surface_->ResourceContextMakeCurrent()) {
    FML_DLOG(INFO) << "Could not make resource context current on IO thread. "
                      "Async texture uploads "
                      "will be disabled.";
    return nullptr;
  }

  return IOManager::CreateCompatibleResourceLoadingContext(GrBackend::kOpenGL_GrBackend);
}

// |shell::PlatformView|
void PlatformViewIOS::SetSemanticsEnabled(bool enabled) {
  if (!owner_controller_) {
    FML_DLOG(WARNING) << "Could not set semantics to enabled, this "
                         "PlatformViewIOS has no ViewController.";
    return;
  }
  if (enabled && !accessibility_bridge_) {
    accessibility_bridge_ = std::make_unique<AccessibilityBridge>(
        static_cast<FlutterView*>(owner_controller_.get().view), this);
  } else if (!enabled && accessibility_bridge_) {
    accessibility_bridge_.reset();
  }
  PlatformView::SetSemanticsEnabled(enabled);
}

// |shell:PlatformView|
void PlatformViewIOS::SetAccessibilityFeatures(int32_t flags) {
  PlatformView::SetAccessibilityFeatures(flags);
}

// |shell::PlatformView|
void PlatformViewIOS::UpdateSemantics(blink::SemanticsNodeUpdates update,
                                      blink::CustomAccessibilityActionUpdates actions) {
  if (accessibility_bridge_) {
    accessibility_bridge_->UpdateSemantics(std::move(update), std::move(actions));
  }
}

// |shell::PlatformView|
std::unique_ptr<VsyncWaiter> PlatformViewIOS::CreateVSyncWaiter() {
  return std::make_unique<VsyncWaiterIOS>(task_runners_);
}

fml::scoped_nsprotocol<FlutterTextInputPlugin*> PlatformViewIOS::GetTextInputPlugin() const {
  return text_input_plugin_;
}

void PlatformViewIOS::SetTextInputPlugin(fml::scoped_nsprotocol<FlutterTextInputPlugin*> plugin) {
  text_input_plugin_ = plugin;
}

}  // namespace shell
