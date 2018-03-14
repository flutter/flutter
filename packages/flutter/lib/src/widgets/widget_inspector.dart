// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'dart:ui' as ui show window, Picture, SceneBuilder, PictureRecorder;
import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'basic.dart';
import 'binding.dart';
import 'framework.dart';
import 'gesture_detector.dart';

/// Signature for the builder callback used by
/// [WidgetInspector.selectButtonBuilder].
typedef Widget InspectorSelectButtonBuilder(BuildContext context, VoidCallback onPressed);

/// A class describing a step along a path through a tree of [DiagnosticsNode]
/// objects.
///
/// This class is used to bundle all data required to display the tree with just
/// the nodes along a path expanded into a single JSON payload.
class _DiagnosticsPathNode {
  /// Creates a full description of a step in a path through a tree of
  /// [DiagnosticsNode] objects.
  ///
  /// The [node] and [child] arguments must not be null.
  _DiagnosticsPathNode({ @required this.node, @required this.children, this.childIndex }) : assert(node != null), assert(children != null);

  /// Node at the point in the path this [_DiagnosticsPathNode] is describing.
  final DiagnosticsNode node;

  /// Children of the [node] being described.
  ///
  /// This value is cached instead of relying on `node.getChildren()` as that
  /// method call might create new [DiagnosticsNode] objects for each child
  /// and we would prefer to use the identical [DiagnosticsNode] for each time
  /// a node exists in the path.
  final List<DiagnosticsNode> children;

  /// Index of the child that the path continues on.
  ///
  /// Equal to `null` if the path does not continue.
  final int childIndex;
}

List<_DiagnosticsPathNode> _followDiagnosticableChain(List<Diagnosticable> chain, {
  String name,
  DiagnosticsTreeStyle style,
}) {
  final List<_DiagnosticsPathNode> path = <_DiagnosticsPathNode>[];
  if (chain.isEmpty)
    return path;
  DiagnosticsNode diagnostic = chain.first.toDiagnosticsNode(name: name, style: style);
  for (int i = 1; i < chain.length; i += 1) {
    final Diagnosticable target = chain[i];
    bool foundMatch = false;
    final List<DiagnosticsNode> children = diagnostic.getChildren();
    for (int j = 0; j < children.length; j += 1) {
      final DiagnosticsNode child = children[j];
      if (child.value == target) {
        foundMatch = true;
        path.add(new _DiagnosticsPathNode(
          node: diagnostic,
          children: children,
          childIndex: j,
        ));
        diagnostic = child;
        break;
      }
    }
    assert(foundMatch);
  }
  path.add(new _DiagnosticsPathNode(node: diagnostic, children: diagnostic.getChildren()));
  return path;
}

/// Signature for the selection change callback used by
/// [WidgetInspectorService.selectionChangedCallback].
typedef void InspectorSelectionChangedCallback();

/// Structure to help reference count Dart objects referenced by a GUI tool
/// using [WidgetInspectorService].
class _InspectorReferenceData {
  _InspectorReferenceData(this.object);

  final Object object;
  int count = 1;
}

/// Service used by GUI tools to interact with the [WidgetInspector].
///
/// Calls to this object are typically made from GUI tools such as the [Flutter
/// IntelliJ Plugin](https://github.com/flutter/flutter-intellij/blob/master/README.md)
/// using the [Dart VM Service protocol](https://github.com/dart-lang/sdk/blob/master/runtime/vm/service/service.md).
/// This class uses its own object id and manages object lifecycles itself
/// instead of depending on the [object ids](https://github.com/dart-lang/sdk/blob/master/runtime/vm/service/service.md#getobject)
/// specified by the VM Service Protocol because the VM Service Protocol ids
/// expire unpredictably. Object references are tracked in groups so that tools
/// that clients can use dereference all objects in a group with a single
/// operation making it easier to avoid memory leaks.
///
/// All methods in this class are appropriate to invoke from debugging tools
/// using the Observatory service protocol to evaluate Dart expressions of the
/// form `WidgetInspectorService.instance.methodName(arg1, arg2, ...)`. If you
/// make changes to any instance method of this class you need to verify that
/// the [Flutter IntelliJ Plugin](https://github.com/flutter/flutter-intellij/blob/master/README.md)
/// widget inspector support still works with the changes.
///
/// All methods returning String values return JSON.
class WidgetInspectorService {
  WidgetInspectorService._();

  /// The current [WidgetInspectorService].
  static WidgetInspectorService get instance => _instance;
  static final WidgetInspectorService _instance = new WidgetInspectorService._();

  /// Ground truth tracking what object(s) are currently selected used by both
  /// GUI tools such as the Flutter IntelliJ Plugin and the [WidgetInspector]
  /// displayed on the device.
  final InspectorSelection selection = new InspectorSelection();

