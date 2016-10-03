// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'all_elements.dart';

/// Signature for [CommonFinders.byPredicate].
typedef bool WidgetPredicate(Widget widget);

/// Signature for [CommonFinders.byElement].
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
  ///     expect(tester, hasWidget(find.text('Back')));
  ///
  /// If the `skipOffstage` argument is true (the default), then this skips
  /// nodes that are [Offstage] or that are from inactive [Route]s.
  Finder text(String text, { bool skipOffstage: true }) => new _TextFinder(text, skipOffstage: skipOffstage);

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
  ///     expect(tester, hasWidget(find.byKey(backKey)));
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
  ///     expect(tester, hasWidget(find.byType(IconButton)));
  ///
  /// If the `skipOffstage` argument is true (the default), then this skips
  /// nodes that are [Offstage] or that are from inactive [Route]s.
  Finder byType(Type type, { bool skipOffstage: true }) => new _WidgetTypeFinder(type, skipOffstage: skipOffstage);

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
  ///     expect(tester, hasWidget(find.byElementType(SingleChildRenderObjectElement)));
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
  ///     tester.tap(find.byConfig(myButton));
  ///
  /// If the `skipOffstage` argument is true (the default), then this skips
  /// nodes that are [Offstage] or that are from inactive [Route]s.
  Finder byConfig(Widget config, { bool skipOffstage: true }) => new _ConfigFinder(config, skipOffstage: skipOffstage);

  /// Finds widgets using a widget predicate.
  ///
  /// Example:
  ///
  ///     expect(tester, hasWidget(find.byWidgetPredicate(
  ///       (Widget widget) => widget is Tooltip && widget.message == 'Back'
  ///     )));
  ///
  /// If the `skipOffstage` argument is true (the default), then this skips
  /// nodes that are [Offstage] or that are from inactive [Route]s.
  Finder byWidgetPredicate(WidgetPredicate predicate, { bool skipOffstage: true }) {
    return new _WidgetPredicateFinder(predicate, skipOffstage: skipOffstage);
  }

  /// Finds Tooltip widgets with the given message.
  ///
  /// Example:
  ///
  ///     expect(tester, hasWidget(find.byTooltip('Back')));
  ///
  /// If the `skipOffstage` argument is true (the default), then this skips
  /// nodes that are [Offstage] or that are from inactive [Route]s.
  Finder byTooltip(String message, { bool skipOffstage: true }) {
    return byWidgetPredicate(
      (Widget widget) => widget is Tooltip && widget.message == message,
      skipOffstage: skipOffstage,
    );
  }

  /// Finds widgets using an element predicate.
  ///
  /// Example:
  ///
  ///     expect(tester, hasWidget(find.byElementPredicate(
  ///       // finds elements of type SingleChildRenderObjectElement, including
  ///       // those that are actually subclasses of that type.
  ///       // (contrast with byElementType, which only returns exact matches)
  ///       (Element element) => element is SingleChildRenderObjectElement
  ///     )));
  ///
  /// If the `skipOffstage` argument is true (the default), then this skips
  /// nodes that are [Offstage] or that are from inactive [Route]s.
  Finder byElementPredicate(ElementPredicate predicate, { bool skipOffstage: true }) {
    return new _ElementPredicateFinder(predicate, skipOffstage: skipOffstage);
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

  Iterable<Element> get _allElements {
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
    final Iterable<Element> result = _cachedResult ?? apply(_allElements);
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
    final Iterable<Element> result = apply(_allElements);
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
    Text textWidget = candidate.widget;
    return textWidget.data == text;
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

        Text textWidget = textElement.widget;
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

class _ConfigFinder extends MatchFinder {
  _ConfigFinder(this.config, { bool skipOffstage: true }) : super(skipOffstage: skipOffstage);

  final Widget config;

  @override
  String get description => 'the given configuration ($config)';

  @override
  bool matches(Element candidate) {
    return candidate.widget == config;
  }
}

class _WidgetPredicateFinder extends MatchFinder {
  _WidgetPredicateFinder(this.predicate, { bool skipOffstage: true }) : super(skipOffstage: skipOffstage);

  final WidgetPredicate predicate;

  @override
  String get description => 'widget matching predicate ($predicate)';

  @override
  bool matches(Element candidate) {
    return predicate(candidate.widget);
  }
}

class _ElementPredicateFinder extends MatchFinder {
  _ElementPredicateFinder(this.predicate, { bool skipOffstage: true }) : super(skipOffstage: skipOffstage);

  final ElementPredicate predicate;

  @override
  String get description => 'element matching predicate ($predicate)';

  @override
  bool matches(Element candidate) {
    return predicate(candidate);
  }
}
