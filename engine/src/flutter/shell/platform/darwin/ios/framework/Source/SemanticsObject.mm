// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/SemanticsObject.h"

#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformViews_Internal.h"

namespace {

flutter::SemanticsAction GetSemanticsActionForScrollDirection(
    UIAccessibilityScrollDirection direction) {
  // To describe the vertical scroll direction, UIAccessibilityScrollDirection uses the
  // direction the scroll bar moves in and SemanticsAction uses the direction the finger
  // moves in. However, the horizontal scroll direction matches the SemanticsAction direction.
  // That is way the following maps vertical opposite of the SemanticsAction, but the horizontal
  // maps directly.
  switch (direction) {
    case UIAccessibilityScrollDirectionRight:
    case UIAccessibilityScrollDirectionPrevious:  // TODO(abarth): Support RTL using
                                                  // _node.textDirection.
      return flutter::SemanticsAction::kScrollRight;
    case UIAccessibilityScrollDirectionLeft:
    case UIAccessibilityScrollDirectionNext:  // TODO(abarth): Support RTL using
                                              // _node.textDirection.
      return flutter::SemanticsAction::kScrollLeft;
    case UIAccessibilityScrollDirectionUp:
      return flutter::SemanticsAction::kScrollDown;
    case UIAccessibilityScrollDirectionDown:
      return flutter::SemanticsAction::kScrollUp;
  }
  FML_DCHECK(false);  // Unreachable
  return flutter::SemanticsAction::kScrollUp;
}

}  // namespace

@implementation FlutterSwitchSemanticsObject {
  SemanticsObject* _semanticsObject;
}

- (instancetype)initWithSemanticsObject:(SemanticsObject*)semanticsObject {
  self = [super init];
  if (self) {
    _semanticsObject = [semanticsObject retain];
  }
  return self;
}

- (void)dealloc {
  [_semanticsObject release];
  [super dealloc];
}

- (NSMethodSignature*)methodSignatureForSelector:(SEL)sel {
  NSMethodSignature* result = [super methodSignatureForSelector:sel];
  if (!result) {
    result = [_semanticsObject methodSignatureForSelector:sel];
  }
  return result;
}

- (void)forwardInvocation:(NSInvocation*)anInvocation {
  [anInvocation setTarget:_semanticsObject];
  [anInvocation invoke];
}

- (CGRect)accessibilityFrame {
  return [_semanticsObject accessibilityFrame];
}

- (id)accessibilityContainer {
  return [_semanticsObject accessibilityContainer];
}

- (NSString*)accessibilityLabel {
  return [_semanticsObject accessibilityLabel];
}

- (NSString*)accessibilityHint {
  return [_semanticsObject accessibilityHint];
}

- (NSString*)accessibilityValue {
  if ([_semanticsObject node].HasFlag(flutter::SemanticsFlags::kIsToggled) ||
      [_semanticsObject node].HasFlag(flutter::SemanticsFlags::kIsChecked)) {
    self.on = YES;
  } else {
    self.on = NO;
  }

  if (![_semanticsObject isAccessibilityBridgeAlive]) {
    return nil;
  } else {
    return [super accessibilityValue];
  }
}

@end  // FlutterSwitchSemanticsObject

@implementation FlutterCustomAccessibilityAction {
}
@end

@interface SemanticsObject ()
/** Should only be called in conjunction with setting child/parent relationship. */
- (void)privateSetParent:(SemanticsObject*)parent;
@end

@implementation SemanticsObject {
  fml::scoped_nsobject<SemanticsObjectContainer> _container;
  NSMutableArray<SemanticsObject*>* _children;
}

#pragma mark - Override base class designated initializers

// Method declared as unavailable in the interface
- (instancetype)init {
  [self release];
  [super doesNotRecognizeSelector:_cmd];
  return nil;
}

#pragma mark - Designated initializers

