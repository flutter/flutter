// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/platform_view_ios.h"
#include <memory>
#include <mutex>
#include <shared_mutex>
#include <unordered_map>
#include <utility>

#include "flutter/common/constants.h"
#include "flutter/common/task_runners.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/trace_event.h"
#include "flutter/shell/common/shell_io_manager.h"
#include "flutter/shell/gpu/gpu_surface_metal_impeller.h"
#import "flutter/shell/platform/darwin/common/InternalFlutterSwiftCommon/InternalFlutterSwiftCommon.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterViewController_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/vsync_waiter_ios.h"

FLUTTER_ASSERT_ARC

namespace flutter {

namespace {

// The root surface never presents to a view, so its delegate must not depend on any view's layer.
class IOSRootSurfaceMetalDelegate final : public GPUSurfaceMetalDelegate {
 public:
  IOSRootSurfaceMetalDelegate() : GPUSurfaceMetalDelegate(MTLRenderTargetType::kCAMetalLayer) {}

  GPUCAMetalLayerHandle GetCAMetalLayer(const DlISize& frame_size) const override {
    FML_DCHECK(false);
    return nullptr;
  }

  bool PresentDrawable(GrMTLHandle drawable) const override {
    FML_DCHECK(false);
    return false;
  }

  GPUMTLTextureInfo GetMTLTexture(const DlISize& frame_size) const override {
    FML_DCHECK(false);
    return {};
  }

  bool PresentTexture(GPUMTLTextureInfo texture) const override {
    FML_DCHECK(false);
    return false;
  }

  bool AllowsDrawingWhenGpuDisabled() const override { return false; }
};

}  // namespace

class IOSSurfacesManager {
 public:
  enum class SurfaceCreationResult {
    kAlreadyExists,
    kFailed,
    kFirstSurfaceCreated,
    kAdditionalSurfaceCreated,
  };

  enum class SurfaceDestructionResult {
    kNotFound,
    kSurfaceDestroyed,
    kLastSurfaceDestroyed,
  };

  explicit IOSSurfacesManager(const std::shared_ptr<IOSContext>& context)
      : aiks_context_(context->GetAiksContext()) {}

  ~IOSSurfacesManager() = default;

  void AddSurface(int64_t view_id, std::unique_ptr<IOSSurface> surface) {
    std::unique_lock<std::shared_mutex> lock(ios_surface_mutex_);
    ios_surfaces_.emplace(view_id, std::move(surface));
  }

  void RemoveSurface(int64_t view_id) {
    std::unique_lock<std::shared_mutex> lock(ios_surface_mutex_);
    ios_surfaces_.erase(view_id);
  }

  std::unique_ptr<Surface> CreateRootSurface() {
    return std::make_unique<GPUSurfaceMetalImpeller>(&root_surface_delegate_, aiks_context_,
                                                     /*render_to_surface=*/false);
  }

  // Rendering surfaces are only accessed on the raster thread.
  SurfaceCreationResult CreateRenderingSurfaceForView(int64_t view_id) {
    if (rendering_surfaces_.find(view_id) != rendering_surfaces_.end()) {
      return SurfaceCreationResult::kAlreadyExists;
    }
    if (!aiks_context_ || !aiks_context_->IsValid()) {
      return SurfaceCreationResult::kFailed;
    }

    std::shared_lock<std::shared_mutex> lock(ios_surface_mutex_);
    auto iter = ios_surfaces_.find(view_id);
    if (iter == ios_surfaces_.end() || !iter->second->IsValid()) {
      return SurfaceCreationResult::kFailed;
    }

    auto surface = iter->second->CreateGPUSurface();
    if (!surface || !surface->IsValid()) {
      return SurfaceCreationResult::kFailed;
    }
    bool is_first_surface = rendering_surfaces_.empty();
    rendering_surfaces_.emplace(view_id, std::move(surface));
    return is_first_surface ? SurfaceCreationResult::kFirstSurfaceCreated
                            : SurfaceCreationResult::kAdditionalSurfaceCreated;
  }

  SurfaceDestructionResult DestroyRenderingSurfaceForView(int64_t view_id) {
    if (rendering_surfaces_.erase(view_id) == 0) {
      return SurfaceDestructionResult::kNotFound;
    }
    return rendering_surfaces_.empty() ? SurfaceDestructionResult::kLastSurfaceDestroyed
                                       : SurfaceDestructionResult::kSurfaceDestroyed;
  }

  std::unique_ptr<SurfaceFrame> CreateSurfaceFrame(int64_t flutter_view_id, DlISize& frame_size) {
    auto iter = rendering_surfaces_.find(flutter_view_id);
    if (iter != rendering_surfaces_.end()) {
      return iter->second.get()->AcquireFrame(frame_size);
    }
    // Return a display-list-backed frame so rasterization has a non-null canvas when the target
    // surface is missing.
    return std::make_unique<SurfaceFrame>(
        nullptr, SurfaceFrame::FramebufferInfo(), [](SurfaceFrame&, DlCanvas*) { return false; },
        [](SurfaceFrame&) { return false; }, frame_size, nullptr, true);
  }

