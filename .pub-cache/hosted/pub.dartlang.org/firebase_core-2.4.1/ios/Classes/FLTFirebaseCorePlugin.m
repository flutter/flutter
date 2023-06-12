// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FLTFirebaseCorePlugin.h"
#import "FLTFirebasePluginRegistry.h"
#import "messages.g.h"

@implementation FLTFirebaseCorePlugin {
  BOOL _coreInitialized;
}

#pragma mark - FlutterPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FLTFirebaseCorePlugin *sharedInstance = [self sharedInstance];
#if TARGET_OS_OSX
#else
  [registrar publish:sharedInstance];
#endif
  FirebaseCoreHostApiSetup(registrar.messenger, sharedInstance);
  FirebaseAppHostApiSetup(registrar.messenger, sharedInstance);
}

// Returns a singleton instance of the Firebase Core plugin.
+ (instancetype)sharedInstance {
  static dispatch_once_t onceToken;
  static FLTFirebaseCorePlugin *instance;

  dispatch_once(&onceToken, ^{
    instance = [[FLTFirebaseCorePlugin alloc] init];
    // Register with the Flutter Firebase plugin registry.
    [[FLTFirebasePluginRegistry sharedInstance] registerFirebasePlugin:instance];

    // Initialize default Firebase app, but only if the plist file options
    // exist.
    //  - If it is missing then there is no default app discovered in Dart and
    //  Dart throws an error.
    //  - Without this the iOS/MacOS app would crash immediately on calling
    //  [FIRApp configure] without
    //    providing helpful context about the crash to the user.
    //
    // Default app exists check is for backwards compatibility of legacy
    // FlutterFire plugins that call [FIRApp configure]; themselves internally.
    FIROptions *options = [FIROptions defaultOptions];
    if (options != nil && [FIRApp allApps][@"__FIRAPP_DEFAULT"] == nil) {
      [FIRApp configureWithOptions:options];
    }
  });

  return instance;
}

#pragma mark - Helpers

- (PigeonFirebaseOptions *)optionsFromFIROptions:(FIROptions *)options {
  PigeonFirebaseOptions *pigeonOptions = [PigeonFirebaseOptions alloc];
  pigeonOptions.apiKey = (id)options.APIKey ?: [NSNull null];
  pigeonOptions.appId = (id)options.googleAppID ?: [NSNull null];
  pigeonOptions.messagingSenderId = (id)options.GCMSenderID ?: [NSNull null];
  pigeonOptions.projectId = (id)options.projectID ?: [NSNull null];
  pigeonOptions.databaseURL = (id)options.databaseURL ?: [NSNull null];
  pigeonOptions.storageBucket = (id)options.storageBucket ?: [NSNull null];
  pigeonOptions.trackingId = (id)options.trackingID ?: [NSNull null];
  pigeonOptions.deepLinkURLScheme = (id)options.deepLinkURLScheme ?: [NSNull null];
  pigeonOptions.androidClientId = (id)options.androidClientID ?: [NSNull null];
  pigeonOptions.iosBundleId = (id)options.bundleID ?: [NSNull null];
  pigeonOptions.iosClientId = (id)options.clientID ?: [NSNull null];
  pigeonOptions.appGroupId = (id)options.appGroupID ?: [NSNull null];
  return pigeonOptions;
}

- (PigeonInitializeResponse *)initializeResponseFromFIRApp:(FIRApp *)firebaseApp {
  NSString *appNameDart = [FLTFirebasePlugin firebaseAppNameFromIosName:firebaseApp.name];
  PigeonInitializeResponse *response = [PigeonInitializeResponse alloc];
  response.name = appNameDart;
  response.options = [self optionsFromFIROptions:firebaseApp.options];
  response.isAutomaticDataCollectionEnabled = @(firebaseApp.isDataCollectionDefaultEnabled);
  response.pluginConstants =
      [[FLTFirebasePluginRegistry sharedInstance] pluginConstantsForFIRApp:firebaseApp];

  return response;
}

#pragma mark - FLTFirebasePlugin

- (void)didReinitializeFirebaseCore:(void (^)(void))completion {
  completion();
}

- (NSDictionary *_Nonnull)pluginConstantsForFIRApp:(FIRApp *)firebase_app {
  return @{};
}

- (NSString *_Nonnull)firebaseLibraryName {
  return LIBRARY_NAME;
}

- (NSString *_Nonnull)firebaseLibraryVersion {
  return LIBRARY_VERSION;
}

- (NSString *_Nonnull)flutterChannelName {
  // The pigeon channel depends on each function
  return @"dev.flutter.pigeon.FirebaseCoreHostApi.initializeApp";
}

#pragma mark - API

