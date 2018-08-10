// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'finders.dart';
import 'widget_tester.dart';

/// The result of evaluating a semantics node by a [AccessibilityPolicy].
class Evaluation {
  /// Create a passing evaluation.
  const Evaluation.pass() : passed = true, reason = null;

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
    final StringBuffer buffer = new StringBuffer();
    if (reason != null)
      buffer.write(reason);
    if (other.reason != null)
      buffer.write(other.reason);
    return new Evaluation._(passed && other.passed, buffer.isEmpty ? null : buffer.toString());
  }
}

/// An accessibility policy describes a restriction to conform to enhance
/// usability.
abstract class AccessibilityPolicy {
  /// A const constructor allows subclasses to be const.
  const AccessibilityPolicy();

  /// Method which is called once before the policy is evaluated.
  ///
  /// Use this method to reset any internal state or initialize fields needed in
  /// evaluate.
  @mustCallSuper
  void beforeEvaluate() {}

  /// Evaluate whether the current state of the `tester` conforms to the rule.
  FutureOr<Evaluation> evaluate(WidgetTester tester);

  /// A description of the policy restrictions and criteria.
  String get description;
}

/// A semantics policy which places restrictions on single semantics nodes.
///
/// If a policy only effects one node at a time, this class can be used as
/// a base to get automatic tree traversal for free. The results for each
/// node will be combined into a single result using [Evaluation.+].
abstract class SingleNodeSemanticsPolicy extends AccessibilityPolicy {
  /// A const constructor allows subclasses to be const.
  const SingleNodeSemanticsPolicy();

  @override
  Evaluation evaluate(WidgetTester tester) {
    final SemanticsNode root = tester.binding.pipelineOwner.semanticsOwner.rootSemanticsNode;
    final List<SemanticsNode> nodesToVisit = <SemanticsNode>[root];
    Evaluation result;
    while (nodesToVisit.isNotEmpty) {
      final SemanticsNode current = nodesToVisit.removeAt(0);
      final List<SemanticsData> children = <SemanticsData>[];
      final SemanticsData currentData = current.getSemanticsData();
      current.visitChildren((SemanticsNode child) {
        nodesToVisit.add(child);
        children.add(child.getSemanticsData());
        return true;
      });
      result += evaluateData(currentData, current.id);
    }
    return result;
  }

  /// Override to provide specific logic for evaluating a single semantics node's
  /// data.
  Evaluation evaluateData(SemanticsData node, int id);
}

class _MinimumTapTargetPolicy extends SingleNodeSemanticsPolicy {
  const _MinimumTapTargetPolicy(this.size);

  final Size size;

  @override
  Evaluation evaluateData(SemanticsData data, int id) {
    if (data.hasAction(SemanticsAction.tap) || data.hasAction(SemanticsAction.longPress)) {
      if (data.rect.width < size.width || data.rect.height < size.height) {
        return new Evaluation.fail('Node{$id}: {$data.rect.size} < Size(48.0, 48.0)');
      }
      return const Evaluation.pass();
    }
    // Nodes with no tap actions are not evaluated by this rule.
    return const Evaluation.pass();
  }

  @override
  String get description => 'Tappable objects should be at least $size';
}


class _LabelledImagePolicy extends SingleNodeSemanticsPolicy {
  const _LabelledImagePolicy();

  @override
  Evaluation evaluateData(SemanticsData data, int id) {
    if (data.hasFlag(ui.SemanticsFlag.isImage) && (data.label == null || data.label.trim().isEmpty)) {
      return new Evaluation.fail('Node{$id}: data.label == null|"" ');
    }
    // Nodes that are not images are not evaluated by this rule.
    return const Evaluation.pass();
  }

  @override
  String get description => 'Images should have labels';
}

class _NoOverlappingTapTargetPolicy extends SingleNodeSemanticsPolicy {
  final Map<int, SemanticsData> _nodes = <int, SemanticsData>{};

  @override
  void beforeEvaluate() {
    _nodes.clear();
    super.beforeEvaluate();
  }

  @override
  Evaluation evaluateData(SemanticsData data, int id) {
    if (data.hasAction(SemanticsAction.tap) || data.hasAction(SemanticsAction.longPress)) {
      Evaluation result = const Evaluation.pass();
      for (int otherId in _nodes.keys) {
        final SemanticsData other = _nodes[otherId];
        if (other.rect.overlaps(data.rect)) {
          result += new Evaluation.fail('Node{$id}: has overlapping touch area with Node{$otherId}');
        }
      }
      _nodes[id] = data;
      return result;
    }
    return const Evaluation.pass();
  }

  @override
  String get description => 'Tap areas should not overlap';
}

class _MinimumTextContrastPolicy extends AccessibilityPolicy {
  const _MinimumTextContrastPolicy();

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
  static const double kminimumRatioLargeText = 3.0;