  /// Callback typically registered by the [WidgetInspector] to receive
  /// notifications when [selection] changes.
  ///
  /// The Flutter IntelliJ Plugin does not need to listen for this event as it
  /// instead listens for `dart:developer` `inspect` events which also trigger
  /// when the inspection target changes on device.
  InspectorSelectionChangedCallback selectionChangedCallback;

  /// The Observatory protocol does not keep alive object references so this
  /// class needs to manually manage groups of objects that should be kept
  /// alive.
  final Map<String, Set<_InspectorReferenceData>> _groups = <String, Set<_InspectorReferenceData>>{};
  final Map<String, _InspectorReferenceData> _idToReferenceData = <String, _InspectorReferenceData>{};
  final Map<Object, String> _objectToId = new Map<Object, String>.identity();
  int _nextId = 0;

  List<String> _pubRootDirectories;

  /// Clear all InspectorService object references.
  ///
  /// Use this method only for testing to ensure that object references from one
  /// test case do not impact other test cases.
  void disposeAllGroups() {
    _groups.clear();
    _idToReferenceData.clear();
    _objectToId.clear();
    _nextId = 0;
  }

  /// Free all references to objects in a group.
  ///
  /// Objects and their associated ids in the group may be kept alive by
  /// references from a different group.
  void disposeGroup(String name) {
    final Set<_InspectorReferenceData> references = _groups.remove(name);
    if (references == null)
      return;
    references.forEach(_decrementReferenceCount);
  }

  void _decrementReferenceCount(_InspectorReferenceData reference) {
    reference.count -= 1;
    assert(reference.count >= 0);
    if (reference.count == 0) {
      final String id = _objectToId.remove(reference.object);
      assert(id != null);
      _idToReferenceData.remove(id);
    }
  }

  /// Returns a unique id for [object] that will remain live at least until
  /// [disposeGroup] is called on [groupName] or [dispose] is called on the id
  /// returned by this method.
  String toId(Object object, String groupName) {
    if (object == null)
      return null;

    final Set<_InspectorReferenceData> group = _groups.putIfAbsent(groupName, () => new Set<_InspectorReferenceData>.identity());
    String id = _objectToId[object];
    _InspectorReferenceData referenceData;
    if (id == null) {
      id = 'inspector-$_nextId';
      _nextId += 1;
      _objectToId[object] = id;
      referenceData = new _InspectorReferenceData(object);
      _idToReferenceData[id] = referenceData;
      group.add(referenceData);
    } else {
      referenceData = _idToReferenceData[id];
      if (group.add(referenceData))
        referenceData.count += 1;
    }
    return id;
  }

  /// Returns whether the application has rendered its first frame and it is
  /// appropriate to display the Widget tree in the inspector.
  bool isWidgetTreeReady([String groupName]) {
    return WidgetsBinding.instance != null &&
           WidgetsBinding.instance.debugDidSendFirstFrameEvent;
  }

  /// Returns the Dart object associated with a reference id.
  ///
  /// The `groupName` parameter is not required by is added to regularize the
  /// API surface of the methods in this class called from the Flutter IntelliJ
  /// Plugin.
  Object toObject(String id, [String groupName]) {
    if (id == null)
      return null;

    final _InspectorReferenceData data = _idToReferenceData[id];
    if (data == null) {
      throw new FlutterError('Id does not exist.');
    }
    return data.object;
  }

  /// Returns the object to introspect to determine the source location of an
  /// object's class.
  ///
  /// The Dart object for the id is returned for all cases but [Element] objects
  /// where the [Widget] configuring the [Element] is returned instead as the
  /// class of the [Widget] is more relevant than the class of the [Element].
  ///
  /// The `groupName` parameter is not required by is added to regularize the
  /// API surface of methods called from the Flutter IntelliJ Plugin.
  Object toObjectForSourceLocation(String id, [String groupName]) {
    final Object object = toObject(id);
    if (object is Element) {
      return object.widget;
    }
    return object;
  }

  /// Remove the object with the specified `id` from the specified object
  /// group.
  ///
  /// If the object exists in other groups it will remain alive and the object
  /// id will remain valid.
  void disposeId(String id, String groupName) {
    if (id == null)
      return;

    final _InspectorReferenceData referenceData = _idToReferenceData[id];
    if (referenceData == null)
      throw new FlutterError('Id does not exist');
    if (_groups[groupName]?.remove(referenceData) != true)
      throw new FlutterError('Id is not in group');
    _decrementReferenceCount(referenceData);
  }

  /// Set the list of directories that should be considered part of the local
  /// project.
  ///
  /// The local project directories are used to distinguish widgets created by
  /// the local project over widgets created from inside the framework.
  void setPubRootDirectories(List<Object> pubRootDirectories) {
    _pubRootDirectories = pubRootDirectories.map<String>(
      (Object directory) => Uri.parse(directory).path,
    ).toList();
  }

