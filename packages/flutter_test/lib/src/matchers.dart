// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Card;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:matcher/expect.dart';
import 'package:matcher/src/expect/async_matcher.dart'; // ignore: implementation_imports

import '_matchers_io.dart' if (dart.library.html) '_matchers_web.dart' show MatchesGoldenFile, captureImage;
import 'accessibility.dart';
import 'binding.dart';
import 'finders.dart';
import 'goldens.dart';
import 'widget_tester.dart' show WidgetTester;

/// Asserts that the [Finder] matches no widgets in the widget tree.
///
/// ## Sample code
///
/// ```dart
/// expect(find.text('Save'), findsNothing);
/// ```
///
/// See also:
///
///  * [findsWidgets], when you want the finder to find one or more widgets.
///  * [findsOneWidget], when you want the finder to find exactly one widget.
///  * [findsNWidgets], when you want the finder to find a specific number of widgets.
///  * [findsAtLeastNWidgets], when you want the finder to find at least a specific number of widgets.
const Matcher findsNothing = _FindsWidgetMatcher(null, 0);

/// Asserts that the [Finder] locates at least one widget in the widget tree.
///
/// ## Sample code
///
/// ```dart
/// expect(find.text('Save'), findsWidgets);
/// ```
///
/// See also:
///
///  * [findsNothing], when you want the finder to not find anything.
///  * [findsOneWidget], when you want the finder to find exactly one widget.
///  * [findsNWidgets], when you want the finder to find a specific number of widgets.
///  * [findsAtLeastNWidgets], when you want the finder to find at least a specific number of widgets.
const Matcher findsWidgets = _FindsWidgetMatcher(1, null);

/// Asserts that the [Finder] locates at exactly one widget in the widget tree.
///
/// ## Sample code
///
/// ```dart
/// expect(find.text('Save'), findsOneWidget);
/// ```
///
/// See also:
///
///  * [findsNothing], when you want the finder to not find anything.
///  * [findsWidgets], when you want the finder to find one or more widgets.
///  * [findsNWidgets], when you want the finder to find a specific number of widgets.
///  * [findsAtLeastNWidgets], when you want the finder to find at least a specific number of widgets.
const Matcher findsOneWidget = _FindsWidgetMatcher(1, 1);

/// Asserts that the [Finder] locates the specified number of widgets in the widget tree.
///
/// ## Sample code
///
/// ```dart
/// expect(find.text('Save'), findsNWidgets(2));
/// ```
///
/// See also:
///
///  * [findsNothing], when you want the finder to not find anything.
///  * [findsWidgets], when you want the finder to find one or more widgets.
///  * [findsOneWidget], when you want the finder to find exactly one widget.
///  * [findsAtLeastNWidgets], when you want the finder to find at least a specific number of widgets.
Matcher findsNWidgets(final int n) => _FindsWidgetMatcher(n, n);

/// Asserts that the [Finder] locates at least a number of widgets in the widget tree.
///
/// ## Sample code
///
/// ```dart
/// expect(find.text('Save'), findsAtLeastNWidgets(2));
/// ```
///
/// See also:
///
///  * [findsNothing], when you want the finder to not find anything.
///  * [findsWidgets], when you want the finder to find one or more widgets.
///  * [findsOneWidget], when you want the finder to find exactly one widget.
///  * [findsNWidgets], when you want the finder to find a specific number of widgets.
Matcher findsAtLeastNWidgets(final int n) => _FindsWidgetMatcher(n, null);

/// Asserts that the [Finder] locates a single widget that has at
/// least one [Offstage] widget ancestor.
///
/// It's important to use a full finder, since by default finders exclude
/// offstage widgets.
///
/// ## Sample code
///
/// ```dart
/// expect(find.text('Save', skipOffstage: false), isOffstage);
/// ```
///
/// See also:
///
///  * [isOnstage], the opposite.
const Matcher isOffstage = _IsOffstage();

/// Asserts that the [Finder] locates a single widget that has no
/// [Offstage] widget ancestors.
///
/// See also:
///
///  * [isOffstage], the opposite.
const Matcher isOnstage = _IsOnstage();

/// Asserts that the [Finder] locates a single widget that has at
/// least one [Card] widget ancestor.
///
/// See also:
///
///  * [isNotInCard], the opposite.
const Matcher isInCard = _IsInCard();

/// Asserts that the [Finder] locates a single widget that has no
/// [Card] widget ancestors.
///
/// This is equivalent to `isNot(isInCard)`.
///
/// See also:
///
///  * [isInCard], the opposite.
const Matcher isNotInCard = _IsNotInCard();

/// Asserts that the object represents the same color as [color] when used to paint.
///
/// Specifically this matcher checks the object is of type [Color] and its [Color.value]
/// equals to that of the given [color].
Matcher isSameColorAs(final Color color) => _ColorMatcher(targetColor: color);

/// Asserts that an object's toString() is a plausible one-line description.
///
/// Specifically, this matcher checks that the string does not contains newline
/// characters, and does not have leading or trailing whitespace, is not
/// empty, and does not contain the default `Instance of ...` string.
const Matcher hasOneLineDescription = _HasOneLineDescription();

/// Asserts that an object's toStringDeep() is a plausible multiline
/// description.
///
/// Specifically, this matcher checks that an object's
/// `toStringDeep(prefixLineOne, prefixOtherLines)`:
///
///  * Does not have leading or trailing whitespace.
///  * Does not contain the default `Instance of ...` string.
///  * The last line has characters other than tree connector characters and
///    whitespace. For example: the line ` │ ║ ╎` has only tree connector
///    characters and whitespace.
///  * Does not contain lines with trailing white space.
///  * Has multiple lines.
///  * The first line starts with `prefixLineOne`
///  * All subsequent lines start with `prefixOtherLines`.
const Matcher hasAGoodToStringDeep = _HasGoodToStringDeep();

/// A matcher for functions that throw [FlutterError].
///
/// This is equivalent to `throwsA(isA<FlutterError>())`.
///
/// If you are trying to test whether a call to [WidgetTester.pumpWidget]
/// results in a [FlutterError], see [TestWidgetsFlutterBinding.takeException].
///
/// See also:
///
///  * [throwsAssertionError], to test if a function throws any [AssertionError].
///  * [throwsArgumentError], to test if a functions throws an [ArgumentError].
///  * [isFlutterError], to test if any object is a [FlutterError].
final Matcher throwsFlutterError = throwsA(isFlutterError);

/// A matcher for functions that throw [AssertionError].
///
/// This is equivalent to `throwsA(isA<AssertionError>())`.
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

/// A matcher for [FlutterError].
///
/// This is equivalent to `isInstanceOf<FlutterError>()`.
///
/// See also:
///
///  * [throwsFlutterError], to test if a function throws a [FlutterError].
///  * [isAssertionError], to test if any object is any kind of [AssertionError].
final TypeMatcher<FlutterError> isFlutterError = isA<FlutterError>();

/// A matcher for [AssertionError].
///
/// This is equivalent to `isInstanceOf<AssertionError>()`.
///
/// See also:
///
///  * [throwsAssertionError], to test if a function throws any [AssertionError].
///  * [isFlutterError], to test if any object is a [FlutterError].
final TypeMatcher<AssertionError> isAssertionError = isA<AssertionError>();

/// A matcher that compares the type of the actual value to the type argument T.
///
/// This is identical to [isA] and is included for backwards compatibility.
TypeMatcher<T> isInstanceOf<T>() => isA<T>();

/// Asserts that two [double]s are equal, within some tolerated error.
///
/// {@template flutter.flutter_test.moreOrLessEquals}
/// Two values are considered equal if the difference between them is within
/// [precisionErrorTolerance] of the larger one. This is an arbitrary value
/// which can be adjusted using the `epsilon` argument. This matcher is intended
/// to compare floating point numbers that are the result of different sequences
/// of operations, such that they may have accumulated slightly different
/// errors.
/// {@endtemplate}
///
/// See also:
///
///  * [closeTo], which is identical except that the epsilon argument is
///    required and not named.
///  * [inInclusiveRange], which matches if the argument is in a specified
///    range.
///  * [rectMoreOrLessEquals] and [offsetMoreOrLessEquals], which do something
///    similar but for [Rect]s and [Offset]s respectively.
Matcher moreOrLessEquals(final double value, { final double epsilon = precisionErrorTolerance }) {
  return _MoreOrLessEquals(value, epsilon);
}

/// Asserts that two [Rect]s are equal, within some tolerated error.
///
/// {@macro flutter.flutter_test.moreOrLessEquals}
///
/// See also:
///
///  * [moreOrLessEquals], which is for [double]s.
///  * [offsetMoreOrLessEquals], which is for [Offset]s.
///  * [within], which offers a generic version of this functionality that can
///    be used to match [Rect]s as well as other types.
Matcher rectMoreOrLessEquals(final Rect value, { final double epsilon = precisionErrorTolerance }) {
  return _IsWithinDistance<Rect>(_rectDistance, value, epsilon);
}

/// Asserts that two [Matrix4]s are equal, within some tolerated error.
///
/// {@macro flutter.flutter_test.moreOrLessEquals}
///
/// See also:
///
///  * [moreOrLessEquals], which is for [double]s.
///  * [offsetMoreOrLessEquals], which is for [Offset]s.
Matcher matrixMoreOrLessEquals(final Matrix4 value, { final double epsilon = precisionErrorTolerance }) {
  return _IsWithinDistance<Matrix4>(_matrixDistance, value, epsilon);
}

/// Asserts that two [Offset]s are equal, within some tolerated error.
///
/// {@macro flutter.flutter_test.moreOrLessEquals}
///
/// See also:
///
///  * [moreOrLessEquals], which is for [double]s.
///  * [rectMoreOrLessEquals], which is for [Rect]s.
///  * [within], which offers a generic version of this functionality that can
///    be used to match [Offset]s as well as other types.
Matcher offsetMoreOrLessEquals(final Offset value, { final double epsilon = precisionErrorTolerance }) {
  return _IsWithinDistance<Offset>(_offsetDistance, value, epsilon);
}

/// Asserts that two [String]s or `Iterable<String>`s are equal after
/// normalizing likely hash codes.
///
/// A `#` followed by 5 hexadecimal digits is assumed to be a short hash code
/// and is normalized to `#00000`.
///
/// Only [String] or `Iterable<String>` are allowed types for `value`.
///
/// See Also:
///
///  * [describeIdentity], a method that generates short descriptions of objects
///    with ids that match the pattern `#[0-9a-f]{5}`.
///  * [shortHash], a method that generates a 5 character long hexadecimal
///    [String] based on [Object.hashCode].
///  * [DiagnosticableTree.toStringDeep], a method that returns a [String]
///    typically containing multiple hash codes.
Matcher equalsIgnoringHashCodes(final Object value) {
  assert(value is String || value is Iterable<String>, "Only String or Iterable<String> are allowed types for equalsIgnoringHashCodes, it doesn't accept ${value.runtimeType}");
  return _EqualsIgnoringHashCodes(value);
}

/// A matcher for [MethodCall]s, asserting that it has the specified
/// method [name] and [arguments].
///
/// Arguments checking implements deep equality for [List] and [Map] types.
Matcher isMethodCall(final String name, { required final dynamic arguments }) {
  return _IsMethodCall(name, arguments);
}

