// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERPLATFORMVIEWLAYER_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERPLATFORMVIEWLAYER_H_

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

/// The kinds of mutation that can be applied to a platform view.
typedef NS_ENUM(NSInteger, FlutterPlatformViewMutatorType) {
  FlutterPlatformViewMutatorTypeOpacity,
  FlutterPlatformViewMutatorTypeClipRect,
  FlutterPlatformViewMutatorTypeClipRoundedRect,
  FlutterPlatformViewMutatorTypeClipRoundedSuperellipse,
  FlutterPlatformViewMutatorTypeClipPath,
  FlutterPlatformViewMutatorTypeTransform,
  FlutterPlatformViewMutatorTypeBackdropFilter,
  FlutterPlatformViewMutatorTypeBackdropClipRect,
  FlutterPlatformViewMutatorTypeBackdropClipRoundedRect,
  FlutterPlatformViewMutatorTypeBackdropClipRoundedSuperellipse,
  FlutterPlatformViewMutatorTypeBackdropClipPath,
};

/// The corner radii of a rounded rect or rounded superellipse.
typedef struct {
  CGSize topLeft;
  CGSize topRight;
  CGSize bottomRight;
  CGSize bottomLeft;
} FlutterPlatformViewCornerRadii;

/// A mutation to apply to a platform view, such as a clip, a transform, or an opacity.
///
/// This class holds the same information as `flutter::Mutator`, using Core Graphics and Core
/// Animation types in place of engine types. It is modelled on `FlutterPlatformViewMutation` in the
/// embedder API.
///
/// This also adds the mutations supported on iOS but not yet in the embedder API: clip path, clip
/// rounded superellipse, backdrop filter, and the backdrop clips.
///
/// Rects, paths, and transforms are in physical pixels.
@interface FlutterPlatformViewMutator : NSObject

@property(nonatomic, readonly) FlutterPlatformViewMutatorType type;

/// The opacity to apply.
///
/// This is only set for opacity mutators.
@property(nonatomic, readonly) double opacity;

/// The bounds of the clip, or the area that a backdrop filter applies to.
///
/// This is only set for rect, rounded rect, and rounded superellipse clips, their backdrop clip
/// equivalents, and backdrop filter mutators.
@property(nonatomic, readonly) CGRect rect;

/// The corner radii of the clip.
///
/// This is only set for rounded rect and rounded superellipse clips, and their backdrop clip
/// equivalents.
@property(nonatomic, readonly) FlutterPlatformViewCornerRadii cornerRadii;

/// The path to clip to.
///
/// This is only set for clip path and backdrop clip path mutators, and is null for all others.
@property(nonatomic, readonly, nullable) CGPathRef path;

/// The transform to apply.
///
/// This is only set for transform mutators.
@property(nonatomic, readonly) CATransform3D transform;

/// The sigma of the Gaussian blur along the x axis.
///
/// This is only set for backdrop filter mutators.
@property(nonatomic, readonly) double blurSigmaX;

/// The sigma of the Gaussian blur along the y axis.
///
/// This is only set for backdrop filter mutators.
@property(nonatomic, readonly) double blurSigmaY;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)mutatorWithOpacity:(double)opacity;
+ (instancetype)mutatorWithClipRect:(CGRect)rect;
+ (instancetype)mutatorWithClipRoundedRect:(CGRect)rect radii:(FlutterPlatformViewCornerRadii)radii;
+ (instancetype)mutatorWithClipRoundedSuperellipse:(CGRect)rect
                                             radii:(FlutterPlatformViewCornerRadii)radii;
+ (instancetype)mutatorWithClipPath:(CGPathRef)path;
+ (instancetype)mutatorWithTransform:(CATransform3D)transform;
+ (instancetype)mutatorWithBackdropFilterRect:(CGRect)rect
                                   blurSigmaX:(double)blurSigmaX
                                   blurSigmaY:(double)blurSigmaY;
+ (instancetype)mutatorWithBackdropClipRect:(CGRect)rect;
+ (instancetype)mutatorWithBackdropClipRoundedRect:(CGRect)rect
                                             radii:(FlutterPlatformViewCornerRadii)radii;
+ (instancetype)mutatorWithBackdropClipRoundedSuperellipse:(CGRect)rect
                                                     radii:(FlutterPlatformViewCornerRadii)radii;
+ (instancetype)mutatorWithBackdropClipPath:(CGPathRef)path;

@end

/// The position, size, and mutators of a platform view in a frame.
///
/// This class holds the same information as `flutter::EmbeddedViewParams`, using Core Graphics
/// types in place of engine types. It is modelled on a `FlutterLayer` which in the embedder API,
/// contains a `FlutterPlatformView`.
@interface FlutterPlatformViewLayer : NSObject

/// The ID of the platform view.
@property(nonatomic, readonly) int64_t viewId;

/// The bounding rect of the platform view once its transforms have been applied, in physical
/// pixels.
@property(nonatomic, readonly) CGRect boundingRect;

/// The size of the platform view before its transforms are applied, scaled by the device pixel
/// ratio.
@property(nonatomic, readonly) CGSize size;

/// The mutators to apply to the platform view.
///
/// These are ordered outermost first. The outermost mutator is the one furthest from the platform
/// view in the layer tree.
@property(nonatomic, readonly) NSArray<FlutterPlatformViewMutator*>* mutators;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithViewId:(int64_t)viewId
                  boundingRect:(CGRect)boundingRect
                          size:(CGSize)size
                      mutators:(NSArray<FlutterPlatformViewMutator*>*)mutators
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERPLATFORMVIEWLAYER_H_
