// Copyright 2013 The Flutter Authors. All rights reserved.
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
#include "flutter/shell/platform/darwin/ios/framework/Source/platform_message_router.h"
#include "flutter/shell/platform/darwin/ios/ios_surface.h"

@class FlutterViewController;

namespace shell {

class PlatformViewIOS final : public PlatformView {
 public:
  explicit PlatformViewIOS(PlatformView::Delegate& delegate, blink::TaskRunners task_runners);

  ~PlatformViewIOS();

  PlatformMessageRouter& GetPlatformMessageRouter();

  fml::WeakPtr<FlutterViewController> GetOwnerViewController() const;
  void SetOwnerViewController(fml::WeakPtr<FlutterViewController> owner_controller);

  void RegisterExternalTexture(int64_t id, NSObject<FlutterTexture>* texture);

  fml::scoped_nsprotocol<FlutterTextInputPlugin*> GetTextInputPlugin() const;

  void SetTextInputPlugin(fml::scoped_nsprotocol<FlutterTextInputPlugin*> plugin);

 private:
  fml::WeakPtr<FlutterViewController> owner_controller_;
  std::unique_ptr<IOSSurface> ios_surface_;
  PlatformMessageRouter platform_message_router_;
  std::unique_ptr<AccessibilityBridge> accessibility_bridge_;
  fml::scoped_nsprotocol<FlutterTextInputPlugin*> text_input_plugin_;
  fml::closure firstFrameCallback_;

  // |shell::PlatformView|
  void HandlePlatformMessage(fml::RefPtr<blink::PlatformMessage> message) override;

  // |shell::PlatformView|
  std::unique_ptr<Surface> CreateRenderingSurface() override;

  // |shell::PlatformView|
  sk_sp<GrContext> CreateResourceContext() const override;

  // |shell::PlatformView|
  void SetSemanticsEnabled(bool enabled) override;

  // |shell::PlatformView|
  void SetAccessibilityFeatures(int32_t flags) override;

  // |shell::PlatformView|
  void UpdateSemantics(blink::SemanticsNodeUpdates update,
                       blink::CustomAccessibilityActionUpdates actions) override;

  // |shell::PlatformView|
  std::unique_ptr<VsyncWaiter> CreateVSyncWaiter() override;

  FML_DISALLOW_COPY_AND_ASSIGN(PlatformViewIOS);
};

}  // namespace shell

#endif  // SHELL_PLATFORM_IOS_PLATFORM_VIEW_IOS_H_