  /// Set the [WidgetInspector] selection to the object matching the specified
  /// id if the object is valid object to set as the inspector selection.
  ///
  /// Returns `true` if the selection was changed.
  ///
  /// The `groupName` parameter is not required by is added to regularize the
  /// API surface of methods called from the Flutter IntelliJ Plugin.
  bool setSelectionById(String id, [String groupName]) {
    return setSelection(toObject(id), groupName);
  }

  /// Set the [WidgetInspector] selection to the specified `object` if it is
  /// a valid object to set as the inspector selection.
  ///
  /// Returns `true` if the selection was changed.
  ///
  /// The `groupName` parameter is not needed but is specified to regularize the
  /// API surface of methods called from the Flutter IntelliJ Plugin.
  bool setSelection(Object object, [String groupName]) {
    if (object is Element || object is RenderObject) {
      if (object is Element) {
        if (object == selection.currentElement) {
          return false;
        }
        selection.currentElement = object;
      } else {
        if (object == selection.current) {
          return false;
        }
        selection.current = object;
      }
      if (selectionChangedCallback != null) {
        if (WidgetsBinding.instance.schedulerPhase == SchedulerPhase.idle) {
          selectionChangedCallback();
        } else {
          // It isn't safe to trigger the selection change callback if we are in
          // the middle of rendering the frame.
          SchedulerBinding.instance.scheduleTask(
            selectionChangedCallback,
            Priority.touch,
          );
        }
      }
      return true;
    }
    return false;
  }

  /// Returns JSON representing the chain of [DiagnosticsNode] instances from
  /// root of thee tree to the [Element] or [RenderObject] matching `id`.
  ///
  /// The JSON contains all information required to display a tree view with
  /// all nodes other than nodes along the path collapsed.
  String getParentChain(String id, String groupName) {
    final Object value = toObject(id);
    List<_DiagnosticsPathNode> path;
    if (value is RenderObject)
      path = _getRenderObjectParentChain(value, groupName);
    else if (value is Element)
      path = _getElementParentChain(value, groupName);
    else
      throw new FlutterError('Cannot get parent chain for node of type ${value.runtimeType}');

    return json.encode(path.map((_DiagnosticsPathNode node) => _pathNodeToJson(node, groupName)).toList());
  }

  Map<String, Object> _pathNodeToJson(_DiagnosticsPathNode pathNode, String groupName) {
    if (pathNode == null)
      return null;
    return <String, Object>{
      'node': _nodeToJson(pathNode.node, groupName),
      'children': _nodesToJson(pathNode.children, groupName),
      'childIndex': pathNode.childIndex,
    };
  }

  List<_DiagnosticsPathNode> _getElementParentChain(Element element, String groupName) {
    return _followDiagnosticableChain(element?.debugGetDiagnosticChain()?.reversed?.toList()) ?? const <_DiagnosticsPathNode>[];
  }

  List<_DiagnosticsPathNode> _getRenderObjectParentChain(RenderObject renderObject, String groupName) {
    final List<RenderObject> chain = <RenderObject>[];
    while (renderObject != null) {
      chain.add(renderObject);
      renderObject = renderObject.parent;
    }
    return _followDiagnosticableChain(chain.reversed.toList());
  }

  Map<String, Object> _nodeToJson(DiagnosticsNode node, String groupName) {
    if (node == null)
      return null;
    final Map<String, Object> json = node.toJsonMap();

    json['objectId'] = toId(node, groupName);
    final Object value = node.value;
    json['valueId'] = toId(value, groupName);

    final _Location creationLocation = _getCreationLocation(value);
    if (creationLocation != null) {
      json['creationLocation'] = creationLocation.toJsonMap();
      if (_isLocalCreationLocation(creationLocation)) {
        json['createdByLocalProject'] = true;
      }
    }
    return json;
  }

  bool _isLocalCreationLocation(_Location location) {
    if (_pubRootDirectories == null || location == null || location.file == null) {
      return false;
    }
    final String file = Uri.parse(location.file).path;
    for (String directory in _pubRootDirectories) {
      if (file.startsWith(directory)) {
        return true;
      }
    }
    return false;
  }

  String _serialize(DiagnosticsNode node, String groupName) {
    return json.encode(_nodeToJson(node, groupName));
  }

  List<Map<String, Object>> _nodesToJson(Iterable<DiagnosticsNode> nodes, String groupName) {
    if (nodes == null)
      return <Map<String, Object>>[];
    return nodes.map<Map<String, Object>>((DiagnosticsNode node) => _nodeToJson(node, groupName)).toList();
  }

  /// Returns a JSON representation of the properties of the [DiagnosticsNode]
  /// object that `diagnosticsNodeId` references.
  String getProperties(String diagnosticsNodeId, String groupName) {
    final DiagnosticsNode node = toObject(diagnosticsNodeId);
    return json.encode(_nodesToJson(node == null ? const <DiagnosticsNode>[] : node.getProperties(), groupName));
  }

