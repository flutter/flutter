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

#import <GoogleMobileAds/GADAdNetworkExtras.h>

/**
 * Provides network specific parameters to include in ad requests.
 * An implementation of this protocol can be passed to FLTGoogleMobileAdsPlugin
 * using registerMediationNetworkExtrasProvider
 */
@protocol FLTMediationNetworkExtrasProvider
@required

/**
 * Gets an array of GADAdNetworkExtras to include in the GADRequest for the
 * given adUnitId and mediationExtrasIdentifier.
 *
 * @param adUnitId the ad unit id associated with the ad request
 * @param mediationExtrasIdentifier  n optional string that comes from the
 * associated dart ad request object. This allows for additional control of
 * which extras to include for an ad request, beyond just the ad unit.
 * @return an array of GADAdNetworkExtras to include in the ad request.
 */
- (NSArray<id<GADAdNetworkExtras>> *_Nullable)
           getMediationExtras:(NSString *_Nonnull)adUnitId
    mediationExtrasIdentifier:(NSString *_Nullable)mediationExtrasIdentifier;

@end
