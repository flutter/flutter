// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERVSYNCCLIENT_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERVSYNCCLIENT_H_

#include <QuartzCore/CADisplayLink.h>

//------------------------------------------------------------------------------
/// @brief      Info.plist key enabling the full range of ProMotion refresh rates for CADisplayLink
///             callbacks and CAAnimation animations in the app.
///
/// @see
/// https://developer.apple.com/documentation/quartzcore/optimizing_promotion_refresh_rates_for_iphone_13_pro_and_ipad_pro#3885321
///
extern NSString* const kCADisableMinimumFrameDurationOnPhoneKey;

@class FlutterFMLTaskRunner;

NS_SWIFT_NAME(DisplayLinkManager)
@interface FlutterDisplayLinkManager : NSObject

//------------------------------------------------------------------------------
/// @brief      Whether the max refresh rate on iPhone ProMotion devices are enabled. This reflects
///             the value of `CADisableMinimumFrameDurationOnPhone` in the info.plist file. On iPads
///             that support ProMotion, the max refresh rate is always enabled.
///
/// @return     YES if the max refresh rate on ProMotion devices is enabled.
///
@property(class, nonatomic, readonly) BOOL maxRefreshRateEnabledOnIPhone;

//------------------------------------------------------------------------------
/// @brief      The display refresh rate used for reporting purposes. The engine does not care
///             about this for frame scheduling. It is only used by tools for instrumentation. The
///             engine uses the duration field of the link per frame for frame scheduling.
///
/// @attention  Do not use the this call in frame scheduling. It is only meant for reporting.
///
/// @return     The refresh rate in frames per second.
///
@property(class, nonatomic, readonly) double displayRefreshRate;

@end

NS_SWIFT_NAME(VSyncClient)
@interface FlutterVSyncClient : NSObject

//------------------------------------------------------------------------------
/// @brief      The current display refresh rate in Hertz, rounded to the nearest integer value. The
///             value. This value is calculated during each vsync callback as the inverse of the
///             frame duration (the time between the current frame and the target next frame). The
///             resulting frequency is rounded to the nearest whole number to smooth out minor
///             hardware timestamp variations.
///
@property(nonatomic, assign, readonly) double refreshRate;

//------------------------------------------------------------------------------
/// @brief      Default value is YES. Vsync client will pause vsync callback after receiving
///             a vsync signal. Setting this property to NO can avoid this and vsync client
///             will trigger vsync callback continuously.
///
///
/// @param allowPauseAfterVsync Allow vsync client to pause after receiving a vsync signal.
///
@property(nonatomic, assign) BOOL allowPauseAfterVsync;

//------------------------------------------------------------------------------
/// @brief      Initializes the vsync client. Refresh rate will default to the system settings.
///
/// @param      taskRunner The task runner to use for posting tasks.
/// @param      callback   The callback to invoke when a vsync signal is received.
///
- (instancetype)initWithTaskRunner:(FlutterFMLTaskRunner*)taskRunner
                          callback:(void (^)(CFTimeInterval startTime,
                                             CFTimeInterval targetTime))callback;

//------------------------------------------------------------------------------
/// @brief      Initializes the vsync client.
///
/// @param      taskRunner                   The task runner to use for posting tasks.
/// @param      isVariableRefreshRateEnabled Whether variable refresh rate should be enabled.
/// @param      maxRefreshRate               The maximum refresh rate to configure the display link
///                                          with.
/// @param      callback                     The callback to invoke when a vsync signal is received.
///
- (instancetype)initWithTaskRunner:(FlutterFMLTaskRunner*)taskRunner
      isVariableRefreshRateEnabled:(BOOL)isVariableRefreshRateEnabled
                    maxRefreshRate:(double)maxRefreshRate
                          callback:(void (^)(CFTimeInterval startTime,
                                             CFTimeInterval targetTime))callback;

- (void)await;

- (void)pause;

//------------------------------------------------------------------------------
/// @brief      Call invalidate before releasing this object to remove from runloops.
///
- (void)invalidate;

- (void)setMaxRefreshRate:(double)refreshRate;

@end

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERVSYNCCLIENT_H_
