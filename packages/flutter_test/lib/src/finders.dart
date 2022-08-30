// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' show Tooltip;
import 'package:flutter/widgets.dart';

import 'all_elements.dart';

/// Signature for [CommonFinders.byWidgetPredicate].
typedef WidgetPredicate = bool Function(Widget widget);

/// Signature for [CommonFinders.byElementPredicate].
typedef ElementPredicate = bool Function(Element element);

/// Some frequently used widget [Finder]s.
const CommonFinders find = CommonFinders._();

/// Provides lightweight syntax for getting frequently used widget [Finder]s.
///
/// This class is instantiated once, as [find].
class CommonFinders {
  const CommonFinders._();

  /// Finds [Text], [EditableText], and optionally [RichText] widgets
  /// containing string equal to the `text` argument.
  ///
  /// If `findRichText` is false, all standalone [RichText] widgets are
  /// ignored and `text` is matched with [Text.data] or [Text.textSpan].
  /// If `findRichText` is true, [RichText] widgets (and therefore also
  /// [Text] and [Text.rich] widgets) are matched by comparing the
  /// [InlineSpan.toPlainText] with the given `text`.
  ///
  /// For [EditableText] widgets, the `text` is always compared to the current
  /// value of the [EditableText.controller].
  ///
  /// If the `skipOffstage` argument is true (the default), then this skips
  /// nodes that are [Offstage] or that are from inactive [Route]s.
  ///
  /// ## Sample code
  ///
  /// ```dart
  /// expect(find.text('Back'), findsOneWidget);
  /// ```
  ///
  /// This will match [Text], [Text.rich], and [EditableText] widgets that
  /// contain the "Back" string.
  ///
  /// ```dart
  /// expect(find.text('Close', findRichText: true), findsOneWidget);
  /// ```
  ///
  /// This will match [Text], [Text.rich], [EditableText], as well as standalone
  /// [RichText] widgets that contain the "Close" string.
  Finder text(
    String text, {
    bool findRichText = false,
    bool skipOffstage = true,
  }) {
    return _TextFinder(
      text,
      findRichText: findRichText,
      skipOffstage: skipOffstage,
    );
  }

  /// Finds [Text] and [EditableText], and optionally [RichText] widgets
  /// which contain the given `pattern` argument.
  ///
  /// If `findRichText` is false, all standalone [RichText] widgets are
  /// ignored and `pattern` is matched with [Text.data] or [Text.textSpan].
  /// If `findRichText` is true, [RichText] widgets (and therefore also
  /// [Text] and [Text.rich] widgets) are matched by comparing the
  /// [InlineSpan.toPlainText] with the given `pattern`.
  ///
  /// For [EditableText] widgets, the `pattern` is always compared to the currentt
  /// value of the [EditableText.controller].
  ///
  /// If the `skipOffstage` argument is true (the default), then this skips
  /// nodes that are [Offstage] or that are from inactive [Route]s.
  ///
  /// ## Sample code
  ///
  /// ```dart
  /// expect(find.textContaining('Back'), findsOneWidget);
  /// expect(find.textContaining(RegExp(r'(\w+)')), findsOneWidget);
  /// ```
  ///
  /// This will match [Text], [Text.rich], and [EditableText] widgets that
  /// contain the given pattern : 'Back' or RegExp(r'(\w+)').
  ///
  /// ```dart
  /// expect(find.textContaining('Close', findRichText: true), findsOneWidget);
  /// expect(find.textContaining(RegExp(r'(\w+)'), findRichText: true), findsOneWidget);
  /// ```
  ///
  /// This will match [Text], [Text.rich], [EditableText], as well as standalone
  /// [RichText] widgets that contain the given pattern : 'Close' or RegExp(r'(\w+)').
  Finder textContaining(
    Pattern pattern, {
    bool findRichText = false,
    bool skipOffstage = true,
  }) {
    return _TextContainingFinder(
      pattern,
      findRichText: findRichText,
      skipOffstage: skipOffstage
    );
  }

