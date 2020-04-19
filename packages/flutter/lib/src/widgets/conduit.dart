// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' show max;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'debug.dart';
import 'framework.dart';
import 'layout_builder.dart';

// When a [Conduit] tries to mount its `remoteChild` onto its remote anchor's
// mountPoint, chances are the [RenderConduitAnchorWidget] hasn't been built for
// the first time yet. In this case a _RenderConduit will be given
// to the [RenderConduitAnchorWidget] that has yet to build, allowing it to attach
// the pending renderObject when it's ready.
class _BoxContainer<T> {
  T content;
}

/// A global key that uniquely identifies the receiving [ConduitAnchor] that a
/// [Conduit] will later attach its `remoteChild`'s `renderObject` to.
///
/// Unlike other global keys, an [AnchorKey] may contain opaque information only
/// useful to [ConduitAnchor]s, so it typically shouldn't be used to
/// key other types of widgets.
class AnchorKey extends GlobalKey {
  /// Creates a unique [AnchorKey].
  AnchorKey()
    : _manifest = _BoxContainer<_ConduitElement>(),
      super.constructor();
  final _BoxContainer<_ConduitElement> _manifest;

  _ConduitElement get _conduitElement => _manifest.content;
  set _conduitElement(_ConduitElement element) {
    assert(element == null || _conduitElement == null);
    _manifest.content = element;
  }

  @override
  _ConduitAnchorElement get currentContext => super.currentContext as _ConduitAnchorElement;
}

/// A widget that builds its [child] and [remoteChildBuilder] as regular children under
/// itself, but places its [remoteChildBuilder]'s render object to the [ConduitAnchor]
/// associated with [remoteKey].
///
/// This widget is useful when you need to build the [remoteChildBuilder] subtree using
/// an [OverlayEntry], but would like the [remoteChildBuilder] to depend on the same set
/// of [InheritedWidget]s as this widget. For example, an in flight [Hero] needs
/// to be placed on an [OverlayEntry] so it appears over other content, but at
/// the same time we want the [DefaultTextStyle] it depends on to remain the same
/// when it starts flying.
class Conduit extends RenderObjectWidget {
  /// Creates a [Conduit] that places its [remoteChildBuilder]'s render object to the
  /// designated [ConduitAnchor] .
  const Conduit({
    Key key,
    AnchorKey remoteKey,
    this.remoteChildBuilder,
    this.child,
  }) : remoteKey = remoteChildBuilder == null ? null : remoteKey,
       assert(
         remoteChildBuilder == null || remoteKey != null,
         'A remoteChildBuilder must be accompanied by a remoteKey.'
       ),
       //assert(remoteKey?._conduitElement == null),
       super(key: key);

  /// A special [GlobalKey] that uniquely identifies a [ConduitAnchor].
  ///
  /// Currently, directly changing [remoteKey] from a non-null value to a different
  /// non-null value (i.e. reparenting [remoteChildBuilder]) is not supported. To
  /// switch to a different [remoteKey], first set this property to null and then
  /// change it to the new [remoteKey].
  ///
  /// Must not be null when [remoteChildBuilder] is not null.
  final AnchorKey remoteKey;

  /// A [LayoutWidgetBuilder] callback that constructs the widget tree like in
  /// a regular [LayoutBuilder], but the constructed tree will visually appears
  /// in a [ConduitAnchor].
  ///
  /// This widget will be built using the [BuildContext] of this [Conduit], same
  /// as the regular [child], however its root render object will be attached to
  /// the render object of a [ConduitAnchor] that [remoteKey] points to, rather
  /// than the render object of this [Conduit] itself, and its [BoxConstraints]
  /// parameter will be provided by the [ConduitAnchor].
  ///
  /// When [remoteChildBuilder] is not null, a valid [remoteKey] must be provided.
  final LayoutWidgetBuilder remoteChildBuilder;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  RenderObjectElement createElement() => _ConduitElement(this);

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderConduit();
}

class _ConduitElement extends RenderObjectElement {
  _ConduitElement(Conduit widget) : super(widget);

  @override
  Conduit get widget => super.widget as Conduit;

  Conduit _previousWidget;

  @override
  _RenderConduit get renderObject => super.renderObject as _RenderConduit;

  Element _remoteChild;
  Element _child;

