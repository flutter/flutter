// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Firebase/Firebase.h>
#import <TargetConditionals.h>
#import <firebase_core/FLTFirebasePluginRegistry.h>

#import "Private/FLTAuthStateChannelStreamHandler.h"
#import "Private/FLTIdTokenChannelStreamHandler.h"
#import "Private/FLTPhoneNumberVerificationStreamHandler.h"

#import "Public/CustomPigeonHeader.h"
#import "Public/FLTFirebaseAuthPlugin.h"
@import CommonCrypto;
#import <AuthenticationServices/AuthenticationServices.h>

NSString *const kFLTFirebaseAuthChannelName = @"plugins.flutter.io/firebase_auth";

// Argument Keys
NSString *const kAppName = @"appName";

// Provider type keys.
NSString *const kSignInMethodPassword = @"password";
NSString *const kSignInMethodEmailLink = @"emailLink";
NSString *const kSignInMethodFacebook = @"facebook.com";
NSString *const kSignInMethodGoogle = @"google.com";
NSString *const kSignInMethodTwitter = @"twitter.com";
NSString *const kSignInMethodGithub = @"github.com";
NSString *const kSignInMethodApple = @"apple.com";
NSString *const kSignInMethodPhone = @"phone";
NSString *const kSignInMethodOAuth = @"oauth";

// Credential argument keys.
NSString *const kArgumentCredential = @"credential";
NSString *const kArgumentProviderId = @"providerId";
NSString *const kArgumentProviderScope = @"scopes";
NSString *const kArgumentProviderCustomParameters = @"customParameters";
NSString *const kArgumentSignInMethod = @"signInMethod";
NSString *const kArgumentSecret = @"secret";
NSString *const kArgumentIdToken = @"idToken";
NSString *const kArgumentAccessToken = @"accessToken";
NSString *const kArgumentRawNonce = @"rawNonce";
NSString *const kArgumentEmail = @"email";
NSString *const kArgumentCode = @"code";
NSString *const kArgumentNewEmail = @"newEmail";
NSString *const kArgumentEmailLink = kSignInMethodEmailLink;
NSString *const kArgumentToken = @"token";
NSString *const kArgumentVerificationId = @"verificationId";
NSString *const kArgumentSmsCode = @"smsCode";
NSString *const kArgumentActionCodeSettings = @"actionCodeSettings";

// MultiFactor
NSString *const kArgumentMultiFactorHints = @"multiFactorHints";
NSString *const kArgumentMultiFactorSessionId = @"multiFactorSessionId";
NSString *const kArgumentMultiFactorResolverId = @"multiFactorResolverId";
NSString *const kArgumentMultiFactorInfo = @"multiFactorInfo";

// Manual error codes & messages.
NSString *const kErrCodeNoCurrentUser = @"no-current-user";
NSString *const kErrMsgNoCurrentUser = @"No user currently signed in.";
NSString *const kErrCodeInvalidCredential = @"invalid-credential";
NSString *const kErrMsgInvalidCredential =
    @"The supplied auth credential is malformed, has expired or is not "
    @"currently supported.";

@interface FLTFirebaseAuthPlugin ()
@property(nonatomic, retain) NSObject<FlutterBinaryMessenger> *messenger;
@property(strong, nonatomic) FIROAuthProvider *authProvider;
// Used to keep the user who wants to link with Apple Sign In
@property(strong, nonatomic) FIRUser *linkWithAppleUser;
@property(strong, nonatomic) FIRAuth *signInWithAppleAuth;
@property BOOL isReauthenticatingWithApple;
@property(strong, nonatomic) NSString *currentNonce;
@property(strong, nonatomic) FLTFirebaseMethodCallResult *appleResult;
@property(strong, nonatomic) id appleArguments;

@end

@implementation FLTFirebaseAuthPlugin {
  // Used for caching credentials between Method Channel method calls.
  NSMutableDictionary<NSNumber *, FIRAuthCredential *> *_credentials;

#if TARGET_OS_IPHONE
  // Map an id to a MultiFactorSession object.
  NSMutableDictionary<NSString *, FIRMultiFactorSession *> *_multiFactorSessionMap;

  // Map an id to a MultiFactorResolver object.
  NSMutableDictionary<NSString *, FIRMultiFactorResolver *> *_multiFactorResolverMap;
#endif

  NSObject<FlutterBinaryMessenger> *_binaryMessenger;
  NSMutableDictionary<NSString *, FlutterEventChannel *> *_eventChannels;
  NSMutableDictionary<NSString *, NSObject<FlutterStreamHandler> *> *_streamHandlers;
  NSData *_apnsToken;
}

#pragma mark - FlutterPlugin

- (instancetype)init:(NSObject<FlutterBinaryMessenger> *)messenger {
  self = [super init];
  if (self) {
    [[FLTFirebasePluginRegistry sharedInstance] registerFirebasePlugin:self];
    _credentials = [NSMutableDictionary<NSNumber *, FIRAuthCredential *> dictionary];
    _binaryMessenger = messenger;
    _eventChannels = [NSMutableDictionary dictionary];
    _streamHandlers = [NSMutableDictionary dictionary];

#if TARGET_OS_IPHONE
    _multiFactorSessionMap = [NSMutableDictionary dictionary];
    _multiFactorResolverMap = [NSMutableDictionary dictionary];
#endif
  }
  return self;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:kFLTFirebaseAuthChannelName
                                  binaryMessenger:[registrar messenger]];
  FLTFirebaseAuthPlugin *instance = [[FLTFirebaseAuthPlugin alloc] init:registrar.messenger];

  [registrar addMethodCallDelegate:instance channel:channel];

#if TARGET_OS_OSX
  // TODO(Salakar): Publish does not exist on MacOS version of
  // FlutterPluginRegistrar.
  // TODO(Salakar): addApplicationDelegate does not exist on MacOS version of
  // FlutterPluginRegistrar. (https://github.com/flutter/flutter/issues/41471)
#else
  [registrar publish:instance];
  [registrar addApplicationDelegate:instance];
  MultiFactorUserHostApiSetup(registrar.messenger, instance);
  MultiFactoResolverHostApiSetup(registrar.messenger, instance);
#endif
}

- (void)cleanupWithCompletion:(void (^)(void))completion {
  // Cleanup credentials.
  [_credentials removeAllObjects];

  for (FlutterEventChannel *channel in self->_eventChannels.allValues) {
    [channel setStreamHandler:nil];
  }
  [self->_eventChannels removeAllObjects];
  for (NSObject<FlutterStreamHandler> *handler in self->_streamHandlers.allValues) {
    [handler onCancelWithArguments:nil];
  }
  [self->_streamHandlers removeAllObjects];

  if (completion != nil) completion();
}

