// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Flutter/Flutter.h>
#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

#import "FWFGeneratedWebKitApis.h"
#import "FWFInstanceManager.h"
#import "FWFObjectHostApi.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Flutter api implementation for WKNavigationDelegate.
 *
 * Handles making callbacks to Dart for a WKNavigationDelegate.
 */
@interface FWFNavigationDelegateFlutterApiImpl : FWFWKNavigationDelegateFlutterApi
- (instancetype)initWithBinaryMessenger:(id<FlutterBinaryMessenger>)binaryMessenger
                        instanceManager:(FWFInstanceManager *)instanceManager;
@end

/**
 * Implementation of WKNavigationDelegate for FWFNavigationDelegateHostApiImpl.
 */
@interface FWFNavigationDelegate : FWFObject <WKNavigationDelegate>
@property(readonly, nonnull, nonatomic) FWFNavigationDelegateFlutterApiImpl *navigationDelegateAPI;

- (instancetype)initWithBinaryMessenger:(id<FlutterBinaryMessenger>)binaryMessenger
                        instanceManager:(FWFInstanceManager *)instanceManager;
@end

/**
 * Host api implementation for WKNavigationDelegate.
 *
 * Handles creating WKNavigationDelegate that intercommunicate with a paired Dart object.
 */
@interface FWFNavigationDelegateHostApiImpl : NSObject <FWFWKNavigationDelegateHostApi>
- (instancetype)initWithBinaryMessenger:(id<FlutterBinaryMessenger>)binaryMessenger
                        instanceManager:(FWFInstanceManager *)instanceManager;
@end

NS_ASSUME_NONNULL_END