- (instancetype)initWithBridge:(fml::WeakPtr<flutter::AccessibilityBridgeIos>)bridge
                           uid:(int32_t)uid {
  FML_DCHECK(bridge) << "bridge must be set";
  FML_DCHECK(uid >= kRootNodeId);
  // Initialize with the UIView as the container.
  // The UIView will not necessarily be accessibility parent for this object.
  // The bridge informs the OS of the actual structure via
  // `accessibilityContainer` and `accessibilityElementAtIndex`.
  self = [super initWithAccessibilityContainer:bridge->view()];

  if (self) {
    _bridge = bridge;
    _uid = uid;
    _children = [[NSMutableArray alloc] init];
  }

  return self;
}

- (void)dealloc {
  for (SemanticsObject* child in _children) {
    [child privateSetParent:nil];
  }
  [_children removeAllObjects];
  [_children release];
  _parent = nil;
  _container.get().semanticsObject = nil;
  [_platformViewSemanticsContainer release];
  [super dealloc];
}

#pragma mark - Semantic object methods

- (BOOL)isAccessibilityBridgeAlive {
  return [self bridge].get() != nil;
}

- (void)setSemanticsNode:(const flutter::SemanticsNode*)node {
  _node = *node;
}

/**
 * Whether calling `setSemanticsNode:` with `node` would cause a layout change.
 */
- (BOOL)nodeWillCauseLayoutChange:(const flutter::SemanticsNode*)node {
  return [self node].rect != node->rect || [self node].transform != node->transform;
}

/**
 * Whether calling `setSemanticsNode:` with `node` would cause a scroll event.
 */
- (BOOL)nodeWillCauseScroll:(const flutter::SemanticsNode*)node {
  return !isnan([self node].scrollPosition) && !isnan(node->scrollPosition) &&
         [self node].scrollPosition != node->scrollPosition;
}

/**
 * Whether calling `setSemanticsNode:` with `node` should trigger an
 * announcement.
 */
- (BOOL)nodeShouldTriggerAnnouncement:(const flutter::SemanticsNode*)node {
  // The node dropped the live region flag, if it ever had one.
  if (!node || !node->HasFlag(flutter::SemanticsFlags::kIsLiveRegion)) {
    return NO;
  }

  // The node has gained a new live region flag, always announce.
  if (![self node].HasFlag(flutter::SemanticsFlags::kIsLiveRegion)) {
    return YES;
  }

  // The label has updated, and the new node has a live region flag.
  return [self node].label != node->label;
}

- (BOOL)hasChildren {
  if (_node.IsPlatformViewNode()) {
    return YES;
  }
  return [self.children count] != 0;
}

- (void)privateSetParent:(SemanticsObject*)parent {
  _parent = parent;
}

- (void)setChildren:(NSArray<SemanticsObject*>*)children {
  for (SemanticsObject* child in _children) {
    [child privateSetParent:nil];
  }
  [_children release];
  _children = [[NSMutableArray alloc] initWithArray:children];
  for (SemanticsObject* child in _children) {
    [child privateSetParent:self];
  }
}

- (void)replaceChildAtIndex:(NSInteger)index withChild:(SemanticsObject*)child {
  SemanticsObject* oldChild = _children[index];
  [oldChild privateSetParent:nil];
  [child privateSetParent:self];
  [_children replaceObjectAtIndex:index withObject:child];
}

#pragma mark - UIAccessibility overrides

- (BOOL)isAccessibilityElement {
  if (![self isAccessibilityBridgeAlive])
    return false;

  // Note: hit detection will only apply to elements that report
  // -isAccessibilityElement of YES. The framework will continue scanning the
  // entire element tree looking for such a hit.

  //  We enforce in the framework that no other useful semantics are merged with these nodes.
  if ([self node].HasFlag(flutter::SemanticsFlags::kScopesRoute))
    return false;

  // If the only flag(s) set are scrolling related AND
  // The only flags set are not kIsHidden OR
  // The node doesn't have a label, value, or hint OR
  // The only actions set are scrolling related actions.
  //
  // The kIsHidden flag set with any other flag just means this node is now
  // hidden but still is a valid target for a11y focus in the tree, e.g. a list
  // item that is currently off screen but the a11y navigation needs to know
  // about.
  return (([self node].flags & ~flutter::kScrollableSemanticsFlags) != 0 &&
          [self node].flags != static_cast<int32_t>(flutter::SemanticsFlags::kIsHidden)) ||
         ![self node].label.empty() || ![self node].value.empty() || ![self node].hint.empty() ||
         ([self node].actions & ~flutter::kScrollableSemanticsActions) != 0;
}

