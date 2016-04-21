// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:quiver/testing/async.dart';
import 'package:test/test.dart';

import 'element_tree_tester.dart';
import 'instrumentation.dart';

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

/// A convenient accessor to frequently used finders.
///
/// Examples:
///
///     tester.tap(find.text('Save'));
///     tester.widget(find.byType(MyWidget));
///     tester.stateOf(find.byConfig(config));
///     tester.getSize(find.byKey(new ValueKey('save-button')));
const CommonFinders find = const CommonFinders._();

/// Asserts that [finder] locates a widget in the test element tree.
///
/// Example:
///
///     expect(tester, hasWidget(find.text('Save')));
Matcher hasWidget(Finder finder) => new _HasWidgetMatcher(finder);

/// Opposite of [hasWidget].
Matcher doesNotHaveWidget(Finder finder) => new _DoesNotHaveWidgetMatcher(finder);

/// Class that programmatically interacts with widgets and the test environment.
class WidgetTester {
  WidgetTester._(this.elementTreeTester);

  /// Exposes the [Element] tree created from widgets.
  final ElementTreeTester elementTreeTester;

  WidgetFlutterBinding get binding => elementTreeTester.binding;

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
  ///
  /// See [ElementTreeTester.dispatchEvent] for details.
  void dispatchEvent(PointerEvent event, HitTestResult result) {
    elementTreeTester.dispatchEvent(event, result);
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
    return this.elementTreeTester.allElements
      .map((Element element) => element.widget);
  }

  /// Finds the first widget, searching in the depth-first traversal order.
  Widget widget(Finder finder) {
    return finder.findFirst(this).widget;
  }

  /// Finds the first state object, searching in the depth-first traversal order.
  State/*=T*/ stateOf/*<T extends State>*/(Finder finder) {
    Element element = finder.findFirst(this);
    Widget widget = element.widget;

    if (widget is StatefulWidget)
      return (element as StatefulElement).state;

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
}

/// Provides lightweight syntax for getting frequently used widget [Finder]s.
class CommonFinders {
  const CommonFinders._();

  /// Finds [Text] widgets containing string equal to [text].
  Finder text(String text) => new _TextFinder(text);

  /// Looks for widgets that contain [Text] with [text] in it.
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

  /// Finds widgets by [key].
  Finder byKey(Key key) => new _KeyFinder(key);

  /// Finds widgets by [type].
  Finder byType(Type type) => new _TypeFinder(type);

  /// Finds widgets equal to [config].
  Finder byConfig(Widget config) => new _ConfigFinder(config);

  /// Finds widgets using a [predicate].
  Finder byPredicate(WidgetPredicate predicate) {
    return new _ElementFinder((Element element) => predicate(element.widget));
  }

  /// Finds widgets using an element [predicate].
  Finder byElement(ElementPredicate predicate) => new _ElementFinder(predicate);
}

/// Finds [Element]s inside the element tree.
abstract class Finder {
  Iterable<Element> find(WidgetTester tester);

  /// Describes what the finder is looking for. The description should be such
  /// that [toString] reads as a descriptive English sentence.
  String get description;

  Element findFirst(WidgetTester tester) {
    Iterable<Element> results = find(tester);
    return results.isNotEmpty
      ? results.first
      : throw new ElementNotFoundError.fromFinder(this);
  }

  @override
  String toString() => 'widget with $description';
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
    return tester.elementTreeTester.findElements((Element element) {
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
    return tester.elementTreeTester.allElements
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
    return tester.elementTreeTester.findElements((Element element) => element.widget.key == key);
  }
}

class _TypeFinder extends Finder {
  _TypeFinder(this.widgetType);

  final Type widgetType;

  @override
  String get description => 'type "$widgetType"';

  @override
  Iterable<Element> find(WidgetTester tester) {
    return tester.elementTreeTester.allElements.where((Element element) {
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
    return tester.elementTreeTester.allElements.where((Element element) {
      return element.widget == config;
    });
  }
}

typedef bool WidgetPredicate(Widget element);
typedef bool ElementPredicate(Element element);

class _ElementFinder extends Finder {
  _ElementFinder(this.predicate);

  final ElementPredicate predicate;

  @override
  String get description => 'element satisfying given predicate ($predicate)';

  @override
  Iterable<Element> find(WidgetTester tester) {
    return tester.elementTreeTester.allElements.where(predicate);
  }
}

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
