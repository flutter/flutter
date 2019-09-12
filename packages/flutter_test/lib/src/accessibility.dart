// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import 'finders.dart';
import 'widget_tester.dart';

/// The result of evaluating a semantics node by a [AccessibilityGuideline].
class Evaluation {
  /// Create a passing evaluation.
  const Evaluation.pass()
    : passed = true,
      reason = null;

  /// Create a failing evaluation, with an optional [reason] explaining the
  /// result.
  const Evaluation.fail([this.reason]) : passed = false;

  // private constructor for adding cases together.
  const Evaluation._(this.passed, this.reason);

  /// Whether the given tree or node passed the policy evaluation.
  final bool passed;

  /// If [passed] is false, contains the reason for failure.
  final String reason;

  /// Combines two evaluation results.
  ///
  /// The [reason] will be concatenated with a newline, and [passed] will be
  /// combined with an `&&` operator.
  Evaluation operator +(Evaluation other) {
    if (other == null)
      return this;
    final StringBuffer buffer = StringBuffer();
    if (reason != null) {
      buffer.write(reason);
      buffer.write(' ');
    }
    if (other.reason != null)
      buffer.write(other.reason);
    return Evaluation._(passed && other.passed, buffer.isEmpty ? null : buffer.toString());
  }
}

/// An accessibility guideline describes a recommendation an application should
/// meet to be considered accessible.
abstract class AccessibilityGuideline {
  /// A const constructor allows subclasses to be const.
  const AccessibilityGuideline();

  /// Evaluate whether the current state of the `tester` conforms to the rule.
  FutureOr<Evaluation> evaluate(WidgetTester tester);

  /// A description of the policy restrictions and criteria.
  String get description;
}

/// A guideline which enforces that all tapable semantics nodes have a minimum
/// size.
///
/// Each platform defines its own guidelines for minimum tap areas.
@visibleForTesting
class MinimumTapTargetGuideline extends AccessibilityGuideline {
  const MinimumTapTargetGuideline._(this.size, this.link);

  /// The minimum allowed size of a tapable node.
  final Size size;

  /// A link describing the tap target guidelines for a platform.
  final String link;

  @override
  FutureOr<Evaluation> evaluate(WidgetTester tester) {
    final SemanticsNode root = tester.binding.pipelineOwner.semanticsOwner.rootSemanticsNode;
    Evaluation traverse(SemanticsNode node) {
      Evaluation result = const Evaluation.pass();
      node.visitChildren((SemanticsNode child) {
        result += traverse(child);
        return true;
      });
      if (node.isMergedIntoParent)
        return result;
      final SemanticsData data = node.getSemanticsData();
      // Skip node if it has no actions, or is marked as hidden.
      if ((!data.hasAction(ui.SemanticsAction.longPress)
        && !data.hasAction(ui.SemanticsAction.tap))
        || data.hasFlag(ui.SemanticsFlag.isHidden))
        return result;
      Rect paintBounds = node.rect;
      SemanticsNode current = node;
      while (current != null) {
        if (current.transform != null)
          paintBounds = MatrixUtils.transformRect(current.transform, paintBounds);
        current = current.parent;
      }
      // skip node if it is touching the edge of the screen, since it might
      // be partially scrolled offscreen.
      const double delta = 0.001;
      if (paintBounds.left <= delta
        || paintBounds.top <= delta
        || (paintBounds.bottom - tester.binding.window.physicalSize.height).abs() <= delta
        || (paintBounds.right - tester.binding.window.physicalSize.width).abs() <= delta)
        return result;
      // shrink by device pixel ratio.
      final Size candidateSize = paintBounds.size / tester.binding.window.devicePixelRatio;
      if (candidateSize.width < size.width - delta || candidateSize.height < size.height - delta) {
        result += Evaluation.fail(
          '$node: expected tap target size of at least $size, but found $candidateSize\n'
          'See also: $link');
      }
      return result;
    }
    return traverse(root);
  }

  @override
  String get description => 'Tappable objects should be at least $size';
}

