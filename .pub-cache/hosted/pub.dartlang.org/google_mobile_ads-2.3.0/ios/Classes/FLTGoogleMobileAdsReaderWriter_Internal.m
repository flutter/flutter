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

#import "FLTGoogleMobileAdsReaderWriter_Internal.h"
#import "FLTAdUtil.h"

// The type values below must be consistent for each platform.
typedef NS_ENUM(NSInteger, FLTAdMobField) {
  FLTAdMobFieldAdSize = 128,
  FLTAdMobFieldAdRequest = 129,
  FLTAdMobFieldFluidAdSize = 130,
  FLTAdMobFieldRewardItem = 132,
  FLTAdMobFieldLoadError = 133,
  FLTAdMobFieldAdManagerAdRequest = 134,
  FLTAdMobFieldAdapterInitializationState = 135,
  FLTAdMobFieldAdapterStatus = 136,
  FLTAdMobFieldInitializationStatus = 137,
  FLTAdmobFieldServerSideVerificationOptions = 138,
  FLTAdmobFieldAdError = 139,
  FLTAdmobFieldGadResponseInfo = 140,
  FLTAdmobFieldGADAdNetworkResponseInfo = 141,
  FLTAdmobFieldAnchoredAdaptiveBannerAdSize = 142,
  FLTAdmobFieldSmartBannerAdSize = 143,
  FLTAdmobFieldNativeAdOptions = 144,
  FLTAdmobFieldVideoOptions = 145,
  FLTAdmobFieldInlineAdaptiveAdSize = 146,
  FLTAdmobRequestConfigurationParams = 148,
};

@interface FLTGoogleMobileAdsWriter : FlutterStandardWriter
@end

@implementation FLTGoogleMobileAdsReaderWriter
- (instancetype)init {
  return [self initWithFactory:[[FLTAdSizeFactory alloc] init]];
}

- (instancetype _Nonnull)initWithFactory:
    (FLTAdSizeFactory *_Nonnull)adSizeFactory {
  self = [super init];
  if (self) {
    _adSizeFactory = adSizeFactory;
  }
  return self;
}

- (FlutterStandardReader *_Nonnull)readerWithData:(NSData *_Nonnull)data {
  FLTGoogleMobileAdsReader *reader =
      [[FLTGoogleMobileAdsReader alloc] initWithFactory:_adSizeFactory
                                                   data:data];
  reader.mediationNetworkExtrasProvider = _mediationNetworkExtrasProvider;
  return reader;
}

- (FlutterStandardWriter *_Nonnull)writerWithData:
    (NSMutableData *_Nonnull)data {
  return [[FLTGoogleMobileAdsWriter alloc] initWithData:data];
}
@end

@implementation FLTGoogleMobileAdsReader {
  NSString *_requestAgent;
}
- (instancetype _Nonnull)initWithFactory:
                             (FLTAdSizeFactory *_Nonnull)adSizeFactory
                                    data:(NSData *_Nonnull)data {
  self = [super initWithData:data];
  if (self) {
    _adSizeFactory = adSizeFactory;
    _requestAgent = [FLTAdUtil requestAgent];
  }
  return self;
}

