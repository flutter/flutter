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
 * Flutter api implementation for WKScriptMessageHandler.
 *
 * Handles making callbacks to Dart for a WKScriptMessageHandler.
 */
@interface FWFScriptMessageHandlerFlutterApiImpl : FWFWKScriptMessageHandlerFlutterApi
- (instancetype)initWithBinaryMessenger:(id<FlutterBinaryMessenger>)binaryMessenger
                        instanceManager:(FWFInstanceManager *)instanceManager;
@end

/**
 * Implementation of WKScriptMessageHandler for FWFScriptMessageHandlerHostApiImpl.
 */
@interface FWFScriptMessageHandler : FWFObject <WKScriptMessageHandler>
@property(readonly, nonnull, nonatomic)
    FWFScriptMessageHandlerFlutterApiImpl *scriptMessageHandlerAPI;

- (instancetype)initWithBinaryMessenger:(id<FlutterBinaryMessenger>)binaryMessenger
                        instanceManager:(FWFInstanceManager *)instanceManager;
@end

/**
 * Host api implementation for WKScriptMessageHandler.
 *
 * Handles creating WKScriptMessageHandler that intercommunicate with a paired Dart object.
 */
@interface FWFScriptMessageHandlerHostApiImpl : NSObject <FWFWKScriptMessageHandlerHostApi>
- (instancetype)initWithBinaryMessenger:(id<FlutterBinaryMessenger>)binaryMessenger
                        instanceManager:(FWFInstanceManager *)instanceManager;
@end

NS_ASSUME_NONNULL_END