/// A guideline which enforces that all nodes with a tap or long press action
/// also have a label.
@visibleForTesting
class LabeledTapTargetGuideline extends AccessibilityGuideline {
  const LabeledTapTargetGuideline._();

  @override
  String get description => 'Tappable widgets should have a semantic label';

  @override
  FutureOr<Evaluation> evaluate(WidgetTester tester) {
    final SemanticsNode root = tester.binding.pipelineOwner.semanticsOwner.rootSemanticsNode;
    Evaluation traverse(SemanticsNode node) {
      Evaluation result = const Evaluation.pass();
      node.visitChildren((SemanticsNode child) {
        result += traverse(child);
        return true;
      });
      if (node.isMergedIntoParent || node.isInvisible || node.hasFlag(ui.SemanticsFlag.isHidden))
        return result;
      final SemanticsData data = node.getSemanticsData();
      // Skip node if it has no actions, or is marked as hidden.
      if (!data.hasAction(ui.SemanticsAction.longPress) && !data.hasAction(ui.SemanticsAction.tap))
        return result;
      if (data.label == null || data.label.isEmpty) {
        result += Evaluation.fail(
          '$node: expected tappable node to have semantic label, but none was found\n',
        );
      }
      return result;
    }
    return traverse(root);
  }
}

/// A guideline which verifies that all nodes that contribute semantics via text
/// meet minimum contrast levels.
///
/// The guidelines are defined by the Web Content Accessibility Guidelines,
/// http://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html.
@visibleForTesting
class MinimumTextContrastGuideline extends AccessibilityGuideline {
  const MinimumTextContrastGuideline._();

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

  @override
  Future<Evaluation> evaluate(WidgetTester tester) async {
    final SemanticsNode root = tester.binding.pipelineOwner.semanticsOwner.rootSemanticsNode;
    final RenderView renderView = tester.binding.renderView;
    final OffsetLayer layer = renderView.debugLayer;
    ui.Image image;
    final ByteData byteData = await tester.binding.runAsync<ByteData>(() async {
      // Needs to be the same pixel ratio otherwise our dimensions won't match the
      // last transform layer.
      image = await layer.toImage(renderView.paintBounds, pixelRatio: 1 / tester.binding.window.devicePixelRatio);
      return image.toByteData();
    });

    Future<Evaluation> evaluateNode(SemanticsNode node) async {
      Evaluation result = const Evaluation.pass();
      if (node.isInvisible || node.isMergedIntoParent || node.hasFlag(ui.SemanticsFlag.isHidden))
        return result;
      final SemanticsData data = node.getSemanticsData();
      final List<SemanticsNode> children = <SemanticsNode>[];
      node.visitChildren((SemanticsNode child) {
        children.add(child);
        return true;
      });
      for (SemanticsNode child in children) {
        result += await evaluateNode(child);
      }
      if (_shouldSkipNode(data)) {
        return result;
      }

      // We need to look up the inherited text properties to determine the
      // contrast ratio based on text size/weight.
      double fontSize;
      bool isBold;
      final String text = (data.label?.isEmpty == true) ? data.value : data.label;
      final List<Element> elements = find.text(text).hitTestable().evaluate().toList();
      Rect paintBounds;
      if (elements.length == 1) {
        final Element element = elements.single;
        final RenderBox renderObject = element.renderObject;
        element.renderObject.paintBounds;
        paintBounds = Rect.fromPoints(
          renderObject.localToGlobal(element.renderObject.paintBounds.topLeft - const Offset(4.0, 4.0)),
          renderObject.localToGlobal(element.renderObject.paintBounds.bottomRight + const Offset(4.0, 4.0)),
        );
        final Widget widget = element.widget;
        final DefaultTextStyle defaultTextStyle = DefaultTextStyle.of(element);
        if (widget is Text) {
          TextStyle effectiveTextStyle = widget.style;
          if (widget.style == null || widget.style.inherit) {
            effectiveTextStyle = defaultTextStyle.style.merge(widget.style);
          }
          fontSize = effectiveTextStyle.fontSize;
          isBold = effectiveTextStyle.fontWeight == FontWeight.bold;
        } else if (widget is EditableText) {
          isBold = widget.style.fontWeight == FontWeight.bold;
          fontSize = widget.style.fontSize;
        } else {
          assert(false);
        }
      } else if (elements.length > 1) {
        return Evaluation.fail('Multiple nodes with the same label: ${data.label}\n');
      } else {
        // If we can't find the text node then assume the label does not
        // correspond to actual text.
        return result;
      }

      if (_isNodeOffScreen(paintBounds, tester.binding.window)) {
        return result;
      }
      final List<int> subset = _subsetToRect(byteData, paintBounds, image.width, image.height);
      // Node was too far off screen.
      if (subset.isEmpty) {
        return result;
      }
      final _ContrastReport report = _ContrastReport(subset);
      final double contrastRatio = report.contrastRatio();
      const double delta = -0.01;
      double targetContrastRatio;
      if ((isBold && fontSize > kBoldTextMinimumSize) || (fontSize ?? 12.0) > kLargeTextMinimumSize) {
        targetContrastRatio = kMinimumRatioLargeText;
      } else {
        targetContrastRatio = kMinimumRatioNormalText;
      }
      if (contrastRatio - targetContrastRatio >= delta) {
        return result + const Evaluation.pass();
      }
      return result + Evaluation.fail(
        '$node:\nExpected contrast ratio of at least '
        '$targetContrastRatio but found ${contrastRatio.toStringAsFixed(2)} for a font size of $fontSize. '
        'The computed light color was: ${report.lightColor}, '
        'The computed dark color was: ${report.darkColor}\n'
        'See also: https://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html'
      );
    }
    return evaluateNode(root);
  }

