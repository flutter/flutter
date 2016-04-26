// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:quiver/testing/async.dart';
import 'package:test/test.dart';

import 'binding.dart';
import 'test_pointer.dart';

/// Signature for [CommonFinders.byPredicate].
typedef bool WidgetPredicate(Widget widget);

/// Signature for [CommonFinders.byElement].
typedef bool ElementPredicate(Element element);

/// Runs the [callback] inside the Flutter test environment.
///
/// Use this function for testing custom [StatelessWidget]s and
/// [StatefulWidget]s.
///
/// Example:
///
///     test('MyWidget', () {
///        testWidgets((WidgetTester tester) {
///          tester.pumpWidget(new MyWidget());
///          tester.tap(find.text('Save'));
///          expect(tester, hasWidget(find.text('Success')));
///        });
///     });
void testWidgets(void callback(WidgetTester widgetTester)) {
  testElementTree((ElementTreeTester elementTreeTester) {
    callback(new WidgetTester._(elementTreeTester));
  });
}

/// Class that programmatically interacts with widgets and the test environment.
class WidgetTester {
  WidgetTester._(this.elementTreeTester);

  /// Exposes the [Element] tree created from widgets.
  final ElementTreeTester elementTreeTester;

  /// The binding instance that the widget tester is using when it
  /// needs a binding (e.g. for event dispatch).
  WidgetsBinding get binding => elementTreeTester.binding;

  /// Renders the UI from the given [widget].
  ///
  /// See [ElementTreeTester.pumpWidget] for details.
  void pumpWidget(Widget widget, [ Duration duration, EnginePhase phase ]) {
    elementTreeTester.pumpWidget(widget, duration, phase);
  }

  /// Triggers a sequence of frames for [duration] amount of time.
  ///
  /// See [ElementTreeTester.pump] for details.
  void pump([ Duration duration, EnginePhase phase ]) {
    elementTreeTester.pump(duration, phase);
  }

  /// Changes the current locale.
  ///
  /// See [ElementTreeTester.setLocale] for details.
  void setLocale(String languageCode, String countryCode) {
    elementTreeTester.setLocale(languageCode, countryCode);
  }

  /// Sends an [event] at [result] location.
  void dispatchEvent(PointerEvent event, HitTestResult result) {
    binding.dispatchEvent(event, result);
  }

  /// Returns the exception most recently caught by the Flutter framework.
  ///
  /// See [ElementTreeTester.takeException] for details.
  dynamic takeException() {
    return elementTreeTester.takeException();
  }

  /// Returns the fake implmentation of the event loop used by the test
  /// environment.
  ///
  /// Use it to travel into the future without actually waiting, control the
  /// flushing of microtasks and timers.
  FakeAsync get async => elementTreeTester.async;

  /// Runs all remaining microtasks, including those scheduled as a result of
  /// running them, until there are no more microtasks scheduled.
  ///
  /// Does not run timers. May result in an infinite loop or run out of memory
  /// if microtasks continue to recursively schedule new microtasks.
  void flushMicrotasks() {
    elementTreeTester.async.flushMicrotasks();
  }

  /// Checks if the element identified by [finder] exists in the tree.
  bool exists(Finder finder) => finder.find(this).isNotEmpty;

  /// All widgets currently live on the UI returned in a depth-first traversal
  /// order.
  Iterable<Widget> get widgets {
    return this.allElements.map((Element element) => element.widget);
  }

  /// Finds the first widget, searching in the depth-first traversal order.
  Widget widget(Finder finder) {
    return finder.findFirst(this).widget;
  }

  /// Finds the first state object, searching in the depth-first traversal order.
  State/*=T*/ stateOf/*<T extends State>*/(Finder finder) {
    Element element = finder.findFirst(this);
    Widget widget = element.widget;

    if (widget is StatefulWidget) {
      StatefulElement statefulElement = element;
      return statefulElement.state;
    }

    throw new ElementNotFoundError(
      'Widget of type ${widget.runtimeType} found by ${finder.description} does not correspond to a StatefulWidget'
    );
  }

