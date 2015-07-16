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
  runApp(new HelloWorldApp());
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

 * `Text`: The `Text` widget lets you create a run of styled text within your
   application.

 * `Flex`: The `Flex` widget lets you create flexible layouts in both the
   horizontal and vertical direction. Its design is based on the web's flexbox
   layout model. You can also use the simpler `Block` widget to create vertical
   layouts of inflexible items.

 * `Container`: The `Container` widget lets you create rectangular visual
   element. A container can be decorated with a `BoxDecoration`, such as a
   background, a border, or a shadow. A `Container` can also have margins,
   padding, and constraints applied to its size. In addition, a `Container` can
   be transformed in three dimensional space using a matrix.

 * `Image`: The `Image` widget lets you display an image, referenced using a
   URL. The underlying image is cached, which means if several `Image` widgets
   refer to the same URL, they'll share the underlying image resource.

Below is a simple toolbar example that shows how to combine these widgets:

```dart
import 'package:sky/widgets/basic.dart';

class MyToolBar extends Component {
  Widget build() {
    return new Container(
      decoration: const BoxDecoration(
        backgroundColor: const Color(0xFF00FFFF)
      ),
      height: 56.0,
      padding: const EdgeDims.symmetric(horizontal: 8.0),
      child: new Flex([
        new Image(src: 'menu.png', size: const Size(25.0, 25.0)),
        new Flexible(child: new Text('My awesome toolbar')),
        new Image(src: 'search.png', size: const Size(25.0, 25.0)),
      ])
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

import 'my_tool_bar.dart';

class DemoApp extends App {
  Widget build() {
    return new Center(child: new MyToolBar());
  }
}

void main() {
  runApp(new DemoApp());
}
```

Here, we've used the `Center` widget to center the toolbar within the view, both
vertically and horizontally. If we didn't center the toolbar, it would fill the
view, both vertically and horizontally, because the root widget is sized to fill
the view.

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
    endPoints: [ Point.origin, const Point(0.0, 36.0) ],
    colors: [ const Color(0xFFEEEEEE), const Color(0xFFCCCCCC) ]
  )
);

class MyButton extends Component {
  Widget build() {
    return new Listener(
      onGestureTap: (event) {
        print('MyButton was tapped!');
      },
      child: new Container(
        height: 36.0,
        padding: const EdgeDims.all(8.0),
        margin: const EdgeDims.symmetric(horizontal: 8.0),
        decoration: _decoration,
        child: new Center(
          child: new Text('Engage')
        )
      )
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
      onGestureTap: (_) {
        if (onPressed != null)
          onPressed();
      },
      child: new Container(
        height: 36.0,
        padding: const EdgeDims.all(8.0),
        margin: const EdgeDims.symmetric(horizontal: 8.0),
        decoration: _decoration,
        child: new Center(child: child)
      )
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
            padding: const EdgeDims.only(left: 10.0),
            child: new Text('Thumbs up')
          )
        ])
      )
    );
  }
```

State
-----

By default, components are stateless. Components usually receive
arguments from their parent component in their constructor, which they typically
store in `final` member variables. When a component is asked to `build`, it uses
these stored values to derive new arguments for the subcomponents it creates.
For example, the generic version of `MyButton` above follows this pattern. In
this way, state naturally flows "down" the component hierachy.

Some components, however, have mutable state that represents the transient state
of that part of the user interface. For example, consider a dialog widget with
a checkbox. While the dialog is open, the user might check and uncheck the
checkbox several times before closing the dialog and committing the final value
of the checkbox to the underlying application data model.

```dart
class MyCheckbox extends Component {
  MyCheckbox({ this.value, this.onChanged });

  final bool value;
  final Function onChanged;

  Widget build() {
    Color color = value ? const Color(0xFF00FF00) : const Color(0xFF0000FF);
    return new Listener(
      onGestureTap: (_) => onChanged(!value),
      child: new Container(
        height: 25.0,
        width: 25.0,
        decoration: new BoxDecoration(backgroundColor: color)
      )
    );
  }
}

class MyDialog extends StatefulComponent {
  MyDialog({ this.onDismissed });

  Function onDismissed;
  bool _checkboxValue = false;

  void _handleCheckboxValueChanged(bool value) {
    setState(() {
      _checkboxValue = value;
    });
  }

  void syncFields(MyDialog source) {
    onDismissed = source.onDismissed;
  }

