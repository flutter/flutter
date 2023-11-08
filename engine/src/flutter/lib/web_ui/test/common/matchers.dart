// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Provides utilities for testing engine code.
library matchers;

import 'dart:math' as math;

import 'package:html/dom.dart' as html_package;
import 'package:html/parser.dart' as html_package;

import 'package:test/test.dart';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart';

/// The epsilon of tolerable double precision error.
///
/// This is used in various places in the framework to allow for floating point
/// precision loss in calculations. Differences below this threshold are safe
/// to disregard.
const double precisionErrorTolerance = 1e-10;

/// Enumerates all persisted surfaces in the tree rooted at [root].
///
/// If [root] is `null` returns all surfaces from the last rendered scene.
///
/// Surfaces are returned in a depth-first order.
Iterable<PersistedSurface> enumerateSurfaces([PersistedSurface? root]) {
  root ??= SurfaceSceneBuilder.debugLastFrameScene;
  final List<PersistedSurface> surfaces = <PersistedSurface>[root!];

  root.visitChildren((PersistedSurface surface) {
    surfaces.addAll(enumerateSurfaces(surface));
  });

  return surfaces;
}

/// Enumerates all pictures nested under [root].
///
/// If [root] is `null` returns all pictures from the last rendered scene.
Iterable<PersistedPicture> enumeratePictures([PersistedSurface? root]) {
  root ??= SurfaceSceneBuilder.debugLastFrameScene;
  return enumerateSurfaces(root).whereType<PersistedPicture>();
}

/// Enumerates all offset surfaces nested under [root].
///
/// If [root] is `null` returns all pictures from the last rendered scene.
Iterable<PersistedOffset> enumerateOffsets([PersistedSurface? root]) {
  root ??= SurfaceSceneBuilder.debugLastFrameScene;
  return enumerateSurfaces(root).whereType<PersistedOffset>();
}

/// Computes the distance between two values.
///
/// The distance should be a metric in a metric space (see
/// https://en.wikipedia.org/wiki/Metric_space). Specifically, if `f` is a
/// distance function then the following conditions should hold:
///
/// - f(a, b) >= 0
/// - f(a, b) == 0 if and only if a == b
/// - f(a, b) == f(b, a)
/// - f(a, c) <= f(a, b) + f(b, c), known as triangle inequality
///
/// This makes it useful for comparing numbers, [Color]s, [Offset]s and other
/// sets of value for which a metric space is defined.
typedef DistanceFunction<T> = double Function(T a, T b);

/// The type of a union of instances of [DistanceFunction<T>] for various types
/// T.
///
/// This type is used to describe a collection of [DistanceFunction<T>]
/// functions which have (potentially) unrelated argument types. Since the
/// argument types of the functions may be unrelated, the only thing that the
/// type system can statically assume about them is that they accept null (since
/// all types in Dart are nullable).
///
/// Calling an instance of this type must either be done dynamically, or by
/// first casting it to a [DistanceFunction<T>] for some concrete T.
typedef AnyDistanceFunction = double Function(Never a, Never b);

const Map<Type, AnyDistanceFunction> _kStandardDistanceFunctions =
    <Type, AnyDistanceFunction>{
  Color: _maxComponentColorDistance,
  Offset: _offsetDistance,
  int: _intDistance,
  double: _doubleDistance,
  Rect: _rectDistance,
  Size: _sizeDistance,
};

double _intDistance(int a, int b) => (b - a).abs().toDouble();
double _doubleDistance(double a, double b) => (b - a).abs();
double _offsetDistance(Offset a, Offset b) => (b - a).distance;

double _maxComponentColorDistance(Color a, Color b) {
  int delta = math.max<int>((a.red - b.red).abs(), (a.green - b.green).abs());
  delta = math.max<int>(delta, (a.blue - b.blue).abs());
  delta = math.max<int>(delta, (a.alpha - b.alpha).abs());
  return delta.toDouble();
}

double _rectDistance(Rect a, Rect b) {
  double delta =
      math.max<double>((a.left - b.left).abs(), (a.top - b.top).abs());
  delta = math.max<double>(delta, (a.right - b.right).abs());
  delta = math.max<double>(delta, (a.bottom - b.bottom).abs());
  return delta;
}

double _sizeDistance(Size a, Size b) {
  final Offset delta = (b - a) as Offset; // ignore: unnecessary_parenthesis
  return delta.distance;
}