  /// Finds the [Element] corresponding to the first widget found by [finder],
  /// searching in the depth-first traversal order.
  Element elementOf(Finder finder) => finder.findFirst(this);

  /// Finds the [RenderObject] corresponding to the first widget found by
  /// [finder], searching in the depth-first traversal order.
  RenderObject renderObjectOf(Finder finder) => finder.findFirst(this).findRenderObject();

  /// Emulates a tapping action at the center of the widget found by [finder].
  void tap(Finder finder, { int pointer: 1 }) {
    tapAt(getCenter(finder), pointer: pointer);
  }

  /// Emulates a tapping action at the given [location].
  ///
  /// See [ElementTreeTester.tapAt] for details.
  void tapAt(Point location, { int pointer: 1 }) {
    elementTreeTester.tapAt(location, pointer: pointer);
  }

  /// Scrolls by dragging the center of a widget found by [finder] by [offset].
  void scroll(Finder finder, Offset offset, { int pointer: 1 }) {
    scrollAt(getCenter(finder), offset, pointer: pointer);
  }

  /// Scrolls by dragging the screen at [startLocation] by [offset].
  ///
  /// See [ElementTreeTester.scrollAt] for details.
  void scrollAt(Point startLocation, Offset offset, { int pointer: 1 }) {
    elementTreeTester.scrollAt(startLocation, offset, pointer: pointer);
  }

  /// Attempts a fling gesture starting at the center of a widget found by
  /// [finder].
  ///
  /// See also [flingFrom].
  void fling(Finder finder, Offset offset, double velocity, { int pointer: 1 }) {
    flingFrom(getCenter(finder), offset, velocity, pointer: pointer);
  }

  /// Attempts a fling gesture starting at [startLocation], moving by [offset]
  /// with the given [velocity].
  ///
  /// See [ElementTreeTester.flingFrom] for details.
  void flingFrom(Point startLocation, Offset offset, double velocity, { int pointer: 1 }) {
    elementTreeTester.flingFrom(startLocation, offset, velocity, pointer: pointer);
  }

  /// Begins a gesture at a particular point, and returns the
  /// [TestGesture] object which you can use to continue the gesture.
  TestGesture startGesture(Point downLocation, { int pointer: 1 }) {
    return elementTreeTester.startGesture(downLocation, pointer: pointer);
  }

  /// Returns the size of the element corresponding to the widget located by
  /// [finder].
  ///
  /// This is only valid once the element's render object has been laid out at
  /// least once.
  Size getSize(Finder finder) {
    assert(finder != null);
    Element element = finder.findFirst(this);
    return elementTreeTester.getSize(element);
  }

  /// Returns the point at the center of the widget found by [finder].
  Point getCenter(Finder finder) {
    Element element = finder.findFirst(this);
    return elementTreeTester.getCenter(element);
  }

  /// Returns the point at the top left of the given element.
  Point getTopLeft(Finder finder) {
    Element element = finder.findFirst(this);
    return elementTreeTester.getTopLeft(element);
  }

  /// Returns the point at the top right of the given element. This
  /// point is not inside the object's hit test area.
  Point getTopRight(Finder finder) {
    Element element = finder.findFirst(this);
    return elementTreeTester.getTopRight(element);
  }

  /// Returns the point at the bottom left of the given element. This
  /// point is not inside the object's hit test area.
  Point getBottomLeft(Finder finder) {
    Element element = finder.findFirst(this);
    return elementTreeTester.getBottomLeft(element);
  }

  /// Returns the point at the bottom right of the given element. This
  /// point is not inside the object's hit test area.
  Point getBottomRight(Finder finder) {
    Element element = finder.findFirst(this);
    return elementTreeTester.getBottomRight(element);
  }

  /// Returns all elements ordered in a depth-first traversal fashion.
  ///
  /// The returned iterable is lazy. It does not walk the entire element tree
  /// immediately, but rather a chunk at a time as the iteration progresses
  /// using [Iterator.moveNext].
  Iterable<Element> get allElements {
    return new _DepthFirstChildIterable(binding.renderViewElement);
  }
}

