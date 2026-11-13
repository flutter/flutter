// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/material.dart';
///
/// @docImport 'matchers.dart';
library;

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'finders.dart';
import 'widget_tester.dart';

Evaluation _toEvaluation(
  EvaluationResult result, {
  String Function(Violation violation)? formatReason,
}) {
  if (result.violations.isEmpty) {
    return const Evaluation.pass();
  }
  var evaluation = const Evaluation.pass();
  for (final Violation violation in result.violations) {
    evaluation += Evaluation.fail(
      formatReason != null ? formatReason(violation) : violation.reason,
    );
  }
  return evaluation;
}

/// The result of evaluating a semantics node by a [AccessibilityGuideline].
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
  final String? reason;

  /// Combines two evaluation results.
  ///
  /// The [reason] will be concatenated with a newline, and [passed] will be
  /// combined with an `&&` operator.
  Evaluation operator +(Evaluation? other) {
    if (other == null) {
      return this;
    }

    final buffer = StringBuffer();
    if (reason != null && reason!.isNotEmpty) {
      buffer.write(reason);
      buffer.writeln();
    }
    if (other.reason != null && other.reason!.isNotEmpty) {
      buffer.write(other.reason);
    }
    return Evaluation._(passed && other.passed, buffer.isEmpty ? null : buffer.toString());
  }
}

// Examples can assume:
// typedef HomePage = Placeholder;

/// An accessibility guideline describes a recommendation an application should
/// meet to be considered accessible.
///
/// Use [meetsGuideline] matcher to test whether a screen meets the
/// accessibility guideline.
///
/// {@tool snippet}
///
/// This sample demonstrates how to run an accessibility guideline in a unit
/// test against a single screen.
///
/// ```dart
/// testWidgets('HomePage meets androidTapTargetGuideline', (WidgetTester tester) async {
///   await tester.pumpWidget(const MaterialApp(home: HomePage()));
///   await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
/// });
/// ```
/// {@end-tool}
///
/// See also:
///  * [androidTapTargetGuideline], which checks that tappable nodes have a
///    minimum size of 48 by 48 pixels.
///  * [iOSTapTargetGuideline], which checks that tappable nodes have a minimum
///    size of 44 by 44 pixels.
///  * [textContrastGuideline], which provides guidance for text contrast
///    requirements specified by [WCAG](https://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html#contrast-ratiodef).
///  * [labeledTapTargetGuideline], which enforces that all nodes with a tap or
///    long press action also have a label.
abstract class AccessibilityGuideline {
  /// A const constructor allows subclasses to be const.
  const AccessibilityGuideline();

  /// Evaluate whether the current state of the `tester` conforms to the rule.
  FutureOr<Evaluation> evaluate(WidgetTester tester);

  /// A description of the policy restrictions and criteria.
  String get description;
}

/// A guideline which enforces that all tappable semantics nodes have a minimum
/// size.
///
/// Each platform defines its own guidelines for minimum tap areas.
///
/// See also:
///  * [AccessibilityGuideline], which provides a general overview of
///    accessibility guidelines and how to use them.
///  * [androidTapTargetGuideline], which checks that tappable nodes have a
///    minimum size of 48 by 48 pixels.
///  * [iOSTapTargetGuideline], which checks that tappable nodes have a minimum
///    size of 44 by 44 pixels.
@visibleForTesting
class MinimumTapTargetGuideline extends AccessibilityGuideline {
  /// Create a new [MinimumTapTargetGuideline].
  const MinimumTapTargetGuideline({required this.size, required this.link});

  /// The minimum allowed size of a tappable node.
  final Size size;

  /// A link describing the tap target guidelines for a platform.
  final String link;

  @override
  FutureOr<Evaluation> evaluate(WidgetTester tester) {
    final FutureOr<EvaluationResult> result = MinimumTapTargetEvaluation(size: size)
        .evaluate(tester.binding);
    String formatReason(Violation violation) => '${violation.reason}See also: $link';
    if (result is Future<EvaluationResult>) {
      return result.then((EvaluationResult r) => _toEvaluation(r, formatReason: formatReason));
    }
    return _toEvaluation(result, formatReason: formatReason);
  }

  /// Returns whether [SemanticsNode] should be skipped for minimum tap target
  /// guideline.
  ///
  /// Skips nodes which are link, hidden, or do not have actions.
  bool shouldSkipNode(SemanticsNode node) =>
      MinimumTapTargetEvaluation(size: size).shouldSkipNode(node);

  @override
  String get description => 'Tappable objects should be at least $size';
}

/// A guideline which enforces that all nodes with a tap or long press action
/// also have a label.
///
/// See also:
///  * [AccessibilityGuideline], which provides a general overview of
///    accessibility guidelines and how to use them.
@visibleForTesting
class LabeledTapTargetGuideline extends AccessibilityGuideline {
  const LabeledTapTargetGuideline._();

  @override
  String get description => 'Tappable widgets should have a semantic label';

  @override
  FutureOr<Evaluation> evaluate(WidgetTester tester) {
    final FutureOr<EvaluationResult> result = const LabeledTapTargetEvaluation().evaluate(
      tester.binding,
    );
    if (result is Future<EvaluationResult>) {
      return result.then(_toEvaluation);
    }
    return _toEvaluation(result);
  }
}

/// A guideline which verifies that all nodes that contribute semantics via text
/// meet minimum contrast levels.
///
/// The guidelines are defined by the Web Content Accessibility Guidelines,
/// http://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html.
///
/// See also:
///  * [AccessibilityGuideline], which provides a general overview of
///    accessibility guidelines and how to use them.
///  * [MinimumTextContrastGuidelineAAA], which follows the WCAG AAA level.
@visibleForTesting
class MinimumTextContrastGuideline extends AccessibilityGuideline {
  /// Create a new [MinimumTextContrastGuideline].
  const MinimumTextContrastGuideline();

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

  MinimumTextContrastEvaluation get _evaluation => const MinimumTextContrastEvaluation(
    minNormalTextContrastRatio: kMinimumRatioNormalText,
    minLargeTextContrastRatio: kMinimumRatioLargeText,
  );

  @override
  Future<Evaluation> evaluate(WidgetTester tester) async {
    final EvaluationResult result = (await tester.binding.runAsync<EvaluationResult>(
      () async => _evaluation.evaluate(tester.binding),
    ))!;
    return _toEvaluation(result);
  }

  /// Returns whether node should be skipped.
  ///
  /// Skip routes which might have labels, and nodes without any text.
  bool shouldSkipNode(SemanticsData data) =>
      data.flagsCollection.scopesRoute || (data.label.trim().isEmpty && data.value.trim().isEmpty);

  /// Returns if a rectangle of node is off the screen.
  ///
  /// Allows node to be of screen partially before culling the node.
  bool isNodeOffScreen(Rect paintBounds, ui.FlutterView window) {
    final Size windowPhysicalSize = window.physicalSize * window.devicePixelRatio;
    return paintBounds.top < -50.0 ||
        paintBounds.left < -50.0 ||
        paintBounds.bottom > windowPhysicalSize.height + 50.0 ||
        paintBounds.right > windowPhysicalSize.width + 50.0;
  }

  /// Returns the required contrast ratio for the [fontSize] and [bold] setting.
  ///
  /// Defined by http://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html
  double targetContrastRatio(double? fontSize, {required bool bold}) {
    final double fontSizeOrDefault = fontSize ?? _kDefaultFontSize;
    if ((bold && fontSizeOrDefault >= kBoldTextMinimumSize) ||
        fontSizeOrDefault >= kLargeTextMinimumSize) {
      return kMinimumRatioLargeText;
    }
    return kMinimumRatioNormalText;
  }

  @override
  String get description => 'Text contrast should follow WCAG guidelines';
}

/// A guideline which verifies that all nodes that contribute semantics via text
/// meet **WCAG AAA** contrast levels.
///
/// The AAA level is defined by the Web Content Accessibility Guidelines:
/// https://www.w3.org/WAI/WCAG22/Understanding/contrast-enhanced
///
/// This guideline enforces a stricter contrast ratio:
///  * Normal text must have a contrast ratio of at least 7.0
///  * Large or bold text must have a contrast ratio of at least 4.5
///
/// See also:
///  * [MinimumTextContrastGuideline], which follows the WCAG AA level.
///  * [AccessibilityGuideline], which provides an overview of guidelines.
@visibleForTesting
class MinimumTextContrastGuidelineAAA extends MinimumTextContrastGuideline {
  /// Create a new [MinimumTextContrastGuidelineAAA].
  const MinimumTextContrastGuidelineAAA();

  /// The minimum contrast ratio for large text (bold ≥14px or ≥18px).
  ///
  /// Defined by WCAG AAA standard http://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html
  static const double kAAAMinimumRatioLargeText = 4.5;

  /// The minimum contrast ratio for normal text.
  ///
  /// Defined by WCAG AAA standard http://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html
  static const double kAAAMinimumRatioNormalText = 7.0;

  @override
  MinimumTextContrastEvaluation get _evaluation => const MinimumTextContrastEvaluation(
    minNormalTextContrastRatio: kAAAMinimumRatioNormalText,
    minLargeTextContrastRatio: kAAAMinimumRatioLargeText,
  );

  @override
  double targetContrastRatio(double? fontSize, {required bool bold}) {
    final double fontSizeOrDefault = fontSize ?? MinimumTextContrastGuideline._kDefaultFontSize;
    if ((bold && fontSizeOrDefault >= MinimumTextContrastGuideline.kBoldTextMinimumSize) ||
        fontSizeOrDefault >= MinimumTextContrastGuideline.kLargeTextMinimumSize) {
      return kAAAMinimumRatioLargeText;
    }
    return kAAAMinimumRatioNormalText;
  }

  @override
  String get description => 'Text contrast should follow WCAG AAA guidelines';
}

/// A guideline which verifies that all elements specified by [finder]
/// meet minimum contrast levels.
///
/// See also:
///  * [AccessibilityGuideline], which provides a general overview of
///    accessibility guidelines and how to use them.
class CustomMinimumContrastGuideline extends AccessibilityGuideline {
  /// Creates a custom guideline which verifies that all elements specified
  /// by [finder] meet minimum contrast levels.
  ///
  /// An optional description string can be given using the [_description] parameter.
  const CustomMinimumContrastGuideline({
    required this.finder,
    this.minimumRatio = 4.5,
    this.tolerance = 0.01,
    this._description = 'Contrast should follow custom guidelines',
  });

  /// The minimum contrast ratio allowed.
  ///
  /// Defaults to 4.5, the minimum contrast
  /// ratio for normal text, defined by WCAG.
  /// See http://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html.
  final double minimumRatio;

  /// Tolerance for minimum contrast ratio.
  ///
  /// Any contrast ratio greater than [minimumRatio] or within a distance of [tolerance]
  /// from [minimumRatio] passes the test.
  /// Defaults to 0.01.
  final double tolerance;

  /// The [Finder] used to find a subset of elements.
  ///
  /// [finder] determines which subset of elements will be tested for
  /// contrast ratio.
  final Finder finder;

  final String _description;

  @override
  String get description => _description;

  @override
  Future<Evaluation> evaluate(WidgetTester tester) async {
    // Collate all evaluations into a final evaluation, then return.
    var result = const Evaluation.pass();
    final images = <ui.FlutterView, ui.Image>{};
    try {
      // Compute elements to be evaluated.
      final List<Element> elements = finder.evaluate().toList();
      final byteDatas = <ui.FlutterView, ByteData>{};

      for (final element in elements) {
        final ui.FlutterView view = tester.viewOf(
          find.byElementPredicate((Element e) => e == element),
        );
        final RenderView renderView = tester.binding.renderViews.firstWhere(
          (RenderView r) => r.flutterView == view,
        );
        final layer = renderView.debugLayer! as OffsetLayer;

        late final ui.Image image;
        late final ByteData byteData;

        // Obtain a previously rendered image or render one for a new view.
        await tester.binding.runAsync(() async {
          image = images[view] ??= await layer.toImage(
            renderView.paintBounds,
            // Needs to be the same pixel ratio otherwise our dimensions
            // won't match the last transform layer.
            pixelRatio: 1 / view.devicePixelRatio,
          );
          byteData = byteDatas[view] ??= (await image.toByteData())!;
        });

        result = result + _evaluateElement(element, byteData, image);
      }
    } finally {
      for (final ui.Image image in images.values) {
        image.dispose();
      }
    }
    return result;
  }

