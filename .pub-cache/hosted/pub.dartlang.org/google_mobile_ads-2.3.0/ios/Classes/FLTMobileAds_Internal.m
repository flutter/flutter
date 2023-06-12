// Copyright 2021 Google LLC
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

#import "FLTMobileAds_Internal.h"

@implementation FLTAdapterStatus
- (instancetype)initWithStatus:(GADAdapterStatus *)status {
  self = [self init];
  if (self) {
    switch (status.state) {
    case GADAdapterInitializationStateNotReady:
      _state = @(FLTAdapterInitializationStateNotReady);
      break;
    case GADAdapterInitializationStateReady:
      _state = @(FLTAdapterInitializationStateReady);
      break;
    }
    _statusDescription = status.description;
    _latency = @(status.latency);
  }
  return self;
}
@end

@implementation FLTInitializationStatus
- (instancetype)initWithStatus:(GADInitializationStatus *)status {
  self = [self init];
  if (self) {
    NSMutableDictionary *newDictionary = [NSMutableDictionary dictionary];
    for (NSString *name in status.adapterStatusesByClassName.allKeys) {
      FLTAdapterStatus *adapterStatus = [[FLTAdapterStatus alloc]
          initWithStatus:status.adapterStatusesByClassName[name]];
      [newDictionary setValue:adapterStatus forKey:name];
    }
    _adapterStatuses = newDictionary;
  }
  return self;
}
@end

@implementation FLTServerSideVerificationOptions
- (GADServerSideVerificationOptions *_Nonnull)
    asGADServerSideVerificationOptions {
  GADServerSideVerificationOptions *options =
      [[GADServerSideVerificationOptions alloc] init];
  options.userIdentifier = _userIdentifier;
  options.customRewardString = _customRewardString;
  return options;
}
@end