/// Asserts that two values are within a certain distance from each other.
///
/// The distance is computed by a [DistanceFunction].
///
/// If `distanceFunction` is null, a standard distance function is used for the
/// type `T` . Standard functions are defined for the following types:
///
///  * [Color], whose distance is the maximum component-wise delta.
///  * [Offset], whose distance is the Euclidean distance computed using the
///    method [Offset.distance].
///  * [Rect], whose distance is the maximum component-wise delta.
///  * [Size], whose distance is the [Offset.distance] of the offset computed as
///    the difference between two sizes.
///  * [int], whose distance is the absolute difference between two integers.
///  * [double], whose distance is the absolute difference between two doubles.
///
/// See also:
///
///  * [moreOrLessEquals], which is similar to this function, but specializes in
///    [double]s and has an optional `epsilon` parameter.
///  * [closeTo], which specializes in numbers only.
Matcher within<T>({
  required T from,
  double distance = precisionErrorTolerance,
  DistanceFunction<T>? distanceFunction,
}) {
  distanceFunction ??= _kStandardDistanceFunctions[T] as DistanceFunction<T>?;

  if (distanceFunction == null) {
    throw ArgumentError(
        'The specified distanceFunction was null, and a standard distance '
        'function was not found for type $T of the provided '
        '`from` argument.');
  }

  return _IsWithinDistance<T>(distanceFunction, from, distance);
}

class _IsWithinDistance<T> extends Matcher {
  const _IsWithinDistance(this.distanceFunction, this.value, this.epsilon);

  final DistanceFunction<T> distanceFunction;
  final T value;
  final double epsilon;

  @override
  bool matches(Object? object, Map<dynamic, dynamic> matchState) {
    if (object is! T) {
      return false;
    }
    if (object == value) {
      return true;
    }
    final T test = object;
    final double distance = distanceFunction(test, value);
    if (distance < 0) {
      throw ArgumentError(
          'Invalid distance function was used to compare a ${value.runtimeType} '
          'to a ${object.runtimeType}. The function must return a non-negative '
          'double value, but it returned $distance.');
    }
    matchState['distance'] = distance;
    return distance <= epsilon;
  }

  @override
  Description describe(Description description) =>
      description.add('$value (±$epsilon)');

  @override
  Description describeMismatch(
    Object? object,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    mismatchDescription
        .add('was ${matchState['distance']} away from the desired value.');
    return mismatchDescription;
  }
}

/// Controls how test HTML is canonicalized by [canonicalizeHtml] function.
///
/// In all cases whitespace between elements is stripped.
enum HtmlComparisonMode {
  /// Retains all attributes.
  ///
  /// Useful when very precise HTML comparison is needed that includes both
  /// layout and non-layout style attributes. This mode is rarely needed. Most
  /// tests should use [layoutOnly] or [nonLayoutOnly].
  everything,

  /// Retains only layout style attributes, such as "width".
  ///
  /// Useful when testing layout because it filters out all the noise that does
  /// not affect layout.
  layoutOnly,

  /// Retains only non-layout style attributes, such as "color".
  ///
  /// Useful when testing styling because it filters out all the noise from the
  /// layout attributes.
  nonLayoutOnly,

  /// Do not consider attributes when comparing HTML.
  noAttributes,
}