  /// Returns a JSON representation of the children of the [DiagnosticsNode]
  /// object that `diagnosticsNodeId` references.
  String getChildren(String diagnosticsNodeId, String groupName) {
    final DiagnosticsNode node = toObject(diagnosticsNodeId);
    return json.encode(_nodesToJson(node == null ? const <DiagnosticsNode>[] : node.getChildren(), groupName));
  }

  /// Returns a JSON representation of the [DiagnosticsNode] for the root
  /// [Element].
  String getRootWidget(String groupName) {
    return _serialize(WidgetsBinding.instance?.renderViewElement?.toDiagnosticsNode(), groupName);
  }

  /// Returns a JSON representation of the [DiagnosticsNode] for the root
  /// [RenderObject].
  String getRootRenderObject(String groupName) {
    return _serialize(RendererBinding.instance?.renderView?.toDiagnosticsNode(), groupName);
  }

  /// Returns a [DiagnosticsNode] representing the currently selected
  /// [RenderObject].
  ///
  /// If the currently selected [RenderObject] is identical to the
  /// [RenderObject] referenced by `previousSelectionId` then the previous
  /// [DiagnosticNode] is reused.
  String getSelectedRenderObject(String previousSelectionId, String groupName) {
    final DiagnosticsNode previousSelection = toObject(previousSelectionId);
    final RenderObject current = selection?.current;
    return _serialize(current == previousSelection?.value ? previousSelection : current?.toDiagnosticsNode(), groupName);
  }

  /// Returns a [DiagnosticsNode] representing the currently selected [Element].
  ///
  /// If the currently selected [Element] is identical to the [Element]
  /// referenced by `previousSelectionId` then the previous [DiagnosticNode] is
  /// reused.
  String getSelectedWidget(String previousSelectionId, String groupName) {
    final DiagnosticsNode previousSelection = toObject(previousSelectionId);
    final Element current = selection?.currentElement;
    return _serialize(current == previousSelection?.value ? previousSelection : current?.toDiagnosticsNode(), groupName);
  }

  /// Returns whether [Widget] creation locations are available.
  ///
  /// [Widget] creation locations are only available for debug mode builds when
  /// the `--track-widget-creation` flag is passed to `flutter_tool`. Dart 2.0
  /// is required as injecting creation locations requires a
  /// [Dart Kernel Transformer](https://github.com/dart-lang/sdk/wiki/Kernel-Documentation).
  bool isWidgetCreationTracked() => new _WidgetForTypeTests() is _HasCreationLocation;
}

class _WidgetForTypeTests extends Widget {
  @override
  Element createElement() => null;
}

/// A widget that enables inspecting the child widget's structure.
///
/// Select a location on your device or emulator and view what widgets and
/// render object that best matches the location. An outline of the selected
/// widget and terse summary information is shown on device with detailed
/// information is shown in the observatory or in IntelliJ when using the
/// Flutter Plugin.
///
/// The inspector has a select mode and a view mode.
///
/// In the select mode, tapping the device selects the widget that best matches
/// the location of the touch and switches to view mode. Dragging a finger on
/// the device selects the widget under the drag location but does not switch
/// modes. Touching the very edge of the bounding box of a widget triggers
/// selecting the widget even if another widget that also overlaps that
/// location would otherwise have priority.
///
/// In the view mode, the previously selected widget is outlined, however,
/// touching the device has the same effect it would have if the inspector
/// wasn't present. This allows interacting with the application and viewing how
/// the selected widget changes position. Clicking on the select icon in the
/// bottom left corner of the application switches back to select mode.
class WidgetInspector extends StatefulWidget {
  /// Creates a widget that enables inspection for the child.
  ///
  /// The [child] argument must not be null.
  const WidgetInspector({
    Key key,
    @required this.child,
    @required this.selectButtonBuilder,
  }) : assert(child != null),
       super(key: key);

  /// The widget that is being inspected.
  final Widget child;

  /// A builder that is called to create the select button.
  ///
  /// The `onPressed` callback passed as an argument to the builder should be
  /// hooked up to the returned widget.
  final InspectorSelectButtonBuilder selectButtonBuilder;

  @override
  _WidgetInspectorState createState() => new _WidgetInspectorState();
}

