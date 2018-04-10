// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/framework/Source/FlutterDartSource.h"

@implementation FlutterDartSource

@synthesize dartMain = _dartMain;
@synthesize packages = _packages;
@synthesize flutterAssets = _flutterAssets;
@synthesize assetsDirContainsScriptSnapshot = _assetsDirContainsScriptSnapshot;

#pragma mark - Convenience Initializers

- (instancetype)init {
  return [self initWithDartMain:nil packages:nil flutterAssets:nil];
}

#pragma mark - Designated Initializers

- (instancetype)initWithDartMain:(NSURL*)dartMain
                        packages:(NSURL*)packages
                   flutterAssets:(NSURL*)flutterAssets {
  self = [super init];

  if (self) {
    _dartMain = [dartMain copy];
    _packages = [packages copy];
    _flutterAssets = [flutterAssets copy];

    NSFileManager* fileManager = [NSFileManager defaultManager];

    const BOOL dartMainExists = [fileManager fileExistsAtPath:dartMain.absoluteURL.path];
    const BOOL packagesExists = [fileManager fileExistsAtPath:packages.absoluteURL.path];

    if (!dartMainExists || !packagesExists) {
      // We cannot actually verify this without opening up the directory. This is
      // just an assumption.
      _assetsDirContainsScriptSnapshot = YES;
    }
  }

  return self;
}

- (instancetype)initWithFlutterAssetsWithScriptSnapshot:(NSURL*)flutterAssets {
  self = [super init];

  if (self) {
    _flutterAssets = [flutterAssets copy];
    _assetsDirContainsScriptSnapshot = YES;
  }

  return self;
}

static BOOL CheckDartProjectURL(NSMutableString* log, NSURL* url, NSString* logLabel) {
  if (url == nil) {
    [log appendFormat:@"The %@ was not specified.\n", logLabel];
    return false;
  }

  if (!url.isFileURL) {
    [log appendFormat:@"The %@ must be a file URL.\n", logLabel];
    return false;
  }

  if (![[NSFileManager defaultManager] fileExistsAtPath:url.absoluteURL.path]) {
    [log appendFormat:@"No file found at '%@' when looking for the %@.\n", url, logLabel];
    return false;
  }

  return true;
}

- (void)validate:(ValidationResult)result {
  NSMutableString* log = [[[NSMutableString alloc] init] autorelease];

  BOOL isValid = YES;

  isValid &= CheckDartProjectURL(log, _flutterAssets, @"Flutter assets");

  if (!_assetsDirContainsScriptSnapshot) {
    isValid &= CheckDartProjectURL(log, _dartMain, @"Dart main");
    isValid &= CheckDartProjectURL(log, _packages, @"Dart packages");
  }

  result(isValid, log);
}

- (void)dealloc {
  [_dartMain release];
  [_packages release];
  [_flutterAssets release];

  [super dealloc];
}

@end
