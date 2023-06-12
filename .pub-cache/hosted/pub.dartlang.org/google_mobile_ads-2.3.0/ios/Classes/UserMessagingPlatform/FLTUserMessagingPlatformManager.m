// Copyright 2022 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "FLTUserMessagingPlatformManager.h"
#import "../FLTAdUtil.h"
#import "../FLTNSString.h"
#import "FLTUserMessagingPlatformReaderWriter.h"
#include <UserMessagingPlatform/UserMessagingPlatform.h>

@implementation FLTUserMessagingPlatformManager {
  FlutterMethodChannel *_methodChannel;
}

- (instancetype _Nonnull)initWithBinaryMessenger:
    (NSObject<FlutterBinaryMessenger> *_Nonnull)binaryMessenger {
  self = [self init];
  if (self) {
    self.readerWriter = [[FLTUserMessagingPlatformReaderWriter alloc] init];
    NSObject<FlutterMethodCodec> *methodCodec =
        [FlutterStandardMethodCodec codecWithReaderWriter:_readerWriter];
    _methodChannel = [[FlutterMethodChannel alloc]
           initWithName:@"plugins.flutter.io/google_mobile_ads/ump"
        binaryMessenger:binaryMessenger
                  codec:methodCodec];

    FLTUserMessagingPlatformManager *__weak weakSelf = self;
    [_methodChannel setMethodCallHandler:^(FlutterMethodCall *_Nonnull call,
                                           FlutterResult _Nonnull result) {
      [weakSelf handleMethodCall:call result:result];
    }];
  }
  return self;
}

- (UIViewController *)rootController {
  return UIApplication.sharedApplication.delegate.window.rootViewController;
}

- (void)handleMethodCall:(FlutterMethodCall *_Nonnull)call
                  result:(FlutterResult _Nonnull)result {
  if ([call.method isEqualToString:@"ConsentInformation#reset"]) {
    [UMPConsentInformation.sharedInstance reset];
    result(nil);
  } else if ([call.method
                 isEqualToString:@"ConsentInformation#getConsentStatus"]) {
    UMPConsentStatus status =
        UMPConsentInformation.sharedInstance.consentStatus;
    result([[NSNumber alloc] initWithInteger:status]);
  } else if ([call.method isEqualToString:
                              @"ConsentInformation#requestConsentInfoUpdate"]) {
    UMPRequestParameters *parameters = call.arguments[@"params"];
    [UMPConsentInformation.sharedInstance
        requestConsentInfoUpdateWithParameters:parameters
                             completionHandler:^(NSError *_Nullable error) {
                               if ([FLTAdUtil isNull:error]) {
                                 result(nil);
                               } else {
                                 result([FlutterError
                                     errorWithCode:[[NSString alloc]
                                                       initWithInt:error.code]
                                           message:error.localizedDescription
                                           details:error.domain]);
                               }
                             }];
  } else if ([call.method
                 isEqualToString:@"UserMessagingPlatform#loadConsentForm"]) {
    [UMPConsentForm
        loadWithCompletionHandler:^(UMPConsentForm *form, NSError *loadError) {
          if ([FLTAdUtil isNull:loadError]) {
            [self.readerWriter trackConsentForm:form];
            result(form);
          } else {
            result([FlutterError
                errorWithCode:[[NSString alloc] initWithInt:loadError.code]
                      message:loadError.localizedDescription
                      details:loadError.domain]);
          }
        }];
  } else if ([call.method isEqualToString:
                              @"ConsentInformation#isConsentFormAvailable"]) {
    BOOL isAvailable = UMPConsentInformation.sharedInstance.formStatus ==
                       UMPFormStatusAvailable;
    result([[NSNumber alloc] initWithBool:isAvailable]);
  } else if ([call.method isEqualToString:@"ConsentForm#show"]) {
    UMPConsentForm *consentForm = call.arguments[@"consentForm"];
    [consentForm
        presentFromViewController:self.rootController
                completionHandler:^(NSError *_Nullable error) {
                  if ([FLTAdUtil isNull:error]) {
                    result(nil);
                  } else {
                    result([FlutterError
                        errorWithCode:[[NSString alloc] initWithInt:error.code]
                              message:error.localizedDescription
                              details:error.domain]);
                  }
                }];
  } else if ([call.method isEqualToString:@"ConsentForm#dispose"]) {
    UMPConsentForm *consentForm = call.arguments[@"consentForm"];
    if ([FLTAdUtil isNotNull:consentForm]) {
      [_readerWriter disposeConsentForm:consentForm];
    } else {
      NSLog(@"FLTUserMessagingPlatformManager - consentForm resources already "
            @"freed");
    }
    result(nil);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

@end