/// Asserts that 2 paths cover the same area by sampling multiple points.
///
/// Samples at least [sampleSize]^2 points inside [areaToCompare], and asserts
/// that the [Path.contains] method returns the same value for each of the
/// points for both paths.
///
/// When using this matcher you typically want to use a rectangle larger than
/// the area you expect to paint in for [areaToCompare] to catch errors where
/// the path draws outside the expected area.
Matcher coversSameAreaAs(final Path expectedPath, { required final Rect areaToCompare, final int sampleSize = 20 })
  => _CoversSameAreaAs(expectedPath, areaToCompare: areaToCompare, sampleSize: sampleSize);

/// Asserts that a [Finder], [Future<ui.Image>], or [ui.Image] matches the
/// golden image file identified by [key], with an optional [version] number.
///
/// For the case of a [Finder], the [Finder] must match exactly one widget and
/// the rendered image of the first [RepaintBoundary] ancestor of the widget is
/// treated as the image for the widget. As such, you may choose to wrap a test
/// widget in a [RepaintBoundary] to specify a particular focus for the test.
///
/// The [key] may be either a [Uri] or a [String] representation of a URL.
///
/// The [version] is a number that can be used to differentiate historical
/// golden files. This parameter is optional.
///
/// This is an asynchronous matcher, meaning that callers should use
/// [expectLater] when using this matcher and await the future returned by
/// [expectLater].
///
/// ## Golden File Testing
///
/// The term __golden file__ refers to a master image that is considered the true
/// rendering of a given widget, state, application, or other visual
/// representation you have chosen to capture.
///
/// The master golden image files that are tested against can be created or
/// updated by running `flutter test --update-goldens` on the test.
///
/// {@tool snippet}
/// Sample invocations of [matchesGoldenFile].
///
/// ```dart
/// await expectLater(
///   find.text('Save'),
///   matchesGoldenFile('save.png'),
/// );
///
/// await expectLater(
///   image,
///   matchesGoldenFile('save.png'),
/// );
///
/// await expectLater(
///   imageFuture,
///   matchesGoldenFile(
///     'save.png',
///     version: 2,
///   ),
/// );
///
/// await expectLater(
///   find.byType(MyWidget),
///   matchesGoldenFile('goldens/myWidget.png'),
/// );
/// ```
/// {@end-tool}
///
/// {@template flutter.flutter_test.matchesGoldenFile.custom_fonts}
/// ## Including Fonts
///
/// Custom fonts may render differently across different platforms, or
/// between different versions of Flutter. For example, a golden file generated
/// on Windows with fonts will likely differ from the one produced by another
/// operating system. Even on the same platform, if the generated golden is
/// tested with a different Flutter version, the test may fail and require an
/// updated image.
///
/// By default, the Flutter framework uses a font called 'Ahem' which shows
/// squares instead of characters, however, it is possible to render images using
/// custom fonts. For example, this is how to load the 'Roboto' font for a
/// golden test:
///
/// {@tool snippet}
/// How to load a custom font for golden images.
/// ```dart
/// testWidgets('Creating a golden image with a custom font', (tester) async {
///   // Assuming the 'Roboto.ttf' file is declared in the pubspec.yaml file
///   final font = rootBundle.load('path/to/font-file/Roboto.ttf');
///
///   final fontLoader = FontLoader('Roboto')..addFont(font);
///   await fontLoader.load();
///
///   await tester.pumpWidget(const SomeWidget());
///
///   await expectLater(
///     find.byType(SomeWidget),
///     matchesGoldenFile('someWidget.png'),
///   );
/// });
/// ```
/// {@end-tool}
///
/// The example above loads the desired font only for that specific test. To load
/// a font for all golden file tests, the `FontLoader.load()` call could be
/// moved in the `flutter_test_config.dart`. In this way, the font will always be
/// loaded before a test:
///
/// {@tool snippet}
/// Loading a custom font from the flutter_test_config.dart file.
/// ```dart
/// Future<void> testExecutable(FutureOr<void> Function() testMain) async {
///   setUpAll(() async {
///     final fontLoader = FontLoader('SomeFont')..addFont(someFont);
///     await fontLoader.load();
///   });
///
///   await testMain();
/// });
/// ```
/// {@end-tool}
/// {@endtemplate}
///
/// See also:
///
///  * [GoldenFileComparator], which acts as the backend for this matcher.
///  * [LocalFileComparator], which is the default [GoldenFileComparator]
///    implementation for `flutter test`.
///  * [matchesReferenceImage], which should be used instead if you want to
///    verify that two different code paths create identical images.
///  * [flutter_test] for a discussion of test configurations, whereby callers
///    may swap out the backend for this matcher.
AsyncMatcher matchesGoldenFile(final Object key, {final int? version}) {
  if (key is Uri) {
    return MatchesGoldenFile(key, version);
  } else if (key is String) {
    return MatchesGoldenFile.forStringPath(key, version);
  }
  throw ArgumentError('Unexpected type for golden file: ${key.runtimeType}');
}

/// Asserts that a [Finder], [Future<ui.Image>], or [ui.Image] matches a
/// reference image identified by [image].
///
/// For the case of a [Finder], the [Finder] must match exactly one widget and
/// the rendered image of the first [RepaintBoundary] ancestor of the widget is
/// treated as the image for the widget.
///
/// This is an asynchronous matcher, meaning that callers should use
/// [expectLater] when using this matcher and await the future returned by
/// [expectLater].
///
/// ## Sample code
///
/// ```dart
/// final ui.Paint paint = ui.Paint()
///   ..style = ui.PaintingStyle.stroke
///   ..strokeWidth = 1.0;
/// final ui.PictureRecorder recorder = ui.PictureRecorder();
/// final ui.Canvas pictureCanvas = ui.Canvas(recorder);
/// pictureCanvas.drawCircle(Offset.zero, 20.0, paint);
/// final ui.Picture picture = recorder.endRecording();
/// ui.Image referenceImage = picture.toImage(50, 50);
///
/// await expectLater(find.text('Save'), matchesReferenceImage(referenceImage));
/// await expectLater(image, matchesReferenceImage(referenceImage);
/// await expectLater(imageFuture, matchesReferenceImage(referenceImage));
/// ```
///
/// See also:
///
///  * [matchesGoldenFile], which should be used instead if you need to verify
///    that a [Finder] or [ui.Image] matches a golden image.
AsyncMatcher matchesReferenceImage(final ui.Image image) {
  return _MatchesReferenceImage(image);
}

/// Asserts that a [SemanticsNode] contains the specified information.
///
/// If either the label, hint, value, textDirection, or rect fields are not
/// provided, then they are not part of the comparison. All of the boolean
/// flag and action fields must match, and default to false.
///
/// To retrieve the semantics data of a widget, use [WidgetTester.getSemantics]
/// with a [Finder] that returns a single widget. Semantics must be enabled
/// in order to use this method.
///
/// ## Sample code
///
/// ```dart
/// final SemanticsHandle handle = tester.ensureSemantics();
/// expect(tester.getSemantics(find.text('hello')), matchesSemantics(label: 'hello'));
/// handle.dispose();
/// ```
///
/// See also:
///
///   * [WidgetTester.getSemantics], the tester method which retrieves semantics.
///   * [containsSemantics], a similar matcher without default values for flags or actions.
Matcher matchesSemantics({
  final String? label,
  final AttributedString? attributedLabel,
  final String? hint,
  final AttributedString? attributedHint,
  final String? value,
  final AttributedString? attributedValue,
  final String? increasedValue,
  final AttributedString? attributedIncreasedValue,
  final String? decreasedValue,
  final AttributedString? attributedDecreasedValue,
  final String? tooltip,
  final TextDirection? textDirection,
  final Rect? rect,
  final Size? size,
  final double? elevation,
  final double? thickness,
  final int? platformViewId,
  final int? maxValueLength,
  final int? currentValueLength,
  // Flags //
  final bool hasCheckedState = false,
  final bool isChecked = false,
  final bool isCheckStateMixed = false,
  final bool isSelected = false,
  final bool isButton = false,
  final bool isSlider = false,
  final bool isKeyboardKey = false,
  final bool isLink = false,
  final bool isFocused = false,
  final bool isFocusable = false,
  final bool isTextField = false,
  final bool isReadOnly = false,
  final bool hasEnabledState = false,
  final bool isEnabled = false,
  final bool isInMutuallyExclusiveGroup = false,
  final bool isHeader = false,
  final bool isObscured = false,
  final bool isMultiline = false,
  final bool namesRoute = false,
  final bool scopesRoute = false,
  final bool isHidden = false,
  final bool isImage = false,
  final bool isLiveRegion = false,
  final bool hasToggledState = false,
  final bool isToggled = false,
  final bool hasImplicitScrolling = false,
  // Actions //
  final bool hasTapAction = false,
  final bool hasLongPressAction = false,
  final bool hasScrollLeftAction = false,
  final bool hasScrollRightAction = false,
  final bool hasScrollUpAction = false,
  final bool hasScrollDownAction = false,
  final bool hasIncreaseAction = false,
  final bool hasDecreaseAction = false,
  final bool hasShowOnScreenAction = false,
  final bool hasMoveCursorForwardByCharacterAction = false,
  final bool hasMoveCursorBackwardByCharacterAction = false,
  final bool hasMoveCursorForwardByWordAction = false,
  final bool hasMoveCursorBackwardByWordAction = false,
  final bool hasSetTextAction = false,
  final bool hasSetSelectionAction = false,
  final bool hasCopyAction = false,
  final bool hasCutAction = false,
  final bool hasPasteAction = false,
  final bool hasDidGainAccessibilityFocusAction = false,
  final bool hasDidLoseAccessibilityFocusAction = false,
  final bool hasDismissAction = false,
  // Custom actions and overrides
  final String? onTapHint,
  final String? onLongPressHint,
  final List<CustomSemanticsAction>? customActions,
  final List<Matcher>? children,
}) {
  return _MatchesSemanticsData(
    label: label,
    attributedLabel: attributedLabel,
    hint: hint,
    attributedHint: attributedHint,
    value: value,
    attributedValue: attributedValue,
    increasedValue: increasedValue,
    attributedIncreasedValue: attributedIncreasedValue,
    decreasedValue: decreasedValue,
    attributedDecreasedValue: attributedDecreasedValue,
    tooltip: tooltip,
    textDirection: textDirection,
    rect: rect,
    size: size,
    elevation: elevation,
    thickness: thickness,
    platformViewId: platformViewId,
    customActions: customActions,
    maxValueLength: maxValueLength,
    currentValueLength: currentValueLength,
    // Flags
    hasCheckedState: hasCheckedState,
    isChecked: isChecked,
    isCheckStateMixed: isCheckStateMixed,
    isSelected: isSelected,
    isButton: isButton,
    isSlider: isSlider,
    isKeyboardKey: isKeyboardKey,
    isLink: isLink,
    isFocused: isFocused,
    isFocusable: isFocusable,
    isTextField: isTextField,
    isReadOnly: isReadOnly,
    hasEnabledState: hasEnabledState,
    isEnabled: isEnabled,
    isInMutuallyExclusiveGroup: isInMutuallyExclusiveGroup,
    isHeader: isHeader,
    isObscured: isObscured,
    isMultiline: isMultiline,
    namesRoute: namesRoute,
    scopesRoute: scopesRoute,
    isHidden: isHidden,
    isImage: isImage,
    isLiveRegion: isLiveRegion,
    hasToggledState: hasToggledState,
    isToggled: isToggled,
    hasImplicitScrolling: hasImplicitScrolling,
    // Actions
    hasTapAction: hasTapAction,
    hasLongPressAction: hasLongPressAction,
    hasScrollLeftAction: hasScrollLeftAction,
    hasScrollRightAction: hasScrollRightAction,
    hasScrollUpAction: hasScrollUpAction,
    hasScrollDownAction: hasScrollDownAction,
    hasIncreaseAction: hasIncreaseAction,
    hasDecreaseAction: hasDecreaseAction,
    hasShowOnScreenAction: hasShowOnScreenAction,
    hasMoveCursorForwardByCharacterAction: hasMoveCursorForwardByCharacterAction,
    hasMoveCursorBackwardByCharacterAction: hasMoveCursorBackwardByCharacterAction,
    hasMoveCursorForwardByWordAction: hasMoveCursorForwardByWordAction,
    hasMoveCursorBackwardByWordAction: hasMoveCursorBackwardByWordAction,
    hasSetTextAction: hasSetTextAction,
    hasSetSelectionAction: hasSetSelectionAction,
    hasCopyAction: hasCopyAction,
    hasCutAction: hasCutAction,
    hasPasteAction: hasPasteAction,
    hasDidGainAccessibilityFocusAction: hasDidGainAccessibilityFocusAction,
    hasDidLoseAccessibilityFocusAction: hasDidLoseAccessibilityFocusAction,
    hasDismissAction: hasDismissAction,
    // Custom actions and overrides
    children: children,
    onLongPressHint: onLongPressHint,
    onTapHint: onTapHint,
  );
}

