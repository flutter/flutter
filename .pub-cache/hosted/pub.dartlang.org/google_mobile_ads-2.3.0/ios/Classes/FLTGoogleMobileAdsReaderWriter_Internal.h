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

#import "FLTAd_Internal.h"
#import "FLTMediationNetworkExtrasProvider.h"
#import <Flutter/Flutter.h>

@class FLTAdSizeFactory;

@interface FLTGoogleMobileAdsReaderWriter : FlutterStandardReaderWriter
@property(readonly) FLTAdSizeFactory *_Nonnull adSizeFactory;
@property id<
    FLTMediationNetworkExtrasProvider> _Nullable mediationNetworkExtrasProvider;

- (instancetype _Nonnull)initWithFactory:
    (FLTAdSizeFactory *_Nonnull)adSizeFactory;
@end

@interface FLTGoogleMobileAdsReader : FlutterStandardReader
@property(readonly) FLTAdSizeFactory *_Nonnull adSizeFactory;
@property id<
    FLTMediationNetworkExtrasProvider> _Nullable mediationNetworkExtrasProvider;

- (instancetype _Nonnull)initWithFactory:
                             (FLTAdSizeFactory *_Nonnull)adSizeFactory
                                    data:(NSData *_Nonnull)data;
@end
