// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterJSONMessageListener.h"

@implementation FlutterJSONMessageListener

- (NSString*)didReceiveString:(NSString*)message {
  if (!message)
    return nil;
  NSError *error = nil;
  NSData* data = [message dataUsingEncoding:NSUTF8StringEncoding];
  NSDictionary* jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
  if (error)
    return nil;
  NSDictionary* response = [self didReceiveJSON:jsonObject];
  if (!response)
    return nil;
  NSData* responseData = [NSJSONSerialization dataWithJSONObject:response options:0 error:nil];
  if (!responseData)
    return nil;
  return [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease];
}

- (NSDictionary*)didReceiveJSON:(NSDictionary*)message {
  return nil;
}

- (NSString *)messageName {
  return nil;
}

@end