/// Asserts that a [SemanticsNode] contains the specified information.
///
/// There are no default expected values, so no unspecified values will be
/// validated.
///
/// To retrieve the semantics data of a widget, use [WidgetTester.getSemantics]
/// with a [Finder] that returns a single widget. Semantics must be enabled
/// in order to use this method.
///
/// ## Sample code
///
/// ```dart
/// final SemanticsHandle handle = tester.ensureSemantics();
/// expect(tester.getSemantics(find.text('hello')), hasSemantics(label: 'hello'));
/// handle.dispose();
/// ```
///
/// See also:
///
///   * [WidgetTester.getSemantics], the tester method which retrieves semantics.
///   * [matchesSemantics], a similar matcher with default values for flags and actions.
Matcher containsSemantics({
  final String? label,
  final AttributedString? attributedLabel,
  final String? hint,
  final AttributedString? attributedHint,
  final String? value,
  final AttributedString? attributedValue,
  final String? increasedValue,
  final AttributedString? attributedIncreasedValue,
  final String? decreasedValue,
  final AttributedString? attributedDecreasedValue,
  final String? tooltip,
  final TextDirection? textDirection,
  final Rect? rect,
  final Size? size,
  final double? elevation,
  final double? thickness,
  final int? platformViewId,
  final int? maxValueLength,
  final int? currentValueLength,
  // Flags
  final bool? hasCheckedState,
  final bool? isChecked,
  final bool? isCheckStateMixed,
  final bool? isSelected,
  final bool? isButton,
  final bool? isSlider,
  final bool? isKeyboardKey,
  final bool? isLink,
  final bool? isFocused,
  final bool? isFocusable,
  final bool? isTextField,
  final bool? isReadOnly,
  final bool? hasEnabledState,
  final bool? isEnabled,
  final bool? isInMutuallyExclusiveGroup,
  final bool? isHeader,
  final bool? isObscured,
  final bool? isMultiline,
  final bool? namesRoute,
  final bool? scopesRoute,
  final bool? isHidden,
  final bool? isImage,
  final bool? isLiveRegion,
  final bool? hasToggledState,
  final bool? isToggled,
  final bool? hasImplicitScrolling,
  // Actions
  final bool? hasTapAction,
  final bool? hasLongPressAction,
  final bool? hasScrollLeftAction,
  final bool? hasScrollRightAction,
  final bool? hasScrollUpAction,
  final bool? hasScrollDownAction,
  final bool? hasIncreaseAction,
  final bool? hasDecreaseAction,
  final bool? hasShowOnScreenAction,
  final bool? hasMoveCursorForwardByCharacterAction,
  final bool? hasMoveCursorBackwardByCharacterAction,
  final bool? hasMoveCursorForwardByWordAction,
  final bool? hasMoveCursorBackwardByWordAction,
  final bool? hasSetTextAction,
  final bool? hasSetSelectionAction,
  final bool? hasCopyAction,
  final bool? hasCutAction,
  final bool? hasPasteAction,
  final bool? hasDidGainAccessibilityFocusAction,
  final bool? hasDidLoseAccessibilityFocusAction,
  final bool? hasDismissAction,
  // Custom actions and overrides
  final String? onTapHint,
  final String? onLongPressHint,
  final List<CustomSemanticsAction>? customActions,
  final List<Matcher>? children,
}) {
  return _MatchesSemanticsData(
    label: label,
    attributedLabel: attributedLabel,
    hint: hint,
    attributedHint: attributedHint,
    value: value,
    attributedValue: attributedValue,
    increasedValue: increasedValue,
    attributedIncreasedValue: attributedIncreasedValue,
    decreasedValue: decreasedValue,
    attributedDecreasedValue: attributedDecreasedValue,
    tooltip: tooltip,
    textDirection: textDirection,
    rect: rect,
    size: size,
    elevation: elevation,
    thickness: thickness,
    platformViewId: platformViewId,
    customActions: customActions,
    maxValueLength: maxValueLength,
    currentValueLength: currentValueLength,
    // Flags
    hasCheckedState: hasCheckedState,
    isChecked: isChecked,
    isCheckStateMixed: isCheckStateMixed,
    isSelected: isSelected,
    isButton: isButton,
    isSlider: isSlider,
    isKeyboardKey: isKeyboardKey,
    isLink: isLink,
    isFocused: isFocused,
    isFocusable: isFocusable,
    isTextField: isTextField,
    isReadOnly: isReadOnly,
    hasEnabledState: hasEnabledState,
    isEnabled: isEnabled,
    isInMutuallyExclusiveGroup: isInMutuallyExclusiveGroup,
    isHeader: isHeader,
    isObscured: isObscured,
    isMultiline: isMultiline,
    namesRoute: namesRoute,
    scopesRoute: scopesRoute,
    isHidden: isHidden,
    isImage: isImage,
    isLiveRegion: isLiveRegion,
    hasToggledState: hasToggledState,
    isToggled: isToggled,
    hasImplicitScrolling: hasImplicitScrolling,
    // Actions
    hasTapAction: hasTapAction,
    hasLongPressAction: hasLongPressAction,
    hasScrollLeftAction: hasScrollLeftAction,
    hasScrollRightAction: hasScrollRightAction,
    hasScrollUpAction: hasScrollUpAction,
    hasScrollDownAction: hasScrollDownAction,
    hasIncreaseAction: hasIncreaseAction,
    hasDecreaseAction: hasDecreaseAction,
    hasShowOnScreenAction: hasShowOnScreenAction,
    hasMoveCursorForwardByCharacterAction: hasMoveCursorForwardByCharacterAction,
    hasMoveCursorBackwardByCharacterAction: hasMoveCursorBackwardByCharacterAction,
    hasMoveCursorForwardByWordAction: hasMoveCursorForwardByWordAction,
    hasMoveCursorBackwardByWordAction: hasMoveCursorBackwardByWordAction,
    hasSetTextAction: hasSetTextAction,
    hasSetSelectionAction: hasSetSelectionAction,
    hasCopyAction: hasCopyAction,
    hasCutAction: hasCutAction,
    hasPasteAction: hasPasteAction,
    hasDidGainAccessibilityFocusAction: hasDidGainAccessibilityFocusAction,
    hasDidLoseAccessibilityFocusAction: hasDidLoseAccessibilityFocusAction,
    hasDismissAction: hasDismissAction,
    // Custom actions and overrides
    children: children,
    onLongPressHint: onLongPressHint,
    onTapHint: onTapHint,
  );
}

/// Asserts that the currently rendered widget meets the provided accessibility
/// `guideline`.
///
/// This matcher requires the result to be awaited and for semantics to be
/// enabled first.
///
/// ## Sample code
///
/// ```dart
/// final SemanticsHandle handle = tester.ensureSemantics();
/// await expectLater(tester, meetsGuideline(textContrastGuideline));
/// handle.dispose();
/// ```
///
/// Supported accessibility guidelines:
///
///   * [androidTapTargetGuideline], for Android minimum tappable area guidelines.
///   * [iOSTapTargetGuideline], for iOS minimum tappable area guidelines.
///   * [textContrastGuideline], for WCAG minimum text contrast guidelines.
///   * [labeledTapTargetGuideline], for enforcing labels on tappable areas.
AsyncMatcher meetsGuideline(final AccessibilityGuideline guideline) {
  return _MatchesAccessibilityGuideline(guideline);
}

/// The inverse matcher of [meetsGuideline].
///
/// This is needed because the [isNot] matcher does not compose with an
/// [AsyncMatcher].
AsyncMatcher doesNotMeetGuideline(final AccessibilityGuideline guideline) {
  return _DoesNotMatchAccessibilityGuideline(guideline);
}

class _FindsWidgetMatcher extends Matcher {
  const _FindsWidgetMatcher(this.min, this.max);

  final int? min;
  final int? max;

  @override
  bool matches(covariant final Finder finder, final Map<dynamic, dynamic> matchState) {
    assert(min != null || max != null);
    assert(min == null || max == null || min! <= max!);
    matchState[Finder] = finder;
    int count = 0;
    final Iterator<Element> iterator = finder.evaluate().iterator;
    if (min != null) {
      while (count < min! && iterator.moveNext()) {
        count += 1;
      }
      if (count < min!) {
        return false;
      }
    }
    if (max != null) {
      while (count <= max! && iterator.moveNext()) {
        count += 1;
      }
      if (count > max!) {
        return false;
      }
    }
    return true;
  }

  @override
  Description describe(final Description description) {
    assert(min != null || max != null);
    if (min == max) {
      if (min == 1) {
        return description.add('exactly one matching node in the widget tree');
      }
      return description.add('exactly $min matching nodes in the widget tree');
    }
    if (min == null) {
      if (max == 0) {
        return description.add('no matching nodes in the widget tree');
      }
      if (max == 1) {
        return description.add('at most one matching node in the widget tree');
      }
      return description.add('at most $max matching nodes in the widget tree');
    }
    if (max == null) {
      if (min == 1) {
        return description.add('at least one matching node in the widget tree');
      }
      return description.add('at least $min matching nodes in the widget tree');
    }
    return description.add('between $min and $max matching nodes in the widget tree (inclusive)');
  }

  @override
  Description describeMismatch(
    final dynamic item,
    final Description mismatchDescription,
    final Map<dynamic, dynamic> matchState,
    final bool verbose,
  ) {
    final Finder finder = matchState[Finder] as Finder;
    final int count = finder.evaluate().length;
    if (count == 0) {
      assert(min != null && min! > 0);
      if (min == 1 && max == 1) {
        return mismatchDescription.add('means none were found but one was expected');
      }
      return mismatchDescription.add('means none were found but some were expected');
    }
    if (max == 0) {
      if (count == 1) {
        return mismatchDescription.add('means one was found but none were expected');
      }
      return mismatchDescription.add('means some were found but none were expected');
    }
    if (min != null && count < min!) {
      return mismatchDescription.add('is not enough');
    }
    assert(max != null && count > min!);
    return mismatchDescription.add('is too many');
  }
}

bool _hasAncestorMatching(final Finder finder, final bool Function(Widget widget) predicate) {
  final Iterable<Element> nodes = finder.evaluate();
  if (nodes.length != 1) {
    return false;
  }
  bool result = false;
  nodes.single.visitAncestorElements((final Element ancestor) {
    if (predicate(ancestor.widget)) {
      result = true;
      return false;
    }
    return true;
  });
  return result;
}