  // Skip routes which might have labels, and nodes without any text.
  bool _shouldSkipNode(SemanticsData data) {
    if (data.hasFlag(ui.SemanticsFlag.scopesRoute))
      return true;
    if (data.label?.trim()?.isEmpty == true && data.value?.trim()?.isEmpty == true)
      return true;
    return false;
  }

  // Returns a rect that is entirely on screen, or null if it is too far off.
  //
  // Given a pixel buffer based on the physical window size, can we actually
  // get all the data from this node? allow a small delta overlap before
  // culling the node.
  bool _isNodeOffScreen(Rect paintBounds, ui.Window window) {
    return paintBounds.top < -50.0
      || paintBounds.left <  -50.0
      || paintBounds.bottom > (window.physicalSize.height * window.devicePixelRatio) + 50.0
      || paintBounds.right > (window.physicalSize.width * window.devicePixelRatio)  + 50.0;
  }

  List<int> _subsetToRect(ByteData data, Rect paintBounds, int width, int height) {
    final int newWidth = paintBounds.size.width.ceil();
    final int newHeight = paintBounds.size.height.ceil();
    final int leftX = paintBounds.topLeft.dx.ceil();
    final int rightX = leftX + newWidth;
    final int topY = paintBounds.topLeft.dy.ceil();
    final int bottomY = topY + newHeight;
    final List<int> buffer = <int>[];

    // Data is stored in row major order.
    for (int i = 0; i < data.lengthInBytes; i+=4) {
      final int index = i ~/ 4;
      final int dx = index % width;
      final int dy = index ~/ width;
      if (dx >= leftX && dx <= rightX && dy >= topY && dy <= bottomY) {
        final int r = data.getUint8(i);
        final int g = data.getUint8(i + 1);
        final int b = data.getUint8(i + 2);
        final int a = data.getUint8(i + 3);
        final int color = (((a & 0xff) << 24) |
          ((r & 0xff) << 16) |
          ((g & 0xff) << 8)  |
          ((b & 0xff) << 0)) & 0xFFFFFFFF;
        buffer.add(color);
      }
    }
    return buffer;
  }

  @override
  String get description => 'Text contrast should follow WCAG guidelines';
}

