// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Service extension constants for the widgets library.
///
/// These constants will be used when registering service extensions in the
/// framework, and they will also be used by tools and services that call these
/// service extensions.
///
/// The String value for each of these extension names should be accessed by
/// calling the `.name` property on the enum value.
enum WidgetsServiceExtensions {
  /// Name of service extension that, when called, will output a string
  /// representation of this app's widget tree to console.
  ///
  /// See also:
  ///
  /// * [WidgetsBinding.initServiceExtensions], where the service extension is
  ///   registered.
  debugDumpApp,

  /// Name of service extension that, when called, will output a string
  /// representation of the focus tree to the console.
  ///
  /// See also:
  ///
  /// * [WidgetsBinding.initServiceExtensions], where the service extension is
  ///   registered.
  debugDumpFocusTree,

  /// Name of service extension that, when called, will overlay a performance
  /// graph on top of this app.
  ///
  /// See also:
  ///
  /// * [WidgetsApp.showPerformanceOverlayOverride], which is the flag
  ///   that this service extension exposes.
  /// * [WidgetsBinding.initServiceExtensions], where the service extension is
  ///   registered.
  showPerformanceOverlay,

  /// Name of service extension that, when called, will return whether the first
  /// 'Flutter.Frame' event has been reported on the Extension stream.
  ///
  /// See also:
  ///
  /// * [WidgetsBinding.initServiceExtensions], where the service extension is
  ///   registered.
  didSendFirstFrameEvent,

  /// Name of service extension that, when called, will return whether the first
  /// frame has been rasterized and the trace event 'Rasterized first useful
  /// frame' has been sent out.
  ///
  /// See also:
  ///
  /// * [WidgetsBinding.initServiceExtensions], where the service extension is
  ///   registered.
  didSendFirstFrameRasterizedEvent,

  /// Name of service extension that, when called, will reassemble the
  /// application.
  ///
  /// See also:
  ///
  /// * [WidgetsBinding.initServiceExtensions], where the service extension is
  ///   registered.
  fastReassemble,

  /// Name of service extension that, when called, will change the value of
  /// [debugProfileBuildsEnabled], which adds [Timeline] events for every widget
  /// built.
  ///
  /// See also:
  ///
  /// * [debugProfileBuildsEnabled], which is the flag that this service extension
  ///   exposes.
  /// * [WidgetsBinding.initServiceExtensions], where the service extension is
  ///   registered.
  profileWidgetBuilds,

  /// Name of service extension that, when called, will change the value of
  /// [debugProfileBuildsEnabledUserWidgets], which adds [Timeline] events for
  /// every user-created widget built.
  ///
  /// See also:
  /// * [debugProfileBuildsEnabledUserWidgets], which is the flag that this
  ///   service extension exposes.
  /// * [WidgetsBinding.initServiceExtensions], where the service extension is
  ///   registered.
  profileUserWidgetBuilds,

  /// Name of service extension that, when called, will change the value of
  /// [WidgetsApp.debugAllowBannerOverride], which controls the visibility of the
  /// debug banner for debug mode apps.
  ///
  /// See also:
  ///
  /// * [WidgetsApp.debugAllowBannerOverride], which is the flag that this service
  ///   extension exposes.
  /// * [WidgetsBinding.initServiceExtensions], where the service extension is
  ///   registered.
  debugAllowBanner,
}

/// Service extension constants for the Widget Inspector.
///
/// These constants will be used when registering service extensions in the
/// framework, and they will also be used by tools and services that call these
/// service extensions.
///
/// The String value for each of these extension names should be accessed by
/// calling the `.name` property on the enum value.
enum WidgetInspectorServiceExtensions {
  /// Name of service extension that, when called, will determine whether
  /// [FlutterError] messages will be presented using a structured format.
  ///
  /// See also:
  ///
  /// * [WidgetInspectorService.initServiceExtensions], where the service
  ///   extension is registered.
  structuredErrors,

  /// Name of service extension that, when called, will change the value of
  /// [WidgetsBinding.debugShowWidgetInspectorOverride], which controls whether the
  /// on-device widget inspector is visible.
  ///
  /// See also:
  /// * [WidgetsBinding.debugShowWidgetInspectorOverride], which is the flag that
  ///   this service extension exposes.
  /// * [WidgetInspectorService.initServiceExtensions], where the service
  ///   extension is registered.
  show,

  /// Name of service extension that, when called, determines
  /// whether a callback is invoked for every dirty [Widget] built each frame.
  ///
  /// See also:
  ///
  /// * [debugOnRebuildDirtyWidget], which is the nullable callback that is
  ///   called for every dirty widget built per frame
  /// * [WidgetInspectorService.initServiceExtensions], where the service
  ///   extension is registered.
  trackRebuildDirtyWidgets,