- (void)detachFromEngineForRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  [self cleanupWithCompletion:nil];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)flutterResult {
  FLTFirebaseMethodCallErrorBlock errorBlock =
      ^(NSString *_Nullable code, NSString *_Nullable message, NSDictionary *_Nullable details,
        NSError *_Nullable error) {
        NSMutableDictionary *generatedDetails = [NSMutableDictionary new];
        if (code == nil) {
          NSDictionary *errorDetails = [FLTFirebaseAuthPlugin getNSDictionaryFromNSError:error];
          [self storeAuthCredentialIfPresent:error];
          code = errorDetails[kArgumentCode];
          message = errorDetails[@"message"];
          generatedDetails = [NSMutableDictionary dictionaryWithDictionary:errorDetails];
        } else {
          generatedDetails = [NSMutableDictionary dictionaryWithDictionary:@{
            kArgumentCode : code,
            @"message" : message,
            @"additionalData" : @{},
          }];
        }

        if (details != nil) {
          generatedDetails[@"additionalData"] = details;
        }

        if ([@"unknown" isEqualToString:code]) {
          NSLog(@"FLTFirebaseAuth: An error occurred while calling method %@, "
                @"errorOrNil => %@",
                call.method, [error userInfo]);
        }

        flutterResult([FLTFirebasePlugin createFlutterErrorFromCode:code
                                                            message:message
                                                    optionalDetails:generatedDetails
                                                 andOptionalNSError:error]);
      };

  FLTFirebaseMethodCallSuccessBlock successBlock = ^(id _Nullable result) {
    if ([result isKindOfClass:[FIRAuthDataResult class]]) {
      flutterResult([self getNSDictionaryFromAuthResult:result]);
    } else if ([result isKindOfClass:[FIRUser class]]) {
      flutterResult([FLTFirebaseAuthPlugin getNSDictionaryFromUser:result]);
    } else {
      flutterResult(result);
    }
  };

  FLTFirebaseMethodCallResult *methodCallResult =
      [FLTFirebaseMethodCallResult createWithSuccess:successBlock andErrorBlock:errorBlock];

  [self ensureAPNSTokenSetting];

  if ([@"Auth#registerIdTokenListener" isEqualToString:call.method]) {
    [self registerIdTokenListener:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Auth#registerAuthStateListener" isEqualToString:call.method]) {
    [self registerAuthStateListener:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Auth#applyActionCode" isEqualToString:call.method]) {
    [self applyActionCode:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Auth#checkActionCode" isEqualToString:call.method]) {
    [self checkActionCode:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Auth#confirmPasswordReset" isEqualToString:call.method]) {
    [self confirmPasswordReset:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Auth#createUserWithEmailAndPassword" isEqualToString:call.method]) {
    [self createUserWithEmailAndPassword:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Auth#fetchSignInMethodsForEmail" isEqualToString:call.method]) {
    [self fetchSignInMethodsForEmail:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Auth#sendPasswordResetEmail" isEqualToString:call.method]) {
    [self sendPasswordResetEmail:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Auth#sendSignInLinkToEmail" isEqualToString:call.method]) {
    [self sendSignInLinkToEmail:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Auth#signInWithCredential" isEqualToString:call.method]) {
    [self signInWithCredential:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Auth#setLanguageCode" isEqualToString:call.method]) {
    [self setLanguageCode:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Auth#setSettings" isEqualToString:call.method]) {
    [self setSettings:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Auth#signInAnonymously" isEqualToString:call.method]) {
    [self signInAnonymously:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Auth#signInWithCustomToken" isEqualToString:call.method]) {
    [self signInWithCustomToken:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Auth#signInWithEmailAndPassword" isEqualToString:call.method]) {
    [self signInWithEmailAndPassword:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Auth#signInWithEmailLink" isEqualToString:call.method]) {
    [self signInWithEmailLink:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Auth#signOut" isEqualToString:call.method]) {
    [self signOut:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Auth#useEmulator" isEqualToString:call.method]) {
    [self useEmulator:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Auth#verifyPasswordResetCode" isEqualToString:call.method]) {
    [self verifyPasswordResetCode:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Auth#signInWithProvider" isEqualToString:call.method]) {
    [self signInWithProvider:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Auth#verifyPhoneNumber" isEqualToString:call.method]) {
    [self verifyPhoneNumber:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"User#delete" isEqualToString:call.method]) {
    [self userDelete:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"User#getIdToken" isEqualToString:call.method]) {
    [self userGetIdToken:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"User#linkWithCredential" isEqualToString:call.method]) {
    [self userLinkWithCredential:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"User#linkWithProvider" isEqualToString:call.method]) {
    [self userLinkWithProvider:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"User#reauthenticateWithProvider" isEqualToString:call.method]) {
    [self reauthenticateWithProvider:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"User#reauthenticateUserWithCredential" isEqualToString:call.method]) {
    [self userReauthenticateUserWithCredential:call.arguments
                          withMethodCallResult:methodCallResult];
  } else if ([@"User#reload" isEqualToString:call.method]) {
    [self userReload:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"User#sendEmailVerification" isEqualToString:call.method]) {
    [self userSendEmailVerification:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"User#unlink" isEqualToString:call.method]) {
    [self userUnlink:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"User#updateEmail" isEqualToString:call.method]) {
    [self userUpdateEmail:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"User#updatePassword" isEqualToString:call.method]) {
    [self userUpdatePassword:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"User#updatePhoneNumber" isEqualToString:call.method]) {
    [self userUpdatePhoneNumber:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"User#updateProfile" isEqualToString:call.method]) {
    [self userUpdateProfile:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"User#verifyBeforeUpdateEmail" isEqualToString:call.method]) {
    [self userVerifyBeforeUpdateEmail:call.arguments withMethodCallResult:methodCallResult];
  } else {
    methodCallResult.success(FlutterMethodNotImplemented);
  }
}

#pragma mark - AppDelegate

#if TARGET_OS_IPHONE
#if !__has_include(<FirebaseMessaging/FirebaseMessaging.h>)
- (BOOL)application:(UIApplication *)application
    didReceiveRemoteNotification:(NSDictionary *)notification
          fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
  if ([[FIRAuth auth] canHandleNotification:notification]) {
    completionHandler(UIBackgroundFetchResultNoData);
    return YES;
  }
  return NO;
}
#endif

- (void)application:(UIApplication *)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  _apnsToken = deviceToken;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary *)options {
  return [[FIRAuth auth] canHandleURL:url];
}
#endif

#pragma mark - FLTFirebasePlugin

- (void)didReinitializeFirebaseCore:(void (^_Nonnull)(void))completion {
  [self cleanupWithCompletion:completion];
}

- (NSString *_Nonnull)firebaseLibraryName {
  return LIBRARY_NAME;
}

- (NSString *_Nonnull)firebaseLibraryVersion {
  return LIBRARY_VERSION;
}

- (NSString *_Nonnull)flutterChannelName {
  return kFLTFirebaseAuthChannelName;
}

- (NSDictionary *_Nonnull)pluginConstantsForFIRApp:(FIRApp *_Nonnull)firebaseApp {
  FIRAuth *auth = [FIRAuth authWithApp:firebaseApp];
  return @{
    @"APP_LANGUAGE_CODE" : (id)[auth languageCode] ?: [NSNull null],
    @"APP_CURRENT_USER" : [auth currentUser]
        ? (id)[FLTFirebaseAuthPlugin getNSDictionaryFromUser:[auth currentUser]]
        : [NSNull null],
  };
}

#pragma mark - Firebase Auth API

- (void)applyActionCode:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  [auth applyActionCode:arguments[kArgumentCode]
             completion:^(NSError *_Nullable error) {
               if (error != nil) {
                 result.error(nil, nil, nil, error);
               } else {
                 result.success(nil);
               }
             }];
}

- (void)checkActionCode:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  [auth checkActionCode:arguments[kArgumentCode]
             completion:^(FIRActionCodeInfo *_Nullable info, NSError *_Nullable error) {
               if (error != nil) {
                 result.error(nil, nil, nil, error);
               } else {
                 NSMutableDictionary *actionCodeResultDict = [NSMutableDictionary dictionary];
                 NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];

                 if (info.email != nil) {
                   dataDict[@"email"] = info.email;
                 }

                 if (info.previousEmail != nil) {
                   dataDict[@"previousEmail"] = info.previousEmail;
                 }

                 if (info.operation == FIRActionCodeOperationPasswordReset) {
                   actionCodeResultDict[@"operation"] = @1;
                 } else if (info.operation == FIRActionCodeOperationVerifyEmail) {
                   actionCodeResultDict[@"operation"] = @2;
                 } else if (info.operation == FIRActionCodeOperationRecoverEmail) {
                   actionCodeResultDict[@"operation"] = @3;
                 } else if (info.operation == FIRActionCodeOperationEmailLink) {
                   actionCodeResultDict[@"operation"] = @4;
                 } else if (info.operation == FIRActionCodeOperationVerifyAndChangeEmail) {
                   actionCodeResultDict[@"operation"] = @5;
                 } else if (info.operation == FIRActionCodeOperationRevertSecondFactorAddition) {
                   actionCodeResultDict[@"operation"] = @6;
                 } else {
                   // Unknown / Error.
                   actionCodeResultDict[@"operation"] = @0;
                 }

                 actionCodeResultDict[@"data"] = dataDict;

                 result.success(actionCodeResultDict);
               }
             }];
}

- (void)confirmPasswordReset:(id)arguments
        withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  [auth confirmPasswordResetWithCode:arguments[kArgumentCode]
                         newPassword:arguments[@"newPassword"]
                          completion:^(NSError *_Nullable error) {
                            if (error != nil) {
                              result.error(nil, nil, nil, error);
                            } else {
                              result.success(nil);
                            }
                          }];
}

- (void)createUserWithEmailAndPassword:(id)arguments
                  withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  [auth createUserWithEmail:arguments[kArgumentEmail]
                   password:arguments[@"password"]
                 completion:^(FIRAuthDataResult *authResult, NSError *error) {
                   if (error != nil) {
                     result.error(nil, nil, nil, error);
                   } else {
                     result.success(authResult);
                   }
                 }];
}

- (void)fetchSignInMethodsForEmail:(id)arguments
              withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  [auth fetchSignInMethodsForEmail:arguments[kArgumentEmail]
                        completion:^(NSArray<NSString *> *_Nullable providers,
                                     NSError *_Nullable error) {
                          if (error != nil) {
                            result.error(nil, nil, nil, error);
                          } else {
                            result.success(@{
                              @"providers" : (id)providers ?: @[],
                            });
                          }
                        }];
}

- (void)sendPasswordResetEmail:(id)arguments
          withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  NSString *email = arguments[kArgumentEmail];
  FIRActionCodeSettings *actionCodeSettings =
      [self getFIRActionCodeSettingsFromArguments:arguments];
  [auth sendPasswordResetWithEmail:email
                actionCodeSettings:actionCodeSettings
                        completion:^(NSError *_Nullable error) {
                          if (error != nil) {
                            result.error(nil, nil, nil, error);
                          } else {
                            result.success(nil);
                          }
                        }];
}

- (void)sendSignInLinkToEmail:(id)arguments
         withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  NSString *email = arguments[kArgumentEmail];
  FIRActionCodeSettings *actionCodeSettings =
      [self getFIRActionCodeSettingsFromArguments:arguments];
  [auth sendSignInLinkToEmail:email
           actionCodeSettings:actionCodeSettings
                   completion:^(NSError *_Nullable error) {
                     if (error != nil) {
                       result.error(nil, nil, nil, error);
                     } else {
                       result.success(nil);
                     }
                   }];
}

- (void)signInWithCredential:(id)arguments
        withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  FIRAuthCredential *credential = [self getFIRAuthCredentialFromArguments:arguments];

  if (credential == nil) {
    result.error(kErrCodeInvalidCredential, kErrMsgInvalidCredential, nil, nil);
    return;
  }

  [auth signInWithCredential:credential
                  completion:^(FIRAuthDataResult *authResult, NSError *error) {
                    if (error != nil) {
                      NSDictionary *userInfo = [error userInfo];
                      NSError *underlyingError = [userInfo objectForKey:NSUnderlyingErrorKey];

                      NSDictionary *firebaseDictionary =
                          underlyingError.userInfo[@"FIRAuthErrorUserInfoDeserializedResponseKey"];

                      if (firebaseDictionary != nil && firebaseDictionary[@"message"] != nil) {
                        // error from firebase-ios-sdk is buried in underlying
                        // error.
                        result.error(nil, firebaseDictionary[@"message"], nil, nil);
                      } else {
                        if (error.code == FIRAuthErrorCodeSecondFactorRequired) {
                          [self handleMultiFactorError:arguments withResult:result withError:error];
                        } else {
                          result.error(nil, nil, nil, error);
                        }
                      }
                    } else {
                      result.success(authResult);
                    }
                  }];
}

// Adapted from
// https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce Used
// for Apple Sign In
- (NSString *)randomNonce:(NSInteger)length {
  NSAssert(length > 0, @"Expected nonce to have positive length");
  NSString *characterSet = @"0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._";
  NSMutableString *result = [NSMutableString string];
  NSInteger remainingLength = length;

  while (remainingLength > 0) {
    NSMutableArray *randoms = [NSMutableArray arrayWithCapacity:16];
    for (NSInteger i = 0; i < 16; i++) {
      uint8_t random = 0;
      int errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random);
      NSAssert(errorCode == errSecSuccess, @"Unable to generate nonce: OSStatus %i", errorCode);

      [randoms addObject:@(random)];
    }

    for (NSNumber *random in randoms) {
      if (remainingLength == 0) {
        break;
      }

      if (random.unsignedIntValue < characterSet.length) {
        unichar character = [characterSet characterAtIndex:random.unsignedIntValue];
        [result appendFormat:@"%C", character];
        remainingLength--;
      }
    }
  }

  return [result copy];
}

- (NSString *)stringBySha256HashingString:(NSString *)input {
  const char *string = [input UTF8String];
  unsigned char result[CC_SHA256_DIGEST_LENGTH];
  CC_SHA256(string, (CC_LONG)strlen(string), result);

  NSMutableString *hashed = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
  for (NSInteger i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
    [hashed appendFormat:@"%02x", result[i]];
  }
  return hashed;
}

static void handleSignInWithApple(FLTFirebaseAuthPlugin *object, FIRAuthDataResult *authResult,
                                  NSError *error) {
  if (error != nil) {
    if (error.code == FIRAuthErrorCodeSecondFactorRequired) {
      [object handleMultiFactorError:object.appleArguments
                          withResult:object.appleResult
                           withError:error];
    } else {
      object.appleResult.error(nil, nil, nil, error);
    }
    return;
  }
  object.appleResult.success(authResult);
}

- (void)authorizationController:(ASAuthorizationController *)controller
    didCompleteWithAuthorization:(ASAuthorization *)authorization
    API_AVAILABLE(macos(10.15), ios(13.0)) {
  if ([authorization.credential isKindOfClass:[ASAuthorizationAppleIDCredential class]]) {
    ASAuthorizationAppleIDCredential *appleIDCredential = authorization.credential;
    NSString *rawNonce = self.currentNonce;
    NSAssert(rawNonce != nil,
             @"Invalid state: A login callback was received, but no login request was sent.");

    if (appleIDCredential.identityToken == nil) {
      NSLog(@"Unable to fetch identity token.");
      return;
    }

    NSString *idToken = [[NSString alloc] initWithData:appleIDCredential.identityToken
                                              encoding:NSUTF8StringEncoding];
    if (idToken == nil) {
      NSLog(@"Unable to serialize id token from data: %@", appleIDCredential.identityToken);
    }

    // Initialize a Firebase credential.
    FIROAuthCredential *credential = [FIROAuthProvider credentialWithProviderID:@"apple.com"
                                                                        IDToken:idToken
                                                                       rawNonce:rawNonce];
    if (self.isReauthenticatingWithApple == YES) {
      self.isReauthenticatingWithApple = NO;
      [[FIRAuth.auth currentUser]
          reauthenticateWithCredential:credential
                            completion:^(FIRAuthDataResult *_Nullable authResult,
                                         NSError *_Nullable error) {
                              handleSignInWithApple(self, authResult, error);
                            }];

    } else if (self.linkWithAppleUser != nil) {
      [self.linkWithAppleUser linkWithCredential:credential
                                      completion:^(FIRAuthDataResult *authResult, NSError *error) {
                                        self.linkWithAppleUser = nil;
                                        handleSignInWithApple(self, authResult, error);
                                      }];

    } else {
      FIRAuth *signInAuth =
          self.signInWithAppleAuth != nil ? self.signInWithAppleAuth : FIRAuth.auth;
      [signInAuth signInWithCredential:credential
                            completion:^(FIRAuthDataResult *_Nullable authResult,
                                         NSError *_Nullable error) {
                              self.signInWithAppleAuth = nil;
                              handleSignInWithApple(self, authResult, error);
                            }];
    }
  }
}

- (void)authorizationController:(ASAuthorizationController *)controller
           didCompleteWithError:(NSError *)error API_AVAILABLE(macos(10.15), ios(13.0)) {
  NSLog(@"Sign in with Apple errored: %@", error);
  switch (error.code) {
    case ASAuthorizationErrorCanceled:
      self.appleResult.error(@"canceled", @"The user canceled the authorization attempt.", nil,
                             error);
      break;

    case ASAuthorizationErrorInvalidResponse:
      self.appleResult.error(@"invalid-response",
                             @"The authorization request received an invalid response.", nil,
                             error);
      break;

    case ASAuthorizationErrorNotHandled:
      self.appleResult.error(@"not-handled", @"The authorization request wasn’t handled.", nil,
                             error);
      break;

    case ASAuthorizationErrorFailed:
      self.appleResult.error(@"failed", @"The authorization attempt failed.", nil, error);
      break;

    case ASAuthorizationErrorUnknown:
    default:
      self.appleResult.error(nil, nil, nil, error);
      break;
  }
  self.appleResult = nil;
}

- (void)signInWithProvider:(id)arguments
      withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];

  if ([arguments[@"signInProvider"] isEqualToString:kSignInMethodApple]) {
    self.signInWithAppleAuth = auth;
    launchAppleSignInRequest(self, arguments, result);
    return;
  }
#if TARGET_OS_OSX
  NSLog(@"signInWithProvider is not supported on the "
        @"MacOS platform.");
  result.success(nil);
#else
  self.authProvider = [FIROAuthProvider providerWithProviderID:arguments[@"signInProvider"]];
  NSArray *scopes = arguments[kArgumentProviderScope];
  if (scopes != nil) {
    [self.authProvider setScopes:scopes];
  }
  NSDictionary *customParameters = arguments[kArgumentProviderCustomParameters];
  if (customParameters != nil) {
    [self.authProvider setCustomParameters:customParameters];
  }

  [self.authProvider
      getCredentialWithUIDelegate:nil
                       completion:^(FIRAuthCredential *_Nullable credential,
                                    NSError *_Nullable error) {
                         handleAppleAuthResult(self, arguments, auth, credential, error, result);
                       }];
#endif
}

- (void)setLanguageCode:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  NSString *languageCode = arguments[@"languageCode"];

  if (languageCode != nil && ![languageCode isEqual:[NSNull null]]) {
    auth.languageCode = languageCode;
  } else {
    [auth useAppLanguage];
  }

  result.success(@{@"languageCode" : auth.languageCode});
}

- (void)setSettings:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];

  if ([[arguments allKeys] containsObject:@"userAccessGroup"] &&
      ![arguments[@"userAccessGroup"] isEqual:[NSNull null]]) {
    BOOL useUserAccessGroupSuccessful;
    NSError *useUserAccessGroupErrorPtr;
    useUserAccessGroupSuccessful = [auth useUserAccessGroup:arguments[@"userAccessGroup"]
                                                      error:&useUserAccessGroupErrorPtr];
    if (!useUserAccessGroupSuccessful) {
      return result.error(nil, nil, nil, useUserAccessGroupErrorPtr);
    }
  }

#if TARGET_OS_IPHONE
  if ([[arguments allKeys] containsObject:@"appVerificationDisabledForTesting"] &&
      ![arguments[@"appVerificationDisabledForTesting"] isEqual:[NSNull null]]) {
    auth.settings.appVerificationDisabledForTesting =
        [arguments[@"appVerificationDisabledForTesting"] boolValue];
  }
#else
  NSLog(@"FIRAuthSettings.appVerificationDisabledForTesting is not supported "
        @"on MacOS.");
#endif

  result.success(nil);
}

- (void)signInWithCustomToken:(id)arguments
         withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];

  [auth signInWithCustomToken:arguments[kArgumentToken]
                   completion:^(FIRAuthDataResult *_Nullable authResult, NSError *_Nullable error) {
                     if (error != nil) {
                       if (error.code == FIRAuthErrorCodeSecondFactorRequired) {
                         [self handleMultiFactorError:arguments withResult:result withError:error];
                       } else {
                         result.error(nil, nil, nil, error);
                       }
                     } else {
                       result.success(authResult);
                     }
                   }];
}

- (void)handleMultiFactorError:(id)arguments
                    withResult:(FLTFirebaseMethodCallResult *)result
                     withError:(NSError *_Nullable)error {
#if TARGET_OS_OSX
  result.error(nil, nil, nil, error);
#else

  FIRMultiFactorResolver *resolver =
      (FIRMultiFactorResolver *)error.userInfo[FIRAuthErrorUserInfoMultiFactorResolverKey];

  NSArray<FIRMultiFactorInfo *> *hints = resolver.hints;
  FIRMultiFactorSession *session = resolver.session;

  NSString *sessionId = [[NSUUID UUID] UUIDString];
  self->_multiFactorSessionMap[sessionId] = session;

  NSString *resolverId = [[NSUUID UUID] UUIDString];
  self->_multiFactorResolverMap[resolverId] = resolver;

  NSMutableArray<NSDictionary *> *pigeonHints = [NSMutableArray array];

  for (FIRMultiFactorInfo *multiFactorInfo in hints) {
    NSString *phoneNumber;
    if ([multiFactorInfo class] == [FIRPhoneMultiFactorInfo class]) {
      FIRPhoneMultiFactorInfo *phoneFactorInfo = (FIRPhoneMultiFactorInfo *)multiFactorInfo;
      phoneNumber = phoneFactorInfo.phoneNumber;
    }

    PigeonMultiFactorInfo *object = [PigeonMultiFactorInfo
        makeWithDisplayName:multiFactorInfo.displayName
        enrollmentTimestamp:[NSNumber numberWithDouble:multiFactorInfo.enrollmentDate
                                                           .timeIntervalSince1970]
                   factorId:multiFactorInfo.factorID
                        uid:multiFactorInfo.UID
                phoneNumber:phoneNumber];

    [pigeonHints addObject:object.toMap];
  }

  NSDictionary *output = @{
    kAppName : arguments[kAppName],
    kArgumentMultiFactorHints : pigeonHints,
    kArgumentMultiFactorSessionId : sessionId,
    kArgumentMultiFactorResolverId : resolverId,
  };
  result.error(nil, nil, output, error);
#endif
}

- (void)signInWithEmailAndPassword:(id)arguments
              withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  [auth signInWithEmail:arguments[kArgumentEmail]
               password:arguments[@"password"]
             completion:^(FIRAuthDataResult *_Nullable authResult, NSError *_Nullable error) {
               if (error != nil) {
                 if (error.code == FIRAuthErrorCodeSecondFactorRequired) {
                   [self handleMultiFactorError:arguments withResult:result withError:error];
                 } else {
                   result.error(nil, nil, nil, error);
                 }
               } else {
                 result.success(authResult);
               }
             }];
}

