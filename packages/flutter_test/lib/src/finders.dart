// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import 'all_elements.dart';

/// Signature for [CommonFinders.byWidgetPredicate].
typedef bool WidgetPredicate(Widget widget);

/// Signature for [CommonFinders.byElementPredicate].
typedef bool ElementPredicate(Element element);

/// Some frequently used widget [Finder]s.
final CommonFinders find = const CommonFinders._();

/// Provides lightweight syntax for getting frequently used widget [Finder]s.
///
/// This class is instantiated once, as [find].
class CommonFinders {
  const CommonFinders._();

  /// Finds [Text] widgets containing string equal to the `text`
  /// argument.
  ///
  /// Example:
  ///
  ///     expect(find.text('Back'), findsOneWidget);
  ///
  /// If the `skipOffstage` argument is true (the default), then this skips
  /// nodes that are [Offstage] or that are from inactive [Route]s.
  Finder text(String text, { bool skipOffstage: true }) => new _TextFinder(text, skipOffstage: skipOffstage);

  /// Finds [Icon] widgets containing icon data equal to the `icon`
  /// argument.
  ///
  /// Example:
  ///
  ///     expect(find.icon(Icons.chevron_left), findsOneWidget);
  ///
  /// If the `skipOffstage` argument is true (the default), then this skips
  /// nodes that are [Offstage] or that are from inactive [Route]s.
  Finder icon(IconData icon, { bool skipOffstage: true }) => new _IconFinder(icon, skipOffstage: skipOffstage);

  /// Looks for widgets that contain a [Text] descendant with `text`
  /// in it.
  ///
  /// Example:
  ///
  ///     // Suppose you have a button with text 'Update' in it:
  ///     new Button(
  ///       child: new Text('Update')
  ///     )
  ///
  ///     // You can find and tap on it like this:
  ///     tester.tap(find.widgetWithText(Button, 'Update'));
  ///
  /// If the `skipOffstage` argument is true (the default), then this skips
  /// nodes that are [Offstage] or that are from inactive [Route]s.
  Finder widgetWithText(Type widgetType, String text, { bool skipOffstage: true }) {
    return new _WidgetWithTextFinder(widgetType, text, skipOffstage: skipOffstage);
  }

  /// Finds widgets by searching for one with a particular [Key].
  ///
  /// Example:
  ///
  ///     expect(find.byKey(backKey), findsOneWidget);
  ///
  /// If the `skipOffstage` argument is true (the default), then this skips
  /// nodes that are [Offstage] or that are from inactive [Route]s.
  Finder byKey(Key key, { bool skipOffstage: true }) => new _KeyFinder(key, skipOffstage: skipOffstage);

  /// Finds widgets by searching for widgets with a particular type.
  ///
  /// This does not do subclass tests, so for example
  /// `byType(StatefulWidget)` will never find anything since that's
  /// an abstract class.
  ///
  /// The `type` argument must be a subclass of [Widget].
  ///
  /// Example:
  ///
  ///     expect(find.byType(IconButton), findsOneWidget);
  ///
  /// If the `skipOffstage` argument is true (the default), then this skips
  /// nodes that are [Offstage] or that are from inactive [Route]s.
  Finder byType(Type type, { bool skipOffstage: true }) => new _WidgetTypeFinder(type, skipOffstage: skipOffstage);

  /// Finds widgets by searching for widgets with a particular icon data.
  ///
  /// Example:
  ///
  ///     expect(find.byIcon(Icons.inbox), findsOneWidget);
  ///
  /// If the `skipOffstage` argument is true (the default), then this skips
  /// nodes that are [Offstage] or that are from inactive [Route]s.
  Finder byIcon(IconData icon, { bool skipOffstage: true }) => new _WidgetIconFinder(icon, skipOffstage: skipOffstage);