  /// Looks for widgets that contain a [Text] descendant with `text`
  /// in it.
  ///
  /// ## Sample code
  ///
  /// ```dart
  /// // Suppose you have a button with text 'Update' in it:
  /// Button(
  ///   child: Text('Update')
  /// )
  ///
  /// // You can find and tap on it like this:
  /// tester.tap(find.widgetWithText(Button, 'Update'));
  /// ```
  ///
  /// If the `skipOffstage` argument is true (the default), then this skips
  /// nodes that are [Offstage] or that are from inactive [Route]s.
  Finder widgetWithText(Type widgetType, String text, { bool skipOffstage = true }) {
    return find.ancestor(
      of: find.text(text, skipOffstage: skipOffstage),
      matching: find.byType(widgetType, skipOffstage: skipOffstage),
    );
  }

  /// Finds [Image] and [FadeInImage] widgets containing `image` equal to the
  /// `image` argument.
  ///
  /// ## Sample code
  ///
  /// ```dart
  /// expect(find.image(FileImage(File(filePath))), findsOneWidget);
  /// ```
  ///
  /// If the `skipOffstage` argument is true (the default), then this skips
  /// nodes that are [Offstage] or that are from inactive [Route]s.
  Finder image(ImageProvider image, { bool skipOffstage = true }) => _WidgetImageFinder(image, skipOffstage: skipOffstage);

  /// Finds widgets by searching for one with a particular [Key].
  ///
  /// ## Sample code
  ///
  /// ```dart
  /// expect(find.byKey(backKey), findsOneWidget);
  /// ```
  ///
  /// If the `skipOffstage` argument is true (the default), then this skips
  /// nodes that are [Offstage] or that are from inactive [Route]s.
  Finder byKey(Key key, { bool skipOffstage = true }) => _KeyFinder(key, skipOffstage: skipOffstage);

  /// Finds widgets by searching for widgets implementing a particular type.
  ///
  /// This matcher accepts subtypes. For example a
  /// `bySubtype<StatefulWidget>()` will find any stateful widget.
  ///
  /// ## Sample code
  ///
  /// ```dart
  /// expect(find.bySubtype<IconButton>(), findsOneWidget);
  /// ```
  ///
  /// If the `skipOffstage` argument is true (the default), then this skips
  /// nodes that are [Offstage] or that are from inactive [Route]s.
  ///
  /// See also:
  /// * [byType], which does not do subtype tests.
  Finder bySubtype<T extends Widget>({ bool skipOffstage = true }) => _WidgetSubtypeFinder<T>(skipOffstage: skipOffstage);

  /// Finds widgets by searching for widgets with a particular type.
  ///
  /// This does not do subclass tests, so for example
  /// `byType(StatefulWidget)` will never find anything since that's
  /// an abstract class.
  ///
  /// The `type` argument must be a subclass of [Widget].
  ///
  /// ## Sample code
  ///
  /// ```dart
  /// expect(find.byType(IconButton), findsOneWidget);
  /// ```
  ///
  /// If the `skipOffstage` argument is true (the default), then this skips
  /// nodes that are [Offstage] or that are from inactive [Route]s.
  ///
  /// See also:
  /// * [bySubtype], which allows subtype tests.
  Finder byType(Type type, { bool skipOffstage = true }) => _WidgetTypeFinder(type, skipOffstage: skipOffstage);

  /// Finds [Icon] widgets containing icon data equal to the `icon`
  /// argument.
  ///
  /// ## Sample code
  ///
  /// ```dart
  /// expect(find.byIcon(Icons.inbox), findsOneWidget);
  /// ```
  ///
  /// If the `skipOffstage` argument is true (the default), then this skips
  /// nodes that are [Offstage] or that are from inactive [Route]s.
  Finder byIcon(IconData icon, { bool skipOffstage = true }) => _WidgetIconFinder(icon, skipOffstage: skipOffstage);