/// Rewrites [htmlContent] by removing irrelevant style attributes.
///
/// If [throwOnUnusedStyleProperties] is `true`, throws instead of rewriting. Set
/// [throwOnUnusedStyleProperties] to `true` to check that expected HTML strings do
/// not contain irrelevant attributes. It is ok for actual HTML to contain all
/// kinds of attributes. They only need to be filtered out before testing.
String canonicalizeHtml(
  String htmlContent, {
  HtmlComparisonMode mode = HtmlComparisonMode.nonLayoutOnly,
  bool throwOnUnusedStyleProperties = false,
  List<String>? ignoredStyleProperties,
}) {
  if (htmlContent.trim().isEmpty) {
    return '';
  }

  String? unusedStyleProperty(String name) {
    if (throwOnUnusedStyleProperties) {
      fail('Provided HTML contains style property "$name" which '
          'is not used for comparison in the test. The HTML was:\n\n$htmlContent');
    }

    return null;
  }

  html_package.Element cleanup(html_package.Element original) {
    String replacementTag = original.localName!;
    switch (replacementTag) {
      case 'flt-scene':
        replacementTag = 's';
      case 'flt-transform':
        replacementTag = 't';
      case 'flt-opacity':
        replacementTag = 'o';
      case 'flt-clip':
        final String? clipType = original.attributes['clip-type'];
        switch (clipType) {
          case 'rect':
            replacementTag = 'clip';
          case 'rrect':
            replacementTag = 'rclip';
          case 'physical-shape':
            replacementTag = 'pshape';
          default:
            throw Exception('Unknown clip type: $clipType');
        }
      case 'flt-clip-interior':
        replacementTag = 'clip-i';
      case 'flt-picture':
        replacementTag = 'pic';
      case 'flt-canvas':
        replacementTag = 'c';
      case 'flt-dom-canvas':
        replacementTag = 'd';
      case 'flt-semantics':
        replacementTag = 'sem';
      case 'flt-semantics-container':
        replacementTag = 'sem-c';
      case 'flt-semantics-img':
        replacementTag = 'sem-img';
      case 'flt-semantics-text-field':
        replacementTag = 'sem-tf';
    }

    final html_package.Element replacement =
        html_package.Element.tag(replacementTag);

    if (mode != HtmlComparisonMode.noAttributes) {
      // Sort the attributes so tests are not sensitive to their order, which
      // does not matter in terms of functionality.
      final List<String> attributeNames = original.attributes.keys.cast<String>().toList();
      attributeNames.sort();
      for (final String name in attributeNames) {
        final String value = original.attributes[name]!;
        if (name == 'style') {
          // The style attribute is handled separately because it contains substructure.
          continue;
        }

        // These are the only attributes we're interested in testing. This list
        // can change over time.
        if (name.startsWith('aria-') || name.startsWith('flt-') || name == 'role') {
          replacement.attributes[name] = value;
        }
      }

      if (original.attributes.containsKey('style')) {
        final String styleValue = original.attributes['style']!;

        int attrCount = 0;
        final String processedAttributes = styleValue
            .split(';')
            .map((String attr) {
              attr = attr.trim();
              if (attr.isEmpty) {
                return null;
              }

              if (mode != HtmlComparisonMode.everything) {
                final bool forLayout = mode == HtmlComparisonMode.layoutOnly;
                final List<String> parts = attr.split(':');
                if (parts.length == 2) {
                  final String name = parts.first;

                  if (ignoredStyleProperties != null && ignoredStyleProperties.contains(name)) {
                    return null;
                  }

                  // Whether the attribute is one that's set to the same value and
                  // never changes. Such attributes are usually not interesting to
                  // test.
                  final bool isStaticAttribute = const <String>[
                    'top',
                    'left',
                    'position',
                  ].contains(name);

                  if (isStaticAttribute) {
                    return unusedStyleProperty(name);
                  }

                  // Whether the attribute is set by the layout system.
                  final bool isLayoutAttribute = const <String>[
                    'top',
                    'left',
                    'bottom',
                    'right',
                    'position',
                    'width',
                    'height',
                    'font-size',
                    'transform',
                    'transform-origin',
                    'white-space',
                  ].contains(name);

                  if (forLayout && !isLayoutAttribute ||
                      !forLayout && isLayoutAttribute) {
                    return unusedStyleProperty(name);
                  }
                }
              }

              attrCount++;
              return attr.trim();
            })
            .where((String? attr) => attr != null && attr.isNotEmpty)
            .join('; ');

        if (attrCount > 0) {
          replacement.attributes['style'] = processedAttributes;
        }
      }
    } else if (throwOnUnusedStyleProperties && original.attributes.isNotEmpty) {
      fail('Provided HTML contains attributes. However, the comparison mode '
          'is $mode. The HTML was:\n\n$htmlContent');
    }

    for (final html_package.Node child in original.nodes) {
      if (child is html_package.Text && child.text.trim().isEmpty) {
        continue;
      }

      if (child is html_package.Element) {
        replacement.append(cleanup(child));
      } else {
        replacement.append(child.clone(true));
      }
    }

    return replacement;
  }

  final html_package.DocumentFragment originalDom =
      html_package.parseFragment(htmlContent);

  final html_package.DocumentFragment cleanDom =
      html_package.DocumentFragment();
  for (final html_package.Element child in originalDom.children) {
    cleanDom.append(cleanup(child));
  }

  return cleanDom.outerHtml;
}

/// Tests that [element] has the HTML structure described by [expectedHtml].
void expectHtml(DomElement element, String expectedHtml,
    {HtmlComparisonMode mode = HtmlComparisonMode.nonLayoutOnly}) {
  expectedHtml =
      canonicalizeHtml(expectedHtml, mode: mode, throwOnUnusedStyleProperties: true);
  final String actualHtml = canonicalizeHtml(element.outerHTML!, mode: mode);
  expect(actualHtml, expectedHtml);
}

class SceneTester {
  SceneTester(this.scene);

  final SurfaceScene scene;

  void expectSceneHtml(String expectedHtml) {
    expectHtml(scene.webOnlyRootElement!, expectedHtml,
        mode: HtmlComparisonMode.noAttributes);
  }
}

/// A matcher for functions that throw [AssertionError].
///
/// This is equivalent to `throwsA(isInstanceOf<AssertionError>())`.
///
/// If you are trying to test whether a call to [WidgetTester.pumpWidget]
/// results in an [AssertionError], see
/// [TestWidgetsFlutterBinding.takeException].
///
/// See also:
///
///  * [throwsFlutterError], to test if a function throws a [FlutterError].
///  * [throwsArgumentError], to test if a functions throws an [ArgumentError].
///  * [isAssertionError], to test if any object is any kind of [AssertionError].
final Matcher throwsAssertionError = throwsA(isAssertionError);

/// A matcher for [AssertionError].
///
/// This is equivalent to `isInstanceOf<AssertionError>()`.
///
/// See also:
///
///  * [throwsAssertionError], to test if a function throws any [AssertionError].
///  * [isFlutterError], to test if any object is a [FlutterError].
const Matcher isAssertionError = TypeMatcher<AssertionError>();