- (void)signInWithEmailLink:(id)arguments
       withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  [auth signInWithEmail:arguments[kArgumentEmail]
                   link:arguments[@"emailLink"]
             completion:^(FIRAuthDataResult *_Nullable authResult, NSError *_Nullable error) {
               if (error != nil) {
                 if (error.code == FIRAuthErrorCodeSecondFactorRequired) {
                   [self handleMultiFactorError:arguments withResult:result withError:error];
                 } else {
                   result.error(nil, nil, nil, error);
                 }
               } else {
                 result.success(authResult);
               }
             }];
}

- (void)signOut:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];

  if (auth.currentUser == nil) {
    result.success(nil);
    return;
  }

  NSError *signOutErrorPtr;
  BOOL signOutSuccessful = [auth signOut:&signOutErrorPtr];

  if (!signOutSuccessful) {
    result.error(nil, nil, nil, signOutErrorPtr);
  } else {
    result.success(nil);
  }
}

- (void)useEmulator:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  [auth useEmulatorWithHost:arguments[@"host"] port:[arguments[@"port"] integerValue]];
  result.success(nil);
}

- (void)verifyPasswordResetCode:(id)arguments
           withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];

  [auth verifyPasswordResetCode:arguments[kArgumentCode]
                     completion:^(NSString *_Nullable email, NSError *_Nullable error) {
                       if (error != nil) {
                         result.error(nil, nil, nil, error);
                       } else {
                         result.success(@{kArgumentEmail : (id)email ?: [NSNull null]});
                       }
                     }];
}

