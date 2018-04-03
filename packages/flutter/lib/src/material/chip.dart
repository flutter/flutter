// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'debug.dart';
import 'feedback.dart';
import 'icons.dart';
import 'material_localizations.dart';
import 'theme.dart';
import 'tooltip.dart';

// Some design constants
const double _kChipHeight = 32.0;
const double _kDeleteIconSize = 18.0;
const int _kTextLabelAlpha = 0xde;
const int _kDeleteIconAlpha = 0xde;
const int _kContainerAlpha = 0x14;
const double _kEdgePadding = 4.0;

/// A material design chip.
///
/// Chips represent complex entities in small blocks, such as a contact, or a
/// choice.
///
/// Supplying a non-null [onDeleted] callback will cause the chip to include a
/// button for deleting the chip.
///
/// Requires one of its ancestors to be a [Material] widget. The [label]
/// and [border] arguments must not be null.
///
/// ## Sample code
///
/// ```dart
/// new Chip(
///   avatar: new CircleAvatar(
///     backgroundColor: Colors.grey.shade800,
///     child: new Text('AB'),
///   ),
///   label: new Text('Aaron Burr'),
/// )
/// ```
///
/// See also:
///
///  * [CircleAvatar], which shows images or initials of people.
///  * <https://material.google.com/components/chips.html>
class Chip extends StatelessWidget {
  /// Creates a material design chip.
  ///
  /// The [label] and [border] arguments may not be null.
  const Chip({
    Key key,
    this.avatar,
    this.deleteIcon,
    @required this.label,
    this.onDeleted,
    this.labelStyle,
    this.deleteButtonTooltipMessage,
    this.backgroundColor,
    this.deleteIconColor,
    this.border: const StadiumBorder(),
  })  : assert(label != null),
        assert(border != null),
        super(key: key);

  /// A widget to display prior to the chip's label.
  ///
  /// Typically a [CircleAvatar] widget.
  final Widget avatar;

  /// The icon displayed when [onDeleted] is non-null.
  ///
  /// This has no effect when [onDeleted] is null since no delete icon will be
  /// shown.
  ///
  /// Defaults to an [Icon] widget containing [Icons.cancel].
  final Widget deleteIcon;

  /// The primary content of the chip.
  ///
  /// Typically a [Text] widget.
  final Widget label;

  /// Called when the user taps the delete button to delete the chip.
  ///
  /// This has no effect when [deleteIcon] is null since no delete icon will be
  /// shown.
  final VoidCallback onDeleted;

  /// The style to be applied to the chip's label.
  ///
  /// This only has effect on widgets that respect the [DefaultTextStyle],
  /// such as [Text].
  final TextStyle labelStyle;

  /// Color to be used for the chip's background, the default is based on the
  /// ambient [IconTheme].
  ///
  /// This color is used as the background of the container that will hold the
  /// widget's label.
  final Color backgroundColor;

  /// The border to draw around the chip.
  ///
  /// Defaults to a [StadiumBorder].
  final ShapeBorder border;

  /// Color for delete icon. The default is based on the ambient [IconTheme].
  final Color deleteIconColor;

  /// Message to be used for the chip delete button's tooltip.
  final String deleteButtonTooltipMessage;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    final ThemeData theme = Theme.of(context);
    return new DefaultTextStyle(
      overflow: TextOverflow.fade,
      textAlign: TextAlign.start,
      maxLines: 1,
      softWrap: false,
      style: labelStyle ??
          theme.textTheme.body2.copyWith(
            color: theme.primaryColorDark.withAlpha(_kTextLabelAlpha),
          ),
      child: new _ChipRenderWidget(
        theme: new _ChipRenderTheme(
          label: label,
          avatar: avatar,
          deleteIcon: onDeleted == null
              ? null
              : new Tooltip(
                  message: deleteButtonTooltipMessage ?? MaterialLocalizations.of(context).deleteButtonTooltip,
                  child: new IconTheme(
                    data: theme.iconTheme.copyWith(
                      color: deleteIconColor ?? theme.iconTheme.color.withAlpha(_kDeleteIconAlpha),
                    ),
                    child: deleteIcon ?? const Icon(Icons.cancel, size: _kDeleteIconSize),
                  ),
                ),
          container: new Container(
            decoration: new ShapeDecoration(
              shape: border,
              color: backgroundColor ?? theme.primaryColorDark.withAlpha(_kContainerAlpha),
            ),
          ),
          padding: const EdgeInsets.all(_kEdgePadding),
          labelPadding: const EdgeInsets.symmetric(horizontal: _kEdgePadding),
        ),
        key: key,
        onDeleted: Feedback.wrapForTap(onDeleted, context),
      ),
    );
  }
}