class _WidgetInspectorState extends State<WidgetInspector>
    with WidgetsBindingObserver {

  _WidgetInspectorState() : selection = WidgetInspectorService.instance.selection;

  Offset _lastPointerLocation;

  final InspectorSelection selection;

  /// Whether the inspector is in select mode.
  ///
  /// In select mode, pointer interactions trigger widget selection instead of
  /// normal interactions. Otherwise the previously selected widget is
  /// highlighted but the application can be interacted with normally.
  bool isSelectMode = true;

  final GlobalKey _ignorePointerKey = new GlobalKey();

  /// Distance from the edge of of the bounding box for an element to consider
  /// as selecting the edge of the bounding box.
  static const double _kEdgeHitMargin = 2.0;

  InspectorSelectionChangedCallback _selectionChangedCallback;
  @override
  void initState() {
    super.initState();

    _selectionChangedCallback = () {
      setState(() {
        // The [selection] property which the build method depends on has
        // changed.
      });
    };
    assert(WidgetInspectorService.instance.selectionChangedCallback == null);
    WidgetInspectorService.instance.selectionChangedCallback = _selectionChangedCallback;
  }

  @override
  void dispose() {
    if (WidgetInspectorService.instance.selectionChangedCallback == _selectionChangedCallback) {
      WidgetInspectorService.instance.selectionChangedCallback = null;
    }
    super.dispose();
  }

  bool _hitTestHelper(
    List<RenderObject> hits,
    List<RenderObject> edgeHits,
    Offset position,
    RenderObject object,
    Matrix4 transform,
  ) {
    bool hit = false;
    final Matrix4 inverse = new Matrix4.inverted(transform);
    final Offset localPosition = MatrixUtils.transformPoint(inverse, position);

    final List<DiagnosticsNode> children = object.debugDescribeChildren();
    for (int i = children.length - 1; i >= 0; i -= 1) {
      final DiagnosticsNode diagnostics = children[i];
      assert(diagnostics != null);
      if (diagnostics.style == DiagnosticsTreeStyle.offstage ||
          diagnostics.value is! RenderObject)
        continue;
      final RenderObject child = diagnostics.value;
      final Rect paintClip = object.describeApproximatePaintClip(child);
      if (paintClip != null && !paintClip.contains(localPosition))
        continue;

      final Matrix4 childTransform = transform.clone();
      object.applyPaintTransform(child, childTransform);
      if (_hitTestHelper(hits, edgeHits, position, child, childTransform))
        hit = true;
    }

    final Rect bounds = object.semanticBounds;
    if (bounds.contains(localPosition)) {
      hit = true;
      // Hits that occur on the edge of the bounding box of an object are
      // given priority to provide a way to select objects that would
      // otherwise be hard to select.
      if (!bounds.deflate(_kEdgeHitMargin).contains(localPosition))
        edgeHits.add(object);
    }
    if (hit)
      hits.add(object);
    return hit;
  }

  /// Returns the list of render objects located at the given position ordered
  /// by priority.
  ///
  /// All render objects that are not offstage that match the location are
  /// included in the list of matches. Priority is given to matches that occur
  /// on the edge of a render object's bounding box and to matches found by
  /// [RenderBox.hitTest].
  List<RenderObject> hitTest(Offset position, RenderObject root) {
    final List<RenderObject> regularHits = <RenderObject>[];
    final List<RenderObject> edgeHits = <RenderObject>[];

    _hitTestHelper(regularHits, edgeHits, position, root, root.getTransformTo(null));
    // Order matches by the size of the hit area.
    double _area(RenderObject object) {
      final Size size = object.semanticBounds?.size;
      return size == null ? double.maxFinite : size.width * size.height;
    }
    regularHits.sort((RenderObject a, RenderObject b) => _area(a).compareTo(_area(b)));
    final Set<RenderObject> hits = new LinkedHashSet<RenderObject>();
    hits..addAll(edgeHits)..addAll(regularHits);
    return hits.toList();
  }

  void _inspectAt(Offset position) {
    if (!isSelectMode)
      return;

    final RenderIgnorePointer ignorePointer = _ignorePointerKey.currentContext.findRenderObject();
    final RenderObject userRender = ignorePointer.child;
    final List<RenderObject> selected = hitTest(position, userRender);

    setState(() {
      selection.candidates = selected;
    });
  }

  void _handlePanDown(DragDownDetails event) {
    _lastPointerLocation = event.globalPosition;
    _inspectAt(event.globalPosition);
  }

  void _handlePanUpdate(DragUpdateDetails event) {
    _lastPointerLocation = event.globalPosition;
    _inspectAt(event.globalPosition);
  }

  void _handlePanEnd(DragEndDetails details) {
    // If the pan ends on the edge of the window assume that it indicates the
    // pointer is being dragged off the edge of the display not a regular touch
    // on the edge of the display. If the pointer is being dragged off the edge
    // of the display we do not want to select anything. A user can still select
    // a widget that is only at the exact screen margin by tapping.
    final Rect bounds = (Offset.zero & (ui.window.physicalSize / ui.window.devicePixelRatio)).deflate(_kOffScreenMargin);
    if (!bounds.contains(_lastPointerLocation)) {
      setState(() {
        selection.clear();
      });
    }
  }

  void _handleTap() {
    if (!isSelectMode)
      return;
    if (_lastPointerLocation != null) {
      _inspectAt(_lastPointerLocation);

      if (selection != null) {
        // Notify debuggers to open an inspector on the object.
        developer.inspect(selection.current);
      }
    }
    setState(() {
      // Only exit select mode if there is a button to return to select mode.
      if (widget.selectButtonBuilder != null)
        isSelectMode = false;
    });
  }

  void _handleEnableSelect() {
    setState(() {
      isSelectMode = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[];
    children.add(new GestureDetector(
      onTap: _handleTap,
      onPanDown: _handlePanDown,
      onPanEnd: _handlePanEnd,
      onPanUpdate: _handlePanUpdate,
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      child: new IgnorePointer(
        ignoring: isSelectMode,
        key: _ignorePointerKey,
        ignoringSemantics: false,
        child: widget.child,
      ),
    ));
    if (!isSelectMode && widget.selectButtonBuilder != null) {
      children.add(new Positioned(
        left: _kInspectButtonMargin,
        bottom: _kInspectButtonMargin,
        child: widget.selectButtonBuilder(context, _handleEnableSelect)
      ));
    }
    children.add(new _InspectorOverlay(selection: selection));
    return new Stack(children: children);
  }
}

/// Mutable selection state of the inspector.
class InspectorSelection {
  /// Render objects that are candidates to be selected.
  ///
  /// Tools may wish to iterate through the list of candidates.
  List<RenderObject> get candidates => _candidates;
  List<RenderObject> _candidates = <RenderObject>[];
  set candidates(List<RenderObject> value) {
    _candidates = value;
    _index = 0;
    _computeCurrent();
  }

  /// Index within the list of candidates that is currently selected.
  int get index => _index;
  int _index = 0;
  set index(int value) {
    _index = value;
    _computeCurrent();
  }

  /// Set the selection to empty.
  void clear() {
    _candidates = <RenderObject>[];
    _index = 0;
    _computeCurrent();
  }

  /// Selected render object typically from the [candidates] list.
  ///
  /// Setting [candidates] or calling [clear] resets the selection.
  ///
  /// Returns null if the selection is invalid.
  RenderObject get current => _current;
  RenderObject _current;
  set current(RenderObject value) {
    if (_current != value) {
      _current = value;
      _currentElement = value.debugCreator.element;
    }
  }

  /// Selected [Element] consistent with the [current] selected [RenderObject].
  ///
  /// Setting [candidates] or calling [clear] resets the selection.
  ///
  /// Returns null if the selection is invalid.
  Element get currentElement => _currentElement;
  Element _currentElement;
  set currentElement(Element element) {
    if (currentElement != element) {
      _currentElement = element;
      _current = element.findRenderObject();
    }
  }

  void _computeCurrent() {
    if (_index < candidates.length) {
      _current = candidates[index];
      _currentElement = _current.debugCreator.element;
    } else {
      _current = null;
      _currentElement = null;
    }
  }

  /// Whether the selected render object is attached to the tree or has gone
  /// out of scope.
  bool get active => _current != null && _current.attached;
}

class _InspectorOverlay extends LeafRenderObjectWidget {
  const _InspectorOverlay({
    Key key,
    @required this.selection,
  }) : super(key: key);

  final InspectorSelection selection;

  @override
  _RenderInspectorOverlay createRenderObject(BuildContext context) {
    return new _RenderInspectorOverlay(selection: selection);
  }

  @override
  void updateRenderObject(BuildContext context, _RenderInspectorOverlay renderObject) {
    renderObject.selection = selection;
  }
}

class _RenderInspectorOverlay extends RenderBox {
  /// The arguments must not be null.
  _RenderInspectorOverlay({ @required InspectorSelection selection }) : _selection = selection, assert(selection != null);

  InspectorSelection get selection => _selection;
  InspectorSelection _selection;
  set selection(InspectorSelection value) {
    if (value != _selection) {
      _selection = value;
    }
    markNeedsPaint();
  }

  @override
  bool get sizedByParent => true;

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  void performResize() {
    size = constraints.constrain(const Size(double.infinity, double.infinity));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    assert(needsCompositing);
    context.addLayer(new _InspectorOverlayLayer(
      overlayRect: new Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height),
      selection: selection,
    ));
  }
}

class _TransformedRect {
  _TransformedRect(RenderObject object) :
    rect = object.semanticBounds,
    transform = object.getTransformTo(null);

  final Rect rect;
  final Matrix4 transform;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType)
      return false;
    final _TransformedRect typedOther = other;
    return rect == typedOther.rect && transform == typedOther.transform;
  }

  @override
  int get hashCode => hashValues(rect, transform);
}

