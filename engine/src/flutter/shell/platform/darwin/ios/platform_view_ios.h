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
#include "flutter/shell/platform/darwin/common/framework/Headers/FlutterTexture.h"
#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterViewController.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/FlutterView.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/accessibility_bridge.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/platform_message_router.h"
#include "flutter/shell/platform/darwin/ios/ios_context.h"
#include "flutter/shell/platform/darwin/ios/ios_surface.h"
#include "flutter/shell/platform/darwin/ios/rendering_api_selection.h"

@class FlutterViewController;

namespace flutter {

/**
 * A bridge connecting the platform agnostic shell and the iOS embedding.
 *
 * The shell provides and requests for UI related data and this PlatformView subclass fulfills
 * it with iOS specific capabilities. As an example, the iOS embedding (the `FlutterEngine` and the
 * `FlutterViewController`) sends pointer data to the shell and receives the shell's request for a
 * Skia GrDirectContext and supplies it.
 *
 * Despite the name "view", this class is unrelated to UIViews on iOS and doesn't have the same
 * lifecycle. It's a long lived bridge owned by the `FlutterEngine` and can be attached and
 * detached sequentially to multiple `FlutterViewController`s and `FlutterView`s.
 */
class PlatformViewIOS final : public PlatformView {
 public:
  explicit PlatformViewIOS(PlatformView::Delegate& delegate,
                           IOSRenderingAPI rendering_api,
                           flutter::TaskRunners task_runners);

  ~PlatformViewIOS() override;

  /**
   * The `PlatformMessageRouter` is the iOS bridge connecting the shell's
   * platform agnostic `PlatformMessage` to iOS's channel message handler.
   */
  PlatformMessageRouter& GetPlatformMessageRouter();

  /**
   * Returns the `FlutterViewController` currently attached to the `FlutterEngine` owning
   * this PlatformViewIOS.
   */
  fml::WeakPtr<FlutterViewController> GetOwnerViewController() const;

  /**
   * Updates the `FlutterViewController` currently attached to the `FlutterEngine` owning
   * this PlatformViewIOS. This should be updated when the `FlutterEngine`
   * is given a new `FlutterViewController`.
   */
  void SetOwnerViewController(fml::WeakPtr<FlutterViewController> owner_controller);

  /**
   * Called one time per `FlutterViewController` when the `FlutterViewController`'s
   * UIView is first loaded.
   *
   * Can be used to perform late initialization after `FlutterViewController`'s
   * init.
   */
  void attachView();

  /**
   * Called through when an external texture such as video or camera is
   * given to the `FlutterEngine` or `FlutterViewController`.
   */
  void RegisterExternalTexture(int64_t id, NSObject<FlutterTexture>* texture);

  // |PlatformView|
  PointerDataDispatcherMaker GetDispatcherMaker() override;

  // |PlatformView|
  void SetSemanticsEnabled(bool enabled) override;

 private:
  /// Smart pointer for use with objective-c observers.
  /// This guarentees we remove the observer.
  class ScopedObserver {
   public:
    ScopedObserver();
    ~ScopedObserver();
    void reset(id<NSObject> observer);
    ScopedObserver(const ScopedObserver&) = delete;
    ScopedObserver& operator=(const ScopedObserver&) = delete;

   private:
    id<NSObject> observer_;
  };

  /// Smart pointer that guarentees we communicate clearing Accessibility
  /// information to Dart.
  class AccessibilityBridgePtr {
   public:
    AccessibilityBridgePtr(const std::function<void(bool)>& set_semantics_enabled);
    AccessibilityBridgePtr(const std::function<void(bool)>& set_semantics_enabled,
                           AccessibilityBridge* bridge);
    ~AccessibilityBridgePtr();
    explicit operator bool() const noexcept { return static_cast<bool>(accessibility_bridge_); }
    AccessibilityBridge* operator->() const noexcept { return accessibility_bridge_.get(); }
    void reset(AccessibilityBridge* bridge = nullptr);

   private:
    FML_DISALLOW_COPY_AND_ASSIGN(AccessibilityBridgePtr);
    std::unique_ptr<AccessibilityBridge> accessibility_bridge_;
    std::function<void(bool)> set_semantics_enabled_;
  };

  fml::WeakPtr<FlutterViewController> owner_controller_;
  // Since the `ios_surface_` is created on the platform thread but
  // used on the raster thread we need to protect it with a mutex.
  std::mutex ios_surface_mutex_;
  std::unique_ptr<IOSSurface> ios_surface_;
  std::shared_ptr<IOSContext> ios_context_;
  PlatformMessageRouter platform_message_router_;
  AccessibilityBridgePtr accessibility_bridge_;
  fml::scoped_nsprotocol<FlutterTextInputPlugin*> text_input_plugin_;
  fml::closure firstFrameCallback_;
  ScopedObserver dealloc_view_controller_observer_;
  std::vector<std::string> platform_resolved_locale_;

  // |PlatformView|
  void HandlePlatformMessage(fml::RefPtr<flutter::PlatformMessage> message) override;

  // |PlatformView|
  std::unique_ptr<Surface> CreateRenderingSurface() override;

  // |PlatformView|
  sk_sp<GrDirectContext> CreateResourceContext() const override;

  // |PlatformView|
  void SetAccessibilityFeatures(int32_t flags) override;

  // |PlatformView|
  void UpdateSemantics(flutter::SemanticsNodeUpdates update,
                       flutter::CustomAccessibilityActionUpdates actions) override;

  // |PlatformView|
  std::unique_ptr<VsyncWaiter> CreateVSyncWaiter() override;

  // |PlatformView|
  void OnPreEngineRestart() const override;

  // |PlatformView|
  std::unique_ptr<std::vector<std::string>> ComputePlatformResolvedLocales(
      const std::vector<std::string>& supported_locale_data) override;

  FML_DISALLOW_COPY_AND_ASSIGN(PlatformViewIOS);
};

}  // namespace flutter

#endif  // SHELL_PLATFORM_IOS_PLATFORM_VIEW_IOS_H_