  /// Looks for widgets that contain an [Icon] descendant displaying [IconData]
  /// `icon` in it.
  ///
  /// ## Sample code
  ///
  /// ```dart
  /// // Suppose you have a button with icon 'arrow_forward' in it:
  /// Button(
  ///   child: Icon(Icons.arrow_forward)
  /// )
  ///
  /// // You can find and tap on it like this:
  /// tester.tap(find.widgetWithIcon(Button, Icons.arrow_forward));
  /// ```
  ///
  /// If the `skipOffstage` argument is true (the default), then this skips
  /// nodes that are [Offstage] or that are from inactive [Route]s.
  Finder widgetWithIcon(Type widgetType, IconData icon, { bool skipOffstage = true }) {
    return find.ancestor(
      of: find.byIcon(icon),
      matching: find.byType(widgetType),
    );
  }

  /// Looks for widgets that contain an [Image] descendant displaying [ImageProvider]
  /// `image` in it.
  ///
  /// ## Sample code
  ///
  /// ```dart
  /// // Suppose you have a button with image in it:
  /// Button(
  ///   child: Image.file(filePath)
  /// )
  ///
  /// // You can find and tap on it like this:
  /// tester.tap(find.widgetWithImage(Button, FileImage(filePath)));
  /// ```
  ///
  /// If the `skipOffstage` argument is true (the default), then this skips
  /// nodes that are [Offstage] or that are from inactive [Route]s.
  Finder widgetWithImage(Type widgetType, ImageProvider image, { bool skipOffstage = true }) {
    return find.ancestor(
      of: find.image(image),
      matching: find.byType(widgetType),
    );
  }

  /// Finds widgets by searching for elements with a particular type.
  ///
  /// This does not do subclass tests, so for example
  /// `byElementType(VirtualViewportElement)` will never find anything
  /// since that's an abstract class.
  ///
  /// The `type` argument must be a subclass of [Element].
  ///
  /// ## Sample code
  ///
  /// ```dart
  /// expect(find.byElementType(SingleChildRenderObjectElement), findsOneWidget);
  /// ```
  ///
  /// If the `skipOffstage` argument is true (the default), then this skips
  /// nodes that are [Offstage] or that are from inactive [Route]s.
  Finder byElementType(Type type, { bool skipOffstage = true }) => _ElementTypeFinder(type, skipOffstage: skipOffstage);

  /// Finds widgets whose current widget is the instance given by the
  /// argument.
  ///
  /// ## Sample code
  ///
  /// ```dart
  /// // Suppose you have a button created like this:
  /// Widget myButton = Button(
  ///   child: Text('Update')
  /// );
  ///
  /// // You can find and tap on it like this:
  /// tester.tap(find.byWidget(myButton));
  /// ```
  ///
  /// If the `skipOffstage` argument is true (the default), then this skips
  /// nodes that are [Offstage] or that are from inactive [Route]s.
  Finder byWidget(Widget widget, { bool skipOffstage = true }) => _WidgetFinder(widget, skipOffstage: skipOffstage);

  /// Finds widgets using a widget [predicate].
  ///
  /// ## Sample code
  ///
  /// ```dart
  /// expect(find.byWidgetPredicate(
  ///   (Widget widget) => widget is Tooltip && widget.message == 'Back',
  ///   description: 'widget with tooltip "Back"',
  /// ), findsOneWidget);
  /// ```
  ///
  /// If [description] is provided, then this uses it as the description of the
  /// [Finder] and appears, for example, in the error message when the finder
  /// fails to locate the desired widget. Otherwise, the description prints the
  /// signature of the predicate function.
  ///
  /// If the `skipOffstage` argument is true (the default), then this skips
  /// nodes that are [Offstage] or that are from inactive [Route]s.
  Finder byWidgetPredicate(WidgetPredicate predicate, { String? description, bool skipOffstage = true }) {
    return _WidgetPredicateFinder(predicate, description: description, skipOffstage: skipOffstage);
  }

