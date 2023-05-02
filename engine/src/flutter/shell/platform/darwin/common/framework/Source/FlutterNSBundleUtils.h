// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_DARWIN_COMMON_FRAMEWORK_SOURCE_FLUTTERNSBUNDLEUTILS_H_
#define SHELL_PLATFORM_DARWIN_COMMON_FRAMEWORK_SOURCE_FLUTTERNSBUNDLEUTILS_H_

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Finds a bundle with the named `bundleID` within `searchURL`.
//
// Returns `nil` if the bundle cannot be found or if errors are encountered.
NSBundle* FLTFrameworkBundleInternal(NSString* bundleID, NSURL* searchURL);

// Finds a bundle with the named `bundleID`.
//
// `+[NSBundle bundleWithIdentifier:]` is slow, and can take in the order of
// tens of milliseconds in a minimal flutter app, and closer to 100 milliseconds
// in a medium sized Flutter app on an iPhone 13. It is likely that the slowness
// comes from having to traverse and load all bundles known to the process.
// Using `+[NSBundle allframeworks]` and filtering also suffers from the same
// problem.
//
// This implementation is an optimization to first limit the search space to
// `+[NSBundle privateFrameworksURL]` of the main bundle, which is usually where
// frameworks used by this file are placed. If the desired bundle cannot be
// found here, the implementation falls back to
// `+[NSBundle bundleWithIdentifier:]`.
NSBundle* FLTFrameworkBundleWithIdentifier(NSString* bundleID);

NS_ASSUME_NONNULL_END

#endif  // SHELL_PLATFORM_DARWIN_COMMON_FRAMEWORK_SOURCE_FLUTTERNSBUNDLEUTILS_H_
