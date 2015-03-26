Effen (fn)
===

Effen is a prototype of a functional-reactive framework for sky which takes inspiration from [React](http://facebook.github.io/react/).

Effen is comprised of three main parts: a virtual-dom and diffing engine, a component mechanism and a very early set of widgets for use in creating applications.

The central idea is that you build your UI out of components. Components describe what their view should look like given their current configuration & state. The diffing engine ensures that the DOM looks how the component describes by applying minimal diffs to transition it from one state to the next.

If you just want to dive into code, see the [stocks example](../examples/stocks).


Hello World
-----------

To build an application, create a subclass of App and instantiate it.

```HTML
<!-- In hello.sky -->
<script>
import 'helloworld.dart';

main() {
  new HelloWorldApp();
}
</script>
```

```JavaScript
// In helloworld.dart
import '../fn/lib/fn.dart';

class HelloWorldApp extends App {
  Node build() {
    return new Text('Hello, World!');
  }
}
```
An app is comprised of (and is, itself, a) components. A component's main job is to implement `Node build()`. The idea here is that the `build` method describes the DOM of a component at any given point during its lifetime. In this case, our `HelloWorldApp`'s `build` method just returns a `Text` node which displays the obligatory line of text.

Nodes
-----
A component's `build` method must return a single `Node` which *may* have children (and so on, forming a *subtree*). Effen comes with a few built-in nodes which mirror the built-in nodes/elements of sky: `Text`, `Anchor` (`<a />`, `Image` (`<img />`) and `Container` (`<div />`). `build` can return a tree of Nodes comprised of any of these nodes and plus any other imported object which extends `Component`.

How to structure you app
------------------------
If you're familiar with React, the basic idea is the same: Application data flows *down* from components which have data to components & nodes which they construct via construction parameters. Generally speaking, View-Model data (data which is derived from *model* data, but exists only because the view needs it), is computed during the course of `build` and is short-lived, being handed into nodes & components as configuration data.

What does "data flowing down the tree" mean?
--------------------------------------------
Consider the case of a checkbox. (i.e. `widgets/checkbox.dart`). The `Checkbox` constructor looks like this:

```JavaScript
  ValueChanged onChanged;
  bool checked;

  Checkbox({ Object key, this.onChanged, this.checked }) : super(key: key);
```

What this means is that the `Checkbox` component is *never* "owns" the state of the checkbox. It's current state is handed into the `checked` parameter, and when a click occurs, the checkbox invokes its `onChanged` callback with the value it thinks it should be changed to -- but it never directly changes the value itself. This is a bit odd at first look, but if you think about it: a control isn't very useful unless it gets its value out to someone and if you think about databinding, the same thing happens: databinding basically tells a control to *treat some remote variable as its storage*. That's all that is happening here. In this case, some owning component probably has a set of values which describe a form.

Stateful vs. Stateless components
---------------------------------
All components have access to two kinds of state: (1) configuration data (constructor arguments) and (2) private data (data they mutate themselves). While react components have explicit property bags for these two kinds of state (`this.prop` and `this.state`), Effen maps these ideas to the public and private fields of the component. Constructor arguments should (by convention) be reflected as public fields of the component and state should only be set on private (with a leading underbar `_`) fields.

All (non-component) Effen nodes are stateless. Some components will be stateful. This state will likely encapsulate transient states of the UI, such as scroll position, animation state, uncommitted form values, etc...

A component can become stateful in two ways: (1) by passing `super(stateful: true)` to its call to the superclass's constructor, or by calling `setState(Function fn)`. The former is a way to have a component start its life stateful, and the latter results in the component becoming statefull *as well as* scheduling the component to re-build at the end of the current animation frame.

What does it mean to be stateful? It means that the diffing mechanism retains the specific *instance* of the component as long as the component which builds it continues to require its presence. The component which constructed it may have provided new configuration in form of different values for the constructor parameters, but these values (public fields) will be copied (using reflection) onto the retained instance whose privates fields are left unmodified.

Rendering
---------
At the end of each animation frame, all components (including the root `App`) which have `setState` on themselves will be rebuilt and the resulting changes will be minimally applied to the DOM. Note that components of lower "order" (those near the root of the tree) will build first because their building may require rebuilding of higher order (those near the leaves), thus avoiding the possibility that a component which is dirty build more than once during a single cycle.

Keys
----
In order to efficiently apply changes to the DOM and to ensure that stateful components are correctly identified, Effen requires that `no two nodes (except Text) or components of the same type may exist as children of another element without being distinguished by unique keys`. [`Text` is excused from this rule]. In many cases, nodes don't require a key because there is only one type amongst its siblings -- but if there is more one, you must assign each a key. This is why most nodes will take `({ Object key })` as an optional constructor parameter. In development mode (i.e. when sky is built `Debug`) Effen will throw an error if you forget to do this.

Event Handling
--------------
Events logically fire through the Effen node tree. If want to handle an event as it bubbles from the target to the root, create an `EventTarget`. `EventTarget` has named (typed) parameters for a small set of events that we've hit so far, as well as a 'custom' argument which is a `Map<String, sky.EventListener>`. If you'd like to add a type argument for an event, just post a patch.

```JavaScript
class MyComp extends Component {
  MyComp({
    Object key
  }) : super(key: key);

  void _handleClick(sky.GestureEvent e) {
    // do stuff
  }

  void _customEventCallback(sky.Event e) {
    // do other stuff
  }

  Node build() {
    new EventTarget(
      new Container(
        children: // ...
      ),
      onGestureTap: _handleClick,
      custom: {
        'myCustomEvent': _customEventCallback
      }
    );
  }

  _handleScroll(sky.Event e) {
    setState(() {
      // update the scroll position
    });
  }
}
```


Styling
-------
Styling is the part of Effen which is least designed and is likely to change. There are two ways to specify styles:

  * `Style` objects which are interned and can be applied to Elements via the `style` constructor parameter. Use `Style` objects for styles which are *not* animated.
  * An `inlineStyle` string which can be applied to Elements via the `inlineStyle` constructor parameter.  Use `inlineStyle` for styles which *are* animated.
  
If you need to apply a Style to a Component or Node which you didn't construct (i.e. one that was handed into your constructor), you can wrap it in a `StyleNode` which also takes a `Style` constructor in it's `style` constructor parameter.

Animation
---------
Animation is still an area of exploration. Have a look at [AnimatedComponent](components/animated_component.dart) and [Drawer](components/drawer.dart) for an example of this this currently works.

Performance
-----------
It is a design goal that it should be *possible* to arrange that all "build" cycles which happen during animations can complete in less than one milliesecond on a Nexus 5.


