// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Firebase/Firebase.h>
#import <firebase_core/FLTFirebasePluginRegistry.h>

#import <TargetConditionals.h>
#import "Private/FLTDocumentSnapshotStreamHandler.h"
#import "Private/FLTFirebaseFirestoreUtils.h"
#import "Private/FLTLoadBundleStreamHandler.h"
#import "Private/FLTQuerySnapshotStreamHandler.h"
#import "Private/FLTSnapshotsInSyncStreamHandler.h"
#import "Private/FLTTransactionStreamHandler.h"
#import "Public/FLTFirebaseFirestorePlugin.h"

NSString *const kFLTFirebaseFirestoreChannelName = @"plugins.flutter.io/firebase_firestore";
NSString *const kFLTFirebaseFirestoreQuerySnapshotEventChannelName =
    @"plugins.flutter.io/firebase_firestore/query";
NSString *const kFLTFirebaseFirestoreDocumentSnapshotEventChannelName =
    @"plugins.flutter.io/firebase_firestore/document";
NSString *const kFLTFirebaseFirestoreSnapshotsInSyncEventChannelName =
    @"plugins.flutter.io/firebase_firestore/snapshotsInSync";
NSString *const kFLTFirebaseFirestoreTransactionChannelName =
    @"plugins.flutter.io/firebase_firestore/transaction";
NSString *const kFLTFirebaseFirestoreLoadBundleChannelName =
    @"plugins.flutter.io/firebase_firestore/loadBundle";

@interface FLTFirebaseFirestorePlugin ()
@property(nonatomic, retain) NSMutableDictionary *transactions;

/// Registers a unique event channel based on a channel prefix.
///
/// Once registered, the plugin will take care of removing the stream handler and cleaning up,
/// if the engine is detached.
///
/// This function generates a random ID.
///
/// @param prefix Channel prefix onto which the unique ID will be appended on. The convention is
///     "namespace/component" whereas the last / is added internally.
/// @param handler The handler object for responding to channel events and submitting data.
/// @return The generated identifier.
/// @see #registerEventChannel(String, String, StreamHandler)
- (NSString *)registerEventChannelWithPrefix:(NSString *)prefix
                               streamHandler:(NSObject<FlutterStreamHandler> *)handler;

/// Registers a unique event channel based on a channel prefix.
///
/// Once registered, the plugin will take care of removing the stream handler and cleaning up,
/// if the engine is detached.
///
/// @param prefix Channel prefix onto which the unique ID will be appended on. The convention is
/// "namespace/component" whereas the last / is added internally.
/// @param identifier A identifier which will be appended to the prefix.
/// @param handler The handler object for responding to channel events and submitting data.
/// @return The passed identifier.
/// @see #registerEventChannel(String, String, StreamHandler)
- (NSString *)registerEventChannelWithPrefix:(NSString *)prefix
                                  identifier:(NSString *)identifier
                               streamHandler:(NSObject<FlutterStreamHandler> *)handler;
@end

static NSMutableDictionary<NSNumber *, NSString *> *_serverTimestampMap;

@implementation FLTFirebaseFirestorePlugin {
  NSMutableDictionary<NSString *, FlutterEventChannel *> *_eventChannels;
  NSMutableDictionary<NSString *, NSObject<FlutterStreamHandler> *> *_streamHandlers;
  NSMutableDictionary<NSString *, FLTTransactionStreamHandler *> *_transactionHandlers;
  NSObject<FlutterBinaryMessenger> *_binaryMessenger;
}

FlutterStandardMethodCodec *_codec;

+ (NSMutableDictionary<NSNumber *, NSString *> *)serverTimestampMap {
  return _serverTimestampMap;
}

+ (void)initialize {
  _codec =
      [FlutterStandardMethodCodec codecWithReaderWriter:[FLTFirebaseFirestoreReaderWriter new]];
}

#pragma mark - FlutterPlugin

// Returns a singleton instance of the Firebase Firestore plugin.
//+ (instancetype)sharedInstance {
//  static dispatch_once_t onceToken;
//  static FLTFirebaseFirestorePlugin *instance;
//
//  dispatch_once(&onceToken, ^{
//    instance = [[FLTFirebaseFirestorePlugin alloc] init];
//    // Register with the Flutter Firebase plugin registry.
//    [[FLTFirebasePluginRegistry sharedInstance] registerFirebasePlugin:instance];
//  });
//
//  return instance;
//}

