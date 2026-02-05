// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../foundation/_features.dart';
import 'binding.dart';
import 'editable_text.dart';
import 'framework.dart';
import 'text.dart';

const String _kAccessibilityEvaluationsDisabledErrorMessage = '''
Accessibility evaluations APIs are not enabled.

Accessibility evaluations APIs are currently experimental. Do not use accessibility evaluations APIs in
production applications or plugins published to pub.dev.

To try experimental accessibility evaluations APIs:
1. Switch to Flutter's main release channel.
2. Turn on the accessibility evaluations feature flag. (See flutter config --help)
''';

/// {@template flutter.widgets.accessibility_evaluations.internal}
/// Do not use in production.
///
/// Flutter will make breaking changes to this API, even in patch versions.
/// {@endtemplate}
///
/// A violation of a semantics node.
@internal
class Violation {
  /// Creates a violation.
  const Violation(this.node, this.reason);

  /// The semantics node that violates the policy.
  final SemanticsNode node;

  /// The reason for the violation.
  final String reason;
}

/// {@macro flutter.widgets.accessibility_evaluations.internal}
///
/// The result of evaluating a semantics node by an [AccessibilityEvaluation].
@internal
class EvaluationResult {
  /// Creates a passing evaluation.
  EvaluationResult(this.violations);

  /// A list of violations found. An empty list means the evaluation passed.
  final List<Violation> violations;
}

/// {@macro flutter.widgets.accessibility_evaluations.internal}
///
/// A class that evaluates a single accessibility rule.
@internal
abstract class AccessibilityEvaluation {
  /// A const constructor allows subclasses to be const.
  const AccessibilityEvaluation();

  /// Evaluate whether the current state of the `binding` conforms to the rule.
  FutureOr<EvaluationResult> evaluate(WidgetsBinding binding) {
    if (!isAccessibilityEvaluationsEnabled) {
      throw UnsupportedError(_kAccessibilityEvaluationsDisabledErrorMessage);
    }
    return _evaluate(binding);
  }

  FutureOr<EvaluationResult> _evaluate(WidgetsBinding binding);
}

/// {@macro flutter.widgets.accessibility_evaluations.internal}
///
/// An evaluation which enforces that all tappable semantics nodes have a minimum
/// size.
@internal
class MinimumTapTargetEvaluation extends AccessibilityEvaluation {
  /// Create a new [MinimumTapTargetEvaluation].
  const MinimumTapTargetEvaluation({required this.size, required this.link});

  /// The minimum allowed size of a tappable node.
  final Size size;

  /// A link describing the tap target evaluations for a platform.
  final String link;

  /// The gap between targets to their parent scrollables to be considered valid
  /// tap targets.
  ///
  /// This avoids cases where a tap target is partially scrolled off-screen that
  /// result in a smaller tap area.
  static const double _kMinimumGapToBoundary = 0.001;

  @override
  FutureOr<EvaluationResult> _evaluate(WidgetsBinding binding) {
    final violations = <Violation>[];
    for (final RenderView view in binding.renderViews) {
      violations.addAll(
        _traverse(view.flutterView, view.owner!.semanticsOwner!.rootSemanticsNode!),
      );
    }

    return EvaluationResult(violations);
  }

  List<Violation> _traverse(ui.FlutterView view, SemanticsNode node) {
    final violations = <Violation>[];
    node.visitChildren((SemanticsNode child) {
      violations.addAll(_traverse(view, child));
      return true;
    });
    if (node.isMergedIntoParent) {
      return violations;
    }
    if (shouldSkipNode(node)) {
      return violations;
    }
    Rect paintBounds = node.rect;
    SemanticsNode? current = node;

    while (current != null) {
      final Matrix4? transform = current.transform;
      if (transform != null) {
        paintBounds = MatrixUtils.transformRect(transform, paintBounds);
      }
      // Skip node if it is touching the edge of the scrollable, since it might
      // be partially scrolled offscreen.
      if (current.flagsCollection.hasImplicitScrolling &&
          _isAtBoundary(paintBounds, current.rect)) {
        return violations;
      }
      current = current.parent;
    }

    final Rect viewRect = Offset.zero & view.physicalSize;
    if (_isAtBoundary(paintBounds, viewRect)) {
      return violations;
    }

    // Shrink by device pixel ratio.
    final Size candidateSize = paintBounds.size / view.devicePixelRatio;
    if (candidateSize.width < size.width - precisionErrorTolerance ||
        candidateSize.height < size.height - precisionErrorTolerance) {
      violations.add(
        Violation(
          node,
          '$node: expected tap target size of at least $size, '
          'but found $candidateSize\n'
          'See also: $link',
        ),
      );
    }
    return violations;
  }