- (id _Nullable)readValueOfType:(UInt8)type {
  FLTAdMobField field = (FLTAdMobField)type;
  switch (field) {
  case FLTAdMobFieldAdSize:
    return [[FLTAdSize alloc]
        initWithWidth:[self readValueOfType:[self readByte]]
               height:[self readValueOfType:[self readByte]]];
  case FLTAdMobFieldFluidAdSize:
    return [[FLTFluidSize alloc] init];
  case FLTAdMobFieldAdRequest: {
    FLTAdRequest *request = [[FLTAdRequest alloc] init];

    request.keywords = [self readValueOfType:[self readByte]];
    request.contentURL = [self readValueOfType:[self readByte]];

    NSNumber *nonPersonalizedAds = [self readValueOfType:[self readByte]];
    request.nonPersonalizedAds = nonPersonalizedAds.boolValue;
    request.neighboringContentURLs = [self readValueOfType:[self readByte]];
    request.mediationExtrasIdentifier = [self readValueOfType:[self readByte]];
    request.mediationNetworkExtrasProvider = _mediationNetworkExtrasProvider;
    request.adMobExtras = [self readValueOfType:[self readByte]];
    request.requestAgent = _requestAgent;
    return request;
  }
  case FLTAdMobFieldRewardItem: {
    return [[FLTRewardItem alloc]
        initWithAmount:[self readValueOfType:[self readByte]]
                  type:[self readValueOfType:[self readByte]]];
  }
  case FLTAdmobFieldGadResponseInfo: {
    NSString *responseIdentifier = [self readValueOfType:[self readByte]];
    NSString *adNetworkClassName = [self readValueOfType:[self readByte]];
    NSArray<FLTGADAdNetworkResponseInfo *> *adNetworkInfoArray =
        [self readValueOfType:[self readByte]];
    FLTGADAdNetworkResponseInfo *loadedResponseInfo =
        [self readValueOfType:[self readByte]];
    NSDictionary<NSString *, id> *extrasDictionary =
        [self readValueOfType:[self readByte]];
    FLTGADResponseInfo *gadResponseInfo = [[FLTGADResponseInfo alloc] init];
    gadResponseInfo.adNetworkClassName = adNetworkClassName;
    gadResponseInfo.responseIdentifier = responseIdentifier;
    gadResponseInfo.adNetworkInfoArray = adNetworkInfoArray;
    gadResponseInfo.loadedAdNetworkResponseInfo = loadedResponseInfo;
    gadResponseInfo.extrasDictionary = extrasDictionary;
    return gadResponseInfo;
  }
  case FLTAdmobFieldGADAdNetworkResponseInfo: {
    NSString *adNetworkClassName = [self readValueOfType:[self readByte]];
    NSNumber *latency = [self readValueOfType:[self readByte]];
    NSString *dictionaryDescription = [self readValueOfType:[self readByte]];
    NSDictionary<NSString *, NSString *> *adUnitMapping =
        [self readValueOfType:[self readByte]];
    NSError *error = [self readValueOfType:[self readByte]];
    NSString *adSourceName = [self readValueOfType:[self readByte]];
    NSString *adSourceID = [self readValueOfType:[self readByte]];
    NSString *adSourceInstanceName = [self readValueOfType:[self readByte]];
    NSString *adSourceInstanceID = [self readValueOfType:[self readByte]];
    FLTGADAdNetworkResponseInfo *adNetworkResponseInfo =
        [[FLTGADAdNetworkResponseInfo alloc] init];
    adNetworkResponseInfo.adNetworkClassName = adNetworkClassName;
    adNetworkResponseInfo.latency = latency;
    adNetworkResponseInfo.dictionaryDescription = dictionaryDescription;
    adNetworkResponseInfo.adUnitMapping = adUnitMapping;
    adNetworkResponseInfo.error = error;
    adNetworkResponseInfo.adSourceName = adSourceName;
    adNetworkResponseInfo.adSourceID = adSourceID;
    adNetworkResponseInfo.adSourceInstanceName = adSourceInstanceName;
    adNetworkResponseInfo.adSourceInstanceID = adSourceInstanceID;

    return adNetworkResponseInfo;
  }
  case FLTAdMobFieldLoadError: {
    NSNumber *code = [self readValueOfType:[self readByte]];
    NSString *domain = [self readValueOfType:[self readByte]];
    NSString *message = [self readValueOfType:[self readByte]];
    FLTGADResponseInfo *responseInfo = [self readValueOfType:[self readByte]];
    FLTLoadAdError *loadAdError = [[FLTLoadAdError alloc] init];
    loadAdError.code = code.longValue;
    loadAdError.domain = domain;
    loadAdError.message = message;
    loadAdError.responseInfo = responseInfo;
    return loadAdError;
  }
  case FLTAdmobFieldAdError: {
    NSNumber *code = [self readValueOfType:[self readByte]];
    NSString *domain = [self readValueOfType:[self readByte]];
    NSString *message = [self readValueOfType:[self readByte]];
    return [NSError errorWithDomain:domain
                               code:code.longValue
                           userInfo:@{NSLocalizedDescriptionKey : message}];
  }
  case FLTAdMobFieldAdManagerAdRequest: {
    FLTGAMAdRequest *request = [[FLTGAMAdRequest alloc] init];
    request.keywords = [self readValueOfType:[self readByte]];
    request.contentURL = [self readValueOfType:[self readByte]];
    request.customTargeting = [self readValueOfType:[self readByte]];
    request.customTargetingLists = [self readValueOfType:[self readByte]];
    NSNumber *nonPersonalizedAds = [self readValueOfType:[self readByte]];
    request.nonPersonalizedAds = nonPersonalizedAds.boolValue;
    request.neighboringContentURLs = [self readValueOfType:[self readByte]];
    request.pubProvidedID = [self readValueOfType:[self readByte]];
    request.mediationExtrasIdentifier = [self readValueOfType:[self readByte]];
    request.mediationNetworkExtrasProvider = _mediationNetworkExtrasProvider;
    request.adMobExtras = [self readValueOfType:[self readByte]];
    request.requestAgent = _requestAgent;
    return request;
  }
  case FLTAdMobFieldAdapterInitializationState: {
    NSString *state = [self readValueOfType:[self readByte]];
    if (!state) {
      return nil;
    } else if ([@"notReady" isEqualToString:state]) {
      return @(FLTAdapterInitializationStateNotReady);
    } else if ([@"ready" isEqualToString:state]) {
      return @(FLTAdapterInitializationStateReady);
    }
    NSLog(@"Failed to interpret AdapterInitializationState of: %@", state);
    return nil;
  }
  case FLTAdMobFieldAdapterStatus: {
    FLTAdapterStatus *status = [[FLTAdapterStatus alloc] init];
    status.state = [self readValueOfType:[self readByte]];
    status.statusDescription = [self readValueOfType:[self readByte]];
    status.latency = [self readValueOfType:[self readByte]];
    return status;
  }
  case FLTAdMobFieldInitializationStatus: {
    FLTInitializationStatus *status = [[FLTInitializationStatus alloc] init];
    status.adapterStatuses = [self readValueOfType:[self readByte]];
    return status;
  }
  case FLTAdmobFieldServerSideVerificationOptions: {
    FLTServerSideVerificationOptions *options =
        [[FLTServerSideVerificationOptions alloc] init];
    options.userIdentifier = [self readValueOfType:[self readByte]];
    options.customRewardString = [self readValueOfType:[self readByte]];
    return options;
  }
  case FLTAdmobFieldAnchoredAdaptiveBannerAdSize: {
    NSString *orientation = [self readValueOfType:[self readByte]];
    NSNumber *width = [self readValueOfType:[self readByte]];
    return [[FLTAnchoredAdaptiveBannerSize alloc] initWithFactory:_adSizeFactory
                                                      orientation:orientation
                                                            width:width];
  }
  case FLTAdmobFieldSmartBannerAdSize:
    return [[FLTSmartBannerSize alloc]
        initWithOrientation:[self readValueOfType:[self readByte]]];
  case FLTAdmobFieldNativeAdOptions: {
    return [[FLTNativeAdOptions alloc]
            initWithAdChoicesPlacement:[self readValueOfType:[self readByte]]
                      mediaAspectRatio:[self readValueOfType:[self readByte]]
                          videoOptions:[self readValueOfType:[self readByte]]
               requestCustomMuteThisAd:[self readValueOfType:[self readByte]]
           shouldRequestMultipleImages:[self readValueOfType:[self readByte]]
        shouldReturnUrlsForImageAssets:[self readValueOfType:[self readByte]]];
  }
  case FLTAdmobFieldVideoOptions: {
    return [[FLTVideoOptions alloc]
        initWithClickToExpandRequested:[self readValueOfType:[self readByte]]
               customControlsRequested:[self readValueOfType:[self readByte]]
                            startMuted:[self readValueOfType:[self readByte]]];
  }
  case FLTAdmobRequestConfigurationParams: {
    GADRequestConfiguration *requestConfig = [GADRequestConfiguration alloc];
    requestConfig.maxAdContentRating = [self readValueOfType:[self readByte]];
    [requestConfig
        tagForChildDirectedTreatment:[self readValueOfType:[self readByte]]];
    [requestConfig
        tagForUnderAgeOfConsent:[self readValueOfType:[self readByte]]];
    requestConfig.testDeviceIdentifiers =
        [self readValueOfType:[self readByte]];
    return requestConfig;
  }
  case FLTAdmobFieldInlineAdaptiveAdSize: {
    return [[FLTInlineAdaptiveBannerSize alloc]
        initWithFactory:_adSizeFactory
                  width:[self readValueOfType:[self readByte]]
              maxHeight:[self readValueOfType:[self readByte]]
            orientation:[self readValueOfType:[self readByte]]];
  }
  }
  return [super readValueOfType:type];
}
@end

