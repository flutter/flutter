// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FWFUIViewHostApi.h"

@interface FWFUIViewHostApiImpl ()
// InstanceManager must be weak to prevent a circular reference with the object it stores.
@property(nonatomic, weak) FWFInstanceManager *instanceManager;
@end

@implementation FWFUIViewHostApiImpl
- (instancetype)initWithInstanceManager:(FWFInstanceManager *)instanceManager {
  self = [self init];
  if (self) {
    _instanceManager = instanceManager;
  }
  return self;
}

- (UIView *)viewForIdentifier:(NSNumber *)identifier {
  return (UIView *)[self.instanceManager instanceForIdentifier:identifier.longValue];
}

- (void)setBackgroundColorForViewWithIdentifier:(nonnull NSNumber *)identifier
                                        toValue:(nullable NSNumber *)color
                                          error:(FlutterError *_Nullable *_Nonnull)error {
  if (!color) {
    [[self viewForIdentifier:identifier] setBackgroundColor:nil];
  }
  int colorInt = color.intValue;
  UIColor *colorObject = [UIColor colorWithRed:(colorInt >> 16 & 0xff) / 255.0
                                         green:(colorInt >> 8 & 0xff) / 255.0
                                          blue:(colorInt & 0xff) / 255.0
                                         alpha:(colorInt >> 24 & 0xff) / 255.0];
  [[self viewForIdentifier:identifier] setBackgroundColor:colorObject];
}

- (void)setOpaqueForViewWithIdentifier:(nonnull NSNumber *)identifier
                              isOpaque:(nonnull NSNumber *)opaque
                                 error:(FlutterError *_Nullable *_Nonnull)error {
  [[self viewForIdentifier:identifier] setOpaque:opaque.boolValue];
}
@end