  static bool _isAtBoundary(Rect child, Rect parent) {
    if (child.left - parent.left > _kMinimumGapToBoundary &&
        parent.right - child.right > _kMinimumGapToBoundary &&
        child.top - parent.top > _kMinimumGapToBoundary &&
        parent.bottom - child.bottom > _kMinimumGapToBoundary) {
      return false;
    }
    return true;
  }

  /// Returns whether [SemanticsNode] should be skipped for minimum tap target
  /// evaluation.
  ///
  /// Skips nodes which are link, hidden, or do not have actions.
  bool shouldSkipNode(SemanticsNode node) {
    final SemanticsData data = node.getSemanticsData();
    // Skip node if it has no actions, or is marked as hidden.
    if ((!data.hasAction(ui.SemanticsAction.longPress) &&
            !data.hasAction(ui.SemanticsAction.tap)) ||
        data.flagsCollection.isHidden) {
      return true;
    }
    // Skip links https://www.w3.org/WAI/WCAG21/Understanding/target-size.html
    if (data.flagsCollection.isLink) {
      return true;
    }
    return false;
  }
}

/// {@macro flutter.widgets.accessibility_evaluations.internal}
///
/// An evaluation which enforces that all nodes with a tap or long press action
/// also have a label.
@internal
class LabeledTapTargetEvaluation extends AccessibilityEvaluation {
  const LabeledTapTargetEvaluation();

  @override
  FutureOr<EvaluationResult> _evaluate(WidgetsBinding binding) {
    final violations = <Violation>[];

    for (final RenderView view in binding.renderViews) {
      violations.addAll(_traverse(view.owner!.semanticsOwner!.rootSemanticsNode!));
    }

    return EvaluationResult(violations);
  }

  List<Violation> _traverse(SemanticsNode node) {
    final violations = <Violation>[];
    node.visitChildren((SemanticsNode child) {
      violations.addAll(_traverse(child));
      return true;
    });
    if (node.isMergedIntoParent ||
        node.isInvisible ||
        node.flagsCollection.isHidden ||
        node.flagsCollection.isTextField) {
      return violations;
    }
    final SemanticsData data = node.getSemanticsData();
    // Skip node if it has no actions, or is marked as hidden.
    if (!data.hasAction(ui.SemanticsAction.longPress) && !data.hasAction(ui.SemanticsAction.tap)) {
      return violations;
    }
    if ((data.label.isEmpty) && (data.tooltip.isEmpty)) {
      violations.add(
        Violation(
          node,
          '$node: expected tappable node to have semantic label, '
          'but none was found.',
        ),
      );
    }
    return violations;
  }
}

/// {@macro flutter.widgets.accessibility_evaluations.internal}
///
/// An evaluation which verifies that all nodes that contribute semantics via text
/// meet minimum contrast levels.
///
/// The evaluations are defined by the Web Content Accessibility Guidelines,
/// http://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html.
@internal
class MinimumTextContrastEvaluation extends AccessibilityEvaluation {
  /// Create a new [MinimumTextContrastEvaluation].
  const MinimumTextContrastEvaluation();

  /// The minimum text size considered large for contrast checking.
  ///
  /// Defined by http://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html
  static const int kLargeTextMinimumSize = 18;

  /// The minimum text size for bold text to be considered large for contrast
  /// checking.
  ///
  /// Defined by http://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html
  static const int kBoldTextMinimumSize = 14;

  /// The minimum contrast ratio for normal text.
  ///
  /// Defined by http://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html
  static const double kMinimumRatioNormalText = 4.5;

  /// The minimum contrast ratio for large text.
  ///
  /// Defined by http://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html
  static const double kMinimumRatioLargeText = 3.0;