class _ChipRenderWidget extends RenderObjectWidget {
  const _ChipRenderWidget({
    Key key,
    @required this.theme,
    this.onDeleted,
  })  : assert(theme != null),
        super(key: key);

  final _ChipRenderTheme theme;
  final VoidCallback onDeleted;

  @override
  _RenderChipElement createElement() => new _RenderChipElement(this);

  @override
  void updateRenderObject(BuildContext context, _RenderChip renderObject) {
    renderObject
      ..theme = theme
      ..textDirection = Directionality.of(context)
      ..onDeleted = onDeleted;
  }

  @override
  RenderObject createRenderObject(BuildContext context) {
    return new _RenderChip(
      theme: theme,
      textDirection: Directionality.of(context),
      onDeleted: onDeleted,
    );
  }
}

enum _ChipSlot {
  label,
  avatar,
  deleteIcon,
  container,
}

class _RenderChipElement extends RenderObjectElement {
  _RenderChipElement(_ChipRenderWidget chip) : super(chip);

  final Map<_ChipSlot, Element> slotToChild = <_ChipSlot, Element>{};
  final Map<Element, _ChipSlot> childToSlot = <Element, _ChipSlot>{};

  @override
  _ChipRenderWidget get widget => super.widget;

  @override
  _RenderChip get renderObject => super.renderObject;

  @override
  void visitChildren(ElementVisitor visitor) {
    slotToChild.values.forEach(visitor);
  }

  @override
  void forgetChild(Element child) {
    assert(slotToChild.values.contains(child));
    assert(childToSlot.keys.contains(child));
    final _ChipSlot slot = childToSlot[child];
    childToSlot.remove(child);
    slotToChild.remove(slot);
  }

  void _mountChild(Widget widget, _ChipSlot slot) {
    final Element oldChild = slotToChild[slot];
    final Element newChild = updateChild(oldChild, widget, slot);
    if (oldChild != null) {
      slotToChild.remove(slot);
      childToSlot.remove(oldChild);
    }
    if (newChild != null) {
      slotToChild[slot] = newChild;
      childToSlot[newChild] = slot;
    }
  }

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _mountChild(widget.theme.avatar, _ChipSlot.avatar);
    _mountChild(widget.theme.deleteIcon, _ChipSlot.deleteIcon);
    _mountChild(widget.theme.label, _ChipSlot.label);
    _mountChild(widget.theme.container, _ChipSlot.container);
  }

  void _updateChild(Widget widget, _ChipSlot slot) {
    final Element oldChild = slotToChild[slot];
    final Element newChild = updateChild(oldChild, widget, slot);
    if (oldChild != null) {
      childToSlot.remove(oldChild);
      slotToChild.remove(slot);
    }
    if (newChild != null) {
      slotToChild[slot] = newChild;
      childToSlot[newChild] = slot;
    }
  }

  @override
  void update(_ChipRenderWidget newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _updateChild(widget.theme.label, _ChipSlot.label);
    _updateChild(widget.theme.avatar, _ChipSlot.avatar);
    _updateChild(widget.theme.deleteIcon, _ChipSlot.deleteIcon);
    _updateChild(widget.theme.container, _ChipSlot.container);
  }

  void _updateRenderObject(RenderObject child, _ChipSlot slot) {
    switch (slot) {
      case _ChipSlot.avatar:
        renderObject.avatar = child;
        break;
      case _ChipSlot.label:
        renderObject.label = child;
        break;
      case _ChipSlot.deleteIcon:
        renderObject.deleteIcon = child;
        break;
      case _ChipSlot.container:
        renderObject.container = child;
        break;
    }
  }

  @override
  void insertChildRenderObject(RenderObject child, dynamic slotValue) {
    assert(child is RenderBox);
    assert(slotValue is _ChipSlot);
    final _ChipSlot slot = slotValue;
    _updateRenderObject(child, slot);
    assert(renderObject.childToSlot.keys.contains(child));
    assert(renderObject.slotToChild.keys.contains(slot));
  }

  @override
  void removeChildRenderObject(RenderObject child) {
    assert(child is RenderBox);
    assert(renderObject.childToSlot.keys.contains(child));
    _updateRenderObject(null, renderObject.childToSlot[child]);
    assert(!renderObject.childToSlot.keys.contains(child));
    assert(!renderObject.slotToChild.keys.contains(slot));
  }

  @override
  void moveChildRenderObject(RenderObject child, dynamic slotValue) {
    assert(false, 'not reachable');
  }
}