- (void)collectRoutes:(NSMutableArray<SemanticsObject*>*)edges {
  if ([self node].HasFlag(flutter::SemanticsFlags::kScopesRoute))
    [edges addObject:self];
  if ([self hasChildren]) {
    for (SemanticsObject* child in self.children) {
      [child collectRoutes:edges];
    }
  }
}

- (BOOL)onCustomAccessibilityAction:(FlutterCustomAccessibilityAction*)action {
  if (![self node].HasAction(flutter::SemanticsAction::kCustomAction))
    return NO;
  int32_t action_id = action.uid;
  std::vector<uint8_t> args;
  args.push_back(3);  // type=int32.
  args.push_back(action_id);
  args.push_back(action_id >> 8);
  args.push_back(action_id >> 16);
  args.push_back(action_id >> 24);
  [self bridge]->DispatchSemanticsAction([self uid], flutter::SemanticsAction::kCustomAction,
                                         std::move(args));
  return YES;
}

- (NSString*)routeName {
  // Returns the first non-null and non-empty semantic label of a child
  // with an NamesRoute flag. Otherwise returns nil.
  if ([self node].HasFlag(flutter::SemanticsFlags::kNamesRoute)) {
    NSString* newName = [self accessibilityLabel];
    if (newName != nil && [newName length] > 0) {
      return newName;
    }
  }
  if ([self hasChildren]) {
    for (SemanticsObject* child in self.children) {
      NSString* newName = [child routeName];
      if (newName != nil && [newName length] > 0) {
        return newName;
      }
    }
  }
  return nil;
}

- (NSString*)accessibilityLabel {
  if (![self isAccessibilityBridgeAlive])
    return nil;

  if ([self node].label.empty())
    return nil;
  return @([self node].label.data());
}

- (NSString*)accessibilityHint {
  if (![self isAccessibilityBridgeAlive])
    return nil;

  if ([self node].hint.empty())
    return nil;
  return @([self node].hint.data());
}

- (NSString*)accessibilityValue {
  if (![self isAccessibilityBridgeAlive])
    return nil;

  if (![self node].value.empty()) {
    return @([self node].value.data());
  }

  // FlutterSwitchSemanticsObject should supercede these conditionals.
  if ([self node].HasFlag(flutter::SemanticsFlags::kHasToggledState) ||
      [self node].HasFlag(flutter::SemanticsFlags::kHasCheckedState)) {
    if ([self node].HasFlag(flutter::SemanticsFlags::kIsToggled) ||
        [self node].HasFlag(flutter::SemanticsFlags::kIsChecked)) {
      return @"1";
    } else {
      return @"0";
    }
  }

  return nil;
}

- (CGRect)accessibilityFrame {
  if (![self isAccessibilityBridgeAlive])
    return CGRectMake(0, 0, 0, 0);

  if ([self node].HasFlag(flutter::SemanticsFlags::kIsHidden)) {
    return [super accessibilityFrame];
  }
  return [self globalRect];
}