- (void)initializeAppAppName:(nonnull NSString *)appName
        initializeAppRequest:(nonnull PigeonFirebaseOptions *)initializeAppRequest
                  completion:(nonnull void (^)(PigeonInitializeResponse *_Nullable,
                                               FlutterError *_Nullable))completion {
  NSString *appNameIos = [FLTFirebasePlugin firebaseAppNameFromDartName:appName];

  if ([FLTFirebasePlugin firebaseAppNamed:appNameIos]) {
    completion([self initializeResponseFromFIRApp:[FLTFirebasePlugin firebaseAppNamed:appNameIos]],
               nil);
    return;
  }

  NSString *appId = initializeAppRequest.appId;
  NSString *messagingSenderId = initializeAppRequest.messagingSenderId;
  FIROptions *options = [[FIROptions alloc] initWithGoogleAppID:appId
                                                    GCMSenderID:messagingSenderId];

  options.APIKey = initializeAppRequest.apiKey;
  options.projectID = initializeAppRequest.projectId;

  // kFirebaseOptionsDatabaseUrl
  if (![initializeAppRequest.databaseURL isEqual:[NSNull null]]) {
    options.databaseURL = initializeAppRequest.databaseURL;
  }

  // kFirebaseOptionsStorageBucket
  if (![options.storageBucket isEqual:[NSNull null]]) {
    options.storageBucket = initializeAppRequest.storageBucket;
  }

  // kFirebaseOptionsTrackingId
  if (![initializeAppRequest.trackingId isEqual:[NSNull null]]) {
    options.trackingID = initializeAppRequest.trackingId;
  }

  // kFirebaseOptionsDeepLinkURLScheme
  if (![initializeAppRequest.deepLinkURLScheme isEqual:[NSNull null]]) {
    options.deepLinkURLScheme = initializeAppRequest.deepLinkURLScheme;
  }

  // kFirebaseOptionsAndroidClientId
  if (![initializeAppRequest.androidClientId isEqual:[NSNull null]]) {
    options.androidClientID = initializeAppRequest.androidClientId;
  }

  // kFirebaseOptionsIosBundleId
  if (![initializeAppRequest.iosBundleId isEqual:[NSNull null]]) {
    options.bundleID = initializeAppRequest.iosBundleId;
  }

  // kFirebaseOptionsIosClientId
  if (![initializeAppRequest.iosClientId isEqual:[NSNull null]]) {
    options.clientID = initializeAppRequest.iosClientId;
  }

  // kFirebaseOptionsAppGroupId
  if (![initializeAppRequest.appGroupId isEqual:[NSNull null]]) {
    options.appGroupID = initializeAppRequest.appGroupId;
  }

  [FIRApp configureWithName:appNameIos options:options];

  completion([self initializeResponseFromFIRApp:[FIRApp appNamed:appNameIos]], nil);
}

- (void)initializeCoreWithCompletion:
    (nonnull void (^)(NSArray<PigeonInitializeResponse *> *_Nullable,
                      FlutterError *_Nullable))completion {
  void (^initializeCoreBlock)(void) = ^void() {
    NSDictionary<NSString *, FIRApp *> *firebaseApps = [FIRApp allApps];
    NSMutableArray *firebaseAppsArray = [NSMutableArray arrayWithCapacity:firebaseApps.count];

    for (NSString *appName in firebaseApps) {
      FIRApp *firebaseApp = firebaseApps[appName];
      [firebaseAppsArray addObject:[self initializeResponseFromFIRApp:firebaseApp]];
    }

    completion(firebaseAppsArray, nil);
  };

  if (!_coreInitialized) {
    _coreInitialized = YES;
    initializeCoreBlock();
  } else {
    [[FLTFirebasePluginRegistry sharedInstance] didReinitializeFirebaseCore:initializeCoreBlock];
  }
}

- (void)optionsFromResourceWithCompletion:(nonnull void (^)(PigeonFirebaseOptions *_Nullable,
                                                            FlutterError *_Nullable))completion {
  // Unsupported on iOS/MacOS.
  completion(nil, nil);
}

- (void)deleteAppName:(nonnull NSString *)appName
           completion:(nonnull void (^)(FlutterError *_Nullable))completion {
  FIRApp *firebaseApp = [FLTFirebasePlugin firebaseAppNamed:appName];

  if (firebaseApp) {
    [firebaseApp deleteApp:^(BOOL success) {
      if (success) {
        completion(nil);
      } else {
        completion([FlutterError errorWithCode:@"delete-failed"
                                       message:@"Failed to delete a Firebase app instance."
                                       details:nil]);
      }
    }];
  } else {
    completion(nil);
  }
}

- (void)setAutomaticDataCollectionEnabledAppName:(nonnull NSString *)appName
                                         enabled:(nonnull NSNumber *)enabled
                                      completion:
                                          (nonnull void (^)(FlutterError *_Nullable))completion {
  FIRApp *firebaseApp = [FLTFirebasePlugin firebaseAppNamed:appName];
  if (firebaseApp) {
    [firebaseApp setDataCollectionDefaultEnabled:enabled];
  }

  completion(nil);
}

- (void)setAutomaticResourceManagementEnabledAppName:(nonnull NSString *)appName
                                             enabled:(nonnull NSNumber *)enabled
                                          completion:(nonnull void (^)(FlutterError *_Nullable))
                                                         completion {
  // Unsupported on iOS/MacOS.
  completion(nil);
}

@end
