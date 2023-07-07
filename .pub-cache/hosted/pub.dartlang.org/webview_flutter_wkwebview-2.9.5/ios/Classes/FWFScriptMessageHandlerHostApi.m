// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FWFScriptMessageHandlerHostApi.h"
#import "FWFDataConverters.h"

@interface FWFScriptMessageHandlerFlutterApiImpl ()
// InstanceManager must be weak to prevent a circular reference with the object it stores.
@property(nonatomic, weak) FWFInstanceManager *instanceManager;
@end

@implementation FWFScriptMessageHandlerFlutterApiImpl
- (instancetype)initWithBinaryMessenger:(id<FlutterBinaryMessenger>)binaryMessenger
                        instanceManager:(FWFInstanceManager *)instanceManager {
  self = [self initWithBinaryMessenger:binaryMessenger];
  if (self) {
    _instanceManager = instanceManager;
  }
  return self;
}

- (long)identifierForHandler:(FWFScriptMessageHandler *)instance {
  return [self.instanceManager identifierWithStrongReferenceForInstance:instance];
}

- (void)didReceiveScriptMessageForHandler:(FWFScriptMessageHandler *)instance
                    userContentController:(WKUserContentController *)userContentController
                                  message:(WKScriptMessage *)message
                               completion:(void (^)(NSError *_Nullable))completion {
  NSNumber *userContentControllerIdentifier =
      @([self.instanceManager identifierWithStrongReferenceForInstance:userContentController]);
  FWFWKScriptMessageData *messageData = FWFWKScriptMessageDataFromWKScriptMessage(message);
  [self didReceiveScriptMessageForHandlerWithIdentifier:@([self identifierForHandler:instance])
                        userContentControllerIdentifier:userContentControllerIdentifier
                                                message:messageData
                                             completion:completion];
}
@end

@implementation FWFScriptMessageHandler
- (instancetype)initWithBinaryMessenger:(id<FlutterBinaryMessenger>)binaryMessenger
                        instanceManager:(FWFInstanceManager *)instanceManager {
  self = [super initWithBinaryMessenger:binaryMessenger instanceManager:instanceManager];
  if (self) {
    _scriptMessageHandlerAPI =
        [[FWFScriptMessageHandlerFlutterApiImpl alloc] initWithBinaryMessenger:binaryMessenger
                                                               instanceManager:instanceManager];
  }
  return self;
}

- (void)userContentController:(nonnull WKUserContentController *)userContentController
      didReceiveScriptMessage:(nonnull WKScriptMessage *)message {
  [self.scriptMessageHandlerAPI didReceiveScriptMessageForHandler:self
                                            userContentController:userContentController
                                                          message:message
                                                       completion:^(NSError *error) {
                                                         NSAssert(!error, @"%@", error);
                                                       }];
}
@end

@interface FWFScriptMessageHandlerHostApiImpl ()
// BinaryMessenger must be weak to prevent a circular reference with the host API it
// references.
@property(nonatomic, weak) id<FlutterBinaryMessenger> binaryMessenger;
// InstanceManager must be weak to prevent a circular reference with the object it stores.
@property(nonatomic, weak) FWFInstanceManager *instanceManager;
@end

@implementation FWFScriptMessageHandlerHostApiImpl
- (instancetype)initWithBinaryMessenger:(id<FlutterBinaryMessenger>)binaryMessenger
                        instanceManager:(FWFInstanceManager *)instanceManager {
  self = [self init];
  if (self) {
    _binaryMessenger = binaryMessenger;
    _instanceManager = instanceManager;
  }
  return self;
}

- (FWFScriptMessageHandler *)scriptMessageHandlerForIdentifier:(NSNumber *)identifier {
  return (FWFScriptMessageHandler *)[self.instanceManager
      instanceForIdentifier:identifier.longValue];
}

- (void)createWithIdentifier:(nonnull NSNumber *)identifier
                       error:(FlutterError *_Nullable *_Nonnull)error {
  FWFScriptMessageHandler *scriptMessageHandler =
      [[FWFScriptMessageHandler alloc] initWithBinaryMessenger:self.binaryMessenger
                                               instanceManager:self.instanceManager];
  [self.instanceManager addDartCreatedInstance:scriptMessageHandler
                                withIdentifier:identifier.longValue];
}
@end