  /// Finds widgets by searching for elements with a particular type.
  ///
  /// This does not do subclass tests, so for example
  /// `byElementType(VirtualViewportElement)` will never find anything
  /// since that's an abstract class.
  ///
  /// The `type` argument must be a subclass of [Element].
  ///
  /// Example:
  ///
  ///     expect(find.byElementType(SingleChildRenderObjectElement), findsOneWidget);
  ///
  /// If the `skipOffstage` argument is true (the default), then this skips
  /// nodes that are [Offstage] or that are from inactive [Route]s.
  Finder byElementType(Type type, { bool skipOffstage: true }) => new _ElementTypeFinder(type, skipOffstage: skipOffstage);

  /// Finds widgets whose current widget is the instance given by the
  /// argument.
  ///
  /// Example:
  ///
  ///     // Suppose you have a button created like this:
  ///     Widget myButton = new Button(
  ///       child: new Text('Update')
  ///     );
  ///
  ///     // You can find and tap on it like this:
  ///     tester.tap(find.byWidget(myButton));
  ///
  /// If the `skipOffstage` argument is true (the default), then this skips
  /// nodes that are [Offstage] or that are from inactive [Route]s.
  Finder byWidget(Widget widget, { bool skipOffstage: true }) => new _WidgetFinder(widget, skipOffstage: skipOffstage);

  /// Finds widgets using a widget [predicate].
  ///
  /// Example:
  ///
  ///     expect(find.byWidgetPredicate(
  ///       (Widget widget) => widget is Tooltip && widget.message == 'Back',
  ///       description: 'widget with tooltip "Back"',
  ///     ), findsOneWidget);
  ///
  /// If [description] is provided, then this uses it as the description of the
  /// [Finder] and appears, for example, in the error message when the finder
  /// fails to locate the desired widget. Otherwise, the description prints the
  /// signature of the predicate function.
  ///
  /// If the `skipOffstage` argument is true (the default), then this skips
  /// nodes that are [Offstage] or that are from inactive [Route]s.
  Finder byWidgetPredicate(WidgetPredicate predicate, { String description, bool skipOffstage: true }) {
    return new _WidgetPredicateFinder(predicate, description: description, skipOffstage: skipOffstage);
  }

  /// Finds Tooltip widgets with the given message.
  ///
  /// Example:
  ///
  ///     expect(find.byTooltip('Back'), findsOneWidget);
  ///
  /// If the `skipOffstage` argument is true (the default), then this skips
  /// nodes that are [Offstage] or that are from inactive [Route]s.
  Finder byTooltip(String message, { bool skipOffstage: true }) {
    return byWidgetPredicate(
      (Widget widget) => widget is Tooltip && widget.message == message,
      skipOffstage: skipOffstage,
    );
  }

  /// Finds widgets using an element [predicate].
  ///
  /// Example:
  ///
  ///     expect(find.byElementPredicate(
  ///       // finds elements of type SingleChildRenderObjectElement, including
  ///       // those that are actually subclasses of that type.
  ///       // (contrast with byElementType, which only returns exact matches)
  ///       (Element element) => element is SingleChildRenderObjectElement,
  ///       description: '$SingleChildRenderObjectElement element',
  ///     ), findsOneWidget);
  ///
  /// If [description] is provided, then this uses it as the description of the
  /// [Finder] and appears, for example, in the error message when the finder
  /// fails to locate the desired widget. Otherwise, the description prints the
  /// signature of the predicate function.
  ///
  /// If the `skipOffstage` argument is true (the default), then this skips
  /// nodes that are [Offstage] or that are from inactive [Route]s.
  Finder byElementPredicate(ElementPredicate predicate, { String description, bool skipOffstage: true }) {
    return new _ElementPredicateFinder(predicate, description: description, skipOffstage: skipOffstage);
  }

  /// Finds widgets that are descendants of the [of] parameter and that match
  /// the [matching] parameter.
  ///
  /// Example:
  ///
  ///     expect(find.descendant(
  ///       of: find.widgetWithText(Row, 'label_1'), matching: find.text('value_1')
  ///     ), findsOneWidget);
  ///
  /// If the [matchRoot] argument is true then the widget(s) specified by [of]
  /// will be matched along with the descendants.
  ///
  /// If the [skipOffstage] argument is true (the default), then nodes that are
  /// [Offstage] or that are from inactive [Route]s are skipped.
  Finder descendant({ Finder of, Finder matching, bool matchRoot: false, bool skipOffstage: true }) {
    return new _DescendantFinder(of, matching, matchRoot: matchRoot, skipOffstage: skipOffstage);
  }
}

