// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Service extension constants for the rendering library.
///
/// These constants will be used when registering service extensions in the
/// framework, and they will also be used by tools and services that call these
/// service extensions.
///
/// The String value for each of these extension names should be accessed by
/// calling the `.name` property on the enum value.
enum RenderingServiceExtensions {
  /// Name of service extension that, when called, will toggle whether the
  /// framework will color invert and horizontally flip images that have been
  /// decoded to a size taking at least [debugImageOverheadAllowance] bytes more
  /// than necessary.
  ///
  /// See also:
  ///
  /// * [debugInvertOversizedImages], which is the flag that this service
  ///   extension exposes.
  /// * [RendererBinding.initServiceExtensions], where the service extension is
  ///   registered.
  invertOversizedImages,

  /// Name of service extension that, when called, will toggle whether each
  /// [RenderBox] will paint a box around its bounds as well as additional boxes
  /// showing construction lines.
  ///
  /// See also:
  ///
  /// * [debugPaintSizeEnabled], which is the flag that this service extension
  ///   exposes.
  /// * [RendererBinding.initServiceExtensions], where the service extension is
  ///   registered.
  debugPaint,

  /// Name of service extension that, when called, will toggle whether each
  /// [RenderBox] will paint a line at each of its baselines.
  ///
  /// See also:
  ///
  /// * [debugPaintBaselinesEnabled], which is the flag that this service
  ///   extension exposes.
  /// * [RendererBinding.initServiceExtensions], where the service extension is
  ///   registered.
  debugPaintBaselinesEnabled,

  /// Name of service extension that, when called, will toggle whether a rotating
  /// set of colors will be overlaid on the device when repainting layers in debug
  /// mode.
  ///
  /// See also:
  ///
  /// * [debugRepaintRainbowEnabled], which is the flag that this service
  ///   extension exposes.
  /// * [RendererBinding.initServiceExtensions], where the service extension is
  ///   registered.
  repaintRainbow,

  /// Name of service extension that, when called, will dump a [String]
  /// representation of the layer tree to console.
  ///
  /// See also:
  ///
  /// * [RendererBinding.initServiceExtensions], where the service extension is
  ///   registered.
  debugDumpLayerTree,

  /// Name of service extension that, when called, will toggle whether all
  /// clipping effects from the layer tree will be ignored.
  ///
  /// See also:
  ///
  /// * [debugDisableClipLayers], which is the flag that this service extension
  ///   exposes.
  /// * [RendererBinding.initServiceExtensions], where the service extension is
  ///   registered.
  debugDisableClipLayers,

  /// Name of service extension that, when called, will toggle whether all
  /// physical modeling effects from the layer tree will be ignored.
  ///
  /// See also:
  ///
  /// * [debugDisablePhysicalShapeLayers], which is the flag that this service
  ///   extension exposes.
  /// * [RendererBinding.initServiceExtensions], where the service extension is
  ///   registered.
  debugDisablePhysicalShapeLayers,

  /// Name of service extension that, when called, will toggle whether all opacity
  /// effects from the layer tree will be ignored.
  ///
  /// See also:
  ///
  /// * [debugDisableOpacityLayers], which is the flag that this service extension
  ///   exposes.
  /// * [RendererBinding.initServiceExtensions], where the service extension is
  ///   registered.
  debugDisableOpacityLayers,

  /// Name of service extension that, when called, will dump a [String]
  /// representation of the render tree to console.
  ///
  /// See also:
  ///
  /// * [RendererBinding.initServiceExtensions], where the service extension is
  ///   registered.
  debugDumpRenderTree,

  /// Name of service extension that, when called, will dump a [String]
  /// representation of the semantics tree (in traversal order) to console.
  ///
  /// See also:
  ///
  /// * [RendererBinding.initServiceExtensions], where the service extension is
  ///   registered.
  debugDumpSemanticsTreeInTraversalOrder,

  /// Name of service extension that, when called, will dump a [String]
  /// representation of the semantics tree (in inverse hit test order) to console.
  ///
  /// See also:
  ///
  /// * [RendererBinding.initServiceExtensions], where the service extension is
  ///   registered.
  debugDumpSemanticsTreeInInverseHitTestOrder,

  /// Name of service extension that, when called, will toggle whether [Timeline]
  /// events are added for every [RenderObject] painted.
  ///
  /// See also:
  ///
  /// * [debugProfilePaintsEnabled], which is the flag that this service extension
  ///   exposes.
  /// * [RendererBinding.initServiceExtensions], where the service extension is
  ///   registered.
  profileRenderObjectPaints,

  /// Name of service extension that, when called, will toggle whether [Timeline]
  /// events are added for every [RenderObject] laid out.
  ///
  /// See also:
  ///
  /// * [debugProfileLayoutsEnabled], which is the flag that this service
  ///   extension exposes.
  /// * [RendererBinding.initServiceExtensions], where the service extension is
  ///   registered.
  profileRenderObjectLayouts,
}