bool _hasAncestorOfType(final Finder finder, final Type targetType) {
  return _hasAncestorMatching(finder, (final Widget widget) => widget.runtimeType == targetType);
}

class _IsOffstage extends Matcher {
  const _IsOffstage();

  @override
  bool matches(covariant final Finder finder, final Map<dynamic, dynamic> matchState) {
    return _hasAncestorMatching(finder, (final Widget widget) {
      if (widget is Offstage) {
        return widget.offstage;
      }
      return false;
    });
  }

  @override
  Description describe(final Description description) => description.add('offstage');
}

class _IsOnstage extends Matcher {
  const _IsOnstage();

  @override
  bool matches(covariant final Finder finder, final Map<dynamic, dynamic> matchState) {
    final Iterable<Element> nodes = finder.evaluate();
    if (nodes.length != 1) {
      return false;
    }
    bool result = true;
    nodes.single.visitAncestorElements((final Element ancestor) {
      final Widget widget = ancestor.widget;
      if (widget is Offstage) {
        result = !widget.offstage;
        return false;
      }
      return true;
    });
    return result;
  }

  @override
  Description describe(final Description description) => description.add('onstage');
}

class _IsInCard extends Matcher {
  const _IsInCard();

  @override
  bool matches(covariant final Finder finder, final Map<dynamic, dynamic> matchState) => _hasAncestorOfType(finder, Card);

  @override
  Description describe(final Description description) => description.add('in card');
}

class _IsNotInCard extends Matcher {
  const _IsNotInCard();

  @override
  bool matches(covariant final Finder finder, final Map<dynamic, dynamic> matchState) => !_hasAncestorOfType(finder, Card);

  @override
  Description describe(final Description description) => description.add('not in card');
}

class _HasOneLineDescription extends Matcher {
  const _HasOneLineDescription();

  @override
  bool matches(final dynamic object, final Map<dynamic, dynamic> matchState) {
    final String description = object.toString();
    return description.isNotEmpty
        && !description.contains('\n')
        && !description.contains('Instance of ')
        && description.trim() == description;
  }

  @override
  Description describe(final Description description) => description.add('one line description');
}

class _EqualsIgnoringHashCodes extends Matcher {
  _EqualsIgnoringHashCodes(final Object v) : _value = _normalize(v);

  final Object _value;

  static final Object _mismatchedValueKey = Object();

  static String _normalizeString(final String value) {
    return value.replaceAll(RegExp(r'#[\da-fA-F]{5}'), '#00000');
  }

  static Object _normalize(final Object value, {final bool expected = true}) {
    if (value is String) {
      return _normalizeString(value);
    }
    if (value is Iterable<String>) {
      return value.map<String>((final dynamic item) => _normalizeString(item.toString()));
    }
    throw ArgumentError('The specified ${expected ? 'expected' : 'comparison'} value for '
        'equalsIgnoringHashCodes must be a String or an Iterable<String>, '
        'not a ${value.runtimeType}');
  }

  @override
  bool matches(final dynamic object, final Map<dynamic, dynamic> matchState) {
    final Object normalized = _normalize(object as Object, expected: false);
    if (!equals(_value).matches(normalized, matchState)) {
      matchState[_mismatchedValueKey] = normalized;
      return false;
    }
    return true;
  }

  @override
  Description describe(final Description description) {
    if (_value is String) {
      return description.add('normalized value matches $_value');
    }
    return description.add('normalized value matches\n').addDescriptionOf(_value);
  }

  @override
  Description describeMismatch(
    final dynamic item,
    final Description mismatchDescription,
    final Map<dynamic, dynamic> matchState,
    final bool verbose,
  ) {
    if (matchState.containsKey(_mismatchedValueKey)) {
      final Object actualValue = matchState[_mismatchedValueKey] as Object;
      // Leading whitespace is added so that lines in the multiline
      // description returned by addDescriptionOf are all indented equally
      // which makes the output easier to read for this case.
      return mismatchDescription
          .add('was expected to be normalized value\n')
          .addDescriptionOf(_value)
          .add('\nbut got\n')
          .addDescriptionOf(actualValue);
    }
    return mismatchDescription;
  }
}

/// Returns true if [c] represents a whitespace code unit.
bool _isWhitespace(final int c) => (c <= 0x000D && c >= 0x0009) || c == 0x0020;

/// Returns true if [c] represents a vertical line Unicode line art code unit.
///
/// See [https://en.wikipedia.org/wiki/Box-drawing_character]. This method only
/// specifies vertical line art code units currently used by Flutter line art.
/// There are other line art characters that technically also represent vertical
/// lines.
bool _isVerticalLine(final int c) {
  return c == 0x2502 || c == 0x2503 || c == 0x2551 || c == 0x254e;
}

/// Returns whether a [line] is all vertical tree connector characters.
///
/// Example vertical tree connector characters: `│ ║ ╎`.
/// The last line of a text tree contains only vertical tree connector
/// characters indicates a poorly formatted tree.
bool _isAllTreeConnectorCharacters(final String line) {
  for (int i = 0; i < line.length; ++i) {
    final int c = line.codeUnitAt(i);
    if (!_isWhitespace(c) && !_isVerticalLine(c)) {
      return false;
    }
  }
  return true;
}

class _HasGoodToStringDeep extends Matcher {
  const _HasGoodToStringDeep();

  static final Object _toStringDeepErrorDescriptionKey = Object();

  @override
  bool matches(final dynamic object, final Map<dynamic, dynamic> matchState) {
    final List<String> issues = <String>[];
    String description = object.toStringDeep() as String; // ignore: avoid_dynamic_calls
    if (description.endsWith('\n')) {
      // Trim off trailing \n as the remaining calculations assume
      // the description does not end with a trailing \n.
      description = description.substring(0, description.length - 1);
    } else {
      issues.add('Not terminated with a line break.');
    }

    if (description.trim() != description) {
      issues.add('Has trailing whitespace.');
    }

    final List<String> lines = description.split('\n');
    if (lines.length < 2) {
      issues.add('Does not have multiple lines.');
    }

    if (description.contains('Instance of ')) {
      issues.add('Contains text "Instance of ".');
    }

    for (int i = 0; i < lines.length; ++i) {
      final String line = lines[i];
      if (line.isEmpty) {
        issues.add('Line ${i + 1} is empty.');
      }

      if (line.trimRight() != line) {
        issues.add('Line ${i + 1} has trailing whitespace.');
      }
    }

    if (_isAllTreeConnectorCharacters(lines.last)) {
      issues.add('Last line is all tree connector characters.');
    }

    // If a toStringDeep method doesn't properly handle nested values that
    // contain line breaks it can fail to add the required prefixes to all
    // lined when toStringDeep is called specifying prefixes.
    const String prefixLineOne = 'PREFIX_LINE_ONE____';
    const String prefixOtherLines = 'PREFIX_OTHER_LINES_';
    final List<String> prefixIssues = <String>[];
    // ignore: avoid_dynamic_calls
    String descriptionWithPrefixes = object.toStringDeep(prefixLineOne: prefixLineOne, prefixOtherLines: prefixOtherLines) as String;
    if (descriptionWithPrefixes.endsWith('\n')) {
      // Trim off trailing \n as the remaining calculations assume
      // the description does not end with a trailing \n.
      descriptionWithPrefixes = descriptionWithPrefixes.substring(
          0, descriptionWithPrefixes.length - 1);
    }
    final List<String> linesWithPrefixes = descriptionWithPrefixes.split('\n');
    if (!linesWithPrefixes.first.startsWith(prefixLineOne)) {
      prefixIssues.add('First line does not contain expected prefix.');
    }

    for (int i = 1; i < linesWithPrefixes.length; ++i) {
      if (!linesWithPrefixes[i].startsWith(prefixOtherLines)) {
        prefixIssues.add('Line ${i + 1} does not contain the expected prefix.');
      }
    }

    final StringBuffer errorDescription = StringBuffer();
    if (issues.isNotEmpty) {
      errorDescription.writeln('Bad toStringDeep():');
      errorDescription.writeln(description);
      errorDescription.writeAll(issues, '\n');
    }

    if (prefixIssues.isNotEmpty) {
      errorDescription.writeln(
          'Bad toStringDeep(prefixLineOne: "$prefixLineOne", prefixOtherLines: "$prefixOtherLines"):');
      errorDescription.writeln(descriptionWithPrefixes);
      errorDescription.writeAll(prefixIssues, '\n');
    }

    if (errorDescription.isNotEmpty) {
      matchState[_toStringDeepErrorDescriptionKey] =
          errorDescription.toString();
      return false;
    }
    return true;
  }

  @override
  Description describeMismatch(
    final dynamic item,
    final Description mismatchDescription,
    final Map<dynamic, dynamic> matchState,
    final bool verbose,
  ) {
    if (matchState.containsKey(_toStringDeepErrorDescriptionKey)) {
      return mismatchDescription.add(matchState[_toStringDeepErrorDescriptionKey] as String);
    }
    return mismatchDescription;
  }

  @override
  Description describe(final Description description) {
    return description.add('multi line description');
  }
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
typedef DistanceFunction<T> = num Function(T a, T b);

/// The type of a union of instances of [DistanceFunction<T>] for various types
/// T.
///
/// This type is used to describe a collection of [DistanceFunction<T>]
/// functions which have (potentially) unrelated argument types. Since the
/// argument types of the functions may be unrelated, their type is declared as
/// `Never`, which is the bottom type in dart to which all other types can be
/// assigned to.
///
/// Calling an instance of this type must either be done dynamically, or by
/// first casting it to a [DistanceFunction<T>] for some concrete T.
typedef AnyDistanceFunction = num Function(Never a, Never b);

const Map<Type, AnyDistanceFunction> _kStandardDistanceFunctions = <Type, AnyDistanceFunction>{
  Color: _maxComponentColorDistance,
  HSVColor: _maxComponentHSVColorDistance,
  HSLColor: _maxComponentHSLColorDistance,
  Offset: _offsetDistance,
  int: _intDistance,
  double: _doubleDistance,
  Rect: _rectDistance,
  Size: _sizeDistance,
};

int _intDistance(final int a, final int b) => (b - a).abs();
double _doubleDistance(final double a, final double b) => (b - a).abs();
double _offsetDistance(final Offset a, final Offset b) => (b - a).distance;

double _maxComponentColorDistance(final Color a, final Color b) {
  int delta = math.max<int>((a.red - b.red).abs(), (a.green - b.green).abs());
  delta = math.max<int>(delta, (a.blue - b.blue).abs());
  delta = math.max<int>(delta, (a.alpha - b.alpha).abs());
  return delta.toDouble();
}

// Compares hue by converting it to a 0.0 - 1.0 range, so that the comparison
// can be a similar error percentage per component.
double _maxComponentHSVColorDistance(final HSVColor a, final HSVColor b) {
  double delta = math.max<double>((a.saturation - b.saturation).abs(), (a.value - b.value).abs());
  delta = math.max<double>(delta, ((a.hue - b.hue) / 360.0).abs());
  return math.max<double>(delta, (a.alpha - b.alpha).abs());
}

// Compares hue by converting it to a 0.0 - 1.0 range, so that the comparison
// can be a similar error percentage per component.
double _maxComponentHSLColorDistance(final HSLColor a, final HSLColor b) {
  double delta = math.max<double>((a.saturation - b.saturation).abs(), (a.lightness - b.lightness).abs());
  delta = math.max<double>(delta, ((a.hue - b.hue) / 360.0).abs());
  return math.max<double>(delta, (a.alpha - b.alpha).abs());
}

double _rectDistance(final Rect a, final Rect b) {
  double delta = math.max<double>((a.left - b.left).abs(), (a.top - b.top).abs());
  delta = math.max<double>(delta, (a.right - b.right).abs());
  delta = math.max<double>(delta, (a.bottom - b.bottom).abs());
  return delta;
}

double _matrixDistance(final Matrix4 a, final Matrix4 b) {
  double delta = 0.0;
  for (int i = 0; i < 16; i += 1) {
    delta = math.max<double>((a[i] - b[i]).abs(), delta);
  }
  return delta;
}

double _sizeDistance(final Size a, final Size b) {
  // TODO(a14n): remove ignore when lint is updated, https://github.com/dart-lang/linter/issues/1843
  // ignore: unnecessary_parenthesis
  final Offset delta = (b - a) as Offset;
  return delta.distance;
}

/// Asserts that two values are within a certain distance from each other.
///
/// The distance is computed by a [DistanceFunction].
///
/// If `distanceFunction` is null, a standard distance function is used for the
/// `T` generic argument. Standard functions are defined for the following
/// types:
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
///  * [rectMoreOrLessEquals], which is similar to this function, but
///    specializes in [Rect]s and has an optional `epsilon` parameter.
///  * [closeTo], which specializes in numbers only.
Matcher within<T>({
  required final num distance,
  required final T from,
  DistanceFunction<T>? distanceFunction,
}) {
  distanceFunction ??= _kStandardDistanceFunctions[T] as DistanceFunction<T>?;

  if (distanceFunction == null) {
    throw ArgumentError(
      'The specified distanceFunction was null, and a standard distance '
      'function was not found for type ${from.runtimeType} of the provided '
      '`from` argument.'
    );
  }

  return _IsWithinDistance<T>(distanceFunction, from, distance);
}

class _IsWithinDistance<T> extends Matcher {
  const _IsWithinDistance(this.distanceFunction, this.value, this.epsilon);