  // How to evaluate a single element.
  Evaluation _evaluateElement(Element element, ByteData byteData, ui.Image image) {
    final renderObject = element.renderObject! as RenderBox;

    final Rect originalPaintBounds = renderObject.paintBounds;

    final Rect inflatedPaintBounds = originalPaintBounds.inflate(4.0);

    final paintBounds = Rect.fromPoints(
      renderObject.localToGlobal(inflatedPaintBounds.topLeft),
      renderObject.localToGlobal(inflatedPaintBounds.bottomRight),
    );

    final Map<Color, int> colorHistogram = _colorsWithinRect(
      byteData,
      paintBounds,
      image.width,
      image.height,
    );

    if (colorHistogram.isEmpty) {
      return const Evaluation.pass();
    }

    final report = _ContrastReport(colorHistogram);
    final double contrastRatio = report.contrastRatio();

    if (contrastRatio >= minimumRatio - tolerance) {
      return const Evaluation.pass();
    } else {
      return Evaluation.fail(
        '$element:\nExpected contrast ratio of at least '
        '$minimumRatio but found ${contrastRatio.toStringAsFixed(2)} \n'
        'The computed light color was: ${report.lightColor}, '
        'The computed dark color was: ${report.darkColor}\n'
        '$description',
      );
    }
  }
}

/// A class that reports the contrast ratio of a part of the screen.
///
/// Commonly used in accessibility testing to obtain the contrast ratio of
/// text widgets and other types of widgets.
class _ContrastReport {
  /// Generates a contrast report given a color histogram.
  ///
  /// The contrast ratio of the most frequent light color and the most
  /// frequent dark color is calculated. Colors are divided into light and
  /// dark colors based on their lightness as an [HSLColor].
  factory _ContrastReport(Map<Color, int> colorHistogram) {
    // To determine the lighter and darker color, partition the colors
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

    // Find the most frequently occurring light and dark color.
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

    // If there is only single color, it is reported as both dark and light.
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
/// and [paintBounds], the rectangle, and [width] and [height],
//  the dimensions of the [ByteData] returns color histogram.
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

/// A guideline which requires tappable semantic nodes a minimum size of
/// 48 by 48.
///
/// See also:
///
///  * [Android tap target guidelines](https://support.google.com/accessibility/android/answer/7101858?hl=en).
///  * [AccessibilityGuideline], which provides a general overview of
///    accessibility guidelines and how to use them.
///  * [iOSTapTargetGuideline], which checks that tappable nodes have a minimum
///    size of 44 by 44 pixels.
const AccessibilityGuideline androidTapTargetGuideline = MinimumTapTargetGuideline(
  size: Size(48.0, 48.0),
  link: 'https://support.google.com/accessibility/android/answer/7101858?hl=en',
);

/// A guideline which requires tappable semantic nodes a minimum size of
/// 44 by 44.
///
/// See also:
///
///  * [iOS human interface guidelines](https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/adaptivity-and-layout/).
///  * [AccessibilityGuideline], which provides a general overview of
///    accessibility guidelines and how to use them.
///  * [androidTapTargetGuideline], which checks that tappable nodes have a
///    minimum size of 48 by 48 pixels.
const AccessibilityGuideline iOSTapTargetGuideline = MinimumTapTargetGuideline(
  size: Size(44.0, 44.0),
  link: 'https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/adaptivity-and-layout/',
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
///
///  * [AccessibilityGuideline], which provides a general overview of
///    accessibility guidelines and how to use them.
const AccessibilityGuideline textContrastGuideline = MinimumTextContrastGuideline();

/// A guideline which enforces that all nodes with a tap or long press action
/// also have a label.
///
///  * [AccessibilityGuideline], which provides a general overview of
///    accessibility guidelines and how to use them.
const AccessibilityGuideline labeledTapTargetGuideline = LabeledTapTargetGuideline._();
