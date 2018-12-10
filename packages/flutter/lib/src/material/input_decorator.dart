// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'input_border.dart';
import 'theme.dart';

const Duration _kTransitionDuration = Duration(milliseconds: 200);
const Curve _kTransitionCurve = Curves.fastOutSlowIn;

// Defines the gap in the InputDecorator's outline border where the
// floating label will appear.
class _InputBorderGap extends ChangeNotifier {
  double _start;
  double get start => _start;
  set start(double value) {
    if (value != _start) {
      _start = value;
      notifyListeners();
    }
  }

  double _extent = 0.0;
  double get extent => _extent;
  set extent(double value) {
    if (value != _extent) {
      _extent = value;
      notifyListeners();
    }
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (runtimeType != other.runtimeType)
      return false;
    final _InputBorderGap typedOther = other;
    return typedOther.start == start && typedOther.extent == extent;
  }

  @override
  int get hashCode => hashValues(start, extent);
}

// Used to interpolate between two InputBorders.
class _InputBorderTween extends Tween<InputBorder> {
  _InputBorderTween({InputBorder begin, InputBorder end}) : super(begin: begin, end: end);

  @override
  InputBorder lerp(double t) => ShapeBorder.lerp(begin, end, t);
}

// Passes the _InputBorderGap parameters along to an InputBorder's paint method.
class _InputBorderPainter extends CustomPainter {
  _InputBorderPainter({
    Listenable repaint,
    this.borderAnimation,
    this.border,
    this.gapAnimation,
    this.gap,
    this.textDirection,
    this.fillColor,
  }) : super(repaint: repaint);

  final Animation<double> borderAnimation;
  final _InputBorderTween border;
  final Animation<double> gapAnimation;
  final _InputBorderGap gap;
  final TextDirection textDirection;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final InputBorder borderValue = border.evaluate(borderAnimation);
    final Rect canvasRect = Offset.zero & size;

    if (fillColor.alpha > 0) {
      canvas.drawPath(
        borderValue.getOuterPath(canvasRect, textDirection: textDirection),
        Paint()
          ..color = fillColor
          ..style = PaintingStyle.fill,
      );
    }

    borderValue.paint(
      canvas,
      canvasRect,
      gapStart: gap.start,
      gapExtent: gap.extent,
      gapPercentage: gapAnimation.value,
      textDirection: textDirection,
    );
  }

  @override
  bool shouldRepaint(_InputBorderPainter oldPainter) {
    return borderAnimation != oldPainter.borderAnimation
        || gapAnimation != oldPainter.gapAnimation
        || border != oldPainter.border
        || gap != oldPainter.gap
        || textDirection != oldPainter.textDirection;
  }
}

// An analog of AnimatedContainer, which can animate its shaped border, for
// _InputBorder. This specialized animated container is needed because the
// _InputBorderGap, which is computed at layout time, is required by the
// _InputBorder's paint method.
class _BorderContainer extends StatefulWidget {
  const _BorderContainer({
    Key key,
    @required this.border,
    @required this.gap,
    @required this.gapAnimation,
    @required this.fillColor,
    this.child,
  }) : assert(border != null),
       assert(gap != null),
       assert(fillColor != null),
       super(key: key);

  final InputBorder border;
  final _InputBorderGap gap;
  final Animation<double> gapAnimation;
  final Color fillColor;
  final Widget child;

  @override
  _BorderContainerState createState() => _BorderContainerState();
}

class _BorderContainerState extends State<_BorderContainer> with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _borderAnimation;
  _InputBorderTween _border;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: _kTransitionDuration,
      vsync: this,
    );
    _borderAnimation = CurvedAnimation(
      parent: _controller,
      curve: _kTransitionCurve,
    );
    _border = _InputBorderTween(
      begin: widget.border,
      end: widget.border,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_BorderContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.border != oldWidget.border) {
      _border = _InputBorderTween(
        begin: oldWidget.border,
        end: widget.border,
      );
      _controller
        ..value = 0.0
        ..forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _InputBorderPainter(
        repaint: Listenable.merge(<Listenable>[_borderAnimation, widget.gap]),
        borderAnimation: _borderAnimation,
        border: _border,
        gapAnimation: widget.gapAnimation,
        gap: widget.gap,
        textDirection: Directionality.of(context),
        fillColor: widget.fillColor,
      ),
      child: widget.child,
    );
  }
}

// Used to "shake" the floating label to the left to the left and right
// when the errorText first appears.
class _Shaker extends AnimatedWidget {
  const _Shaker({
    Key key,
    Animation<double> animation,
    this.child,
  }) : super(key: key, listenable: animation);

  final Widget child;

  Animation<double> get animation => listenable;

  double get translateX {
    const double shakeDelta = 4.0;
    final double t = animation.value;
    if (t <= 0.25)
      return -t * shakeDelta;
    else if (t < 0.75)
      return (t - 0.5) * shakeDelta;
    else
      return (1.0 - t) * 4.0 * shakeDelta;
  }

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: Matrix4.translationValues(translateX, 0.0, 0.0),
      child: child,
    );
  }
}

// Display the helper and error text. When the error text appears
// it fades and the helper text fades out. The error text also
// slides upwards a little when it first appears.
class _HelperError extends StatefulWidget {
  const _HelperError({
    Key key,
    this.textAlign,
    this.helperText,
    this.helperStyle,
    this.errorText,
    this.errorStyle,
    this.errorMaxLines,
  }) : super(key: key);

  final TextAlign textAlign;
  final String helperText;
  final TextStyle helperStyle;
  final String errorText;
  final TextStyle errorStyle;
  final int errorMaxLines;

  @override
  _HelperErrorState createState() => _HelperErrorState();
}

class _HelperErrorState extends State<_HelperError> with SingleTickerProviderStateMixin {
  // If the height of this widget and the counter are zero ("empty") at
  // layout time, no space is allocated for the subtext.
  static const Widget empty = SizedBox();