  static const double _kDefaultFontSize = 12.0;

  static const double _tolerance = -0.01;

  @override
  Future<EvaluationResult> _evaluate(WidgetsBinding binding) async {
    final violations = <Violation>[];
    for (final RenderView renderView in binding.renderViews) {
      final layer = renderView.debugLayer! as OffsetLayer;
      final SemanticsNode root = renderView.owner!.semanticsOwner!.rootSemanticsNode!;

      late ui.Image image;
      // Needs to be the same pixel ratio otherwise our dimensions won't match
      // the last transform layer.
      final double ratio = 1 / renderView.flutterView.devicePixelRatio;
      image = await layer.toImage(renderView.paintBounds, pixelRatio: ratio);
      final ByteData? byteData = await image.toByteData();

      violations.addAll(await _evaluateNode(root, image, byteData!, renderView));
      image.dispose();
    }

    return EvaluationResult(violations);
  }

  Future<List<Violation>> _evaluateNode(
    SemanticsNode node,
    ui.Image image,
    ByteData byteData,
    RenderView renderView,
  ) async {
    final violations = <Violation>[];

    // Skip disabled nodes, as they are not required to pass contrast checks.
    final isDisabled = node.flagsCollection.isEnabled == ui.Tristate.isFalse;

    if (node.isInvisible ||
        node.isMergedIntoParent ||
        node.flagsCollection.isHidden ||
        isDisabled) {
      return violations;
    }

    final SemanticsData data = node.getSemanticsData();
    final children = <SemanticsNode>[];
    node.visitChildren((SemanticsNode child) {
      children.add(child);
      return true;
    });
    for (final child in children) {
      violations.addAll(await _evaluateNode(child, image, byteData, renderView));
    }
    if (_shouldSkipNode(data)) {
      return violations;
    }
    final String text = data.label.isEmpty ? data.value : data.label;
    final Iterable<Element> elements = _collectElementsByText(
      WidgetsBinding.instance.rootElement!,
      text,
    );
    for (final element in elements) {
      violations.addAll(await _evaluateElement(node, element, image, byteData, renderView));
    }
    return violations;
  }

  Future<List<Violation>> _evaluateElement(
    SemanticsNode node,
    Element element,
    ui.Image image,
    ByteData byteData,
    RenderView renderView,
  ) async {
    // Look up inherited text properties to determine text size and weight.
    late bool isBold;
    double? fontSize;

    late final Rect screenBounds;
    late final Rect paintBoundsWithOffset;

    final RenderObject? renderBox = element.renderObject;
    if (renderBox is! RenderBox) {
      throw StateError('Unexpected renderObject type: $renderBox');
    }

    final Matrix4 globalTransform = renderBox.getTransformTo(null);
    paintBoundsWithOffset = MatrixUtils.transformRect(
      globalTransform,
      renderBox.paintBounds.inflate(4.0),
    );

    // The semantics node transform will include root view transform, which is
    // not included in renderBox.getTransformTo(null). Manually multiply the
    // root transform to the global transform.
    final rootTransform = Matrix4.identity();
    renderView.applyPaintTransform(renderView.child!, rootTransform);
    rootTransform.multiply(globalTransform);
    screenBounds = MatrixUtils.transformRect(rootTransform, renderBox.paintBounds);
    Rect nodeBounds = node.rect;
    SemanticsNode? current = node;
    while (current != null) {
      final Matrix4? transform = current.transform;
      if (transform != null) {
        nodeBounds = MatrixUtils.transformRect(transform, nodeBounds);
      }
      current = current.parent;
    }
    final Rect intersection = nodeBounds.intersect(screenBounds);
    if (intersection.width <= 0 || intersection.height <= 0) {
      // Skip this element since it doesn't correspond to the given semantic
      // node.
      return <Violation>[];
    }

    final Widget widget = element.widget;
    final DefaultTextStyle defaultTextStyle = DefaultTextStyle.of(element);
    if (widget is Text) {
      final TextStyle? style = widget.style;
      final TextStyle effectiveTextStyle = style == null || style.inherit
          ? defaultTextStyle.style.merge(widget.style)
          : style;
      isBold = effectiveTextStyle.fontWeight == FontWeight.bold;
      fontSize = effectiveTextStyle.fontSize;
    } else if (widget is EditableText) {
      isBold = widget.style.fontWeight == FontWeight.bold;
      fontSize = widget.style.fontSize;
    } else {
      throw StateError('Unexpected widget type: ${widget.runtimeType}');
    }

    if (_isNodeOffScreen(paintBoundsWithOffset, renderView.flutterView)) {
      return <Violation>[];
    }

    final Map<Color, int> colorHistogram = _colorsWithinRect(
      byteData,
      paintBoundsWithOffset,
      image.width,
      image.height,
    );

    // Node was too far off screen.
    if (colorHistogram.isEmpty) {
      return <Violation>[];
    }

    final report = _ContrastReport(colorHistogram);

    final double contrastRatio = report.contrastRatio();
    final double targetContrastRatio = _targetContrastRatio(fontSize, bold: isBold);

    if (contrastRatio - targetContrastRatio >= _tolerance) {
      return <Violation>[];
    }
    return <Violation>[
      Violation(
        node,
        '$node:\n'
        'Expected contrast ratio of at least $targetContrastRatio '
        'but found ${contrastRatio.toStringAsFixed(2)} '
        'for a font size of $fontSize.\n'
        'The computed colors were:\n'
        'light - ${report.lightColor}, dark - ${report.darkColor}\n'
        'See also: '
        'https://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html',
      ),
    ];
  }