- (CGRect)globalRect {
  SkM44 globalTransform = [self node].transform;
  for (SemanticsObject* parent = [self parent]; parent; parent = parent.parent) {
    globalTransform = parent.node.transform * globalTransform;
  }

  SkPoint quad[4];
  [self node].rect.toQuad(quad);
  for (auto& point : quad) {
    SkV4 vector = globalTransform.map(point.x(), point.y(), 0, 1);
    point.set(vector.x / vector.w, vector.y / vector.w);
  }
  SkRect rect;
  rect.setBounds(quad, 4);

  // `rect` is in the physical pixel coordinate system. iOS expects the accessibility frame in
  // the logical pixel coordinate system. Therefore, we divide by the `scale` (pixel ratio) to
  // convert.
  CGFloat scale = [[[self bridge]->view() window] screen].scale;
  auto result =
      CGRectMake(rect.x() / scale, rect.y() / scale, rect.width() / scale, rect.height() / scale);
  return UIAccessibilityConvertFrameToScreenCoordinates(result, [self bridge]->view());
}

#pragma mark - UIAccessibilityElement protocol

- (void)setAccessibilityContainer:(id)container {
  // Explicit noop.  The containers are calculated lazily in `accessibilityContainer`.
  // See also: https://github.com/flutter/flutter/issues/54366
}

- (id)accessibilityContainer {
  if ([self hasChildren] || [self uid] == kRootNodeId) {
    if (_container == nil)
      _container.reset([[SemanticsObjectContainer alloc] initWithSemanticsObject:self
                                                                          bridge:[self bridge]]);
    return _container.get();
  }
  if ([self parent] == nil) {
    // This can happen when we have released the accessibility tree but iOS is
    // still holding onto our objects. iOS can take some time before it
    // realizes that the tree has changed.
    return nil;
  }
  return [[self parent] accessibilityContainer];
}

#pragma mark - UIAccessibilityAction overrides

- (BOOL)accessibilityActivate {
  if (![self isAccessibilityBridgeAlive])
    return NO;
  if (![self node].HasAction(flutter::SemanticsAction::kTap))
    return NO;
  [self bridge]->DispatchSemanticsAction([self uid], flutter::SemanticsAction::kTap);
  return YES;
}

- (void)accessibilityIncrement {
  if (![self isAccessibilityBridgeAlive])
    return;
  if ([self node].HasAction(flutter::SemanticsAction::kIncrease)) {
    [self node].value = [self node].increasedValue;
    [self bridge]->DispatchSemanticsAction([self uid], flutter::SemanticsAction::kIncrease);
  }
}

- (void)accessibilityDecrement {
  if (![self isAccessibilityBridgeAlive])
    return;
  if ([self node].HasAction(flutter::SemanticsAction::kDecrease)) {
    [self node].value = [self node].decreasedValue;
    [self bridge]->DispatchSemanticsAction([self uid], flutter::SemanticsAction::kDecrease);
  }
}

- (BOOL)accessibilityScroll:(UIAccessibilityScrollDirection)direction {
  if (![self isAccessibilityBridgeAlive])
    return NO;
  flutter::SemanticsAction action = GetSemanticsActionForScrollDirection(direction);
  if (![self node].HasAction(action))
    return NO;
  [self bridge]->DispatchSemanticsAction([self uid], action);
  return YES;
}

- (BOOL)accessibilityPerformEscape {
  if (![self isAccessibilityBridgeAlive])
    return NO;
  if (![self node].HasAction(flutter::SemanticsAction::kDismiss))
    return NO;
  [self bridge]->DispatchSemanticsAction([self uid], flutter::SemanticsAction::kDismiss);
  return YES;
}

#pragma mark UIAccessibilityFocus overrides

- (void)accessibilityElementDidBecomeFocused {
  if (![self isAccessibilityBridgeAlive])
    return;
  [self bridge]->AccessibilityObjectDidBecomeFocused([self uid]);
  if ([self node].HasFlag(flutter::SemanticsFlags::kIsHidden) ||
      [self node].HasFlag(flutter::SemanticsFlags::kIsHeader)) {
    [self bridge]->DispatchSemanticsAction([self uid], flutter::SemanticsAction::kShowOnScreen);
  }
  if ([self node].HasAction(flutter::SemanticsAction::kDidGainAccessibilityFocus)) {
    [self bridge]->DispatchSemanticsAction([self uid],
                                           flutter::SemanticsAction::kDidGainAccessibilityFocus);
  }
}

