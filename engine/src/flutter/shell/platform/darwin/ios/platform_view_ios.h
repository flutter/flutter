// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_IOS_PLATFORM_VIEW_IOS_H_
#define SHELL_PLATFORM_IOS_PLATFORM_VIEW_IOS_H_

#include <memory>

#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/accessibility_bridge.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/platform_message_router.h"
#include "flutter/shell/platform/darwin/ios/ios_surface.h"
#include "lib/fxl/functional/closure.h"
#include "lib/fxl/macros.h"

@class CALayer;
@class UIView;

namespace shell {

class PlatformViewIOS : public PlatformView {
 public:
  explicit PlatformViewIOS(CALayer* layer,
                           NSObject<FlutterBinaryMessenger>* binaryMessenger);

  ~PlatformViewIOS() override;

  void Attach() override;

  void Attach(fxl::Closure firstFrameCallback);

  void NotifyCreated();

  void ToggleAccessibility(UIView* view, bool enabled);

  PlatformMessageRouter& platform_message_router() {
    return platform_message_router_;
  }

  fml::WeakPtr<PlatformViewIOS> GetWeakPtr();

  void UpdateSurfaceSize();

  VsyncWaiter* GetVsyncWaiter() override;

  bool ResourceContextMakeCurrent() override;

  void HandlePlatformMessage(
      fxl::RefPtr<blink::PlatformMessage> message) override;

  void UpdateSemantics(std::vector<blink::SemanticsNode> update) override;

  void RunFromSource(const std::string& assets_directory,
                     const std::string& main,
                     const std::string& packages) override;

  NSObject<FlutterBinaryMessenger>* binary_messenger() const {
    return binary_messenger_;
  }

 private:
  std::unique_ptr<IOSSurface> ios_surface_;
  PlatformMessageRouter platform_message_router_;
  std::unique_ptr<AccessibilityBridge> accessibility_bridge_;
  fxl::Closure firstFrameCallback_;
  fml::WeakPtrFactory<PlatformViewIOS> weak_factory_;
  NSObject<FlutterBinaryMessenger>* binary_messenger_;

  void SetupAndLoadFromSource(const std::string& assets_directory,
                              const std::string& main,
                              const std::string& packages);

  FXL_DISALLOW_COPY_AND_ASSIGN(PlatformViewIOS);
};

}  // namespace shell

#endif  // SHELL_PLATFORM_IOS_PLATFORM_VIEW_IOS_H_