  @override
  void forgetChild(Element child) {
    assert(child != null);
    super.forgetChild(child);
    if (child == _child) {
      _child = null;
      return;
    }

    assert(child == _remoteChild);
    renderObject._follower?.leader = null;
    _remoteChild = null;
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_child != null)
      visitor(_child);
    if (_remoteChild != null)
      visitor(_remoteChild);
  }

  void updateRemoteChild() {
    final _ConduitAnchorElement remoteMountPoint = widget.remoteKey?.currentContext;
    if (remoteMountPoint != null) {
      // If mountPoint is already mounted.
      assert(remoteMountPoint.renderObject != null);
      remoteMountPoint.renderObject.leader = renderObject;
    }
    renderObject.updateCallback(_layout);
  }

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    assert(_child == null);
    assert(_remoteChild == null);
    assert(slot == newSlot);

    _child = updateChild(_child, widget.child, null);
    assert((_child == null) == (widget.child == null));

    widget.remoteKey?._conduitElement = this;
    updateRemoteChild();
  }

  @override
  void unmount() {
    super.unmount();
    widget.remoteKey?._conduitElement = null;
    renderObject._follower?.leader = null;
  }

  @override
  void attachRenderObject(dynamic newSlot) {
    super.attachRenderObject(newSlot);
    widget.remoteKey?.currentContext?.renderObject?.leader = renderObject;
  }

  @override
  void detachRenderObject() {
    super.detachRenderObject();
    widget.remoteKey?.currentContext?.renderObject?.leader = null;
  }

  @override
  void activate() {
    super.activate();
    widget.remoteKey?._conduitElement = this;
    widget.remoteKey?.currentContext?.renderObject?.leader = renderObject;
    if (_remoteChild?.renderObject != null) {
      final RenderBox remoteChildRenderBox =  _remoteChild.renderObject as RenderBox;
      insertChildRenderObject(remoteChildRenderBox, this);
    }
  }

  @override
  void deactivate() {
    super.deactivate();
    widget.remoteKey?._conduitElement = null;
    widget.remoteKey?.currentContext?.renderObject?.leader = null;
    if (_remoteChild?.renderObject != null) {
      final RenderBox remoteChildRenderBox =  _remoteChild.renderObject as RenderBox;
      removeChildRenderObject(remoteChildRenderBox);
    }
  }

  @override
  void update(Conduit newWidget) {
    final Conduit oldWidget = widget;

    assert(
      oldWidget.remoteKey == newWidget.remoteKey
      || oldWidget.remoteKey == null
      || newWidget.remoteKey == null,
      'Currently transferring remoteChild to a different remote anchor is not supported.',
    );

    _previousWidget = oldWidget;
    super.update(newWidget);
    assert(widget == newWidget);

    _child = updateChild(_child, widget.child, null);
    updateRemoteChild();
  }

  @override
  void performRebuild() {
    final RenderObject follower = renderObject._follower;
    if (follower != null)
      renderObject.markDependentNeedsLayout(follower);
    super.performRebuild();
  }

  @override
  void insertChildRenderObject(RenderBox child, dynamic slot) {
    if (slot is _ConduitElement && slot == this) {
      final _ConduitAnchorElement mountPoint = widget.remoteKey.currentContext;
      // At this point the mount point should already be mounted, and should
      // be the caller of the layout callback.
      if (renderObject._follower == null) {
        //assert(mountPoint.renderObject.leader == null);
        mountPoint.renderObject?.leader = renderObject;
      }
      assert(mountPoint?.renderObject?.leader == renderObject);
      mountPoint.insertChildRenderObject(child, null);
      return;
    }

    // Insert to the child slot.
    final _RenderConduit oldRenderObject = renderObject;
    assert(slot == null);
    assert(oldRenderObject.debugValidateChild(child));
    oldRenderObject.child = child;
    assert(oldRenderObject == renderObject);
  }

  @override
  void moveChildRenderObject(RenderObject child, dynamic slot) {
    assert(false);
  }

  @override
  void removeChildRenderObject(RenderBox child) {
    assert(child != null);
    assert(
      renderObject != null,
      'Trying to remove $child from $this which does not have a renderObject.',
    );
    if (child == renderObject.child) {
      assert(child?.parent != null);
      final _RenderConduit oldRenderObject = renderObject;
      assert(renderObject.child == child);
      oldRenderObject.child = null;
      assert(oldRenderObject == renderObject);
    } else {
      final AnchorKey key = _previousWidget?.remoteKey ?? widget?.remoteKey;
      assert(key != null);
      key.currentContext?.removeChildRenderObject(child);
    }
  }

  void _layout(BoxConstraints constraints) {
    assert(constraints != null);
    owner.buildScope(this, () {
      Widget built;
      if (widget.remoteChildBuilder != null) {
        try {
          built = widget.remoteChildBuilder(this, constraints);
          debugWidgetBuilderValue(widget, built);
        } catch (e, stack) {
          built = ErrorWidget.builder(
            _debugReportException(
              ErrorDescription('building remoteChild $widget'),
              e,
              stack,
              informationCollector: () sync* {
                yield DiagnosticsDebugCreator(DebugCreator(this));
              },
            ),
          );
        }
      }
      try {
        _remoteChild = updateChild(_remoteChild, built, this);
        //assert(_remoteChild != null);
      } catch (e, stack) {
        built = ErrorWidget.builder(
          _debugReportException(
            ErrorDescription('building remoteChild $widget'),
            e,
            stack,
            informationCollector: () sync* {
              yield DiagnosticsDebugCreator(DebugCreator(this));
            },
          ),
        );
        _remoteChild = updateChild(null, built, this);
      }
    });
  }
}

