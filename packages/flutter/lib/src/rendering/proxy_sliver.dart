// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';
import 'dart:ui' as ui show Color;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';

import 'layer.dart';
import 'object.dart';
import 'proxy_box.dart';
import 'sliver.dart';

/// A base class for sliver render objects that resemble their children.
///
/// A proxy sliver has a single child and mimics all the properties of
/// that child by calling through to the child for each function in the render
/// sliver protocol. For example, a proxy sliver determines its geometry by
/// asking its sliver child to layout with the same constraints and then
/// matching the geometry.
///
/// A proxy sliver isn't useful on its own because you might as well just
/// replace the proxy sliver with its child. However, RenderProxySliver is a
/// useful base class for render objects that wish to mimic most, but not all,
/// of the properties of their sliver child.
///
/// See also:
///
///  * [RenderProxyBox], a base class for render boxes that resemble their
///    children.
abstract class RenderProxySliver extends RenderSliver
    with RenderObjectWithChildMixin<RenderSliver> {
  /// Creates a proxy render sliver.
  ///
  /// Proxy render slivers aren't created directly because they proxy
  /// the render sliver protocol to their sliver [child]. Instead, use one of
  /// the subclasses.
  RenderProxySliver([RenderSliver? child]) {
    this.child = child;
  }

  @override
  Rect get semanticBounds {
    if (child != null) {
      return child!.semanticBounds;
    }
    return super.semanticBounds;
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverPhysicalParentData) {
      child.parentData = SliverPhysicalParentData();
    }
  }

  @override
  void performLayout() {
    assert(child != null);
    child!.layout(constraints, parentUsesSize: true);
    geometry = child!.geometry;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      context.paintChild(child!, offset);
    }
  }

  @override
  bool hitTestChildren(
    SliverHitTestResult result, {
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) {
    return child != null &&
        child!.geometry!.hitTestExtent > 0 &&
        child!.hitTest(
          result,
          mainAxisPosition: mainAxisPosition,
          crossAxisPosition: crossAxisPosition,
        );
  }

  @override
  double childMainAxisPosition(RenderSliver child) {
    assert(child == this.child);
    return 0.0;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    final SliverPhysicalParentData childParentData = child.parentData! as SliverPhysicalParentData;
    childParentData.applyPaintTransform(transform);
  }
}

/// Makes its sliver child partially transparent.
///
/// This class paints its sliver child into an intermediate buffer and then
/// blends the sliver child back into the scene, partially transparent.
///
/// For values of opacity other than 0.0 and 1.0, this class is relatively
/// expensive, because it requires painting the sliver child into an intermediate
/// buffer. For the value 0.0, the sliver child is not painted at all.
/// For the value 1.0, the sliver child is painted immediately without an
/// intermediate buffer.
class RenderSliverOpacity extends RenderProxySliver {
  /// Creates a partially transparent render object.
  ///
  /// The [opacity] argument must be between 0.0 and 1.0, inclusive.
  RenderSliverOpacity({
    double opacity = 1.0,
    bool alwaysIncludeSemantics = false,
    RenderSliver? sliver,
  }) : assert(opacity >= 0.0 && opacity <= 1.0),
       _opacity = opacity,
       _alwaysIncludeSemantics = alwaysIncludeSemantics,
       _alpha = ui.Color.getAlphaFromOpacity(opacity) {
    child = sliver;
  }

  @override
  bool get alwaysNeedsCompositing => child != null && (_alpha > 0);

  int _alpha;

  /// The fraction to scale the child's alpha value.
  ///
  /// An opacity of one is fully opaque. An opacity of zero is fully transparent
  /// (i.e. invisible).
  ///
  /// Values one and zero are painted with a fast path. Other values require
  /// painting the child into an intermediate buffer, which is expensive.
  double get opacity => _opacity;
  double _opacity;
  set opacity(double value) {
    assert(value >= 0.0 && value <= 1.0);
    if (_opacity == value) {
      return;
    }
    final bool didNeedCompositing = alwaysNeedsCompositing;
    final bool wasVisible = _alpha != 0;
    _opacity = value;
    _alpha = ui.Color.getAlphaFromOpacity(_opacity);
    if (didNeedCompositing != alwaysNeedsCompositing) {
      markNeedsCompositingBitsUpdate();
    }
    markNeedsPaint();
    if (wasVisible != (_alpha != 0) && !alwaysIncludeSemantics) {
      markNeedsSemanticsUpdate();
    }
  }

