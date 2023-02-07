// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/SemanticsObject.h"

#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformViews_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterSemanticsScrollView.h"

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

SkM44 GetGlobalTransform(SemanticsObject* reference) {
  SkM44 globalTransform = [reference node].transform;
  for (SemanticsObject* parent = [reference parent]; parent; parent = parent.parent) {
    globalTransform = parent.node.transform * globalTransform;
  }
  return globalTransform;
}

SkPoint ApplyTransform(SkPoint& point, const SkM44& transform) {
  SkV4 vector = transform.map(point.x(), point.y(), 0, 1);
  return SkPoint::Make(vector.x / vector.w, vector.y / vector.w);
}

CGPoint ConvertPointToGlobal(SemanticsObject* reference, CGPoint local_point) {
  SkM44 globalTransform = GetGlobalTransform(reference);
  SkPoint point = SkPoint::Make(local_point.x, local_point.y);
  point = ApplyTransform(point, globalTransform);
  // `rect` is in the physical pixel coordinate system. iOS expects the accessibility frame in
  // the logical pixel coordinate system. Therefore, we divide by the `scale` (pixel ratio) to
  // convert.
  UIScreen* screen = [[[reference bridge]->view() window] screen];
  // Screen can be nil if the FlutterView is covered by another native view.
  CGFloat scale = screen == nil ? [UIScreen mainScreen].scale : screen.scale;
  auto result = CGPointMake(point.x() / scale, point.y() / scale);
  return [[reference bridge]->view() convertPoint:result toView:nil];
}

CGRect ConvertRectToGlobal(SemanticsObject* reference, CGRect local_rect) {
  SkM44 globalTransform = GetGlobalTransform(reference);

  SkPoint quad[4] = {
      SkPoint::Make(local_rect.origin.x, local_rect.origin.y),                          // top left
      SkPoint::Make(local_rect.origin.x + local_rect.size.width, local_rect.origin.y),  // top right
      SkPoint::Make(local_rect.origin.x + local_rect.size.width,
                    local_rect.origin.y + local_rect.size.height),  // bottom right
      SkPoint::Make(local_rect.origin.x,
                    local_rect.origin.y + local_rect.size.height)  // bottom left
  };
  for (auto& point : quad) {
    point = ApplyTransform(point, globalTransform);
  }
  SkRect rect;
  NSCAssert(rect.setBoundsCheck(quad, 4), @"Transformed points can't form a rect");
  rect.setBounds(quad, 4);

  // `rect` is in the physical pixel coordinate system. iOS expects the accessibility frame in
  // the logical pixel coordinate system. Therefore, we divide by the `scale` (pixel ratio) to
  // convert.
  UIScreen* screen = [[[reference bridge]->view() window] screen];
  // Screen can be nil if the FlutterView is covered by another native view.
  CGFloat scale = screen == nil ? [UIScreen mainScreen].scale : screen.scale;
  auto result =
      CGRectMake(rect.x() / scale, rect.y() / scale, rect.width() / scale, rect.height() / scale);
  return UIAccessibilityConvertFrameToScreenCoordinates(result, [reference bridge]->view());
}

}  // namespace

@interface FlutterSwitchSemanticsObject ()
@property(nonatomic, readonly) UISwitch* nativeSwitch;
@end

@implementation FlutterSwitchSemanticsObject

- (instancetype)initWithBridge:(fml::WeakPtr<flutter::AccessibilityBridgeIos>)bridge
                           uid:(int32_t)uid {
  self = [super initWithBridge:bridge uid:uid];
  if (self) {
    _nativeSwitch = [[UISwitch alloc] init];
  }
  return self;
}

- (void)dealloc {
  [_nativeSwitch release];
  [super dealloc];
}

- (NSMethodSignature*)methodSignatureForSelector:(SEL)sel {
  NSMethodSignature* result = [super methodSignatureForSelector:sel];
  if (!result) {
    result = [_nativeSwitch methodSignatureForSelector:sel];
  }
  return result;
}

- (void)forwardInvocation:(NSInvocation*)anInvocation {
  [anInvocation setTarget:_nativeSwitch];
  [anInvocation invoke];
}

- (NSString*)accessibilityValue {
  if ([self node].HasFlag(flutter::SemanticsFlags::kIsToggled) ||
      [self node].HasFlag(flutter::SemanticsFlags::kIsChecked)) {
    _nativeSwitch.on = YES;
  } else {
    _nativeSwitch.on = NO;
  }

  if (![self isAccessibilityBridgeAlive]) {
    return nil;
  } else {
    return _nativeSwitch.accessibilityValue;
  }
}

