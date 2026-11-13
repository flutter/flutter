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

  /// Name of service extension that, when called, sets the
  /// [DebugViewMetricsOverride.platformBrightness] of
  /// [debugAllViewsMetricsOverride], and reports the platform brightness.
  ///
  /// Tools should call [viewMetricsOverride] with a `viewId` of `all` instead,
  /// which reads and writes every metric of that override. This extension
  /// remains for the tools that already call it.
  ///
  /// A `value` of `'Brightness.light'` or `'Brightness.dark'` overrides the
  /// brightness of every view, and any other `value` stops overriding it. A
  /// view's own entry in [debugViewMetricsOverrides] outranks it. The other
  /// metrics of [debugAllViewsMetricsOverride] stay as they are. A call without
  /// a `value` changes nothing.
  ///
  /// The reply's `value` is the brightness [BindingBase.platformDispatcher]
  /// reports once the call is done, such as `'Brightness.dark'`. A change
  /// shows from the next frame on, and the reply does not wait for that frame.
  ///
  /// A call that changes the brightness of [debugAllViewsMetricsOverride]
  /// posts a `Flutter.ServiceExtensionStateChanged` event whose `value` is the
  /// reply's `value`, and the event of [viewMetricsOverride]. That `value` can
  /// be the same as the last one, for example when the new override matches
  /// the platform brightness. A call that changes nothing posts no event.
  ///
  /// See also:
  ///
  /// * [debugAllViewsMetricsOverride], the override whose brightness this
  ///   service extension exposes.
  /// * [BindingBase.initServiceExtensions], where the service extension is
  ///   registered.
  brightnessOverride,

  /// Name of service extension that, when called, reads or changes the view
  /// metric overrides in [debugViewMetricsOverrides] and
  /// [debugAllViewsMetricsOverride].
  ///
  /// The extension takes these parameters, all optional:
  ///
  ///  * `viewId`: the [FlutterView.viewId] to act on, as a non-negative integer
  ///    string, or `all` to act on [debugAllViewsMetricsOverride], which every
  ///    view applies beneath its own override.
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
  ///  * If `overrides` is present, it replaces the override that `viewId`
  ///    names, which is then required. An empty object (`{}`) removes that
  ///    override.
  ///  * Otherwise, it is a read, and changes nothing.
  ///
  /// A malformed `viewId` or `overrides` fails the call, and nothing changes.
  ///
  /// A change takes effect before the call returns: the framework is told to
  /// re-read the metrics it altered, as it would be if the platform had
  /// changed them, so the next frame reflects it. See
  /// [DebugViewMetricsOverride] for what is applied, and where.
  ///
  /// Every reply has one key, whatever the call was, so that a client can
  /// resynchronize from any reply without remembering which call produced it:
  ///
  ///  * `overrides`: every override installed once the call is done, each in
  ///    the format [DebugViewMetricsOverride.toJson] produces. A view's entry
  ///    is keyed by its stringified view id, because JSON object keys must be
  ///    strings. [debugAllViewsMetricsOverride] is keyed by `all`. A view
  ///    without an entry has no override of its own.
  ///
  /// A call that changes an override also posts a
  /// `Flutter.ServiceExtensionStateChanged` event whose `value` is that same
  /// map, so that clients other than the caller learn about the change too. A
  /// call that changes nothing posts no event.
  ///
  /// A call that changes the brightness of [debugAllViewsMetricsOverride] also
  /// posts the event of [brightnessOverride].
  ///
  /// See also:
  ///
  ///  * [DebugViewMetricsOverride], the value this service extension exposes.
  ///  * [debugViewMetricsOverrides], the map this service extension writes to.
  ///  * [debugAllViewsMetricsOverride], the override this service extension
  ///    writes to for a `viewId` of `all`.
  ///  * [BindingBase.initServiceExtensions], where the service extension is
  ///    registered.
  viewMetricsOverride,
}