  /// Whether child semantics are included regardless of the opacity.
  ///
  /// If false, semantics are excluded when [opacity] is 0.0.
  ///
  /// Defaults to false.
  bool get alwaysIncludeSemantics => _alwaysIncludeSemantics;
  bool _alwaysIncludeSemantics;
  set alwaysIncludeSemantics(bool value) {
    if (value == _alwaysIncludeSemantics) {
      return;
    }
    _alwaysIncludeSemantics = value;
    markNeedsSemanticsUpdate();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null && child!.geometry!.visible) {
      if (_alpha == 0) {
        // No need to keep the layer. We'll create a new one if necessary.
        layer = null;
        return;
      }
      assert(needsCompositing);
      layer = context.pushOpacity(offset, _alpha, super.paint, oldLayer: layer as OpacityLayer?);
      assert(() {
        layer!.debugCreator = debugCreator;
        return true;
      }());
    }
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (child != null && (_alpha != 0 || alwaysIncludeSemantics)) {
      visitor(child!);
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('opacity', opacity));
    properties.add(
      FlagProperty(
        'alwaysIncludeSemantics',
        value: alwaysIncludeSemantics,
        ifTrue: 'alwaysIncludeSemantics',
      ),
    );
  }
}

/// A render object that is invisible during hit testing.
///
/// When [ignoring] is true, this render object (and its subtree) is invisible
/// to hit testing. It still consumes space during layout and paints its sliver
/// child as usual. It just cannot be the target of located events, because its
/// render object returns false from [hitTest].
///
/// ## Semantics
///
/// Using this class may also affect how the semantics subtree underneath is
/// collected.
///
/// {@macro flutter.widgets.IgnorePointer.semantics}
///
/// {@macro flutter.widgets.IgnorePointer.ignoringSemantics}
class RenderSliverIgnorePointer extends RenderProxySliver {
  /// Creates a render object that is invisible to hit testing.
  RenderSliverIgnorePointer({
    RenderSliver? sliver,
    bool ignoring = true,
    @Deprecated(
      'Create a custom sliver ignore pointer widget instead. '
      'This feature was deprecated after v3.8.0-12.0.pre.',
    )
    bool? ignoringSemantics,
  }) : _ignoring = ignoring,
       _ignoringSemantics = ignoringSemantics {
    child = sliver;
  }

  /// Whether this render object is ignored during hit testing.
  ///
  /// Regardless of whether this render object is ignored during hit testing, it
  /// will still consume space during layout and be visible during painting.
  ///
  /// {@macro flutter.widgets.IgnorePointer.semantics}
  bool get ignoring => _ignoring;
  bool _ignoring;
  set ignoring(bool value) {
    if (value == _ignoring) {
      return;
    }
    _ignoring = value;
    if (ignoringSemantics == null) {
      markNeedsSemanticsUpdate();
    }
  }

  /// Whether the semantics of this render object is ignored when compiling the
  /// semantics tree.
  ///
  /// {@macro flutter.widgets.IgnorePointer.ignoringSemantics}
  @Deprecated(
    'Create a custom sliver ignore pointer widget instead. '
    'This feature was deprecated after v3.8.0-12.0.pre.',
  )
  bool? get ignoringSemantics => _ignoringSemantics;
  bool? _ignoringSemantics;
  set ignoringSemantics(bool? value) {
    if (value == _ignoringSemantics) {
      return;
    }
    _ignoringSemantics = value;
    markNeedsSemanticsUpdate();
  }

