// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Flutter/Flutter.h>

#import "FWFGeneratedWebKitApis.h"
#import "FWFInstanceManager.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Flutter api implementation for NSObject.
 *
 * Handles making callbacks to Dart for an NSObject.
 */
@interface FWFObjectFlutterApiImpl : FWFNSObjectFlutterApi
- (instancetype)initWithBinaryMessenger:(id<FlutterBinaryMessenger>)binaryMessenger
                        instanceManager:(FWFInstanceManager *)instanceManager;

- (void)observeValueForObject:(NSObject *)instance
                      keyPath:(NSString *)keyPath
                       object:(NSObject *)object
                       change:(NSDictionary<NSKeyValueChangeKey, id> *)change
                   completion:(void (^)(FlutterError *_Nullable))completion;
@end

/**
 * Implementation of NSObject for FWFObjectHostApiImpl.
 */
@interface FWFObject : NSObject
@property(readonly, nonnull, nonatomic) FWFObjectFlutterApiImpl *objectApi;

- (instancetype)initWithBinaryMessenger:(id<FlutterBinaryMessenger>)binaryMessenger
                        instanceManager:(FWFInstanceManager *)instanceManager;
@end

/**
 * Host api implementation for NSObject.
 *
 * Handles creating NSObject that intercommunicate with a paired Dart object.
 */
@interface FWFObjectHostApiImpl : NSObject <FWFNSObjectHostApi>
- (instancetype)initWithInstanceManager:(FWFInstanceManager *)instanceManager;
@end

NS_ASSUME_NONNULL_END