 private:
  const std::shared_ptr<impeller::AiksContext> aiks_context_;
  IOSRootSurfaceMetalDelegate root_surface_delegate_;

  std::unordered_map<int64_t, std::unique_ptr<IOSSurface>> ios_surfaces_;

  std::unordered_map<int64_t, std::unique_ptr<Surface>> rendering_surfaces_;

  // Native surfaces are added and removed on the platform thread and read on the raster thread.
  std::shared_mutex ios_surface_mutex_;

  FML_DISALLOW_COPY_AND_ASSIGN(IOSSurfacesManager);
};

PlatformViewIOS::PlatformViewIOS(PlatformView::Delegate& delegate,
                                 const std::shared_ptr<IOSContext>& context,
                                 __weak FlutterPlatformViewsController* platform_views_controller,
                                 const flutter::TaskRunners& task_runners)
    : PlatformView(delegate, task_runners),
      ios_context_(context),
      platform_views_controller_(platform_views_controller),
      platform_message_handler_(
          new PlatformMessageHandlerIos(task_runners.GetPlatformTaskRunner())),
      ios_surfaces_manager_(std::make_shared<IOSSurfacesManager>(context)),
      view_controllers_([NSMapTable weakToWeakObjectsMapTable]) {}

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

void PlatformViewIOS::NotifyViewRenderingSurfaceCreated(int64_t view_id) {
  FML_DCHECK(task_runners_.GetPlatformTaskRunner()->RunsTasksOnCurrentThread());
  auto result = IOSSurfacesManager::SurfaceCreationResult::kFailed;
  IOSSurfacesManager* surfaces_manager_ptr = ios_surfaces_manager_.get();
  fml::ManualResetWaitableEvent latch;
  fml::TaskRunner::RunNowOrPostTask(
      task_runners_.GetRasterTaskRunner(), [&latch, &result, surfaces_manager_ptr, view_id]() {
        result = surfaces_manager_ptr->CreateRenderingSurfaceForView(view_id);
        latch.Signal();
      });
  latch.Wait();
  if (result == IOSSurfacesManager::SurfaceCreationResult::kFirstSurfaceCreated) {
    NotifyCreated();
  } else if (result == IOSSurfacesManager::SurfaceCreationResult::kAdditionalSurfaceCreated) {
    ScheduleFrame();
  }
}

void PlatformViewIOS::NotifyViewRenderingSurfaceDestroyed(int64_t view_id) {
  FML_DCHECK(task_runners_.GetPlatformTaskRunner()->RunsTasksOnCurrentThread());
  auto result = IOSSurfacesManager::SurfaceDestructionResult::kNotFound;
  IOSSurfacesManager* surfaces_manager_ptr = ios_surfaces_manager_.get();
  fml::AutoResetWaitableEvent latch;
  fml::TaskRunner::RunNowOrPostTask(
      task_runners_.GetRasterTaskRunner(), [&latch, &result, surfaces_manager_ptr, view_id]() {
        result = surfaces_manager_ptr->DestroyRenderingSurfaceForView(view_id);
        latch.Signal();
      });
  latch.Wait();
  if (result == IOSSurfacesManager::SurfaceDestructionResult::kLastSurfaceDestroyed) {
    NotifyDestroyed();
  }
}

// |PlatformView|
void PlatformViewIOS::HandlePlatformMessage(std::unique_ptr<flutter::PlatformMessage> message) {
  platform_message_handler_->HandlePlatformMessage(std::move(message));
}

FlutterViewController* PlatformViewIOS::GetOwnerViewController() const {
  return [view_controllers_ objectForKey:@(flutter::kFlutterImplicitViewId)];
}

void PlatformViewIOS::SetOwnerViewController(__weak FlutterViewController* owner_controller) {
  FML_DCHECK(task_runners_.GetPlatformTaskRunner()->RunsTasksOnCurrentThread());
  FlutterViewController* existing_controller =
      [view_controllers_ objectForKey:@(flutter::kFlutterImplicitViewId)];
  if (owner_controller != nil && existing_controller == owner_controller) {
    ApplyLocaleToOwnerController();
    return;
  }

  // The weak controller may already be nil when its deallocation notification arrives.
  if (existing_controller != nil || owner_controller == nil) {
    RemoveOwnerViewController(flutter::kFlutterImplicitViewId);
  }

  if (owner_controller != nil) {
    AddOwnerViewController(owner_controller);
  }
}

void PlatformViewIOS::AddOwnerViewController(__weak FlutterViewController* owner_controller) {
  FML_DCHECK(task_runners_.GetPlatformTaskRunner()->RunsTasksOnCurrentThread());

  FlutterViewIdentifier viewIdentifier = owner_controller.viewIdentifier;
  FML_DCHECK([view_controllers_ objectForKey:@(viewIdentifier)] == nil);
  [view_controllers_ setObject:owner_controller forKey:@(viewIdentifier)];
  owner_controller.applicationLocale =
      application_locale_.empty() ? nil : @(application_locale_.data());

  if (semantics_tree_enabled_) {
    accessibility_bridges_[viewIdentifier] =
        std::make_unique<AccessibilityBridge>(owner_controller, this, platform_views_controller_);
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

  // Rendering surfaces borrow the native surface as their delegate.
  NotifyViewRenderingSurfaceDestroyed(viewIdentifier);

  [view_controllers_ removeObjectForKey:@(viewIdentifier)];
  ios_surfaces_manager_->RemoveSurface(viewIdentifier);
  [platform_views_controller_ detachFromFlutterViewController:viewIdentifier];

  auto iter = accessibility_bridges_.find(viewIdentifier);
  if (iter != accessibility_bridges_.end()) {
    accessibility_bridges_.erase(viewIdentifier);
  }
}

void PlatformViewIOS::attachView(FlutterViewIdentifier viewIdentifier) {
  FlutterViewController* owner_controller = [view_controllers_ objectForKey:@(viewIdentifier)];
  FML_DCHECK(owner_controller);
  FML_DCHECK(owner_controller.isViewLoaded) << "FlutterViewController's view should be loaded "
                                               "before attaching to PlatformViewIOS.";
  FlutterView* flutter_view = static_cast<FlutterView*>(owner_controller.view);
  CALayer* ca_layer = flutter_view.layer;
  auto ios_surface = IOSSurface::Create(ios_context_, ca_layer);
  FML_DCHECK(ios_surface != nullptr);
  ios_surfaces_manager_->AddSurface(viewIdentifier, std::move(ios_surface));

  auto iter = accessibility_bridges_.find(owner_controller.viewIdentifier);
  if (iter != accessibility_bridges_.end()) {
    accessibility_bridges_[owner_controller.viewIdentifier] =
        std::make_unique<AccessibilityBridge>(owner_controller, this, platform_views_controller_);
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
  return ios_surfaces_manager_->CreateRootSurface();
}

// |PlatformView|
std::shared_ptr<ExternalViewEmbedder> PlatformViewIOS::CreateExternalViewEmbedder() {
  IOSSurfacesManager* surfaces_manager_ptr = ios_surfaces_manager_.get();
  return std::make_shared<IOSExternalViewEmbedder>(
      platform_views_controller_, ios_context_,
      [surfaces_manager_ptr](int64_t view_id, DlISize& frame_size) {
        return surfaces_manager_ptr->CreateSurfaceFrame(view_id, frame_size);
      });
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
  FlutterViewController* owner_controller = [view_controllers_ objectForKey:@(view_id)];
  if (owner_controller) {
    auto iter = accessibility_bridges_.find(owner_controller.viewIdentifier);
    if (iter != accessibility_bridges_.end()) {
      iter->second.get()->UpdateSemantics(std::move(update), actions);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:FlutterSemanticsUpdateNotification
                                                        object:owner_controller];
  }
}

// |PlatformView|
void PlatformViewIOS::SetApplicationLocale(std::string locale) {
  application_locale_ = std::move(locale);
  ApplyLocaleToOwnerController();
}

// |PlatformView|
void PlatformViewIOS::SetSemanticsTreeEnabled(bool enabled) {
  semantics_tree_enabled_ = enabled;
  if ([view_controllers_ count] > 0) {
    NSEnumerator* e = [view_controllers_ objectEnumerator];
    FlutterViewController* controller = nil;
    while ((controller = [e nextObject])) {
      if (enabled) {
        auto iter = accessibility_bridges_.find(controller.viewIdentifier);
        if (iter != accessibility_bridges_.end()) {
          continue;
        }

        accessibility_bridges_[controller.viewIdentifier] =
            std::make_unique<AccessibilityBridge>(controller, this, platform_views_controller_);
      } else {
        accessibility_bridges_.erase(controller.viewIdentifier);
      }
    }
  }
}

// |PlatformView|
std::unique_ptr<VsyncWaiter> PlatformViewIOS::CreateVSyncWaiter() {
  return std::make_unique<VsyncWaiterIOS>(task_runners_);
}

// |PlatformView|
void PlatformViewIOS::OnPreEngineRestart() const {
  for (auto& [view_id, bridge] : accessibility_bridges_) {
    if (bridge) {
      bridge->clearState();
    }
  }

  if ([view_controllers_ count] > 0) {
    NSEnumerator* e = [view_controllers_ objectEnumerator];
    FlutterViewController* controller = nil;
    while ((controller = [e nextObject])) {
      [controller.platformViewsController reset];
      [controller.restorationPlugin reset];
      [controller.textInputPlugin reset];
    }
  }
}

// |PlatformView|
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

void PlatformViewIOS::ApplyLocaleToOwnerController() {
  if ([view_controllers_ count] > 0) {
    NSEnumerator* e = [view_controllers_ objectEnumerator];
    FlutterViewController* controller = nil;
    while ((controller = [e nextObject])) {
      controller.applicationLocale =
          application_locale_.empty() ? nil : @(application_locale_.data());
    }
  }
}

}  // namespace flutter