  /// Returns whether node should be skipped.
  ///
  /// Skip routes which might have labels, and nodes without any text.
  bool _shouldSkipNode(SemanticsData data) =>
      data.flagsCollection.scopesRoute || (data.label.trim().isEmpty && data.value.trim().isEmpty);

  /// Returns if a rectangle of node is off the screen.
  ///
  /// Allows node to be off screen partially before culling the node.
  bool _isNodeOffScreen(Rect paintBounds, ui.FlutterView window) {
    final Size windowPhysicalSize = window.physicalSize * window.devicePixelRatio;
    return paintBounds.top < -50.0 ||
        paintBounds.left < -50.0 ||
        paintBounds.bottom > windowPhysicalSize.height + 50.0 ||
        paintBounds.right > windowPhysicalSize.width + 50.0;
  }

  /// Returns the required contrast ratio for the [fontSize] and [bold] setting.
  ///
  /// Defined by http://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html
  double _targetContrastRatio(double? fontSize, {required bool bold}) {
    final double fontSizeOrDefault = fontSize ?? _kDefaultFontSize;
    if ((bold && fontSizeOrDefault >= kBoldTextMinimumSize) ||
        fontSizeOrDefault >= kLargeTextMinimumSize) {
      return kMinimumRatioLargeText;
    }
    return kMinimumRatioNormalText;
  }
}

/// {@macro flutter.widgets.accessibility_evaluations.internal}
///
/// An evaluation which verifies that all nodes that contribute semantics via text
/// meet **WCAG AAA** contrast levels.
///
/// The AAA level is defined by the Web Content Accessibility Guidelines:
/// https://www.w3.org/WAI/WCAG22/Understanding/contrast-enhanced
///
/// This evaluation enforces a stricter contrast ratio:
///  * Normal text must have a contrast ratio of at least 7.0
///  * Large or bold text must have a contrast ratio of at least 4.5
@internal
class MinimumTextContrastEvaluationAAA extends MinimumTextContrastEvaluation {
  /// Create a new [MinimumTextContrastEvaluationAAA].
  const MinimumTextContrastEvaluationAAA();

  /// The minimum contrast ratio for large text (bold ≥14px or ≥18px).
  ///
  /// Defined by WCAG AAA standard http://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html
  static const double kAAAMinimumRatioLargeText = 4.5;

  /// The minimum contrast ratio for normal text.
  ///
  /// Defined by WCAG AAA standard http://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html
  static const double kAAAMinimumRatioNormalText = 7.0;

  @override
  double _targetContrastRatio(double? fontSize, {required bool bold}) {
    final double fontSizeOrDefault = fontSize ?? MinimumTextContrastEvaluation._kDefaultFontSize;
    if ((bold && fontSizeOrDefault >= MinimumTextContrastEvaluation.kBoldTextMinimumSize) ||
        fontSizeOrDefault >= MinimumTextContrastEvaluation.kLargeTextMinimumSize) {
      return kAAAMinimumRatioLargeText;
    }
    return kAAAMinimumRatioNormalText;
  }
}