- (instancetype)init:(NSObject<FlutterBinaryMessenger> *)messenger {
  self = [super init];
  if (self) {
    _binaryMessenger = messenger;
    _transactions = [NSMutableDictionary<NSNumber *, FIRTransaction *> dictionary];
    _eventChannels = [NSMutableDictionary dictionary];
    _streamHandlers = [NSMutableDictionary dictionary];
    _transactionHandlers = [NSMutableDictionary dictionary];
    _serverTimestampMap = [NSMutableDictionary dictionary];
  }
  return self;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:kFLTFirebaseFirestoreChannelName
                                  binaryMessenger:[registrar messenger]
                                            codec:_codec];

  FLTFirebaseFirestorePlugin *instance =
      [[FLTFirebaseFirestorePlugin alloc] init:[registrar messenger]];
  [registrar addMethodCallDelegate:instance channel:channel];

#if TARGET_OS_OSX
// TODO(Salakar): Publish does not exist on MacOS version of FlutterPluginRegistrar.
#else
  [registrar publish:instance];
#endif
}

- (void)cleanupWithCompletion:(void (^)(void))completion {
  for (FlutterEventChannel *channel in self->_eventChannels) {
    [channel setStreamHandler:nil];
  }
  [self->_eventChannels removeAllObjects];
  for (NSObject<FlutterStreamHandler> *handler in self->_streamHandlers) {
    [handler onCancelWithArguments:nil];
  }
  [self->_streamHandlers removeAllObjects];

  @synchronized(self->_transactions) {
    [self->_transactions removeAllObjects];
  }

  __block int instancesTerminated = 0;
  NSUInteger numberOfApps = [[FIRApp allApps] count];
  void (^firestoreTerminateInstanceCompletion)(NSError *) = ^void(NSError *error) {
    instancesTerminated++;
    if (instancesTerminated == numberOfApps && completion != nil) {
      completion();
    }
  };

  if (numberOfApps > 0) {
    for (NSString *appName in [FIRApp allApps]) {
      FIRApp *app = [FIRApp appNamed:appName];
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [[FIRFirestore firestoreForApp:app] terminateWithCompletion:^(NSError *error) {
          [FLTFirebaseFirestoreUtils destroyCachedFIRFirestoreInstanceForKey:appName];
          firestoreTerminateInstanceCompletion(error);
        }];
      });
    }
  } else {
    if (completion != nil) completion();
  }
}

