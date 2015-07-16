// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/mac/bundle_locations.h"

#include "base/logging.h"
#include "base/mac/foundation_util.h"
#include "base/strings/sys_string_conversions.h"

namespace base {
namespace mac {

// NSBundle isn't threadsafe, all functions in this file must be called on the
// main thread.
static NSBundle* g_override_framework_bundle = nil;
static NSBundle* g_override_outer_bundle = nil;

NSBundle* MainBundle() {
  return [NSBundle mainBundle];
}

FilePath MainBundlePath() {
  NSBundle* bundle = MainBundle();
  return NSStringToFilePath([bundle bundlePath]);
}

NSBundle* OuterBundle() {
  if (g_override_outer_bundle)
    return g_override_outer_bundle;
  return [NSBundle mainBundle];
}

FilePath OuterBundlePath() {
  NSBundle* bundle = OuterBundle();
  return NSStringToFilePath([bundle bundlePath]);
}

NSBundle* FrameworkBundle() {
  if (g_override_framework_bundle)
    return g_override_framework_bundle;
  return [NSBundle mainBundle];
}

FilePath FrameworkBundlePath() {
  NSBundle* bundle = FrameworkBundle();
  return NSStringToFilePath([bundle bundlePath]);
}

static void AssignOverrideBundle(NSBundle* new_bundle,
                                 NSBundle** override_bundle) {
  if (new_bundle != *override_bundle) {
    [*override_bundle release];
    *override_bundle = [new_bundle retain];
  }
}

static void AssignOverridePath(const FilePath& file_path,
                               NSBundle** override_bundle) {
  NSString* path = base::SysUTF8ToNSString(file_path.value());
  NSBundle* new_bundle = [NSBundle bundleWithPath:path];
  DCHECK(new_bundle) << "Failed to load the bundle at " << file_path.value();
  AssignOverrideBundle(new_bundle, override_bundle);
}

void SetOverrideOuterBundle(NSBundle* bundle) {
  AssignOverrideBundle(bundle, &g_override_outer_bundle);
}

void SetOverrideFrameworkBundle(NSBundle* bundle) {
  AssignOverrideBundle(bundle, &g_override_framework_bundle);
}

void SetOverrideOuterBundlePath(const FilePath& file_path) {
  AssignOverridePath(file_path, &g_override_outer_bundle);
}

void SetOverrideFrameworkBundlePath(const FilePath& file_path) {
  AssignOverridePath(file_path, &g_override_framework_bundle);
}

}  // namespace mac
}  // namespace base