- (UIAccessibilityTraits)accessibilityTraits {
  if ([self node].HasFlag(flutter::SemanticsFlags::kIsEnabled)) {
    _nativeSwitch.enabled = YES;
  } else {
    _nativeSwitch.enabled = NO;
  }

  return _nativeSwitch.accessibilityTraits;
}

@end  // FlutterSwitchSemanticsObject

@interface FlutterScrollableSemanticsObject ()
@property(nonatomic, retain) FlutterSemanticsScrollView* scrollView;
@end

@implementation FlutterScrollableSemanticsObject {
  fml::scoped_nsobject<SemanticsObjectContainer> _container;
}

- (instancetype)initWithBridge:(fml::WeakPtr<flutter::AccessibilityBridgeIos>)bridge
                           uid:(int32_t)uid {
  self = [super initWithBridge:bridge uid:uid];
  if (self) {
    _scrollView = [[FlutterSemanticsScrollView alloc] initWithSemanticsObject:self];
    [_scrollView setShowsHorizontalScrollIndicator:NO];
    [_scrollView setShowsVerticalScrollIndicator:NO];
    [self.bridge->view() addSubview:_scrollView];
  }
  return self;
}

- (void)dealloc {
  [_scrollView removeFromSuperview];
  _scrollView.semanticsObject = nil;
  [_scrollView release];
  [super dealloc];
}

- (void)accessibilityBridgeDidFinishUpdate {
  // In order to make iOS think this UIScrollView is scrollable, the following
  // requirements must be true.
  // 1. contentSize must be bigger than the frame size.
  // 2. The scrollable isAccessibilityElement must return YES
  //
  // Once the requirements are met, the iOS uses contentOffset to determine
  // what scroll actions are available. e.g. If the view scrolls vertically and
  // contentOffset is 0.0, only the scroll down action is available.
  [_scrollView setFrame:[self accessibilityFrame]];
  [_scrollView setContentSize:[self contentSizeInternal]];
  [_scrollView setContentOffset:[self contentOffsetInternal] animated:NO];
}

- (id)nativeAccessibility {
  return _scrollView;
}

// private methods

- (float)scrollExtentMax {
  if (![self isAccessibilityBridgeAlive]) {
    return 0.0f;
  }
  float scrollExtentMax = self.node.scrollExtentMax;
  if (isnan(scrollExtentMax)) {
    scrollExtentMax = 0.0f;
  } else if (!isfinite(scrollExtentMax)) {
    scrollExtentMax = kScrollExtentMaxForInf + [self scrollPosition];
  }
  return scrollExtentMax;
}

- (float)scrollPosition {
  if (![self isAccessibilityBridgeAlive]) {
    return 0.0f;
  }
  float scrollPosition = self.node.scrollPosition;
  if (isnan(scrollPosition)) {
    scrollPosition = 0.0f;
  }
  NSCAssert(isfinite(scrollPosition), @"The scrollPosition must not be infinity");
  return scrollPosition;
}

- (CGSize)contentSizeInternal {
  CGRect result;
  const SkRect& rect = self.node.rect;

  if (self.node.actions & flutter::kVerticalScrollSemanticsActions) {
    result = CGRectMake(rect.x(), rect.y(), rect.width(), rect.height() + [self scrollExtentMax]);
  } else if (self.node.actions & flutter::kHorizontalScrollSemanticsActions) {
    result = CGRectMake(rect.x(), rect.y(), rect.width() + [self scrollExtentMax], rect.height());
  } else {
    result = CGRectMake(rect.x(), rect.y(), rect.width(), rect.height());
  }
  return ConvertRectToGlobal(self, result).size;
}

- (CGPoint)contentOffsetInternal {
  CGPoint result;
  CGPoint origin = _scrollView.frame.origin;
  const SkRect& rect = self.node.rect;
  if (self.node.actions & flutter::kVerticalScrollSemanticsActions) {
    result = ConvertPointToGlobal(self, CGPointMake(rect.x(), rect.y() + [self scrollPosition]));
  } else if (self.node.actions & flutter::kHorizontalScrollSemanticsActions) {
    result = ConvertPointToGlobal(self, CGPointMake(rect.x() + [self scrollPosition], rect.y()));
  } else {
    result = origin;
  }
  return CGPointMake(result.x - origin.x, result.y - origin.y);
}

@end  // FlutterScrollableSemanticsObject

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
  NSMutableArray<SemanticsObject*>* _childrenInHitTestOrder;
  BOOL _inDealloc;
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
    _childrenInHitTestOrder = [[NSMutableArray alloc] init];
  }

  return self;
}

