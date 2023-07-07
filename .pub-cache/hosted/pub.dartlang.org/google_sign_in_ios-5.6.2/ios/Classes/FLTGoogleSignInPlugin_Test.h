// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This header is available in the Test module. Import via "@import google_sign_in.Test;"

#import <google_sign_in_ios/FLTGoogleSignInPlugin.h>

NS_ASSUME_NONNULL_BEGIN

@class GIDSignIn;

/// Methods exposed for unit testing.
@interface FLTGoogleSignInPlugin ()

/// Inject @c GIDSignIn for testing.
- (instancetype)initWithSignIn:(GIDSignIn *)signIn;

/// Inject @c GIDSignIn and @c googleServiceProperties for testing.
- (instancetype)initWithSignIn:(GIDSignIn *)signIn
    withGoogleServiceProperties:(nullable NSDictionary<NSString *, id> *)googleServiceProperties
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
