// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

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
  Finder text(String text) => new _TextFinder(text);

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
  Finder widgetWithText(Type widgetType, String text) {
    return new _WidgetWithTextFinder(widgetType, text);
  }

  /// Finds widgets by searching for one with a particular [Key].
  ///
  /// Example:
  ///
  ///     expect(tester, hasWidget(find.byKey(backKey)));
  Finder byKey(Key key) => new _KeyFinder(key);

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
  Finder byType(Type type) => new _WidgetTypeFinder(type);

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
  Finder byElementType(Type type) => new _ElementTypeFinder(type);

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
  Finder byConfig(Widget config) => new _ConfigFinder(config);

  /// Finds widgets using a widget predicate.
  ///
  /// Example:
  ///
  ///     expect(tester, hasWidget(find.byWidgetPredicate(
  ///       (Widget widget) => widget is Tooltip && widget.message == 'Back'
  ///     )));
  Finder byWidgetPredicate(WidgetPredicate predicate) {
    return new _WidgetPredicateFinder(predicate);
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
  Finder byElementPredicate(ElementPredicate predicate) {
    return new _ElementPredicateFinder(predicate);
  }
}

/// Searches a widget tree and returns nodes that match a particular
/// pattern.
abstract class Finder {
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

  // Right now this is hard-coded to just grab the elements from the binding.
  //
  // One could imagine a world where CommonFinders and Finder can be configured
  // to work from a specific subtree, but we'll implement that when it's needed.
  static Iterable<Element> get _allElements => collectAllElementsFrom(WidgetsBinding.instance.renderViewElement);

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

  @override
  String toString() {
    final List<Element> widgets = evaluate().toList();
    final int count = widgets.length;
    if (count == 0)
      return 'zero widgets with $description';
    if (count == 1)
      return 'exactly one widget with $description: ${widgets.single}';
    if (count < 4)
      return '$count widgets with $description: $widgets';
    return '$count widgets with $description: ${widgets[0]}, ${widgets[1]}, ${widgets[2]}, ...';
  }
}

/// Searches a widget tree and returns nodes that match a particular
/// pattern.
abstract class MatchFinder extends Finder {
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
  _TextFinder(this.text);

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
  _WidgetWithTextFinder(this.widgetType, this.text);

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
  _KeyFinder(this.key);

  final Key key;

  @override
  String get description => 'key $key';

  @override
  bool matches(Element candidate) {
    return candidate.widget.key == key;
  }
}

class _WidgetTypeFinder extends MatchFinder {
  _WidgetTypeFinder(this.widgetType);

  final Type widgetType;

  @override
  String get description => 'type "$widgetType"';

  @override
  bool matches(Element candidate) {
    return candidate.widget.runtimeType == widgetType;
  }
}

class _ElementTypeFinder extends MatchFinder {
  _ElementTypeFinder(this.elementType);

  final Type elementType;

  @override
  String get description => 'type "$elementType"';

  @override
  bool matches(Element candidate) {
    return candidate.runtimeType == elementType;
  }
}

class _ConfigFinder extends MatchFinder {
  _ConfigFinder(this.config);

  final Widget config;

  @override
  String get description => 'the given configuration ($config)';

  @override
  bool matches(Element candidate) {
    return candidate.widget == config;
  }
}

class _WidgetPredicateFinder extends MatchFinder {
  _WidgetPredicateFinder(this.predicate);

  final WidgetPredicate predicate;

  @override
  String get description => 'widget matching predicate ($predicate)';

  @override
  bool matches(Element candidate) {
    return predicate(candidate.widget);
  }
}

class _ElementPredicateFinder extends MatchFinder {
  _ElementPredicateFinder(this.predicate);

  final ElementPredicate predicate;

  @override
  String get description => 'element matching predicate ($predicate)';

  @override
  bool matches(Element candidate) {
    return predicate(candidate);
  }
}
