// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "SemanticsObject.h"

#include <cmath>

#include "flutter/lib/ui/semantics/semantics_node.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterSemanticsScrollView.h"

FLUTTER_ASSERT_ARC

// The SemanticsObject class conforms to UIFocusItem and UIFocusItemContainer
// protocols, so the SemanticsObject tree can also be used to represent
// interactive UI components on screen that can receive UIFocusSystem focus.
//
// Typically, physical key events received by the FlutterViewController is
// first delivered to the framework, but that stopped working for navigation keys
// since iOS 15 when full keyboard access (FKA) is on, because those events are
// consumed by the UIFocusSystem and never dispatched to the UIResponders in the
// application (see
// https://developer.apple.com/documentation/uikit/uikeycommand/3780513-wantspriorityoversystembehavior
// ). FKA relies on the iOS focus engine, to enable FKA on iOS 15+, we use
// SemanticsObject to provide the iOS focus engine with the required hierarchical
// information and geometric context.
//
// The focus engine focus is different from accessibility focus, or even the
// currentFocus of the Flutter FocusManager in the framework. On iOS 15+, FKA
// key events are dispatched to the current iOS focus engine focus (and
// translated to calls such as -[NSObject accessibilityActivate]), while most
// other key events are dispatched to the framework.
@interface SemanticsObject (UIFocusSystem) <UIFocusItem, UIFocusItemContainer>
/// The `UIFocusItem` that represents this SemanticsObject.
///
///  For regular `SemanticsObject`s, this method returns `self`,
///  for `FlutterScrollableSemanticsObject`s, this method returns its scroll view.
- (id<UIFocusItem>)focusItem;
@end

@interface FlutterScrollableSemanticsObject (UIFocusSystem)
/// The scroll offset last reported by the framework, in the scroll view's
/// coordinate space. Implemented in SemanticsObject.mm.
- (CGPoint)contentOffsetInternal;
@end

// Whether the nearest scroll container above `object` supports implicit
// scrolling.
//
// The framework sets `hasImplicitScrolling` on the scrollable's node rather
// than on its children. Stop at the nearest scroll container so that, for
// example, pages of a PageView (which disallows implicit scrolling) nested in
// a ListView are not treated as reachable.
static BOOL IsInImplicitlyScrollingContainer(SemanticsObject* object) {
  for (SemanticsObject* ancestor = object.parent; ancestor; ancestor = ancestor.parent) {
    const flutter::SemanticsNode& node = ancestor.node;
    if (node.flags.hasImplicitScrolling) {
      return YES;
    }
    // Scrollables report a scroll position once laid out, even when they do
    // not allow implicit scrolling.
    if (!std::isnan(node.scrollPosition)) {
      return NO;
    }
  }
  return NO;
}

#pragma mark - Tab navigation

// The focus engine only considers items that are roughly on screen. With Tab
// and Shift+Tab, it therefore skips offscreen items in a scrollable and wraps
// around before reaching the end of the list. To fix that, the object losing
// focus checks the proposed item against the framework's semantics traversal
// order (see -shouldUpdateFocusInContext:). If they differ, it rejects the
// update, asks the framework to scroll the correct item into view, and then
// requests a focus update to it.

static SemanticsObject* RootOf(SemanticsObject* object) {
  SemanticsObject* root = object;
  while (root.parent) {
    root = root.parent;
  }
  return root;
}

// The number of semantics updates to wait for the framework to scroll the
// target into view before requesting focus anyway, for example when the
// target is clipped by something other than its scrollable.
static const int kMaxSemanticsUpdatesToWaitForScroll = 3;

// How long to wait for the framework to scroll the target into view before
// requesting focus anyway, in case no semantics update arrives at all.
static const int64_t kMaxWaitForScrollNanoseconds = 300 * NSEC_PER_MSEC;

// The item that Tab / Shift+Tab should focus next, while waiting for the
// framework to scroll it into view.
@interface FlutterPendingFocusTarget : NSObject
@property(nonatomic, weak) SemanticsObject* target;
@property(nonatomic) int updatesLeft;
@end

@implementation FlutterPendingFocusTarget
@end