class _ChipRenderTheme {
  const _ChipRenderTheme({
    @required this.avatar,
    @required this.label,
    @required this.deleteIcon,
    @required this.container,
    @required this.padding,
    @required this.labelPadding,
  });

  final Widget avatar;
  final Widget label;
  final Widget deleteIcon;
  final Widget container;
  final EdgeInsets padding;
  final EdgeInsets labelPadding;

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final _ChipRenderTheme typedOther = other;
    return typedOther.avatar == avatar &&
        typedOther.label == label &&
        typedOther.deleteIcon == deleteIcon &&
        typedOther.container == container &&
        typedOther.padding == padding &&
        typedOther.labelPadding == labelPadding;
  }

  @override
  int get hashCode {
    return hashValues(
      avatar,
      label,
      deleteIcon,
      container,
      padding,
      labelPadding,
    );
  }
}

class _RenderChip extends RenderBox {
  _RenderChip({
    @required _ChipRenderTheme theme,
    @required TextDirection textDirection,
    this.onDeleted,
  })  : assert(theme != null),
        assert(textDirection != null),
        _theme = theme,
        _textDirection = textDirection {
    _tap = new TapGestureRecognizer(debugOwner: this)
      ..onTapDown = _handleTapDown
      ..onTap = _handleTap;
  }

  // Set this to true to have outlines of the tap targets drawn over
  // the chip.  This should never be checked in while set to 'true'.
  static const bool _debugShowTapTargetOutlines = false;
  static const EdgeInsets _iconPadding = const EdgeInsets.all(_kEdgePadding);

  final Map<_ChipSlot, RenderBox> slotToChild = <_ChipSlot, RenderBox>{};
  final Map<RenderBox, _ChipSlot> childToSlot = <RenderBox, _ChipSlot>{};

  TapGestureRecognizer _tap;

  VoidCallback onDeleted;
  Rect _deleteButtonRect;
  Rect _actionRect;
  Offset _tapDownLocation;

  RenderBox _updateChild(RenderBox oldChild, RenderBox newChild, _ChipSlot slot) {
    if (oldChild != null) {
      dropChild(oldChild);
      childToSlot.remove(oldChild);
      slotToChild.remove(slot);
    }
    if (newChild != null) {
      childToSlot[newChild] = slot;
      slotToChild[slot] = newChild;
      adoptChild(newChild);
    }
    return newChild;
  }

  RenderBox _avatar;
  RenderBox get avatar => _avatar;
  set avatar(RenderBox value) {
    _avatar = _updateChild(_avatar, value, _ChipSlot.avatar);
  }

  RenderBox _deleteIcon;
  RenderBox get deleteIcon => _deleteIcon;
  set deleteIcon(RenderBox value) {
    _deleteIcon = _updateChild(_deleteIcon, value, _ChipSlot.deleteIcon);
  }

  RenderBox _label;
  RenderBox get label => _label;
  set label(RenderBox value) {
    _label = _updateChild(_label, value, _ChipSlot.label);
  }

  RenderBox _container;
  RenderBox get container => _container;
  set container(RenderBox value) {
    _container = _updateChild(_container, value, _ChipSlot.container);
  }

  _ChipRenderTheme get theme => _theme;
  _ChipRenderTheme _theme;
  set theme(_ChipRenderTheme value) {
    if (_theme == value) {
      return;
    }
    _theme = value;
    markNeedsLayout();
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
    markNeedsLayout();
  }