  /// Finds Tooltip widgets with the given message.
  ///
  /// ## Sample code
  ///
  /// ```dart
  /// expect(find.byTooltip('Back'), findsOneWidget);
  /// ```
  ///
  /// If the `skipOffstage` argument is true (the default), then this skips
  /// nodes that are [Offstage] or that are from inactive [Route]s.
  Finder byTooltip(String message, { bool skipOffstage = true }) {
    return byWidgetPredicate(
      (Widget widget) => widget is Tooltip && widget.message == message,
      skipOffstage: skipOffstage,
    );
  }

  /// Finds widgets using an element [predicate].
  ///
  /// ## Sample code
  ///
  /// ```dart
  /// expect(find.byElementPredicate(
  ///   // finds elements of type SingleChildRenderObjectElement, including
  ///   // those that are actually subclasses of that type.
  ///   // (contrast with byElementType, which only returns exact matches)
  ///   (Element element) => element is SingleChildRenderObjectElement,
  ///   description: '$SingleChildRenderObjectElement element',
  /// ), findsOneWidget);
  /// ```
  ///
  /// If [description] is provided, then this uses it as the description of the
  /// [Finder] and appears, for example, in the error message when the finder
  /// fails to locate the desired widget. Otherwise, the description prints the
  /// signature of the predicate function.
  ///
  /// If the `skipOffstage` argument is true (the default), then this skips
  /// nodes that are [Offstage] or that are from inactive [Route]s.
  Finder byElementPredicate(ElementPredicate predicate, { String? description, bool skipOffstage = true }) {
    return _ElementPredicateFinder(predicate, description: description, skipOffstage: skipOffstage);
  }

  /// Finds widgets that are descendants of the [of] parameter and that match
  /// the [matching] parameter.
  ///
  /// ## Sample code
  ///
  /// ```dart
  /// expect(find.descendant(
  ///   of: find.widgetWithText(Row, 'label_1'), matching: find.text('value_1')
  /// ), findsOneWidget);
  /// ```
  ///
  /// If the [matchRoot] argument is true then the widget(s) specified by [of]
  /// will be matched along with the descendants.
  ///
  /// If the [skipOffstage] argument is true (the default), then nodes that are
  /// [Offstage] or that are from inactive [Route]s are skipped.
  Finder descendant({
    required Finder of,
    required Finder matching,
    bool matchRoot = false,
    bool skipOffstage = true,
  }) {
    return _DescendantFinder(of, matching, matchRoot: matchRoot, skipOffstage: skipOffstage);
  }

  /// Finds widgets that are ancestors of the [of] parameter and that match
  /// the [matching] parameter.
  ///
  /// ## Sample code
  ///
  /// ```dart
  /// // Test if a Text widget that contains 'faded' is the
  /// // descendant of an Opacity widget with opacity 0.5:
  /// expect(
  ///   tester.widget<Opacity>(
  ///     find.ancestor(
  ///       of: find.text('faded'),
  ///       matching: find.byType('Opacity'),
  ///     )
  ///   ).opacity,
  ///   0.5
  /// );
  /// ```
  ///
  /// If the [matchRoot] argument is true then the widget(s) specified by [of]
  /// will be matched along with the ancestors.
  Finder ancestor({
    required Finder of,
    required Finder matching,
    bool matchRoot = false,
  }) {
    return _AncestorFinder(of, matching, matchRoot: matchRoot);
  }