  /// Name of service extension that, when called, returns the mapping of
  /// widget locations to ids.
  ///
  /// This service extension is only supported if
  /// [WidgetInspectorService._widgetCreationTracked] is true.
  ///
  /// See also:
  ///
  /// * [trackRebuildDirtyWidgets], which toggles dispatching events that use
  ///   these ids to efficiently indicate the locations of widgets.
  /// * [WidgetInspectorService.initServiceExtensions], where the service
  ///   extension is registered.
  widgetLocationIdMap,

  /// Name of service extension that, when called, determines whether
  /// [WidgetInspectorService._trackRepaintWidgets], which determines whether
  /// a callback is invoked for every [RenderObject] painted each frame.
  ///
  /// See also:
  ///
  /// * [debugOnProfilePaint], which is the nullable callback that is called for
  ///   every dirty widget built per frame
  /// * [WidgetInspectorService.initServiceExtensions], where the service
  ///   extension is registered.
  trackRepaintWidgets,

  /// Name of service extension that, when called, will clear all
  /// [WidgetInspectorService] object references in all groups.
  ///
  /// See also:
  ///
  /// * [WidgetInspectorService.disposeAllGroups], the method that this service
  ///   extension calls.
  /// * [WidgetInspectorService.initServiceExtensions], where the service
  ///   extension is registered.
  disposeAllGroups,

  /// Name of service extension that, when called, will clear all
  /// [WidgetInspectorService] object references in a group.
  ///
  /// See also:
  ///
  /// * [WidgetInspectorService.disposeGroup], the method that this service
  ///   extension calls.
  /// * [WidgetInspectorService.initServiceExtensions], where the service
  ///   extension is registered.
  disposeGroup,

  /// Name of service extension that, when called, returns whether it is
  /// appropriate to display the Widget tree in the inspector, which is only
  /// true after the application has rendered its first frame.
  ///
  /// See also:
  ///
  /// * [WidgetInspectorService.isWidgetTreeReady], the method that this service
  ///   extension calls.
  /// * [WidgetsBinding.debugDidSendFirstFrameEvent], which stores the
  ///   value of whether the first frame has been rendered.
  /// * [WidgetInspectorService.initServiceExtensions], where the service
  ///   extension is registered.
  isWidgetTreeReady,

  /// Name of service extension that, when called, will remove the object with
  /// the specified `id` from the specified object group.
  ///
  /// See also:
  ///
  /// * [WidgetInspectorService.disposeId], the method that this service
  ///   extension calls.
  /// * [WidgetInspectorService.initServiceExtensions], where the service
  ///   extension is registered.
  disposeId,

  /// Name of service extension that, when called, will set the list of
  /// directories that should be considered part of the local project for the
  /// Widget inspector summary tree.
  ///
  /// See also:
  ///
  /// * [WidgetInspectorService.addPubRootDirectories], which should be used in
  ///   place of this method to add directories.
  /// * [WidgetInspectorService.removePubRootDirectories], which should be used
  ///   in place of this method to remove directories.
  /// * [WidgetInspectorService.initServiceExtensions], where the service
  ///   extension is registered.
  @Deprecated(
    'Use addPubRootDirectories instead. '
    'This feature was deprecated after v3.18.0-2.0.pre.',
  )
  setPubRootDirectories,

  /// Name of service extension that, when called, will add a list of
  /// directories that should be considered part of the local project for the
  /// Widget inspector summary tree.
  ///
  /// See also:
  ///
  /// * [WidgetInspectorService.addPubRootDirectories], the method that this
  ///   service extension calls.
  /// * [WidgetInspectorService.removePubRootDirectories], which should be used
  ///   to remove directories.
  /// * [WidgetInspectorService.pubRootDirectories], which should be used
  ///   to return the active list of directories.
  /// * [WidgetInspectorService.initServiceExtensions], where the service
  ///   extension is registered.
  addPubRootDirectories,

  /// Name of service extension that, when called, will remove a list of
  /// directories that should no longer be considered part of the local project
  /// for the Widget inspector summary tree.
  ///
  /// See also:
  ///
  /// * [WidgetInspectorService.removePubRootDirectories], the method that this
  ///   service extension calls.
  /// * [WidgetInspectorService.addPubRootDirectories], which should be used
  ///   to add directories.
  /// * [WidgetInspectorService.pubRootDirectories], which should be used
  ///   to return the active list of directories.
  /// * [WidgetInspectorService.initServiceExtensions], where the service
  ///   extension is registered.
  removePubRootDirectories,