/// State describing how the inspector overlay should be rendered.
///
/// The equality operator can be used to determine whether the overlay needs to
/// be rendered again.
class _InspectorOverlayRenderState {
  _InspectorOverlayRenderState({
    @required this.overlayRect,
    @required this.selected,
    @required this.candidates,
    @required this.tooltip,
    @required this.textDirection,
  });

  final Rect overlayRect;
  final _TransformedRect selected;
  final List<_TransformedRect> candidates;
  final String tooltip;
  final TextDirection textDirection;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType)
      return false;

    final _InspectorOverlayRenderState typedOther = other;
    return overlayRect == typedOther.overlayRect
        && selected == typedOther.selected
        && listEquals<_TransformedRect>(candidates, typedOther.candidates)
        && tooltip == typedOther.tooltip;
  }

  @override
  int get hashCode => hashValues(overlayRect, selected, hashList(candidates), tooltip);
}

const int _kMaxTooltipLines = 5;
const Color _kTooltipBackgroundColor = const Color.fromARGB(230, 60, 60, 60);
const Color _kHighlightedRenderObjectFillColor = const Color.fromARGB(128, 128, 128, 255);
const Color _kHighlightedRenderObjectBorderColor = const Color.fromARGB(128, 64, 64, 128);

/// A layer that outlines the selected [RenderObject] and candidate render
/// objects that also match the last pointer location.
///
/// This approach is horrific for performance and is only used here because this
/// is limited to debug mode. Do not duplicate the logic in production code.
class _InspectorOverlayLayer extends Layer {
  /// Creates a layer that displays the inspector overlay.
  _InspectorOverlayLayer({
    @required this.overlayRect,
    @required this.selection,
  }) : assert(overlayRect != null), assert(selection != null) {
    bool inDebugMode = false;
    assert(() {
      inDebugMode = true;
      return true;
    }());
    if (inDebugMode == false) {
      throw new FlutterError(
        'The inspector should never be used in production mode due to the '
        'negative performance impact.'
      );
    }
  }