  final DistanceFunction<T> distanceFunction;
  final T value;
  final num epsilon;

  @override
  bool matches(final dynamic object, final Map<dynamic, dynamic> matchState) {
    if (object is! T) {
      return false;
    }
    if (object == value) {
      return true;
    }
    final num distance = distanceFunction(object, value);
    if (distance < 0) {
      throw ArgumentError(
        'Invalid distance function was used to compare a ${value.runtimeType} '
        'to a ${object.runtimeType}. The function must return a non-negative '
        'double value, but it returned $distance.'
      );
    }
    matchState['distance'] = distance;
    return distance <= epsilon;
  }

  @override
  Description describe(final Description description) => description.add('$value (±$epsilon)');

  @override
  Description describeMismatch(
    final dynamic object,
    final Description mismatchDescription,
    final Map<dynamic, dynamic> matchState,
    final bool verbose,
  ) {
    mismatchDescription.add('was ${matchState['distance']} away from the desired value.');
    return mismatchDescription;
  }
}

class _MoreOrLessEquals extends Matcher {
  const _MoreOrLessEquals(this.value, this.epsilon)
    : assert(epsilon >= 0);

  final double value;
  final double epsilon;

  @override
  bool matches(final dynamic object, final Map<dynamic, dynamic> matchState) {
    if (object is! double) {
      return false;
    }
    if (object == value) {
      return true;
    }
    return (object - value).abs() <= epsilon;
  }

  @override
  Description describe(final Description description) => description.add('$value (±$epsilon)');

  @override
  Description describeMismatch(final dynamic item, final Description mismatchDescription, final Map<dynamic, dynamic> matchState, final bool verbose) {
    return super.describeMismatch(item, mismatchDescription, matchState, verbose)
      ..add('$item is not in the range of $value (±$epsilon).');
  }
}

class _IsMethodCall extends Matcher {
  const _IsMethodCall(this.name, this.arguments);

  final String name;
  final dynamic arguments;

  @override
  bool matches(final dynamic item, final Map<dynamic, dynamic> matchState) {
    if (item is! MethodCall) {
      return false;
    }
    if (item.method != name) {
      return false;
    }
    return _deepEquals(item.arguments, arguments);
  }

  bool _deepEquals(final dynamic a, final dynamic b) {
    if (a == b) {
      return true;
    }
    if (a is List) {
      return b is List && _deepEqualsList(a, b);
    }
    if (a is Map) {
      return b is Map && _deepEqualsMap(a, b);
    }
    return false;
  }

  bool _deepEqualsList(final List<dynamic> a, final List<dynamic> b) {
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (!_deepEquals(a[i], b[i])) {
        return false;
      }
    }
    return true;
  }

  bool _deepEqualsMap(final Map<dynamic, dynamic> a, final Map<dynamic, dynamic> b) {
    if (a.length != b.length) {
      return false;
    }
    for (final dynamic key in a.keys) {
      if (!b.containsKey(key) || !_deepEquals(a[key], b[key])) {
        return false;
      }
    }
    return true;
  }

  @override
  Description describe(final Description description) {
    return description
        .add('has method name: ').addDescriptionOf(name)
        .add(' with arguments: ').addDescriptionOf(arguments);
  }
}

/// Asserts that a [Finder] locates a single object whose root RenderObject
/// is a [RenderClipRect] with no clipper set, or an equivalent
/// [RenderClipPath].
const Matcher clipsWithBoundingRect = _ClipsWithBoundingRect();

/// Asserts that a [Finder] locates a single object whose root RenderObject is
/// not a [RenderClipRect], [RenderClipRRect], [RenderClipOval], or
/// [RenderClipPath].
const Matcher hasNoImmediateClip = _MatchAnythingExceptClip();

/// Asserts that a [Finder] locates a single object whose root RenderObject
/// is a [RenderClipRRect] with no clipper set, and border radius equals to
/// [borderRadius], or an equivalent [RenderClipPath].
Matcher clipsWithBoundingRRect({ required final BorderRadius borderRadius }) {
  return _ClipsWithBoundingRRect(borderRadius: borderRadius);
}

/// Asserts that a [Finder] locates a single object whose root RenderObject
/// is a [RenderClipPath] with a [ShapeBorderClipper] that clips to
/// [shape].
Matcher clipsWithShapeBorder({ required final ShapeBorder shape }) {
  return _ClipsWithShapeBorder(shape: shape);
}

/// Asserts that a [Finder] locates a single object whose root RenderObject
/// is a [RenderPhysicalModel] or a [RenderPhysicalShape].
///
/// - If the render object is a [RenderPhysicalModel]
///    - If [shape] is non null asserts that [RenderPhysicalModel.shape] is equal to
///   [shape].
///    - If [borderRadius] is non null asserts that [RenderPhysicalModel.borderRadius] is equal to
///   [borderRadius].
///     - If [elevation] is non null asserts that [RenderPhysicalModel.elevation] is equal to
///   [elevation].
/// - If the render object is a [RenderPhysicalShape]
///    - If [borderRadius] is non null asserts that the shape is a rounded
///   rectangle with this radius.
///    - If [borderRadius] is null, asserts that the shape is equivalent to
///   [shape].
///    - If [elevation] is non null asserts that [RenderPhysicalModel.elevation] is equal to
///   [elevation].
Matcher rendersOnPhysicalModel({
  final BoxShape? shape,
  final BorderRadius? borderRadius,
  final double? elevation,
}) {
  return _RendersOnPhysicalModel(
    shape: shape,
    borderRadius: borderRadius,
    elevation: elevation,
  );
}

/// Asserts that a [Finder] locates a single object whose root RenderObject
/// is [RenderPhysicalShape] that uses a [ShapeBorderClipper] that clips to
/// [shape] as its clipper.
/// If [elevation] is non null asserts that [RenderPhysicalShape.elevation] is
/// equal to [elevation].
Matcher rendersOnPhysicalShape({
  required final ShapeBorder shape,
  final double? elevation,
}) {
  return _RendersOnPhysicalShape(
    shape: shape,
    elevation: elevation,
  );
}

abstract class _FailWithDescriptionMatcher extends Matcher {
  const _FailWithDescriptionMatcher();

  bool failWithDescription(final Map<dynamic, dynamic> matchState, final String description) {
    matchState['failure'] = description;
    return false;
  }

  @override
  Description describeMismatch(
    final dynamic item,
    final Description mismatchDescription,
    final Map<dynamic, dynamic> matchState,
    final bool verbose,
  ) {
    return mismatchDescription.add(matchState['failure'] as String);
  }
}

class _MatchAnythingExceptClip extends _FailWithDescriptionMatcher {
  const _MatchAnythingExceptClip();

  @override
  bool matches(covariant final Finder finder, final Map<dynamic, dynamic> matchState) {
    final Iterable<Element> nodes = finder.evaluate();
    if (nodes.length != 1) {
      return failWithDescription(matchState, 'did not have a exactly one child element');
    }
    final RenderObject renderObject = nodes.single.renderObject!;

    switch (renderObject.runtimeType) {
      case RenderClipPath:
      case RenderClipOval:
      case RenderClipRect:
      case RenderClipRRect:
        return failWithDescription(matchState, 'had a root render object of type: ${renderObject.runtimeType}');
      default:
        return true;
    }
  }

  @override
  Description describe(final Description description) {
    return description.add('does not have a clip as an immediate child');
  }
}

abstract class _MatchRenderObject<M extends RenderObject, T extends RenderObject> extends _FailWithDescriptionMatcher {
  const _MatchRenderObject();

  bool renderObjectMatchesT(final Map<dynamic, dynamic> matchState, final T renderObject);
  bool renderObjectMatchesM(final Map<dynamic, dynamic> matchState, final M renderObject);

  @override
  bool matches(covariant final Finder finder, final Map<dynamic, dynamic> matchState) {
    final Iterable<Element> nodes = finder.evaluate();
    if (nodes.length != 1) {
      return failWithDescription(matchState, 'did not have a exactly one child element');
    }
    final RenderObject renderObject = nodes.single.renderObject!;

    if (renderObject.runtimeType == T) {
      return renderObjectMatchesT(matchState, renderObject as T);
    }

    if (renderObject.runtimeType == M) {
      return renderObjectMatchesM(matchState, renderObject as M);
    }

    return failWithDescription(matchState, 'had a root render object of type: ${renderObject.runtimeType}');
  }
}

class _RendersOnPhysicalModel extends _MatchRenderObject<RenderPhysicalShape, RenderPhysicalModel> {
  const _RendersOnPhysicalModel({
    this.shape,
    this.borderRadius,
    this.elevation,
  });

  final BoxShape? shape;
  final BorderRadius? borderRadius;
  final double? elevation;

  @override
  bool renderObjectMatchesT(final Map<dynamic, dynamic> matchState, final RenderPhysicalModel renderObject) {
    if (shape != null && renderObject.shape != shape) {
      return failWithDescription(matchState, 'had shape: ${renderObject.shape}');
    }

    if (borderRadius != null && renderObject.borderRadius != borderRadius) {
      return failWithDescription(matchState, 'had borderRadius: ${renderObject.borderRadius}');
    }

    if (elevation != null && renderObject.elevation != elevation) {
      return failWithDescription(matchState, 'had elevation: ${renderObject.elevation}');
    }

    return true;
  }

