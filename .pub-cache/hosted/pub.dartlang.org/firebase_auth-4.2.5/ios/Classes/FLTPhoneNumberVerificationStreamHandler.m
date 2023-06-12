// Copyright 2021 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "Private/FLTPhoneNumberVerificationStreamHandler.h"
#import "Public/FLTFirebaseAuthPlugin.h"

@implementation FLTPhoneNumberVerificationStreamHandler {
  FIRAuth *_auth;
  NSString *_phoneNumber;
#if TARGET_OS_OSX
#else
  FIRMultiFactorSession *_session;
  FIRPhoneMultiFactorInfo *_factorInfo;
#endif
}

#if TARGET_OS_OSX
- (instancetype)initWithAuth:(id)auth arguments:(NSDictionary *)arguments {
  self = [super init];
  if (self) {
    _auth = auth;
    _phoneNumber = arguments[@"phoneNumber"];
  }
  return self;
}

#else
- (instancetype)initWithAuth:(id)auth
                   arguments:(NSDictionary *)arguments
                     session:(FIRMultiFactorSession *)session
                  factorInfo:(FIRPhoneMultiFactorInfo *)factorInfo {
  self = [super init];
  if (self) {
    _auth = auth;
    _phoneNumber = arguments[@"phoneNumber"];
    _session = session;
    _factorInfo = factorInfo;
  }
  return self;
}
#endif

- (FlutterError *)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)events {
#if TARGET_OS_IPHONE
  id completer = ^(NSString *verificationID, NSError *error) {
    if (error != nil) {
      NSDictionary *errorDetails = [FLTFirebaseAuthPlugin getNSDictionaryFromNSError:error];
      events(@{
        @"name" : @"Auth#phoneVerificationFailed",
        @"error" : @{
          @"message" : errorDetails[@"message"],
          @"details" : errorDetails,
        }
      });
    } else {
      events(@{
        @"name" : @"Auth#phoneCodeSent",
        @"verificationId" : verificationID,
      });
    }
  };

  // Try catch to capture 'missing URL scheme' error.
  @try {
    if (_factorInfo != nil) {
      [[FIRPhoneAuthProvider providerWithAuth:_auth]
          verifyPhoneNumberWithMultiFactorInfo:_factorInfo
                                    UIDelegate:nil
                            multiFactorSession:_session
                                    completion:completer];

    } else {
      [[FIRPhoneAuthProvider providerWithAuth:_auth] verifyPhoneNumber:_phoneNumber
                                                            UIDelegate:nil
                                                    multiFactorSession:_session
                                                            completion:completer];
    }
  } @catch (NSException *exception) {
    events(@{
      @"name" : @"Auth#phoneVerificationFailed",
      @"error" : @{
        @"message" : exception.reason,
      }
    });
  }
#endif

  return nil;
}

- (FlutterError *)onCancelWithArguments:(id)arguments {
  return nil;
}

@end
