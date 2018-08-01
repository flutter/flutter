// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_IOS_PLATFORM_VIEW_IOS_H_
#define SHELL_PLATFORM_IOS_PLATFORM_VIEW_IOS_H_

#include <memory>

#include "flutter/fml/closure.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterTexture.h"
#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterViewController.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/FlutterView.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/accessibility_bridge.h"
#include "flutter/shell/platform/darwin/ios/headless_platform_view_ios.h"
#include "flutter/shell/platform/darwin/ios/ios_surface.h"

namespace shell {

class PlatformViewIOS final : public HeadlessPlatformViewIOS {
 public:
  explicit PlatformViewIOS(PlatformView::Delegate& delegate,
                           blink::TaskRunners task_runners,
                           FlutterViewController* owner_controller_,
                           FlutterView* owner_view_);

  ~PlatformViewIOS() override;

  FlutterViewController* GetOwnerViewController() const;

  void RegisterExternalTexture(int64_t id, NSObject<FlutterTexture>* texture);

  fml::scoped_nsprotocol<FlutterTextInputPlugin*> GetTextInputPlugin() const;

  void SetTextInputPlugin(
      fml::scoped_nsprotocol<FlutterTextInputPlugin*> plugin);

 private:
  FlutterViewController* owner_controller_;  // weak reference.
  FlutterView* owner_view_;                  // weak reference.
  std::unique_ptr<IOSSurface> ios_surface_;
  PlatformMessageRouter platform_message_router_;
  std::unique_ptr<AccessibilityBridge> accessibility_bridge_;
  fml::scoped_nsprotocol<FlutterTextInputPlugin*> text_input_plugin_;
  fml::closure firstFrameCallback_;

  // |shell::PlatformView|
  std::unique_ptr<Surface> CreateRenderingSurface() override;

  // |shell::PlatformView|
  sk_sp<GrContext> CreateResourceContext() const override;

  // |shell::PlatformView|
  void SetSemanticsEnabled(bool enabled) override;

  // |shell::PlatformView|
  void SetAccessibilityFeatures(int32_t flags) override;

  // |shell::PlatformView|
  void UpdateSemantics(
      blink::SemanticsNodeUpdates update,
      blink::CustomAccessibilityActionUpdates actions) override;

  // |shell::PlatformView|
  std::unique_ptr<VsyncWaiter> CreateVSyncWaiter() override;

  FML_DISALLOW_COPY_AND_ASSIGN(PlatformViewIOS);
};

}  // namespace shell

#endif  // SHELL_PLATFORM_IOS_PLATFORM_VIEW_IOS_H_
