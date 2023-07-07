// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Flutter/Flutter.h>
#import <WebKit/WebKit.h>

#import "FWFGeneratedWebKitApis.h"
#import "FWFInstanceManager.h"
#import "FWFObjectHostApi.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Flutter api implementation for WKWebViewConfiguration.
 *
 * Handles making callbacks to Dart for a WKWebViewConfiguration.
 */
@interface FWFWebViewConfigurationFlutterApiImpl : FWFWKWebViewConfigurationFlutterApi
- (instancetype)initWithBinaryMessenger:(id<FlutterBinaryMessenger>)binaryMessenger
                        instanceManager:(FWFInstanceManager *)instanceManager;

- (void)createWithConfiguration:(WKWebViewConfiguration *)configuration
                     completion:(void (^)(FlutterError *_Nullable))completion;
@end

/**
 * Implementation of WKWebViewConfiguration for FWFWebViewConfigurationHostApiImpl.
 */
@interface FWFWebViewConfiguration : WKWebViewConfiguration
@property(readonly, nonnull, nonatomic) FWFObjectFlutterApiImpl *objectApi;

- (instancetype)initWithBinaryMessenger:(id<FlutterBinaryMessenger>)binaryMessenger
                        instanceManager:(FWFInstanceManager *)instanceManager;
@end

/**
 * Host api implementation for WKWebViewConfiguration.
 *
 * Handles creating WKWebViewConfiguration that intercommunicate with a paired Dart object.
 */
@interface FWFWebViewConfigurationHostApiImpl : NSObject <FWFWKWebViewConfigurationHostApi>
- (instancetype)initWithBinaryMessenger:(id<FlutterBinaryMessenger>)binaryMessenger
                        instanceManager:(FWFInstanceManager *)instanceManager;
@end

NS_ASSUME_NONNULL_END