// The pending targets, keyed by FlutterView.
static NSMapTable<UIView*, FlutterPendingFocusTarget*>* PendingFocusTargets() {
  static NSMapTable<UIView*, FlutterPendingFocusTarget*>* targets;
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    targets = [NSMapTable weakToStrongObjectsMapTable];
  });
  return targets;
}

static FlutterPendingFocusTarget* PendingFocusTargetEntry(SemanticsObject* object) {
  UIView* view = object.bridgeView;
  return view ? [PendingFocusTargets() objectForKey:view] : nil;
}

static void ClearPendingFocusTarget(SemanticsObject* object) {
  UIView* view = object.bridgeView;
  if (view) {
    [PendingFocusTargets() removeObjectForKey:view];
  }
}

// Whether `object` is still attached to the semantics tree of its bridge.
static BOOL IsAttached(SemanticsObject* object) {
  return object.bridge && RootOf(object).uid == kRootNodeId;
}

// The pending target of `object`'s FlutterView, or nil if there is none or it
// was removed from the semantics tree.
static SemanticsObject* PendingFocusTarget(SemanticsObject* object) {
  SemanticsObject* target = PendingFocusTargetEntry(object).target;
  if (target && !IsAttached(target)) {
    ClearPendingFocusTarget(object);
    return nil;
  }
  return target;
}

static void CollectFocusable(SemanticsObject* object, NSMutableArray<SemanticsObject*>* result) {
  // A scrollable is represented in the focus system by its scroll view, which
  // cannot be focused, so it is never a valid Tab target.
  if (object.focusItem == object && [object canBecomeFocused]) {
    [result addObject:object];
  }
  for (SemanticsObject* child in object.children) {
    CollectFocusable(child, result);
  }
}

// The next (or previous) focusable object after `object` in the framework's
// semantics traversal order, wrapping around at either end.
static SemanticsObject* FocusableNeighbor(SemanticsObject* object, BOOL forward) {
  NSMutableArray<SemanticsObject*>* focusable = [NSMutableArray array];
  CollectFocusable(RootOf(object), focusable);
  NSUInteger index = [focusable indexOfObjectIdenticalTo:object];
  if (index == NSNotFound) {
    return nil;
  }
  NSUInteger count = focusable.count;
  return focusable[(index + (forward ? 1 : count - 1)) % count];
}

// Requests a focus update to the pending target.
static void RequestFocusToPendingTarget(SemanticsObject* target) {
  if (target != PendingFocusTarget(target)) {
    return;  // Superseded, completed, or removed.
  }
  // A focus update request only takes effect if the requesting environment
  // contains the focused item. Request it from the root, whose
  // preferredFocusEnvironments returns the pending target.
  SemanticsObject* root = RootOf(target);
  UIFocusSystem* focusSystem = [UIFocusSystem focusSystemForEnvironment:root];
  [focusSystem requestFocusUpdateToEnvironment:root];
  [focusSystem updateFocusIfNeeded];
  // The focus update has been committed (or refused), so do not keep
  // redirecting later focus updates to the target.
  ClearPendingFocusTarget(target);
}

static void MoveFocusTo(SemanticsObject* target) {
  UIView* view = target.bridgeView;
  if (!view) {
    return;
  }
  FlutterPendingFocusTarget* entry = [[FlutterPendingFocusTarget alloc] init];
  entry.target = target;
  entry.updatesLeft = kMaxSemanticsUpdatesToWaitForScroll;
  [PendingFocusTargets() setObject:entry forKey:view];

  flutter::AccessibilityBridgeIos* bridge = target.bridge;
  if (bridge && IsInImplicitlyScrollingContainer(target)) {
    bridge->DispatchSemanticsAction(target.uid, flutter::SemanticsAction::kShowOnScreen);
  }
  if (!target.node.flags.isHidden) {
    // No scroll is needed, so a semantics update may never arrive.
    dispatch_async(dispatch_get_main_queue(), ^{
      RequestFocusToPendingTarget(target);
    });
    return;
  }
  // Otherwise, -focusSystemDidFinishSemanticsUpdate requests focus once the
  // target has been scrolled into view. Fall back to a timeout in case the
  // scroll changes nothing and no semantics update arrives.
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kMaxWaitForScrollNanoseconds),
                 dispatch_get_main_queue(), ^{
                   RequestFocusToPendingTarget(target);
                 });
}

