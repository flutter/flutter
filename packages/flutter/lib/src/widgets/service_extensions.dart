// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Service extension that, when called, will output a string representation of
/// this app's widget tree to console.
///
/// See also:
///
/// * [BindingBase.initServiceExtensions], where the service extension is
///   registered.
const String debugDumpAppExt = 'debugDumpApp';

/// Service extension that, when called, will overlay a performance graph on top
/// of this app.
///
/// See also:
///
/// * [WidgetsApp.showPerformanceOverlayOverride], which is the flag
///   that this service extension exposes.
/// * [BindingBase.initServiceExtensions], where the service extension is
///   registered.
const String showPerformanceOverlayExt = 'showPerformanceOverlay';

/// Service extension that, when called, will return whether the first
/// 'Flutter.Frame' event has been reported on the Extension stream.
///
/// See also:
///
/// * [BindingBase.initServiceExtensions], where the service extension is
///   registered.
const String didSendFirstFrameEventExt = 'didSendFirstFrameEvent';

/// Service extension that, when called, will return whether the first frame
/// has been rasterized and the trace event 'Rasterized first useful frame' has
/// been sent out.
///
/// See also:
///
/// * [BindingBase.initServiceExtensions], where the service extension is
///   registered.
const String didSendFirstFrameRasterizedEventExt =
    'didSendFirstFrameRasterizedEvent';

/// Service extension that, when called, will reassemble the application.
///
/// See also:
///
/// * [BindingBase.initServiceExtensions], where the service extension is
///   registered.
const String fastReassembleExt = 'fastReassemble';

/// Service extension that, when called, will change the value of
/// [debugProfileBuildsEnabled], which adds [Timeline] events for every widget
/// built.
///
/// See also:
///
/// * [debugProfileBuildsEnabled], which is the flag that this service extension
///   exposes.
/// * [BindingBase.initServiceExtensions], where the service extension is
///   registered.
const String profileWidgetBuildsExt = 'profileWidgetBuilds';

/// Service extension that, when called, will change the value of
/// [debugProfileBuildsEnabledUserWidgets], which adds [Timeline] events for
/// every user-created widget built.
///
/// See also:
/// * [debugProfileBuildsEnabledUserWidgets], which is the flag that this
///   service extension exposes.
/// * [BindingBase.initServiceExtensions], where the service extension is
///   registered.
const String profileUserWidgetBuildsExt = 'profileUserWidgetBuilds';

/// Service extension that, when called, will change the value of
/// [WidgetsApp.debugAllowBannerOverride], which controls the visibility of the
/// debug banner for debug mode apps.
///
/// See also:
///
/// * [WidgetsApp.debugAllowBannerOverride], which is the flag that this service
///   extension exposes.
/// * [BindingBase.initServiceExtensions], where the service extension is
///   registered.
const String debugAllowBannerExt = 'debugAllowBanner';
