Effen (fn)
===

Effen is a prototype of a functional-reactive framework for sky which takes inspiration from [React](http://facebook.github.io/react/). The code as you see it here is a first-draft, is unreviewed, untested and will probably catch your house on fire. It is a proof of concept.

Effen is comprised of three main parts: a virtual-dom and diffing engine, a component mechanism and a very early set of widgets for use in creating applications.

If you just want to dive into code, see the `sky/examples/stocks-fn`.

Is this the official framework for Sky?
---------------------------------------
Nope, it's just an experiment. We're testing how well it works and how we like it.

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
  Node render() {
    return new Text('Hello, World!');
  }
}
```
An app is comprised of (and is, itself, a) components. A component's main job is to implement `Node render()`. The idea here is that the `render` method describes the DOM of a component at any given point during its lifetime. In this case, our `HelloWorldApp`'s `render` method just returns a `Text` node which displays the obligatory line of text.

Nodes
-----
A component's `render` method must return a single `Node` which *may* have children (and so on, forming a *subtree*). Effen comes with a few built-in nodes which mirror the built-in nodes/elements of sky: `Text`, `Anchor` (`<a />`, `Image` (`<img />`) and `Container` (`<div />`). `render` can return a tree of Nodes comprised of any of these nodes and plus any other imported object which extends `Component`.

How to structure you app
------------------------
If you're familiar with React, the basic idea is the same: Application data flows *down* from components which have data to components & nodes which they construct via construction parameters. Generally speaking, View-Model data (data which is derived from *model* data, but exists only because the view needs it), is computed during the course of `render` and is short-lived, being handed into nodes & components as configuration data.

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
All components have access to two kinds of state: (1) data which is handing in from their owner (the component which constructed them) and (2) data which they mutate themselves. While react components have explicit property bags for these two kinds of state (`this.prop` and `this.state`), Effen maps these ideas to the public and private fields of the component. Constructor arguments should (by convention) be reflected as public fields of the component and state should only be set on private (with a leading underbar `_`) fields.

All nodes and most components should be stateless, never needing to mutate themselves and only reacting to data which is handed into them. Some components will be stateful. This state will likely encapsulate transient states of the UI, such as scroll position, animation state, uncommitted form values, etc...

A component can become stateful in two ways: (1) by passing `super(stateful: true)` to its call to the superclasses constructor, or by calling `setState(Function fn)`. The former is a way to have a component start its life stateful, and the later results in the component becoming statefull *as well as* scheduling the component to re-render at the end of the current animation frame.

What does it mean to be stateful? It means that the diffing mechanism retains the specific *instance* of the component as long as the component which renders it continues to require its presence. The component which constructed it may have provided new configuration in form of different values for the constructor parameters, but these values (public fields) will be copied (using reflection) onto the retained instance whose privates fields are left unmodified.

Rendering
---------
At the end of each animation frame, all components (including the root `App`) which have `setState` on themselves will be re-rendered and the resulting changes will be minimally applied to the DOM. Note that components of lower "order" (those near the root of the tree) will render first because their rendering may require re-rendering of higher order (those near the leaves), thus avoiding the possibility that a component which is dirty render more than once during a single cycle.

Keys
----
In order to efficiently apply changes to the DOM and to ensure that stateful components are correctly identified, Effen requires that `no two nodes (except Text) or components of the same type may exist as children of another element without being distinguished by unique keys`. [`Text` is excused from this rule]. In many cases, nodes don't require a key because there is only one type amongst its siblings -- but if there is more one, you must assign each a key. This is why most nodes will take `({ Object key })` as an optional constructor parameter. In development mode (i.e. when sky is built `Debug`) Effen will throw an error if you forget to do this.

Event Handling
--------------
To handle an event is to receive a callback. All elements, (e.g. `Container`, `Anchor`, and `Image`) have optional named constructor arguments named `on*` whose type is function that takes a single `sky.Event` as a parameter. To handle an event, implement a callback on your component and pass it to the appropriate node. If you need to expose the event callback to an owner component, just pipe it through your constructor arguments:

```JavaScript
class MyComp extends Component {
  MyComp({
    Object key,
    sky.EventListener onClick // delegated handler
  }) : super(key: key);
  
  Node render() {
    return new Container(
      onClick: onClick,
      onScrollStart: _handleScroll // direct handler
    );
  }

  _handleScroll(sky.Event e) {
    setState(() {
      // update the scroll position
    });
  }
}
```

*Note: Only a subset of the events defined in sky are currently exposed on Element. If you need one which isn't present, feel free to post a patch which adds it.*

Styling
-------
Styling is the part of Effen which is least designed and is likely to change. At the moment, there are two ways to apply style to an element: (1) by handing a `Style` object to the `style` constructor parameter, or by passing a `String` to the `inlineStyle` constructor parameter. Both take a string of CSS, but the construction of a `Style` object presently causes a new `<style />` element to be created at the document level which can quickly be applied to components by Effen setting their class -- while inlineStyle does what you would expect.

`Style` objects are for most styling which is static and `inlineStyle`s are for styling which is dynamic (e.g. `display: ` or `transform: translate*()` which may change as a result of animating of transient UI state).

Animation
---------
Animation is still an area of exploration. The pattern which is presently used in the `stocks-fn` example is the following: Components which are animatable should contain within their implementation file an Animation object whose job it is to react to events and control an animation by exposing one or more Dart `stream`s of data. The `Animation` object is owned by the owner (or someone even higher) and the stream is passed into the animating component via its constructor. The first time the component renders, it listens on the stream and calls `setState` on itself for each value which emerges from the stream [See the `drawer.dart` widget for an example].

Performance
-----------
Isn't diffing the DOM expensive? This is kind of a subject question with a few answers, but the biggest issue is what do you mean by "fast"?

The stock answer is that diffing the DOM is fast because you compute the diff of the current VDOM from the previous VDOM and only apply the diffs to the actual DOM. The truth that this is fast, but not really fast enough to re-render everything on the screen for 60 or 120fps animations on a mobile device.

The answer that many people don't get is that there are really two logical types of renders: (1) When underlying model data changes: This generally requires handing in new data to the root component (in Effen, this means the `App` calling `setState` on itself). (2) When user interaction updates a control or an animation takes place. (1) is generally more expensive because it requires a full rendering & diff, but tends to happen infrequently. (2) tends to happen frequently, but at nodes which are near the leafs of the tree, so the number of nodes which must be reconsiled is generally small.

React provides a way to manually insist that a componet not re-render based on its old and new state (and they encourage the use of immutable data structures because discovering the data is the same can be accomplished with a reference comparison). A similar mechanism is in the works for Effen.

Lastly, Effen does something unique: Because its diffing is component-wise, it can be smart about not forcing the re-render of components which are handed in as *arguments* when only the component itself is dirty. For example, the `drawer.dart` component knows how to animate out & back and expose a content pane -- but it takes its content pane as an argument. When the animation mutates the inlineStyle of the `Drawer`'s `Container`, it must schedule itself for re-render -- but -- because the content was handed in to its constructor, its configuration can't have changed and Effen doesn't require it to re-render.

It is a design goal that it should be *possible* to arrange that all "render" cycles which happen during animations can complete in less than one milliesecond on a Nexus 5.