/// Searches a widget tree and returns nodes that match a particular
/// pattern.
abstract class Finder {
  /// Initialises a Finder. Used by subclasses to initialize the [skipOffstage]
  /// property.
  Finder({ this.skipOffstage: true });

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
  /// [Element.visitChildrenForSemantics]. This skips offstage children of
  /// [Offstage] widgets, as well as children of inactive [Route]s.
  final bool skipOffstage;

  /// Returns all the [Element]s that will be considered by this finder.
  ///
  /// See [collectAllElementsFrom].
  @protected
  Iterable<Element> get allCandidates {
    return collectAllElementsFrom(
      WidgetsBinding.instance.renderViewElement,
      skipOffstage: skipOffstage
    );
  }

  Iterable<Element> _cachedResult;

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
  Finder get first => new _FirstFinder(this);

  /// Returns a variant of this finder that only matches the last element
  /// matched by this finder.
  Finder get last => new _LastFinder(this);

  @override
  String toString() {
    final String additional = skipOffstage ? ' (ignoring offstage widgets)' : '';
    final List<Element> widgets = evaluate().toList();
    final int count = widgets.length;
    if (count == 0)
      return 'zero widgets with $description$additional';
    if (count == 1)
      return 'exactly one widget with $description$additional: ${widgets.single}';
    if (count < 4)
      return '$count widgets with $description$additional: $widgets';
    return '$count widgets with $description$additional: ${widgets[0]}, ${widgets[1]}, ${widgets[2]}, ...';
  }
}

class _FirstFinder extends Finder {
  _FirstFinder(this.parent);

  final Finder parent;

  @override
  String get description => '${parent.description} (ignoring all but first)';

  @override
  Iterable<Element> apply(Iterable<Element> candidates) sync* {
    yield parent.apply(candidates).first;
  }
}

class _LastFinder extends Finder {
  _LastFinder(this.parent);

  final Finder parent;

  @override
  String get description => '${parent.description} (ignoring all but last)';

  @override
  Iterable<Element> apply(Iterable<Element> candidates) sync* {
    yield parent.apply(candidates).last;
  }
}

/// Searches a widget tree and returns nodes that match a particular
/// pattern.
abstract class MatchFinder extends Finder {
  /// Initialises a predicate-based Finder. Used by subclasses to initialize the
  /// [skipOffstage] property.
  MatchFinder({ bool skipOffstage: true }) : super(skipOffstage: skipOffstage);

  /// Returns true if the given element matches the pattern.
  ///
  /// When implementing your own MatchFinder, this is the main method to override.
  bool matches(Element candidate);

  @override
  Iterable<Element> apply(Iterable<Element> candidates) {
    return candidates.where(matches);
  }
}

class _TextFinder extends MatchFinder {
  _TextFinder(this.text, { bool skipOffstage: true }) : super(skipOffstage: skipOffstage);

  final String text;

  @override
  String get description => 'text "$text"';

  @override
  bool matches(Element candidate) {
    if (candidate.widget is! Text)
      return false;
    final Text textWidget = candidate.widget;
    return textWidget.data == text;
  }
}

class _IconFinder extends MatchFinder {
  _IconFinder(this.icon, { bool skipOffstage: true }) : super(skipOffstage: skipOffstage);

  final IconData icon;

  @override
  String get description => 'icon "$icon"';

  @override
  bool matches(Element candidate) {
    if (candidate.widget is! Icon)
      return false;
    final Icon iconWidget = candidate.widget;
    return iconWidget.icon == icon;
  }
}

class _WidgetWithTextFinder extends Finder {
  _WidgetWithTextFinder(this.widgetType, this.text, { bool skipOffstage: true }) : super(skipOffstage: skipOffstage);

