// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/platform_view_ios.h"
#include <memory>

#include <utility>

#include "flutter/common/task_runners.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/trace_event.h"
#include "flutter/shell/common/shell_io_manager.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterViewController_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/vsync_waiter_ios.h"

namespace flutter {

PlatformViewIOS::AccessibilityBridgePtr::AccessibilityBridgePtr(
    const std::function<void(bool)>& set_semantics_enabled)
    : AccessibilityBridgePtr(set_semantics_enabled, nullptr) {}

PlatformViewIOS::AccessibilityBridgePtr::AccessibilityBridgePtr(
    const std::function<void(bool)>& set_semantics_enabled,
    AccessibilityBridge* bridge)
    : accessibility_bridge_(bridge), set_semantics_enabled_(set_semantics_enabled) {
  if (bridge) {
    set_semantics_enabled_(true);
  }
}

PlatformViewIOS::AccessibilityBridgePtr::~AccessibilityBridgePtr() {
  if (accessibility_bridge_) {
    set_semantics_enabled_(false);
  }
}

void PlatformViewIOS::AccessibilityBridgePtr::reset(AccessibilityBridge* bridge) {
  if (accessibility_bridge_) {
    set_semantics_enabled_(false);
  }
  accessibility_bridge_.reset(bridge);
  if (accessibility_bridge_) {
    set_semantics_enabled_(true);
  }
}

PlatformViewIOS::PlatformViewIOS(
    PlatformView::Delegate& delegate,
    IOSRenderingAPI rendering_api,
    const std::shared_ptr<FlutterPlatformViewsController>& platform_views_controller,
    flutter::TaskRunners task_runners)
    : PlatformView(delegate, std::move(task_runners)),
      ios_context_(IOSContext::Create(rendering_api)),
      platform_views_controller_(platform_views_controller),
      accessibility_bridge_([this](bool enabled) { PlatformView::SetSemanticsEnabled(enabled); }) {}

PlatformViewIOS::~PlatformViewIOS() = default;

PlatformMessageRouter& PlatformViewIOS::GetPlatformMessageRouter() {
  return platform_message_router_;
}

// |PlatformView|
void PlatformViewIOS::HandlePlatformMessage(fml::RefPtr<flutter::PlatformMessage> message) {
  platform_message_router_.HandlePlatformMessage(std::move(message));
}

fml::WeakPtr<FlutterViewController> PlatformViewIOS::GetOwnerViewController() const {
  return owner_controller_;
}

void PlatformViewIOS::SetOwnerViewController(fml::WeakPtr<FlutterViewController> owner_controller) {
  FML_DCHECK(task_runners_.GetPlatformTaskRunner()->RunsTasksOnCurrentThread());
  std::lock_guard<std::mutex> guard(ios_surface_mutex_);
  if (ios_surface_ || !owner_controller) {
    NotifyDestroyed();
    ios_surface_.reset();
    accessibility_bridge_.reset();
  }
  owner_controller_ = owner_controller;

  // Add an observer that will clear out the owner_controller_ ivar and
  // the accessibility_bridge_ in case the view controller is deleted.
  dealloc_view_controller_observer_.reset(
      [[[NSNotificationCenter defaultCenter] addObserverForName:FlutterViewControllerWillDealloc
                                                         object:owner_controller_.get()
                                                          queue:[NSOperationQueue mainQueue]
                                                     usingBlock:^(NSNotification* note) {
                                                       // Implicit copy of 'this' is fine.
                                                       accessibility_bridge_.reset();
                                                       owner_controller_.reset();
                                                     }] retain]);

  if (owner_controller_ && [owner_controller_.get() isViewLoaded]) {
    this->attachView();
  }
  // Do not call `NotifyCreated()` here - let FlutterViewController take care
  // of that when its Viewport is sized.  If `NotifyCreated()` is called here,
  // it can occasionally get invoked before the viewport is sized resulting in
  // a framebuffer that will not be able to completely attach.
}

void PlatformViewIOS::attachView() {
  FML_DCHECK(owner_controller_);
  FML_DCHECK(owner_controller_.get().isViewLoaded)
      << "FlutterViewController's view should be loaded "
         "before attaching to PlatformViewIOS.";
  auto flutter_view = static_cast<FlutterView*>(owner_controller_.get().view);
  auto ca_layer = fml::scoped_nsobject<CALayer>{[[flutter_view layer] retain]};
  ios_surface_ = IOSSurface::Create(ios_context_, ca_layer);
  FML_DCHECK(ios_surface_ != nullptr);

  if (accessibility_bridge_) {
    accessibility_bridge_.reset(new AccessibilityBridge(
        owner_controller_.get(), this, [owner_controller_.get() platformViewsController]));
  }
}

PointerDataDispatcherMaker PlatformViewIOS::GetDispatcherMaker() {
  return [](DefaultPointerDataDispatcher::Delegate& delegate) {
    return std::make_unique<SmoothPointerDataDispatcher>(delegate);
  };
}

void PlatformViewIOS::RegisterExternalTexture(int64_t texture_id,
                                              NSObject<FlutterTexture>* texture) {
  RegisterTexture(ios_context_->CreateExternalTexture(
      texture_id, fml::scoped_nsobject<NSObject<FlutterTexture>>{[texture retain]}));
}

// |PlatformView|
std::unique_ptr<Surface> PlatformViewIOS::CreateRenderingSurface() {
  FML_DCHECK(task_runners_.GetRasterTaskRunner()->RunsTasksOnCurrentThread());
  std::lock_guard<std::mutex> guard(ios_surface_mutex_);
  if (!ios_surface_) {
    FML_DLOG(INFO) << "Could not CreateRenderingSurface, this PlatformViewIOS "
                      "has no ViewController.";
    return nullptr;
  }
  return ios_surface_->CreateGPUSurface();
}

// |PlatformView|
std::shared_ptr<ExternalViewEmbedder> PlatformViewIOS::CreateExternalViewEmbedder() {
  return std::make_shared<IOSExternalViewEmbedder>(platform_views_controller_, ios_context_);
}

// |PlatformView|
sk_sp<GrDirectContext> PlatformViewIOS::CreateResourceContext() const {
  return ios_context_->CreateResourceContext();
}

// |PlatformView|
void PlatformViewIOS::SetSemanticsEnabled(bool enabled) {
  if (!owner_controller_) {
    FML_LOG(WARNING) << "Could not set semantics to enabled, this "
                        "PlatformViewIOS has no ViewController.";
    return;
  }
  if (enabled && !accessibility_bridge_) {
    accessibility_bridge_.reset(new AccessibilityBridge(
        owner_controller_.get(), this, [owner_controller_.get() platformViewsController]));
  } else if (!enabled && accessibility_bridge_) {
    accessibility_bridge_.reset();
  } else {
    PlatformView::SetSemanticsEnabled(enabled);
  }
}

// |shell:PlatformView|
void PlatformViewIOS::SetAccessibilityFeatures(int32_t flags) {
  PlatformView::SetAccessibilityFeatures(flags);
}

// |PlatformView|
void PlatformViewIOS::UpdateSemantics(flutter::SemanticsNodeUpdates update,
                                      flutter::CustomAccessibilityActionUpdates actions) {
  FML_DCHECK(owner_controller_);
  if (accessibility_bridge_) {
    accessibility_bridge_->UpdateSemantics(std::move(update), std::move(actions));
    [[NSNotificationCenter defaultCenter] postNotificationName:FlutterSemanticsUpdateNotification
                                                        object:owner_controller_.get()];
  }
}

// |PlatformView|
std::unique_ptr<VsyncWaiter> PlatformViewIOS::CreateVSyncWaiter() {
  return std::make_unique<VsyncWaiterIOS>(task_runners_);
}

void PlatformViewIOS::OnPreEngineRestart() const {
  if (accessibility_bridge_) {
    accessibility_bridge_->clearState();
  }
  if (!owner_controller_) {
    return;
  }
  [owner_controller_.get() platformViewsController]->Reset();
}

std::unique_ptr<std::vector<std::string>> PlatformViewIOS::ComputePlatformResolvedLocales(
    const std::vector<std::string>& supported_locale_data) {
  size_t localeDataLength = 3;
  NSMutableArray<NSString*>* supported_locale_identifiers =
      [NSMutableArray arrayWithCapacity:supported_locale_data.size() / localeDataLength];
  for (size_t i = 0; i < supported_locale_data.size(); i += localeDataLength) {
    NSDictionary<NSString*, NSString*>* dict = @{
      NSLocaleLanguageCode : [NSString stringWithUTF8String:supported_locale_data[i].c_str()],
      NSLocaleCountryCode : [NSString stringWithUTF8String:supported_locale_data[i + 1].c_str()],
      NSLocaleScriptCode : [NSString stringWithUTF8String:supported_locale_data[i + 2].c_str()]
    };
    [supported_locale_identifiers addObject:[NSLocale localeIdentifierFromComponents:dict]];
  }
  NSArray<NSString*>* result =
      [NSBundle preferredLocalizationsFromArray:supported_locale_identifiers];

  // Output format should be either empty or 3 strings for language, country, and script.
  std::unique_ptr<std::vector<std::string>> out = std::make_unique<std::vector<std::string>>();

  if (result != nullptr && [result count] > 0) {
    if (@available(ios 10.0, *)) {
      NSLocale* locale = [NSLocale localeWithLocaleIdentifier:[result firstObject]];
      NSString* languageCode = [locale languageCode];
      out->emplace_back(languageCode == nullptr ? "" : languageCode.UTF8String);
      NSString* countryCode = [locale countryCode];
      out->emplace_back(countryCode == nullptr ? "" : countryCode.UTF8String);
      NSString* scriptCode = [locale scriptCode];
      out->emplace_back(scriptCode == nullptr ? "" : scriptCode.UTF8String);
    }
  }
  return out;
}

PlatformViewIOS::ScopedObserver::ScopedObserver() : observer_(nil) {}

PlatformViewIOS::ScopedObserver::~ScopedObserver() {
  if (observer_) {
    [[NSNotificationCenter defaultCenter] removeObserver:observer_];
    [observer_ release];
  }
}

void PlatformViewIOS::ScopedObserver::reset(id<NSObject> observer) {
  if (observer != observer_) {
    if (observer_) {
      [[NSNotificationCenter defaultCenter] removeObserver:observer_];
      [observer_ release];
    }
    observer_ = observer;
  }
}

}  // namespace flutter