- (void)userDelete:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  FIRUser *currentUser = auth.currentUser;
  if (currentUser == nil) {
    result.error(kErrCodeNoCurrentUser, kErrMsgNoCurrentUser, nil, nil);
    return;
  }

  [currentUser deleteWithCompletion:^(NSError *_Nullable error) {
    if (error != nil) {
      result.error(nil, nil, nil, error);
    } else {
      result.success(nil);
    }
  }];
}

- (void)userGetIdToken:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  FIRUser *currentUser = auth.currentUser;
  if (currentUser == nil) {
    result.error(kErrCodeNoCurrentUser, kErrMsgNoCurrentUser, nil, nil);
    return;
  }

  BOOL forceRefresh = [arguments[@"forceRefresh"] boolValue];
  BOOL tokenOnly = [arguments[@"tokenOnly"] boolValue];

  [currentUser
      getIDTokenResultForcingRefresh:forceRefresh
                          completion:^(FIRAuthTokenResult *tokenResult, NSError *error) {
                            if (error != nil) {
                              result.error(nil, nil, nil, error);
                              return;
                            }

                            if (tokenOnly) {
                              result.success(
                                  @{kArgumentToken : (id)tokenResult.token ?: [NSNull null]});
                            } else {
                              long expirationTimestamp =
                                  (long)[tokenResult.expirationDate timeIntervalSince1970] * 1000;
                              long authTimestamp =
                                  (long)[tokenResult.authDate timeIntervalSince1970] * 1000;
                              long issuedAtTimestamp =
                                  (long)[tokenResult.issuedAtDate timeIntervalSince1970] * 1000;

                              NSMutableDictionary *tokenData =
                                  [[NSMutableDictionary alloc] initWithDictionary:@{
                                    @"authTimestamp" : @(authTimestamp),
                                    @"claims" : tokenResult.claims,
                                    @"expirationTimestamp" : @(expirationTimestamp),
                                    @"issuedAtTimestamp" : @(issuedAtTimestamp),
                                    @"signInProvider" : (id)tokenResult.signInProvider
                                        ?: [NSNull null],
                                    @"signInSecondFactor" : (id)tokenResult.signInSecondFactor
                                        ?: [NSNull null],
                                    kArgumentToken : tokenResult.token,
                                  }];

                              result.success(tokenData);
                            }
                          }];
}

static void launchAppleSignInRequest(FLTFirebaseAuthPlugin *object, id arguments,
                                     FLTFirebaseMethodCallResult *result) {
  if (@available(iOS 13.0, macOS 10.15, *)) {
    NSString *nonce = [object randomNonce:32];
    object.currentNonce = nonce;
    object.appleResult = result;
    object.appleArguments = arguments;

    ASAuthorizationAppleIDProvider *appleIDProvider = [[ASAuthorizationAppleIDProvider alloc] init];

    ASAuthorizationAppleIDRequest *request = [appleIDProvider createRequest];
    NSMutableArray *requestedScopes = [NSMutableArray arrayWithCapacity:2];
    if ([arguments[kArgumentProviderScope] containsObject:@"name"]) {
      [requestedScopes addObject:ASAuthorizationScopeFullName];
    }
    if ([arguments[kArgumentProviderScope] containsObject:@"email"]) {
      [requestedScopes addObject:ASAuthorizationScopeEmail];
    }
    request.requestedScopes = [requestedScopes copy];
    request.nonce = [object stringBySha256HashingString:nonce];

    ASAuthorizationController *authorizationController =
        [[ASAuthorizationController alloc] initWithAuthorizationRequests:@[ request ]];
    authorizationController.delegate = object;
    authorizationController.presentationContextProvider = object;
    [authorizationController performRequests];
  } else {
    NSLog(@"Sign in with Apple was introduced in iOS 13, update your Podfile with platform :ios, "
          @"'13.0'");
  }
}

static void handleAppleAuthResult(FLTFirebaseAuthPlugin *object, id arguments, FIRAuth *auth,
                                  FIRAuthCredential *credentials, NSError *error,
                                  FLTFirebaseMethodCallResult *result) {
  if (error) {
    if (error.code == FIRAuthErrorCodeSecondFactorRequired) {
      [object handleMultiFactorError:arguments withResult:result withError:error];
    } else {
      result.error(nil, nil, nil, error);
    }
    return;
  }
  if (credentials) {
    [auth signInWithCredential:credentials
                    completion:^(FIRAuthDataResult *authResult, NSError *error) {
                      if (error != nil) {
                        NSDictionary *userInfo = [error userInfo];
                        NSError *underlyingError = [userInfo objectForKey:NSUnderlyingErrorKey];

                        NSDictionary *firebaseDictionary =
                            underlyingError.userInfo[@"FIRAuthErrorUserInfoDes"
                                                     @"erializedResponseKey"];

                        if (firebaseDictionary != nil && firebaseDictionary[@"message"] != nil) {
                          // error from firebase-ios-sdk is
                          // buried in underlying error.
                          result.error(nil, firebaseDictionary[@"message"], nil, nil);
                        } else {
                          result.error(nil, nil, nil, error);
                        }
                      } else {
                        result.success(authResult);
                      }
                    }];
  }
}