  @override
  bool hitTest(
    SliverHitTestResult result, {
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) {
    return !ignoring &&
        super.hitTest(
          result,
          mainAxisPosition: mainAxisPosition,
          crossAxisPosition: crossAxisPosition,
        );
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (_ignoringSemantics ?? false) {
      return;
    }
    super.visitChildrenForSemantics(visitor);
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    // Do not block user interactions if _ignoringSemantics is false; otherwise,
    // delegate to absorbing
    config.isBlockingUserActions = ignoring && (_ignoringSemantics ?? true);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('ignoring', ignoring));
    properties.add(
      DiagnosticsProperty<bool>(
        'ignoringSemantics',
        ignoringSemantics,
        description: ignoringSemantics == null ? null : 'implicitly $ignoringSemantics',
      ),
    );
  }
}

/// Lays the sliver child out as if it was in the tree, but without painting
/// anything, without making the sliver child available for hit testing, and
/// without taking any room in the parent.
class RenderSliverOffstage extends RenderProxySliver {
  /// Creates an offstage render object.
  RenderSliverOffstage({bool offstage = true, RenderSliver? sliver}) : _offstage = offstage {
    child = sliver;
  }

  /// Whether the sliver child is hidden from the rest of the tree.
  ///
  /// If true, the sliver child is laid out as if it was in the tree, but
  /// without painting anything, without making the sliver child available for
  /// hit testing, and without taking any room in the parent.
  ///
  /// If false, the sliver child is included in the tree as normal.
  bool get offstage => _offstage;
  bool _offstage;

  set offstage(bool value) {
    if (value == _offstage) {
      return;
    }
    _offstage = value;
    markNeedsLayoutForSizedByParentChange();
  }

  @override
  void performLayout() {
    assert(child != null);
    child!.layout(constraints, parentUsesSize: true);
    if (!offstage) {
      geometry = child!.geometry;
    } else {
      geometry = SliverGeometry.zero;
    }
  }

  @override
  bool hitTest(
    SliverHitTestResult result, {
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) {
    return !offstage &&
        super.hitTest(
          result,
          mainAxisPosition: mainAxisPosition,
          crossAxisPosition: crossAxisPosition,
        );
  }

  @override
  bool hitTestChildren(
    SliverHitTestResult result, {
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) {
    return !offstage &&
        child != null &&
        child!.geometry!.hitTestExtent > 0 &&
        child!.hitTest(
          result,
          mainAxisPosition: mainAxisPosition,
          crossAxisPosition: crossAxisPosition,
        );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (offstage) {
      return;
    }
    context.paintChild(child!, offset);
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (offstage) {
      return;
    }
    super.visitChildrenForSemantics(visitor);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('offstage', offstage));
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    if (child == null) {
      return <DiagnosticsNode>[];
    }
    return <DiagnosticsNode>[
      child!.toDiagnosticsNode(
        name: 'child',
        style: offstage ? DiagnosticsTreeStyle.offstage : DiagnosticsTreeStyle.sparse,
      ),
    ];
  }
}

/// Makes its sliver child partially transparent, driven from an [Animation].
///
/// This is a variant of [RenderSliverOpacity] that uses an [Animation<double>]
/// rather than a [double] to control the opacity.
class RenderSliverAnimatedOpacity extends RenderProxySliver
    with RenderAnimatedOpacityMixin<RenderSliver> {
  /// Creates a partially transparent render object.
  RenderSliverAnimatedOpacity({
    required Animation<double> opacity,
    bool alwaysIncludeSemantics = false,
    RenderSliver? sliver,
  }) {
    this.opacity = opacity;
    this.alwaysIncludeSemantics = alwaysIncludeSemantics;
    child = sliver;
  }
}

/// Applies a cross-axis constraint to its sliver child.
///
/// This render object takes a [maxExtent] parameter and uses the smaller of
/// [maxExtent] and the parent's [SliverConstraints.crossAxisExtent] as the
/// cross axis extent of the [SliverConstraints] passed to the sliver child.
class RenderSliverConstrainedCrossAxis extends RenderProxySliver {
  /// Creates a render object that constrains the cross axis extent of its sliver child.
  ///
  /// The [maxExtent] parameter must be nonnegative.
  RenderSliverConstrainedCrossAxis({required double maxExtent})
    : _maxExtent = maxExtent,
      assert(maxExtent >= 0.0);