  /// Name of service extension that, when called, will return the list of
  /// directories that are considered part of the local project
  /// for the Widget inspector summary tree.
  ///
  /// See also:
  ///
  /// * [WidgetInspectorService.pubRootDirectories], the method that this
  ///   service extension calls.
  /// * [WidgetInspectorService.addPubRootDirectories], which should be used
  ///   to add directories.
  /// * [WidgetInspectorService.removePubRootDirectories], which should be used
  ///   to remove directories.
  /// * [WidgetInspectorService.initServiceExtensions], where the service
  ///   extension is registered.
  getPubRootDirectories,

  /// Name of service extension that, when called, will set the
  /// [WidgetInspector] selection to the object matching the specified id and
  /// will return whether the selection was changed.
  ///
  /// See also:
  ///
  /// * [WidgetInspectorService.setSelectionById], the method that this service
  ///   extension calls.
  /// * [WidgetInspectorService.initServiceExtensions], where the service
  ///   extension is registered.
  setSelectionById,

  /// Name of service extension that, when called, will retrieve the chain of
  /// [DiagnosticsNode] instances form the root of the tree to the [Element] or
  /// [RenderObject] matching the specified id, passed as an argument.
  ///
  /// See also:
  ///
  /// * [WidgetInspectorService.getParentChain], which returns a json encoded
  ///   String representation of this data.
  /// * [WidgetInspectorService.initServiceExtensions], where the service
  ///   extension is registered.
  getParentChain,

  /// Name of service extension that, when called, will return the properties
  /// for the [DiagnosticsNode] object matching the specified id, passed as an
  /// argument.
  ///
  /// See also:
  ///
  /// * [WidgetInspectorService.getProperties], which returns a json encoded
  ///   String representation of this data.
  /// * [WidgetInspectorService.initServiceExtensions], where the service
  ///   extension is registered.
  getProperties,

  /// Name of service extension that, when called, will return the children
  /// for the [DiagnosticsNode] object matching the specified id, passed as an
  /// argument.
  ///
  /// See also:
  ///
  /// * [WidgetInspectorService.getChildren], which returns a json encoded
  ///   String representation of this data.
  /// * [WidgetInspectorService.initServiceExtensions], where the service
  ///   extension is registered.
  getChildren,

  /// Name of service extension that, when called, will return the children
  /// created by user code for the [DiagnosticsNode] object matching the
  /// specified id, passed as an argument.
  ///
  /// See also:
  ///
  /// * [WidgetInspectorService.getChildrenSummaryTree], which returns a json
  ///   encoded String representation of this data.
  /// * [WidgetInspectorService.initServiceExtensions], where the service
  ///   extension is registered.
  getChildrenSummaryTree,

  /// Name of service extension that, when called, will return all children and
  /// their properties for the [DiagnosticsNode] object matching the specified
  /// id, passed as an argument.
  ///
  /// See also:
  ///
  /// * [WidgetInspectorService.getChildrenDetailsSubtree], which returns a json
  ///   encoded String representation of this data.
  /// * [WidgetInspectorService.initServiceExtensions], where the service
  ///   extension is registered.
  getChildrenDetailsSubtree,

  /// Name of service extension that, when called, will return the
  /// [DiagnosticsNode] data for the root [Element].
  ///
  /// See also:
  ///
  /// * [WidgetInspectorService.getRootWidget], which returns a json encoded
  ///   String representation of this data.
  /// * [WidgetInspectorService.initServiceExtensions], where the service
  ///   extension is registered.
  getRootWidget,

  /// Name of service extension that, when called, will return the
  /// [DiagnosticsNode] data for the root [Element] of the widget tree.
  ///
  /// If the parameter `isSummaryTree` is true, the tree will only include
  /// [Element]s that were created by user code.
  ///
  /// If the parameter `withPreviews` is true, text previews will be included
  /// for [Element]s with a corresponding [RenderObject] of type
  /// [RenderParagraph].
  ///
  /// See also:
  ///
  /// * [WidgetInspectorService.initServiceExtensions], where the service
  ///   extension is registered.
  getRootWidgetTree,

  /// Name of service extension that, when called, will return the
  /// [DiagnosticsNode] data for the root [Element] of the summary tree, which
  /// only includes [Element]s that were created by user code.
  ///
  /// See also:
  ///
  /// * [WidgetInspectorService.getRootWidgetSummaryTree], which returns a json
  ///   encoded String representation of this data.
  /// * [WidgetInspectorService.initServiceExtensions], where the service
  ///   extension is registered.
  getRootWidgetSummaryTree,