- (void)accessibilityElementDidLoseFocus {
  if (![self isAccessibilityBridgeAlive])
    return;
  [self bridge]->AccessibilityObjectDidLoseFocus([self uid]);
  if ([self node].HasAction(flutter::SemanticsAction::kDidLoseAccessibilityFocus)) {
    [self bridge]->DispatchSemanticsAction([self uid],
                                           flutter::SemanticsAction::kDidLoseAccessibilityFocus);
  }
}

@end

@implementation FlutterSemanticsObject {
}

#pragma mark - Override base class designated initializers

// Method declared as unavailable in the interface
- (instancetype)init {
  [self release];
  [super doesNotRecognizeSelector:_cmd];
  return nil;
}

#pragma mark - Designated initializers

- (instancetype)initWithBridge:(fml::WeakPtr<flutter::AccessibilityBridgeIos>)bridge
                           uid:(int32_t)uid {
  self = [super initWithBridge:bridge uid:uid];
  return self;
}

#pragma mark - UIAccessibility overrides

- (UIAccessibilityTraits)accessibilityTraits {
  UIAccessibilityTraits traits = UIAccessibilityTraitNone;
  if ([self node].HasAction(flutter::SemanticsAction::kIncrease) ||
      [self node].HasAction(flutter::SemanticsAction::kDecrease)) {
    traits |= UIAccessibilityTraitAdjustable;
  }
  // FlutterSwitchSemanticsObject should supercede these conditionals.
  if ([self node].HasFlag(flutter::SemanticsFlags::kHasToggledState) ||
      [self node].HasFlag(flutter::SemanticsFlags::kHasCheckedState)) {
    traits |= UIAccessibilityTraitButton;
  }
  if ([self node].HasFlag(flutter::SemanticsFlags::kIsSelected)) {
    traits |= UIAccessibilityTraitSelected;
  }
  if ([self node].HasFlag(flutter::SemanticsFlags::kIsButton)) {
    traits |= UIAccessibilityTraitButton;
  }
  if ([self node].HasFlag(flutter::SemanticsFlags::kHasEnabledState) &&
      ![self node].HasFlag(flutter::SemanticsFlags::kIsEnabled)) {
    traits |= UIAccessibilityTraitNotEnabled;
  }
  if ([self node].HasFlag(flutter::SemanticsFlags::kIsHeader)) {
    traits |= UIAccessibilityTraitHeader;
  }
  if ([self node].HasFlag(flutter::SemanticsFlags::kIsImage)) {
    traits |= UIAccessibilityTraitImage;
  }
  if ([self node].HasFlag(flutter::SemanticsFlags::kIsLiveRegion)) {
    traits |= UIAccessibilityTraitUpdatesFrequently;
  }
  if ([self node].HasFlag(flutter::SemanticsFlags::kIsLink)) {
    traits |= UIAccessibilityTraitLink;
  }
  return traits;
}

@end

@interface FlutterPlatformViewSemanticsContainer ()
@property(nonatomic, assign) SemanticsObject* semanticsObject;
@property(nonatomic, strong) UIView* platformView;
@end

@implementation FlutterPlatformViewSemanticsContainer

// Method declared as unavailable in the interface
- (instancetype)init {
  [self release];
  [super doesNotRecognizeSelector:_cmd];
  return nil;
}

- (instancetype)initWithSemanticsObject:(SemanticsObject*)object {
  FML_CHECK(object);
  // Initialize with the UIView as the container.
  // The UIView will not necessarily be accessibility parent for this object.
  // The bridge informs the OS of the actual structure via
  // `accessibilityContainer` and `accessibilityElementAtIndex`.
  if (self = [super initWithAccessibilityContainer:object.bridge->view()]) {
    _semanticsObject = object;
    auto controller = object.bridge->GetPlatformViewsController();
    if (controller) {
      _platformView = [controller->GetPlatformViewByID(object.node.platformViewId) retain];
    }
  }
  return self;
}