  InspectorSelection selection;

  /// The rectangle in this layer's coordinate system that the overlay should
  /// occupy.
  ///
  /// The scene must be explicitly recomposited after this property is changed
  /// (as described at [Layer]).
  final Rect overlayRect;

  _InspectorOverlayRenderState _lastState;

  /// Picture generated from _lastState.
  ui.Picture _picture;

  TextPainter _textPainter;
  double _textPainterMaxWidth;

  @override
  void addToScene(ui.SceneBuilder builder, Offset layerOffset) {
    if (!selection.active)
      return;

    final RenderObject selected = selection.current;
    final List<_TransformedRect> candidates = <_TransformedRect>[];
    for (RenderObject candidate in selection.candidates) {
      if (candidate == selected || !candidate.attached)
        continue;
      candidates.add(new _TransformedRect(candidate));
    }

    final _InspectorOverlayRenderState state = new _InspectorOverlayRenderState(
      overlayRect: overlayRect,
      selected: new _TransformedRect(selected),
      tooltip: selection.currentElement.toStringShort(),
      textDirection: TextDirection.ltr,
      candidates: candidates,
    );

    if (state != _lastState) {
      _lastState = state;
      _picture = _buildPicture(state);
    }
    builder.addPicture(layerOffset, _picture);
  }

  ui.Picture _buildPicture(_InspectorOverlayRenderState state) {
    final ui.PictureRecorder recorder = new ui.PictureRecorder();
    final Canvas canvas = new Canvas(recorder, state.overlayRect);
    final Size size = state.overlayRect.size;

    final Paint fillPaint = new Paint()
      ..style = PaintingStyle.fill
      ..color = _kHighlightedRenderObjectFillColor;

    final Paint borderPaint = new Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = _kHighlightedRenderObjectBorderColor;

    // Highlight the selected renderObject.
    final Rect selectedPaintRect = state.selected.rect.deflate(0.5);
    canvas
      ..save()
      ..transform(state.selected.transform.storage)
      ..drawRect(selectedPaintRect, fillPaint)
      ..drawRect(selectedPaintRect, borderPaint)
      ..restore();

    // Show all other candidate possibly selected elements. This helps selecting
    // render objects by selecting the edge of the bounding box shows all
    // elements the user could toggle the selection between.
    for (_TransformedRect transformedRect in state.candidates) {
      canvas
        ..save()
        ..transform(transformedRect.transform.storage)
        ..drawRect(transformedRect.rect.deflate(0.5), borderPaint)
        ..restore();
    }

    final Rect targetRect = MatrixUtils.transformRect(
        state.selected.transform, state.selected.rect);
    final Offset target = new Offset(targetRect.left, targetRect.center.dy);
    const double offsetFromWidget = 9.0;
    final double verticalOffset = (targetRect.height) / 2 + offsetFromWidget;

    _paintDescription(canvas, state.tooltip, state.textDirection, target, verticalOffset, size, targetRect);

    // TODO(jacobr): provide an option to perform a debug paint of just the
    // selected widget.
    return recorder.endRecording();
  }