@implementation FLTGoogleMobileAdsWriter
- (void)writeAdSize:(FLTAdSize *_Nonnull)value {
  if ([value isKindOfClass:[FLTInlineAdaptiveBannerSize class]]) {
    [self writeByte:FLTAdmobFieldInlineAdaptiveAdSize];
    FLTInlineAdaptiveBannerSize *size = (FLTInlineAdaptiveBannerSize *)value;
    [self writeValue:size.width];
    [self writeValue:size.maxHeight];
    [self writeValue:size.orientation];
  } else if ([value isKindOfClass:[FLTAnchoredAdaptiveBannerSize class]]) {
    [self writeByte:FLTAdmobFieldAnchoredAdaptiveBannerAdSize];
    FLTAnchoredAdaptiveBannerSize *size =
        (FLTAnchoredAdaptiveBannerSize *)value;
    [self writeValue:size.orientation];
    [self writeValue:size.width];
  } else if ([value isKindOfClass:[FLTSmartBannerSize class]]) {
    [self writeByte:FLTAdmobFieldSmartBannerAdSize];
    FLTSmartBannerSize *size = (FLTSmartBannerSize *)value;
    [self writeValue:size.orientation];
  } else if ([value isKindOfClass:[FLTFluidSize class]]) {
    [self writeByte:FLTAdMobFieldFluidAdSize];
  } else if ([value isKindOfClass:[FLTAdSize class]]) {
    [self writeByte:FLTAdMobFieldAdSize];
    [self writeValue:value.width];
    [self writeValue:value.height];
  }
}