  Widget build() {
    return new Flex([
      new MyCheckbox(
        value: _checkboxValue,
        onChanged: _handleCheckboxValueChanged
      ),
      new MyButton(
        onPressed: () => onDismissed(_checkboxValue),
        child: new Text("Save")
      ),
    ],
    justifyContent: FlexJustifyContent.center);
  }
}
```

The `MyCheckbox` component follows the pattern for stateless components. It
stores the values it receives in its constructor in `final` member variables,
which it then uses during its `build` function. Notice that when the user taps
on the checkbox, the checkbox itself doesn't use `value`. Instead, the checkbox
calls a function it received from its parent component. This pattern lets you
store state higher in the component hierarchy, which causes the state to persist
for longer periods of time. In the extreme, the state stored on the `App`
component persists for the lifetime of the application.

The `MyDialog` component is more complicated because it is a stateful component.
Let's walk through the differences in `MyDialog` caused by its being stateful:

 * `MyDialog` extends StatefulComponent instead of Component.

 * `MyDialog` has non-`final` member variables. Over the lifetime of the dialog,
   we'll need to modify the values of these member variables, which means we
   cannot mark them `final`.

 * `MyDialog` has private member variables. By convention, components store
   values they receive from their parent in public member variables and store
   their own internal, transient state in private member variables. There's no
   requirement to follow this convention, but we've found that it helps keep us
   organized.

 * Whenever `MyDialog` modifies its transient state, the dialog does so inside
   a `setState` callback. Using `setState` is important because it marks the
   component as dirty and schedules it to be rebuilt. If a component modifies
   its transient state outside of a `setState` callback, the framework won't
   know that the component has changed state and might not call the component's
   `build` function, which means the user interface might not update to reflect
   the changed state.

 * `MyDialog` implements the `syncFields` member function. To understand
   `syncFields`, we'll need to dive a bit deeper into how the `build` function
   is used by the framework.

   A component's `build` function returns a tree of widgets that represent a
   "virtual" description of its appearance. The first time the framework calls
   `build`, the framework walks this description and creates a "physical" tree
   of `RenderObjects` that matches the description. When the framework calls
   `build` again, the component still returns a fresh description of its
   appearence, but this time the framework compares the new description with the
   previous description and makes the minimal modifications to the underlying
   `RenderObjects` to make them match the new description.

   In this process, old stateless components are discarded and the new stateless
   components created by the parent component are retained in the widget
   hierchy. Old _stateful_ components, however, cannot simply be discarded
   because they contain state that needs to be preserved. Instead, the old
   stateful components are retained in the widget hierarchy and asked to
   `syncFields` with the new instance of the component created by the parent in
   its `build` function.

   Without `syncFields`, the new values the parent component passed to the
   `MyDialog` constructor in the parent's `build` function would be lost because
   they would be stored only as member variables on the new instance of the
   component, which is not retained in the component hiearchy. Therefore, the
   `syncFields` function in a component should update `this` to account for the
   new values the parent passed to `source` because `source` is the authorative
   source of those values.

   By convention, components typically store the values they receive from their
   parents in public member variables and their own internal state in private
   member variables. Therefore, a typical `syncFields` implementation will copy
   the public, but not the private, member variables from `source`. When
   following this convention, there is no need to copy over the private member
   variables because those represent the internal state of the object and `this`
   is the authoritative source of that state.

   When implementing a `StatefulComponent`, make sure to call
   `super.syncFields(source)` from within your `syncFields()` method,
   unless you are extending `StatefulComponent` directly.

Finally, when the user taps on the "Save" button, `MyDialog` follows the same
pattern as `MyCheckbox` and calls a function passed in by its parent component
to return the final value of the checkbox up the hierarchy.

didMount and didUnmount
-----------------------

When a component is inserted into the widget tree, the framework calls the
`didMount` function on the component. When a component is removed from the
widget tree, the framework calls the `didUnmount` function on the component.
In some situations, a component that has been unmounted might again be mounted.
For example, a stateful component might receive a pre-built component from its
parent (similar to `child` from the `MyButton` example above) that the stateful
component might incorporate, then not incorporate, and then later incorporate
again in the widget tree it builds, according to its changing state.

Typically, a stateful component will override `didMount` to initialize any
non-trivial internal state. Initializing internal state in `didMount` is more
efficient (and less error-prone) than initializing that state during the
component's constructor because parent executes the component's constructor each
time the parent rebuilds even though the framework mounts only the first
instance into the widget heiarchy. (Instead of mounting later instances, the
framework passes them to the original instance in `syncFields` so that the first
instance of the component can incorporate the values passed by the parent to the
component's constructor.)

Components often override `didUnmount` to release resources or to cancel
subscriptions to event streams from outside the widget hierachy. When overriding
either `didMount` or `didUnmount`, a component should call its superclass's
`didMount` or `didUnmount` function.

initState
---------

The framework calls the `initState` function on stateful components before
building them. The default implementation of initState does nothing. If your
component requires non-trivial work to initialize its state, you should
override initState and do it there rather than doing it in the stateful
component's constructor. If the component doesn't need to be built (for
example, if it was constructed just to have its fields synchronized with
an existing stateful component) you'll avoid unnecessary work. Also, some
operations that involve interacting with the widget hierarchy cannot be
done in a component's constructor.

When overriding `initState`, a component should call its superclass's 
`initState` function.

Keys
----

If a component requires fine-grained control over which widgets sync with each
other, the component can assign keys to the widgets it builds. Without keys, the
framework matches widgets in the current and previous build according to their
`runtimeType` and the order in which they appear. With keys, the framework
requires that the two widgets have the same `key` as well as the same
`runtimeType`.

Keys are most useful in components that build many instances of the same type of
widget. For example, consider an infinite list component that builds just enough
copies of a particular widget to fill its visible region:

 * Without keys, the first entry in the current build would always sync with the
   first entry in the previous build, even if, semantically, the first entry in
   the list just scrolled off screen and is no longer visible in the viewport.

 * By assigning each entry in the list a "semantic" key, the infinite list can
   be more efficient because the framework will sync entries with matching
   semantic keys and therefore similiar (or identical) visual appearances.
   Moreover, syncing the entries semantically means that state retained in
   stateful subcomponents will remain attached to the same semantic entry rather
   than the entry in the same numerical position in the viewport.

Useful debugging tools
----------------------

This is a quick way to dump the entire widget tree to the console.
This can be quite useful in figuring out exactly what is going on when
working with the widgets system. For this to work, you have to have
launched your app with `runApp()`.

```dart
import 'package:sky/widget/widget.dart';

debugDumpApp();
```

Dependencies
------------

 * `package:vector_math`
 * [`package:sky/animation`](../animation)
 * [`package:sky/base`](../base)
 * [`package:sky/painting`](../painting)
 * [`package:sky/rendering`](../rendering)
 * [`package:sky/theme`](../theme)
