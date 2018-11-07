// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLUTTER_H_
#define FLUTTER_FLUTTER_H_

/**
 BREAKING CHANGES:

 October 5, 2018:
  - Removed FlutterNavigationController.h/.mm
  - Changed return signature of `FlutterDartHeadlessCodeRunner.run*` from void
 to bool
  - Removed HeadlessPlatformViewIOS
  - Marked FlutterDartHeadlessCodeRunner deprecated

 August 31, 2018: Marked -[FlutterDartProject
 initFromDefaultSourceForConfiguration] and FlutterStandardBigInteger as
 unavailable.

 July 26, 2018: Marked -[FlutterDartProject
 initFromDefaultSourceForConfiguration] deprecated.

 February 28, 2018: Removed "initWithFLXArchive" and
 "initWithFLXArchiveWithScriptSnapshot".

 January 15, 2018: Marked "initWithFLXArchive" and
 "initWithFLXArchiveWithScriptSnapshot" as unavailable following the
 deprecation from December 11, 2017. Scheduled to be removed on February
 19, 2018.

 January 09, 2018: Deprecated "FlutterStandardBigInteger" and its use in
 "FlutterStandardMessageCodec" and "FlutterStandardMethodCodec". Scheduled to
 be marked as unavailable once the deprecation has been available on the
 flutter/flutter alpha branch for four weeks. "FlutterStandardBigInteger" was
 needed because the Dart 1.0 int type had no size limit. With Dart 2.0, the
 int type is a fixed-size, 64-bit signed integer. If you need to communicate
 larger integers, use NSString encoding instead.

 December 11, 2017: Deprecated "initWithFLXArchive" and
 "initWithFLXArchiveWithScriptSnapshot" and scheculed the same to be marked as
 unavailable on January 15, 2018. Instead, "initWithFlutterAssets" and
 "initWithFlutterAssetsWithScriptSnapshot" should be used. The reason for this
 change is that the FLX archive will be deprecated and replaced with a flutter
 assets directory containing the same files as the FLX did.

 November 29, 2017: Added a BREAKING CHANGES section.
 */

#include "FlutterAppDelegate.h"
#include "FlutterBinaryMessenger.h"
#include "FlutterCallbackCache.h"
#include "FlutterChannels.h"
#include "FlutterCodecs.h"
#include "FlutterDartProject.h"
#include "FlutterEngine.h"
#include "FlutterHeadlessDartRunner.h"
#include "FlutterMacros.h"
#include "FlutterPlatformViews.h"
#include "FlutterPlugin.h"
#include "FlutterPluginAppLifeCycleDelegate.h"
#include "FlutterTexture.h"
#include "FlutterViewController.h"

#endif  // FLUTTER_FLUTTER_H_
