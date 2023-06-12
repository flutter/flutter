// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FLTThreadSafeFlutterResult.h"
#import <Foundation/Foundation.h>
#import "QueueUtils.h"

@implementation FLTThreadSafeFlutterResult {
}

- (id)initWithResult:(FlutterResult)result {
  self = [super init];
  if (!self) {
    return nil;
  }
  _flutterResult = result;
  return self;
}

- (void)sendSuccess {
  [self send:nil];
}

- (void)sendSuccessWithData:(id)data {
  [self send:data];
}

- (void)sendError:(NSError *)error {
  [self sendErrorWithCode:[NSString stringWithFormat:@"Error %d", (int)error.code]
                  message:error.localizedDescription
                  details:error.domain];
}

- (void)sendErrorWithCode:(NSString *)code
                  message:(NSString *_Nullable)message
                  details:(id _Nullable)details {
  FlutterError *flutterError = [FlutterError errorWithCode:code message:message details:details];
  [self send:flutterError];
}

- (void)sendFlutterError:(FlutterError *)flutterError {
  [self send:flutterError];
}

- (void)sendNotImplemented {
  [self send:FlutterMethodNotImplemented];
}

/**
 * Sends result to flutterResult on the main thread.
 */
- (void)send:(id _Nullable)result {
  FLTEnsureToRunOnMainQueue(^{
    self.flutterResult(result);
  });
}

@end