  final Type widgetType;
  final String text;

  @override
  String get description => 'type $widgetType with text "$text"';

  @override
  Iterable<Element> apply(Iterable<Element> candidates) {
    return candidates
      .map((Element textElement) {
        if (textElement.widget is! Text)
          return null;

        final Text textWidget = textElement.widget;
        if (textWidget.data == text) {
          try {
            textElement.visitAncestorElements((Element element) {
              if (element.widget.runtimeType == widgetType)
                throw element;
              return true;
            });
          } on Element catch (result) {
            return result;
          }
        }
        return null;
      })
      .where((Element element) => element != null);
  }
}

class _KeyFinder extends MatchFinder {
  _KeyFinder(this.key, { bool skipOffstage: true }) : super(skipOffstage: skipOffstage);

  final Key key;

  @override
  String get description => 'key $key';

  @override
  bool matches(Element candidate) {
    return candidate.widget.key == key;
  }
}

class _WidgetTypeFinder extends MatchFinder {
  _WidgetTypeFinder(this.widgetType, { bool skipOffstage: true }) : super(skipOffstage: skipOffstage);

  final Type widgetType;

  @override
  String get description => 'type "$widgetType"';

  @override
  bool matches(Element candidate) {
    return candidate.widget.runtimeType == widgetType;
  }
}

class _WidgetIconFinder extends MatchFinder {
  _WidgetIconFinder(this.icon, { bool skipOffstage: true }) : super(skipOffstage: skipOffstage);

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
  _ElementTypeFinder(this.elementType, { bool skipOffstage: true }) : super(skipOffstage: skipOffstage);

  final Type elementType;

  @override
  String get description => 'type "$elementType"';

  @override
  bool matches(Element candidate) {
    return candidate.runtimeType == elementType;
  }
}

class _WidgetFinder extends MatchFinder {
  _WidgetFinder(this.widget, { bool skipOffstage: true }) : super(skipOffstage: skipOffstage);

  final Widget widget;

  @override
  String get description => 'the given widget ($widget)';

  @override
  bool matches(Element candidate) {
    return candidate.widget == widget;
  }
}

class _WidgetPredicateFinder extends MatchFinder {
  _WidgetPredicateFinder(this.predicate, { String description, bool skipOffstage: true })
      : _description = description,
        super(skipOffstage: skipOffstage);

  final WidgetPredicate predicate;
  final String _description;

  @override
  String get description => _description ?? 'widget matching predicate ($predicate)';

  @override
  bool matches(Element candidate) {
    return predicate(candidate.widget);
  }
}

class _ElementPredicateFinder extends MatchFinder {
  _ElementPredicateFinder(this.predicate, { String description, bool skipOffstage: true })
      : _description = description,
        super(skipOffstage: skipOffstage);

  final ElementPredicate predicate;
  final String _description;

  @override
  String get description => _description ?? 'element matching predicate ($predicate)';

  @override
  bool matches(Element candidate) {
    return predicate(candidate);
  }
}

class _DescendantFinder extends Finder {
  _DescendantFinder(this.ancestor, this.descendant, {
    this.matchRoot: false,
    bool skipOffstage: true,
  }) : super(skipOffstage: skipOffstage);

  final Finder ancestor;
  final Finder descendant;
  final bool matchRoot;

  @override
  String get description {
    if (matchRoot)
      return '${descendant.description} in the subtree(s) beginning with ${ancestor.description}';
    return '${descendant.description} that has ancestor(s) with ${ancestor.description}';
  }

  @override
  Iterable<Element> apply(Iterable<Element> candidates) {
    return candidates.where((Element element) => descendant.evaluate().contains(element));
  }

  @override
  Iterable<Element> get allCandidates {
    final Iterable<Element> ancestorElements = ancestor.evaluate();
    final List<Element> candidates = ancestorElements.expand(
      (Element element) => collectAllElementsFrom(element, skipOffstage: skipOffstage)
    ).toSet().toList();
    if (matchRoot)
      candidates.insertAll(0, ancestorElements);
    return candidates;
  }
}
