// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Flutter/Flutter.h>
#import <WebKit/WebKit.h>

#import "FWFGeneratedWebKitApis.h"
#import "FWFInstanceManager.h"
#import "FWFObjectHostApi.h"
#import "FWFWebViewConfigurationHostApi.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Flutter api implementation for WKUIDelegate.
 *
 * Handles making callbacks to Dart for a WKUIDelegate.
 */
@interface FWFUIDelegateFlutterApiImpl : FWFWKUIDelegateFlutterApi
@property(readonly, nonatomic)
    FWFWebViewConfigurationFlutterApiImpl *webViewConfigurationFlutterApi;

- (instancetype)initWithBinaryMessenger:(id<FlutterBinaryMessenger>)binaryMessenger
                        instanceManager:(FWFInstanceManager *)instanceManager;
@end

/**
 * Implementation of WKUIDelegate for FWFUIDelegateHostApiImpl.
 */
@interface FWFUIDelegate : FWFObject <WKUIDelegate>
@property(readonly, nonnull, nonatomic) FWFUIDelegateFlutterApiImpl *UIDelegateAPI;

- (instancetype)initWithBinaryMessenger:(id<FlutterBinaryMessenger>)binaryMessenger
                        instanceManager:(FWFInstanceManager *)instanceManager;
@end

/**
 * Host api implementation for WKUIDelegate.
 *
 * Handles creating WKUIDelegate that intercommunicate with a paired Dart object.
 */
@interface FWFUIDelegateHostApiImpl : NSObject <FWFWKUIDelegateHostApi>
- (instancetype)initWithBinaryMessenger:(id<FlutterBinaryMessenger>)binaryMessenger
                        instanceManager:(FWFInstanceManager *)instanceManager;
@end

NS_ASSUME_NONNULL_END