/// A widget keyed by an [AnchorKey] and allows a [Conduit] possesses the same
/// [AnchorKey] to attach the render object of its `remoteChild` to.
class ConduitAnchor extends LeafRenderObjectWidget {
  /// Creates a [ConduitAnchor] with an [AnchorKey].
  const ConduitAnchor({
    @required AnchorKey key,
  }) : assert(key != null),
       super(key: key);

  @override
  AnchorKey get key => super.key as AnchorKey;

  @override
  LeafRenderObjectElement createElement() => _ConduitAnchorElement(this);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderConduitAnchor()..leader = key._conduitElement?.renderObject;
  }
}

class _ConduitAnchorElement extends LeafRenderObjectElement {
  _ConduitAnchorElement(ConduitAnchor widget) : super(widget);

  @override
  ConduitAnchor get widget => super.widget as ConduitAnchor;

  @override
  _RenderConduitAnchor get renderObject => super.renderObject as _RenderConduitAnchor;

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    renderObject.leader = widget.key._conduitElement?.renderObject;
  }

  @override
  void unmount() {
    renderObject.leader = null;
    super.unmount();
  }

  @override
  void insertChildRenderObject(RenderBox child, dynamic slot) {
    assert(slot == null);
    final _RenderConduitAnchor renderBox = renderObject;
    assert(renderBox.debugValidateChild(child));
    renderObject.child = child;
    assert(renderObject == renderBox);
  }

  @override
  void removeChildRenderObject(RenderBox child) {
    final _RenderConduitAnchor renderBox = renderObject;
    // This is more forgiving than a typical removeChildRenderObject implementation,
    // since _RenderConduitAnchorElement detaches its remoteChild.renderObject in
    // `Element.deactivate()`.
    if (renderBox.child != null) {
      assert(renderBox.child == child);
      renderBox.child = null;
    }
    assert(renderObject == renderBox);
  }
}

// A RenderProxyBox subclass that keeps its follower's depth greater than or equal
// to its own depth, if its follower is not null.
class _RenderConduit extends RenderProxyBox {
  _RenderConduit([RenderBox child]) : super(child);

  _RenderConduitAnchor _follower;
  LayoutCallback<BoxConstraints> _callback;

  void updateCallback(LayoutCallback<BoxConstraints> callback) {
    _callback = callback;
    if (_follower != null)
      markDependentNeedsLayout(_follower);
  }

  @override
  void redepthChildren() {
    super.redepthChildren();
    if (_follower != null)
      redepthChild(_follower);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    if (_follower != null)
      properties.add(DiagnosticsProperty<RenderObject>('follower', _follower));
  }
}

class _RenderConduitAnchor extends RenderProxyBox with RenderConstrainedLayoutBuilder<BoxConstraints, RenderBox> {
  _RenderConduitAnchor([RenderBox child]) : super(child);

  _RenderConduit _leader;
  _RenderConduit get leader => _leader;
  set leader(_RenderConduit value) {
    if (value == leader)
      return;

    assert(value?._follower == null, '$value already has a follower: ${value._follower}');
    assert(
      (value == null) != (leader == null),
      '$this already has a leader: $leader, new leader $value cannot be assigned.',
    );
    leader?._follower = null;
    _leader = value;
    leader?._follower = this;
  }

  int get minDepth => (leader?.depth ?? -1) + 1;

  @override
  int get depth => max(super.depth, minDepth);

  @override
  bool get sizedByParent => true;

  @override
  bool get shouldDeferLayout => true;

  @override
  void performResize() {
    size = constraints.biggest;
    assert(size.isFinite);
  }

  @override
  void performLayout() {
    if (leader?._callback != null && leader.attached) {
      invokeLayoutCallback(_leader._callback);
    }
    child?.layout(constraints, parentUsesSize: false);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('minDepth', minDepth));
    properties.add(IntProperty('depth', depth));
    if (leader != null)
      properties.add(DiagnosticsProperty<RenderObject>('leader', leader));
  }
}

FlutterErrorDetails _debugReportException(
  DiagnosticsNode context,
  dynamic exception,
  StackTrace stack, {
  InformationCollector informationCollector,
}) {
  final FlutterErrorDetails details = FlutterErrorDetails(
    exception: exception,
    stack: stack,
    library: 'widgets library',
    context: context,
    informationCollector: informationCollector,
  );
  FlutterError.reportError(details);
  return details;
}