  /// The cross axis extent to apply to the sliver child.
  ///
  /// This value must be nonnegative.
  double get maxExtent => _maxExtent;
  double _maxExtent;
  set maxExtent(double value) {
    if (_maxExtent == value) {
      return;
    }
    _maxExtent = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    assert(child != null);
    assert(maxExtent >= 0.0);
    child!.layout(
      constraints.copyWith(crossAxisExtent: min(_maxExtent, constraints.crossAxisExtent)),
      parentUsesSize: true,
    );
    final SliverGeometry childLayoutGeometry = child!.geometry!;
    geometry = childLayoutGeometry.copyWith(
      crossAxisExtent: min(_maxExtent, constraints.crossAxisExtent),
    );
  }
}

class RenderSliverSemanticsAnnotations extends RenderProxySliver {
  RenderSliverSemanticsAnnotations({
    RenderSliver? child,
    required SemanticsProperties properties,
    bool container = false,
    bool explicitChildNodes = false,
    bool excludeSemantics = false,
    bool blockUserActions = false,
    TextDirection? textDirection,
  }) : _container = container,
       _explicitChildNodes = explicitChildNodes,
       _excludeSemantics = excludeSemantics,
       _blockUserActions = blockUserActions,
       _textDirection = textDirection,
       _properties = properties,
       super(child) {
    _updateAttributedFields(_properties);
  }

  /// All of the [SemanticsProperties] for this [RenderSemanticsAnnotations].
  SemanticsProperties get properties => _properties;
  SemanticsProperties _properties;
  set properties(SemanticsProperties value) {
    if (_properties == value) {
      return;
    }
    _properties = value;
    _updateAttributedFields(_properties);
    markNeedsSemanticsUpdate();
  }

  /// If 'container' is true, this [RenderObject] will introduce a new
  /// node in the semantics tree. Otherwise, the semantics will be
  /// merged with the semantics of any ancestors.
  ///
  /// Whether descendants of this [RenderObject] can add their semantic information
  /// to the [SemanticsNode] introduced by this configuration is controlled by
  /// [explicitChildNodes].
  bool get container => _container;
  bool _container;
  set container(bool value) {
    if (container == value) {
      return;
    }
    _container = value;
    markNeedsSemanticsUpdate();
  }

  /// Whether descendants of this [RenderObject] are allowed to add semantic
  /// information to the [SemanticsNode] annotated by this widget.
  ///
  /// When set to false descendants are allowed to annotate [SemanticsNode]s of
  /// their parent with the semantic information they want to contribute to the
  /// semantic tree.
  /// When set to true the only way for descendants to contribute semantic
  /// information to the semantic tree is to introduce new explicit
  /// [SemanticsNode]s to the tree.
  ///
  /// This setting is often used in combination with
  /// [SemanticsConfiguration.isSemanticBoundary] to create semantic boundaries
  /// that are either writable or not for children.
  bool get explicitChildNodes => _explicitChildNodes;
  bool _explicitChildNodes;
  set explicitChildNodes(bool value) {
    if (_explicitChildNodes == value) {
      return;
    }
    _explicitChildNodes = value;
    markNeedsSemanticsUpdate();
  }

  /// Whether descendants of this [RenderObject] should have their semantic
  /// information ignored.
  ///
  /// When this flag is set to true, all child semantics nodes are ignored.
  /// This can be used as a convenience for cases where a child is wrapped in
  /// an [ExcludeSemantics] widget and then another [Semantics] widget.
  bool get excludeSemantics => _excludeSemantics;
  bool _excludeSemantics;
  set excludeSemantics(bool value) {
    if (_excludeSemantics == value) {
      return;
    }
    _excludeSemantics = value;
    markNeedsSemanticsUpdate();
  }