  /// Name of service extension that, when called, will return the
  /// [DiagnosticsNode] data for the root [Element] of the summary tree with
  /// text previews included.
  ///
  /// The summary tree only includes [Element]s that were created by user code.
  /// Text previews will only be available for [Element]s with a corresponding
  /// [RenderObject] of type [RenderParagraph].
  ///
  /// See also:
  ///
  /// * [WidgetInspectorService.initServiceExtensions], where the service
  ///   extension is registered.
  getRootWidgetSummaryTreeWithPreviews,

  /// Name of service extension that, when called, will return the details
  /// subtree, which includes properties, rooted at the [DiagnosticsNode] object
  /// matching the specified id and the having a size matching the specified
  /// subtree depth, both passed as arguments.
  ///
  /// See also:
  ///
  /// * [WidgetInspectorService.getDetailsSubtree], the method that this service
  ///   extension calls.
  /// * [WidgetInspectorService.getDetailsSubtree], which returns a json
  ///   encoded String representation of this data.
  /// * [WidgetInspectorService.initServiceExtensions], where the service
  ///   extension is registered.
  getDetailsSubtree,

  /// Name of service extension that, when called, will return the
  /// [DiagnosticsNode] data for the currently selected [Element].
  ///
  /// See also:
  ///
  /// * [WidgetInspectorService.getSelectedWidget], which returns a json
  ///   encoded String representation of this data.
  /// * [WidgetInspectorService.initServiceExtensions], where the service
  ///   extension is registered.
  getSelectedWidget,

  /// Name of service extension that, when called, will return the
  /// [DiagnosticsNode] data for the currently selected [Element] in the summary
  /// tree, which only includes [Element]s created in user code.
  ///
  /// If the selected [Element] does not exist in the summary tree, the first
  /// ancestor in the summary tree for the currently selected [Element] will be
  /// returned.
  ///
  /// See also:
  ///
  /// * [WidgetInspectorService.getSelectedSummaryWidget], which returns a json
  ///   encoded String representation of this data.
  /// * [WidgetInspectorService.initServiceExtensions], where the service
  ///   extension is registered.
  getSelectedSummaryWidget,

  /// Name of service extension that, when called, will return whether [Widget]
  /// creation locations are available.
  ///
  /// See also:
  ///
  /// * [WidgetInspectorService.isWidgetCreationTracked], the method that this
  ///   service extension calls.
  /// * [WidgetInspectorService.initServiceExtensions], where the service
  ///   extension is registered.
  isWidgetCreationTracked,

  /// Name of service extension that, when called, will return a base64 encoded
  /// image of the [RenderObject] or [Element] matching the specified 'id`,
  /// passed as an argument, and sized at the specified 'width' and 'height'
  /// values, also passed as arguments.
  ///
  /// See also:
  ///
  /// * [WidgetInspectorService.screenshot], the method that this service
  ///   extension calls.
  /// * [WidgetInspectorService.initServiceExtensions], where the service
  ///   extension is registered.
  screenshot,

  /// Name of service extension that, when called, will return the
  /// [DiagnosticsNode] data for the currently selected [Element] and will
  /// include information about the [Element]'s layout properties.
  ///
  /// See also:
  ///
  /// * [WidgetInspectorService.initServiceExtensions], where the service
  ///   extension is registered.
  getLayoutExplorerNode,

  /// Name of service extension that, when called, will set the [FlexFit] value
  /// for the [FlexParentData] of the [RenderObject] matching the specified
  /// `id`, passed as an argument.
  ///
  /// See also:
  ///
  /// * [WidgetInspectorService.initServiceExtensions], where the service
  ///   extension is registered.
  setFlexFit,

  /// Name of service extension that, when called, will set the flex value
  /// for the [FlexParentData] of the [RenderObject] matching the specified
  /// `id`, passed as an argument.
  ///
  /// See also:
  ///
  /// * [WidgetInspectorService.initServiceExtensions], where the service
  ///   extension is registered.
  setFlexFactor,

  /// Name of service extension that, when called, will set the
  /// [MainAxisAlignment] and [CrossAxisAlignment] values for the [RenderFlex]
  /// matching the specified `id`, passed as an argument.
  ///
  /// The [MainAxisAlignment] and [CrossAxisAlignment] values will be passed as
  /// arguments `mainAxisAlignment` and `crossAxisAlignment`, respectively.
  ///
  /// See also:
  ///
  /// * [WidgetInspectorService.initServiceExtensions], where the service
  ///   extension is registered.
  setFlexProperties,
}