  @override
  bool renderObjectMatchesM(final Map<dynamic, dynamic> matchState, final RenderPhysicalShape renderObject) {
    if (renderObject.clipper.runtimeType != ShapeBorderClipper) {
      return failWithDescription(matchState, 'clipper was: ${renderObject.clipper}');
    }
    final ShapeBorderClipper shapeClipper = renderObject.clipper! as ShapeBorderClipper;

    if (borderRadius != null && !assertRoundedRectangle(shapeClipper, borderRadius!, matchState)) {
      return false;
    }

    if (borderRadius == null &&
      shape == BoxShape.rectangle &&
      !assertRoundedRectangle(shapeClipper, BorderRadius.zero, matchState)) {
      return false;
    }

    if (borderRadius == null &&
      shape == BoxShape.circle &&
      !assertCircle(shapeClipper, matchState)) {
      return false;
    }

    if (elevation != null && renderObject.elevation != elevation) {
      return failWithDescription(matchState, 'had elevation: ${renderObject.elevation}');
    }

    return true;
  }

  bool assertRoundedRectangle(final ShapeBorderClipper shapeClipper, final BorderRadius borderRadius, final Map<dynamic, dynamic> matchState) {
    if (shapeClipper.shape.runtimeType != RoundedRectangleBorder) {
      return failWithDescription(matchState, 'had shape border: ${shapeClipper.shape}');
    }
    final RoundedRectangleBorder border = shapeClipper.shape as RoundedRectangleBorder;
    if (border.borderRadius != borderRadius) {
      return failWithDescription(matchState, 'had borderRadius: ${border.borderRadius}');
    }
    return true;
  }

  bool assertCircle(final ShapeBorderClipper shapeClipper, final Map<dynamic, dynamic> matchState) {
    if (shapeClipper.shape.runtimeType != CircleBorder) {
      return failWithDescription(matchState, 'had shape border: ${shapeClipper.shape}');
    }
    return true;
  }

  @override
  Description describe(final Description description) {
    description.add('renders on a physical model');
    if (shape != null) {
      description.add(' with shape $shape');
    }
    if (borderRadius != null) {
      description.add(' with borderRadius $borderRadius');
    }
    if (elevation != null) {
      description.add(' with elevation $elevation');
    }
    return description;
  }
}

class _RendersOnPhysicalShape extends _MatchRenderObject<RenderPhysicalShape, RenderPhysicalModel> {
  const _RendersOnPhysicalShape({
    required this.shape,
    this.elevation,
  });

  final ShapeBorder shape;
  final double? elevation;

  @override
  bool renderObjectMatchesM(final Map<dynamic, dynamic> matchState, final RenderPhysicalShape renderObject) {
    if (renderObject.clipper.runtimeType != ShapeBorderClipper) {
      return failWithDescription(matchState, 'clipper was: ${renderObject.clipper}');
    }
    final ShapeBorderClipper shapeClipper = renderObject.clipper! as ShapeBorderClipper;

    if (shapeClipper.shape != shape) {
      return failWithDescription(matchState, 'shape was: ${shapeClipper.shape}');
    }

    if (elevation != null && renderObject.elevation != elevation) {
      return failWithDescription(matchState, 'had elevation: ${renderObject.elevation}');
    }

    return true;
  }

  @override
  bool renderObjectMatchesT(final Map<dynamic, dynamic> matchState, final RenderPhysicalModel renderObject) {
    return false;
  }

  @override
  Description describe(final Description description) {
    description.add('renders on a physical model with shape $shape');
    if (elevation != null) {
      description.add(' with elevation $elevation');
    }
    return description;
  }
}

class _ClipsWithBoundingRect extends _MatchRenderObject<RenderClipPath, RenderClipRect> {
  const _ClipsWithBoundingRect();

  @override
  bool renderObjectMatchesT(final Map<dynamic, dynamic> matchState, final RenderClipRect renderObject) {
    if (renderObject.clipper != null) {
      return failWithDescription(matchState, 'had a non null clipper ${renderObject.clipper}');
    }
    return true;
  }

  @override
  bool renderObjectMatchesM(final Map<dynamic, dynamic> matchState, final RenderClipPath renderObject) {
    if (renderObject.clipper.runtimeType != ShapeBorderClipper) {
      return failWithDescription(matchState, 'clipper was: ${renderObject.clipper}');
    }
    final ShapeBorderClipper shapeClipper = renderObject.clipper! as ShapeBorderClipper;
    if (shapeClipper.shape.runtimeType != RoundedRectangleBorder) {
      return failWithDescription(matchState, 'shape was: ${shapeClipper.shape}');
    }
    final RoundedRectangleBorder border = shapeClipper.shape as RoundedRectangleBorder;
    if (border.borderRadius != BorderRadius.zero) {
      return failWithDescription(matchState, 'borderRadius was: ${border.borderRadius}');
    }
    return true;
  }

  @override
  Description describe(final Description description) =>
    description.add('clips with bounding rectangle');
}

class _ClipsWithBoundingRRect extends _MatchRenderObject<RenderClipPath, RenderClipRRect> {
  const _ClipsWithBoundingRRect({required this.borderRadius});

  final BorderRadius borderRadius;


  @override
  bool renderObjectMatchesT(final Map<dynamic, dynamic> matchState, final RenderClipRRect renderObject) {
    if (renderObject.clipper != null) {
      return failWithDescription(matchState, 'had a non null clipper ${renderObject.clipper}');
    }

    if (renderObject.borderRadius != borderRadius) {
      return failWithDescription(matchState, 'had borderRadius: ${renderObject.borderRadius}');
    }

    return true;
  }

  @override
  bool renderObjectMatchesM(final Map<dynamic, dynamic> matchState, final RenderClipPath renderObject) {
    if (renderObject.clipper.runtimeType != ShapeBorderClipper) {
      return failWithDescription(matchState, 'clipper was: ${renderObject.clipper}');
    }
    final ShapeBorderClipper shapeClipper = renderObject.clipper! as ShapeBorderClipper;
    if (shapeClipper.shape.runtimeType != RoundedRectangleBorder) {
      return failWithDescription(matchState, 'shape was: ${shapeClipper.shape}');
    }
    final RoundedRectangleBorder border = shapeClipper.shape as RoundedRectangleBorder;
    if (border.borderRadius != borderRadius) {
      return failWithDescription(matchState, 'had borderRadius: ${border.borderRadius}');
    }
    return true;
  }

  @override
  Description describe(final Description description) =>
    description.add('clips with bounding rounded rectangle with borderRadius: $borderRadius');
}

class _ClipsWithShapeBorder extends _MatchRenderObject<RenderClipPath, RenderClipRRect> {
  const _ClipsWithShapeBorder({required this.shape});

  final ShapeBorder shape;

  @override
  bool renderObjectMatchesM(final Map<dynamic, dynamic> matchState, final RenderClipPath renderObject) {
    if (renderObject.clipper.runtimeType != ShapeBorderClipper) {
      return failWithDescription(matchState, 'clipper was: ${renderObject.clipper}');
    }
    final ShapeBorderClipper shapeClipper = renderObject.clipper! as ShapeBorderClipper;
    if (shapeClipper.shape != shape) {
      return failWithDescription(matchState, 'shape was: ${shapeClipper.shape}');
    }
    return true;
  }

  @override
  bool renderObjectMatchesT(final Map<dynamic, dynamic> matchState, final RenderClipRRect renderObject) {
    return false;
  }


  @override
  Description describe(final Description description) =>
    description.add('clips with shape: $shape');
}

class _CoversSameAreaAs extends Matcher {
  _CoversSameAreaAs(
    this.expectedPath, {
    required this.areaToCompare,
    this.sampleSize = 20,
  }) : maxHorizontalNoise = areaToCompare.width / sampleSize,
       maxVerticalNoise = areaToCompare.height / sampleSize {
    // Use a fixed random seed to make sure tests are deterministic.
    random = math.Random(1);
  }

  final Path expectedPath;
  final Rect areaToCompare;
  final int sampleSize;
  final double maxHorizontalNoise;
  final double maxVerticalNoise;
  late math.Random random;

  @override
  bool matches(covariant final Path actualPath, final Map<dynamic, dynamic> matchState) {
    for (int i = 0; i < sampleSize; i += 1) {
      for (int j = 0; j < sampleSize; j += 1) {
        final Offset offset = Offset(
          i * (areaToCompare.width / sampleSize),
          j * (areaToCompare.height / sampleSize),
        );

        if (!_samplePoint(matchState, actualPath, offset)) {
          return false;
        }

        final Offset noise = Offset(
          maxHorizontalNoise * random.nextDouble(),
          maxVerticalNoise * random.nextDouble(),
        );

        if (!_samplePoint(matchState, actualPath, offset + noise)) {
          return false;
        }
      }
    }
    return true;
  }

  bool _samplePoint(final Map<dynamic, dynamic> matchState, final Path actualPath, final Offset offset) {
    if (expectedPath.contains(offset) == actualPath.contains(offset)) {
      return true;
    }

    if (actualPath.contains(offset)) {
      return failWithDescription(matchState, '$offset is contained in the actual path but not in the expected path');
    } else {
      return failWithDescription(matchState, '$offset is contained in the expected path but not in the actual path');
    }
  }

  bool failWithDescription(final Map<dynamic, dynamic> matchState, final String description) {
    matchState['failure'] = description;
    return false;
  }

  @override
  Description describeMismatch(
    final dynamic item,
    final Description mismatchDescription,
    final Map<dynamic, dynamic> matchState,
    final bool verbose,
  ) {
    return mismatchDescription.add(matchState['failure'] as String);
  }

  @override
  Description describe(final Description description) =>
    description.add('covers expected area and only expected area');
}

class _ColorMatcher extends Matcher {
  const _ColorMatcher({
    required this.targetColor,
  });

  final Color targetColor;

  @override
  bool matches(final dynamic item, final Map<dynamic, dynamic> matchState) {
    if (item is Color) {
      return item == targetColor || item.value == targetColor.value;
    }
    return false;
  }

  @override
  Description describe(final Description description) => description.add('matches color $targetColor');
}

int _countDifferentPixels(final Uint8List imageA, final Uint8List imageB) {
  assert(imageA.length == imageB.length);
  int delta = 0;
  for (int i = 0; i < imageA.length; i+=4) {
    if (imageA[i] != imageB[i] ||
        imageA[i + 1] != imageB[i + 1] ||
        imageA[i + 2] != imageB[i + 2] ||
        imageA[i + 3] != imageB[i + 3]) {
      delta++;
    }
  }
  return delta;
}

class _MatchesReferenceImage extends AsyncMatcher {
  const _MatchesReferenceImage(this.referenceImage);

  final ui.Image referenceImage;

  @override
  Future<String?> matchAsync(final dynamic item) async {
    Future<ui.Image> imageFuture;
    if (item is Future<ui.Image>) {
      imageFuture = item;
    } else if (item is ui.Image) {
      imageFuture = Future<ui.Image>.value(item);
    } else {
      final Finder finder = item as Finder;
      final Iterable<Element> elements = finder.evaluate();
      if (elements.isEmpty) {
        return 'could not be rendered because no widget was found';
      } else if (elements.length > 1) {
        return 'matched too many widgets';
      }
      imageFuture = captureImage(elements.single);
    }

    final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.instance;
    return binding.runAsync<String?>(() async {
      final ui.Image image = await imageFuture;
      final ByteData? bytes = await image.toByteData();
      if (bytes == null) {
        return 'could not be encoded.';
      }

      final ByteData? referenceBytes = await referenceImage.toByteData();
      if (referenceBytes == null) {
        return 'could not have its reference image encoded.';
      }

      if (referenceImage.height != image.height || referenceImage.width != image.width) {
        return 'does not match as width or height do not match. $image != $referenceImage';
      }

      final int countDifferentPixels = _countDifferentPixels(
        Uint8List.view(bytes.buffer),
        Uint8List.view(referenceBytes.buffer),
      );
      return countDifferentPixels == 0 ? null : 'does not match on $countDifferentPixels pixels';
    }, additionalTime: const Duration(minutes: 1));
  }

