Sky Widgets
===========

Sky widgets are built using a functional-reactive framework, which takes
inspiration from [React](http://facebook.github.io/react/). The central idea is
that you build your UI out of components. Components describe what their view
should look like given their current configuration and state. When a component's
state changes, the component rebuilds its description, which the framework diffs
against the previous description in order to determine the minial changes needed
in the underlying render tree to transition from one state to the next.

Hello World
-----------

To build an application, create a subclass of App and instantiate it:

```dart
import 'package:sky/widgets/basic.dart';

class HelloWorldApp extends App {
  Widget build() {
    return new Text('Hello, world!');
  }
}

void main() {
  new HelloWorldApp();
}
```

An app is comprised of (and is, itself, a) widgets. The most commonly authored
widgets are, like `App`, subclasses of `Component`.  A component's main job is
to implement `Widget build()` by returning newly-created instances of other
widgets. If a component builds other components, the framework will build those
components in turn until the process bottoms out in a collection of basic
widgets, such as those in `sky/widgets/basic.dart`. In the case of
`HelloWorldApp`, the `build` function simply returns a new `Text` node, which is
a basic widget representing a string of text.

Basic Widgets
-------------

Sky comes with a suite of powerful basic widgets, of which the following are
very commonly used:

 * `Text`. The `Text` widget lets you create a run of styled text within your
   application.

 * `Flex`. The `Flex` widget lets you create flexible layouts in both the
   horizontal and vertical direction. Its design is based on the web's flexbox
   layout model. You can also use the simpler `Block` widget to create vertical
   layouts of inflexible items.

 * `Container`. The `Container` widget lets you create rectangular visual
   element. A container can be decorated with a `BoxDecoration`, such as a
   background, a border, or a shadow. A `Container` can also have margins,
   padding, and constraints applied to its size. In addition, a `Container` can
   be transformed in three dimensional space using a matrix.

 * `Image`. The `Image` widget lets you display an image, referenced using a
   URL. The underlying image is cached, which means if several `Image` widgets
   refer to the same URL, they'll share the underlying image resource.

Below is a simple toolbar example that shows how to combine these widgets:

```dart
import 'package:sky/widgets/basic.dart';

class MyToolBar extends Component {
  Widget build() {
    return new Container(
      child: new Flex([
        new Image(src: 'menu.png', size: const Size(25.0, 25.0)),
        new Flexible(child: new Text('My awesome toolbar')),
        new Image(src: 'search.png', size: const Size(25.0, 25.0)),
      ]),
      height: 56.0,
      padding: new EdgeDims.symmetric(horizontal: 8.0),
      decoration: const BoxDecoration(
        backgroundColor: const Color(0xFF00FFFF),
      )
    );
  }
}
```

The `MyToolBar` component creates a cyan `Container` with a height of 56
device-independent pixels with an internal padding of 8 pixels, both on the
left and the right. Inside the container, `MyToolBar` uses a `Flex` layout
in the (default) horizontal direction. The middle child, the `Text` widget, is
marked as `Flexible`, which means it expands to fill any remaining available
space that hasn't been consumed by the inflexible children. You can have
multiple `Flexible` children and determine the ratio in which they consume the
available space using the `flex` argument to `Flexible`.

To use this component, we simply create an instance of `MyToolBar` in a `build`
function:

```dart
import 'package:sky/widgets/basic.dart';

import `my_tool_bar.dart';

class DemoApp extends App {
  Widget build() {
    return new Center(child: new MyToolBar());
  }
}

void main() {
  new DemoApp();
}
```

Here, we've used the `Center` widget to center the toolbar within the view, both
vertically and horizontally. Because the toolbar uses a flexible layout
internally, it expands to fill all the available horizontal space.

Listening to Events
-------------------

In addition to being stunningly beautiful, most applications react to user
input. The first step in building an interactive application is to listen for
input events. Let's see how that works by creating a simple button:

```dart
import 'package:sky/widgets/basic.dart';

final BoxDecoration _decoration = new BoxDecoration(
  borderRadius: 5.0,
  gradient: new LinearGradient(
    endPoints: [ Point.origin, new Point(0.0, 36.0) ],
    colors: [ const Color(0xFFEEEEEE), const Color(0xFFCCCCCC) ]
  )
);

class MyButton extends Component {
  Widget build() {
    return new Listener(
      child: new Container(
        child: new Center(
          child: new Text('Engage')
        ),
        height: 36.0,
        padding: new EdgeDims.all(8.0),
        margin: new EdgeDims.symmetric(horizontal: 8.0),
        decoration: _decoration
      ),
      onGestureTap: (event) {
        print('MyButton was tapped!');
      }
    );
  }
}
```

The `Listener` widget doesn't have an visual representation but instead listens
for events bubbling through the application. When a tap gesture bubbles out from
the `Container`, the `Listener` will call its `onGestureTap` callback, in this
case printing a message to the console.

You can use `Listener` to listen for a variety of input events, including
low-level pointer events and higher-level gesture events, such as taps, scrolls,
and flings.

Generic Components
------------------

One of the most powerful features of components is the ability to pass around
references to already-built widgets and reuse them in your `build` function. For
example, we wouldn't want to define a new button component every time we wanted
a button with a novel label:

```dart
class MyButton extends Component {
  MyButton({ this.child, this.onPressed });

  final Widget child;
  final Function onPressed;

  Widget build() {
    return new Listener(
      child: new Container(
        child: new Center(child: child),
        height: 36.0,
        padding: new EdgeDims.all(8.0),
        margin: new EdgeDims.symmetric(horizontal: 8.0),
        decoration: _decoration
      ),
      onGestureTap: (_) {
        if (onPressed != null)
          onPressed();
      }
    );
  }
}
```

Rather than providing the button's label as a `String`, we've let the code that
uses `MyButton` provide an arbitrary `Widget` to put inside the button. For
example, we can put an elaborate layout involving text and an image inside the
button:

```dart
  Widget build() {
    return new MyButton(
      child: new ShrinkWrapWidth(
        child: new Flex([
          new Image(src: 'thumbs-up.png', size: const Size(25.0, 25.0)),
          new Container(
            child: new Text('Thumbs up'),
            padding: new EdgeDims.only(left: 10.0)
          )
        ])
      )
    );
  }
```

State
-----

TODO(abarth)
