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
#include "flutter/shell/platform/darwin/ios/ios_surface_metal_impeller.h"
#include "flutter/shell/gpu/gpu_surface_metal_impeller.h"
#include "flutter/impeller/renderer/backend/metal/formats_mtl.h"
#import "flutter/shell/platform/darwin/common/InternalFlutterSwiftCommon/InternalFlutterSwiftCommon.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterViewController_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/vsync_waiter_ios.h"


FLUTTER_ASSERT_ARC

namespace flutter {

IOSSurfacesManager::IOSSurfacesManager(const std::shared_ptr<IOSContext>& context)
    : impeller_context_(context ? context->GetImpellerContext() : nullptr),
      aiks_context_(context ? context->GetAiksContext() : nullptr) {
  if (!impeller_context_ || !aiks_context_) {
    return;
  }
}

void IOSSurfacesManager::AddSurface(int64_t view_id, std::unique_ptr<IOSSurface> surface) {
//  std::lock_guard<std::mutex> guard(ios_surface_mutex_);
  std::unique_lock<std::shared_mutex> lock(ios_surface_mutex_);
  ios_surfaces_.emplace(view_id, std::move(surface));
}

void IOSSurfacesManager::RemoveSurface(int64_t view_id) {
//  std::lock_guard<std::mutex> guard(ios_surface_mutex_);
  std::unique_lock<std::shared_mutex> lock(ios_surface_mutex_);
  ios_surfaces_.erase(view_id);
}

IOSSurface* IOSSurfacesManager::GetSurface(int64_t view_id) const {
//  std::lock_guard<std::mutex> guard(ios_surface_mutex_);
  std::shared_lock<std::shared_mutex> lock(ios_surface_mutex_);
  auto iter = ios_surfaces_.find(view_id);
  if (iter != ios_surfaces_.end()) {
      return iter->second.get();
  }

  return nullptr;
}

std::unique_ptr<Surface> IOSSurfacesManager::CreateGPUSurface() {
  auto iter = ios_surfaces_.find(kFlutterImplicitViewId);
  if (iter != ios_surfaces_.end()) {
    auto *ios_surface = static_cast<IOSSurfaceMetalImpeller *>(iter->second.get());
    impeller_context_->UpdateOffscreenLayerPixelFormat(
      impeller::FromMTLPixelFormat(ios_surface->GetPixelFormat()));
  }

  IOSSurfacesManager* surfaces_manager_ptr = this;
  return std::make_unique<GPUSurfaceMetalImpeller>(
             nullptr,          //
             aiks_context_, //
             true,          //
             [surfaces_manager_ptr](int64_t view_id) {               // get_gpu_surface_delegate
                  auto *surface = surfaces_manager_ptr->GetSurface(view_id);
                  return static_cast<IOSSurfaceMetalImpeller *>(surface);;
              });
}

PlatformViewIOS::PlatformViewIOS(PlatformView::Delegate& delegate,
                                 const std::shared_ptr<IOSContext>& context,
                                 __weak FlutterPlatformViewsController* platform_views_controller,
                                 const flutter::TaskRunners& task_runners)
    : PlatformView(delegate, task_runners),
      ios_context_(context),
      platform_views_controller_(platform_views_controller),
      platform_message_handler_(
          new PlatformMessageHandlerIos(task_runners.GetPlatformTaskRunner())),
      ios_surfaces_manager_(std::make_unique<IOSSurfacesManager>(context)),
      viewControllers_([NSMapTable weakToWeakObjectsMapTable]) {}

PlatformViewIOS::PlatformViewIOS(
    PlatformView::Delegate& delegate,
    IOSRenderingAPI rendering_api,
    __weak FlutterPlatformViewsController* platform_views_controller,
    const flutter::TaskRunners& task_runners,
    const std::shared_ptr<fml::ConcurrentTaskRunner>& worker_task_runner,
    const std::shared_ptr<const fml::SyncSwitch>& is_gpu_disabled_sync_switch)
    : PlatformViewIOS(delegate,
                      IOSContext::Create(rendering_api,
                                         delegate.OnPlatformViewGetSettings().enable_impeller
                                             ? IOSRenderingBackend::kImpeller
                                             : IOSRenderingBackend::kSkia,
                                         is_gpu_disabled_sync_switch,
                                         delegate.OnPlatformViewGetSettings()),
                      platform_views_controller,
                      task_runners) {}

PlatformViewIOS::~PlatformViewIOS() = default;

// |PlatformView|
void PlatformViewIOS::HandlePlatformMessage(std::unique_ptr<flutter::PlatformMessage> message) {
  platform_message_handler_->HandlePlatformMessage(std::move(message));
}

FlutterViewController* PlatformViewIOS::GetOwnerViewController() const {
  return owner_controller_;
}

void PlatformViewIOS::SetOwnerViewController(__weak FlutterViewController* owner_controller) {
  FML_DCHECK(task_runners_.GetPlatformTaskRunner()->RunsTasksOnCurrentThread());



  std::lock_guard<std::mutex> guard(ios_surface_mutex_);
  // if (ios_surface_ || !owner_controller) {
  //   NotifyDestroyed();
  //   ios_surface_.reset();
  //   accessibility_bridge_.reset();
  // }
  // owner_controller_ = owner_controller;

  FlutterViewIdentifier viewIdentifier = owner_controller.viewIdentifier;
  // NSAssert([viewControllers_ objectForKey:@(viewIdentifier)] == nil,
  //          @"The requested view ID is occupied.");
  [viewControllers_ setObject:owner_controller forKey:@(viewIdentifier)];

  // Add an observer that will clear out the owner_controller_ ivar and
  // the accessibility_bridge_ in case the view controller is deleted.
  dealloc_view_controller_observer_.reset([[NSNotificationCenter defaultCenter]
      addObserverForName:FlutterViewControllerWillDealloc
                  object:owner_controller_
                   queue:[NSOperationQueue mainQueue]
              usingBlock:^(NSNotification* note) {
                FlutterViewController* owner_controller =
                  (FlutterViewController*)note.object;
                if (owner_controller.viewIdentifier == kFlutterImplicitViewId) {
                // Implicit copy of 'this' is fine.
                accessibility_bridge_.reset();
                }

                // owner_controller_ = nil;
              }]);

  if (owner_controller && owner_controller.isViewLoaded) {
    this->attachView(viewIdentifier);
  }
  // Do not call `NotifyCreated()` here - let FlutterViewController take care
  // of that when its Viewport is sized.  If `NotifyCreated()` is called here,
  // it can occasionally get invoked before the viewport is sized resulting in
  // a framebuffer that will not be able to completely attach.
}

void PlatformViewIOS::AddOwnerViewController(__weak FlutterViewController* owner_controller) {
  FML_DCHECK(task_runners_.GetPlatformTaskRunner()->RunsTasksOnCurrentThread());

  // if (accessibility_bridge_) {
  //   accessibility_bridge_ = std::make_unique<AccessibilityBridge>(
  //       owner_controller_, this, owner_controller_.platformViewsController);
  std::lock_guard<std::mutex> guard(ios_surface_mutex_);
  // if (ios_surface_ || !owner_controller) {
  //   NotifyDestroyed();
  //   ios_surface_.reset();
  //   accessibility_bridge_.Clear();
  // }
  // owner_controller_ = owner_controller;
  FlutterViewIdentifier viewIdentifier = owner_controller.viewIdentifier;
  FML_DCHECK([viewControllers_ objectForKey:@(viewIdentifier)] == nil);
//   NSAssert([viewControllers_ objectForKey:@(viewIdentifier)] == nil,
//            @"The requested view ID is occupied.");
  [viewControllers_ setObject:owner_controller forKey:@(viewIdentifier)];

  if (owner_controller.viewIdentifier == kFlutterImplicitViewId) {
  if (accessibility_bridge_) {
    accessibility_bridge_ = std::make_unique<AccessibilityBridge>(
        owner_controller, this, owner_controller.platformViewsController);
  }


    // Add an observer that will clear out the owner_controller_ ivar and
    // the accessibility_bridge_ in case the view controller is deleted.
    dealloc_view_controller_observer_.reset([[NSNotificationCenter defaultCenter]
        addObserverForName:FlutterViewControllerWillDealloc
                    object:owner_controller
                     queue:[NSOperationQueue mainQueue]
                usingBlock:^(NSNotification* note) {
                  // Implicit copy of 'this' is fine.
                  FlutterViewController* owner_controller =
                    (FlutterViewController*)note.object;
                  if (owner_controller.viewIdentifier == kFlutterImplicitViewId) {
                    // accessibility_bridge_.Clear();
                    accessibility_bridge_.reset();
                  }

                  // owner_controller_ = nil;
                }]);
  }

  if (owner_controller && owner_controller.isViewLoaded) {
    this->attachView(viewIdentifier);
  }
  // Do not call `NotifyCreated()` here - let FlutterViewController take care
  // of that when its Viewport is sized.  If `NotifyCreated()` is called here,
  // it can occasionally get invoked before the viewport is sized resulting in
  // a framebuffer that will not be able to completely attach.
}

void PlatformViewIOS::RemoveOwnerViewController(FlutterViewIdentifier viewIdentifier) {
  FML_DCHECK(task_runners_.GetPlatformTaskRunner()->RunsTasksOnCurrentThread());

  std::lock_guard<std::mutex> guard(ios_surface_mutex_);
//  FlutterViewController* owner_controller = [viewControllers_ objectForKey:@(viewIdentifier)];
//  FML_DCHECK(owner_controller);

  if (viewIdentifier == kFlutterImplicitViewId) {
    NotifyDestroyed();
    accessibility_bridge_.reset();
  }

  [viewControllers_ removeObjectForKey:@(viewIdentifier)];
  ios_surfaces_manager_->RemoveSurface(viewIdentifier);

//   if (ios_surfaces_manager_ || !owner_controller) {
//     NotifyDestroyed();
//     ios_surface_.reset();
//     accessibility_bridge_.Clear();
//   }
}

void PlatformViewIOS::attachView(FlutterViewIdentifier viewIdentifier) {
  FlutterViewController* owner_controller =
      [viewControllers_ objectForKey:@(viewIdentifier)];
  FML_DCHECK(owner_controller);
  FML_DCHECK(owner_controller.isViewLoaded) << "FlutterViewController's view should be loaded "
                                                "before attaching to PlatformViewIOS.";
  FlutterView* flutter_view = static_cast<FlutterView*>(owner_controller.view);
  CALayer* ca_layer = flutter_view.layer;
  // ios_surface_ = IOSSurface::Create(ios_context_, ca_layer);
  auto ios_surface = IOSSurface::Create(ios_context_, ca_layer);
  FML_DCHECK(ios_surface != nullptr);
  // kFlutterImplicitViewId
  ios_surfaces_manager_->AddSurface( viewIdentifier, std::move(ios_surface));

  // TODO: Make `AccessibilityBridge` support multi-view.
  if (viewIdentifier == kFlutterImplicitViewId) {
    if (accessibility_bridge_) {
      accessibility_bridge_.reset(
          new AccessibilityBridge(owner_controller, this, platform_views_controller_));
    }
  }
}

PointerDataDispatcherMaker PlatformViewIOS::GetDispatcherMaker() {
  return [](DefaultPointerDataDispatcher::Delegate& delegate) {
    return std::make_unique<SmoothPointerDataDispatcher>(delegate);
  };
}

void PlatformViewIOS::RegisterExternalTexture(int64_t texture_id,
                                              NSObject<FlutterTexture>* texture) {
  RegisterTexture(ios_context_->CreateExternalTexture(texture_id, texture));
}

// |PlatformView|
std::unique_ptr<Surface> PlatformViewIOS::CreateRenderingSurface() {
  FML_DCHECK(task_runners_.GetRasterTaskRunner()->RunsTasksOnCurrentThread());
  std::lock_guard<std::mutex> guard(ios_surface_mutex_);
  // if (!ios_surface_) {
  //   FML_DLOG(INFO) << "Could not CreateRenderingSurface, this PlatformViewIOS "
  //                     "has no ViewController.";
  //   return nullptr;
  // }
  if (!ios_surfaces_manager_) {
    FML_DLOG(INFO) << "Could not CreateRenderingSurface, this PlatformViewIOS "
                      "has no ViewController.";
    return nullptr;
  }
  return ios_surfaces_manager_->CreateGPUSurface();
}

// |PlatformView|
std::shared_ptr<ExternalViewEmbedder> PlatformViewIOS::CreateExternalViewEmbedder() {
  return std::make_shared<IOSExternalViewEmbedder>(platform_views_controller_, ios_context_);
}

// |PlatformView|
std::shared_ptr<impeller::Context> PlatformViewIOS::GetImpellerContext() const {
  return ios_context_->GetImpellerContext();
}

// |PlatformView|
void PlatformViewIOS::SetSemanticsEnabled(bool enabled) {
  PlatformView::SetSemanticsEnabled(enabled);
}

// |PlatformView|
void PlatformViewIOS::SetAccessibilityFeatures(int32_t flags) {
  PlatformView::SetAccessibilityFeatures(flags);
}

// |PlatformView|
void PlatformViewIOS::UpdateSemantics(int64_t view_id,
                                      flutter::SemanticsNodeUpdates update,
                                      flutter::CustomAccessibilityActionUpdates actions) {
  FlutterViewController* owner_controller =
      [viewControllers_ objectForKey:@(view_id)];
  FML_DCHECK(owner_controller);
  if (accessibility_bridge_) {
    accessibility_bridge_.get()->UpdateSemantics(std::move(update), actions);
    [[NSNotificationCenter defaultCenter] postNotificationName:FlutterSemanticsUpdateNotification
                                                        object:owner_controller];
  }
}

// |PlatformView|
void PlatformViewIOS::SetSemanticsTreeEnabled(bool enabled) {
  FlutterViewController* owner_controller = [viewControllers_ objectForKey:@(kFlutterImplicitViewId)];
//  FML_DCHECK(owner_controller);
  if (owner_controller) {
    if (enabled) {
      if (accessibility_bridge_) {
        return;
      }
      accessibility_bridge_ =
          std::make_unique<AccessibilityBridge>(owner_controller, this, platform_views_controller_);
    } else {
      accessibility_bridge_.reset();
    }
  }
}

// |PlatformView|
std::unique_ptr<VsyncWaiter> PlatformViewIOS::CreateVSyncWaiter() {
  return std::make_unique<VsyncWaiterIOS>(task_runners_);
}

void PlatformViewIOS::OnPreEngineRestart() const {
  if (accessibility_bridge_) {
    accessibility_bridge_.get()->clearState();
  }
  if (!owner_controller_) {
    return;
  }
  [owner_controller_.platformViewsController reset];
  [owner_controller_.restorationPlugin reset];
  [owner_controller_.textInputPlugin reset];
}

std::unique_ptr<std::vector<std::string>> PlatformViewIOS::ComputePlatformResolvedLocales(
    const std::vector<std::string>& supported_locale_data) {
  size_t localeDataLength = 3;
  NSMutableArray<NSString*>* supported_locale_identifiers =
      [NSMutableArray arrayWithCapacity:supported_locale_data.size() / localeDataLength];
  for (size_t i = 0; i < supported_locale_data.size(); i += localeDataLength) {
    NSDictionary<NSString*, NSString*>* dict = @{
      NSLocaleLanguageCode : [NSString stringWithUTF8String:supported_locale_data[i].c_str()]
          ?: @"",
      NSLocaleCountryCode : [NSString stringWithUTF8String:supported_locale_data[i + 1].c_str()]
          ?: @"",
      NSLocaleScriptCode : [NSString stringWithUTF8String:supported_locale_data[i + 2].c_str()]
          ?: @""
    };
    [supported_locale_identifiers addObject:[NSLocale localeIdentifierFromComponents:dict]];
  }
  NSArray<NSString*>* result =
      [NSBundle preferredLocalizationsFromArray:supported_locale_identifiers];

  // Output format should be either empty or 3 strings for language, country, and script.
  std::unique_ptr<std::vector<std::string>> out = std::make_unique<std::vector<std::string>>();

  if (result != nullptr && [result count] > 0) {
    NSLocale* locale = [NSLocale localeWithLocaleIdentifier:[result firstObject]];
    NSString* languageCode = [locale languageCode];
    out->emplace_back(languageCode == nullptr ? "" : languageCode.UTF8String);
    NSString* countryCode = [locale countryCode];
    out->emplace_back(countryCode == nullptr ? "" : countryCode.UTF8String);
    NSString* scriptCode = [locale scriptCode];
    out->emplace_back(scriptCode == nullptr ? "" : scriptCode.UTF8String);
  }
  return out;
}

  // void PlatformViewIOS::NotifyCreated(int64_t view_id) {}

  // void PlatformViewIOS::NotifyDestroyed(int64_t view_id) {}

PlatformViewIOS::ScopedObserver::ScopedObserver() {}

PlatformViewIOS::ScopedObserver::~ScopedObserver() {
  if (observer_) {
    [[NSNotificationCenter defaultCenter] removeObserver:observer_];
  }
}

void PlatformViewIOS::ScopedObserver::reset(id<NSObject> observer) {
  if (observer != observer_) {
    if (observer_) {
      [[NSNotificationCenter defaultCenter] removeObserver:observer_];
    }
    observer_ = observer;
  }
}

}  // namespace flutter