@implementation SemanticsObject (FlutterFocusSystemUpdates)

- (void)focusSystemDidFinishSemanticsUpdate {
  FlutterPendingFocusTarget* entry = PendingFocusTargetEntry(self);
  SemanticsObject* target = PendingFocusTarget(self);
  if (!target) {
    return;
  }
  entry.updatesLeft--;
  if (!target.node.flags.isHidden || entry.updatesLeft <= 0) {
    // Let the scroll view geometry settle before asking the focus system.
    dispatch_async(dispatch_get_main_queue(), ^{
      RequestFocusToPendingTarget(target);
    });
  }
}

@end

@implementation SemanticsObject (UIFocusSystem)

- (id<UIFocusItem>)focusItem {
  return self;
}

#pragma mark - UIFocusEnvironment Conformance

- (void)setNeedsFocusUpdate {
}

- (void)updateFocusIfNeeded {
}

- (BOOL)shouldUpdateFocusInContext:(UIFocusUpdateContext*)context {
  // Only the item that is losing focus decides, so the decision is made once
  // per focus update.
  flutter::AccessibilityBridgeIos* bridge = self.bridge;
  if (context.previouslyFocusedItem != self || !bridge || bridge->isVoiceOverRunning()) {
    return YES;
  }
  // Tab and Shift+Tab move with the Next and Previous headings. When the focus
  // engine runs out of candidates, it wraps around with the First and Last
  // headings instead. Requested focus updates use UIFocusHeadingNone.
  UIFocusHeading heading = context.focusHeading;
  BOOL forward = (heading & (UIFocusHeadingNext | UIFocusHeadingFirst)) != 0;
  BOOL backward = (heading & (UIFocusHeadingPrevious | UIFocusHeadingLast)) != 0;
  if (forward == backward) {
    return YES;
  }
  // Let focus leave the FlutterView, e.g. to native views in add-to-app. This
  // can skip offscreen Flutter items after the last visible one.
  id<UIFocusItem> proposed = context.nextFocusedItem;
  if (proposed && !([(NSObject*)proposed isKindOfClass:[SemanticsObject class]] &&
                    ((SemanticsObject*)proposed).bridge == bridge)) {
    return YES;
  }
  // If an earlier Tab is still waiting for its target to scroll into view,
  // continue from that target so quick key presses stay in order.
  SemanticsObject* pending = PendingFocusTarget(self);
  SemanticsObject* expected = FocusableNeighbor(pending ?: self, forward);
  if (!expected || (!pending && proposed == expected)) {
    return YES;
  }
  MoveFocusTo(expected);
  return NO;
}

// Forwards focus changes made by the iOS focus system (for example, Full
// Keyboard Access) to the framework, mirroring what
// -[SemanticsObject accessibilityElementDidBecomeFocused] does for VoiceOver.
//
// UIKit calls this on every environment in both the previous and the next
// focus chain, so only act when this object is the item that gained or lost
// focus.
- (void)didUpdateFocusInContext:(UIFocusUpdateContext*)context
       withAnimationCoordinator:(UIFocusAnimationCoordinator*)coordinator {
  flutter::AccessibilityBridgeIos* bridge = self.bridge;
  // When VoiceOver is running, the UIAccessibility focus callbacks already
  // dispatch these actions. Avoid duplicates and conflicting focus-loss events
  // when the two focuses diverge.
  if (!bridge || bridge->isVoiceOverRunning()) {
    return;
  }
  // Any completed focus change ends a pending Tab redirect, including focus
  // moving elsewhere by other means (for example, a click).
  if (context.nextFocusedItem == self || context.previouslyFocusedItem == self) {
    ClearPendingFocusTarget(self);
  }
  if (context.nextFocusedItem == self) {
    // The framework scrolls the focused item into view; the focus engine's own
    // scrolling is cancelled (see FlutterSemanticsScrollView). The framework
    // ignores the request if the item is already fully visible.
    if (IsInImplicitlyScrollingContainer(self)) {
      bridge->DispatchSemanticsAction(self.uid, flutter::SemanticsAction::kShowOnScreen);
    }
    if (self.node.HasAction(flutter::SemanticsAction::kFocus)) {
      bridge->DispatchSemanticsAction(self.uid, flutter::SemanticsAction::kFocus);
    }
    if (self.node.HasAction(flutter::SemanticsAction::kDidGainAccessibilityFocus)) {
      bridge->DispatchSemanticsAction(self.uid,
                                      flutter::SemanticsAction::kDidGainAccessibilityFocus);
    }
  } else if (context.previouslyFocusedItem == self) {
    if (self.node.HasAction(flutter::SemanticsAction::kDidLoseAccessibilityFocus)) {
      bridge->DispatchSemanticsAction(self.uid,
                                      flutter::SemanticsAction::kDidLoseAccessibilityFocus);
    }
  }
}

