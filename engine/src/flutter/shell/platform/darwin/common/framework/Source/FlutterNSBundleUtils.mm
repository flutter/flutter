// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <Foundation/Foundation.h>

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"

FLUTTER_ASSERT_ARC

NSBundle* FLTFrameworkBundleInternal(NSString* bundleID, NSURL* searchURL) {
  NSDirectoryEnumerator<NSURL*>* frameworkEnumerator = [NSFileManager.defaultManager
                 enumeratorAtURL:searchURL
      includingPropertiesForKeys:nil
                         options:NSDirectoryEnumerationSkipsSubdirectoryDescendants |
                                 NSDirectoryEnumerationSkipsHiddenFiles
                    // Skip directories where errors are encountered.
                    errorHandler:nil];

  for (NSURL* candidate in frameworkEnumerator) {
    NSBundle* bundle = [NSBundle bundleWithURL:candidate];
    if ([bundle.bundleIdentifier isEqualToString:bundleID]) {
      return bundle;
    }
  }
  return nil;
}

NSBundle* FLTFrameworkBundleWithIdentifier(NSString* bundleID) {
  NSBundle* bundle = FLTFrameworkBundleInternal(bundleID, NSBundle.mainBundle.privateFrameworksURL);
  if (bundle != nil) {
    return bundle;
  }
  // Fallback to slow implementation.
  return [NSBundle bundleWithIdentifier:bundleID];
}