  // The returned list is ordered for hit testing.
  Iterable<RenderBox> get _children sync* {
    if (avatar != null) {
      yield avatar;
    }
    if (label != null) {
      yield label;
    }
    if (deleteIcon != null) {
      yield deleteIcon;
    }
    if (container != null) {
      yield container;
    }
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent && deleteIcon != null) {
      _tap.addPointer(event);
    }
  }

  void _handleTapDown(TapDownDetails details) {
    if (deleteIcon != null) {
      _tapDownLocation = globalToLocal(details.globalPosition);
    }
  }

  void _handleTap() {
    if (_tapDownLocation == null) {
      return;
    }
    if (deleteIcon != null && onDeleted != null && _deleteButtonRect.contains(_tapDownLocation)) {
      onDeleted();
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    for (RenderBox child in _children) {
      child.attach(owner);
    }
  }

  @override
  void detach() {
    super.detach();
    for (RenderBox child in _children) {
      child.detach();
    }
  }

  @override
  void redepthChildren() {
    _children.forEach(redepthChild);
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    _children.forEach(visitor);
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final List<DiagnosticsNode> value = <DiagnosticsNode>[];
    void add(RenderBox child, String name) {
      if (child != null) {
        value.add(child.toDiagnosticsNode(name: name));
      }
    }

    add(avatar, 'avatar');
    add(label, 'label');
    add(deleteIcon, 'deleteIcon');
    add(container, 'container');
    return value;
  }

  @override
  bool get sizedByParent => false;

  static double _minWidth(RenderBox box, double height) {
    return box == null ? 0.0 : box.getMinIntrinsicWidth(height);
  }

  static double _maxWidth(RenderBox box, double height) {
    return box == null ? 0.0 : box.getMaxIntrinsicWidth(height);
  }

  static double _minHeight(RenderBox box, double width) {
    return box == null ? 0.0 : box.getMinIntrinsicWidth(width);
  }

  static Size _boxSize(RenderBox box) => box == null ? Size.zero : box.size;

  static BoxParentData _boxParentData(RenderBox box) => box.parentData;

  @override
  double computeMinIntrinsicWidth(double height) {
    // The overall padding isn't affected by missing avatar or delete icon
    // because we add the padding regardless to give extra padding for the label
    // when they're missing.
    final double overallPadding = theme.labelPadding.horizontal + _iconPadding.horizontal * 2.0;
    return overallPadding + _minWidth(avatar, height) + _minWidth(label, height) + _minWidth(deleteIcon, height);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    // The overall padding isn't affected by missing avatar or delete icon
    // because we add the padding regardless to give extra padding for the label
    // when they're missing.
    final double overallPadding = theme.labelPadding.horizontal + _iconPadding.horizontal * 2.0;
    return overallPadding + _maxWidth(avatar, height) + _maxWidth(label, height) + _maxWidth(deleteIcon, height);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    // This widget is sized to the height of the label only, as long as it's
    // larger than _kChipHeight.  The other widgets are sized to match the
    // label.
    return math.max(_kChipHeight, theme.labelPadding.vertical + _minHeight(label, width));
  }

  @override
  double computeMaxIntrinsicHeight(double width) => computeMinIntrinsicHeight(width);

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    // The baseline of this widget is the baseline of the label.
    return label.computeDistanceToActualBaseline(baseline);
  }

  @override
  void performLayout() {
    double overallHeight = _kChipHeight;
    if (label != null) {
      label.layout(constraints.loosen(), parentUsesSize: true);
      // Now that we know the height, we can determine how much to shrink the
      // constraints by for the "real" layout. Ignored if the constraints are
      // infinite.
      overallHeight = math.max(overallHeight, _boxSize(label).height);
      if (constraints.maxWidth.isFinite) {
        final double allPadding = _iconPadding.horizontal * 2.0 + theme.labelPadding.horizontal;
        final double iconSizes = (avatar != null ? overallHeight - _iconPadding.vertical : 0.0)
            + (deleteIcon != null ? overallHeight - _iconPadding.vertical : 0.0);
        label.layout(
          constraints.loosen().copyWith(
                maxWidth: math.max(0.0, constraints.maxWidth - iconSizes - allPadding),
              ),
          parentUsesSize: true,
        );
      }
    }
    final double labelWidth = theme.labelPadding.horizontal + _boxSize(label).width;
    final double iconSize = overallHeight - _iconPadding.vertical;
    final BoxConstraints iconConstraints = new BoxConstraints.tightFor(
      width: iconSize,
      height: iconSize,
    );
    double avatarWidth = _iconPadding.horizontal;
    if (avatar != null) {
      avatar.layout(iconConstraints, parentUsesSize: true);
      avatarWidth += _boxSize(avatar).width;
    }
    double deleteIconWidth = _iconPadding.horizontal;
    if (deleteIcon != null) {
      deleteIcon.layout(iconConstraints, parentUsesSize: true);
      deleteIconWidth += _boxSize(deleteIcon).width;
    }
    final double overallWidth = avatarWidth + labelWidth + deleteIconWidth;

    if (container != null) {
      final BoxConstraints containerConstraints = new BoxConstraints.tightFor(
        height: overallHeight,
        width: overallWidth,
      );
      container.layout(containerConstraints, parentUsesSize: true);
      _boxParentData(container).offset = Offset.zero;
    }

    double centerLayout(RenderBox box, double x) {
      _boxParentData(box).offset = new Offset(x, (overallHeight - box.size.height) / 2.0);
      return box.size.width;
    }

    const double left = 0.0;
    final double right = overallWidth;

    switch (textDirection) {
      case TextDirection.rtl:
        double start = right - _kEdgePadding;
        if (avatar != null) {
          start -= centerLayout(avatar, start - avatar.size.width);
        }
        start -= _iconPadding.left + theme.labelPadding.right;
        if (label != null) {
          start -= centerLayout(label, start - label.size.width);
        }
        start -= _iconPadding.right + theme.labelPadding.left;
        double deleteButtonWidth = 0.0;
        if (deleteIcon != null) {
          _deleteButtonRect = new Rect.fromLTWH(
            0.0,
            0.0,
            iconSize + _iconPadding.horizontal,
            iconSize + _iconPadding.vertical,
          );
          deleteButtonWidth = _deleteButtonRect.width;
          start -= centerLayout(deleteIcon, start - deleteIcon.size.width);
        }
        if (avatar != null || label != null) {
          _actionRect = new Rect.fromLTWH(
            deleteButtonWidth,
            0.0,
            overallWidth - deleteButtonWidth,
            overallHeight,
          );
        }
        break;
      case TextDirection.ltr:
        double start = left + _kEdgePadding;
        if (avatar != null) {
          start += centerLayout(avatar, start);
        }
        start += _iconPadding.right + theme.labelPadding.left;
        if (label != null) {
          start += centerLayout(label, start);
        }
        start += _iconPadding.left + theme.labelPadding.right;
        if (avatar != null || label != null) {
          _actionRect = new Rect.fromLTWH(
            0.0,
            0.0,
            deleteIcon != null ? (start - _kEdgePadding) : overallWidth,
            overallHeight,
          );
        }
        if (deleteIcon != null) {
          _deleteButtonRect = new Rect.fromLTWH(
            start - _kEdgePadding,
            0.0,
            iconSize + _iconPadding.horizontal,
            iconSize + _iconPadding.vertical,
          );
          centerLayout(deleteIcon, start);
        }
        break;
    }

    size = constraints.constrain(new Size(overallWidth, overallHeight));
    assert(size.width == constraints.constrainWidth(overallWidth));
    assert(size.height == constraints.constrainHeight(overallHeight));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    void doPaint(RenderBox child) {
      if (child != null) {
        context.paintChild(child, _boxParentData(child).offset + offset);
      }
    }

    doPaint(container);
    doPaint(avatar);
    doPaint(deleteIcon);
    doPaint(label);
  }

  @override
  void debugPaint(PaintingContext context, Offset offset) {
    assert(!_debugShowTapTargetOutlines ||
        () {
          // Draws a rect around the tap targets to help with visualizing where
          // they really are.
          final Paint outlinePaint = new Paint()
            ..color = const Color(0xff800000)
            ..strokeWidth = 1.0
            ..style = PaintingStyle.stroke;
          if (deleteIcon != null) {
            context.canvas.drawRect(_deleteButtonRect.shift(offset), outlinePaint);
          }
          context.canvas.drawRect(
            _actionRect.shift(offset),
            outlinePaint..color = const Color(0xff008000),
          );
          return true;
        }());
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  bool hitTestChildren(HitTestResult result, {@required Offset position}) {
    assert(position != null);
    for (RenderBox child in _children) {
      if (child.hasSize && child.hitTest(result, position: position - _boxParentData(child).offset)) {
        return true;
      }
    }
    return false;
  }
}
