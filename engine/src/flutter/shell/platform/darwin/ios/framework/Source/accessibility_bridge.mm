// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/accessibility_bridge.h"

#include <algorithm>
#include <cmath>
#include <utility>

#include "flutter/fml/logging.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterEngine_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterViewController_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/TextInputSemanticsObject.h"
#import "flutter/shell/platform/darwin/ios/platform_view_ios.h"

#include "flutter/common/constants.h"

#pragma GCC diagnostic error "-Wundeclared-selector"

FLUTTER_ASSERT_ARC

namespace flutter {
namespace {

class DefaultIosDelegate : public AccessibilityBridge::IosDelegate {
 public:
  bool IsFlutterViewControllerPresentingModalViewController(
      FlutterViewController* view_controller) override {
    if (view_controller) {
      return view_controller.isPresentingViewController;
    } else {
      return false;
    }
  }

  void PostAccessibilityNotification(UIAccessibilityNotifications notification,
                                     id argument) override {
    UIAccessibilityPostNotification(notification, argument);
  }
};
}  // namespace

AccessibilityBridge::AccessibilityBridge(
    FlutterViewController* view_controller,
    PlatformViewIOS* platform_view,
    __weak FlutterPlatformViewsController* platform_views_controller,
    std::unique_ptr<IosDelegate> ios_delegate)
    : view_controller_(view_controller),
      accessibility_element_init_container_([[UIView alloc] initWithFrame:CGRectZero]),
      platform_view_(platform_view),
      platform_views_controller_(platform_views_controller),
      objects_([[NSMutableDictionary alloc] init]),
      previous_routes_({}),
      ios_delegate_(ios_delegate ? std::move(ios_delegate)
                                 : std::make_unique<DefaultIosDelegate>()),
      weak_factory_(this) {
  accessibility_channel_ = [[FlutterBasicMessageChannel alloc]
         initWithName:@"flutter/accessibility"
      binaryMessenger:platform_view->GetOwnerViewController().engine.binaryMessenger
                codec:[FlutterStandardMessageCodec sharedInstance]];
  fml::WeakPtr<AccessibilityBridge> weak_self = GetWeakPtr();
  [accessibility_channel_ setMessageHandler:^(id message, FlutterReply reply) {
    if (weak_self) {
      weak_self->HandleEvent((NSDictionary*)message);
    }
  }];
}

AccessibilityBridge::~AccessibilityBridge() {
  [accessibility_channel_ setMessageHandler:nil];
  clearState();
}

void AccessibilityBridge::SetViewController(FlutterViewController* viewController,
                                            FlutterView* previousView) {
  if (viewController) {
    FML_DCHECK(viewController.platformViewsController == platform_views_controller_)
        << "A reattached FlutterViewController must belong to the same FlutterEngine.";
  }
  view_controller_ = viewController;
  UIView* currentView = ViewIfLoaded();
  if (previousView != currentView) {
    ClearAccessibilityElementsIfOwnedByBridge(previousView);
  }
  UpdateAccessibilityElementsForCurrentView();
  NotifySemanticsObjectsViewChanged();
}

UIView<UITextInput>* AccessibilityBridge::textInputView() {
  return [[platform_view_->GetOwnerViewController().engine textInputPlugin] textInputView];
}

bool AccessibilityBridge::HasSemantics() const {
  return objects_[@(kRootNodeId)] != nil;
}

void AccessibilityBridge::AccessibilityObjectDidBecomeFocused(int32_t id) {
  last_focused_semantics_object_id_ = id;
  [accessibility_channel_ sendMessage:@{@"type" : @"didGainFocus", @"nodeId" : @(id)}];
}

void AccessibilityBridge::AccessibilityObjectDidLoseFocus(int32_t id) {
  if (last_focused_semantics_object_id_ == id) {
    last_focused_semantics_object_id_ = kSemanticObjectIdInvalid;
  }
}

namespace {

// Keys into UIKit's accessibility strings, so scroll announcements match native
// scroll views in every language iOS supports. The keys are undocumented, so
// each has an English fallback.
//
// TODO(LouiseHsu): Have the framework supply these strings instead, removing
// the dependency on undocumented keys.
// https://github.com/flutter/flutter/issues/189285
constexpr char kUIKitAccessibilityBundleId[] = "com.apple.UIKit.axbundle";
constexpr char kUIKitAccessibilityTable[] = "Accessibility";
constexpr char kScrollPageStatusKey[] = "scroll.page.summary";
constexpr char kScrollRowStatusKey[] = "table.scrollbypage.status";
constexpr char kScrollPageStatusFallback[] = "page %1$@ of %2$@";
constexpr char kScrollRowStatusFallback[] = "rows %1$@ to %2$@ of %3$@";

// UIKit's accessibility strings bundle, or nil if not loaded yet. iOS loads it
// when VoiceOver starts, so only a successful lookup is cached.
NSBundle* UIKitAccessibilityBundle() {
  static NSBundle* bundle = nil;
  if (!bundle) {
    bundle = [NSBundle bundleWithIdentifier:@(kUIKitAccessibilityBundleId)];
  }
  return bundle;
}

// Formats `value` with the current locale's digits.
NSString* LocalizedCount(int64_t value) {
  return [NSNumberFormatter localizedStringFromNumber:@(value)
                                          numberStyle:NSNumberFormatterDecimalStyle];
}

// Replaces %1$@, %2$@, ... in `format` with `arguments`, or returns nil if a
// placeholder is left over. Avoids +stringWithFormat: because `format` comes
// from a system file and could have more specifiers than arguments.
NSString* SubstitutePositionalArguments(NSString* format, NSArray<NSString*>* arguments) {
  NSMutableString* result = [format mutableCopy];
  for (NSUInteger i = 0; i < arguments.count; ++i) {
    NSString* token = [NSString stringWithFormat:@"%%%lu$@", static_cast<unsigned long>(i + 1)];
    [result replaceOccurrencesOfString:token
                            withString:arguments[i]
                               options:0
                                 range:NSMakeRange(0, result.length)];
  }
  if ([result rangeOfString:@"$@"].location != NSNotFound ||
      [result rangeOfString:@"%@"].location != NSNotFound) {
    return nil;
  }
  return result;
}

// Looks up `key` in UIKit's table and fills in `arguments`, falling back to
// `fallback_format` if that fails.
NSString* LocalizedScrollStatus(const char* key,
                                const char* fallback_format,
                                NSArray<NSString*>* arguments) {
  NSString* fallback = @(fallback_format);
  NSString* format = fallback;
  if (NSBundle* bundle = UIKitAccessibilityBundle()) {
    NSString* localized = [bundle localizedStringForKey:@(key)
                                                  value:fallback
                                                  table:@(kUIKitAccessibilityTable)];
    if (localized.length > 0) {
      format = localized;
    }
  }
  NSString* result = SubstitutePositionalArguments(format, arguments);
  if (result) {
    return result;
  }
  return SubstitutePositionalArguments(fallback, arguments);
}

// Computes the numbers to announce for `object`'s scroll position. Builds no
// strings, so it is cheap enough to run on every frame of a scroll.
AccessibilityScrollStatus ComputeScrollStatus(SemanticsObject* object) {
  const flutter::SemanticsNode& node = object.node;

  AccessibilityScrollStatus status;
  status.uid = object.uid;

  // "rows x to y of z", when the scrollable reports child indexes.
  if (node.scrollChildren > 0) {
    // Skip off-screen cache extent rows, which the framework marks hidden.
    int64_t visible = 0;
    for (SemanticsObject* child in object.children) {
      if (!child.node.flags.isHidden) {
        ++visible;
      }
    }
    int64_t total = node.scrollChildren;
    int64_t first = std::clamp<int64_t>(node.scrollIndex + 1, 1, total);
    status.form = AccessibilityScrollStatus::Form::kRows;
    status.first = first;
    status.last = std::min(total, first + std::max<int64_t>(visible, 1) - 1);
    status.total = total;
    return status;
  }

  // Otherwise "page x of y", from the scroll extents.
  double position = node.scrollPosition;
  double extent_min = node.scrollExtentMin;
  double extent_max = node.scrollExtentMax;
  if (std::isnan(position) || std::isnan(extent_max) || !std::isfinite(extent_max)) {
    // No page count exists for an infinite or unknown extent.
    return status;
  }
  if (std::isnan(extent_min)) {
    extent_min = 0.0;
  }

  const bool horizontal = node.HasAction(flutter::SemanticsAction::kScrollLeft) ||
                          node.HasAction(flutter::SemanticsAction::kScrollRight);
  const double viewport = horizontal ? node.rect.width() : node.rect.height();
  if (viewport <= 0.0) {
    return status;
  }

  // A partial last screen counts as a page. The tolerance stops floating point
  // error in the extents from adding a page.
  constexpr double kPageTolerance = 1e-6;
  const double range = std::max(extent_max - extent_min, 0.0);
  int64_t total_pages = std::max<int64_t>(
      static_cast<int64_t>(std::ceil((range + viewport) / viewport - kPageTolerance)), 1);

  // Map scroll progress onto the pages so the end is always the last page;
  // `position / viewport` can't reach it unless the content is a whole number
  // of screens.
  int64_t current_page = 1;
  if (range > 0.0 && total_pages > 1) {
    const double progress = std::clamp((position - extent_min) / range, 0.0, 1.0);
    current_page = 1 + static_cast<int64_t>(std::round(progress * (total_pages - 1)));
  }
  status.form = AccessibilityScrollStatus::Form::kPage;
  status.first = std::clamp<int64_t>(current_page, 1, total_pages);
  status.total = total_pages;
  return status;
}

// Renders `status` as the string UIAccessibilityPageScrolledNotification
// expects, or nil if there is nothing accurate to say.
NSString* FormatScrollStatus(const AccessibilityScrollStatus& status) {
  switch (status.form) {
    case AccessibilityScrollStatus::Form::kNone:
      return nil;
    case AccessibilityScrollStatus::Form::kRows:
      return LocalizedScrollStatus(kScrollRowStatusKey, kScrollRowStatusFallback, @[
        LocalizedCount(status.first), LocalizedCount(status.last), LocalizedCount(status.total)
      ]);
    case AccessibilityScrollStatus::Form::kPage:
      return LocalizedScrollStatus(kScrollPageStatusKey, kScrollPageStatusFallback,
                                   @[ LocalizedCount(status.first), LocalizedCount(status.total) ]);
  }
}

}  // namespace

void AccessibilityBridge::UpdateSemantics(
    flutter::SemanticsNodeUpdates nodes,
    const flutter::CustomAccessibilityActionUpdates& actions) {
  BOOL layoutChanged = NO;
  // The object whose scroll position changed in this update, if any.
  SemanticsObject* scrolledObject = nil;
  BOOL needsAnnouncement = NO;
  for (const auto& entry : actions) {
    const flutter::CustomAccessibilityAction& action = entry.second;
    actions_[action.id] = action;
  }
  // The semantics cache is updated even while the owner view is not loaded. UIKit
  // accessibility notifications are only useful once there is a loaded view with
  // accessibility elements to inspect.
  BOOL shouldPostAccessibilityNotifications =
      view_controller_ && ViewIfLoaded() &&
      !ios_delegate_->IsFlutterViewControllerPresentingModalViewController(view_controller_);
  for (const auto& entry : nodes) {
    const flutter::SemanticsNode& node = entry.second;
    SemanticsObject* object = GetOrCreateObject(node.id, nodes);
    layoutChanged = layoutChanged || [object nodeWillCauseLayoutChange:&node];
    if ([object nodeWillCauseScroll:&node]) {
      scrolledObject = object;
    }
    needsAnnouncement = [object nodeShouldTriggerAnnouncement:&node];
    [object setSemanticsNode:&node];
    NSUInteger newChildCountInTraversalOrder = node.childrenInTraversalOrder.size();
    NSMutableArray* newChildren =
        [[NSMutableArray alloc] initWithCapacity:newChildCountInTraversalOrder];
    for (NSUInteger i = 0; i < newChildCountInTraversalOrder; ++i) {
      SemanticsObject* child = GetOrCreateObject(node.childrenInTraversalOrder[i], nodes);
      [newChildren addObject:child];
    }
    NSUInteger newChildCountInHitTestOrder = node.childrenInHitTestOrder.size();
    NSMutableArray* newChildrenInHitTestOrder =
        [[NSMutableArray alloc] initWithCapacity:newChildCountInHitTestOrder];
    for (NSUInteger i = 0; i < newChildCountInHitTestOrder; ++i) {
      SemanticsObject* child = GetOrCreateObject(node.childrenInHitTestOrder[i], nodes);
      [newChildrenInHitTestOrder addObject:child];
    }
    object.children = newChildren;
    object.childrenInHitTestOrder = newChildrenInHitTestOrder;
    if (!node.customAccessibilityActions.empty()) {
      NSMutableArray<FlutterCustomAccessibilityAction*>* accessibilityCustomActions =
          [[NSMutableArray alloc] init];
      for (int32_t action_id : node.customAccessibilityActions) {
        flutter::CustomAccessibilityAction& action = actions_[action_id];
        if (action.overrideId != -1) {
          // iOS does not support overriding standard actions, so we ignore any
          // custom actions that have an override id provided.
          continue;
        }
        NSString* label = @(action.label.data());
        SEL selector = @selector(onCustomAccessibilityAction:);
        FlutterCustomAccessibilityAction* customAction =
            [[FlutterCustomAccessibilityAction alloc] initWithName:label
                                                            target:object
                                                          selector:selector];
        customAction.uid = action_id;
        [accessibilityCustomActions addObject:customAction];
      }
      object.accessibilityCustomActions = accessibilityCustomActions;
    }

    if (needsAnnouncement && shouldPostAccessibilityNotifications) {
      // Try to be more polite - iOS 11+ supports
      // UIAccessibilitySpeechAttributeQueueAnnouncement which should avoid
      // interrupting system notifications or other elements.
      // Expectation: roughly match the behavior of polite announcements on
      // Android.
      NSString* announcement = [[NSString alloc] initWithUTF8String:object.node.label.c_str()];
      UIAccessibilityPostNotification(
          UIAccessibilityAnnouncementNotification,
          [[NSAttributedString alloc] initWithString:announcement
                                          attributes:@{
                                            UIAccessibilitySpeechAttributeQueueAnnouncement : @YES
                                          }]);
    }
  }

  SemanticsObject* root = objects_[@(kRootNodeId)];

  bool routeChanged = false;
  SemanticsObject* lastAdded = nil;

  if (root) {
    UpdateAccessibilityElementsForCurrentView();
    NSMutableArray<SemanticsObject*>* newRoutes = [[NSMutableArray alloc] init];
    [root collectRoutes:newRoutes];
    // Finds the last route that is not in the previous routes.
    for (SemanticsObject* route in newRoutes) {
      if (std::find(previous_routes_.begin(), previous_routes_.end(), [route uid]) ==
          previous_routes_.end()) {
        lastAdded = route;
      }
    }
    // If all the routes are in the previous route, get the last route.
    if (lastAdded == nil && [newRoutes count] > 0) {
      int index = [newRoutes count] - 1;
      lastAdded = [newRoutes objectAtIndex:index];
    }
    // There are two cases if lastAdded != nil
    // 1. lastAdded is not in previous routes. In this case,
    //    [lastAdded uid] != previous_route_id_
    // 2. All new routes are in previous routes and
    //    lastAdded = newRoutes.last.
    // In the first case, we need to announce new route. In the second case,
    // we need to announce if one list is shorter than the other.
    if (lastAdded != nil &&
        ([lastAdded uid] != previous_route_id_ || [newRoutes count] != previous_routes_.size())) {
      previous_route_id_ = [lastAdded uid];
      routeChanged = true;
    }
    previous_routes_.clear();
    for (SemanticsObject* route in newRoutes) {
      previous_routes_.push_back([route uid]);
    }
  } else {
    UIView* view = ViewIfLoaded();
    ClearAccessibilityElementsIfOwnedByBridge(view);
  }

  NSMutableArray<NSNumber*>* doomed_uids = [NSMutableArray arrayWithArray:objects_.allKeys];
  if (root) {
    VisitObjectsRecursivelyAndRemove(root, doomed_uids);
  }
  [objects_ removeObjectsForKeys:doomed_uids];

  for (SemanticsObject* object in objects_.allValues) {
    [object accessibilityBridgeDidFinishUpdate];
  }

  if (!shouldPostAccessibilityNotifications) {
    return;
  }

  layoutChanged = layoutChanged || [doomed_uids count] > 0;

  if (routeChanged) {
    NSString* routeName = [lastAdded routeName];
    ios_delegate_->PostAccessibilityNotification(UIAccessibilityScreenChangedNotification,
                                                 routeName);
  }

  if (scrolledObject) {
    // Not an `else` of `layoutChanged`: a scroll moves its children, which
    // almost always sets `layoutChanged` too.
    //
    // A scroll spans many frames, so only announce when the status changes.
    AccessibilityScrollStatus status = ComputeScrollStatus(scrolledObject);
    if (status != last_scroll_status_) {
      last_scroll_status_ = status;
      ios_delegate_->PostAccessibilityNotification(UIAccessibilityPageScrolledNotification,
                                                   FormatScrollStatus(status));
    }
  }

  if (layoutChanged) {
    SemanticsObject* next = FindNextFocusableIfNecessary();
    SemanticsObject* lastFocused = [objects_ objectForKey:@(last_focused_semantics_object_id_)];
    // Only specify the focus item if the new focus is different, avoiding double focuses on the
    // same item. See: https://github.com/flutter/flutter/issues/104176. If there is a route
    // change, we always refocus.
    ios_delegate_->PostAccessibilityNotification(
        UIAccessibilityLayoutChangedNotification,
        (routeChanged || next != lastFocused) ? next.nativeAccessibility : NULL);
  }
}

void AccessibilityBridge::DispatchSemanticsAction(int32_t node_uid,
                                                  flutter::SemanticsAction action) {
  // TODO(team-ios): Remove implicit view assumption.
  // https://github.com/flutter/flutter/issues/142845
  platform_view_->DispatchSemanticsAction(kFlutterImplicitViewId, node_uid, action, {});
}

void AccessibilityBridge::DispatchSemanticsAction(int32_t node_uid,
                                                  flutter::SemanticsAction action,
                                                  fml::MallocMapping args) {
  // TODO(team-ios): Remove implicit view assumption.
  // https://github.com/flutter/flutter/issues/142845
  platform_view_->DispatchSemanticsAction(kFlutterImplicitViewId, node_uid, action,
                                          std::move(args));
}

static void ReplaceSemanticsObject(SemanticsObject* oldObject,
                                   SemanticsObject* newObject,
                                   NSMutableDictionary<NSNumber*, SemanticsObject*>* objects) {
  // `newObject` should represent the same id as `oldObject`.
  FML_DCHECK(oldObject.node.id == newObject.uid);
  NSNumber* nodeId = @(oldObject.node.id);
  NSUInteger positionInChildlist = [oldObject.parent.children indexOfObject:oldObject];
  oldObject.children = @[];
  [oldObject.parent replaceChildAtIndex:positionInChildlist withChild:newObject];
  [objects removeObjectForKey:nodeId];
  objects[nodeId] = newObject;
}

static SemanticsObject* CreateObject(const flutter::SemanticsNode& node,
                                     const fml::WeakPtr<AccessibilityBridge>& weak_ptr) {
  if (node.flags.isTextField && !node.flags.isReadOnly) {
    // Text fields are backed by objects that implement UITextInput.
    return [[TextInputSemanticsObject alloc] initWithBridge:weak_ptr uid:node.id];
  } else if (!node.flags.isInMutuallyExclusiveGroup &&
             (node.flags.isToggled != flutter::SemanticsTristate::kNone ||
              node.flags.isChecked != flutter::SemanticsCheckState::kNone)) {
    return [[FlutterSwitchSemanticsObject alloc] initWithBridge:weak_ptr uid:node.id];
  } else if (node.flags.hasImplicitScrolling) {
    return [[FlutterScrollableSemanticsObject alloc] initWithBridge:weak_ptr uid:node.id];
  } else if (node.IsPlatformViewNode()) {
    FlutterPlatformViewsController* platformViewsController =
        weak_ptr->GetPlatformViewsController();
    FlutterTouchInterceptingView* touchInterceptingView =
        [platformViewsController flutterTouchInterceptingViewForId:node.platformViewId];
    return [[FlutterPlatformViewSemanticsContainer alloc] initWithBridge:weak_ptr
                                                                     uid:node.id
                                                            platformView:touchInterceptingView];
  } else {
    return [[FlutterSemanticsObject alloc] initWithBridge:weak_ptr uid:node.id];
  }
}

SemanticsObject* AccessibilityBridge::GetOrCreateObject(int32_t uid,
                                                        flutter::SemanticsNodeUpdates& updates) {
  SemanticsObject* object = objects_[@(uid)];
  if (!object) {
    object = CreateObject(updates[uid], GetWeakPtr());
    objects_[@(uid)] = object;
  } else {
    // Existing node case
    auto nodeEntry = updates.find(object.node.id);
    if (nodeEntry != updates.end()) {
      // There's an update for this node
      flutter::SemanticsNode node = nodeEntry->second;
      if (object.node.flags.isTextField != node.flags.isTextField ||
          object.node.flags.isReadOnly != node.flags.isReadOnly ||
          (object.node.flags.isChecked == flutter::SemanticsCheckState::kNone) !=
              (node.flags.isChecked == flutter::SemanticsCheckState::kNone) ||
          ((object.node.flags.isToggled == flutter::SemanticsTristate::kNone) !=
           (node.flags.isToggled == flutter::SemanticsTristate::kNone)) ||
          object.node.flags.hasImplicitScrolling != node.flags.hasImplicitScrolling

      ) {
        // The node changed its type. In this case, we cannot reuse the existing
        // SemanticsObject implementation. Instead, we replace it with a new
        // instance.
        SemanticsObject* newSemanticsObject = CreateObject(node, GetWeakPtr());
        ReplaceSemanticsObject(object, newSemanticsObject, objects_);
        object = newSemanticsObject;
      }
    }
  }
  return object;
}

void AccessibilityBridge::VisitObjectsRecursivelyAndRemove(SemanticsObject* object,
                                                           NSMutableArray<NSNumber*>* doomed_uids) {
  [doomed_uids removeObject:@(object.uid)];
  for (SemanticsObject* child in [object children])
    VisitObjectsRecursivelyAndRemove(child, doomed_uids);
}

SemanticsObject* AccessibilityBridge::FindNextFocusableIfNecessary() {
  // This property will be -1 if the focus is outside of the flutter
  // application. In this case, we should not refocus anything.
  if (last_focused_semantics_object_id_ == kSemanticObjectIdInvalid) {
    return nil;
  }

  // Tries to refocus the previous focused semantics object to avoid random jumps.
  return FindFirstFocusable(objects_[@(last_focused_semantics_object_id_)]);
}

SemanticsObject* AccessibilityBridge::FindFirstFocusable(SemanticsObject* parent) {
  SemanticsObject* currentObject = parent ?: objects_[@(kRootNodeId)];
  if (!currentObject) {
    return nil;
  }
  if (currentObject.isAccessibilityElement) {
    return currentObject;
  }

  for (SemanticsObject* child in [currentObject children]) {
    SemanticsObject* candidate = FindFirstFocusable(child);
    if (candidate) {
      return candidate;
    }
  }
  return nil;
}

void AccessibilityBridge::HandleEvent(NSDictionary<NSString*, id>* annotatedEvent) {
  NSString* type = annotatedEvent[@"type"];
  if ([type isEqualToString:@"announce"]) {
    NSString* message = annotatedEvent[@"data"][@"message"];
    ios_delegate_->PostAccessibilityNotification(UIAccessibilityAnnouncementNotification, message);
  }
  if ([type isEqualToString:@"focus"]) {
    SemanticsObject* node = objects_[annotatedEvent[@"nodeId"]];
    ios_delegate_->PostAccessibilityNotification(UIAccessibilityLayoutChangedNotification, node);
  }
}

fml::WeakPtr<AccessibilityBridge> AccessibilityBridge::GetWeakPtr() {
  return weak_factory_.GetWeakPtr();
}

bool AccessibilityBridge::AccessibilityElementsWereInstalledByBridge(NSArray* elements) const {
  if (elements.count != 1) {
    return false;
  }
  id element = elements.firstObject;
  if (![element isKindOfClass:[SemanticsObjectContainer class]]) {
    return false;
  }
  SemanticsObject* semanticsObject = ((SemanticsObjectContainer*)element).semanticsObject;
  return semanticsObject && semanticsObject.bridge == this;
}

void AccessibilityBridge::ClearAccessibilityElementsIfOwnedByBridge(UIView* view) {
  if (!view) {
    return;
  }
  if (AccessibilityElementsWereInstalledByBridge(view.accessibilityElements)) {
    view.accessibilityElements = nil;
  }
}

void AccessibilityBridge::UpdateAccessibilityElementsForCurrentView() {
  UIView* view = ViewIfLoaded();
  if (!view) {
    return;
  }
  SemanticsObject* root = objects_[@(kRootNodeId)];
  if (!root) {
    view.accessibilityElements = nil;
    return;
  }
  id accessibilityContainer = [root accessibilityContainer];
  if (!accessibilityContainer) {
    view.accessibilityElements = nil;
    return;
  }
  view.accessibilityElements = @[ accessibilityContainer ];
}

void AccessibilityBridge::NotifySemanticsObjectsViewChanged() {
  for (SemanticsObject* object in objects_.allValues) {
    [object accessibilityBridgeDidChangeView];
  }
}

void AccessibilityBridge::clearState() {
  [objects_ removeAllObjects];
  previous_route_id_ = 0;
  previous_routes_.clear();
  last_scroll_status_ = {};
  view_controller_.viewIfLoaded.accessibilityElements = nil;
}

}  // namespace flutter