- (id<UIFocusEnvironment>)parentFocusEnvironment {
  // The root SemanticsObject node's parent is the FlutterView.
  return self.parent.focusItem ?: [self bridgeView];
}

- (NSArray<id<UIFocusEnvironment>>*)preferredFocusEnvironments {
  // The root directs a requested focus update to the pending Tab target (see
  // RequestFocusToPendingTarget).
  SemanticsObject* pending = self.parent ? nil : PendingFocusTarget(self);
  return pending ? @[ pending ] : nil;
}

- (id<UIFocusItemContainer>)focusItemContainer {
  return self;
}

#pragma mark - UIFocusItem Conformance

- (BOOL)canBecomeFocused {
  // Hidden nodes inside an implicitly scrolling container are clipped,
  // offscreen items. Keep them focusable so keyboard navigation can reach
  // them; Tab navigation scrolls them into view (see
  // -shouldUpdateFocusInContext:).
  // Nodes clipped by any other container (e.g. a PageView that disallows
  // implicit scrolling) must not receive focus.
  if (self.node.flags.isHidden && !IsInImplicitlyScrollingContainer(self)) {
    return NO;
  }
  // Supports SemanticsObjects that handle -[NSObject accessibilityActivate] or
  // that explicitly opt in to focus.
  return self.node.HasAction(flutter::SemanticsAction::kTap) ||
         self.node.HasAction(flutter::SemanticsAction::kFocus);
}

// The frame is described in the `coordinateSpace` of the
// `parentFocusEnvironment` (all `parentFocusEnvironment`s are `UIFocusItem`s).
//
// See also the `coordinateSpace` implementation.
// TODO(LongCatIsLooong): use CoreGraphics types.
- (CGRect)frame {
  if (!self.bridge) {
    return CGRectZero;
  }
  SkPoint quad[4] = {SkPoint::Make(self.node.rect.left(), self.node.rect.top()),
                     SkPoint::Make(self.node.rect.left(), self.node.rect.bottom()),
                     SkPoint::Make(self.node.rect.right(), self.node.rect.top()),
                     SkPoint::Make(self.node.rect.right(), self.node.rect.bottom())};

  SkM44 transform = self.node.transform;
  FlutterScrollableSemanticsObject* scrollable;
  for (SemanticsObject* ancestor = self.parent; ancestor; ancestor = ancestor.parent) {
    if ([ancestor isKindOfClass:[FlutterScrollableSemanticsObject class]]) {
      scrollable = (FlutterScrollableSemanticsObject*)ancestor;
      break;
    }
    transform = ancestor.node.transform * transform;
  }

  for (auto& vertex : quad) {
    SkV4 vector = transform.map(vertex.x(), vertex.y(), 0, 1);
    vertex = SkPoint::Make(vector.x / vector.w, vector.y / vector.w);
  }

  SkRect rect;
  rect.setBounds({quad, 4});
  // If this UIFocusItemContainer's coordinateSpace is a UIScrollView, offset
  // the rect by the content offset because the content offset translation is
  // incorporated into the paint transform at different node depth in UIKit
  // and Flutter. In Flutter, the translation is added to the cells
  // while in UIKit the viewport's bounds is manipulated (IOW, each cell's frame
  // in the UIScrollView coordinateSpace does not change when the UIScrollView
  // scrolls).
  //
  // Use the scroll offset reported by the framework rather than the
  // UIScrollView's live `contentOffset`. The cell translations come from the
  // same framework update, so the frame stays correct even if UIKit moves the
  // UIScrollView before the next update.
  if (scrollable) {
    CGPoint contentOffset = scrollable.contentOffsetInternal;
    return CGRectMake(rect.x() + contentOffset.x, rect.y() + contentOffset.y, rect.width(),
                      rect.height());
  }
  CGRect unscaledRect = CGRectMake(rect.x(), rect.y(), rect.width(), rect.height());
  // `rect` could be in physical pixels since the root RenderObject ("RenderView")
  // applies a transform that turns logical pixels to physical pixels. Undo the
  // transform by dividing the coordinates by the screen's scale factor, if this
  // UIFocusItem's reported `coordinateSpace` is the root view (which means this
  // UIFocusItem is not inside of a scroll view).
  //
  // Screen can be nil if the FlutterView is covered by another native view.
  UIView* view = self.bridgeView;
  CGFloat scale = (view.window.screen ?: UIScreen.mainScreen).scale;
  return CGRectMake(unscaledRect.origin.x / scale, unscaledRect.origin.y / scale,
                    unscaledRect.size.width / scale, unscaledRect.size.height / scale);
}