- (void)userLinkWithProvider:(id)arguments
        withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];

  FIRUser *currentUser = auth.currentUser;
  if (currentUser == nil) {
    result.error(kErrCodeNoCurrentUser, kErrMsgNoCurrentUser, nil, nil);
    return;
  }

  if ([arguments[@"signInProvider"] isEqualToString:kSignInMethodApple]) {
    self.linkWithAppleUser = currentUser;
    launchAppleSignInRequest(self, arguments, result);
    return;
  }
#if TARGET_OS_OSX
  NSLog(@"linkWithProvider is not supported on the "
        @"MacOS platform.");
  result.success(nil);
#else
  self.authProvider = [FIROAuthProvider providerWithProviderID:arguments[@"signInProvider"]];
  NSArray *scopes = arguments[kArgumentProviderScope];
  if (scopes != nil) {
    [self.authProvider setScopes:scopes];
  }
  NSDictionary *customParameters = arguments[kArgumentProviderCustomParameters];
  if (customParameters != nil) {
    [self.authProvider setCustomParameters:customParameters];
  }

  [currentUser
      linkWithProvider:self.authProvider
            UIDelegate:nil
            completion:^(FIRAuthDataResult *authResult, NSError *error) {
              handleAppleAuthResult(self, arguments, auth, authResult.credential, error, result);
            }];
#endif
}

- (void)reauthenticateWithProvider:(id)arguments
              withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];

  FIRUser *currentUser = auth.currentUser;
  if (currentUser == nil) {
    result.error(kErrCodeNoCurrentUser, kErrMsgNoCurrentUser, nil, nil);
    return;
  }

  if ([arguments[@"signInProvider"] isEqualToString:kSignInMethodApple]) {
    self.isReauthenticatingWithApple = YES;
    launchAppleSignInRequest(self, arguments, result);
    return;
  }
#if TARGET_OS_OSX
  NSLog(@"reauthenticateWithProvider is not supported on the "
        @"MacOS platform.");
  result.success(nil);
#else
  self.authProvider = [FIROAuthProvider providerWithProviderID:arguments[@"signInProvider"]];
  NSArray *scopes = arguments[kArgumentProviderScope];
  if (scopes != nil) {
    [self.authProvider setScopes:scopes];
  }
  NSDictionary *customParameters = arguments[kArgumentProviderCustomParameters];
  if (customParameters != nil) {
    [self.authProvider setCustomParameters:customParameters];
  }

  [currentUser reauthenticateWithProvider:self.authProvider
                               UIDelegate:nil
                               completion:^(FIRAuthDataResult *authResult, NSError *error) {
                                 handleAppleAuthResult(self, arguments, auth, authResult.credential,
                                                       error, result);
                               }];
#endif
}

- (void)userLinkWithCredential:(id)arguments
          withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];

  FIRUser *currentUser = auth.currentUser;
  if (currentUser == nil) {
    result.error(kErrCodeNoCurrentUser, kErrMsgNoCurrentUser, nil, nil);
    return;
  }

  FIRAuthCredential *credential = [self getFIRAuthCredentialFromArguments:arguments];
  if (credential == nil) {
    result.error(kErrCodeInvalidCredential, kErrMsgInvalidCredential, nil, nil);
    return;
  }

  [currentUser linkWithCredential:credential
                       completion:^(FIRAuthDataResult *authResult, NSError *error) {
                         if (error != nil) {
                           if (error.code == FIRAuthErrorCodeSecondFactorRequired) {
                             [self handleMultiFactorError:arguments
                                               withResult:result
                                                withError:error];
                           } else {
                             result.error(nil, nil, nil, error);
                           }
                         } else {
                           result.success(authResult);
                         }
                       }];
}

- (void)userReauthenticateUserWithCredential:(id)arguments
                        withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];

  FIRUser *currentUser = auth.currentUser;
  if (currentUser == nil) {
    result.error(kErrCodeNoCurrentUser, kErrMsgNoCurrentUser, nil, nil);
    return;
  }

  FIRAuthCredential *credential = [self getFIRAuthCredentialFromArguments:arguments];
  if (credential == nil) {
    result.error(kErrCodeInvalidCredential, kErrMsgInvalidCredential, nil, nil);
    return;
  }

  [currentUser reauthenticateWithCredential:credential
                                 completion:^(FIRAuthDataResult *authResult, NSError *error) {
                                   if (error != nil) {
                                     if (error.code == FIRAuthErrorCodeSecondFactorRequired) {
                                       [self handleMultiFactorError:arguments
                                                         withResult:result
                                                          withError:error];
                                     } else {
                                       result.error(nil, nil, nil, error);
                                     }
                                   } else {
                                     result.success(authResult);
                                   }
                                 }];
}

- (void)userReload:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  FIRUser *currentUser = auth.currentUser;
  if (currentUser == nil) {
    result.error(kErrCodeNoCurrentUser, kErrMsgNoCurrentUser, nil, nil);
    return;
  }

  [currentUser reloadWithCompletion:^(NSError *_Nullable error) {
    if (error != nil) {
      result.error(nil, nil, nil, error);
    } else {
      result.success(auth.currentUser);
    }
  }];
}

- (void)userSendEmailVerification:(id)arguments
             withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  FIRUser *currentUser = auth.currentUser;
  if (currentUser == nil) {
    result.error(kErrCodeNoCurrentUser, kErrMsgNoCurrentUser, nil, nil);
    return;
  }

  FIRActionCodeSettings *actionCodeSettings =
      [self getFIRActionCodeSettingsFromArguments:arguments];
  [currentUser sendEmailVerificationWithActionCodeSettings:actionCodeSettings
                                                completion:^(NSError *_Nullable error) {
                                                  if (error != nil) {
                                                    result.error(nil, nil, nil, error);
                                                  } else {
                                                    result.success(nil);
                                                  }
                                                }];
}

- (void)userUnlink:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  FIRUser *currentUser = auth.currentUser;
  if (currentUser == nil) {
    result.error(kErrCodeNoCurrentUser, kErrMsgNoCurrentUser, nil, nil);
    return;
  }

  [currentUser
      unlinkFromProvider:arguments[kArgumentProviderId]
              completion:^(FIRUser *_Nullable user, NSError *_Nullable error) {
                if (error != nil) {
                  result.error(nil, nil, nil, error);
                } else {
                  [auth.currentUser reloadWithCompletion:^(NSError *_Nullable reloadError) {
                    if (reloadError != nil) {
                      result.error(nil, nil, nil, reloadError);
                    } else {
                      // Note: On other SDKs `unlinkFromProvider` returns an
                      // AuthResult instance, whereas the iOS SDK currently
                      // does not, so we manualy construct a Dart
                      // representation of one here.
                      result.success(@{
                        @"additionalUserInfo" : [NSNull null],
                        @"authCredential" : [NSNull null],
                        @"user" : auth.currentUser
                            ? [FLTFirebaseAuthPlugin getNSDictionaryFromUser:auth.currentUser]
                            : [NSNull null],
                      });
                    }
                  }];
                }
              }];
}

- (void)userUpdateEmail:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  FIRUser *currentUser = auth.currentUser;
  if (currentUser == nil) {
    result.error(kErrCodeNoCurrentUser, kErrMsgNoCurrentUser, nil, nil);
    return;
  }

  [currentUser updateEmail:arguments[kArgumentNewEmail]
                completion:^(NSError *_Nullable error) {
                  if (error != nil) {
                    result.error(nil, nil, nil, error);
                  } else {
                    [currentUser reloadWithCompletion:^(NSError *_Nullable reloadError) {
                      if (reloadError != nil) {
                        result.error(nil, nil, nil, reloadError);
                      } else {
                        result.success(auth.currentUser);
                      }
                    }];
                  }
                }];
}

- (void)userUpdatePassword:(id)arguments
      withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  FIRUser *currentUser = auth.currentUser;
  if (currentUser == nil) {
    result.error(kErrCodeNoCurrentUser, kErrMsgNoCurrentUser, nil, nil);
    return;
  }

  [currentUser updatePassword:arguments[@"newPassword"]
                   completion:^(NSError *_Nullable error) {
                     if (error != nil) {
                       result.error(nil, nil, nil, error);
                     } else {
                       [currentUser reloadWithCompletion:^(NSError *_Nullable reloadError) {
                         if (reloadError != nil) {
                           result.error(nil, nil, nil, reloadError);
                         } else {
                           result.success(auth.currentUser);
                         }
                       }];
                     }
                   }];
}

- (void)userUpdatePhoneNumber:(id)arguments
         withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
