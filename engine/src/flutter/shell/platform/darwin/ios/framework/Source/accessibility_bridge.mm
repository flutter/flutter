// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/accessibility_bridge.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterEngine_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterViewController_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/accessibility_text_entry.h"

#import "flutter/shell/platform/darwin/ios/platform_view_ios.h"

#pragma GCC diagnostic error "-Wundeclared-selector"

FLUTTER_ASSERT_NOT_ARC

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

AccessibilityBridge::AccessibilityBridge(FlutterViewController* view_controller,
                                         PlatformViewIOS* platform_view,
                                         FlutterPlatformViewsController* platform_views_controller,
                                         std::unique_ptr<IosDelegate> ios_delegate)
    : view_controller_(view_controller),
      platform_view_(platform_view),
      platform_views_controller_(platform_views_controller),
      last_focused_semantics_object_id_(0),
      objects_([[NSMutableDictionary alloc] init]),
      weak_factory_(this),
      previous_route_id_(0),
      previous_routes_({}),
      ios_delegate_(ios_delegate ? std::move(ios_delegate)
                                 : std::make_unique<DefaultIosDelegate>()) {
  accessibility_channel_.reset([[FlutterBasicMessageChannel alloc]
         initWithName:@"flutter/accessibility"
      binaryMessenger:platform_view->GetOwnerViewController().get().engine.binaryMessenger
                codec:[FlutterStandardMessageCodec sharedInstance]]);
  [accessibility_channel_.get() setMessageHandler:^(id message, FlutterReply reply) {
    HandleEvent((NSDictionary*)message);
  }];
}

AccessibilityBridge::~AccessibilityBridge() {
  [accessibility_channel_.get() setMessageHandler:nil];
  clearState();
  view_controller_.view.accessibilityElements = nil;
}

UIView<UITextInput>* AccessibilityBridge::textInputView() {
  return [[platform_view_->GetOwnerViewController().get().engine textInputPlugin] textInputView];
}

void AccessibilityBridge::AccessibilityFocusDidChange(int32_t id) {
  last_focused_semantics_object_id_ = id;
}