- (void)writeValue:(id)value {
  if ([value isKindOfClass:[FLTAdSize class]]) {
    [self writeAdSize:value];
  } else if ([value isKindOfClass:[FLTGAMAdRequest class]]) {
    [self writeByte:FLTAdMobFieldAdManagerAdRequest];
    FLTGAMAdRequest *request = value;
    [self writeValue:request.keywords];
    [self writeValue:request.contentURL];
    [self writeValue:request.customTargeting];
    [self writeValue:request.customTargetingLists];
    [self writeValue:@(request.nonPersonalizedAds)];
    [self writeValue:request.neighboringContentURLs];
    [self writeValue:request.pubProvidedID];
    [self writeValue:request.mediationExtrasIdentifier];
    [self writeValue:request.adMobExtras];
  } else if ([value isKindOfClass:[FLTAdRequest class]]) {
    [self writeByte:FLTAdMobFieldAdRequest];
    FLTAdRequest *request = value;
    [self writeValue:request.keywords];
    [self writeValue:request.contentURL];
    [self writeValue:@(request.nonPersonalizedAds)];
    [self writeValue:request.neighboringContentURLs];
    [self writeValue:request.mediationExtrasIdentifier];
    [self writeValue:request.adMobExtras];
  } else if ([value isKindOfClass:[FLTRewardItem class]]) {
    [self writeByte:FLTAdMobFieldRewardItem];
    FLTRewardItem *item = value;
    [self writeValue:item.amount];
    [self writeValue:item.type];
  } else if ([value isKindOfClass:[FLTGADResponseInfo class]]) {
    [self writeByte:FLTAdmobFieldGadResponseInfo];
    FLTGADResponseInfo *responseInfo = value;
    [self writeValue:responseInfo.responseIdentifier];
    [self writeValue:responseInfo.adNetworkClassName];
    [self writeValue:responseInfo.adNetworkInfoArray];
    [self writeValue:responseInfo.loadedAdNetworkResponseInfo];
    [self writeValue:responseInfo.extrasDictionary];
  } else if ([value isKindOfClass:[FLTGADAdNetworkResponseInfo class]]) {
    [self writeByte:FLTAdmobFieldGADAdNetworkResponseInfo];
    FLTGADAdNetworkResponseInfo *networkResponseInfo = value;
    [self writeValue:networkResponseInfo.adNetworkClassName];
    [self writeValue:networkResponseInfo.latency];
    [self writeValue:networkResponseInfo.dictionaryDescription];
    [self writeValue:networkResponseInfo.adUnitMapping];
    [self writeValue:networkResponseInfo.error];
    [self writeValue:networkResponseInfo.adSourceName];
    [self writeValue:networkResponseInfo.adSourceID];
    [self writeValue:networkResponseInfo.adSourceInstanceName];
    [self writeValue:networkResponseInfo.adSourceInstanceID];
  } else if ([value isKindOfClass:[FLTLoadAdError class]]) {
    [self writeByte:FLTAdMobFieldLoadError];
    FLTLoadAdError *error = value;
    [self writeValue:@(error.code)];
    [self writeValue:error.domain];
    [self writeValue:error.message];
    [self writeValue:error.responseInfo];
  } else if ([value isKindOfClass:[NSError class]]) {
    [self writeByte:FLTAdmobFieldAdError];
    NSError *error = value;
    [self writeValue:@(error.code)];
    [self writeValue:error.domain];
    [self writeValue:error.localizedDescription];
  } else if ([value isKindOfClass:[FLTAdapterStatus class]]) {
    [self writeByte:FLTAdMobFieldAdapterStatus];
    FLTAdapterStatus *status = value;
    [self writeByte:FLTAdMobFieldAdapterInitializationState];
    if (!status.state) {
      [self writeValue:[NSNull null]];
    } else if (status.state.unsignedLongValue ==
               FLTAdapterInitializationStateNotReady) {
      [self writeValue:@"notReady"];
    } else if (status.state.unsignedLongValue ==
               FLTAdapterInitializationStateReady) {
      [self writeValue:@"ready"];
    } else {
      NSLog(@"Failed to interpret AdapterInitializationState of: %@",
            status.state);
      [self writeValue:[NSNull null]];
    }
    [self writeValue:status.statusDescription];
    [self writeValue:status.latency];
  } else if ([value isKindOfClass:[FLTInitializationStatus class]]) {
    [self writeByte:FLTAdMobFieldInitializationStatus];
    FLTInitializationStatus *status = value;
    [self writeValue:status.adapterStatuses];
  } else if ([value isKindOfClass:[FLTServerSideVerificationOptions class]]) {
    [self writeByte:FLTAdmobFieldServerSideVerificationOptions];
    FLTServerSideVerificationOptions *options = value;
    [self writeValue:options.userIdentifier];
    [self writeValue:options.customRewardString];
  } else if ([value isKindOfClass:[FLTNativeAdOptions class]]) {
    [self writeByte:FLTAdmobFieldNativeAdOptions];
    FLTNativeAdOptions *options = value;
    [self writeValue:options.adChoicesPlacement];
    [self writeValue:options.mediaAspectRatio];
    [self writeValue:options.videoOptions];
    [self writeValue:options.requestCustomMuteThisAd];
    [self writeValue:options.shouldRequestMultipleImages];
    [self writeValue:options.shouldReturnUrlsForImageAssets];
  } else if ([value isKindOfClass:[FLTVideoOptions class]]) {
    [self writeByte:FLTAdmobFieldVideoOptions];
    FLTVideoOptions *options = value;
    [self writeValue:options.clickToExpandRequested];
    [self writeValue:options.customControlsRequested];
    [self writeValue:options.startMuted];
  } else if ([value isKindOfClass:[GADRequestConfiguration class]]) {
    [self writeByte:FLTAdmobRequestConfigurationParams];
    GADRequestConfiguration *params = value;
    [self writeValue:params.maxAdContentRating];
    // using null temporarily for tagForUnderAgeOfConsent and
    // tagForChildDirectedTreatment as there are no getters for them in
    // GADRequestConfiguration.
    [super writeValue:NSNull.null];
    [super writeValue:NSNull.null];
    [self writeValue:params.testDeviceIdentifiers];
  } else {
    [super writeValue:value];
  }
}
@end