class _DepthFirstChildIterable extends IterableBase<Element> {
  _DepthFirstChildIterable(this.rootElement);

  Element rootElement;

  @override
  Iterator<Element> get iterator => new _DepthFirstChildIterator(rootElement);
}

class _DepthFirstChildIterator implements Iterator<Element> {
  _DepthFirstChildIterator(Element rootElement)
      : _stack = _reverseChildrenOf(rootElement).toList();

  Element _current;

  final List<Element> _stack;

  @override
  Element get current => _current;

  @override
  bool moveNext() {
    if (_stack.isEmpty)
      return false;

    _current = _stack.removeLast();
    // Stack children in reverse order to traverse first branch first
    _stack.addAll(_reverseChildrenOf(_current));

    return true;
  }

  static Iterable<Element> _reverseChildrenOf(Element element) {
    final List<Element> children = <Element>[];
    element.visitChildren(children.add);
    return children.reversed;
  }
}

/// A convenient accessor to frequently used finders.
///
/// Examples:
///
///     tester.tap(find.text('Save'));
///     tester.widget(find.byType(MyWidget));
///     tester.stateOf(find.byConfig(config));
///     tester.getSize(find.byKey(new ValueKey('save-button')));
const CommonFinders find = const CommonFinders._();

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
  Finder widgetWithText(Type widgetType, String text) => new _WidgetWithTextFinder(widgetType, text);

  /// Finds widgets by searching for one with a particular [Key].
  ///
  /// Example:
  ///
  ///     expect(tester, hasWidget(find.byKey(backKey)));
  Finder byKey(Key key) => new _KeyFinder(key);

  /// Finds widgets by searching for widgets with a particular type.
  ///
  /// The `type` argument must be a subclass of [Widget].
  ///
  /// Example:
  ///
  ///     expect(tester, hasWidget(find.byType(IconButton)));
  Finder byType(Type type) => new _TypeFinder(type);

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
  Finder byWidgetPredicate(WidgetPredicate predicate) => new _WidgetPredicateFinder(predicate);

  /// Finds widgets using an element predicate.
  ///
  /// Example:
  ///
  ///     expect(tester, hasWidget(find.byWidgetPredicate(
  ///       (Element element) => element is SingleChildRenderObjectElement
  ///     )));
  Finder byElementPredicate(ElementPredicate predicate) => new _ElementPredicateFinder(predicate);
}

/// Finds [Element]s inside the element tree.
abstract class Finder {
  /// Returns all the elements that match this finder's pattern,
  /// using the given tester to determine which element tree to look at.
  Iterable<Element> find(WidgetTester tester);

  /// Describes what the finder is looking for. The description should be
  /// a brief English noun phrase describing the finder's pattern.
  String get description;

  /// Returns the first value returned from [find], unless no value is found,
  /// in which case it throws an [ElementNotFoundError].
  Element findFirst(WidgetTester tester) {
    Iterable<Element> results = find(tester);
    return results.isNotEmpty
      ? results.first
      : throw new ElementNotFoundError.fromFinder(this);
  }

  @override
  String toString() => '[Finder for $description]';
}

/// Indicates that an attempt to find a widget within the current element tree
/// failed.
class ElementNotFoundError extends Error {
  ElementNotFoundError(this.message);

  ElementNotFoundError.fromFinder(Finder finder)
      : message = 'Element not found by ${finder.description}';

  final String message;

  @override
  String toString() => 'ElementNotFoundError: $message';
}

class _TextFinder extends Finder {
  _TextFinder(this.text);

  final String text;

  @override
  String get description => 'text "$text"';

  @override
  Iterable<Element> find(WidgetTester tester) {
    return tester.allElements.where((Element element) {
      if (element.widget is! Text)
        return false;
      Text textWidget = element.widget;
      return textWidget.data == text;
    });
  }
}