  /// Finds [Semantics] widgets matching the given `label`, either by
  /// [RegExp.hasMatch] or string equality.
  ///
  /// The framework may combine semantics labels in certain scenarios, such as
  /// when multiple [Text] widgets are in a [MaterialButton] widget. In such a
  /// case, it may be preferable to match by regular expression. Consumers of
  /// this API __must not__ introduce unsuitable content into the semantics tree
  /// for the purposes of testing; in particular, you should prefer matching by
  /// regular expression rather than by string if the framework has combined
  /// your semantics, and not try to force the framework to break up the
  /// semantics nodes. Breaking up the nodes would have an undesirable effect on
  /// screen readers and other accessibility services.
  ///
  /// ## Sample code
  ///
  /// ```dart
  /// expect(find.bySemanticsLabel('Back'), findsOneWidget);
  /// ```
  ///
  /// If the `skipOffstage` argument is true (the default), then this skips
  /// nodes that are [Offstage] or that are from inactive [Route]s.
  Finder bySemanticsLabel(Pattern label, { bool skipOffstage = true }) {
    if (WidgetsBinding.instance.pipelineOwner.semanticsOwner == null) {
      throw StateError('Semantics are not enabled. '
                       'Make sure to call tester.ensureSemantics() before using '
                       'this finder, and call dispose on its return value after.');
    }
    return byElementPredicate(
      (Element element) {
        // Multiple elements can have the same renderObject - we want the "owner"
        // of the renderObject, i.e. the RenderObjectElement.
        if (element is! RenderObjectElement) {
          return false;
        }
        final String? semanticsLabel = element.renderObject.debugSemantics?.label;
        if (semanticsLabel == null) {
          return false;
        }
        return label is RegExp
            ? label.hasMatch(semanticsLabel)
            : label == semanticsLabel;
      },
      skipOffstage: skipOffstage,
    );
  }
}

/// Searches a widget tree and returns nodes that match a particular
/// pattern.
abstract class Finder {
  /// Initializes a Finder. Used by subclasses to initialize the [skipOffstage]
  /// property.
  Finder({ this.skipOffstage = true });

  /// Describes what the finder is looking for. The description should be
  /// a brief English noun phrase describing the finder's pattern.
  String get description;

  /// Returns all the elements in the given list that match this
  /// finder's pattern.
  ///
  /// When implementing your own Finders that inherit directly from
  /// [Finder], this is the main method to override. If your finder
  /// can efficiently be described just in terms of a predicate
  /// function, consider extending [MatchFinder] instead.
  Iterable<Element> apply(Iterable<Element> candidates);

  /// Whether this finder skips nodes that are offstage.
  ///
  /// If this is true, then the elements are walked using
  /// [Element.debugVisitOnstageChildren]. This skips offstage children of
  /// [Offstage] widgets, as well as children of inactive [Route]s.
  final bool skipOffstage;

  /// Returns all the [Element]s that will be considered by this finder.
  ///
  /// See [collectAllElementsFrom].
  @protected
  Iterable<Element> get allCandidates {
    return collectAllElementsFrom(
      WidgetsBinding.instance.renderViewElement!,
      skipOffstage: skipOffstage,
    );
  }

  Iterable<Element>? _cachedResult;

  /// Returns the current result. If [precache] was called and returned true, this will
  /// cheaply return the result that was computed then. Otherwise, it creates a new
  /// iterable to compute the answer.
  ///
  /// Calling this clears the cache from [precache].
  Iterable<Element> evaluate() {
    final Iterable<Element> result = _cachedResult ?? apply(allCandidates);
    _cachedResult = null;
    return result;
  }

  /// Attempts to evaluate the finder. Returns whether any elements in the tree
  /// matched the finder. If any did, then the result is cached and can be obtained
  /// from [evaluate].
  ///
  /// If this returns true, you must call [evaluate] before you call [precache] again.
  bool precache() {
    assert(_cachedResult == null);
    final Iterable<Element> result = apply(allCandidates);
    if (result.isNotEmpty) {
      _cachedResult = result;
      return true;
    }
    _cachedResult = null;
    return false;
  }

  /// Returns a variant of this finder that only matches the first element
  /// matched by this finder.
  Finder get first => _FirstFinder(this);

