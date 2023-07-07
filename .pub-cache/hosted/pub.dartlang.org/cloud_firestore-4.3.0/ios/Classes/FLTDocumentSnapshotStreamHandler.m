// Copyright 2021 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Firebase/Firebase.h>
#import <firebase_core/FLTFirebasePluginRegistry.h>

#import "Private/FLTDocumentSnapshotStreamHandler.h"
#import "Private/FLTFirebaseFirestoreUtils.h"

@interface FLTDocumentSnapshotStreamHandler ()
@property(readwrite, strong) id<FIRListenerRegistration> listenerRegistration;
@end

@implementation FLTDocumentSnapshotStreamHandler

- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:(nonnull FlutterEventSink)events {
  NSNumber *includeMetadataChanges = arguments[@"includeMetadataChanges"];

  FIRDocumentReference *document = arguments[@"reference"];

  id listener = ^(FIRDocumentSnapshot *snapshot, NSError *_Nullable error) {
    if (error) {
      NSArray *codeAndMessage = [FLTFirebaseFirestoreUtils ErrorCodeAndMessageFromNSError:error];
      NSString *code = codeAndMessage[0];
      NSString *message = codeAndMessage[1];
      NSDictionary *details = @{
        @"code" : code,
        @"message" : message,
      };
      dispatch_async(dispatch_get_main_queue(), ^{
        events([FLTFirebasePlugin createFlutterErrorFromCode:code
                                                     message:message
                                             optionalDetails:details
                                          andOptionalNSError:error]);
      });
    } else {
      dispatch_async(dispatch_get_main_queue(), ^{
        events(snapshot);
      });
    }
  };

  self.listenerRegistration =
      [document addSnapshotListenerWithIncludeMetadataChanges:includeMetadataChanges.boolValue
                                                     listener:listener];

  return nil;
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments {
  [self.listenerRegistration remove];
  self.listenerRegistration = nil;

  return nil;
}

@end