#pragma mark - UIFocusItemContainer Conformance

- (NSArray<id<UIFocusItem>>*)focusItemsInRect:(CGRect)rect {
  // It seems the iOS focus system relies heavily on focusItemsInRect
  // (instead of preferredFocusEnvironments) for directional navigation.
  //
  // The order of the items seems to be important, menus and dialogs become
  // unreachable via FKA if the returned children are organized
  // in hit-test order.
  //
  // This method is only supposed to return items within the given
  // rect but returning everything in the subtree seems to work fine.
  NSMutableArray<id<UIFocusItem>>* reversedItems =
      [[NSMutableArray alloc] initWithCapacity:self.childrenInHitTestOrder.count];
  for (NSUInteger i = 0; i < self.childrenInHitTestOrder.count; ++i) {
    SemanticsObject* child = self.childrenInHitTestOrder[self.childrenInHitTestOrder.count - 1 - i];
    [reversedItems addObject:child.focusItem];
  }
  return reversedItems;
}

- (id<UICoordinateSpace>)coordinateSpace {
  // A regular SemanticsObject uses the same coordinate space as its parent.
  return self.parent.coordinateSpace ?: [self bridgeView];
}

@end

/// Scrollable containers interact with the iOS focus engine using the
/// `UIFocusItemScrollableContainer` protocol. The said protocol (and other focus-related protocols)
/// does not provide means to inform the focus system of layout changes. In order for the focus
/// highlight to update properly as the scroll view scrolls, this implementation incorporates a
/// UIScrollView into the focus hierarchy to workaround the highlight update problem.
///
///  As a result, in the current implementation only scrollable containers and the root node
///  establish their own `coordinateSpace`s. All other `UIFocusItemContainter`s use the same
///  `coordinateSpace` as the containing UIScrollView, or the root `FlutterView`, whichever is
///  closer.
///
/// See also the `frame` method implementation.
#pragma mark - Scrolling

@interface FlutterScrollableSemanticsObject (CoordinateSpace)
@end

@implementation FlutterScrollableSemanticsObject (CoordinateSpace)
- (id<UICoordinateSpace>)coordinateSpace {
  // A scrollable SemanticsObject uses the same coordinate space as the scroll view.
  // This may not work very well in nested scroll views.
  return self.scrollView;
}

- (id<UIFocusItem>)focusItem {
  return self.scrollView;
}

@end

@interface FlutterSemanticsScrollView (UIFocusItemScrollableContainer) <
    UIFocusItemScrollableContainer>
@end

@implementation FlutterSemanticsScrollView (UIFocusItemScrollableContainer)

#pragma mark - FlutterSemanticsScrollView UIFocusItemScrollableContainer Conformance

- (CGSize)visibleSize {
  return self.frame.size;
}

- (BOOL)canBecomeFocused {
  return NO;
}

- (id<UIFocusEnvironment>)parentFocusEnvironment {
  return self.semanticsObject.parentFocusEnvironment;
}

- (NSArray<id<UIFocusEnvironment>>*)preferredFocusEnvironments {
  return nil;
}

- (NSArray<id<UIFocusItem>>*)focusItemsInRect:(CGRect)rect {
  return [self.semanticsObject focusItemsInRect:rect];
}
@end