  void _paintDescription(
    Canvas canvas,
    String message,
    TextDirection textDirection,
    Offset target,
    double verticalOffset,
    Size size,
    Rect targetRect,
  ) {
    canvas.save();
    final double maxWidth = size.width - 2 * (_kScreenEdgeMargin + _kTooltipPadding);
    if (_textPainter == null || _textPainter.text.text != message || _textPainterMaxWidth != maxWidth) {
      _textPainterMaxWidth = maxWidth;
      _textPainter = new TextPainter()
        ..maxLines = _kMaxTooltipLines
        ..ellipsis = '...'
        ..text = new TextSpan(style: _messageStyle, text: message)
        ..textDirection = textDirection
        ..layout(maxWidth: maxWidth);
    }

    final Size tooltipSize = _textPainter.size + const Offset(_kTooltipPadding * 2, _kTooltipPadding * 2);
    final Offset tipOffset = positionDependentBox(
      size: size,
      childSize: tooltipSize,
      target: target,
      verticalOffset: verticalOffset,
      preferBelow: false,
    );

    final Paint tooltipBackground = new Paint()
      ..style = PaintingStyle.fill
      ..color = _kTooltipBackgroundColor;
    canvas.drawRect(
      new Rect.fromPoints(
        tipOffset,
        tipOffset.translate(tooltipSize.width, tooltipSize.height),
      ),
      tooltipBackground,
    );

    double wedgeY = tipOffset.dy;
    final bool tooltipBelow = tipOffset.dy > target.dy;
    if (!tooltipBelow)
      wedgeY += tooltipSize.height;

    const double wedgeSize = _kTooltipPadding * 2;
    double wedgeX = math.max(tipOffset.dx, target.dx) + wedgeSize * 2;
    wedgeX = math.min(wedgeX, tipOffset.dx + tooltipSize.width - wedgeSize * 2);
    final List<Offset> wedge = <Offset>[
      new Offset(wedgeX - wedgeSize, wedgeY),
      new Offset(wedgeX + wedgeSize, wedgeY),
      new Offset(wedgeX, wedgeY + (tooltipBelow ? -wedgeSize : wedgeSize)),
    ];
    canvas.drawPath(new Path()..addPolygon(wedge, true,), tooltipBackground);
    _textPainter.paint(canvas, tipOffset + const Offset(_kTooltipPadding, _kTooltipPadding));
    canvas.restore();
  }
}

const double _kScreenEdgeMargin = 10.0;
const double _kTooltipPadding = 5.0;
const double _kInspectButtonMargin = 10.0;

/// Interpret pointer up events within with this margin as indicating the
/// pointer is moving off the device.
const double _kOffScreenMargin = 1.0;

const TextStyle _messageStyle = const TextStyle(
  color: const Color(0xFFFFFFFF),
  fontSize: 10.0,
  height: 1.2,
);

/// Interface for classes that track the source code location the their
/// constructor was called from.
///
/// A [Dart Kernel Transformer](https://github.com/dart-lang/sdk/wiki/Kernel-Documentation).
/// adds this interface to the [Widget] class when the
/// `--track-widget-creation` flag is passed to `flutter_tool`. Dart 2.0 is
/// required as injecting creation locations requires a
/// [Dart Kernel Transformer](https://github.com/dart-lang/sdk/wiki/Kernel-Documentation).
// ignore: unused_element
abstract class _HasCreationLocation {
  _Location get _location;
}

/// A tuple with file, line, and column number, for displaying human-readable
/// file locations.
class _Location {
  const _Location({
    this.file,
    this.line,
    this.column,
    this.name,
    this.parameterLocations
  });

  /// File path of the location.
  final String file;

  /// 1-based line number.
  final int line;
  /// 1-based column number.
  final int column;

  /// Optional name of the parameter or function at this location.
  final String name;

  /// Optional locations of the parameters of the member at this location.
  final List<_Location> parameterLocations;

  Map<String, Object> toJsonMap() {
    final Map<String, Object> json = <String, Object>{
      'file': file,
      'line': line,
      'column': column,
    };
    if (name != null) {
      json['name'] = name;
    }
    if (parameterLocations != null) {
      json['parameterLocations'] = parameterLocations.map<Map<String, Object>>(
          (_Location location) => location.toJsonMap()).toList();
    }
    return json;
  }

  @override
  String toString() {
    final List<String> parts = <String>[];
    if (name != null) {
      parts.add(name);
    }
    if (file != null) {
      parts.add(file);
    }
    parts..add('$line')..add('$column');
    return parts.join(':');
  }
}

/// Returns the creation location of an object if one is available.
///
/// Creation locations are only available for debug mode builds when
/// the `--track-widget-creation` flag is passed to `flutter_tool`. Dart 2.0 is
/// required as injecting creation locations requires a
/// [Dart Kernel Transformer](https://github.com/dart-lang/sdk/wiki/Kernel-Documentation).
///
/// Currently creation locations are only available for [Widget] and [Element]
_Location _getCreationLocation(Object object) {
  final Object candidate =  object is Element ? object.widget : object;
  return candidate is _HasCreationLocation ? candidate._location : null;
}