#if TARGET_OS_IPHONE
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];

  FIRUser *currentUser = auth.currentUser;
  if (currentUser == nil) {
    result.error(kErrCodeNoCurrentUser, kErrMsgNoCurrentUser, nil, nil);
    return;
  }

  FIRAuthCredential *credential = [self getFIRAuthCredentialFromArguments:arguments];
  if (credential == nil) {
    result.error(kErrCodeInvalidCredential, kErrMsgInvalidCredential, nil, nil);
    return;
  }

  [currentUser
      updatePhoneNumberCredential:(FIRPhoneAuthCredential *)credential
                       completion:^(NSError *_Nullable error) {
                         if (error != nil) {
                           result.error(nil, nil, nil, error);
                         } else {
                           [currentUser reloadWithCompletion:^(NSError *_Nullable reloadError) {
                             if (reloadError != nil) {
                               result.error(nil, nil, nil, reloadError);
                             } else {
                               result.success(auth.currentUser);
                             }
                           }];
                         }
                       }];
#else
  NSLog(@"Updating a users phone number via Firebase Authentication is only "
        @"supported on the iOS "
        @"platform.");
  result.success(nil);
#endif
}

- (void)userUpdateProfile:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  FIRUser *currentUser = auth.currentUser;
  if (currentUser == nil) {
    result.error(kErrCodeNoCurrentUser, kErrMsgNoCurrentUser, nil, nil);
    return;
  }

  NSDictionary *profileUpdates = arguments[@"profile"];
  FIRUserProfileChangeRequest *changeRequest = [currentUser profileChangeRequest];

  if (profileUpdates[@"displayName"] != nil) {
    if ([profileUpdates[@"displayName"] isEqual:[NSNull null]]) {
      changeRequest.displayName = nil;
    } else {
      changeRequest.displayName = profileUpdates[@"displayName"];
    }
  }

  if (profileUpdates[@"photoURL"] != nil) {
    if ([profileUpdates[@"photoURL"] isEqual:[NSNull null]]) {
      // We apparently cannot set photoURL to nil/NULL to remove it.
      // Instead, setting it to empty string appears to work.
      // When doing so, Dart will properly receive `null` anyway.
      changeRequest.photoURL = [NSURL URLWithString:@""];
    } else {
      changeRequest.photoURL = [NSURL URLWithString:profileUpdates[@"photoURL"]];
    }
  }

  [changeRequest commitChangesWithCompletion:^(NSError *error) {
    if (error != nil) {
      result.error(nil, nil, nil, error);
    } else {
      [currentUser reloadWithCompletion:^(NSError *_Nullable reloadError) {
        if (reloadError != nil) {
          result.error(nil, nil, nil, reloadError);
        } else {
          result.success(auth.currentUser);
        }
      }];
    }
  }];
}

- (void)userVerifyBeforeUpdateEmail:(id)arguments
               withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];

  FIRUser *currentUser = auth.currentUser;
  if (currentUser == nil) {
    result.error(kErrCodeNoCurrentUser, kErrMsgNoCurrentUser, nil, nil);
    return;
  }

  NSString *newEmail = arguments[kArgumentNewEmail];
  FIRActionCodeSettings *actionCodeSettings =
      [self getFIRActionCodeSettingsFromArguments:arguments];
  [currentUser sendEmailVerificationBeforeUpdatingEmail:newEmail
                                     actionCodeSettings:actionCodeSettings
                                             completion:^(NSError *error) {
                                               if (error != nil) {
                                                 result.error(nil, nil, nil, error);
                                               } else {
                                                 result.success(nil);
                                               }
                                             }];
}

- (void)registerIdTokenListener:(id)arguments
           withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];

  NSString *name =
      [NSString stringWithFormat:@"%@/id-token/%@", kFLTFirebaseAuthChannelName, auth.app.name];

  FlutterEventChannel *channel = [FlutterEventChannel eventChannelWithName:name
                                                           binaryMessenger:_binaryMessenger];

  FLTIdTokenChannelStreamHandler *handler =
      [[FLTIdTokenChannelStreamHandler alloc] initWithAuth:auth];
  [channel setStreamHandler:handler];

  [_eventChannels setObject:channel forKey:name];
  [_streamHandlers setObject:handler forKey:name];

  result.success(name);
}

- (void)registerAuthStateListener:(id)arguments
             withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];

  NSString *name =
      [NSString stringWithFormat:@"%@/auth-state/%@", kFLTFirebaseAuthChannelName, auth.app.name];
  FlutterEventChannel *channel = [FlutterEventChannel eventChannelWithName:name
                                                           binaryMessenger:_binaryMessenger];

  FLTAuthStateChannelStreamHandler *handler =
      [[FLTAuthStateChannelStreamHandler alloc] initWithAuth:auth];
  [channel setStreamHandler:handler];

  [_eventChannels setObject:channel forKey:name];
  [_streamHandlers setObject:handler forKey:name];

  result.success(name);
}

- (void)signInAnonymously:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];
  [auth signInAnonymouslyWithCompletion:^(FIRAuthDataResult *authResult, NSError *error) {
    if (error != nil) {
      result.error(nil, nil, nil, error);
    } else {
      result.success(authResult);
    }
  }];
}

- (void)verifyPhoneNumber:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
#if TARGET_OS_OSX
  NSLog(@"The Firebase Phone Authentication provider is not supported on the "
        @"MacOS platform.");
  result.success(nil);
#else
  FIRAuth *auth = [self getFIRAuthFromArguments:arguments];

  NSString *name = [NSString
      stringWithFormat:@"%@/phone/%@", kFLTFirebaseAuthChannelName, [NSUUID UUID].UUIDString];
  FlutterEventChannel *channel = [FlutterEventChannel eventChannelWithName:name
                                                           binaryMessenger:_binaryMessenger];

  NSString *multiFactorSessionId = arguments[kArgumentMultiFactorSessionId];
  FIRMultiFactorSession *multiFactorSession = nil;

  if (multiFactorSessionId != nil) {
    multiFactorSession = _multiFactorSessionMap[multiFactorSessionId];
  }

  NSString *multiFactorInfoId = arguments[kArgumentMultiFactorInfo];

  FIRPhoneMultiFactorInfo *multiFactorInfo = nil;
  if (multiFactorInfoId != nil) {
    for (NSString *resolverId in _multiFactorResolverMap) {
      for (FIRMultiFactorInfo *info in _multiFactorResolverMap[resolverId].hints) {
        if ([info.UID isEqualToString:multiFactorInfoId] &&
            [info class] == [FIRPhoneMultiFactorInfo class]) {
          multiFactorInfo = (FIRPhoneMultiFactorInfo *)info;
          break;
        }
      }
    }
  }

  FLTPhoneNumberVerificationStreamHandler *handler =
      [[FLTPhoneNumberVerificationStreamHandler alloc] initWithAuth:auth
                                                          arguments:arguments
                                                            session:multiFactorSession
                                                         factorInfo:multiFactorInfo];
  [channel setStreamHandler:handler];

  [_eventChannels setObject:channel forKey:name];
  [_streamHandlers setObject:handler forKey:name];

  result.success(name);
#endif
}

#pragma mark - Utilities

- (void)storeAuthCredentialIfPresent:(NSError *)error {
  if ([error userInfo][FIRAuthErrorUserInfoUpdatedCredentialKey] != nil) {
    FIRAuthCredential *authCredential = [error userInfo][FIRAuthErrorUserInfoUpdatedCredentialKey];
    // We temporarily store the non-serializable credential so the
    // Dart API can consume these at a later time.
    NSNumber *authCredentialHash = @([authCredential hash]);
    _credentials[authCredentialHash] = authCredential;
  }
}

+ (NSDictionary *)getNSDictionaryFromNSError:(NSError *)error {
  NSString *code = @"unknown";
  NSString *message = @"An unknown error has occurred.";

  if (error == nil) {
    return @{
      kArgumentCode : code,
      @"message" : message,
      @"additionalData" : @{},
    };
  }

  // code
  if ([error userInfo][FIRAuthErrorUserInfoNameKey] != nil) {
    // See [FIRAuthErrorCodeString] for list of codes.
    // Codes are in the format "ERROR_SOME_NAME", converting below to the format
    // required in Dart. ERROR_SOME_NAME -> SOME_NAME
    NSString *firebaseErrorCode = [error userInfo][FIRAuthErrorUserInfoNameKey];
    code = [firebaseErrorCode stringByReplacingOccurrencesOfString:@"ERROR_" withString:@""];
    // SOME_NAME -> SOME-NAME
    code = [code stringByReplacingOccurrencesOfString:@"_" withString:@"-"];
    // SOME-NAME -> some-name
    code = [code lowercaseString];
  }

  // message
  if ([error userInfo][NSLocalizedDescriptionKey] != nil) {
    message = [error userInfo][NSLocalizedDescriptionKey];
  }

  NSMutableDictionary *additionalData = [NSMutableDictionary dictionary];
  // additionalData.email
  if ([error userInfo][FIRAuthErrorUserInfoEmailKey] != nil) {
    additionalData[kArgumentEmail] = [error userInfo][FIRAuthErrorUserInfoEmailKey];
  }
  // additionalData.authCredential
  if ([error userInfo][FIRAuthErrorUserInfoUpdatedCredentialKey] != nil) {
    FIRAuthCredential *authCredential = [error userInfo][FIRAuthErrorUserInfoUpdatedCredentialKey];
    additionalData[@"authCredential"] =
        [FLTFirebaseAuthPlugin getNSDictionaryFromAuthCredential:authCredential];
  }

  // Manual message overrides to ensure messages/codes matche other platforms.
  if ([message isEqual:@"The password must be 6 characters long or more."]) {
    message = @"Password should be at least 6 characters";
  }

  return @{
    kArgumentCode : code,
    @"message" : message,
    @"additionalData" : additionalData,
  };
}