void AccessibilityBridge::UpdateSemantics(flutter::SemanticsNodeUpdates nodes,
                                          flutter::CustomAccessibilityActionUpdates actions) {
  BOOL layoutChanged = NO;
  BOOL scrollOccured = NO;
  BOOL needsAnnouncement = NO;
  for (const auto& entry : actions) {
    const flutter::CustomAccessibilityAction& action = entry.second;
    actions_[action.id] = action;
  }
  for (const auto& entry : nodes) {
    const flutter::SemanticsNode& node = entry.second;
    SemanticsObject* object = GetOrCreateObject(node.id, nodes);
    layoutChanged = layoutChanged || [object nodeWillCauseLayoutChange:&node];
    scrollOccured = scrollOccured || [object nodeWillCauseScroll:&node];
    needsAnnouncement = [object nodeShouldTriggerAnnouncement:&node];
    [object setSemanticsNode:&node];
    NSUInteger newChildCount = node.childrenInTraversalOrder.size();
    NSMutableArray* newChildren =
        [[[NSMutableArray alloc] initWithCapacity:newChildCount] autorelease];
    for (NSUInteger i = 0; i < newChildCount; ++i) {
      SemanticsObject* child = GetOrCreateObject(node.childrenInTraversalOrder[i], nodes);
      [newChildren addObject:child];
    }
    object.children = newChildren;
    if (node.customAccessibilityActions.size() > 0) {
      NSMutableArray<FlutterCustomAccessibilityAction*>* accessibilityCustomActions =
          [[[NSMutableArray alloc] init] autorelease];
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
            [[[FlutterCustomAccessibilityAction alloc] initWithName:label
                                                             target:object
                                                           selector:selector] autorelease];
        customAction.uid = action_id;
        [accessibilityCustomActions addObject:customAction];
      }
      object.accessibilityCustomActions = accessibilityCustomActions;
    }

    if (object.node.IsPlatformViewNode()) {
      FlutterPlatformViewsController* controller = GetPlatformViewsController();
      if (controller) {
        object.platformViewSemanticsContainer = [[[FlutterPlatformViewSemanticsContainer alloc]
            initWithSemanticsObject:object] autorelease];
      }
    } else if (object.platformViewSemanticsContainer) {
      object.platformViewSemanticsContainer = nil;
    }
    if (needsAnnouncement) {
      // Try to be more polite - iOS 11+ supports
      // UIAccessibilitySpeechAttributeQueueAnnouncement which should avoid
      // interrupting system notifications or other elements.
      // Expectation: roughly match the behavior of polite announcements on
      // Android.
      NSString* announcement =
          [[[NSString alloc] initWithUTF8String:object.node.label.c_str()] autorelease];
      if (@available(iOS 11.0, *)) {
        UIAccessibilityPostNotification(
            UIAccessibilityAnnouncementNotification,
            [[[NSAttributedString alloc]
                initWithString:announcement
                    attributes:@{
                      UIAccessibilitySpeechAttributeQueueAnnouncement : @YES
                    }] autorelease]);
      } else {
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, announcement);
      }
    }
  }

  SemanticsObject* root = objects_.get()[@(kRootNodeId)];

  bool routeChanged = false;
  SemanticsObject* lastAdded = nil;

  if (root) {
    if (!view_controller_.view.accessibilityElements) {
      view_controller_.view.accessibilityElements = @[ [root accessibilityContainer] ];
    }
    NSMutableArray<SemanticsObject*>* newRoutes = [[[NSMutableArray alloc] init] autorelease];
    [root collectRoutes:newRoutes];
    for (SemanticsObject* route in newRoutes) {
      if (std::find(previous_routes_.begin(), previous_routes_.end(), [route uid]) !=
          previous_routes_.end()) {
        lastAdded = route;
      }
    }
    if (lastAdded == nil && [newRoutes count] > 0) {
      int index = [newRoutes count] - 1;
      lastAdded = [newRoutes objectAtIndex:index];
    }
    if (lastAdded != nil && [lastAdded uid] != previous_route_id_) {
      previous_route_id_ = [lastAdded uid];
      routeChanged = true;
    }
    previous_routes_.clear();
    for (SemanticsObject* route in newRoutes) {
      previous_routes_.push_back([route uid]);
    }
  } else {
    view_controller_.view.accessibilityElements = nil;
  }

  NSMutableArray<NSNumber*>* doomed_uids = [NSMutableArray arrayWithArray:[objects_.get() allKeys]];
  if (root)
    VisitObjectsRecursivelyAndRemove(root, doomed_uids);
  [objects_ removeObjectsForKeys:doomed_uids];

  layoutChanged = layoutChanged || [doomed_uids count] > 0;
  if (routeChanged) {
    if (!ios_delegate_->IsFlutterViewControllerPresentingModalViewController(view_controller_)) {
      ios_delegate_->PostAccessibilityNotification(UIAccessibilityScreenChangedNotification,
                                                   [lastAdded routeFocusObject]);
    }
  } else if (layoutChanged) {
    // Tries to refocus the previous focused semantics object to avoid random jumps.
    ios_delegate_->PostAccessibilityNotification(
        UIAccessibilityLayoutChangedNotification,
        [objects_.get() objectForKey:@(last_focused_semantics_object_id_)]);
  }
  if (scrollOccured) {
    // Tries to refocus the previous focused semantics object to avoid random jumps.
    ios_delegate_->PostAccessibilityNotification(
        UIAccessibilityPageScrolledNotification,
        [objects_.get() objectForKey:@(last_focused_semantics_object_id_)]);
  }
}

void AccessibilityBridge::DispatchSemanticsAction(int32_t uid, flutter::SemanticsAction action) {
  platform_view_->DispatchSemanticsAction(uid, action, {});
}

void AccessibilityBridge::DispatchSemanticsAction(int32_t uid,
                                                  flutter::SemanticsAction action,
                                                  std::vector<uint8_t> args) {
  platform_view_->DispatchSemanticsAction(uid, action, std::move(args));
}