  /// Returns a variant of this finder that only matches the last element
  /// matched by this finder.
  Finder get last => _LastFinder(this);

  /// Returns a variant of this finder that only matches the element at the
  /// given index matched by this finder.
  Finder at(int index) => _IndexFinder(this, index);

  /// Returns a variant of this finder that only matches elements reachable by
  /// a hit test.
  ///
  /// The [at] parameter specifies the location relative to the size of the
  /// target element where the hit test is performed.
  Finder hitTestable({ Alignment at = Alignment.center }) => _HitTestableFinder(this, at);

  @override
  String toString() {
    final String additional = skipOffstage ? ' (ignoring offstage widgets)' : '';
    final List<Element> widgets = evaluate().toList();
    final int count = widgets.length;
    if (count == 0) {
      return 'zero widgets with $description$additional';
    }
    if (count == 1) {
      return 'exactly one widget with $description$additional: ${widgets.single}';
    }
    if (count < 4) {
      return '$count widgets with $description$additional: $widgets';
    }
    return '$count widgets with $description$additional: ${widgets[0]}, ${widgets[1]}, ${widgets[2]}, ...';
  }
}

/// Applies additional filtering against a [parent] [Finder].
abstract class ChainedFinder extends Finder {
  /// Create a Finder chained against the candidates of another [Finder].
  ChainedFinder(this.parent) : assert(parent != null);

  /// Another [Finder] that will run first.
  final Finder parent;

  /// Return another [Iterable] when given an [Iterable] of candidates from a
  /// parent [Finder].
  ///
  /// This is the method to implement when subclassing [ChainedFinder].
  Iterable<Element> filter(Iterable<Element> parentCandidates);

  @override
  Iterable<Element> apply(Iterable<Element> candidates) {
    return filter(parent.apply(candidates));
  }

  @override
  Iterable<Element> get allCandidates => parent.allCandidates;
}

class _FirstFinder extends ChainedFinder {
  _FirstFinder(super.parent);

  @override
  String get description => '${parent.description} (ignoring all but first)';

  @override
  Iterable<Element> filter(Iterable<Element> parentCandidates) sync* {
    yield parentCandidates.first;
  }
}

class _LastFinder extends ChainedFinder {
  _LastFinder(super.parent);

  @override
  String get description => '${parent.description} (ignoring all but last)';

  @override
  Iterable<Element> filter(Iterable<Element> parentCandidates) sync* {
    yield parentCandidates.last;
  }
}

class _IndexFinder extends ChainedFinder {
  _IndexFinder(super.parent, this.index);

  final int index;

  @override
  String get description => '${parent.description} (ignoring all but index $index)';

  @override
  Iterable<Element> filter(Iterable<Element> parentCandidates) sync* {
    yield parentCandidates.elementAt(index);
  }
}

class _HitTestableFinder extends ChainedFinder {
  _HitTestableFinder(super.parent, this.alignment);

  final Alignment alignment;

  @override
  String get description => '${parent.description} (considering only hit-testable ones)';

  @override
  Iterable<Element> filter(Iterable<Element> parentCandidates) sync* {
    for (final Element candidate in parentCandidates) {
      final RenderBox box = candidate.renderObject! as RenderBox;
      final Offset absoluteOffset = box.localToGlobal(alignment.alongSize(box.size));
      final HitTestResult hitResult = HitTestResult();
      WidgetsBinding.instance.hitTest(hitResult, absoluteOffset);
      for (final HitTestEntry entry in hitResult.path) {
        if (entry.target == candidate.renderObject) {
          yield candidate;
          break;
        }
      }
    }
  }
}

/// Searches a widget tree and returns nodes that match a particular
/// pattern.
abstract class MatchFinder extends Finder {
  /// Initializes a predicate-based Finder. Used by subclasses to initialize the
  /// [skipOffstage] property.
  MatchFinder({ super.skipOffstage });