  /// Whether to block user interactions for the semantics subtree.
  ///
  /// Setting this true prevents user from activating pointer related
  /// [SemanticsAction]s, such as [SemanticsAction.tap] or
  /// [SemanticsAction.longPress].
  bool get blockUserActions => _blockUserActions;
  bool _blockUserActions;
  set blockUserActions(bool value) {
    if (_blockUserActions == value) {
      return;
    }
    _blockUserActions = value;
    markNeedsSemanticsUpdate();
  }

  void _updateAttributedFields(SemanticsProperties value) {
    _attributedLabel = _effectiveAttributedLabel(value);
    _attributedValue = _effectiveAttributedValue(value);
    _attributedIncreasedValue = _effectiveAttributedIncreasedValue(value);
    _attributedDecreasedValue = _effectiveAttributedDecreasedValue(value);
    _attributedHint = _effectiveAttributedHint(value);
  }

  AttributedString? _effectiveAttributedLabel(SemanticsProperties value) {
    return value.attributedLabel ?? (value.label == null ? null : AttributedString(value.label!));
  }

  AttributedString? _effectiveAttributedValue(SemanticsProperties value) {
    return value.attributedValue ?? (value.value == null ? null : AttributedString(value.value!));
  }

  AttributedString? _effectiveAttributedIncreasedValue(SemanticsProperties value) {
    return value.attributedIncreasedValue ??
        (value.increasedValue == null ? null : AttributedString(value.increasedValue!));
  }

  AttributedString? _effectiveAttributedDecreasedValue(SemanticsProperties value) {
    return properties.attributedDecreasedValue ??
        (value.decreasedValue == null ? null : AttributedString(value.decreasedValue!));
  }

  AttributedString? _effectiveAttributedHint(SemanticsProperties value) {
    return value.attributedHint ?? (value.hint == null ? null : AttributedString(value.hint!));
  }

  AttributedString? _attributedLabel;
  AttributedString? _attributedValue;
  AttributedString? _attributedIncreasedValue;
  AttributedString? _attributedDecreasedValue;
  AttributedString? _attributedHint;