  AnimationController _controller;
  Widget _helper;
  Widget _error;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: _kTransitionDuration,
      vsync: this,
    );
    if (widget.errorText != null) {
      _error = _buildError();
      _controller.value = 1.0;
    } else if (widget.helperText != null) {
      _helper = _buildHelper();
    }
    _controller.addListener(_handleChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleChange() {
    setState(() {
      // The _controller's value has changed.
    });
  }

  @override
  void didUpdateWidget(_HelperError old) {
    super.didUpdateWidget(old);

    final String newErrorText = widget.errorText;
    final String newHelperText = widget.helperText;
    final String oldErrorText = old.errorText;
    final String oldHelperText = old.helperText;

    final bool errorTextStateChanged = (newErrorText != null) != (oldErrorText != null);
    final bool helperTextStateChanged = newErrorText == null && (newHelperText != null) != (oldHelperText != null);

    if (errorTextStateChanged || helperTextStateChanged) {
      if (newErrorText != null) {
        _error = _buildError();
        _controller.forward();
      } else if (newHelperText != null) {
        _helper = _buildHelper();
        _controller.reverse();
      } else {
        _controller.reverse();
      }
    }
  }

  Widget _buildHelper() {
    assert(widget.helperText != null);
    return Semantics(
      container: true,
      child: Opacity(
        opacity: 1.0 - _controller.value,
        child: Text(
          widget.helperText,
          style: widget.helperStyle,
          textAlign: widget.textAlign,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildError() {
    assert(widget.errorText != null);
    return Semantics(
      container: true,
      liveRegion: true,
      child: Opacity(
        opacity: _controller.value,
        child: FractionalTranslation(
          translation: Tween<Offset>(
            begin: const Offset(0.0, -0.25),
            end: const Offset(0.0, 0.0),
          ).evaluate(_controller.view),
          child: Text(
            widget.errorText,
            style: widget.errorStyle,
            textAlign: widget.textAlign,
            overflow: TextOverflow.ellipsis,
            maxLines: widget.errorMaxLines,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isDismissed) {
      _error = null;
      if (widget.helperText != null) {
        return _helper = _buildHelper();
      } else {
        _helper = null;
        return empty;
      }
    }

    if (_controller.isCompleted) {
      _helper = null;
      if (widget.errorText != null) {
        return _error = _buildError();
      } else {
        _error = null;
        return empty;
      }
    }

    if (_helper == null && widget.errorText != null)
      return _buildError();

    if (_error == null && widget.helperText != null)
      return _buildHelper();

    if (widget.errorText != null) {
      return Stack(
        children: <Widget>[
          Opacity(
            opacity: 1.0 - _controller.value,
            child: _helper,
          ),
          _buildError(),
        ],
      );
    }

    if (widget.helperText != null) {
      return Stack(
        children: <Widget>[
          _buildHelper(),
          Opacity(
            opacity: _controller.value,
            child: _error,
          ),
        ],
      );
    }

    return empty;
  }
}

// Identifies the children of a _RenderDecorationElement.
enum _DecorationSlot {
  icon,
  input,
  label,
  hint,
  prefix,
  suffix,
  prefixIcon,
  suffixIcon,
  helperError,
  counter,
  container,
}

// An analog of InputDecoration for the _Decorator widget.
class _Decoration {
  const _Decoration({
    @required this.contentPadding,
    @required this.isCollapsed,
    @required this.floatingLabelHeight,
    @required this.floatingLabelProgress,
    this.border,
    this.borderGap,
    this.icon,
    this.input,
    this.label,
    this.hint,
    this.prefix,
    this.suffix,
    this.prefixIcon,
    this.suffixIcon,
    this.helperError,
    this.counter,
    this.container,
  }) : assert(contentPadding != null),
       assert(isCollapsed != null),
       assert(floatingLabelHeight != null),
       assert(floatingLabelProgress != null);

  final EdgeInsetsGeometry contentPadding;
  final bool isCollapsed;
  final double floatingLabelHeight;
  final double floatingLabelProgress;
  final InputBorder border;
  final _InputBorderGap borderGap;
  final Widget icon;
  final Widget input;
  final Widget label;
  final Widget hint;
  final Widget prefix;
  final Widget suffix;
  final Widget prefixIcon;
  final Widget suffixIcon;
  final Widget helperError;
  final Widget counter;
  final Widget container;

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    final _Decoration typedOther = other;
    return typedOther.contentPadding == contentPadding
        && typedOther.floatingLabelHeight == floatingLabelHeight
        && typedOther.floatingLabelProgress == floatingLabelProgress
        && typedOther.border == border
        && typedOther.borderGap == borderGap
        && typedOther.icon == icon
        && typedOther.input == input
        && typedOther.label == label
        && typedOther.hint == hint
        && typedOther.prefix == prefix
        && typedOther.suffix == suffix
        && typedOther.prefixIcon == prefixIcon
        && typedOther.suffixIcon == suffixIcon
        && typedOther.helperError == helperError
        && typedOther.counter == counter
        && typedOther.container == container;
  }

  @override
  int get hashCode {
    return hashValues(
      contentPadding,
      floatingLabelHeight,
      floatingLabelProgress,
      border,
      borderGap,
      icon,
      input,
      label,
      hint,
      prefix,
      suffix,
      prefixIcon,
      suffixIcon,
      helperError,
      counter,
      container,
    );
  }
}

// A container for the layout values computed by _RenderDecoration._layout.
// These values are used by _RenderDecoration.performLayout to position
// all of the renderer children of a _RenderDecoration.
class _RenderDecorationLayout {
  const _RenderDecorationLayout({
    this.boxToBaseline,
    this.inputBaseline, // for InputBorderType.underline
    this.outlineBaseline, // for InputBorderType.outline
    this.subtextBaseline,
    this.containerHeight,
    this.subtextHeight,
  });

  final Map<RenderBox, double> boxToBaseline;
  final double inputBaseline;
  final double outlineBaseline;
  final double subtextBaseline; // helper/error counter
  final double containerHeight;
  final double subtextHeight;
}

// The workhorse: layout and paint a _Decorator widget's _Decoration.
class _RenderDecoration extends RenderBox {
  _RenderDecoration({
    @required _Decoration decoration,
    @required TextDirection textDirection,
    @required TextBaseline textBaseline,
    @required bool isFocused,
  }) : assert(decoration != null),
       assert(textDirection != null),
       assert(textBaseline != null),
       _decoration = decoration,
       _textDirection = textDirection,
       _textBaseline = textBaseline,
       _isFocused = isFocused;

  final Map<_DecorationSlot, RenderBox> slotToChild = <_DecorationSlot, RenderBox>{};
  final Map<RenderBox, _DecorationSlot> childToSlot = <RenderBox, _DecorationSlot>{};

  RenderBox _updateChild(RenderBox oldChild, RenderBox newChild, _DecorationSlot slot) {
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

  RenderBox _icon;
  RenderBox get icon => _icon;
  set icon(RenderBox value) {
    _icon = _updateChild(_icon, value, _DecorationSlot.icon);
  }

  RenderBox _input;
  RenderBox get input => _input;
  set input(RenderBox value) {
    _input = _updateChild(_input, value, _DecorationSlot.input);
  }

  RenderBox _label;
  RenderBox get label => _label;
  set label(RenderBox value) {
    _label = _updateChild(_label, value, _DecorationSlot.label);
  }

  RenderBox _hint;
  RenderBox get hint => _hint;
  set hint(RenderBox value) {
    _hint = _updateChild(_hint, value, _DecorationSlot.hint);
  }

  RenderBox _prefix;
  RenderBox get prefix => _prefix;
  set prefix(RenderBox value) {
    _prefix = _updateChild(_prefix, value, _DecorationSlot.prefix);
  }

  RenderBox _suffix;
  RenderBox get suffix => _suffix;
  set suffix(RenderBox value) {
    _suffix = _updateChild(_suffix, value, _DecorationSlot.suffix);
  }

  RenderBox _prefixIcon;
  RenderBox get prefixIcon => _prefixIcon;
  set prefixIcon(RenderBox value) {
    _prefixIcon = _updateChild(_prefixIcon, value, _DecorationSlot.prefixIcon);
  }

  RenderBox _suffixIcon;
  RenderBox get suffixIcon => _suffixIcon;
  set suffixIcon(RenderBox value) {
    _suffixIcon = _updateChild(_suffixIcon, value, _DecorationSlot.suffixIcon);
  }

  RenderBox _helperError;
  RenderBox get helperError => _helperError;
  set helperError(RenderBox value) {
    _helperError = _updateChild(_helperError, value, _DecorationSlot.helperError);
  }

  RenderBox _counter;
  RenderBox get counter => _counter;
  set counter(RenderBox value) {
    _counter = _updateChild(_counter, value, _DecorationSlot.counter);
  }

  RenderBox _container;
  RenderBox get container => _container;
  set container(RenderBox value) {
    _container = _updateChild(_container, value, _DecorationSlot.container);
  }

  // The returned list is ordered for hit testing.
  Iterable<RenderBox> get _children sync *{
    if (icon != null)
      yield icon;
    if (input != null)
      yield input;
    if (prefixIcon != null)
      yield prefixIcon;
    if (suffixIcon != null)
      yield suffixIcon;
    if (prefix != null)
      yield prefix;
    if (suffix != null)
      yield suffix;
    if (label != null)
      yield label;
    if (hint != null)
      yield hint;
    if (helperError != null)
      yield helperError;
    if (counter != null)
      yield counter;
    if (container != null)
      yield container;
  }

  _Decoration get decoration => _decoration;
  _Decoration _decoration;
  set decoration(_Decoration value) {
    assert(value != null);
    if (_decoration == value)
      return;
    _decoration = value;
    markNeedsLayout();
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    assert(value != null);
    if (_textDirection == value)
      return;
    _textDirection = value;
    markNeedsLayout();
  }

  TextBaseline get textBaseline => _textBaseline;
  TextBaseline _textBaseline;
  set textBaseline(TextBaseline value) {
    assert(value != null);
    if (_textBaseline == value)
      return;
    _textBaseline = value;
    markNeedsLayout();
  }

  bool get isFocused => _isFocused;
  bool _isFocused;
  set isFocused(bool value) {
    assert(value != null);
    if (_isFocused == value)
      return;
    _isFocused = value;
    markNeedsSemanticsUpdate();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    for (RenderBox child in _children)
      child.attach(owner);
  }

  @override
  void detach() {
    super.detach();
    for (RenderBox child in _children)
      child.detach();
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
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (icon != null)
      visitor(icon);
    if (prefix != null)
      visitor(prefix);
    if (prefixIcon != null)
      visitor(prefixIcon);
    if (isFocused && hint != null) {
      // Bypass opacity to always read hint when focused. This prevents the
      // label from changing when text is entered.
      final RenderProxyBox typedHint = hint;
      visitor(typedHint.child);
    } else if (!isFocused && label != null)
      visitor(label);
    if (input != null)
      visitor(input);
    if (suffixIcon != null)
      visitor(suffixIcon);
    if (suffix != null)
      visitor(suffix);
    if (container != null)
      visitor(container);
    if (helperError != null)
      visitor(helperError);
    if (counter != null)
      visitor(counter);
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final List<DiagnosticsNode> value = <DiagnosticsNode>[];
    void add(RenderBox child, String name) {
      if (child != null)
        value.add(child.toDiagnosticsNode(name: name));
    }
    add(icon, 'icon');
    add(input, 'input');
    add(label, 'label');
    add(hint, 'hint');
    add(prefix, 'prefix');
    add(suffix, 'suffix');
    add(prefixIcon, 'prefixIcon');
    add(suffixIcon, 'suffixIcon');
    add(helperError, 'helperError');
    add(counter, 'counter');
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
    return box == null ? 0.0 : box.getMinIntrinsicHeight(width);
  }

  static Size _boxSize(RenderBox box) => box == null ? Size.zero : box.size;

  static BoxParentData _boxParentData(RenderBox box) => box.parentData;

  EdgeInsets get contentPadding => decoration.contentPadding;

  // Returns a value used by performLayout to position all
  // of the renderers. This method applies layout to all of the renderers
  // except the container. For convenience, the container is laid out
  // in performLayout().
  _RenderDecorationLayout _layout(BoxConstraints layoutConstraints) {
    final Map<RenderBox, double> boxToBaseline = <RenderBox, double>{};
    BoxConstraints boxConstraints = layoutConstraints.loosen();
    double aboveBaseline = 0.0;
    double belowBaseline = 0.0;
    void layoutLineBox(RenderBox box) {
      if (box == null)
        return;
      box.layout(boxConstraints, parentUsesSize: true);
      final double baseline = box.getDistanceToBaseline(textBaseline);
      assert(baseline != null && baseline >= 0.0);
      boxToBaseline[box] = baseline;
      aboveBaseline = math.max(baseline, aboveBaseline);
      belowBaseline = math.max(box.size.height - baseline, belowBaseline);
    }
    layoutLineBox(prefix);
    layoutLineBox(suffix);

    if (icon != null)
      icon.layout(boxConstraints, parentUsesSize: true);
    if (prefixIcon != null)
      prefixIcon.layout(boxConstraints, parentUsesSize: true);
    if (suffixIcon != null)
      suffixIcon.layout(boxConstraints, parentUsesSize: true);

    final double inputWidth = math.max(0.0, constraints.maxWidth - (
      _boxSize(icon).width
      + contentPadding.left
      + _boxSize(prefixIcon).width
      + _boxSize(prefix).width
      + _boxSize(suffix).width
      + _boxSize(suffixIcon).width
      + contentPadding.right));

    boxConstraints = boxConstraints.copyWith(maxWidth: inputWidth);
    if (label != null) // The label is not baseline aligned.
      label.layout(boxConstraints, parentUsesSize: true);

    boxConstraints = boxConstraints.copyWith(minWidth: inputWidth);
    layoutLineBox(hint);
    layoutLineBox(input);

    double inputBaseline = contentPadding.top + aboveBaseline;
    double containerHeight = contentPadding.top
      + aboveBaseline
      + belowBaseline
      + contentPadding.bottom;

    if (label != null) {
      // floatingLabelHeight includes the vertical gap between the inline
      // elements and the floating label.
      containerHeight += decoration.floatingLabelHeight;
      inputBaseline += decoration.floatingLabelHeight;
    }

    containerHeight = math.max(
      containerHeight,
      math.max(
        _boxSize(suffixIcon).height,
        _boxSize(prefixIcon).height));

    // Inline text within an outline border is centered within the container
    // less 2.0 dps at the top to account for the vertical space occupied
    // by the floating label.
    final double outlineBaseline = aboveBaseline +
      (containerHeight - (2.0 + aboveBaseline + belowBaseline)) / 2.0;

    double subtextBaseline = 0.0;
    double subtextHeight = 0.0;
    if (helperError != null || counter != null) {
      boxConstraints = layoutConstraints.loosen();
      aboveBaseline = 0.0;
      belowBaseline = 0.0;
      layoutLineBox(counter);

      // The helper or error text can occupy the full width less the space
      // occupied by the icon and counter.
      boxConstraints = boxConstraints.copyWith(
        maxWidth: math.max(0.0, boxConstraints.maxWidth
          - _boxSize(icon).width
          - _boxSize(counter).width
          - contentPadding.horizontal,
        ),
      );
      layoutLineBox(helperError);

      if (aboveBaseline + belowBaseline > 0.0) {
        const double subtextGap = 8.0;
        subtextBaseline = containerHeight + subtextGap + aboveBaseline;
        subtextHeight = subtextGap + aboveBaseline + belowBaseline;
      }
    }

    return _RenderDecorationLayout(
      boxToBaseline: boxToBaseline,
      containerHeight: containerHeight,
      inputBaseline: inputBaseline,
      outlineBaseline: outlineBaseline,
      subtextBaseline: subtextBaseline,
      subtextHeight: subtextHeight,
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return _minWidth(icon, height)
      + contentPadding.left
      + _minWidth(prefixIcon, height)
      + _minWidth(prefix, height)
      + math.max(_minWidth(input, height), _minWidth(hint, height))
      + _minWidth(suffix, height)
      + _minWidth(suffixIcon, height)
      + contentPadding.right;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _maxWidth(icon, height)
      + contentPadding.left
      + _maxWidth(prefixIcon, height)
      + _maxWidth(prefix, height)
      + math.max(_maxWidth(input, height), _maxWidth(hint, height))
      + _maxWidth(suffix, height)
      + _maxWidth(suffixIcon, height)
      + contentPadding.right;
  }

  double _lineHeight(double width, List<RenderBox> boxes) {
    double height = 0.0;
    for (RenderBox box in boxes) {
      if (box == null)
        continue;
      height = math.max(_minHeight(box, width), height);
    }
    return height;
    // TODO(hansmuller): this should compute the overall line height for the
    // boxes when they've been baseline-aligned.
    // See https://github.com/flutter/flutter/issues/13715
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    double subtextHeight = _lineHeight(width, <RenderBox>[helperError, counter]);
    if (subtextHeight > 0.0)
      subtextHeight += 8.0;
    return contentPadding.top
      + (label == null ? 0.0 : decoration.floatingLabelHeight)
      + _lineHeight(width, <RenderBox>[prefix, input, suffix])
      + subtextHeight
      + contentPadding.bottom;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return computeMinIntrinsicHeight(width);
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    assert(false, 'not implemented');
    return 0.0;
  }

  // Records where the label was painted.
  Matrix4 _labelTransform;

  @override
  void performLayout() {
    _labelTransform = null;
    final _RenderDecorationLayout layout = _layout(constraints);

    final double overallWidth = constraints.maxWidth;
    final double overallHeight = layout.containerHeight + layout.subtextHeight;

    if (container != null) {
      final BoxConstraints containerConstraints = BoxConstraints.tightFor(
        height: layout.containerHeight,
        width: overallWidth - _boxSize(icon).width,
      );
      container.layout(containerConstraints, parentUsesSize: true);
      double x;
      switch (textDirection) {
        case TextDirection.rtl:
          x = 0.0;
          break;
        case TextDirection.ltr:
          x = _boxSize(icon).width;
          break;
       }
      _boxParentData(container).offset = Offset(x, 0.0);
    }

    double height;
    double centerLayout(RenderBox box, double x) {
      _boxParentData(box).offset = Offset(x, (height - box.size.height) / 2.0);
      return box.size.width;
    }

    double baseline;
    double baselineLayout(RenderBox box, double x) {
      _boxParentData(box).offset = Offset(x, baseline - layout.boxToBaseline[box]);
      return box.size.width;
    }

    final double left = contentPadding.left;
    final double right = overallWidth - contentPadding.right;

    height = layout.containerHeight;
    baseline = decoration.isCollapsed || !decoration.border.isOutline
      ? layout.inputBaseline
      : layout.outlineBaseline;

    if (icon != null) {
      double x;
      switch (textDirection) {
        case TextDirection.rtl:
          x = overallWidth - icon.size.width;
          break;
        case TextDirection.ltr:
          x = 0.0;
          break;
       }
      centerLayout(icon, x);
    }

    switch (textDirection) {
      case TextDirection.rtl: {
        double start = right - _boxSize(icon).width;
        double end = left;
        if (prefixIcon != null) {
          start += contentPadding.left;
          start -= centerLayout(prefixIcon, start - prefixIcon.size.width);
        }
        if (label != null)
          centerLayout(label, start - label.size.width);
        if (prefix != null)
          start -= baselineLayout(prefix, start - prefix.size.width);
        if (input != null)
          baselineLayout(input, start - input.size.width);
        if (hint != null)
          baselineLayout(hint, start - hint.size.width);
        if (suffixIcon != null) {
          end -= contentPadding.left;
          end += centerLayout(suffixIcon, end);
        }
        if (suffix != null)
          end += baselineLayout(suffix, end);
        break;
      }
      case TextDirection.ltr: {
        double start = left + _boxSize(icon).width;
        double end = right;
        if (prefixIcon != null) {
          start -= contentPadding.left;
          start += centerLayout(prefixIcon, start);
        }
        if (label != null)
          centerLayout(label, start);
        if (prefix != null)
          start += baselineLayout(prefix, start);
        if (input != null)
          baselineLayout(input, start);
        if (hint != null)
          baselineLayout(hint, start);
        if (suffixIcon != null) {
          end += contentPadding.right;
          end -= centerLayout(suffixIcon, end - suffixIcon.size.width);
        }
        if (suffix != null)
          end -= baselineLayout(suffix, end - suffix.size.width);
        break;
      }
    }

    if (helperError != null || counter != null) {
      height = layout.subtextHeight;
      baseline = layout.subtextBaseline;

      switch (textDirection) {
        case TextDirection.rtl:
          if (helperError != null)
            baselineLayout(helperError, right - helperError.size.width - _boxSize(icon).width);
          if (counter != null)
            baselineLayout(counter, left);
          break;
        case TextDirection.ltr:
          if (helperError != null)
            baselineLayout(helperError, left + _boxSize(icon).width);
          if (counter != null)
            baselineLayout(counter, right - counter.size.width);
          break;
      }
    }

    if (label != null) {
      final double labelX = _boxParentData(label).offset.dx;
      switch (textDirection) {
        case TextDirection.rtl:
          decoration.borderGap.start = labelX + label.size.width;
          break;
        case TextDirection.ltr:
          // The value of _InputBorderGap.start is relative to the origin of the
          // _BorderContainer which is inset by the icon's width.
          decoration.borderGap.start = labelX - _boxSize(icon).width;
          break;
      }
      decoration.borderGap.extent = label.size.width * 0.75;
    } else {
      decoration.borderGap.start = null;
      decoration.borderGap.extent = 0.0;
    }

    size = constraints.constrain(Size(overallWidth, overallHeight));
    assert(size.width == constraints.constrainWidth(overallWidth));
    assert(size.height == constraints.constrainHeight(overallHeight));
  }

  void _paintLabel(PaintingContext context, Offset offset) {
    context.paintChild(label, offset);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    void doPaint(RenderBox child) {
      if (child != null)
        context.paintChild(child, _boxParentData(child).offset + offset);
    }
    doPaint(container);

    if (label != null) {
      final Offset labelOffset = _boxParentData(label).offset;
      final double labelHeight = label.size.height;
      final double t = decoration.floatingLabelProgress;
      // The center of the outline border label ends up a little below the
      // center of the top border line.
      final bool isOutlineBorder = decoration.border != null && decoration.border.isOutline;
      final double floatingY = isOutlineBorder ? -labelHeight * 0.25 : contentPadding.top;
      final double scale = lerpDouble(1.0, 0.75, t);
      double dx;
      switch (textDirection) {
        case TextDirection.rtl:
          dx = labelOffset.dx + label.size.width * (1.0 - scale); // origin is on the right
          break;
        case TextDirection.ltr:
          dx = labelOffset.dx; // origin on the left
          break;
      }
      final double dy = lerpDouble(0.0, floatingY - labelOffset.dy, t);
      _labelTransform = Matrix4.identity()
        ..translate(dx, labelOffset.dy + dy)
        ..scale(scale);
      context.pushTransform(needsCompositing, offset, _labelTransform, _paintLabel);
    }

    doPaint(icon);
    doPaint(prefix);
    doPaint(suffix);
    doPaint(prefixIcon);
    doPaint(suffixIcon);
    doPaint(hint);
    doPaint(input);
    doPaint(helperError);
    doPaint(counter);
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  bool hitTestChildren(HitTestResult result, { @required Offset position }) {
    assert(position != null);
    for (RenderBox child in _children) {
      // TODO(hansmuller): label must be handled specially since we've transformed it
      if (child.hitTest(result, position: position - _boxParentData(child).offset))
        return true;
    }
    return false;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    if (child == label && _labelTransform != null) {
      final Offset labelOffset = _boxParentData(label).offset;
      transform
        ..multiply(_labelTransform)
        ..translate(-labelOffset.dx, -labelOffset.dy);
    }
    super.applyPaintTransform(child, transform);
  }
}

class _RenderDecorationElement extends RenderObjectElement {
  _RenderDecorationElement(_Decorator widget) : super(widget);

  final Map<_DecorationSlot, Element> slotToChild = <_DecorationSlot, Element>{};
  final Map<Element, _DecorationSlot> childToSlot = <Element, _DecorationSlot>{};

  @override
  _Decorator get widget => super.widget;

  @override
  _RenderDecoration get renderObject => super.renderObject;

  @override
  void visitChildren(ElementVisitor visitor) {
    slotToChild.values.forEach(visitor);
  }

  @override
  void forgetChild(Element child) {
    assert(slotToChild.values.contains(child));
    assert(childToSlot.keys.contains(child));
    final _DecorationSlot slot = childToSlot[child];
    childToSlot.remove(child);
    slotToChild.remove(slot);
  }

  void _mountChild(Widget widget, _DecorationSlot slot) {
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
    _mountChild(widget.decoration.icon, _DecorationSlot.icon);
    _mountChild(widget.decoration.input, _DecorationSlot.input);
    _mountChild(widget.decoration.label, _DecorationSlot.label);
    _mountChild(widget.decoration.hint, _DecorationSlot.hint);
    _mountChild(widget.decoration.prefix, _DecorationSlot.prefix);
    _mountChild(widget.decoration.suffix, _DecorationSlot.suffix);
    _mountChild(widget.decoration.prefixIcon, _DecorationSlot.prefixIcon);
    _mountChild(widget.decoration.suffixIcon, _DecorationSlot.suffixIcon);
    _mountChild(widget.decoration.helperError, _DecorationSlot.helperError);
    _mountChild(widget.decoration.counter, _DecorationSlot.counter);
    _mountChild(widget.decoration.container, _DecorationSlot.container);
  }

  void _updateChild(Widget widget, _DecorationSlot slot) {
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
  void update(_Decorator newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _updateChild(widget.decoration.icon, _DecorationSlot.icon);
    _updateChild(widget.decoration.input, _DecorationSlot.input);
    _updateChild(widget.decoration.label, _DecorationSlot.label);
    _updateChild(widget.decoration.hint, _DecorationSlot.hint);
    _updateChild(widget.decoration.prefix, _DecorationSlot.prefix);
    _updateChild(widget.decoration.suffix, _DecorationSlot.suffix);
    _updateChild(widget.decoration.prefixIcon, _DecorationSlot.prefixIcon);
    _updateChild(widget.decoration.suffixIcon, _DecorationSlot.suffixIcon);
    _updateChild(widget.decoration.helperError, _DecorationSlot.helperError);
    _updateChild(widget.decoration.counter, _DecorationSlot.counter);
    _updateChild(widget.decoration.container, _DecorationSlot.container);
  }

  void _updateRenderObject(RenderObject child, _DecorationSlot slot) {
    switch (slot) {
      case _DecorationSlot.icon:
        renderObject.icon = child;
        break;
      case _DecorationSlot.input:
        renderObject.input = child;
        break;
      case _DecorationSlot.label:
        renderObject.label = child;
        break;
      case _DecorationSlot.hint:
        renderObject.hint = child;
        break;
      case _DecorationSlot.prefix:
        renderObject.prefix = child;
        break;
      case _DecorationSlot.suffix:
        renderObject.suffix = child;
        break;
      case _DecorationSlot.prefixIcon:
        renderObject.prefixIcon = child;
        break;
      case _DecorationSlot.suffixIcon:
        renderObject.suffixIcon = child;
        break;
      case _DecorationSlot.helperError:
        renderObject.helperError = child;
        break;
      case _DecorationSlot.counter:
        renderObject.counter = child;
        break;
      case _DecorationSlot.container:
        renderObject.container = child;
        break;
    }
  }

  @override
  void insertChildRenderObject(RenderObject child, dynamic slotValue) {
    assert(child is RenderBox);
    assert(slotValue is _DecorationSlot);
    final _DecorationSlot slot = slotValue;
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

class _Decorator extends RenderObjectWidget {
  const _Decorator({
    Key key,
    @required this.decoration,
    @required this.textDirection,
    @required this.textBaseline,
    @required this.isFocused,
  }) : assert(decoration != null),
       assert(textDirection != null),
       assert(textBaseline != null),
       super(key: key);

  final _Decoration decoration;
  final TextDirection textDirection;
  final TextBaseline textBaseline;
  final bool isFocused;

  @override
  _RenderDecorationElement createElement() => _RenderDecorationElement(this);

  @override
  _RenderDecoration createRenderObject(BuildContext context) {
    return _RenderDecoration(
      decoration: decoration,
      textDirection: textDirection,
      textBaseline: textBaseline,
      isFocused: isFocused,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderDecoration renderObject) {
    renderObject
     ..decoration = decoration
     ..textDirection = textDirection
     ..textBaseline = textBaseline
     ..isFocused = isFocused;
  }
}

class _AffixText extends StatelessWidget {
  const _AffixText({
    this.labelIsFloating,
    this.text,
    this.style,
    this.child
  });

  final bool labelIsFloating;
  final String text;
  final TextStyle style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: style,
      child: AnimatedOpacity(
        duration: _kTransitionDuration,
        curve: _kTransitionCurve,
        opacity: labelIsFloating ? 1.0 : 0.0,
        child: child ?? Text(text, style: style,),
      ),
    );
  }
}

/// Defines the appearance of a Material Design text field.
///
/// [InputDecorator] displays the visual elements of a Material Design text
/// field around its input [child]. The visual elements themselves are defined
/// by an [InputDecoration] object and their layout and appearance depend
/// on the `baseStyle`, `textAlign`, `isFocused`, and `isEmpty` parameters.
///
/// [TextField] uses this widget to decorate its [EditableText] child.
///
/// [InputDecorator] can be used to create widgets that look and behave like a
/// [TextField] but support other kinds of input.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// See also:
///
///  * [TextField], which uses an [InputDecorator] to display a border,
///    labels, and icons, around its [EditableText] child.
///  * [Decoration] and [DecoratedBox], for drawing arbitrary decorations
///    around other widgets.
class InputDecorator extends StatefulWidget {
  /// Creates a widget that displays a border, labels, and icons,
  /// for a [TextField].
  ///
  /// The [isFocused] and [isEmpty] arguments must not be null.
  const InputDecorator({
    Key key,
    this.decoration,
    this.baseStyle,
    this.textAlign,
    this.isFocused = false,
    this.isEmpty = false,
    this.child,
  }) : assert(isFocused != null),
       assert(isEmpty != null),
       super(key: key);

  /// The text and styles to use when decorating the child.
  ///
  /// If null, `const InputDecoration()` is used. Null [InputDecoration]
  /// properties are initialized with the corresponding values from
  /// [ThemeData.inputDecorationTheme].
  final InputDecoration decoration;

  /// The style on which to base the label, hint, counter, and error styles
  /// if the [decoration] does not provide explicit styles.
  ///
  /// If null, `baseStyle` defaults to the `subhead` style from the
  /// current [Theme], see [ThemeData.textTheme].
  ///
  /// The [TextStyle.textBaseline] of the [baseStyle] is used to determine
  /// the baseline used for text alignment.
  final TextStyle baseStyle;

  /// How the text in the decoration should be aligned horizontally.
  final TextAlign textAlign;

  /// Whether the input field has focus.
  ///
  /// Determines the position of the label text and the color and weight
  /// of the border.
  ///
  /// Defaults to false.
  final bool isFocused;

  /// Whether the input field is empty.
  ///
  /// Determines the position of the label text and whether to display the hint
  /// text.
  ///
  /// Defaults to false.
  final bool isEmpty;

  /// The widget below this widget in the tree.
  ///
  /// Typically an [EditableText], [DropdownButton], or [InkWell].
  final Widget child;

  /// Whether the label needs to get out of the way of the input, either by
  /// floating or disappearing.
  bool get _labelShouldWithdraw => !isEmpty || isFocused;

  @override
  _InputDecoratorState createState() => _InputDecoratorState();

  /// The RenderBox that defines this decorator's "container". That's the
  /// area which is filled if [InputDecoration.isFilled] is true. It's the area
  /// adjacent to [InputDecoration.icon] and above the widgets that contain
  /// [InputDecoration.helperText], [InputDecoration.errorText], and
  /// [InputDecoration.counterText].
  ///
  /// [TextField] renders ink splashes within the container.
  static RenderBox containerOf(BuildContext context) {
    final _RenderDecoration result = context.ancestorRenderObjectOfType(const TypeMatcher<_RenderDecoration>());
    return result?.container;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<InputDecoration>('decoration', decoration));
    properties.add(DiagnosticsProperty<TextStyle>('baseStyle', baseStyle, defaultValue: null));
    properties.add(DiagnosticsProperty<bool>('isFocused', isFocused));
    properties.add(DiagnosticsProperty<bool>('isEmpty', isEmpty));
  }
}

class _InputDecoratorState extends State<InputDecorator> with TickerProviderStateMixin {
  AnimationController _floatingLabelController;
  AnimationController _shakingLabelController;
  final _InputBorderGap _borderGap = _InputBorderGap();

  @override
  void initState() {
    super.initState();
    _floatingLabelController = AnimationController(
      duration: _kTransitionDuration,
      vsync: this,
      value: (widget.decoration.hasFloatingPlaceholder && widget._labelShouldWithdraw) ? 1.0 : 0.0,
    );
    _floatingLabelController.addListener(_handleChange);

    _shakingLabelController = AnimationController(
      duration: _kTransitionDuration,
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _effectiveDecoration = null;
  }

  @override
  void dispose() {
    _floatingLabelController.dispose();
    _shakingLabelController.dispose();
    super.dispose();
  }

  void _handleChange() {
    setState(() {
      // The _floatingLabelController's value has changed.
    });
  }

  InputDecoration _effectiveDecoration;
  InputDecoration get decoration {
    _effectiveDecoration ??= widget.decoration.applyDefaults(
      Theme.of(context).inputDecorationTheme
    );
    return _effectiveDecoration;
  }

  TextAlign get textAlign => widget.textAlign;
  bool get isFocused => widget.isFocused;
  bool get isEmpty => widget.isEmpty;

  @override
  void didUpdateWidget(InputDecorator old) {
    super.didUpdateWidget(old);
    if (widget.decoration != old.decoration)
      _effectiveDecoration = null;

    if (widget._labelShouldWithdraw != old._labelShouldWithdraw && widget.decoration.hasFloatingPlaceholder) {
      if (widget._labelShouldWithdraw) {
        _floatingLabelController.forward();
      }
      else
        _floatingLabelController.reverse();
    }

    final String errorText = decoration.errorText;
    final String oldErrorText = old.decoration.errorText;

    if (_floatingLabelController.isCompleted && errorText != null && errorText != oldErrorText) {
      _shakingLabelController
        ..value = 0.0
        ..forward();
    }
  }

  Color _getActiveColor(ThemeData themeData) {
    if (isFocused) {
      switch (themeData.brightness) {
        case Brightness.dark:
          return themeData.accentColor;
        case Brightness.light:
          return themeData.primaryColor;
      }
    }
    return themeData.hintColor;
  }

  Color _getFillColor(ThemeData themeData) {
    if (decoration.filled != true) // filled == null same as filled == false
      return Colors.transparent;
    if (decoration.fillColor != null)
      return decoration.fillColor;

    // dark theme: 10% white (enabled), 5% white (disabled)
    // light theme: 4% black (enabled), 2% black (disabled)
    const Color darkEnabled = Color(0x1AFFFFFF);
    const Color darkDisabled = Color(0x0DFFFFFF);
    const Color lightEnabled = Color(0x0A000000);
    const Color lightDisabled = Color(0x05000000);

    switch (themeData.brightness) {
      case Brightness.dark:
        return decoration.enabled ? darkEnabled : darkDisabled;
      case Brightness.light:
        return decoration.enabled ? lightEnabled : lightDisabled;
    }
    return lightEnabled;
  }

  Color _getDefaultIconColor(ThemeData themeData) {
    if (!decoration.enabled)
      return themeData.disabledColor;

    switch (themeData.brightness) {
      case Brightness.dark:
        return Colors.white70;
      case Brightness.light:
        return Colors.black45;
      default:
        return themeData.iconTheme.color;
    }
  }

  // True if the label will be shown and the hint will not.
  // If we're not focused, there's no value, and labelText was provided,
  // then the label appears where the hint would.
  bool get _hasInlineLabel => !widget._labelShouldWithdraw && decoration.labelText != null;

  // If the label is a floating placeholder, it's always shown.
  bool get _shouldShowLabel => _hasInlineLabel || decoration.hasFloatingPlaceholder;


  // The base style for the inline label or hint when they're displayed "inline",
  // i.e. when they appear in place of the empty text field.
  TextStyle _getInlineStyle(ThemeData themeData) {
    return themeData.textTheme.subhead.merge(widget.baseStyle)
      .copyWith(color: decoration.enabled ? themeData.hintColor : themeData.disabledColor);
  }

  TextStyle _getFloatingLabelStyle(ThemeData themeData) {
    final Color color = decoration.errorText != null
      ? decoration.errorStyle?.color ?? themeData.errorColor
      : _getActiveColor(themeData);
    final TextStyle style = themeData.textTheme.subhead.merge(widget.baseStyle);
    return style
      .copyWith(color: decoration.enabled ? color : themeData.disabledColor)
      .merge(decoration.labelStyle);
  }

  TextStyle _getHelperStyle(ThemeData themeData) {
    final Color color = decoration.enabled ? themeData.hintColor : Colors.transparent;
    return themeData.textTheme.caption.copyWith(color: color).merge(decoration.helperStyle);
  }

  TextStyle _getErrorStyle(ThemeData themeData) {
    final Color color = decoration.enabled ? themeData.errorColor : Colors.transparent;
    return themeData.textTheme.caption.copyWith(color: color).merge(decoration.errorStyle);
  }

  InputBorder _getDefaultBorder(ThemeData themeData) {
    if (decoration.border?.borderSide == BorderSide.none) {
      return decoration.border;
    }

    Color borderColor;
    if (decoration.enabled) {
      borderColor = decoration.errorText == null
        ? _getActiveColor(themeData)
        : themeData.errorColor;
    } else {
      borderColor = (decoration.filled == true && decoration.border?.isOutline != true)
        ? Colors.transparent
        : themeData.disabledColor;
    }

    double borderWeight;
    if (decoration.isCollapsed || decoration?.border == InputBorder.none || !decoration.enabled)
      borderWeight = 0.0;
    else
      borderWeight = isFocused ? 2.0 : 1.0;

    final InputBorder border = decoration.border ?? const UnderlineInputBorder();
    return border.copyWith(borderSide: BorderSide(color: borderColor, width: borderWeight));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final TextStyle inlineStyle = _getInlineStyle(themeData);
    final TextBaseline textBaseline = inlineStyle.textBaseline;

    final TextStyle hintStyle = inlineStyle.merge(decoration.hintStyle);
    final Widget hint = decoration.hintText == null ? null : AnimatedOpacity(
      opacity: (isEmpty && !_hasInlineLabel) ? 1.0 : 0.0,
      duration: _kTransitionDuration,
      curve: _kTransitionCurve,
      child: Text(
        decoration.hintText,
        style: hintStyle,
        overflow: TextOverflow.ellipsis,
        textAlign: textAlign,
      ),
    );

    final bool isError = decoration.errorText != null;
    InputBorder border;
    if (!decoration.enabled)
      border = isError ? decoration.errorBorder : decoration.disabledBorder;
    else if (isFocused)
      border = isError ? decoration.focusedErrorBorder : decoration.focusedBorder;
    else
      border = isError ? decoration.errorBorder : decoration.enabledBorder;
    border ??= _getDefaultBorder(themeData);

    final Widget container = _BorderContainer(
      border: border,
      gap: _borderGap,
      gapAnimation: _floatingLabelController.view,
      fillColor: _getFillColor(themeData),
    );

    final TextStyle inlineLabelStyle = inlineStyle.merge(decoration.labelStyle);
    final Widget label = decoration.labelText == null ? null : _Shaker(
      animation: _shakingLabelController.view,
      child: AnimatedOpacity(
        duration: _kTransitionDuration,
        curve: _kTransitionCurve,
        opacity: _shouldShowLabel ? 1.0 : 0.0,
        child: AnimatedDefaultTextStyle(
          duration:_kTransitionDuration,
          curve: _kTransitionCurve,
          style: widget._labelShouldWithdraw
            ? _getFloatingLabelStyle(themeData)
            : inlineLabelStyle,
          child: Text(
            decoration.labelText,
            overflow: TextOverflow.ellipsis,
            textAlign: textAlign,
          ),
        ),
      ),
    );

    final Widget prefix = decoration.prefix == null && decoration.prefixText == null ? null :
      _AffixText(
        labelIsFloating: widget._labelShouldWithdraw,
        text: decoration.prefixText,
        style: decoration.prefixStyle ?? hintStyle,
        child: decoration.prefix,
      );

    final Widget suffix = decoration.suffix == null && decoration.suffixText == null ? null :
      _AffixText(
        labelIsFloating: widget._labelShouldWithdraw,
        text: decoration.suffixText,
        style: decoration.suffixStyle ?? hintStyle,
        child: decoration.suffix,
      );

    final Color activeColor = _getActiveColor(themeData);
    final bool decorationIsDense = decoration.isDense == true; // isDense == null, same as false
    final double iconSize = decorationIsDense ? 18.0 : 24.0;
    final Color iconColor = isFocused ? activeColor : _getDefaultIconColor(themeData);

    final Widget icon = decoration.icon == null ? null :
      Padding(
        padding: const EdgeInsetsDirectional.only(end: 16.0),
        child: IconTheme.merge(
          data: IconThemeData(
            color: iconColor,
            size: iconSize,
          ),
          child: decoration.icon,
        ),
      );

    final Widget prefixIcon = decoration.prefixIcon == null ? null :
      Center(
        widthFactor: 1.0,
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
          child: IconTheme.merge(
            data: IconThemeData(
              color: iconColor,
              size: iconSize,
            ),
            child: decoration.prefixIcon,
          ),
        ),
      );

    final Widget suffixIcon = decoration.suffixIcon == null ? null :
      Center(
        widthFactor: 1.0,
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
          child: IconTheme.merge(
            data: IconThemeData(
              color: iconColor,
              size: iconSize,
            ),
            child: decoration.suffixIcon,
          ),
        ),
      );

    final Widget helperError = _HelperError(
      textAlign: textAlign,
      helperText: decoration.helperText,
      helperStyle: _getHelperStyle(themeData),
      errorText: decoration.errorText,
      errorStyle: _getErrorStyle(themeData),
      errorMaxLines: decoration.errorMaxLines,
    );

    final Widget counter = decoration.counterText == null ? null :
      Semantics(
        container: true,
        liveRegion: isFocused,
        child: Text(
          decoration.counterText,
          style: _getHelperStyle(themeData).merge(decoration.counterStyle),
          overflow: TextOverflow.ellipsis,
          semanticsLabel: decoration.semanticCounterText,
        ),
      );

    // The _Decoration widget and _RenderDecoration assume that contentPadding
    // has been resolved to EdgeInsets.
    final TextDirection textDirection = Directionality.of(context);
    final EdgeInsets decorationContentPadding = decoration.contentPadding?.resolve(textDirection);

    EdgeInsets contentPadding;
    double floatingLabelHeight;
    if (decoration.isCollapsed) {
      floatingLabelHeight = 0.0;
      contentPadding = decorationContentPadding ?? EdgeInsets.zero;
    } else if (!border.isOutline) {
      // 4.0: the vertical gap between the inline elements and the floating label.
      floatingLabelHeight = (4.0 + 0.75 * inlineLabelStyle.fontSize) * MediaQuery.textScaleFactorOf(context);
      if (decoration.filled == true) { // filled == null same as filled == false
        contentPadding = decorationContentPadding ?? (decorationIsDense
          ? const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 8.0)
          : const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 12.0));
      } else {
        // Not left or right padding for underline borders that aren't filled
        // is a small concession to backwards compatibility. This eliminates
        // the most noticeable layout change introduced by #13734.
        contentPadding = decorationContentPadding ?? (decorationIsDense
          ? const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 8.0)
          : const EdgeInsets.fromLTRB(0.0, 12.0, 0.0, 12.0));
      }
    } else {
      floatingLabelHeight = 0.0;
      contentPadding = decorationContentPadding ?? (decorationIsDense
        ? const EdgeInsets.fromLTRB(12.0, 20.0, 12.0, 12.0)
        : const EdgeInsets.fromLTRB(12.0, 24.0, 12.0, 16.0));
    }

    return _Decorator(
      decoration: _Decoration(
        contentPadding: contentPadding,
        isCollapsed: decoration.isCollapsed,
        floatingLabelHeight: floatingLabelHeight,
        floatingLabelProgress: _floatingLabelController.value,
        border: border,
        borderGap: _borderGap,
        icon: icon,
        input: widget.child,
        label: label,
        hint: hint,
        prefix: prefix,
        suffix: suffix,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        helperError: helperError,
        counter: counter,
        container: container,
      ),
      textDirection: textDirection,
      textBaseline: textBaseline,
      isFocused: isFocused,
    );
  }
}

/// The border, labels, icons, and styles used to decorate a Material
/// Design text field.
///
/// The [TextField] and [InputDecorator] classes use [InputDecoration] objects
/// to describe their decoration. (In fact, this class is merely the
/// configuration of an [InputDecorator], which does all the heavy lifting.)
///
/// See also:
///
///  * [TextField], which is a text input widget that uses an
///    [InputDecoration].
///  * [InputDecorator], which is a widget that draws an [InputDecoration]
///    around an input child widget.
///  * [Decoration] and [DecoratedBox], for drawing borders and backgrounds
///    around a child widget.
@immutable
class InputDecoration {
  /// Creates a bundle of the border, labels, icons, and styles used to
  /// decorate a Material Design text field.
  ///
  /// Unless specified by [ThemeData.inputDecorationTheme],
  /// [InputDecorator] defaults [isDense] to true, and [filled] to false,
  /// and [maxLines] to 1. The default border is an instance
  /// of [UnderlineInputBorder]. If [border] is [InputBorder.none] then
  /// no border is drawn.
  ///
  /// The [enabled] argument must not be null.
  ///
  /// Only [prefix] or [prefixText] can be specified.
  /// The same applies for [suffix] and [suffixText].
  const InputDecoration({
    this.icon,
    this.labelText,
    this.labelStyle,
    this.helperText,
    this.helperStyle,
    this.hintText,
    this.hintStyle,
    this.errorText,
    this.errorStyle,
    this.errorMaxLines,
    this.hasFloatingPlaceholder = true,
    this.isDense,
    this.contentPadding,
    this.prefixIcon,
    this.prefix,
    this.prefixText,
    this.prefixStyle,
    this.suffixIcon,
    this.suffix,
    this.suffixText,
    this.suffixStyle,
    this.counterText,
    this.counterStyle,
    this.filled,
    this.fillColor,
    this.errorBorder,
    this.focusedBorder,
    this.focusedErrorBorder,
    this.disabledBorder,
    this.enabledBorder,
    this.border,
    this.enabled = true,
    this.semanticCounterText,
  }) : assert(enabled != null),
       assert(!(prefix != null && prefixText != null), 'Declaring both prefix and prefixText is not allowed'),
       assert(!(suffix != null && suffixText != null), 'Declaring both suffix and suffixText is not allowed'),
       isCollapsed = false;

  /// Defines an [InputDecorator] that is the same size as the input field.
  ///
  /// This type of input decoration does not include a border by default.
  ///
  /// Sets the [isCollapsed] property to true.
  const InputDecoration.collapsed({
    @required this.hintText,
    this.hasFloatingPlaceholder = true,
    this.hintStyle,
    this.filled = false,
    this.fillColor,
    this.border = InputBorder.none,
    this.enabled = true,
  }) : assert(enabled != null),
       icon = null,
       labelText = null,
       labelStyle = null,
       helperText = null,
       helperStyle = null,
       errorText = null,
       errorStyle = null,
       errorMaxLines = null,
       isDense = false,
       contentPadding = EdgeInsets.zero,
       isCollapsed = true,
       prefixIcon = null,
       prefix = null,
       prefixText = null,
       prefixStyle = null,
       suffix = null,
       suffixIcon = null,
       suffixText = null,
       suffixStyle = null,
       counterText = null,
       counterStyle = null,
       errorBorder = null,
       focusedBorder = null,
       focusedErrorBorder = null,
       disabledBorder = null,
       enabledBorder = null,
       semanticCounterText = null;

  /// An icon to show before the input field and outside of the decoration's
  /// container.
  ///
  /// The size and color of the icon is configured automatically using an
  /// [IconTheme] and therefore does not need to be explicitly given in the
  /// icon widget.
  ///
  /// The trailing edge of the icon is padded by 16dps.
  ///
  /// The decoration's container is the area which is filled if [isFilled] is
  /// true and bordered per the [border]. It's the area adjacent to
  /// [decoration.icon] and above the widgets that contain [helperText],
  /// [errorText], and [counterText].
  ///
  /// See [Icon], [ImageIcon].
  final Widget icon;

  /// Text that describes the input field.
  ///
  /// When the input field is empty and unfocused, the label is displayed on
  /// top of the input field (i.e., at the same location on the screen where
  /// text may be entered in the input field). When the input field receives
  /// focus (or if the field is non-empty), the label moves above (i.e.,
  /// vertically adjacent to) the input field.
  final String labelText;

  /// The style to use for the [labelText] when the label is above (i.e.,
  /// vertically adjacent to) the input field.
  ///
  /// When the [labelText] is on top of the input field, the text uses the
  /// [hintStyle] instead.
  ///
  /// If null, defaults to a value derived from the base [TextStyle] for the
  /// input field and the current [Theme].
  final TextStyle labelStyle;

  /// Text that provides context about the input [child]'s value, such as how
  /// the value will be used.
  ///
  /// If non-null, the text is displayed below the input [child], in the same
  /// location as [errorText]. If a non-null [errorText] value is specified then
  /// the helper text is not shown.
  final String helperText;

  /// The style to use for the [helperText].
  final TextStyle helperStyle;

  /// Text that suggests what sort of input the field accepts.
  ///
  /// Displayed on top of the input [child] (i.e., at the same location on the
  /// screen where text may be entered in the input [child]) when the input
  /// [isEmpty] and either (a) [labelText] is null or (b) the input has the focus.
  final String hintText;

  /// The style to use for the [hintText].
  ///
  /// Also used for the [labelText] when the [labelText] is displayed on
  /// top of the input field (i.e., at the same location on the screen where
  /// text may be entered in the input [child]).
  ///
  /// If null, defaults to a value derived from the base [TextStyle] for the
  /// input field and the current [Theme].
  final TextStyle hintStyle;

  /// Text that appears below the input [child] and the border.
  ///
  /// If non-null, the border's color animates to red and the [helperText] is
  /// not shown.
  ///
  /// In a [TextFormField], this is overridden by the value returned from
  /// [TextFormField.validator], if that is not null.
  final String errorText;

  /// The style to use for the [errorText].
  ///
  /// If null, defaults of a value derived from the base [TextStyle] for the
  /// input field and the current [Theme].
  final TextStyle errorStyle;


  /// The maximum number of lines the [errorText] can occupy.
  ///
  /// Defaults to null, which means that the [errorText] will be limited
  /// to a single line with [TextOverflow.ellipsis].
  ///
  /// This value is passed along to the [Text.maxLines] attribute
  /// of the [Text] widget used to display the error.
  final int errorMaxLines;

  /// Whether the label floats on focus.
  ///
  /// If this is false, the placeholder disappears when the input has focus or
  /// inputted text.
  /// If this is true, the placeholder will rise to the top of the input when
  /// the input has focus or inputted text.
  ///
  /// Defaults to true.
  final bool hasFloatingPlaceholder;

  /// Whether the input [child] is part of a dense form (i.e., uses less vertical
  /// space).
  ///
  /// Defaults to false.
  final bool isDense;

  /// The padding for the input decoration's container.
  ///
  /// The decoration's container is the area which is filled if [isFilled] is
  /// true and bordered per the [border]. It's the area adjacent to
  /// [decoration.icon] and above the widgets that contain [helperText],
  /// [errorText], and [counterText].
  ///
  /// By default the `contentPadding` reflects [isDense] and the type of the
  /// [border]. If [isCollapsed] is true then `contentPadding` is
  /// [EdgeInsets.zero].
  final EdgeInsetsGeometry contentPadding;

  /// Whether the decoration is the same size as the input field.
  ///
  /// A collapsed decoration cannot have [labelText], [errorText], an [icon].
  ///
  /// To create a collapsed input decoration, use [InputDecoration..collapsed].
  final bool isCollapsed;

  /// An icon that that appears before the [prefixText] and the input and within
  /// the decoration's container.
  ///
  /// The size and color of the prefix icon is configured automatically using an
  /// [IconTheme] and therefore does not need to be explicitly given in the
  /// icon widget.
  ///
  /// The prefix icon is constrained with a minimum size of 48px by 48px, but
  /// can be expanded beyond that. Anything larger than 24px will require
  /// additional padding to ensure it matches the material spec of 12px padding
  /// between the left edge of the input and leading edge of the prefix icon.
  /// To pad the leading edge of the prefix icon:
  ///
  /// ```dart
  /// prefixIcon: Padding(
  ///   padding: const EdgeInsetsDirectional.only(start: 12.0),
  ///   child: myIcon, // icon is 48px widget.
  /// )
  /// ```
  ///
  /// The decoration's container is the area which is filled if [isFilled] is
  /// true and bordered per the [border]. It's the area adjacent to
  /// [decoration.icon] and above the widgets that contain [helperText],
  /// [errorText], and [counterText].
  ///
  /// See [Icon], [ImageIcon].
  final Widget prefixIcon;

  /// Optional widget to place on the line before the input.
  /// Can be used to add some padding to the [prefixText] or to
  /// add a custom widget in front of the input. The widget's baseline
  /// is lined up with the input baseline.
  ///
  /// Only one of [prefix] and [prefixText] can be specified.
  final Widget prefix;

  /// Optional text prefix to place on the line before the input.
  ///
  /// Uses the [prefixStyle]. Uses [hintStyle] if [prefixStyle] isn't
  /// specified. Prefix is not returned as part of the input.
  final String prefixText;

  /// The style to use for the [prefixText].
  ///
  /// If null, defaults to the [hintStyle].
  final TextStyle prefixStyle;

  /// An icon that that appears after the input and [suffixText] and within
  /// the decoration's container.
  ///
  /// The size and color of the suffix icon is configured automatically using an
  /// [IconTheme] and therefore does not need to be explicitly given in the
  /// icon widget.
  ///
  /// The suffix icon is constrained with a minimum size of 48px by 48px, but
  /// can be expanded beyond that. Anything larger than 24px will require
  /// additional padding to ensure it matches the material spec of 12px padding
  /// between the right edge of the input and trailing edge of the prefix icon.
  /// To pad the trailing edge of the suffix icon:
  ///
  /// ```dart
  /// suffixIcon: Padding(
  ///   padding: const EdgeInsetsDirectional.only(end: 12.0),
  ///   child: myIcon, // icon is 48px widget.
  /// )
  /// ```
  ///
  /// The decoration's container is the area which is filled if [isFilled] is
  /// true and bordered per the [border]. It's the area adjacent to
  /// [decoration.icon] and above the widgets that contain [helperText],
  /// [errorText], and [counterText].
  ///
  /// See [Icon], [ImageIcon].
  final Widget suffixIcon;

  /// Optional widget to place on the line after the input.
  /// Can be used to add some padding to the [suffixText] or to
  /// add a custom widget after the input. The widget's baseline
  /// is lined up with the input baseline.
  ///
  /// Only one of [suffix] and [suffixText] can be specified.
  final Widget suffix;

  /// Optional text suffix to place on the line after the input.
  ///
  /// Uses the [suffixStyle]. Uses [hintStyle] if [suffixStyle] isn't
  /// specified. Suffix is not returned as part of the input.
  final String suffixText;

  /// The style to use for the [suffixText].
  ///
  /// If null, defaults to the [hintStyle].
  final TextStyle suffixStyle;

  /// Optional text to place below the line as a character count.
  ///
  /// Rendered using [counterStyle]. Uses [helperStyle] if [counterStyle] is
  /// null.
  ///
  /// The semantic label can be replaced by providing a [semanticCounterText].
  final String counterText;

  /// The style to use for the [counterText].
  ///
  /// If null, defaults to the [helperStyle].
  final TextStyle counterStyle;

  /// If true the decoration's container is filled with [fillColor].
  ///
  /// Typically this field set to true if [border] is
  /// [const UnderlineInputBorder()].
  ///
  /// The decoration's container is the area which is filled if [isFilled] is
  /// true and bordered per the [border]. It's the area adjacent to
  /// [decoration.icon] and above the widgets that contain [helperText],
  /// [errorText], and [counterText].
  ///
  /// This property is false by default.
  final bool filled;

  /// The color to fill the decoration's container with, if [filled] is true.
  ///
  /// By default the fillColor is based on the current [Theme].
  ///
  /// The decoration's container is the area which is filled if [isFilled] is
  /// true and bordered per the [border]. It's the area adjacent to
  /// [decoration.icon] and above the widgets that contain [helperText],
  /// [errorText], and [counterText].
  final Color fillColor;

  /// The border to display when the [InputDecorator] does not have the focus and
  /// is showing an error.
  ///
  /// See also:
  ///  * [InputDecorator.isFocused], which is true if the [InputDecorator]'s child
  ///    has the focus.
  ///  * [InputDecoration.errorText], the error shown by the [InputDecorator], if non-null.
  ///  * [border], for a description of where the [InputDecorator] border appears.
  ///  * [UnderlineInputBorder], an [InputDecorator] border which draws a horizontal
  ///    line at the bottom of the input decorator's container.
  ///  * [OutlineInputBorder], an [InputDecorator] border which draws a
  ///    rounded rectangle around the input decorator's container.
  ///  * [InputBorder.none], which doesn't draw a border.
  ///  * [focusedBorder], displayed when [InputDecorator.isFocused] is true
  ///    and [InputDecoration.errorText] is null.
  ///  * [focusedErrorBorder], displayed when [InputDecorator.isFocused] is true
  ///    and [InputDecoration.errorText] is non-null.
  ///  * [disabledBorder], displayed when [InputDecoration.enabled] is false
  ///    and [InputDecoration.errorText] is null.
  ///  * [enabledBorder], displayed when [InputDecoration.enabled] is true
  ///    and [InputDecoration.errorText] is null.
  final InputBorder errorBorder;

  /// The border to display when the [InputDecorator] has the focus and is not
  /// showing an error.
  ///
  /// See also:
  ///
  ///  * [InputDecorator.isFocused], which is true if the [InputDecorator]'s child
  ///    has the focus.
  ///  * [InputDecoration.errorText], the error shown by the [InputDecorator], if non-null.
  ///  * [border], for a description of where the [InputDecorator] border appears.
  ///  * [UnderlineInputBorder], an [InputDecorator] border which draws a horizontal
  ///    line at the bottom of the input decorator's container.
  ///  * [OutlineInputBorder], an [InputDecorator] border which draws a
  ///    rounded rectangle around the input decorator's container.
  ///  * [InputBorder.none], which doesn't draw a border.
  ///  * [errorBorder], displayed when [InputDecorator.isFocused] is false
  ///    and [InputDecoration.errorText] is non-null.
  ///  * [focusedErrorBorder], displayed when [InputDecorator.isFocused] is true
  ///    and [InputDecoration.errorText] is non-null.
  ///  * [disabledBorder], displayed when [InputDecoration.enabled] is false
  ///    and [InputDecoration.errorText] is null.
  ///  * [enabledBorder], displayed when [InputDecoration.enabled] is true
  ///    and [InputDecoration.errorText] is null.
  final InputBorder focusedBorder;

  /// The border to display when the [InputDecorator] has the focus and is
  /// showing an error.
  ///
  /// See also:
  ///
  ///  * [InputDecorator.isFocused], which is true if the [InputDecorator]'s child
  ///    has the focus.
  ///  * [InputDecoration.errorText], the error shown by the [InputDecorator], if non-null.
  ///  * [border], for a description of where the [InputDecorator] border appears.
  ///  * [UnderlineInputBorder], an [InputDecorator] border which draws a horizontal
  ///    line at the bottom of the input decorator's container.
  ///  * [OutlineInputBorder], an [InputDecorator] border which draws a
  ///    rounded rectangle around the input decorator's container.
  ///  * [InputBorder.none], which doesn't draw a border.
  ///  * [errorBorder], displayed when [InputDecorator.isFocused] is false
  ///    and [InputDecoration.errorText] is non-null.
  ///  * [focusedBorder], displayed when [InputDecorator.isFocused] is true
  ///    and [InputDecoration.errorText] is null.
  ///  * [disabledBorder], displayed when [InputDecoration.enabled] is false
  ///    and [InputDecoration.errorText] is null.
  ///  * [enabledBorder], displayed when [InputDecoration.enabled] is true
  ///    and [InputDecoration.errorText] is null.
  final InputBorder focusedErrorBorder;

  /// The border to display when the [InputDecorator] is disabled and is not
  /// showing an error.
  ///
  /// See also:
  ///
  ///  * [InputDecoration.enabled], which is false if the [InputDecorator] is disabled.
  ///  * [InputDecoration.errorText], the error shown by the [InputDecorator], if non-null.
  ///  * [border], for a description of where the [InputDecorator] border appears.
  ///  * [UnderlineInputBorder], an [InputDecorator] border which draws a horizontal
  ///    line at the bottom of the input decorator's container.
  ///  * [OutlineInputBorder], an [InputDecorator] border which draws a
  ///    rounded rectangle around the input decorator's container.
  ///  * [InputBorder.none], which doesn't draw a border.
  ///  * [errorBorder], displayed when [InputDecorator.isFocused] is false
  ///    and [InputDecoration.errorText] is non-null.
  ///  * [focusedBorder], displayed when [InputDecorator.isFocused] is true
  ///    and [InputDecoration.errorText] is null.
  ///  * [focusedErrorBorder], displayed when [InputDecorator.isFocused] is true
  ///    and [InputDecoration.errorText] is non-null.
  ///  * [enabledBorder], displayed when [InputDecoration.enabled] is true
  ///    and [InputDecoration.errorText] is null.
  final InputBorder disabledBorder;

  /// The border to display when the [InputDecorator] is enabled and is not
  /// showing an error.
  ///
  /// See also:
  ///
  ///  * [InputDecoration.enabled], which is false if the [InputDecorator] is disabled.
  ///  * [InputDecoration.errorText], the error shown by the [InputDecorator], if non-null.
  ///  * [border], for a description of where the [InputDecorator] border appears.
  ///  * [UnderlineInputBorder], an [InputDecorator] border which draws a horizontal
  ///    line at the bottom of the input decorator's container.
  ///  * [OutlineInputBorder], an [InputDecorator] border which draws a
  ///    rounded rectangle around the input decorator's container.
  ///  * [InputBorder.none], which doesn't draw a border.
  ///  * [errorBorder], displayed when [InputDecorator.isFocused] is false
  ///    and [InputDecoration.errorText] is non-null.
  ///  * [focusedBorder], displayed when [InputDecorator.isFocused] is true
  ///    and [InputDecoration.errorText] is null.
  ///  * [focusedErrorBorder], displayed when [InputDecorator.isFocused] is true
  ///    and [InputDecoration.errorText] is non-null.
  ///  * [disabledBorder], displayed when [InputDecoration.enabled] is false
  ///    and [InputDecoration.errorText] is null.
  final InputBorder enabledBorder;

  /// The shape of the border to draw around the decoration's container.
  ///
  /// This border's [InputBorder.borderSide], i.e. the border's color and width,
  /// will be overridden to reflect the input decorator's state. Only the
  /// border's shape is used. If custom  [BorderSide] values are desired for
  /// a given state, all four borders – [errorBorder], [focusedBorder],
  /// [enabledBorder], [disabledBorder] – must be set.
  ///
  /// The decoration's container is the area which is filled if [isFilled] is
  /// true and bordered per the [border]. It's the area adjacent to
  /// [InputDecoration.icon] and above the widgets that contain
  /// [InputDecoration.helperText], [InputDecoration.errorText], and
  /// [InputDecoration.counterText].
  ///
  /// The border's bounds, i.e. the value of `border.getOuterPath()`, define
  /// the area to be filled.
  ///
  /// This property is only used when the appropriate one of [errorBorder],
  /// [focusedBorder], [focusedErrorBorder], [disabledBorder], or [enabledBorder]
  /// is not specified. This border's [InputBorder.borderSide] property is
  /// configured by the InputDecorator, depending on the values of
  /// [InputDecoration.errorText], [InputDecoration.enabled],
  /// [InputDecorator.isFocused and the current [Theme].
  ///
  /// Typically one of [UnderlineInputBorder] or [OutlineInputBorder].
  /// If null, InputDecorator's default is `const UnderlineInputBorder()`.
  ///
  /// See also:
  ///
  ///  * [InputBorder.none], which doesn't draw a border.
  ///  * [UnderlineInputBorder], which draws a horizontal line at the
  ///    bottom of the input decorator's container.
  ///  * [OutlineInputBorder], an [InputDecorator] border which draws a
  ///    rounded rectangle around the input decorator's container.
  final InputBorder border;

  /// If false [helperText],[errorText], and [counterText] are not displayed,
  /// and the opacity of the remaining visual elements is reduced.
  ///
  /// This property is true by default.
  final bool enabled;

  /// A semantic label for the [counterText].
  ///
  /// Defaults to null.
  ///
  /// If provided, this replaces the semantic label of the [counterText].
  final String semanticCounterText;

  /// Creates a copy of this input decoration with the given fields replaced
  /// by the new values.
  ///
  /// Always sets [isCollapsed] to false.
  InputDecoration copyWith({
    Widget icon,
    String labelText,
    TextStyle labelStyle,
    String helperText,
    TextStyle helperStyle,
    String hintText,
    TextStyle hintStyle,
    String errorText,
    TextStyle errorStyle,
    int errorMaxLines,
    bool hasFloatingPlaceholder,
    bool isDense,
    EdgeInsetsGeometry contentPadding,
    Widget prefixIcon,
    Widget prefix,
    String prefixText,
    TextStyle prefixStyle,
    Widget suffixIcon,
    Widget suffix,
    String suffixText,
    TextStyle suffixStyle,
    String counterText,
    TextStyle counterStyle,
    bool filled,
    Color fillColor,
    InputBorder errorBorder,
    InputBorder focusedBorder,
    InputBorder focusedErrorBorder,
    InputBorder disabledBorder,
    InputBorder enabledBorder,
    InputBorder border,
    bool enabled,
    String semanticCounterText,
  }) {
    return InputDecoration(
      icon: icon ?? this.icon,
      labelText: labelText ?? this.labelText,
      labelStyle: labelStyle ?? this.labelStyle,
      helperText: helperText ?? this.helperText,
      helperStyle: helperStyle ?? this.helperStyle,
      hintText: hintText ?? this.hintText,
      hintStyle: hintStyle ?? this.hintStyle,
      errorText: errorText ?? this.errorText,
      errorStyle: errorStyle ?? this.errorStyle,
      errorMaxLines: errorMaxLines ?? this.errorMaxLines,
      hasFloatingPlaceholder: hasFloatingPlaceholder ?? this.hasFloatingPlaceholder,
      isDense: isDense ?? this.isDense,
      contentPadding: contentPadding ?? this.contentPadding,
      prefixIcon: prefixIcon ?? this.prefixIcon,
      prefix: prefix ?? this.prefix,
      prefixText: prefixText ?? this.prefixText,
      prefixStyle: prefixStyle ?? this.prefixStyle,
      suffixIcon: suffixIcon ?? this.suffixIcon,
      suffix: suffix ?? this.suffix,
      suffixText: suffixText ?? this.suffixText,
      suffixStyle: suffixStyle ?? this.suffixStyle,
      counterText: counterText ?? this.counterText,
      counterStyle: counterStyle ?? this.counterStyle,
      filled: filled ?? this.filled,
      fillColor: fillColor ?? this.fillColor,
      errorBorder: errorBorder ?? this.errorBorder,
      focusedBorder: focusedBorder ?? this.focusedBorder,
      focusedErrorBorder: focusedErrorBorder ?? this.focusedErrorBorder,
      disabledBorder: disabledBorder ?? this.disabledBorder,
      enabledBorder: enabledBorder ?? this.enabledBorder,
      border: border ?? this.border,
      enabled: enabled ?? this.enabled,
      semanticCounterText: semanticCounterText ?? this.semanticCounterText,
    );
  }

  /// Used by widgets like [TextField] and [InputDecorator] to create a new
  /// [InputDecoration] with default values taken from the [theme].
  ///
  /// Only null valued properties from this [InputDecoration] are replaced
  /// by the corresponding values from [theme].
  InputDecoration applyDefaults(InputDecorationTheme theme) {
    return copyWith(
      labelStyle: labelStyle ?? theme.labelStyle,
      helperStyle: helperStyle ?? theme.helperStyle,
      hintStyle: hintStyle ?? theme.hintStyle,
      errorStyle: errorStyle ?? theme.errorStyle,
      errorMaxLines: errorMaxLines ?? theme.errorMaxLines,
      hasFloatingPlaceholder: hasFloatingPlaceholder ?? theme.hasFloatingPlaceholder,
      isDense: isDense ?? theme.isDense,
      contentPadding: contentPadding ?? theme.contentPadding,
      prefixStyle: prefixStyle ?? theme.prefixStyle,
      suffixStyle: suffixStyle ?? theme.suffixStyle,
      counterStyle: counterStyle ?? theme.counterStyle,
      filled: filled ?? theme.filled,
      fillColor: fillColor ?? theme.fillColor,
      errorBorder: errorBorder ?? theme.errorBorder,
      focusedBorder: focusedBorder ?? theme.focusedBorder,
      focusedErrorBorder: focusedErrorBorder ?? theme.focusedErrorBorder,
      disabledBorder: disabledBorder ?? theme.disabledBorder,
      enabledBorder: enabledBorder ?? theme.enabledBorder,
      border: border ?? theme.border,
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    final InputDecoration typedOther = other;
    return typedOther.icon == icon
        && typedOther.labelText == labelText
        && typedOther.labelStyle == labelStyle
        && typedOther.helperText == helperText
        && typedOther.helperStyle == helperStyle
        && typedOther.hintText == hintText
        && typedOther.hintStyle == hintStyle
        && typedOther.errorText == errorText
        && typedOther.errorStyle == errorStyle
        && typedOther.errorMaxLines == errorMaxLines
        && typedOther.hasFloatingPlaceholder == hasFloatingPlaceholder
        && typedOther.isDense == isDense
        && typedOther.contentPadding == contentPadding
        && typedOther.isCollapsed == isCollapsed
        && typedOther.prefixIcon == prefixIcon
        && typedOther.prefix == prefix
        && typedOther.prefixText == prefixText
        && typedOther.prefixStyle == prefixStyle
        && typedOther.suffixIcon == suffixIcon
        && typedOther.suffix == suffix
        && typedOther.suffixText == suffixText
        && typedOther.suffixStyle == suffixStyle
        && typedOther.counterText == counterText
        && typedOther.counterStyle == counterStyle
        && typedOther.filled == filled
        && typedOther.fillColor == fillColor
        && typedOther.errorBorder == errorBorder
        && typedOther.focusedBorder == focusedBorder
        && typedOther.focusedErrorBorder == focusedErrorBorder
        && typedOther.disabledBorder == disabledBorder
        && typedOther.enabledBorder == enabledBorder
        && typedOther.border == border
        && typedOther.enabled == enabled
        && typedOther.semanticCounterText == semanticCounterText;
  }

  @override
  int get hashCode {
    // Split into multiple hashValues calls
    // because the hashValues function is limited to 20 parameters.
    return hashValues(
      icon,
      labelText,
      labelStyle,
      helperText,
      helperStyle,
      hintText,
      hintStyle,
      errorText,
      errorStyle,
      errorMaxLines,
      hasFloatingPlaceholder,
      isDense,
      hashValues(
        contentPadding,
        isCollapsed,
        filled,
        fillColor,
        border,
        enabled,
        prefixIcon,
        prefix,
        prefixText,
        prefixStyle,
        suffixIcon,
        suffix,
        suffixText,
      ),
      hashValues(
        suffixStyle,
        counterText,
        counterStyle,
        filled,
        fillColor,
        errorBorder,
        focusedBorder,
        focusedErrorBorder,
        disabledBorder,
        enabledBorder,
        border,
        enabled,
        semanticCounterText,
      ),
    );
  }

  @override
  String toString() {
    final List<String> description = <String>[];
    if (icon != null)
      description.add('icon: $icon');
    if (labelText != null)
      description.add('labelText: "$labelText"');
    if (helperText != null)
      description.add('helperText: "$helperText"');
    if (hintText != null)
      description.add('hintText: "$hintText"');
    if (errorText != null)
      description.add('errorText: "$errorText"');
    if (errorStyle != null)
      description.add('errorStyle: "$errorStyle"');
    if (errorMaxLines != null)
      description.add('errorMaxLines: "$errorMaxLines"');
    if (hasFloatingPlaceholder == false)
      description.add('hasFloatingPlaceholder: false');
    if (isDense ?? false)
      description.add('isDense: $isDense');
    if (contentPadding != null)
      description.add('contentPadding: $contentPadding');
    if (isCollapsed)
      description.add('isCollapsed: $isCollapsed');
    if (prefixIcon != null)
      description.add('prefixIcon: $prefixIcon');
    if (prefix != null)
      description.add('prefix: $prefix');
    if (prefixText != null)
      description.add('prefixText: $prefixText');
    if (prefixStyle != null)
      description.add('prefixStyle: $prefixStyle');
    if (suffixIcon != null)
      description.add('suffixIcon: $suffixIcon');
    if (suffix != null)
      description.add('suffix: $suffix');
    if (suffixText != null)
      description.add('suffixText: $suffixText');
    if (suffixStyle != null)
      description.add('suffixStyle: $suffixStyle');
    if (counterText != null)
      description.add('counterText: $counterText');
    if (counterStyle != null)
      description.add('counterStyle: $counterStyle');
    if (filled == true) // filled == null same as filled == false
      description.add('filled: true');
    if (fillColor != null)
      description.add('fillColor: $fillColor');
    if (errorBorder != null)
      description.add('errorBorder: $errorBorder');
    if (focusedBorder != null)
      description.add('focusedBorder: $focusedBorder');
    if (focusedErrorBorder != null)
      description.add('focusedErrorBorder: $focusedErrorBorder');
    if (disabledBorder != null)
      description.add('disabledBorder: $disabledBorder');
    if (enabledBorder != null)
      description.add('enabledBorder: $enabledBorder');
    if (border != null)
      description.add('border: $border');
    if (!enabled)
      description.add('enabled: false');
    if (semanticCounterText != null)
      description.add('semanticCounterText: $semanticCounterText');
    return 'InputDecoration(${description.join(', ')})';
  }
}

/// Defines the default appearance of [InputDecorator]s.
///
/// This class is used to define the value of [ThemeData.inputDecorationTheme].
/// The [InputDecorator], [TextField], and [TextFormField] widgets use
/// the current input decoration theme to initialize null [InputDecoration]
/// properties.
///
/// The [InputDecoration.applyDefaults] method is used to combine a input
/// decoration theme with an [InputDecoration] object.
@immutable
class InputDecorationTheme extends Diagnosticable {
  /// Creates a value for [ThemeData.inputDecorationTheme] that
  /// defines default values for [InputDecorator].
  ///
  /// The values of [isDense], [isCollapsed], [isFilled], and [border] must
  /// not be null.
  const InputDecorationTheme({
    this.labelStyle,
    this.helperStyle,
    this.hintStyle,
    this.errorStyle,
    this.errorMaxLines,
    this.hasFloatingPlaceholder = true,
    this.isDense = false,
    this.contentPadding,
    this.isCollapsed = false,
    this.prefixStyle,
    this.suffixStyle,
    this.counterStyle,
    this.filled = false,
    this.fillColor,
    this.errorBorder,
    this.focusedBorder,
    this.focusedErrorBorder,
    this.disabledBorder,
    this.enabledBorder,
    this.border,
  }) : assert(isDense != null),
       assert(isCollapsed != null),
      assert(filled != null);

  /// The style to use for [InputDecoration.labelText] when the label is
  /// above (i.e., vertically adjacent to) the input field.
  ///
  /// When the [labelText] is on top of the input field, the text uses the
  /// [hintStyle] instead.
  ///
  /// If null, defaults to a value derived from the base [TextStyle] for the
  /// input field and the current [Theme].
  final TextStyle labelStyle;

  /// The style to use for [InputDecoration.helperText].
  final TextStyle helperStyle;

  /// The style to use for the [InputDecoration.hintText].
  ///
  /// Also used for the [labelText] when the [labelText] is displayed on
  /// top of the input field (i.e., at the same location on the screen where
  /// text may be entered in the input field).
  ///
  /// If null, defaults to a value derived from the base [TextStyle] for the
  /// input field and the current [Theme].
  final TextStyle hintStyle;

  /// The style to use for the [InputDecoration.errorText].
  ///
  /// If null, defaults of a value derived from the base [TextStyle] for the
  /// input field and the current [Theme].
  final TextStyle errorStyle;

  /// The maximum number of lines the [errorText] can occupy.
  ///
  /// Defaults to null, which means that the [errorText] will be limited
  /// to a single line with [TextOverflow.ellipsis].
  ///
  /// This value is passed along to the [Text.maxLines] attribute
  /// of the [Text] widget used to display the error.
  final int errorMaxLines;

  /// Whether the placeholder text floats to become a label on focus.
  ///
  /// If this is false, the placeholder disappears when the input has focus or
  /// inputted text.
  /// If this is true, the placeholder will rise to the top of the input when
  /// the input has focus or inputted text.
  ///
  /// Defaults to true.
  final bool hasFloatingPlaceholder;

  /// Whether the input decorator's child is part of a dense form (i.e., uses
  /// less vertical space).
  ///
  /// Defaults to false.
  final bool isDense;

  /// The padding for the input decoration's container.
  ///
  /// The decoration's container is the area which is filled if
  /// [InputDecoration.isFilled] is true and bordered per the [border].
  /// It's the area adjacent to [InputDecoration.icon] and above the
  /// [InputDecoration.icon] and above the widgets that contain
  /// [InputDecoration.helperText], [InputDecoration.errorText], and
  /// [InputDecoration.counterText].
  ///
  /// By default the `contentPadding` reflects [isDense] and the type of the
  /// [border]. If [isCollapsed] is true then `contentPadding` is
  /// [EdgeInsets.zero].
  final EdgeInsetsGeometry contentPadding;

  /// Whether the decoration is the same size as the input field.
  ///
  /// A collapsed decoration cannot have [InputDecoration.labelText],
  /// [InputDecoration.errorText], or an [InputDecoration.icon].
  final bool isCollapsed;

  /// The style to use for the [InputDecoration.prefixText].
  ///
  /// If null, defaults to the [hintStyle].
  final TextStyle prefixStyle;

  /// The style to use for the [InputDecoration.suffixText].
  ///
  /// If null, defaults to the [hintStyle].
  final TextStyle suffixStyle;

  /// The style to use for the [InputDecoration.counterText].
  ///
  /// If null, defaults to the [helperStyle].
  final TextStyle counterStyle;

  /// If true the decoration's container is filled with [fillColor].
  ///
  /// Typically this field set to true if [border] is
  /// [const UnderlineInputBorder()].
  ///
  /// The decoration's container is the area, defined by the border's
  /// [InputBorder.getOuterPath], which is filled if [isFilled] is
  /// true and bordered per the [border].
  ///
  /// This property is false by default.
  final bool filled;

  /// The color to fill the decoration's container with, if [filled] is true.
  ///
  /// By default the fillColor is based on the current [Theme].
  ///
  /// The decoration's container is the area, defined by the border's
  /// [InputBorder.getOuterPath], which is filled if [isFilled] is
  /// true and bordered per the [border].
  final Color fillColor;

  /// The border to display when the [InputDecorator] does not have the focus and
  /// is showing an error.
  ///
  /// See also:
  ///  * [InputDecorator.isFocused], which is true if the [InputDecorator]'s child
  ///    has the focus.
  ///  * [InputDecoration.errorText], the error shown by the [InputDecorator], if non-null.
  ///  * [border], for a description of where the [InputDecorator] border appears.
  ///  * [UnderlineInputBorder], an [InputDecorator] border which draws a horizontal
  ///    line at the bottom of the input decorator's container.
  ///  * [OutlineInputBorder], an [InputDecorator] border which draws a
  ///    rounded rectangle around the input decorator's container.
  ///  * [InputBorder.none], which doesn't draw a border.
  ///  * [focusedBorder], displayed when [InputDecorator.isFocused] is true
  ///    and [InputDecoration.errorText] is null.
  ///  * [focusedErrorBorder], displayed when [InputDecorator.isFocused] is true
  ///    and [InputDecoration.errorText] is non-null.
  ///  * [disabledBorder], displayed when [InputDecoration.enabled] is false
  ///    and [InputDecoration.errorText] is null.
  ///  * [enabledBorder], displayed when [InputDecoration.enabled] is true
  ///    and [InputDecoration.errorText] is null.
  final InputBorder errorBorder;

  /// The border to display when the [InputDecorator] has the focus and is not
  /// showing an error.
  ///
  /// See also:
  ///
  ///  * [InputDecorator.isFocused], which is true if the [InputDecorator]'s child
  ///    has the focus.
  ///  * [InputDecoration.errorText], the error shown by the [InputDecorator], if non-null.
  ///  * [border], for a description of where the [InputDecorator] border appears.
  ///  * [UnderlineInputBorder], an [InputDecorator] border which draws a horizontal
  ///    line at the bottom of the input decorator's container.
  ///  * [OutlineInputBorder], an [InputDecorator] border which draws a
  ///    rounded rectangle around the input decorator's container.
  ///  * [InputBorder.none], which doesn't draw a border.
  ///  * [errorBorder], displayed when [InputDecorator.isFocused] is false
  ///    and [InputDecoration.errorText] is non-null.
  ///  * [focusedErrorBorder], displayed when [InputDecorator.isFocused] is true
  ///    and [InputDecoration.errorText] is non-null.
  ///  * [disabledBorder], displayed when [InputDecoration.enabled] is false
  ///    and [InputDecoration.errorText] is null.
  ///  * [enabledBorder], displayed when [InputDecoration.enabled] is true
  ///    and [InputDecoration.errorText] is null.
  final InputBorder focusedBorder;

  /// The border to display when the [InputDecorator] has the focus and is
  /// showing an error.
  ///
  /// See also:
  ///
  ///  * [InputDecorator.isFocused], which is true if the [InputDecorator]'s child
  ///    has the focus.
  ///  * [InputDecoration.errorText], the error shown by the [InputDecorator], if non-null.
 ///  * [border], for a description of where the [InputDecorator] border appears.
  ///  * [UnderlineInputBorder], an [InputDecorator] border which draws a horizontal
  ///    line at the bottom of the input decorator's container.
  ///  * [OutlineInputBorder], an [InputDecorator] border which draws a
  ///    rounded rectangle around the input decorator's container.
  ///  * [InputBorder.none], which doesn't draw a border.
  ///  * [errorBorder], displayed when [InputDecorator.isFocused] is false
  ///    and [InputDecoration.errorText] is non-null.
  ///  * [focusedBorder], displayed when [InputDecorator.isFocused] is true
  ///    and [InputDecoration.errorText] is null.
  ///  * [disabledBorder], displayed when [InputDecoration.enabled] is false
  ///    and [InputDecoration.errorText] is null.
  ///  * [enabledBorder], displayed when [InputDecoration.enabled] is true
  ///    and [InputDecoration.errorText] is null.
  final InputBorder focusedErrorBorder;

   /// The border to display when the [InputDecorator] is disabled and is not
  /// showing an error.
  ///
  /// See also:
  ///
  ///  * [InputDecoration.enabled], which is false if the [InputDecorator] is disabled.
  ///  * [InputDecoration.errorText], the error shown by the [InputDecorator], if non-null.
  ///  * [border], for a description of where the [InputDecorator] border appears.
  ///  * [UnderlineInputBorder], an [InputDecorator] border which draws a horizontal
  ///    line at the bottom of the input decorator's container.
  ///  * [OutlineInputBorder], an [InputDecorator] border which draws a
  ///    rounded rectangle around the input decorator's container.
  ///  * [InputBorder.none], which doesn't draw a border.
  ///  * [errorBorder], displayed when [InputDecorator.isFocused] is false
  ///    and [InputDecoration.errorText] is non-null.
  ///  * [focusedBorder], displayed when [InputDecorator.isFocused] is true
  ///    and [InputDecoration.errorText] is null.
  ///  * [focusedErrorBorder], displayed when [InputDecorator.isFocused] is true
  ///    and [InputDecoration.errorText] is non-null.
  ///  * [enabledBorder], displayed when [InputDecoration.enabled] is true
  ///    and [InputDecoration.errorText] is null.
  final InputBorder disabledBorder;

  /// The border to display when the [InputDecorator] is enabled and is not
  /// showing an error.
  ///
  /// See also:
  ///
  ///  * [InputDecoration.enabled], which is false if the [InputDecorator] is disabled.
  ///  * [InputDecoration.errorText], the error shown by the [InputDecorator], if non-null.
  ///  * [border], for a description of where the [InputDecorator] border appears.
  ///  * [UnderlineInputBorder], an [InputDecorator] border which draws a horizontal
  ///    line at the bottom of the input decorator's container.
  ///  * [OutlineInputBorder], an [InputDecorator] border which draws a
  ///    rounded rectangle around the input decorator's container.
  ///  * [InputBorder.none], which doesn't draw a border.
  ///  * [errorBorder], displayed when [InputDecorator.isFocused] is false
  ///    and [InputDecoration.errorText] is non-null.
  ///  * [focusedBorder], displayed when [InputDecorator.isFocused] is true
  ///    and [InputDecoration.errorText] is null.
  ///  * [focusedErrorBorder], displayed when [InputDecorator.isFocused] is true
  ///    and [InputDecoration.errorText] is non-null.
  ///  * [disabledBorder], displayed when [InputDecoration.enabled] is false
  ///    and [InputDecoration.errorText] is null.
  final InputBorder enabledBorder;

  /// The shape of the border to draw around the decoration's container.
  ///
  /// The decoration's container is the area which is filled if [isFilled] is
  /// true and bordered per the [border]. It's the area adjacent to
  /// [InputDecoration.icon] and above the widgets that contain
  /// [InputDecoration.helperText], [InputDecoration.errorText], and
  /// [InputDecoration.counterText].
  ///
  /// The border's bounds, i.e. the value of `border.getOuterPath()`, define
  /// the area to be filled.
  ///
  /// This property is only used when the appropriate one of [errorBorder],
  /// [focusedBorder], [focusedErrorBorder], [disabledBorder], or [enabledBorder]
  /// is not specified. This border's [InputBorder.borderSide] property is
  /// configured by the InputDecorator, depending on the values of
  /// [InputDecoration.errorText], [InputDecoration.enabled],
  /// [InputDecorator.isFocused and the current [Theme].
  ///
  /// Typically one of [UnderlineInputBorder] or [OutlineInputBorder].
  /// If null, InputDecorator's default is `const UnderlineInputBorder()`.
  ///
  /// See also:
  ///
  ///  * [InputBorder.none], which doesn't draw a border.
  ///  * [UnderlineInputBorder], which draws a horizontal line at the
  ///    bottom of the input decorator's container.
  ///  * [OutlineInputBorder], an [InputDecorator] border which draws a
  ///    rounded rectangle around the input decorator's container.
  final InputBorder border;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    const InputDecorationTheme defaultTheme = InputDecorationTheme();
    properties.add(DiagnosticsProperty<TextStyle>('labelStyle', labelStyle, defaultValue: defaultTheme.labelStyle));
    properties.add(DiagnosticsProperty<TextStyle>('helperStyle', helperStyle, defaultValue: defaultTheme.helperStyle));
    properties.add(DiagnosticsProperty<TextStyle>('hintStyle', hintStyle, defaultValue: defaultTheme.hintStyle));
    properties.add(DiagnosticsProperty<TextStyle>('errorStyle', errorStyle, defaultValue: defaultTheme.errorStyle));
    properties.add(DiagnosticsProperty<int>('errorMaxLines', errorMaxLines, defaultValue: defaultTheme.errorMaxLines));
    properties.add(DiagnosticsProperty<bool>('hasFloatingPlaceholder', hasFloatingPlaceholder, defaultValue: defaultTheme.hasFloatingPlaceholder));
    properties.add(DiagnosticsProperty<bool>('isDense', isDense, defaultValue: defaultTheme.isDense));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('contentPadding', contentPadding, defaultValue: defaultTheme.contentPadding));
    properties.add(DiagnosticsProperty<bool>('isCollapsed', isCollapsed, defaultValue: defaultTheme.isCollapsed));
    properties.add(DiagnosticsProperty<TextStyle>('prefixStyle', prefixStyle, defaultValue: defaultTheme.prefixStyle));
    properties.add(DiagnosticsProperty<TextStyle>('suffixStyle', suffixStyle, defaultValue: defaultTheme.suffixStyle));
    properties.add(DiagnosticsProperty<TextStyle>('counterStyle', counterStyle, defaultValue: defaultTheme.counterStyle));
    properties.add(DiagnosticsProperty<bool>('filled', filled, defaultValue: defaultTheme.filled));
    properties.add(DiagnosticsProperty<Color>('fillColor', fillColor, defaultValue: defaultTheme.fillColor));
    properties.add(DiagnosticsProperty<InputBorder>('errorBorder', errorBorder, defaultValue: defaultTheme.errorBorder));
    properties.add(DiagnosticsProperty<InputBorder>('focusedBorder', focusedBorder, defaultValue: defaultTheme.focusedErrorBorder));
    properties.add(DiagnosticsProperty<InputBorder>('focusedErrorborder', focusedErrorBorder, defaultValue: defaultTheme.focusedErrorBorder));
    properties.add(DiagnosticsProperty<InputBorder>('disabledBorder', disabledBorder, defaultValue: defaultTheme.disabledBorder));
    properties.add(DiagnosticsProperty<InputBorder>('enabledBorder', enabledBorder, defaultValue: defaultTheme.enabledBorder));
    properties.add(DiagnosticsProperty<InputBorder>('border', border, defaultValue: defaultTheme.border));
  }
}