  /// Returns true if the given element matches the pattern.
  ///
  /// When implementing your own MatchFinder, this is the main method to override.
  bool matches(Element candidate);

  @override
  Iterable<Element> apply(Iterable<Element> candidates) {
    return candidates.where(matches);
  }
}

abstract class _MatchTextFinder extends MatchFinder {
  _MatchTextFinder({
    this.findRichText = false,
    super.skipOffstage,
  });

  /// Whether standalone [RichText] widgets should be found or not.
  ///
  /// Defaults to `false`.
  ///
  /// If disabled, only [Text] widgets will be matched. [RichText] widgets
  /// *without* a [Text] ancestor will be ignored.
  /// If enabled, only [RichText] widgets will be matched. This *implicitly*
  /// matches [Text] widgets as well since they always insert a [RichText]
  /// child.
  ///
  /// In either case, [EditableText] widgets will also be matched.
  final bool findRichText;

  bool matchesText(String textToMatch);

  @override
  bool matches(Element candidate) {
    final Widget widget = candidate.widget;
    if (widget is EditableText) {
      return _matchesEditableText(widget);
    }

    if (!findRichText) {
      return _matchesNonRichText(widget);
    }
    // It would be sufficient to always use _matchesRichText if we wanted to
    // match both standalone RichText widgets as well as Text widgets. However,
    // the find.text() finder used to always ignore standalone RichText widgets,
    // which is why we need the _matchesNonRichText method in order to not be
    // backwards-compatible and not break existing tests.
    return _matchesRichText(widget);
  }

  bool _matchesRichText(Widget widget) {
    if (widget is RichText) {
      return matchesText(widget.text.toPlainText());
    }
    return false;
  }

  bool _matchesNonRichText(Widget widget) {
    if (widget is Text) {
      if (widget.data != null) {
        return matchesText(widget.data!);
      }
      assert(widget.textSpan != null);
      return matchesText(widget.textSpan!.toPlainText());
    }
    return false;
  }

  bool _matchesEditableText(EditableText widget) {
    return matchesText(widget.controller.text);
  }
}

class _TextFinder extends _MatchTextFinder {
  _TextFinder(
    this.text, {
    super.findRichText,
    super.skipOffstage,
  });

  final String text;

  @override
  String get description => 'text "$text"';

  @override
  bool matchesText(String textToMatch) {
    return textToMatch == text;
  }
}

class _TextContainingFinder extends _MatchTextFinder {
  _TextContainingFinder(
    this.pattern, {
    super.findRichText,
    super.skipOffstage,
  });

  final Pattern pattern;

  @override
  String get description => 'text containing $pattern';

  @override
  bool matchesText(String textToMatch) {
    return textToMatch.contains(pattern);
  }
}

class _KeyFinder extends MatchFinder {
  _KeyFinder(this.key, { super.skipOffstage });

  final Key key;

  @override
  String get description => 'key $key';

  @override
  bool matches(Element candidate) {
    return candidate.widget.key == key;
  }
}

class _WidgetSubtypeFinder<T extends Widget> extends MatchFinder {
  _WidgetSubtypeFinder({ super.skipOffstage });

  @override
  String get description => 'is "$T"';

  @override
  bool matches(Element candidate) {
    return candidate.widget is T;
  }
}

class _WidgetTypeFinder extends MatchFinder {
  _WidgetTypeFinder(this.widgetType, { super.skipOffstage });

  final Type widgetType;

  @override
  String get description => 'type "$widgetType"';

  @override
  bool matches(Element candidate) {
    return candidate.widget.runtimeType == widgetType;
  }
}

class _WidgetImageFinder extends MatchFinder {
  _WidgetImageFinder(this.image, { super.skipOffstage });

  final ImageProvider image;

  @override
  String get description => 'image "$image"';

  @override
  bool matches(Element candidate) {
    final Widget widget = candidate.widget;
    if (widget is Image) {
      return widget.image == image;
    } else if (widget is FadeInImage) {
      return widget.image == image;
    }
    return false;
  }
}