- (void)detachFromEngineForRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  [self cleanupWithCompletion:nil];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)flutterResult {
  FLTFirebaseMethodCallErrorBlock errorBlock = ^(
      NSString *_Nullable code, NSString *_Nullable message, NSDictionary *_Nullable details,
      NSError *_Nullable error) {
    if (code == nil) {
      NSArray *codeAndMessage = [FLTFirebaseFirestoreUtils ErrorCodeAndMessageFromNSError:error];
      code = codeAndMessage[0];
      message = codeAndMessage[1];
      details = @{
        @"code" : code,
        @"message" : message,
      };
    }
    if ([@"unknown" isEqualToString:code]) {
      NSLog(@"FLTFirebaseFirestore: An error occurred while calling method %@", call.method);
    }
    flutterResult([FLTFirebasePlugin createFlutterErrorFromCode:code
                                                        message:message
                                                optionalDetails:details
                                             andOptionalNSError:error]);
  };

  FLTFirebaseMethodCallResult *methodCallResult =
      [FLTFirebaseMethodCallResult createWithSuccess:flutterResult andErrorBlock:errorBlock];

  if ([@"Transaction#get" isEqualToString:call.method]) {
    [self transactionGet:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Transaction#create" isEqualToString:call.method]) {
    [self transactionCreate:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Transaction#storeResult" isEqualToString:call.method]) {
    [self transactionStoreResult:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"DocumentReference#set" isEqualToString:call.method]) {
    [self documentSet:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"DocumentReference#update" isEqualToString:call.method]) {
    [self documentUpdate:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"DocumentReference#delete" isEqualToString:call.method]) {
    [self documentDelete:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"DocumentReference#get" isEqualToString:call.method]) {
    [self documentGet:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Firestore#namedQueryGet" isEqualToString:call.method]) {
    [self namedQueryGet:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Query#get" isEqualToString:call.method]) {
    [self queryGet:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"WriteBatch#commit" isEqualToString:call.method]) {
    [self batchCommit:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Firestore#terminate" isEqualToString:call.method]) {
    [self terminate:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Firestore#enableNetwork" isEqualToString:call.method]) {
    [self enableNetwork:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Firestore#disableNetwork" isEqualToString:call.method]) {
    [self disableNetwork:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Firestore#clearPersistence" isEqualToString:call.method]) {
    [self clearPersistence:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Firestore#waitForPendingWrites" isEqualToString:call.method]) {
    [self waitForPendingWrites:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"SnapshotsInSync#setup" isEqualToString:call.method]) {
    [self setupSnapshotsInSyncListener:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Query#snapshots" isEqualToString:call.method]) {
    [self setupQuerySnapshotsListener:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"DocumentReference#snapshots" isEqualToString:call.method]) {
    [self setupDocumentReferenceSnapshotsListener:call.arguments
                             withMethodCallResult:methodCallResult];
  } else if ([@"LoadBundle#snapshots" isEqualToString:call.method]) {
    [self setupLoadBundleListener:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"AggregateQuery#count" isEqualToString:call.method]) {
    [self aggregateQuery:call.arguments withMethodCallResult:methodCallResult];
  } else if ([@"Firestore#setIndexConfiguration" isEqualToString:call.method]) {
    [self setIndexConfiguration:call.arguments withMethodCallResult:methodCallResult];
  } else {
    methodCallResult.success(FlutterMethodNotImplemented);
  }
}

#pragma mark - FLTFirebasePlugin

- (void)didReinitializeFirebaseCore:(void (^)(void))completion {
  [self cleanupWithCompletion:completion];
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
  return kFLTFirebaseFirestoreChannelName;
}

#pragma mark - Firestore API

- (void)setIndexConfiguration:(id)arguments
         withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRFirestore *firestore = arguments[@"firestore"];
  NSString *indexConfiguration = arguments[@"indexConfiguration"];

  [firestore setIndexConfigurationFromJSON:indexConfiguration
                                completion:^(NSError *_Nullable error) {
                                  if (error != nil) {
                                    result.error(nil, nil, nil, error);
                                  } else {
                                    result.success(nil);
                                  }
                                }];
}

- (void)setupSnapshotsInSyncListener:(id)arguments
                withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  result.success([self
      registerEventChannelWithPrefix:kFLTFirebaseFirestoreSnapshotsInSyncEventChannelName
                       streamHandler:[FLTSnapshotsInSyncStreamHandler new]]);
}

- (void)setupLoadBundleListener:(id)arguments
           withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  result.success([self registerEventChannelWithPrefix:kFLTFirebaseFirestoreLoadBundleChannelName
                                        streamHandler:[FLTLoadBundleStreamHandler new]]);
}

- (void)setupDocumentReferenceSnapshotsListener:(id)arguments
                           withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  result.success([self
      registerEventChannelWithPrefix:kFLTFirebaseFirestoreDocumentSnapshotEventChannelName
                       streamHandler:[FLTDocumentSnapshotStreamHandler new]]);
}

- (void)setupQuerySnapshotsListener:(id)arguments
               withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  result.success([self
      registerEventChannelWithPrefix:kFLTFirebaseFirestoreQuerySnapshotEventChannelName
                       streamHandler:[FLTQuerySnapshotStreamHandler new]]);
}

- (void)waitForPendingWrites:(id)arguments
        withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRFirestore *firestore = arguments[@"firestore"];
  [firestore waitForPendingWritesWithCompletion:^(NSError *error) {
    if (error != nil) {
      result.error(nil, nil, nil, error);
    } else {
      result.success(nil);
    }
  }];
}

- (void)clearPersistence:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRFirestore *firestore = arguments[@"firestore"];
  [firestore clearPersistenceWithCompletion:^(NSError *error) {
    if (error != nil) {
      result.error(nil, nil, nil, error);
    } else {
      result.success(nil);
    }
  }];
}

- (void)terminate:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRFirestore *firestore = arguments[@"firestore"];
  [firestore terminateWithCompletion:^(NSError *error) {
    if (error != nil) {
      result.error(nil, nil, nil, error);
    } else {
      [FLTFirebaseFirestoreUtils destroyCachedFIRFirestoreInstanceForKey:firestore.app.name];
      result.success(nil);
    }
  }];
}

- (void)enableNetwork:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRFirestore *firestore = arguments[@"firestore"];
  [firestore enableNetworkWithCompletion:^(NSError *error) {
    if (error != nil) {
      result.error(nil, nil, nil, error);
    } else {
      result.success(nil);
    }
  }];
}

- (void)disableNetwork:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRFirestore *firestore = arguments[@"firestore"];
  [firestore disableNetworkWithCompletion:^(NSError *error) {
    if (error != nil) {
      result.error(nil, nil, nil, error);
    } else {
      result.success(nil);
    }
  }];
}