- (void)dealloc {
  [_platformView release];
  _platformView = nil;
  [super dealloc];
}

- (NSArray*)accessibilityElements {
  return @[ _semanticsObject, _platformView ];
}

- (CGRect)accessibilityFrame {
  return _semanticsObject.accessibilityFrame;
}

- (BOOL)isAccessibilityElement {
  return NO;
}

- (id)accessibilityContainer {
  return [_semanticsObject accessibilityContainer];
}

- (BOOL)accessibilityScroll:(UIAccessibilityScrollDirection)direction {
  return [_platformView accessibilityScroll:direction];
}

@end

@implementation SemanticsObjectContainer {
  SemanticsObject* _semanticsObject;
  fml::WeakPtr<flutter::AccessibilityBridgeIos> _bridge;
}

#pragma mark - initializers

// Method declared as unavailable in the interface
- (instancetype)init {
  [self release];
  [super doesNotRecognizeSelector:_cmd];
  return nil;
}

- (instancetype)initWithSemanticsObject:(SemanticsObject*)semanticsObject
                                 bridge:(fml::WeakPtr<flutter::AccessibilityBridgeIos>)bridge {
  FML_DCHECK(semanticsObject) << "semanticsObject must be set";
  // Initialize with the UIView as the container.
  // The UIView will not necessarily be accessibility parent for this object.
  // The bridge informs the OS of the actual structure via
  // `accessibilityContainer` and `accessibilityElementAtIndex`.
  self = [super initWithAccessibilityContainer:bridge->view()];

  if (self) {
    _semanticsObject = semanticsObject;
    _bridge = bridge;
  }

  return self;
}

#pragma mark - UIAccessibilityContainer overrides

- (NSInteger)accessibilityElementCount {
  NSInteger count = [[_semanticsObject children] count] + 1;
  return count;
}

- (nullable id)accessibilityElementAtIndex:(NSInteger)index {
  if (index < 0 || index >= [self accessibilityElementCount])
    return nil;
  if (index == 0) {
    return _semanticsObject;
  }

  SemanticsObject* child = [_semanticsObject children][index - 1];

  // Swap the original `SemanticsObject` to a `PlatformViewSemanticsContainer`
  if (child.node.IsPlatformViewNode()) {
    child.platformViewSemanticsContainer.index = index;
    return child.platformViewSemanticsContainer;
  }

  if ([child hasChildren])
    return [child accessibilityContainer];
  return child;
}

- (NSInteger)indexOfAccessibilityElement:(id)element {
  if (element == _semanticsObject)
    return 0;

  // FlutterPlatformViewSemanticsContainer is always the last element of its parent.
  if ([element isKindOfClass:[FlutterPlatformViewSemanticsContainer class]]) {
    return ((FlutterPlatformViewSemanticsContainer*)element).index;
  }

  NSArray<SemanticsObject*>* children = [_semanticsObject children];
  for (size_t i = 0; i < [children count]; i++) {
    SemanticsObject* child = children[i];
    if ((![child hasChildren] && child == element) ||
        ([child hasChildren] && [child accessibilityContainer] == element))
      return i + 1;
  }
  return NSNotFound;
}

#pragma mark - UIAccessibilityElement protocol

- (BOOL)isAccessibilityElement {
  return NO;
}

- (CGRect)accessibilityFrame {
  return [_semanticsObject accessibilityFrame];
}

- (id)accessibilityContainer {
  if (!_bridge) {
    return nil;
  }
  return ([_semanticsObject uid] == kRootNodeId)
             ? _bridge->view()
             : [[_semanticsObject parent] accessibilityContainer];
}

#pragma mark - UIAccessibilityAction overrides

- (BOOL)accessibilityScroll:(UIAccessibilityScrollDirection)direction {
  return [_semanticsObject accessibilityScroll:direction];
}

@end
