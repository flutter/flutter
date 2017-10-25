// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLUTTERDARTPROJECT_H_
#define FLUTTER_FLUTTERDARTPROJECT_H_

#import <Foundation/Foundation.h>

#include "FlutterMacros.h"

FLUTTER_EXPORT
@interface FlutterDartProject : NSObject

- (instancetype)initWithPrecompiledDartBundle:(NSBundle*)bundle NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithFLXArchive:(NSURL*)archiveURL
                          dartMain:(NSURL*)dartMainURL
                          packages:(NSURL*)dartPackages NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithFLXArchiveWithScriptSnapshot:(NSURL*)archiveURL NS_DESIGNATED_INITIALIZER;

- (instancetype)initFromDefaultSourceForConfiguration;

@end

#endif  // FLUTTER_FLUTTERDARTPROJECT_H_