- (void)transactionGet:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSString *transactionId = arguments[@"transactionId"];
    FIRDocumentReference *document = arguments[@"reference"];

    FIRTransaction *transaction = self->_transactions[transactionId];

    NSError *error = [[NSError alloc] init];
    FIRDocumentSnapshot *snapshot = [transaction getDocument:document error:&error];

    if (error != nil) {
      result.error(nil, nil, nil, error);
    } else if (snapshot != nil) {
      result.success(snapshot);
    } else {
      result.success(nil);
    }
  });
}

- (void)transactionCreate:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  NSString *transactionId = [[[NSUUID UUID] UUIDString] lowercaseString];

  FLTTransactionStreamHandler *handler =
      [[FLTTransactionStreamHandler alloc] initWithId:transactionId
          started:^(FIRTransaction *_Nonnull transaction) {
            self->_transactions[transactionId] = transaction;
          }
          ended:^{
            self->_transactions[transactionId] = nil;
          }];

  _transactionHandlers[transactionId] = handler;

  result.success([self registerEventChannelWithPrefix:kFLTFirebaseFirestoreTransactionChannelName
                                           identifier:transactionId
                                        streamHandler:handler]);
}

- (void)transactionStoreResult:(id)arguments
          withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  NSString *transactionId = arguments[@"transactionId"];
  NSDictionary *transactionResult = arguments[@"result"];

  [_transactionHandlers[transactionId] receiveTransactionResponse:transactionResult];

  result.success(nil);
}

- (void)documentSet:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  id data = arguments[@"data"];
  FIRDocumentReference *document = arguments[@"reference"];

  NSDictionary *options = arguments[@"options"];
  void (^completionBlock)(NSError *) = ^(NSError *error) {
    if (error != nil) {
      result.error(nil, nil, nil, error);
    } else {
      result.success(nil);
    }
  };

  if ([options[@"merge"] isEqual:@YES]) {
    [document setData:data merge:YES completion:completionBlock];
  } else if (![options[@"mergeFields"] isEqual:[NSNull null]]) {
    [document setData:data mergeFields:options[@"mergeFields"] completion:completionBlock];
  } else {
    [document setData:data completion:completionBlock];
  }
}

- (void)documentUpdate:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  id data = arguments[@"data"];
  FIRDocumentReference *document = arguments[@"reference"];

  [document updateData:data
            completion:^(NSError *error) {
              if (error != nil) {
                result.error(nil, nil, nil, error);
              } else {
                result.success(nil);
              }
            }];
}

- (void)documentDelete:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRDocumentReference *document = arguments[@"reference"];

  [document deleteDocumentWithCompletion:^(NSError *error) {
    if (error != nil) {
      result.error(nil, nil, nil, error);
    } else {
      result.success(nil);
    }
  }];
}

- (void)documentGet:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRDocumentReference *document = arguments[@"reference"];
  FIRFirestoreSource source = [FLTFirebaseFirestoreUtils FIRFirestoreSourceFromArguments:arguments];
  NSString *serverTimestampBehaviorString = arguments[@"serverTimestampBehavior"];
  id completion = ^(FIRDocumentSnapshot *_Nullable snapshot, NSError *_Nullable error) {
    if (error != nil) {
      result.error(nil, nil, nil, error);
    } else {
      [_serverTimestampMap setObject:serverTimestampBehaviorString forKey:@([snapshot hash])];
      result.success(snapshot);
    }
  };

  [document getDocumentWithSource:source completion:completion];
}

- (void)queryGet:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRQuery *query = arguments[@"query"];
  // Why we check [NSNull null]:  https://github.com/firebase/flutterfire/issues/9328
  if (query == nil || query == [NSNull null]) {
    result.error(@"sdk-error",
                 @"An error occurred while parsing query arguments, see native logs for more "
                 @"information. Please report this issue.",
                 nil, nil);
    return;
  }

  NSString *serverTimestampBehaviorString = arguments[@"serverTimestampBehavior"];

  FIRFirestoreSource source = [FLTFirebaseFirestoreUtils FIRFirestoreSourceFromArguments:arguments];
  [query getDocumentsWithSource:source
                     completion:^(FIRQuerySnapshot *_Nullable snapshot, NSError *_Nullable error) {
                       if (error != nil) {
                         result.error(nil, nil, nil, error);
                       } else {
                         [_serverTimestampMap setObject:serverTimestampBehaviorString
                                                 forKey:@([snapshot hash])];
                         result.success(snapshot);
                       }
                     }];
}