class _WidgetWithTextFinder extends Finder {
  _WidgetWithTextFinder(this.widgetType, this.text);

  final Type widgetType;
  final String text;

  @override
  String get description => 'type $widgetType with text "$text"';

  @override
  Iterable<Element> find(WidgetTester tester) {
    return tester.allElements
      .map((Element textElement) {
        if (textElement.widget is! Text)
          return null;

        Text textWidget = textElement.widget;
        if (textWidget.data == text) {
          Element parent;
          textElement.visitAncestorElements((Element element) {
            if (element.widget.runtimeType == widgetType) {
              parent = element;
              return false;
            }
            return true;
          });
          return parent;
        }

        return null;
      })
      .where((Element element) => element != null);
  }
}

class _KeyFinder extends Finder {
  _KeyFinder(this.key);

  final Key key;

  @override
  String get description => 'key $key';

  @override
  Iterable<Element> find(WidgetTester tester) {
    return tester.allElements.where((Element element) {
      return element.widget.key == key;
    });
  }
}

class _TypeFinder extends Finder {
  _TypeFinder(this.widgetType);

  final Type widgetType;

  @override
  String get description => 'type "$widgetType"';

  @override
  Iterable<Element> find(WidgetTester tester) {
    return tester.allElements.where((Element element) {
      return element.widget.runtimeType == widgetType;
    });
  }
}

class _ConfigFinder extends Finder {
  _ConfigFinder(this.config);

  final Widget config;

  @override
  String get description => 'the given configuration ($config)';

  @override
  Iterable<Element> find(WidgetTester tester) {
    return tester.allElements.where((Element element) {
      return element.widget == config;
    });
  }
}

class _WidgetPredicateFinder extends Finder {
  _WidgetPredicateFinder(this.predicate);

  final WidgetPredicate predicate;

  @override
  String get description => 'widget predicate ($predicate)';

  @override
  Iterable<Element> find(WidgetTester tester) {
    return tester.allElements.where((Element element) {
      return predicate(element.widget);
    });
  }
}

class _ElementPredicateFinder extends Finder {
  _ElementPredicateFinder(this.predicate);

  final ElementPredicate predicate;

  @override
  String get description => 'element predicate ($predicate)';

  @override
  Iterable<Element> find(WidgetTester tester) {
    return tester.allElements.where(predicate);
  }
}

/// Asserts that [finder] locates a widget in the test element tree.
///
/// Example:
///
///     expect(tester, hasWidget(find.text('Save')));
Matcher hasWidget(Finder finder) => new _HasWidgetMatcher(finder);

class _HasWidgetMatcher extends Matcher {
  const _HasWidgetMatcher(this.finder);

  final Finder finder;

  @override
  bool matches(WidgetTester tester, Map<dynamic, dynamic> matchState) {
    return tester.exists(finder);
  }

  @override
  Description describe(Description description) {
    return description.add('$finder exists in the element tree');
  }

  @override
  Description describeMismatch(
      dynamic item, Description mismatchDescription, Map<dynamic, dynamic> matchState, bool verbose) {
    return mismatchDescription.add('Does not contain $finder');
  }
}

/// Asserts that [finder] does not locate a widget in the test element tree.
/// Opposite of [hasWidget].
///
/// Example:
///
///     expect(tester, doesNotHaveWidget(find.text('Save')));
Matcher doesNotHaveWidget(Finder finder) => new _DoesNotHaveWidgetMatcher(finder);

class _DoesNotHaveWidgetMatcher extends Matcher {
  const _DoesNotHaveWidgetMatcher(this.finder);

  final Finder finder;

  @override
  bool matches(WidgetTester tester, Map<dynamic, dynamic> matchState) {
    return !tester.exists(finder);
  }

  @override
  Description describe(Description description) {
    return description.add('$finder does not exist in the element tree');
  }

  @override
  Description describeMismatch(
      dynamic item, Description mismatchDescription, Map<dynamic, dynamic> matchState, bool verbose) {
    return mismatchDescription.add('Contains $finder');
  }
}