- (FIRAuth *_Nullable)getFIRAuthFromArguments:(NSDictionary *)arguments {
  NSString *appNameDart = arguments[kAppName];
  NSString *tenantId = arguments[@"tenantId"];
  FIRApp *app = [FLTFirebasePlugin firebaseAppNamed:appNameDart];
  FIRAuth *auth = [FIRAuth authWithApp:app];

  if (tenantId != nil && ![tenantId isEqual:[NSNull null]]) {
    auth.tenantID = tenantId;
  }

  return auth;
}

- (FIRAuth *_Nullable)getFIRAuthFromAppName:(NSString *)appNameDart {
  FIRApp *app = [FLTFirebasePlugin firebaseAppNamed:appNameDart];
  FIRAuth *auth = [FIRAuth authWithApp:app];

  return auth;
}

- (FIRActionCodeSettings *_Nullable)getFIRActionCodeSettingsFromArguments:
    (NSDictionary *)arguments {
  NSDictionary *actionCodeSettingsDictionary = arguments[kArgumentActionCodeSettings];
  if (actionCodeSettingsDictionary == nil || [actionCodeSettingsDictionary isEqual:[NSNull null]]) {
    return nil;
  }

  FIRActionCodeSettings *actionCodeSettings = [FIRActionCodeSettings new];
  NSDictionary *iOSSettings = actionCodeSettingsDictionary[@"iOS"];
  NSDictionary *androidSettings = actionCodeSettingsDictionary[@"android"];

  // URL - required
  actionCodeSettings.URL = [NSURL URLWithString:actionCodeSettingsDictionary[@"url"]];

  // Dynamic Link Domain - optional
  if (actionCodeSettingsDictionary[@"dynamicLinkDomain"] != nil &&
      ![actionCodeSettingsDictionary[@"dynamicLinkDomain"] isEqual:[NSNull null]]) {
    actionCodeSettings.dynamicLinkDomain = actionCodeSettingsDictionary[@"dynamicLinkDomain"];
  }

  // Handle code in app - optional
  if (actionCodeSettingsDictionary[@"handleCodeInApp"] != nil &&
      ![actionCodeSettingsDictionary[@"handleCodeInApp"] isEqual:[NSNull null]]) {
    actionCodeSettings.handleCodeInApp =
        [actionCodeSettingsDictionary[@"handleCodeInApp"] boolValue];
  }

  // Android settings - optional
  if (androidSettings != nil && ![androidSettings isEqual:[NSNull null]]) {
    BOOL installIfNotAvailable = NO;
    if (androidSettings[@"installApp"] != nil &&
        ![androidSettings[@"installApp"] isEqual:[NSNull null]]) {
      installIfNotAvailable = [androidSettings[@"installApp"] boolValue];
    }
    [actionCodeSettings setAndroidPackageName:androidSettings[@"packageName"]
                        installIfNotAvailable:installIfNotAvailable
                               minimumVersion:androidSettings[@"minimumVersion"]];
  }

  // iOS settings - optional
  if (iOSSettings != nil && ![iOSSettings isEqual:[NSNull null]]) {
    if (iOSSettings[@"bundleId"] != nil && ![iOSSettings[@"bundleId"] isEqual:[NSNull null]]) {
      [actionCodeSettings setIOSBundleID:iOSSettings[@"bundleId"]];
    }
  }

  return actionCodeSettings;
}

- (FIRAuthCredential *_Nullable)getFIRAuthCredentialFromArguments:(NSDictionary *)arguments {
  NSDictionary *credentialDictionary = arguments[kArgumentCredential];

  // If the credential dictionary contains a token, it means a native one has
  // been stored for later usage, so we'll attempt to retrieve it here.
  if (credentialDictionary[kArgumentToken] != nil &&
      ![credentialDictionary[kArgumentToken] isEqual:[NSNull null]]) {
    NSNumber *credentialHashCode = credentialDictionary[kArgumentToken];
    return _credentials[credentialHashCode];
  }

  NSString *signInMethod = credentialDictionary[kArgumentSignInMethod];
  NSString *secret = credentialDictionary[kArgumentSecret] == [NSNull null]
                         ? nil
                         : credentialDictionary[kArgumentSecret];
  NSString *idToken = credentialDictionary[kArgumentIdToken] == [NSNull null]
                          ? nil
                          : credentialDictionary[kArgumentIdToken];
  NSString *accessToken = credentialDictionary[kArgumentAccessToken] == [NSNull null]
                              ? nil
                              : credentialDictionary[kArgumentAccessToken];
  NSString *rawNonce = credentialDictionary[kArgumentRawNonce] == [NSNull null]
                           ? nil
                           : credentialDictionary[kArgumentRawNonce];

  // Password Auth
  if ([signInMethod isEqualToString:kSignInMethodPassword]) {
    NSString *email = credentialDictionary[kArgumentEmail];
    return [FIREmailAuthProvider credentialWithEmail:email password:secret];
  }

  // Email Link Auth
  if ([signInMethod isEqualToString:kSignInMethodEmailLink]) {
    NSString *email = credentialDictionary[kArgumentEmail];
    NSString *emailLink = credentialDictionary[kArgumentEmailLink];
    return [FIREmailAuthProvider credentialWithEmail:email link:emailLink];
  }

  // Facebook Auth
  if ([signInMethod isEqualToString:kSignInMethodFacebook]) {
    return [FIRFacebookAuthProvider credentialWithAccessToken:accessToken];
  }

  // Google Auth
  if ([signInMethod isEqualToString:kSignInMethodGoogle]) {
    return [FIRGoogleAuthProvider credentialWithIDToken:idToken accessToken:accessToken];
  }

  // Twitter Auth
  if ([signInMethod isEqualToString:kSignInMethodTwitter]) {
    return [FIRTwitterAuthProvider credentialWithToken:accessToken secret:secret];
  }

  // GitHub Auth
  if ([signInMethod isEqualToString:kSignInMethodGithub]) {
    return [FIRGitHubAuthProvider credentialWithToken:accessToken];
  }

  // Phone Auth - Only supported on iOS
  if ([signInMethod isEqualToString:kSignInMethodPhone]) {
#if TARGET_OS_IPHONE
    NSString *verificationId = credentialDictionary[kArgumentVerificationId];
    NSString *smsCode = credentialDictionary[kArgumentSmsCode];
    return [[FIRPhoneAuthProvider providerWithAuth:[self getFIRAuthFromArguments:arguments]]
        credentialWithVerificationID:verificationId
                    verificationCode:smsCode];
#else
    NSLog(@"The Firebase Phone Authentication provider is not supported on the "
          @"MacOS platform.");
    return nil;
#endif
  }

  // OAuth
  if ([signInMethod isEqualToString:kSignInMethodOAuth]) {
    NSString *providerId = credentialDictionary[kArgumentProviderId];
    return [FIROAuthProvider credentialWithProviderID:providerId
                                              IDToken:idToken
                                             rawNonce:rawNonce
                                          accessToken:accessToken];
  }

  NSLog(@"Support for an auth provider with identifier '%@' is not implemented.", signInMethod);
  return nil;
}

- (NSDictionary *)getNSDictionaryFromAuthResult:(FIRAuthDataResult *)authResult {
  return @{
    @"additionalUserInfo" :
        [self getNSDictionaryFromAdditionalUserInfo:authResult.additionalUserInfo],
    @"authCredential" :
        [FLTFirebaseAuthPlugin getNSDictionaryFromAuthCredential:authResult.credential],
    @"user" : [FLTFirebaseAuthPlugin getNSDictionaryFromUser:authResult.user],
  };
}

- (id)getNSDictionaryFromAdditionalUserInfo:(FIRAdditionalUserInfo *)additionalUserInfo {
  if (additionalUserInfo == nil) {
    return [NSNull null];
  }

  return @{
    @"isNewUser" : @(additionalUserInfo.newUser),
    @"profile" : (id)additionalUserInfo.profile ?: [NSNull null],
    kArgumentProviderId : (id)additionalUserInfo.providerID ?: [NSNull null],
    @"username" : (id)additionalUserInfo.username ?: [NSNull null],
  };
}