class _WidgetIconFinder extends MatchFinder {
  _WidgetIconFinder(this.icon, { super.skipOffstage });

  final IconData icon;

  @override
  String get description => 'icon "$icon"';

  @override
  bool matches(Element candidate) {
    final Widget widget = candidate.widget;
    return widget is Icon && widget.icon == icon;
  }
}

class _ElementTypeFinder extends MatchFinder {
  _ElementTypeFinder(this.elementType, { super.skipOffstage });

  final Type elementType;

  @override
  String get description => 'type "$elementType"';

  @override
  bool matches(Element candidate) {
    return candidate.runtimeType == elementType;
  }
}

class _WidgetFinder extends MatchFinder {
  _WidgetFinder(this.widget, { super.skipOffstage });

  final Widget widget;

  @override
  String get description => 'the given widget ($widget)';

  @override
  bool matches(Element candidate) {
    return candidate.widget == widget;
  }
}

class _WidgetPredicateFinder extends MatchFinder {
  _WidgetPredicateFinder(this.predicate, { String? description, super.skipOffstage })
    : _description = description;

  final WidgetPredicate predicate;
  final String? _description;

  @override
  String get description => _description ?? 'widget matching predicate ($predicate)';

  @override
  bool matches(Element candidate) {
    return predicate(candidate.widget);
  }
}

class _ElementPredicateFinder extends MatchFinder {
  _ElementPredicateFinder(this.predicate, { String? description, super.skipOffstage })
    : _description = description;

  final ElementPredicate predicate;
  final String? _description;

  @override
  String get description => _description ?? 'element matching predicate ($predicate)';

  @override
  bool matches(Element candidate) {
    return predicate(candidate);
  }
}

class _DescendantFinder extends Finder {
  _DescendantFinder(
    this.ancestor,
    this.descendant, {
    this.matchRoot = false,
    super.skipOffstage,
  });

  final Finder ancestor;
  final Finder descendant;
  final bool matchRoot;

  @override
  String get description {
    if (matchRoot) {
      return '${descendant.description} in the subtree(s) beginning with ${ancestor.description}';
    }
    return '${descendant.description} that has ancestor(s) with ${ancestor.description}';
  }

  @override
  Iterable<Element> apply(Iterable<Element> candidates) {
    return candidates.where((Element element) => descendant.evaluate().contains(element));
  }

  @override
  Iterable<Element> get allCandidates {
    final Iterable<Element> ancestorElements = ancestor.evaluate();
    final List<Element> candidates = ancestorElements.expand<Element>(
      (Element element) => collectAllElementsFrom(element, skipOffstage: skipOffstage)
    ).toSet().toList();
    if (matchRoot) {
      candidates.insertAll(0, ancestorElements);
    }
    return candidates;
  }
}

class _AncestorFinder extends Finder {
  _AncestorFinder(this.descendant, this.ancestor, { this.matchRoot = false }) : super(skipOffstage: false);

  final Finder ancestor;
  final Finder descendant;
  final bool matchRoot;

  @override
  String get description {
    if (matchRoot) {
      return 'ancestor ${ancestor.description} beginning with ${descendant.description}';
    }
    return '${ancestor.description} which is an ancestor of ${descendant.description}';
  }

  @override
  Iterable<Element> apply(Iterable<Element> candidates) {
    return candidates.where((Element element) => ancestor.evaluate().contains(element));
  }

  @override
  Iterable<Element> get allCandidates {
    final List<Element> candidates = <Element>[];
    for (final Element root in descendant.evaluate()) {
      final List<Element> ancestors = <Element>[];
      if (matchRoot) {
        ancestors.add(root);
      }
      root.visitAncestorElements((Element element) {
        ancestors.add(element);
        return true;
      });
      candidates.addAll(ancestors);
    }
    return candidates;
  }
}