- (void)namedQueryGet:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRFirestore *firestore = arguments[@"firestore"];
  NSString *name = arguments[@"name"];

  FIRFirestoreSource source = [FLTFirebaseFirestoreUtils FIRFirestoreSourceFromArguments:arguments];
  NSString *serverTimestampBehaviorString = arguments[@"serverTimestampBehavior"];

  [firestore getQueryNamed:name
                completion:^(FIRQuery *_Nullable query) {
                  if (query == nil) {
                    result.error(@"non-existent-named-query",
                                 @"Named query has not been found. Please check it has been loaded "
                                 @"properly via loadBundle().",
                                 nil, nil);
                    return;
                  }
                  [query getDocumentsWithSource:source
                                     completion:^(FIRQuerySnapshot *_Nullable snapshot,
                                                  NSError *_Nullable error) {
                                       if (error != nil) {
                                         result.error(nil, nil, nil, error);
                                       } else {
                                         [_serverTimestampMap
                                             setObject:serverTimestampBehaviorString
                                                forKey:@([snapshot hash])];
                                         result.success(snapshot);
                                       }
                                     }];
                }];
}

- (void)batchCommit:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRFirestore *firestore = arguments[@"firestore"];
  NSArray<NSDictionary *> *writes = arguments[@"writes"];
  FIRWriteBatch *batch = [firestore batch];

  for (NSDictionary *write in writes) {
    NSString *type = write[@"type"];
    NSString *path = write[@"path"];
    FIRDocumentReference *reference = [firestore documentWithPath:path];

    if ([@"DELETE" isEqualToString:type]) {
      [batch deleteDocument:reference];
    } else if ([@"UPDATE" isEqualToString:type]) {
      NSDictionary *data = write[@"data"];
      [batch updateData:data forDocument:reference];
    } else if ([@"SET" isEqualToString:type]) {
      NSDictionary *data = write[@"data"];
      NSDictionary *options = write[@"options"];
      if ([options[@"merge"] isEqual:@YES]) {
        [batch setData:data forDocument:reference merge:YES];
      } else if (![options[@"mergeFields"] isEqual:[NSNull null]]) {
        [batch setData:data forDocument:reference mergeFields:options[@"mergeFields"]];
      } else {
        [batch setData:data forDocument:reference];
      }
    }
  }

  [batch commitWithCompletion:^(NSError *error) {
    if (error != nil) {
      result.error(nil, nil, nil, error);
    } else {
      result.success(nil);
    }
  }];
}

- (void)aggregateQuery:(id)arguments withMethodCallResult:(FLTFirebaseMethodCallResult *)result {
  FIRQuery *query = arguments[@"query"];

  // NOTE: There is only "server" as the source at the moment. So this
  // is unused for the time being. Using "FIRAggregateSourceServer".
  // NSString *source = arguments[@"source"];

  FIRAggregateQuery *aggregateQuery = [query count];

  [aggregateQuery aggregationWithSource:FIRAggregateSourceServer
                             completion:^(FIRAggregateQuerySnapshot *_Nullable snapshot,
                                          NSError *_Nullable error) {
                               if (error != nil) {
                                 result.error(nil, nil, nil, error);
                               } else {
                                 NSMutableDictionary *response = [NSMutableDictionary dictionary];
                                 response[@"count"] = snapshot.count;

                                 result.success(response);
                               }
                             }];
}

- (NSString *)registerEventChannelWithPrefix:(NSString *)prefix
                               streamHandler:(NSObject<FlutterStreamHandler> *)handler {
  return [self registerEventChannelWithPrefix:prefix
                                   identifier:[[[NSUUID UUID] UUIDString] lowercaseString]
                                streamHandler:handler];
}

- (NSString *)registerEventChannelWithPrefix:(NSString *)prefix
                                  identifier:(NSString *)identifier
                               streamHandler:(NSObject<FlutterStreamHandler> *)handler {
  NSString *channelName = [NSString stringWithFormat:@"%@/%@", prefix, identifier];

  FlutterEventChannel *channel = [[FlutterEventChannel alloc] initWithName:channelName
                                                           binaryMessenger:_binaryMessenger
                                                                     codec:_codec];

  [channel setStreamHandler:handler];
  [_eventChannels setObject:channel forKey:identifier];
  [_streamHandlers setObject:handler forKey:identifier];

  return identifier;
}

@end