+ (id)getNSDictionaryFromAuthCredential:(FIRAuthCredential *)authCredential {
  if (authCredential == nil) {
    return [NSNull null];
  }

  NSString *accessToken = nil;
  if ([authCredential isKindOfClass:[FIROAuthCredential class]]) {
    if (((FIROAuthCredential *)authCredential).accessToken != nil) {
      accessToken = ((FIROAuthCredential *)authCredential).accessToken;
    } else if (((FIROAuthCredential *)authCredential).IDToken != nil) {
      // For Sign In With Apple, the token is stored in IDToken
      accessToken = ((FIROAuthCredential *)authCredential).IDToken;
    }
  }

  return @{
    kArgumentProviderId : authCredential.provider,
    // Note: "signInMethod" does not exist on iOS SDK, so using provider
    // instead.
    kArgumentSignInMethod : authCredential.provider,
    kArgumentToken : @([authCredential hash]),
    kArgumentAccessToken : accessToken ?: [NSNull null],
  };
}

+ (NSDictionary *)getNSDictionaryFromUserInfo:(id<FIRUserInfo>)userInfo {
  NSString *photoURL = nil;
  if (userInfo.photoURL != nil) {
    photoURL = userInfo.photoURL.absoluteString;
    if ([photoURL length] == 0) photoURL = nil;
  }
  return @{
    kArgumentProviderId : userInfo.providerID,
    @"displayName" : (id)userInfo.displayName ?: [NSNull null],
    @"uid" : (id)userInfo.uid ?: [NSNull null],
    @"photoURL" : (id)photoURL ?: [NSNull null],
    kArgumentEmail : (id)userInfo.email ?: [NSNull null],
    @"phoneNumber" : (id)userInfo.phoneNumber ?: [NSNull null],
  };
}

+ (NSMutableDictionary *)getNSDictionaryFromUser:(FIRUser *)user {
  // FIRUser inherits from FIRUserInfo, so we can re-use
  // `getNSDictionaryFromUserInfo` method.
  NSMutableDictionary *userData = [[self getNSDictionaryFromUserInfo:user] mutableCopy];
  NSMutableDictionary *metadata = [NSMutableDictionary dictionary];

  // metadata.creationTimestamp as milliseconds
  long creationDate = (long)([user.metadata.creationDate timeIntervalSince1970] * 1000);
  metadata[@"creationTime"] = @(creationDate);

  // metadata.lastSignInTimestamp as milliseconds
  long lastSignInDate = (long)([user.metadata.lastSignInDate timeIntervalSince1970] * 1000);
  metadata[@"lastSignInTime"] = @(lastSignInDate);

  // metadata
  userData[@"metadata"] = metadata;

  // providerData
  NSMutableArray<NSDictionary<NSString *, NSString *> *> *providerData =
      [NSMutableArray arrayWithCapacity:user.providerData.count];
  for (id<FIRUserInfo> userInfo in user.providerData) {
    [providerData addObject:[FLTFirebaseAuthPlugin getNSDictionaryFromUserInfo:userInfo]];
  }
  userData[@"providerData"] = providerData;

  userData[@"isAnonymous"] = @(user.isAnonymous);
  userData[@"emailVerified"] = @(user.isEmailVerified);

  if (user.tenantID != nil) {
    userData[@"tenantId"] = user.tenantID;
  } else {
    userData[@"tenantId"] = [NSNull null];
  }

  // native does not provide refresh tokens
  userData[@"refreshToken"] = @"";
  return userData;
}

- (void)ensureAPNSTokenSetting {
#if !TARGET_OS_OSX
  FIRApp *defaultApp = [FIRApp defaultApp];
  if (defaultApp) {
    if ([FIRAuth auth].APNSToken == nil && _apnsToken != nil) {
      [[FIRAuth auth] setAPNSToken:_apnsToken type:FIRAuthAPNSTokenTypeUnknown];
      _apnsToken = nil;
    }
  }
#endif
}

#if TARGET_OS_IPHONE
- (FIRMultiFactor *)getAppMultiFactor:(nonnull NSString *)appName {
  FIRAuth *auth = [self getFIRAuthFromAppName:appName];
  FIRUser *currentUser = auth.currentUser;
  return currentUser.multiFactor;
}

- (void)enrollPhoneAppName:(nonnull NSString *)appName
                 assertion:(nonnull PigeonPhoneMultiFactorAssertion *)assertion
               displayName:(nullable NSString *)displayName
                completion:(nonnull void (^)(FlutterError *_Nullable))completion {
  FIRMultiFactor *multiFactor = [self getAppMultiFactor:appName];

  FIRPhoneAuthCredential *credential =
      [[FIRPhoneAuthProvider providerWithAuth:[self getFIRAuthFromAppName:appName]]
          credentialWithVerificationID:[assertion verificationId]
                      verificationCode:[assertion verificationCode]];

  FIRMultiFactorAssertion *multiFactorAssertion =
      [FIRPhoneMultiFactorGenerator assertionWithCredential:credential];

  [multiFactor enrollWithAssertion:multiFactorAssertion
                       displayName:displayName
                        completion:^(NSError *_Nullable error) {
                          if (error == nil) {
                            completion(nil);
                          } else {
                            completion([FlutterError errorWithCode:@"enroll-failed"
                                                           message:error.localizedDescription
                                                           details:nil]);
                          }
                        }];
}

- (void)getEnrolledFactorsAppName:(nonnull NSString *)appName
                       completion:(nonnull void (^)(NSArray<PigeonMultiFactorInfo *> *_Nullable,
                                                    FlutterError *_Nullable))completion {
  FIRMultiFactor *multiFactor = [self getAppMultiFactor:appName];

  NSArray<FIRMultiFactorInfo *> *enrolledFactors = [multiFactor enrolledFactors];

  NSMutableArray<PigeonMultiFactorInfo *> *results = [NSMutableArray array];

  for (FIRMultiFactorInfo *multiFactorInfo in enrolledFactors) {
    NSString *phoneNumber;
    if ([multiFactorInfo class] == [FIRPhoneMultiFactorInfo class]) {
      FIRPhoneMultiFactorInfo *phoneFactorInfo = (FIRPhoneMultiFactorInfo *)multiFactorInfo;
      phoneNumber = phoneFactorInfo.phoneNumber;
    }

    [results
        addObject:[PigeonMultiFactorInfo
                      makeWithDisplayName:multiFactorInfo.displayName
                      enrollmentTimestamp:[NSNumber numberWithDouble:multiFactorInfo.enrollmentDate
                                                                         .timeIntervalSince1970]
                                 factorId:multiFactorInfo.factorID
                                      uid:multiFactorInfo.UID
                              phoneNumber:phoneNumber]];
  }

  completion(results, nil);
}

- (void)getSessionAppName:(nonnull NSString *)appName
               completion:(nonnull void (^)(PigeonMultiFactorSession *_Nullable,
                                            FlutterError *_Nullable))completion {
  FIRMultiFactor *multiFactor = [self getAppMultiFactor:appName];
  [multiFactor getSessionWithCompletion:^(FIRMultiFactorSession *_Nullable session,
                                          NSError *_Nullable error) {
    NSString *UUID = [[NSUUID UUID] UUIDString];
    self->_multiFactorSessionMap[UUID] = session;

    PigeonMultiFactorSession *pigeonSession = [PigeonMultiFactorSession makeWithId:UUID];
    completion(pigeonSession, nil);
  }];
}

- (void)unenrollAppName:(nonnull NSString *)appName
              factorUid:(nullable NSString *)factorUid
             completion:(nonnull void (^)(FlutterError *_Nullable))completion {
  FIRMultiFactor *multiFactor = [self getAppMultiFactor:appName];
  [multiFactor unenrollWithFactorUID:factorUid
                          completion:^(NSError *_Nullable error) {
                            if (error == nil) {
                              completion(nil);
                            } else {
                              completion([FlutterError errorWithCode:@"unenroll-failed"
                                                             message:error.localizedDescription
                                                             details:nil]);
                            }
                          }];
}

- (void)resolveSignInResolverId:(nonnull NSString *)resolverId
                      assertion:(nonnull PigeonPhoneMultiFactorAssertion *)assertion
                     completion:(nonnull void (^)(NSDictionary<NSString *, id> *_Nullable,
                                                  FlutterError *_Nullable))completion {
  FIRMultiFactorResolver *resolver = _multiFactorResolverMap[resolverId];

  FIRPhoneAuthCredential *credential =
      [[FIRPhoneAuthProvider provider] credentialWithVerificationID:[assertion verificationId]
                                                   verificationCode:[assertion verificationCode]];

  FIRMultiFactorAssertion *multiFactorAssertion =
      [FIRPhoneMultiFactorGenerator assertionWithCredential:credential];

  [resolver
      resolveSignInWithAssertion:multiFactorAssertion
                      completion:^(FIRAuthDataResult *_Nullable authResult,
                                   NSError *_Nullable error) {
                        if (error == nil) {
                          completion([self getNSDictionaryFromAuthResult:authResult], nil);
                        } else {
                          completion(nil, [FlutterError errorWithCode:@"resolve-signin-failed"
                                                              message:error.localizedDescription
                                                              details:nil]);
                        }
                      }];
}

#endif

- (nonnull ASPresentationAnchor)presentationAnchorForAuthorizationController:
    (nonnull ASAuthorizationController *)controller API_AVAILABLE(macos(10.15), ios(13.0)) {
#if TARGET_OS_OSX
  return [[NSApplication sharedApplication] keyWindow];
#else
  return [[UIApplication sharedApplication] keyWindow];
#endif
}

@end
