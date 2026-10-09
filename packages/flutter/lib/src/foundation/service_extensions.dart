// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'dart:ui';
///
/// @docImport 'binding.dart';
/// @docImport 'debug.dart';
/// @docImport 'platform.dart';
library;

/// Service extension constants for the foundation library.
///
/// These constants will be used when registering service extensions in the
/// framework, and they will also be used by tools and services that call these
/// service extensions.
///
/// The String value for each of these extension names should be accessed by
/// calling the `.name` property on the enum value.
enum FoundationServiceExtensions {
  /// Name of service extension that, when called, will cause the entire
  /// application to redraw.
  ///
  /// See also:
  ///
  /// * [BindingBase.initServiceExtensions], where the service extension is
  ///   registered.
  reassemble,

  /// Name of service extension that, when called, will terminate the Flutter
  /// application.
  ///
  /// See also:
  ///
  /// * [BindingBase.initServiceExtensions], where the service extension is
  ///   registered.
  exit,

  /// Name of service extension that, when called, will get or set the value of
  /// [connectedVmServiceUri].
  ///
  /// See also:
  ///
  /// * [connectedVmServiceUri], which stores the uri for the connected vm service
  ///   protocol.
  /// * [BindingBase.initServiceExtensions], where the service extension is
  ///   registered.
  connectedVmServiceUri,

  /// Name of service extension that, when called, will get or set the value of
  /// [activeDevToolsServerAddress].
  ///
  /// See also:
  ///
  /// * [activeDevToolsServerAddress], which stores the address for the active
  ///   DevTools server used for debugging this application.
  /// * [BindingBase.initServiceExtensions], where the service extension is
  ///   registered.
  activeDevToolsServerAddress,

  /// Name of service extension that, when called, will change the value of
  /// [defaultTargetPlatform], which controls which [TargetPlatform] that the
  /// framework will execute for.
  ///
  /// See also:
  ///
  /// * [debugDefaultTargetPlatformOverride], which is the flag that this service
  ///   extension exposes.
  /// * [BindingBase.initServiceExtensions], where the service extension is
  ///   registered.
  platformOverride,

  /// Name of service extension that, when called, will override the platform
  /// [Brightness].
  ///
  /// See also:
  ///
  /// * [debugBrightnessOverride], which is the flag that this service
  ///   extension exposes.
  /// * [BindingBase.initServiceExtensions], where the service extension is
  ///   registered.
  brightnessOverride,

  /// Name of service extension that, when called, reads or changes the view
  /// metric overrides in [debugViewMetricsOverrides].
  ///
  /// The extension takes these parameters, all optional:
  ///
  ///  * `viewId`: the [FlutterView.viewId] to act on, as a non-negative integer
  ///    string.
  ///  * `overrides`: a JSON-encoded object, in the format
  ///    [DebugViewMetricsOverride.fromJson] accepts.
  ///  * `clearAll`: `'true'` to remove every override.
  ///
  /// Other parameters are ignored.
  ///
  /// A call does the first of these that applies:
  ///
  ///  * If `clearAll` is `'true'`, it removes every override and ignores the
  ///    other parameters.
  ///  * If `overrides` is present, it replaces the override registered for the
  ///    view that `viewId` names, which is then required. An empty object
  ///    (`{}`) removes that view's override.
  ///  * Otherwise, it is a read, and changes nothing.
  ///
  /// A malformed `viewId` or `overrides` fails the call, and nothing changes.
  ///
  /// Every reply has one key, whatever the call was, so that a client can
  /// resynchronize from any reply without remembering which call produced it:
  ///
  ///  * `overrides`: every override installed once the call is done, keyed by
  ///    stringified view id (JSON object keys must be strings), each in the
  ///    format [DebugViewMetricsOverride.toJson] produces. A view without an
  ///    entry has no override.
  ///
  /// A call that changes an override also posts a
  /// `Flutter.ServiceExtensionStateChanged` event whose `value` is that same
  /// map, so that clients other than the caller learn about the change too. A
  /// call that changes nothing posts no event.
  ///
  /// See also:
  ///
  ///  * [DebugViewMetricsOverride], the value this service extension exposes.
  ///  * [debugViewMetricsOverrides], the map this service extension writes to.
  ///  * [BindingBase.initServiceExtensions], where the service extension is
  ///    registered.
  viewMetricsOverride,
}
