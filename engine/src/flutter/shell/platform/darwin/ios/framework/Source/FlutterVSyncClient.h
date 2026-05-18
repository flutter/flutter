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

//------------------------------------------------------------------------------
/// @brief      A manager type that queries display characteristics, such as high refresh rate
///             capabilities.
///
///             Provides static properties to check whether dynamic refresh rates are supported
///             on the device and to get the display's maximum refresh rate (either the hardware
///             maximum or the maximum configured by the user).
///
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
/// @brief      The maximum display refresh rate used for reporting purposes. This is intended to
///             return either the hardware maximum refresh rate or the maximum configured by the
///             user (e.g. via an Info.plist setting or custom configuration). The engine does not
///             care about this for frame scheduling. It is only used by tools for instrumentation.
///             The engine uses the duration field of the link per frame for frame scheduling.
///
/// @attention  Do not use this call in frame scheduling. It is only meant for reporting.
///
/// @return     The maximum refresh rate in frames per second.
///
@property(class, nonatomic, readonly) double displayRefreshRate;

@end

//------------------------------------------------------------------------------
/// @brief      A client that wraps a `CADisplayLink` to deliver synchronized vsync signals.
///
///             Schedules on-demand vsync signals using a request-and-pause cycle to maintain CPU
///             and battery efficiency. Adds additional logic around the wrapped CADisplayLink to
///             ensure consistent frame timings both on display link startup and at steady state.
///
NS_SWIFT_NAME(VSyncClient)
@interface FlutterVSyncClient : NSObject

//------------------------------------------------------------------------------
/// @brief      The current display refresh rate in Hertz, rounded to the nearest integer value.
///
///             This value is calculated during each vsync callback as the inverse of the
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
/// @param      allowPauseAfterVsync         Allow vsync client to pause after receiving a vsync
///                                          signal.
///
@property(nonatomic, assign) BOOL allowPauseAfterVsync;

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

//------------------------------------------------------------------------------
/// @brief      Requests a vsync signal.
///
///             Unpauses the underlying `CADisplayLink` to schedule the next vsync callback.
///             Once the vsync callback executes, the client automatically pauses the display
///             link if `allowPauseAfterVsync` is `YES`.
///
- (void)await;

//------------------------------------------------------------------------------
/// @brief      Pauses the vsync client.
///
///             Pauses the underlying `CADisplayLink` to stop receiving vsync signals immediately.
///
- (void)pause;

//------------------------------------------------------------------------------
/// @brief      Call invalidate before releasing this object to remove from runloops.
///
- (void)invalidate;

//------------------------------------------------------------------------------
/// @brief      Dynamically configures the display link's frame rate ranges.
///
///             Adjusts the target and minimum FPS limits of the display link to support variable
///             refresh rates (e.g. on ProMotion displays) when dynamic rate changes are enabled.
///
/// @param      refreshRate                  The target maximum refresh rate in Hz.
///
- (void)setMaxRefreshRate:(double)refreshRate;

@end

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERVSYNCCLIENT_H_