/// A class that reports the contrast ratio of a part of the screen.
class _ContrastReport {
  /// Generates a contrast report given a color histogram.
  ///
  /// The contrast ratio of the most frequent light color and the most
  /// frequent dark color is calculated. Colors are divided into light and
  /// dark colors based on their lightness as an [HSLColor].
  factory _ContrastReport(Map<Color, int> colorHistogram) {
    // To determine the lighter and darker colors, partition the colors
    // by HSL lightness and then choose the mode from each group.
    var totalLightness = 0.0;
    var count = 0;
    for (final MapEntry<Color, int> entry in colorHistogram.entries) {
      totalLightness += HSLColor.fromColor(entry.key).lightness * entry.value;
      count += entry.value;
    }
    final double averageLightness = totalLightness / count;
    assert(!averageLightness.isNaN);

    MapEntry<Color, int>? lightColor;
    MapEntry<Color, int>? darkColor;

    // Find the most frequently occurring light and dark colors.
    for (final MapEntry<Color, int> entry in colorHistogram.entries) {
      final double lightness = HSLColor.fromColor(entry.key).lightness;
      final int count = entry.value;
      if (lightness <= averageLightness) {
        if (count > (darkColor?.value ?? 0)) {
          darkColor = entry;
        }
      } else if (count > (lightColor?.value ?? 0)) {
        lightColor = entry;
      }
    }

    // If there is only a single color, it is reported as both dark and light.
    return _ContrastReport._(lightColor?.key ?? darkColor!.key, darkColor?.key ?? lightColor!.key);
  }

  const _ContrastReport._(this.lightColor, this.darkColor);

  /// The most frequently occurring light color. Uses [Colors.transparent] if
  /// the rectangle is empty.
  final Color lightColor;

  /// The most frequently occurring dark color. Uses [Colors.transparent] if
  /// the rectangle is empty.
  final Color darkColor;

  /// Computes the contrast ratio as defined by the WCAG.
  ///
  /// Source: https://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html
  double contrastRatio() =>
      (lightColor.computeLuminance() + 0.05) / (darkColor.computeLuminance() + 0.05);
}

/// Gives the color histogram of all pixels inside a given rectangle on the
/// screen.
///
/// Given a [ByteData] object [data], which stores the color of each pixel
/// in row-first order, where each pixel is given in 4 bytes in RGBA order,
/// and [paintBounds], the rectangle, and [width] and [height].
/// The dimensions of the [ByteData] are [width] and [height].
/// Returns color histogram.
Map<Color, int> _colorsWithinRect(ByteData data, Rect paintBounds, int width, int height) {
  final Rect truePaintBounds = paintBounds.intersect(
    Rect.fromLTWH(0.0, 0.0, width.toDouble(), height.toDouble()),
  );

  final int leftX = truePaintBounds.left.floor();
  final int rightX = truePaintBounds.right.ceil();
  final int topY = truePaintBounds.top.floor();
  final int bottomY = truePaintBounds.bottom.ceil();

  final rgbaToCount = <int, int>{};

  int getPixel(ByteData data, int x, int y) {
    final int offset = (y * width + x) * 4;
    return data.getUint32(offset);
  }

  for (var x = leftX; x < rightX; x++) {
    for (var y = topY; y < bottomY; y++) {
      rgbaToCount.update(getPixel(data, x, y), (int count) => count + 1, ifAbsent: () => 1);
    }
  }

  return rgbaToCount.map<Color, int>((int rgba, int count) {
    final int argb = (rgba << 24) | (rgba >> 8) & 0xFFFFFFFF;
    return MapEntry<Color, int>(Color(argb), count);
  });
}

Iterable<Element> _collectElementsByText(Element root, String text) {
  final result = <Element>[];
  root.visitChildren((Element child) {
    if (child.widget is Text && (child.widget as Text).data == text) {
      result.add(child);
    }
    result.addAll(_collectElementsByText(child, text));
  });
  return result;
}