  @override
  Future<Evaluation> evaluate(WidgetTester tester) async {
    final SemanticsNode root = tester.binding.pipelineOwner.semanticsOwner.rootSemanticsNode;
    final RenderView renderView = tester.binding.renderView;
    final OffsetLayer layer = renderView.layer;

    Future<Evaluation> evaluateNode(SemanticsNode node) async {
      final SemanticsData data = node.getSemanticsData();
      final List<SemanticsNode> children = <SemanticsNode>[];
      Evaluation result = const Evaluation.pass();
      node.visitChildren((SemanticsNode child) {
        children.add(child);
        return true;
      });
      for (SemanticsNode child in children)
        result += await evaluateNode(child);
      if (data?.label?.trim()?.isEmpty == true || data.hasFlag(ui.SemanticsFlag.scopesRoute))
        return result;
      // TODO(jonahwilliams): handle icons somehow.
      final List<Element> elements = find.text(data.label).evaluate().toList();
      if (elements.isEmpty)
        return result;
      if (elements.length > 1)
        return const Evaluation.fail('Multiple nodes with the same label');

      final Element element = elements.single;
      final Widget widget = element.widget;
      final DefaultTextStyle defaultTextStyle = DefaultTextStyle.of(element);
      // We need to look up the inherited text properties to determine the
      // contrast ratio based on text size/weight.
      double fontSize;
      bool isBold;
      if (widget is Text) {
        TextStyle effectiveTextStyle = widget.style;
        if (widget.style == null || widget.style.inherit)
          effectiveTextStyle = defaultTextStyle.style.merge(widget.style);
        fontSize = effectiveTextStyle.fontSize;
        isBold = effectiveTextStyle.fontWeight == FontWeight.bold;
      } else {
        // TODO(jonahwilliams): handle other widgets like editable text.
        return result;
      }

      // Transform local coordinate to screen coordinates.
      Rect paintBounds = node.rect;
      SemanticsNode current = node;
      while (current != null) {
        if (current.transform != null)
          paintBounds = MatrixUtils.transformRect(current.transform, paintBounds);
        paintBounds = paintBounds.shift(current.parent?.rect?.topLeft ?? Offset.zero);
        current = current.parent;
      }
      final ByteData byteData = await tester.binding.runAsync<ByteData>(() async  {
        final ui.Image image = await layer.toImage(paintBounds);
        return image.toByteData();
      });
      final _ContrastReport report = new _ContrastReport(byteData);
      final double contrastRatio = report.contrastRatio();
      final double targetContrastRatio = (isBold && fontSize > kBoldTextMinimumSize) ?
        kminimumRatioLargeText : kMinimumRatioNormalText;
      if (contrastRatio >= targetContrastRatio)
        return result + const Evaluation.pass();
      return result + new Evaluation.fail(
        '${node.toString()}:\nExpected contrast ratio of at least $targetContrastRatio, '
        'but found $contrastRatio. '
        'The computed foreground color was: ${report.lightColor}, '
        'The comptued background color was: ${report.darkColor}'
      );
    }
    return evaluateNode(root);
  }

  @override
  String get description => 'Text contrast should follow WCAG guidelines';
}

class _ContrastReport {
  factory _ContrastReport(ByteData byteData) {
    final Map<int, int> colorHistogram = <int, int>{};
    for (int i = 0; i < byteData.lengthInBytes; i += 4) {
      final int r = byteData.getUint8(i);
      final int g = byteData.getUint8(i + 1);
      final int b = byteData.getUint8(i + 2);
      final int a = byteData.getUint8(i + 3);
      final int color = (((a & 0xff) << 24) |
        ((r & 0xff) << 16) |
        ((g & 0xff) << 8)  |
        ((b & 0xff) << 0)) & 0xFFFFFFFF;
      colorHistogram[color] = (colorHistogram[color] ?? 0) + 1;
    }
    assert(colorHistogram.isNotEmpty);
    if (colorHistogram.length == 1) {
      final Color hslColor = new Color(colorHistogram.keys.first);
      return new _ContrastReport._(hslColor, hslColor);
    }
    if (colorHistogram.length == 2) {
      final Color firstColor = new Color(colorHistogram.keys.first);
      final Color lastColor =  new Color(colorHistogram.keys.last);
      if (firstColor.computeLuminance() < lastColor.computeLuminance()) {
        return new _ContrastReport._(lastColor, firstColor);
      }
      return new _ContrastReport._(firstColor, lastColor);
    }
    // to determine the lighter and darker color, partition the colors
    // by lightness and then choose a weighted average from each group.
    final double averageLightness = colorHistogram.keys.fold(0.0, (double total, int color) {
      return total + new HSLColor.fromColor(new Color(color)).lightness;
    }) / colorHistogram.length;
    double lightSum = 0.0;
    double darkSum = 0.0;
    int darkCount = 0;
    int lightCount = 0;
    // compute average of light color and dark color.
    for (MapEntry<int, int> entry in colorHistogram.entries) {
      final HSLColor color = new HSLColor.fromColor(new Color(entry.key));
      final int count = entry.value;
      if (color.lightness < averageLightness) {
        darkSum += color.toColor().value * count;
        darkCount += count;
      } else {
        lightSum += color.toColor().value * count;
        lightCount += count;
      }
    }
    final Color lightColor = new Color(lightSum ~/ lightCount);
    final Color darkColor = new Color(darkSum ~/ darkCount);
    return new _ContrastReport._(lightColor, darkColor);
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

/// A policy which restricts all tapable semantic nodes a minimum size of
/// 48 by 48.
const AccessibilityPolicy minimumTapTargetPolicyAndroid = _MinimumTapTargetPolicy(Size(48.0, 48.0));

/// A policy which restricts all tapable semantic nodes a minimum size of
/// 44 by 44.
const AccessibilityPolicy minimumTapTargetPolicyIOS = _MinimumTapTargetPolicy(Size(44.0, 44.0));

/// A policy which requires all image nodes to have a non-trivial label.
const AccessibilityPolicy labelledImagePolicy = _LabelledImagePolicy();

/// A policy which enforces text contrast.
const AccessibilityPolicy minimumTextContrastPolicy = _MinimumTextContrastPolicy();

/// A policy which requires that tap targets do not overlap.
final AccessibilityPolicy noOverlappingTapTargetPolcy = new _NoOverlappingTapTargetPolicy();