  /// If non-null, sets the [SemanticsNode.textDirection] semantic to the given
  /// value.
  ///
  /// This must not be null if [SemanticsProperties.attributedLabel],
  /// [SemanticsProperties.attributedHint],
  /// [SemanticsProperties.attributedValue],
  /// [SemanticsProperties.attributedIncreasedValue], or
  /// [SemanticsProperties.attributedDecreasedValue] are not null.
  TextDirection? get textDirection => _textDirection;
  TextDirection? _textDirection;
  set textDirection(TextDirection? value) {
    if (textDirection == value) {
      return;
    }
    _textDirection = value;
    markNeedsSemanticsUpdate();
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (excludeSemantics) {
      return;
    }
    super.visitChildrenForSemantics(visitor);
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.isSemanticBoundary = container;
    config.explicitChildNodes = explicitChildNodes;
    config.isBlockingUserActions = blockUserActions;
    assert(
      ((_properties.scopesRoute ?? false) && explicitChildNodes) ||
          !(_properties.scopesRoute ?? false),
      'explicitChildNodes must be set to true if scopes route is true',
    );
    assert(
      !((_properties.toggled ?? false) && (_properties.checked ?? false)),
      'A semantics node cannot be toggled and checked at the same time',
    );

    if (_properties.enabled != null) {
      config.isEnabled = _properties.enabled;
    }
    if (_properties.checked != null) {
      config.isChecked = _properties.checked;
    }
    if (_properties.mixed != null) {
      config.isCheckStateMixed = _properties.mixed;
    }
    if (_properties.toggled != null) {
      config.isToggled = _properties.toggled;
    }
    if (_properties.selected != null) {
      config.isSelected = _properties.selected!;
    }
    if (_properties.button != null) {
      config.isButton = _properties.button!;
    }
    if (_properties.expanded != null) {
      config.isExpanded = _properties.expanded;
    }
    if (_properties.link != null) {
      config.isLink = _properties.link!;
    }
    if (_properties.linkUrl != null) {
      config.linkUrl = _properties.linkUrl;
    }
    if (_properties.slider != null) {
      config.isSlider = _properties.slider!;
    }
    if (_properties.keyboardKey != null) {
      config.isKeyboardKey = _properties.keyboardKey!;
    }
    if (_properties.header != null) {
      config.isHeader = _properties.header!;
    }
    if (_properties.headingLevel != null) {
      config.headingLevel = _properties.headingLevel!;
    }
    if (_properties.textField != null) {
      config.isTextField = _properties.textField!;
    }
    if (_properties.readOnly != null) {
      config.isReadOnly = _properties.readOnly!;
    }
    if (_properties.focusable != null) {
      config.isFocusable = _properties.focusable!;
    }
    if (_properties.focused != null) {
      config.isFocused = _properties.focused!;
    }
    if (_properties.inMutuallyExclusiveGroup != null) {
      config.isInMutuallyExclusiveGroup = _properties.inMutuallyExclusiveGroup!;
    }
    if (_properties.obscured != null) {
      config.isObscured = _properties.obscured!;
    }
    if (_properties.multiline != null) {
      config.isMultiline = _properties.multiline!;
    }
    if (_properties.hidden != null) {
      config.isHidden = _properties.hidden!;
    }
    if (_properties.image != null) {
      config.isImage = _properties.image!;
    }
    if (_properties.isRequired != null) {
      config.isRequired = _properties.isRequired;
    }
    if (_properties.identifier != null) {
      config.identifier = _properties.identifier!;
    }
    if (_attributedLabel != null) {
      config.attributedLabel = _attributedLabel!;
    }
    if (_attributedValue != null) {
      config.attributedValue = _attributedValue!;
    }
    if (_attributedIncreasedValue != null) {
      config.attributedIncreasedValue = _attributedIncreasedValue!;
    }
    if (_attributedDecreasedValue != null) {
      config.attributedDecreasedValue = _attributedDecreasedValue!;
    }
    if (_attributedHint != null) {
      config.attributedHint = _attributedHint!;
    }
    if (_properties.tooltip != null) {
      config.tooltip = _properties.tooltip!;
    }
    if (_properties.hintOverrides != null && _properties.hintOverrides!.isNotEmpty) {
      config.hintOverrides = _properties.hintOverrides;
    }
    if (_properties.scopesRoute != null) {
      config.scopesRoute = _properties.scopesRoute!;
    }
    if (_properties.namesRoute != null) {
      config.namesRoute = _properties.namesRoute!;
    }
    if (_properties.liveRegion != null) {
      config.liveRegion = _properties.liveRegion!;
    }
    if (_properties.maxValueLength != null) {
      config.maxValueLength = _properties.maxValueLength;
    }
    if (_properties.currentValueLength != null) {
      config.currentValueLength = _properties.currentValueLength;
    }
    if (textDirection != null) {
      config.textDirection = textDirection;
    }
    if (_properties.sortKey != null) {
      config.sortKey = _properties.sortKey;
    }
    if (_properties.tagForChildren != null) {
      config.addTagForChildren(_properties.tagForChildren!);
    }
    if (properties.role != null) {
      config.role = _properties.role!;
    }
    if (_properties.controlsNodes != null) {
      config.controlsNodes = _properties.controlsNodes;
    }
    if (config.validationResult != _properties.validationResult) {
      config.validationResult = _properties.validationResult;
    }

    // Registering _perform* as action handlers instead of the user provided
    // ones to ensure that changing a user provided handler from a non-null to
    // another non-null value doesn't require a semantics update.
    if (_properties.onTap != null) {
      config.onTap = _performTap;
    }
    if (_properties.onLongPress != null) {
      config.onLongPress = _performLongPress;
    }
    if (_properties.onDismiss != null) {
      config.onDismiss = _performDismiss;
    }
    if (_properties.onScrollLeft != null) {
      config.onScrollLeft = _performScrollLeft;
    }
    if (_properties.onScrollRight != null) {
      config.onScrollRight = _performScrollRight;
    }
    if (_properties.onScrollUp != null) {
      config.onScrollUp = _performScrollUp;
    }
    if (_properties.onScrollDown != null) {
      config.onScrollDown = _performScrollDown;
    }
    if (_properties.onIncrease != null) {
      config.onIncrease = _performIncrease;
    }
    if (_properties.onDecrease != null) {
      config.onDecrease = _performDecrease;
    }
    if (_properties.onCopy != null) {
      config.onCopy = _performCopy;
    }
    if (_properties.onCut != null) {
      config.onCut = _performCut;
    }
    if (_properties.onPaste != null) {
      config.onPaste = _performPaste;
    }
    if (_properties.onMoveCursorForwardByCharacter != null) {
      config.onMoveCursorForwardByCharacter = _performMoveCursorForwardByCharacter;
    }
    if (_properties.onMoveCursorBackwardByCharacter != null) {
      config.onMoveCursorBackwardByCharacter = _performMoveCursorBackwardByCharacter;
    }
    if (_properties.onMoveCursorForwardByWord != null) {
      config.onMoveCursorForwardByWord = _performMoveCursorForwardByWord;
    }
    if (_properties.onMoveCursorBackwardByWord != null) {
      config.onMoveCursorBackwardByWord = _performMoveCursorBackwardByWord;
    }
    if (_properties.onSetSelection != null) {
      config.onSetSelection = _performSetSelection;
    }
    if (_properties.onSetText != null) {
      config.onSetText = _performSetText;
    }
    if (_properties.onDidGainAccessibilityFocus != null) {
      config.onDidGainAccessibilityFocus = _performDidGainAccessibilityFocus;
    }
    if (_properties.onDidLoseAccessibilityFocus != null) {
      config.onDidLoseAccessibilityFocus = _performDidLoseAccessibilityFocus;
    }
    if (_properties.onFocus != null) {
      config.onFocus = _performFocus;
    }
    if (_properties.customSemanticsActions != null) {
      config.customSemanticsActions = _properties.customSemanticsActions!;
    }
  }

