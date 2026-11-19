// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformViewLayer.h"

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"

FLUTTER_ASSERT_ARC

static BOOL CornerRadiiEqual(FlutterPlatformViewCornerRadii a, FlutterPlatformViewCornerRadii b) {
  return CGSizeEqualToSize(a.topLeft, b.topLeft) && CGSizeEqualToSize(a.topRight, b.topRight) &&
         CGSizeEqualToSize(a.bottomRight, b.bottomRight) &&
         CGSizeEqualToSize(a.bottomLeft, b.bottomLeft);
}

@implementation FlutterPlatformViewMutator

- (instancetype)initWithType:(FlutterPlatformViewMutatorType)type {
  if (self = [super init]) {
    _type = type;
    _transform = CATransform3DIdentity;
  }
  return self;
}

- (void)dealloc {
  CGPathRelease(_path);
}

+ (instancetype)mutatorWithOpacity:(double)opacity {
  FlutterPlatformViewMutator* mutator =
      [[self alloc] initWithType:FlutterPlatformViewMutatorTypeOpacity];
  mutator->_opacity = opacity;
  return mutator;
}

+ (instancetype)mutatorWithClipRect:(CGRect)rect {
  FlutterPlatformViewMutator* mutator =
      [[self alloc] initWithType:FlutterPlatformViewMutatorTypeClipRect];
  mutator->_rect = rect;
  return mutator;
}

+ (instancetype)mutatorWithClipRoundedRect:(CGRect)rect
                                     radii:(FlutterPlatformViewCornerRadii)radii {
  FlutterPlatformViewMutator* mutator =
      [[self alloc] initWithType:FlutterPlatformViewMutatorTypeClipRoundedRect];
  mutator->_rect = rect;
  mutator->_cornerRadii = radii;
  return mutator;
}

+ (instancetype)mutatorWithClipRoundedSuperellipse:(CGRect)rect
                                             radii:(FlutterPlatformViewCornerRadii)radii {
  FlutterPlatformViewMutator* mutator =
      [[self alloc] initWithType:FlutterPlatformViewMutatorTypeClipRoundedSuperellipse];
  mutator->_rect = rect;
  mutator->_cornerRadii = radii;
  return mutator;
}

+ (instancetype)mutatorWithClipPath:(CGPathRef)path {
  FlutterPlatformViewMutator* mutator =
      [[self alloc] initWithType:FlutterPlatformViewMutatorTypeClipPath];
  mutator->_path = CGPathRetain(path);
  return mutator;
}

+ (instancetype)mutatorWithTransform:(CATransform3D)transform {
  FlutterPlatformViewMutator* mutator =
      [[self alloc] initWithType:FlutterPlatformViewMutatorTypeTransform];
  mutator->_transform = transform;
  return mutator;
}

+ (instancetype)mutatorWithBackdropFilterRect:(CGRect)rect
                                   blurSigmaX:(double)blurSigmaX
                                   blurSigmaY:(double)blurSigmaY {
  FlutterPlatformViewMutator* mutator =
      [[self alloc] initWithType:FlutterPlatformViewMutatorTypeBackdropFilter];
  mutator->_rect = rect;
  mutator->_blurSigmaX = blurSigmaX;
  mutator->_blurSigmaY = blurSigmaY;
  return mutator;
}

+ (instancetype)mutatorWithBackdropClipRect:(CGRect)rect {
  FlutterPlatformViewMutator* mutator =
      [[self alloc] initWithType:FlutterPlatformViewMutatorTypeBackdropClipRect];
  mutator->_rect = rect;
  return mutator;
}

+ (instancetype)mutatorWithBackdropClipRoundedRect:(CGRect)rect
                                             radii:(FlutterPlatformViewCornerRadii)radii {
  FlutterPlatformViewMutator* mutator =
      [[self alloc] initWithType:FlutterPlatformViewMutatorTypeBackdropClipRoundedRect];
  mutator->_rect = rect;
  mutator->_cornerRadii = radii;
  return mutator;
}

+ (instancetype)mutatorWithBackdropClipRoundedSuperellipse:(CGRect)rect
                                                     radii:(FlutterPlatformViewCornerRadii)radii {
  FlutterPlatformViewMutator* mutator =
      [[self alloc] initWithType:FlutterPlatformViewMutatorTypeBackdropClipRoundedSuperellipse];
  mutator->_rect = rect;
  mutator->_cornerRadii = radii;
  return mutator;
}

+ (instancetype)mutatorWithBackdropClipPath:(CGPathRef)path {
  FlutterPlatformViewMutator* mutator =
      [[self alloc] initWithType:FlutterPlatformViewMutatorTypeBackdropClipPath];
  mutator->_path = CGPathRetain(path);
  return mutator;
}

- (BOOL)isEqual:(id)object {
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:[FlutterPlatformViewMutator class]]) {
    return NO;
  }
  FlutterPlatformViewMutator* other = object;
  if (_type != other->_type || _opacity != other->_opacity ||
      !CGRectEqualToRect(_rect, other->_rect) ||
      !CornerRadiiEqual(_cornerRadii, other->_cornerRadii) ||
      !CATransform3DEqualToTransform(_transform, other->_transform) ||
      _blurSigmaX != other->_blurSigmaX || _blurSigmaY != other->_blurSigmaY) {
    return NO;
  }
  if (_path == NULL || other->_path == NULL) {
    return _path == other->_path;
  }
  return CGPathEqualToPath(_path, other->_path);
}

- (NSUInteger)hash {
  return @(_type).hash ^ @(_opacity).hash ^ @(_transform.m41).hash ^ @(_blurSigmaX).hash;
}

@end

@implementation FlutterPlatformViewLayer

- (instancetype)initWithViewId:(int64_t)viewId
                  boundingRect:(CGRect)boundingRect
                          size:(CGSize)size
                      mutators:(NSArray<FlutterPlatformViewMutator*>*)mutators {
  if (self = [super init]) {
    _viewId = viewId;
    _boundingRect = boundingRect;
    _size = size;
    _mutators = [mutators copy];
  }
  return self;
}

- (BOOL)isEqual:(id)object {
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:[FlutterPlatformViewLayer class]]) {
    return NO;
  }
  FlutterPlatformViewLayer* other = object;
  return _viewId == other->_viewId && CGRectEqualToRect(_boundingRect, other->_boundingRect) &&
         CGSizeEqualToSize(_size, other->_size) && [_mutators isEqualToArray:other->_mutators];
}

- (NSUInteger)hash {
  return @(_viewId).hash ^ @(_size.width).hash ^ @(_size.height).hash ^ _mutators.count;
}

@end
