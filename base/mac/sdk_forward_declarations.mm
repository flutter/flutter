// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/mac/sdk_forward_declarations.h"

#if !defined(MAC_OS_X_VERSION_10_7) || \
    MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_7
NSString* const NSWindowWillEnterFullScreenNotification =
    @"NSWindowWillEnterFullScreenNotification";

NSString* const NSWindowWillExitFullScreenNotification =
    @"NSWindowWillExitFullScreenNotification";

NSString* const NSWindowDidEnterFullScreenNotification =
    @"NSWindowDidEnterFullScreenNotification";

NSString* const NSWindowDidExitFullScreenNotification =
    @"NSWindowDidExitFullScreenNotification";

NSString* const NSWindowDidChangeBackingPropertiesNotification =
    @"NSWindowDidChangeBackingPropertiesNotification";

NSString* const CBAdvertisementDataServiceDataKey = @"kCBAdvDataServiceData";

NSString* const NSPreferredScrollerStyleDidChangeNotification =
    @"NSPreferredScrollerStyleDidChangeNotification";
#endif  // MAC_OS_X_VERSION_10_7

#if !defined(MAC_OS_X_VERSION_10_9) || \
    MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_9
NSString* const NSWindowDidChangeOcclusionStateNotification =
    @"NSWindowDidChangeOcclusionStateNotification";

NSString* const CBAdvertisementDataIsConnectable = @"kCBAdvDataIsConnectable";
#endif  // MAC_OS_X_VERSION_10_9

#if !defined(MAC_OS_X_VERSION_10_10) || \
    MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_10
NSString* const NSUserActivityTypeBrowsingWeb =
    @"NSUserActivityTypeBrowsingWeb";

NSString* const NSAppearanceNameVibrantDark = @"NSAppearanceNameVibrantDark";
#endif  // MAC_OS_X_VERSION_10_10