  @override
  Description describe(final Description description) {
    return description.add('rasterized image matches that of a $referenceImage reference image');
  }
}

class _MatchesSemanticsData extends Matcher {
  _MatchesSemanticsData({
    required this.label,
    required this.attributedLabel,
    required this.hint,
    required this.attributedHint,
    required this.value,
    required this.attributedValue,
    required this.increasedValue,
    required this.attributedIncreasedValue,
    required this.decreasedValue,
    required this.attributedDecreasedValue,
    required this.tooltip,
    required this.textDirection,
    required this.rect,
    required this.size,
    required this.elevation,
    required this.thickness,
    required this.platformViewId,
    required this.maxValueLength,
    required this.currentValueLength,
    // Flags
    required final bool? hasCheckedState,
    required final bool? isChecked,
    required final bool? isCheckStateMixed,
    required final bool? isSelected,
    required final bool? isButton,
    required final bool? isSlider,
    required final bool? isKeyboardKey,
    required final bool? isLink,
    required final bool? isFocused,
    required final bool? isFocusable,
    required final bool? isTextField,
    required final bool? isReadOnly,
    required final bool? hasEnabledState,
    required final bool? isEnabled,
    required final bool? isInMutuallyExclusiveGroup,
    required final bool? isHeader,
    required final bool? isObscured,
    required final bool? isMultiline,
    required final bool? namesRoute,
    required final bool? scopesRoute,
    required final bool? isHidden,
    required final bool? isImage,
    required final bool? isLiveRegion,
    required final bool? hasToggledState,
    required final bool? isToggled,
    required final bool? hasImplicitScrolling,
    // Actions
    required final bool? hasTapAction,
    required final bool? hasLongPressAction,
    required final bool? hasScrollLeftAction,
    required final bool? hasScrollRightAction,
    required final bool? hasScrollUpAction,
    required final bool? hasScrollDownAction,
    required final bool? hasIncreaseAction,
    required final bool? hasDecreaseAction,
    required final bool? hasShowOnScreenAction,
    required final bool? hasMoveCursorForwardByCharacterAction,
    required final bool? hasMoveCursorBackwardByCharacterAction,
    required final bool? hasMoveCursorForwardByWordAction,
    required final bool? hasMoveCursorBackwardByWordAction,
    required final bool? hasSetTextAction,
    required final bool? hasSetSelectionAction,
    required final bool? hasCopyAction,
    required final bool? hasCutAction,
    required final bool? hasPasteAction,
    required final bool? hasDidGainAccessibilityFocusAction,
    required final bool? hasDidLoseAccessibilityFocusAction,
    required final bool? hasDismissAction,
    // Custom actions and overrides
    required final String? onTapHint,
    required final String? onLongPressHint,
    required this.customActions,
    required this.children,
  })  : flags = <SemanticsFlag, bool>{
          if (hasCheckedState != null) SemanticsFlag.hasCheckedState: hasCheckedState,
          if (isChecked != null) SemanticsFlag.isChecked: isChecked,
          if (isCheckStateMixed != null) SemanticsFlag.isCheckStateMixed: isCheckStateMixed,
          if (isSelected != null) SemanticsFlag.isSelected: isSelected,
          if (isButton != null) SemanticsFlag.isButton: isButton,
          if (isSlider != null) SemanticsFlag.isSlider: isSlider,
          if (isKeyboardKey != null) SemanticsFlag.isKeyboardKey: isKeyboardKey,
          if (isLink != null) SemanticsFlag.isLink: isLink,
          if (isTextField != null) SemanticsFlag.isTextField: isTextField,
          if (isReadOnly != null) SemanticsFlag.isReadOnly: isReadOnly,
          if (isFocused != null) SemanticsFlag.isFocused: isFocused,
          if (isFocusable != null) SemanticsFlag.isFocusable: isFocusable,
          if (hasEnabledState != null) SemanticsFlag.hasEnabledState: hasEnabledState,
          if (isEnabled != null) SemanticsFlag.isEnabled: isEnabled,
          if (isInMutuallyExclusiveGroup != null) SemanticsFlag.isInMutuallyExclusiveGroup: isInMutuallyExclusiveGroup,
          if (isHeader != null) SemanticsFlag.isHeader: isHeader,
          if (isObscured != null) SemanticsFlag.isObscured: isObscured,
          if (isMultiline != null) SemanticsFlag.isMultiline: isMultiline,
          if (namesRoute != null) SemanticsFlag.namesRoute: namesRoute,
          if (scopesRoute != null) SemanticsFlag.scopesRoute: scopesRoute,
          if (isHidden != null) SemanticsFlag.isHidden: isHidden,
          if (isImage != null) SemanticsFlag.isImage: isImage,
          if (isLiveRegion != null) SemanticsFlag.isLiveRegion: isLiveRegion,
          if (hasToggledState != null) SemanticsFlag.hasToggledState: hasToggledState,
          if (isToggled != null) SemanticsFlag.isToggled: isToggled,
          if (hasImplicitScrolling != null) SemanticsFlag.hasImplicitScrolling: hasImplicitScrolling,
          if (isSlider != null) SemanticsFlag.isSlider: isSlider,
        },
        actions = <SemanticsAction, bool>{
          if (hasTapAction != null) SemanticsAction.tap: hasTapAction,
          if (hasLongPressAction != null) SemanticsAction.longPress: hasLongPressAction,
          if (hasScrollLeftAction != null) SemanticsAction.scrollLeft: hasScrollLeftAction,
          if (hasScrollRightAction != null) SemanticsAction.scrollRight: hasScrollRightAction,
          if (hasScrollUpAction != null) SemanticsAction.scrollUp: hasScrollUpAction,
          if (hasScrollDownAction != null) SemanticsAction.scrollDown: hasScrollDownAction,
          if (hasIncreaseAction != null) SemanticsAction.increase: hasIncreaseAction,
          if (hasDecreaseAction != null) SemanticsAction.decrease: hasDecreaseAction,
          if (hasShowOnScreenAction != null) SemanticsAction.showOnScreen: hasShowOnScreenAction,
          if (hasMoveCursorForwardByCharacterAction != null) SemanticsAction.moveCursorForwardByCharacter: hasMoveCursorForwardByCharacterAction,
          if (hasMoveCursorBackwardByCharacterAction != null) SemanticsAction.moveCursorBackwardByCharacter: hasMoveCursorBackwardByCharacterAction,
          if (hasSetSelectionAction != null) SemanticsAction.setSelection: hasSetSelectionAction,
          if (hasCopyAction != null) SemanticsAction.copy: hasCopyAction,
          if (hasCutAction != null) SemanticsAction.cut: hasCutAction,
          if (hasPasteAction != null) SemanticsAction.paste: hasPasteAction,
          if (hasDidGainAccessibilityFocusAction != null) SemanticsAction.didGainAccessibilityFocus: hasDidGainAccessibilityFocusAction,
          if (hasDidLoseAccessibilityFocusAction != null) SemanticsAction.didLoseAccessibilityFocus: hasDidLoseAccessibilityFocusAction,
          if (customActions != null) SemanticsAction.customAction: customActions.isNotEmpty,
          if (hasDismissAction != null) SemanticsAction.dismiss: hasDismissAction,
          if (hasMoveCursorForwardByWordAction != null) SemanticsAction.moveCursorForwardByWord: hasMoveCursorForwardByWordAction,
          if (hasMoveCursorBackwardByWordAction != null) SemanticsAction.moveCursorBackwardByWord: hasMoveCursorBackwardByWordAction,
          if (hasSetTextAction != null) SemanticsAction.setText: hasSetTextAction,
        },
        hintOverrides = onTapHint == null && onLongPressHint == null
            ? null
            : SemanticsHintOverrides(
                onTapHint: onTapHint,
                onLongPressHint: onLongPressHint,
              );

  final String? label;
  final AttributedString? attributedLabel;
  final String? hint;
  final AttributedString? attributedHint;
  final String? value;
  final AttributedString? attributedValue;
  final String? increasedValue;
  final AttributedString? attributedIncreasedValue;
  final String? decreasedValue;
  final AttributedString? attributedDecreasedValue;
  final String? tooltip;
  final SemanticsHintOverrides? hintOverrides;
  final List<CustomSemanticsAction>? customActions;
  final TextDirection? textDirection;
  final Rect? rect;
  final Size? size;
  final double? elevation;
  final double? thickness;
  final int? platformViewId;
  final int? maxValueLength;
  final int? currentValueLength;
  final List<Matcher>? children;

  /// There are three possible states for these two maps:
  ///
  ///  1. If the flag/action maps to `true`, then it must be present in the SemanticData
  ///  2. If the flag/action maps to `false`, then it must not be present in the SemanticData
  ///  3. If the flag/action is not in the map, then it will not be validated against
  final Map<SemanticsAction, bool> actions;
  final Map<SemanticsFlag, bool> flags;

  @override
  Description describe(final Description description) {
    description.add('has semantics');
    if (label != null) {
      description.add(' with label: $label');
    }
    if (attributedLabel != null) {
      description.add(' with attributedLabel: $attributedLabel');
    }
    if (value != null) {
      description.add(' with value: $value');
    }
    if (attributedValue != null) {
      description.add(' with attributedValue: $attributedValue');
    }
    if (hint != null) {
      description.add(' with hint: $hint');
    }
    if (attributedHint != null) {
      description.add(' with attributedHint: $attributedHint');
    }
    if (increasedValue != null) {
      description.add(' with increasedValue: $increasedValue ');
    }
    if (attributedIncreasedValue != null) {
      description.add(' with attributedIncreasedValue: $attributedIncreasedValue');
    }
    if (decreasedValue != null) {
      description.add(' with decreasedValue: $decreasedValue ');
    }
    if (attributedDecreasedValue != null) {
      description.add(' with attributedDecreasedValue: $attributedDecreasedValue');
    }
    if (tooltip != null) {
      description.add(' with tooltip: $tooltip');
    }
    if (actions.isNotEmpty) {
      final List<SemanticsAction> expectedActions = actions.entries
        .where((final MapEntry<ui.SemanticsAction, bool> e) => e.value)
        .map((final MapEntry<ui.SemanticsAction, bool> e) => e.key)
        .toList();
      final List<SemanticsAction> notExpectedActions = actions.entries
        .where((final MapEntry<ui.SemanticsAction, bool> e) => !e.value)
        .map((final MapEntry<ui.SemanticsAction, bool> e) => e.key)
        .toList();

      if (expectedActions.isNotEmpty) {
        description.add(' with actions: ${_createEnumsSummary(expectedActions)} ');
      }
      if (notExpectedActions.isNotEmpty) {
        description.add(' without actions: ${_createEnumsSummary(notExpectedActions)} ');
      }
    }
    if (flags.isNotEmpty) {
      final List<SemanticsFlag> expectedFlags = flags.entries
        .where((final MapEntry<ui.SemanticsFlag, bool> e) => e.value)
        .map((final MapEntry<ui.SemanticsFlag, bool> e) => e.key)
        .toList();
      final List<SemanticsFlag> notExpectedFlags = flags.entries
        .where((final MapEntry<ui.SemanticsFlag, bool> e) => !e.value)
        .map((final MapEntry<ui.SemanticsFlag, bool> e) => e.key)
        .toList();

      if (expectedFlags.isNotEmpty) {
        description.add(' with flags: ${_createEnumsSummary(expectedFlags)} ');
      }
      if (notExpectedFlags.isNotEmpty) {
        description.add(' without flags: ${_createEnumsSummary(notExpectedFlags)} ');
      }
    }
    if (textDirection != null) {
      description.add(' with textDirection: $textDirection ');
    }
    if (rect != null) {
      description.add(' with rect: $rect');
    }
    if (size != null) {
      description.add(' with size: $size');
    }
    if (elevation != null) {
      description.add(' with elevation: $elevation');
    }
    if (thickness != null) {
      description.add(' with thickness: $thickness');
    }
    if (platformViewId != null) {
      description.add(' with platformViewId: $platformViewId');
    }
    if (maxValueLength != null) {
      description.add(' with maxValueLength: $maxValueLength');
    }
    if (currentValueLength != null) {
      description.add(' with currentValueLength: $currentValueLength');
    }
    if (customActions != null) {
      description.add(' with custom actions: $customActions');
    }
    if (hintOverrides != null) {
      description.add(' with custom hints: $hintOverrides');
    }
    if (children != null) {
      description.add(' with children:\n');
      for (final _MatchesSemanticsData child in children!.cast<_MatchesSemanticsData>()) {
        child.describe(description);
      }
    }
    return description;
  }