  void _performTap() {
    _properties.onTap?.call();
  }

  void _performLongPress() {
    _properties.onLongPress?.call();
  }

  void _performDismiss() {
    _properties.onDismiss?.call();
  }

  void _performScrollLeft() {
    _properties.onScrollLeft?.call();
  }

  void _performScrollRight() {
    _properties.onScrollRight?.call();
  }

  void _performScrollUp() {
    _properties.onScrollUp?.call();
  }

  void _performScrollDown() {
    _properties.onScrollDown?.call();
  }

  void _performIncrease() {
    _properties.onIncrease?.call();
  }

  void _performDecrease() {
    _properties.onDecrease?.call();
  }

  void _performCopy() {
    _properties.onCopy?.call();
  }

  void _performCut() {
    _properties.onCut?.call();
  }

  void _performPaste() {
    _properties.onPaste?.call();
  }

  void _performMoveCursorForwardByCharacter(bool extendSelection) {
    _properties.onMoveCursorForwardByCharacter?.call(extendSelection);
  }

  void _performMoveCursorBackwardByCharacter(bool extendSelection) {
    _properties.onMoveCursorBackwardByCharacter?.call(extendSelection);
  }

  void _performMoveCursorForwardByWord(bool extendSelection) {
    _properties.onMoveCursorForwardByWord?.call(extendSelection);
  }

  void _performMoveCursorBackwardByWord(bool extendSelection) {
    _properties.onMoveCursorBackwardByWord?.call(extendSelection);
  }

  void _performSetSelection(TextSelection selection) {
    _properties.onSetSelection?.call(selection);
  }

  void _performSetText(String text) {
    _properties.onSetText?.call(text);
  }

  void _performDidGainAccessibilityFocus() {
    _properties.onDidGainAccessibilityFocus?.call();
  }

  void _performDidLoseAccessibilityFocus() {
    _properties.onDidLoseAccessibilityFocus?.call();
  }

  void _performFocus() {
    _properties.onFocus?.call();
  }
}