static void ReplaceSemanticsObject(SemanticsObject* oldObject,
                                   SemanticsObject* newObject,
                                   NSMutableDictionary<NSNumber*, SemanticsObject*>* objects) {
  // `newObject` should represent the same id as `oldObject`.
  assert(oldObject.node.id == newObject.node.id);
  NSNumber* nodeId = @(oldObject.node.id);
  NSUInteger positionInChildlist = [oldObject.parent.children indexOfObject:oldObject];
  [objects removeObjectForKey:nodeId];
  [oldObject.parent replaceChildAtIndex:positionInChildlist withChild:newObject];
  objects[nodeId] = newObject;
}

static SemanticsObject* CreateObject(const flutter::SemanticsNode& node,
                                     fml::WeakPtr<AccessibilityBridge> weak_ptr) {
  if (node.HasFlag(flutter::SemanticsFlags::kIsTextField) &&
      !node.HasFlag(flutter::SemanticsFlags::kIsReadOnly)) {
    // Text fields are backed by objects that implement UITextInput.
    return [[[TextInputSemanticsObject alloc] initWithBridge:weak_ptr uid:node.id] autorelease];
  } else if (node.HasFlag(flutter::SemanticsFlags::kHasToggledState) ||
             node.HasFlag(flutter::SemanticsFlags::kHasCheckedState)) {
    SemanticsObject* delegateObject =
        [[[FlutterSemanticsObject alloc] initWithBridge:weak_ptr uid:node.id] autorelease];
    return (SemanticsObject*)[[[FlutterSwitchSemanticsObject alloc]
        initWithSemanticsObject:delegateObject] autorelease];
  } else {
    return [[[FlutterSemanticsObject alloc] initWithBridge:weak_ptr uid:node.id] autorelease];
  }
}

static bool DidFlagChange(const flutter::SemanticsNode& oldNode,
                          const flutter::SemanticsNode& newNode,
                          SemanticsFlags flag) {
  return oldNode.HasFlag(flag) != newNode.HasFlag(flag);
}

SemanticsObject* AccessibilityBridge::GetOrCreateObject(int32_t uid,
                                                        flutter::SemanticsNodeUpdates& updates) {
  SemanticsObject* object = objects_.get()[@(uid)];
  if (!object) {
    object = CreateObject(updates[uid], GetWeakPtr());
    objects_.get()[@(uid)] = object;
  } else {
    // Existing node case
    auto nodeEntry = updates.find(object.node.id);
    if (nodeEntry != updates.end()) {
      // There's an update for this node
      flutter::SemanticsNode node = nodeEntry->second;
      if (DidFlagChange(object.node, node, flutter::SemanticsFlags::kIsTextField) ||
          DidFlagChange(object.node, node, flutter::SemanticsFlags::kIsReadOnly) ||
          DidFlagChange(object.node, node, flutter::SemanticsFlags::kHasCheckedState) ||
          DidFlagChange(object.node, node, flutter::SemanticsFlags::kHasToggledState)) {
        // The node changed its type. In this case, we cannot reuse the existing
        // SemanticsObject implementation. Instead, we replace it with a new
        // instance.
        SemanticsObject* newSemanticsObject = CreateObject(node, GetWeakPtr());
        ReplaceSemanticsObject(object, newSemanticsObject, objects_.get());
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

void AccessibilityBridge::HandleEvent(NSDictionary<NSString*, id>* annotatedEvent) {
  NSString* type = annotatedEvent[@"type"];
  if ([type isEqualToString:@"announce"]) {
    NSString* message = annotatedEvent[@"data"][@"message"];
    ios_delegate_->PostAccessibilityNotification(UIAccessibilityAnnouncementNotification, message);
  }
}

fml::WeakPtr<AccessibilityBridge> AccessibilityBridge::GetWeakPtr() {
  return weak_factory_.GetWeakPtr();
}

void AccessibilityBridge::clearState() {
  [objects_ removeAllObjects];
  previous_route_id_ = 0;
  previous_routes_.clear();
}

}  // namespace flutter