- (void)dealloc {
  for (SemanticsObject* child in _children) {
    [child privateSetParent:nil];
  }
  [_children removeAllObjects];
  [_childrenInHitTestOrder removeAllObjects];
  [_children release];
  [_childrenInHitTestOrder release];

  _parent = nil;
  _container.get().semanticsObject = nil;
  _inDealloc = YES;
  [super dealloc];
}

#pragma mark - Semantic object property accesser

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

- (void)setChildrenInHitTestOrder:(NSArray<SemanticsObject*>*)childrenInHitTestOrder {
  for (SemanticsObject* child in _childrenInHitTestOrder) {
    [child privateSetParent:nil];
  }
  [_childrenInHitTestOrder release];
  _childrenInHitTestOrder = [[NSMutableArray alloc] initWithArray:childrenInHitTestOrder];
  for (SemanticsObject* child in _childrenInHitTestOrder) {
    [child privateSetParent:self];
  }
}

- (BOOL)hasChildren {
  return [self.children count] != 0;
}

#pragma mark - Semantic object method

- (BOOL)isAccessibilityBridgeAlive {
  return [self bridge].get() != nil;
}

- (void)setSemanticsNode:(const flutter::SemanticsNode*)node {
  _node = *node;
}

- (void)accessibilityBridgeDidFinishUpdate { /* Do nothing by default */
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

- (void)replaceChildAtIndex:(NSInteger)index withChild:(SemanticsObject*)child {
  SemanticsObject* oldChild = _children[index];
  [oldChild privateSetParent:nil];
  [child privateSetParent:self];
  [_children replaceObjectAtIndex:index withObject:child];
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

- (id)nativeAccessibility {
  return self;
}

#pragma mark - Semantic object private method

- (void)privateSetParent:(SemanticsObject*)parent {
  _parent = parent;
}

- (NSAttributedString*)createAttributedStringFromString:(NSString*)string
                                         withAttributes:
                                             (const flutter::StringAttributes&)attributes {
  NSMutableAttributedString* attributedString =
      [[[NSMutableAttributedString alloc] initWithString:string] autorelease];
  for (const auto& attribute : attributes) {
    NSRange range = NSMakeRange(attribute->start, attribute->end - attribute->start);
    switch (attribute->type) {
      case flutter::StringAttributeType::kLocale: {
        std::shared_ptr<flutter::LocaleStringAttribute> locale_attribute =
            std::static_pointer_cast<flutter::LocaleStringAttribute>(attribute);
        NSDictionary* attributeDict = @{
          UIAccessibilitySpeechAttributeLanguage : @(locale_attribute->locale.data()),
        };
        [attributedString setAttributes:attributeDict range:range];
        break;
      }
      case flutter::StringAttributeType::kSpellOut: {
        if (@available(iOS 13.0, *)) {
          NSDictionary* attributeDict = @{
            UIAccessibilitySpeechAttributeSpellOut : @YES,
          };
          [attributedString setAttributes:attributeDict range:range];
        }
        break;
      }
    }
  }
  return attributedString;
}

#pragma mark - UIAccessibility overrides

- (BOOL)isAccessibilityElement {
  if (![self isAccessibilityBridgeAlive]) {
    return false;
  }

  // Note: hit detection will only apply to elements that report
  // -isAccessibilityElement of YES. The framework will continue scanning the
  // entire element tree looking for such a hit.

  //  We enforce in the framework that no other useful semantics are merged with these nodes.
  if ([self node].HasFlag(flutter::SemanticsFlags::kScopesRoute)) {
    return false;
  }

  return [self isFocusable];
}

- (bool)isFocusable {
  // If the node is scrollable AND hidden OR
  // The node has a label, value, or hint OR
  // The node has non-scrolling related actions.
  //
  // The kIsHidden flag set with the scrollable flag means this node is now
  // hidden but still is a valid target for a11y focus in the tree, e.g. a list
  // item that is currently off screen but the a11y navigation needs to know
  // about.
  return (([self node].flags & flutter::kScrollableSemanticsFlags) != 0 &&
          ([self node].flags & static_cast<int32_t>(flutter::SemanticsFlags::kIsHidden)) != 0) ||
         ![self node].label.empty() || ![self node].value.empty() || ![self node].hint.empty() ||
         ([self node].actions & ~flutter::kScrollableSemanticsActions) != 0;
}

- (void)collectRoutes:(NSMutableArray<SemanticsObject*>*)edges {
  if ([self node].HasFlag(flutter::SemanticsFlags::kScopesRoute)) {
    [edges addObject:self];
  }
  if ([self hasChildren]) {
    for (SemanticsObject* child in self.children) {
      [child collectRoutes:edges];
    }
  }
}

- (BOOL)onCustomAccessibilityAction:(FlutterCustomAccessibilityAction*)action {
  if (![self node].HasAction(flutter::SemanticsAction::kCustomAction)) {
    return NO;
  }
  int32_t action_id = action.uid;
  std::vector<uint8_t> args;
  args.push_back(3);  // type=int32.
  args.push_back(action_id);
  args.push_back(action_id >> 8);
  args.push_back(action_id >> 16);
  args.push_back(action_id >> 24);
  [self bridge]->DispatchSemanticsAction(
      [self uid], flutter::SemanticsAction::kCustomAction,
      fml::MallocMapping::Copy(args.data(), args.size() * sizeof(uint8_t)));
  return YES;
}

- (NSString*)accessibilityLabel {
  if (![self isAccessibilityBridgeAlive]) {
    return nil;
  }
  NSString* label = nil;
  if (![self node].label.empty()) {
    label = @([self node].label.data());
  }
  if (![self node].tooltip.empty()) {
    label = label ? [NSString stringWithFormat:@"%@\n%@", label, @([self node].tooltip.data())]
                  : @([self node].tooltip.data());
  }
  return label;
}

- (bool)containsPoint:(CGPoint)point {
  // The point is in global coordinates, so use the global rect here.
  return CGRectContainsPoint([self globalRect], point);
}

// Finds the first eligiable semantics object in hit test order.
- (SemanticsObject*)search:(CGPoint)point {
  // Search children in hit test order.
  for (SemanticsObject* child in [self childrenInHitTestOrder]) {
    if ([child containsPoint:point]) {
      SemanticsObject* childSearchResult = [child search:point];
      if (childSearchResult != nil) {
        return childSearchResult;
      }
    }
  }

  // Check if the current semantic object should be returned.
  if ([self containsPoint:point] && [self isFocusable]) {
    return self.nativeAccessibility;
  }
  return nil;
}

// Overrides apple private method to fix https://github.com/flutter/flutter/issues/113377.
// For overlapping UIAccessibilityElements (e.g. a stack) in IOS, the focus goes to the smallest
// object before IOS 16, but to the top-left object in IOS 16.
// Overrides this method to focus the first eligiable semantics object in hit test order.
- (id)_accessibilityHitTest:(CGPoint)point withEvent:(UIEvent*)event {
  return [self search:point];
}

- (NSAttributedString*)accessibilityAttributedLabel {
  NSString* label = [self accessibilityLabel];
  if (label.length == 0) {
    return nil;
  }
  return [self createAttributedStringFromString:label withAttributes:[self node].labelAttributes];
}

- (NSString*)accessibilityHint {
  if (![self isAccessibilityBridgeAlive]) {
    return nil;
  }

  if ([self node].hint.empty()) {
    return nil;
  }
  return @([self node].hint.data());
}

- (NSAttributedString*)accessibilityAttributedHint {
  NSString* hint = [self accessibilityHint];
  if (hint.length == 0) {
    return nil;
  }
  return [self createAttributedStringFromString:hint withAttributes:[self node].hintAttributes];
}

- (NSString*)accessibilityValue {
  if (![self isAccessibilityBridgeAlive]) {
    return nil;
  }

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

- (NSAttributedString*)accessibilityAttributedValue {
  NSString* value = [self accessibilityValue];
  if (value.length == 0) {
    return nil;
  }
  return [self createAttributedStringFromString:value withAttributes:[self node].valueAttributes];
}

- (CGRect)accessibilityFrame {
  if (![self isAccessibilityBridgeAlive]) {
    return CGRectMake(0, 0, 0, 0);
  }

  if ([self node].HasFlag(flutter::SemanticsFlags::kIsHidden)) {
    return [super accessibilityFrame];
  }
  return [self globalRect];
}

- (CGRect)globalRect {
  const SkRect& rect = [self node].rect;
  CGRect localRect = CGRectMake(rect.x(), rect.y(), rect.width(), rect.height());
  return ConvertRectToGlobal(self, localRect);
}

#pragma mark - UIAccessibilityElement protocol

- (void)setAccessibilityContainer:(id)container {
  // Explicit noop.  The containers are calculated lazily in `accessibilityContainer`.
  // See also: https://github.com/flutter/flutter/issues/54366
}

- (id)accessibilityContainer {
  if (_inDealloc) {
    // In iOS9, `accessibilityContainer` will be called by `[UIAccessibilityElementSuperCategory
    // dealloc]` during `[super dealloc]`. And will crash when accessing `_children` which has
    // called `[_children release]` in `[SemanticsObject dealloc]`.
    // https://github.com/flutter/flutter/issues/87247
    return nil;
  }

  if (![self isAccessibilityBridgeAlive]) {
    return nil;
  }

  if ([self hasChildren] || [self uid] == kRootNodeId) {
    if (_container == nil) {
      _container.reset([[SemanticsObjectContainer alloc] initWithSemanticsObject:self
                                                                          bridge:[self bridge]]);
    }
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
  if (![self isAccessibilityBridgeAlive]) {
    return NO;
  }
  if (![self node].HasAction(flutter::SemanticsAction::kTap)) {
    return NO;
  }
  [self bridge]->DispatchSemanticsAction([self uid], flutter::SemanticsAction::kTap);
  return YES;
}

- (void)accessibilityIncrement {
  if (![self isAccessibilityBridgeAlive]) {
    return;
  }
  if ([self node].HasAction(flutter::SemanticsAction::kIncrease)) {
    [self node].value = [self node].increasedValue;
    [self bridge]->DispatchSemanticsAction([self uid], flutter::SemanticsAction::kIncrease);
  }
}

- (void)accessibilityDecrement {
  if (![self isAccessibilityBridgeAlive]) {
    return;
  }
  if ([self node].HasAction(flutter::SemanticsAction::kDecrease)) {
    [self node].value = [self node].decreasedValue;
    [self bridge]->DispatchSemanticsAction([self uid], flutter::SemanticsAction::kDecrease);
  }
}

- (BOOL)accessibilityScroll:(UIAccessibilityScrollDirection)direction {
  if (![self isAccessibilityBridgeAlive]) {
    return NO;
  }
  flutter::SemanticsAction action = GetSemanticsActionForScrollDirection(direction);
  if (![self node].HasAction(action)) {
    return NO;
  }
  [self bridge]->DispatchSemanticsAction([self uid], action);
  return YES;
}

- (BOOL)accessibilityPerformEscape {
  if (![self isAccessibilityBridgeAlive]) {
    return NO;
  }
  if (![self node].HasAction(flutter::SemanticsAction::kDismiss)) {
    return NO;
  }
  [self bridge]->DispatchSemanticsAction([self uid], flutter::SemanticsAction::kDismiss);
  return YES;
}

#pragma mark UIAccessibilityFocus overrides

- (void)accessibilityElementDidBecomeFocused {
  if (![self isAccessibilityBridgeAlive]) {
    return;
  }
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
  if (![self isAccessibilityBridgeAlive]) {
    return;
  }
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
  if (traits == UIAccessibilityTraitNone && ![self hasChildren] &&
      [[self accessibilityLabel] length] != 0 &&
      ![self node].HasFlag(flutter::SemanticsFlags::kIsTextField)) {
    traits = UIAccessibilityTraitStaticText;
  }
  return traits;
}

@end

@interface FlutterPlatformViewSemanticsContainer ()
@property(nonatomic, retain) UIView* platformView;
@end

@implementation FlutterPlatformViewSemanticsContainer

- (instancetype)initWithBridge:(fml::WeakPtr<flutter::AccessibilityBridgeIos>)bridge
                           uid:(int32_t)uid
                  platformView:(nonnull UIView*)platformView {
  if (self = [super initWithBridge:bridge uid:uid]) {
    _platformView = [platformView retain];
  }
  return self;
}

- (void)dealloc {
  [_platformView release];
  _platformView = nil;
  [super dealloc];
}

#pragma mark - UIAccessibilityContainer overrides

- (NSArray*)accessibilityElements {
  return @[ _platformView ];
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
  if (index < 0 || index >= [self accessibilityElementCount]) {
    return nil;
  }
  if (index == 0) {
    return _semanticsObject.nativeAccessibility;
  }

  SemanticsObject* child = [_semanticsObject children][index - 1];

  if ([child hasChildren]) {
    return [child accessibilityContainer];
  }
  return child.nativeAccessibility;
}

- (NSInteger)indexOfAccessibilityElement:(id)element {
  if (element == _semanticsObject.nativeAccessibility) {
    return 0;
  }

  NSArray<SemanticsObject*>* children = [_semanticsObject children];
  for (size_t i = 0; i < [children count]; i++) {
    SemanticsObject* child = children[i];
    if ((![child hasChildren] && child.nativeAccessibility == element) ||
        ([child hasChildren] && [child.nativeAccessibility accessibilityContainer] == element)) {
      return i + 1;
    }
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