  bool _stringAttributesEqual(final List<StringAttribute> first, final List<StringAttribute> second) {
    if (first.length != second.length) {
      return false;
    }
    for (int i = 0; i < first.length; i++) {
      if (first[i] is SpellOutStringAttribute &&
          (second[i] is! SpellOutStringAttribute ||
           second[i].range != first[i].range)) {
        return false;
      }
      if (first[i] is LocaleStringAttribute &&
          (second[i] is! LocaleStringAttribute ||
           second[i].range != first[i].range ||
           (second[i] as LocaleStringAttribute).locale != (second[i] as LocaleStringAttribute).locale)) {
        return false;
      }
    }
    return true;
  }

  @override
  bool matches(final dynamic node, final Map<dynamic, dynamic> matchState) {
    if (node == null) {
      return failWithDescription(matchState, 'No SemanticsData provided. '
        'Maybe you forgot to enable semantics?');
    }
    final SemanticsData data = node is SemanticsNode ? node.getSemanticsData() : (node as SemanticsData);
    if (label != null && label != data.label) {
      return failWithDescription(matchState, 'label was: ${data.label}');
    }
    if (attributedLabel != null &&
        (attributedLabel!.string != data.attributedLabel.string ||
         !_stringAttributesEqual(attributedLabel!.attributes, data.attributedLabel.attributes))) {
      return failWithDescription(
          matchState, 'attributedLabel was: ${data.attributedLabel}');
    }
    if (hint != null && hint != data.hint) {
      return failWithDescription(matchState, 'hint was: ${data.hint}');
    }
    if (attributedHint != null &&
        (attributedHint!.string != data.attributedHint.string ||
         !_stringAttributesEqual(attributedHint!.attributes, data.attributedHint.attributes))) {
      return failWithDescription(
          matchState, 'attributedHint was: ${data.attributedHint}');
    }
    if (value != null && value != data.value) {
      return failWithDescription(matchState, 'value was: ${data.value}');
    }
    if (attributedValue != null &&
        (attributedValue!.string != data.attributedValue.string ||
         !_stringAttributesEqual(attributedValue!.attributes, data.attributedValue.attributes))) {
      return failWithDescription(
          matchState, 'attributedValue was: ${data.attributedValue}');
    }
    if (increasedValue != null && increasedValue != data.increasedValue) {
      return failWithDescription(matchState, 'increasedValue was: ${data.increasedValue}');
    }
    if (attributedIncreasedValue != null &&
        (attributedIncreasedValue!.string != data.attributedIncreasedValue.string ||
         !_stringAttributesEqual(attributedIncreasedValue!.attributes, data.attributedIncreasedValue.attributes))) {
      return failWithDescription(
          matchState, 'attributedIncreasedValue was: ${data.attributedIncreasedValue}');
    }
    if (decreasedValue != null && decreasedValue != data.decreasedValue) {
      return failWithDescription(matchState, 'decreasedValue was: ${data.decreasedValue}');
    }
    if (attributedDecreasedValue != null &&
        (attributedDecreasedValue!.string != data.attributedDecreasedValue.string ||
         !_stringAttributesEqual(attributedDecreasedValue!.attributes, data.attributedDecreasedValue.attributes))) {
      return failWithDescription(
          matchState, 'attributedDecreasedValue was: ${data.attributedDecreasedValue}');
    }
    if (tooltip != null && tooltip != data.tooltip) {
      return failWithDescription(matchState, 'tooltip was: ${data.tooltip}');
    }
    if (textDirection != null && textDirection != data.textDirection) {
      return failWithDescription(matchState, 'textDirection was: $textDirection');
    }
    if (rect != null && rect != data.rect) {
      return failWithDescription(matchState, 'rect was: ${data.rect}');
    }
    if (size != null && size != data.rect.size) {
      return failWithDescription(matchState, 'size was: ${data.rect.size}');
    }
    if (elevation != null && elevation != data.elevation) {
      return failWithDescription(matchState, 'elevation was: ${data.elevation}');
    }
    if (thickness != null && thickness != data.thickness) {
      return failWithDescription(matchState, 'thickness was: ${data.thickness}');
    }
    if (platformViewId != null && platformViewId != data.platformViewId) {
      return failWithDescription(matchState, 'platformViewId was: ${data.platformViewId}');
    }
    if (currentValueLength != null && currentValueLength != data.currentValueLength) {
      return failWithDescription(matchState, 'currentValueLength was: ${data.currentValueLength}');
    }
    if (maxValueLength != null && maxValueLength != data.maxValueLength) {
      return failWithDescription(matchState, 'maxValueLength was: ${data.maxValueLength}');
    }
    if (actions.isNotEmpty) {
      final List<SemanticsAction> unexpectedActions = <SemanticsAction>[];
      final List<SemanticsAction> missingActions = <SemanticsAction>[];
      for (final MapEntry<ui.SemanticsAction, bool> actionEntry in actions.entries) {
        final ui.SemanticsAction action = actionEntry.key;
        final bool actionExpected = actionEntry.value;
        final bool actionPresent = (action.index & data.actions) == action.index;
        if (actionPresent != actionExpected) {
          if(actionExpected) {
            missingActions.add(action);
          } else {
            unexpectedActions.add(action);
          }
        }
      }

      if (unexpectedActions.isNotEmpty || missingActions.isNotEmpty) {
        return failWithDescription(matchState, 'missing actions: ${_createEnumsSummary(missingActions)} unexpected actions: ${_createEnumsSummary(unexpectedActions)}');
      }
    }
    if (customActions != null || hintOverrides != null) {
      final List<CustomSemanticsAction> providedCustomActions = data.customSemanticsActionIds?.map<CustomSemanticsAction>((final int id) {
        return CustomSemanticsAction.getAction(id)!;
      }).toList() ?? <CustomSemanticsAction>[];
      final List<CustomSemanticsAction> expectedCustomActions = customActions?.toList() ?? <CustomSemanticsAction>[];
      if (hintOverrides?.onTapHint != null) {
        expectedCustomActions.add(CustomSemanticsAction.overridingAction(hint: hintOverrides!.onTapHint!, action: SemanticsAction.tap));
      }
      if (hintOverrides?.onLongPressHint != null) {
        expectedCustomActions.add(CustomSemanticsAction.overridingAction(hint: hintOverrides!.onLongPressHint!, action: SemanticsAction.longPress));
      }
      if (expectedCustomActions.length != providedCustomActions.length) {
        return failWithDescription(matchState, 'custom actions were: $providedCustomActions');
      }
      int sortActions(final CustomSemanticsAction left, final CustomSemanticsAction right) {
        return CustomSemanticsAction.getIdentifier(left) - CustomSemanticsAction.getIdentifier(right);
      }
      expectedCustomActions.sort(sortActions);
      providedCustomActions.sort(sortActions);
      for (int i = 0; i < expectedCustomActions.length; i++) {
        if (expectedCustomActions[i] != providedCustomActions[i]) {
          return failWithDescription(matchState, 'custom actions were: $providedCustomActions');
        }
      }
    }
    if (flags.isNotEmpty) {
      final List<SemanticsFlag> unexpectedFlags = <SemanticsFlag>[];
      final List<SemanticsFlag> missingFlags = <SemanticsFlag>[];
      for (final MapEntry<ui.SemanticsFlag, bool> flagEntry in flags.entries) {
        final ui.SemanticsFlag flag = flagEntry.key;
        final bool flagExpected = flagEntry.value;
        final bool flagPresent = flag.index & data.flags == flag.index;
        if (flagPresent != flagExpected) {
          if(flagExpected) {
            missingFlags.add(flag);
          } else {
            unexpectedFlags.add(flag);
          }
        }
      }

      if (unexpectedFlags.isNotEmpty || missingFlags.isNotEmpty) {
        return failWithDescription(matchState, 'missing flags: ${_createEnumsSummary(missingFlags)} unexpected flags: ${_createEnumsSummary(unexpectedFlags)}');
      }
    }
    bool allMatched = true;
    if (children != null) {
      int i = 0;
      (node as SemanticsNode).visitChildren((final SemanticsNode child) {
        allMatched = children![i].matches(child, matchState) && allMatched;
        i += 1;
        return allMatched;
      });
    }
    return allMatched;
  }

  bool failWithDescription(final Map<dynamic, dynamic> matchState, final String description) {
    matchState['failure'] = description;
    return false;
  }

  @override
  Description describeMismatch(
    final dynamic item,
    final Description mismatchDescription,
    final Map<dynamic, dynamic> matchState,
    final bool verbose,
  ) {
    return mismatchDescription.add(matchState['failure'] as String);
  }

  static String _createEnumsSummary<T extends Object>(final List<T> enums) {
    assert(T == SemanticsAction || T == SemanticsFlag, 'This method is only intended for lists of SemanticsActions or SemanticsFlags.');
    if (T == SemanticsAction) {
      return '[${(enums as List<SemanticsAction>).map((final SemanticsAction d) => d.name).join(', ')}]';
    } else {
      return '[${(enums as List<SemanticsFlag>).map((final SemanticsFlag d) => d.name).join(', ')}]';
    }
  }
}

class _MatchesAccessibilityGuideline extends AsyncMatcher {
  _MatchesAccessibilityGuideline(this.guideline);

  final AccessibilityGuideline guideline;

  @override
  Description describe(final Description description) {
    return description.add(guideline.description);
  }

  @override
  Future<String?> matchAsync(covariant final WidgetTester tester) async {
    final Evaluation result = await guideline.evaluate(tester);
    if (result.passed) {
      return null;
    }
    return result.reason;
  }
}

class _DoesNotMatchAccessibilityGuideline extends AsyncMatcher {
  _DoesNotMatchAccessibilityGuideline(this.guideline);

  final AccessibilityGuideline guideline;

  @override
  Description describe(final Description description) {
    return description.add('Does not ${guideline.description}');
  }

  @override
  Future<String?> matchAsync(covariant final WidgetTester tester) async {
    final Evaluation result = await guideline.evaluate(tester);
    if (result.passed) {
      return 'Failed';
    }
    return null;
  }
}