class _ContrastReport {
  factory _ContrastReport(List<int> colors) {
    final Map<int, int> colorHistogram = <int, int>{};
    for (int color in colors) {
      colorHistogram[color] = (colorHistogram[color] ?? 0) + 1;
    }
    if (colorHistogram.length == 1) {
      final Color hslColor = Color(colorHistogram.keys.first);
      return _ContrastReport._(hslColor, hslColor);
    }
    // to determine the lighter and darker color, partition the colors
    // by lightness and then choose the mode from each group.
    double averageLightness = 0.0;
    for (int color in colorHistogram.keys) {
      final HSLColor hslColor = HSLColor.fromColor(Color(color));
      averageLightness += hslColor.lightness * colorHistogram[color];
    }
    averageLightness /= colors.length;
    assert(averageLightness != double.nan);
    int lightColor = 0;
    int darkColor = 0;
    int lightCount = 0;
    int darkCount = 0;
    // Find the most frequently occurring light and dark color.
    for (MapEntry<int, int> entry in colorHistogram.entries) {
      final HSLColor color = HSLColor.fromColor(Color(entry.key));
      final int count = entry.value;
      if (color.lightness <= averageLightness && count > darkCount) {
        darkColor = entry.key;
        darkCount = count;
      } else if (color.lightness > averageLightness && count > lightCount) {
        lightColor = entry.key;
        lightCount = count;
      }
    }
    assert (lightColor != 0 && darkColor != 0);
    return _ContrastReport._(Color(lightColor), Color(darkColor));
  }

  const _ContrastReport._(this.lightColor, this.darkColor);

  final Color lightColor;
  final Color darkColor;

  /// Computes the contrast ratio as defined by the WCAG.
  ///
  /// source: https://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html
  double contrastRatio() {
    return (_luminance(lightColor) + 0.05) / (_luminance(darkColor) + 0.05);
  }

  /// Relative luminance calculation.
  ///
  /// Based on https://www.w3.org/TR/2008/REC-WCAG20-20081211/#relativeluminancedef
  static double _luminance(Color color) {
    double r = color.red / 255.0;
    double g = color.green / 255.0;
    double b = color.blue / 255.0;
    if (r <= 0.03928)
      r /= 12.92;
    else
      r = math.pow((r + 0.055)/ 1.055, 2.4);
    if (g <= 0.03928)
      g /= 12.92;
    else
      g = math.pow((g + 0.055)/ 1.055, 2.4);
    if (b <= 0.03928)
      b /= 12.92;
    else
      b = math.pow((b + 0.055)/ 1.055, 2.4);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }
}

/// A guideline which requires tapable semantic nodes a minimum size of 48 by 48.
///
/// See also:
///
///  * [Android tap target guidelines](https://support.google.com/accessibility/android/answer/7101858?hl=en).
const AccessibilityGuideline androidTapTargetGuideline = MinimumTapTargetGuideline._(
  Size(48.0, 48.0),
  'https://support.google.com/accessibility/android/answer/7101858?hl=en',
);

/// A guideline which requires tapable semantic nodes a minimum size of 44 by 44.
///
/// See also:
///
///   * [iOS human interface guidelines](https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/adaptivity-and-layout/).
const AccessibilityGuideline iOSTapTargetGuideline = MinimumTapTargetGuideline._(
  Size(44.0, 44.0),
  'https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/adaptivity-and-layout/',
);

/// A guideline which requires text contrast to meet minimum values.
///
/// This guideline traverses the semantics tree looking for nodes with values or
/// labels that corresponds to a Text or Editable text widget. Given the
/// background pixels for the area around this widget, it performs a very naive
/// partitioning of the colors into "light" and "dark" and then chooses the most
/// frequently occurring color in each partition as a representative of the
/// foreground and background colors. The contrast ratio is calculated from
/// these colors according to the [WCAG](https://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html#contrast-ratiodef)
const AccessibilityGuideline textContrastGuideline = MinimumTextContrastGuideline._();

/// A guideline which enforces that all nodes with a tap or long press action
/// also have a label.
const AccessibilityGuideline labeledTapTargetGuideline = LabeledTapTargetGuideline._();
