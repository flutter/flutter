// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FLTFirebasePlugin.h"

// Firebase default app name.
NSString *_Nonnull const kFIRDefaultAppNameIOS = @"__FIRAPP_DEFAULT";
NSString *_Nonnull const kFIRDefaultAppNameDart = @"[DEFAULT]";

@interface FLTFirebaseMethodCallResult ()
@property(readwrite, nonatomic) FLTFirebaseMethodCallErrorBlock error;
@property(readwrite, nonatomic) FLTFirebaseMethodCallSuccessBlock success;
@end
@implementation FLTFirebaseMethodCallResult

+ (instancetype)createWithSuccess:(FLTFirebaseMethodCallSuccessBlock)successBlock
                    andErrorBlock:(FLTFirebaseMethodCallErrorBlock)errorBlock {
  FLTFirebaseMethodCallResult *methodCallResult = [[FLTFirebaseMethodCallResult alloc] init];
  methodCallResult.error = errorBlock;
  methodCallResult.success = successBlock;
  return methodCallResult;
}

@end

@implementation FLTFirebasePlugin
+ (FlutterError *_Nonnull)createFlutterErrorFromCode:(NSString *_Nonnull)code
                                             message:(NSString *_Nonnull)message
                                     optionalDetails:(NSDictionary *_Nullable)details
                                  andOptionalNSError:(NSError *_Nullable)error {
  NSMutableDictionary *detailsDict = [NSMutableDictionary dictionaryWithDictionary:details ?: @{}];
  if (error != nil) {
    detailsDict[@"nativeErrorCode"] = [@(error.code) stringValue];
    detailsDict[@"nativeErrorMessage"] = error.localizedDescription;
  }
  return [FlutterError errorWithCode:code message:message details:detailsDict];
}

+ (NSString *)firebaseAppNameFromDartName:(NSString *_Nonnull)appName {
  NSString *appNameIOS = appName;
  if ([kFIRDefaultAppNameDart isEqualToString:appName]) {
    appNameIOS = kFIRDefaultAppNameIOS;
  }
  return appNameIOS;
}

+ (NSString *_Nonnull)firebaseAppNameFromIosName:(NSString *_Nonnull)appName {
  NSString *appNameDart = appName;
  if ([kFIRDefaultAppNameIOS isEqualToString:appName]) {
    appNameDart = kFIRDefaultAppNameDart;
  }
  return appNameDart;
}

+ (FIRApp *_Nullable)firebaseAppNamed:(NSString *_Nonnull)appName {
  return [FIRApp allApps][[self firebaseAppNameFromDartName:appName]];
}
@end
