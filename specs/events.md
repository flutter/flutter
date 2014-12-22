Sky Event Model
===============

```javascript
  // EVENTS

  class Event {
    constructor (String type, Boolean bubbles = true, any data = null); // O(1)
    readonly attribute String type; // O(1)
    readonly attribute Boolean bubbles; // O(1)
    attribute any data; // O(1)

    readonly attribute EventTarget target; // O(1)
    attribute Boolean handled; // O(1)
    attribute any result; // O(1)

    // TODO(ianh): do events get blocked at scope boundaries, e.g. focus events when both sides are in the scope?
    // TODO(ianh): do events get retargetted, e.g. focus when leaving a custom element?
  }

  callback EventListener any (Event event);
    // if the return value is not undefined:
    //   assign it to event.result
    //   set event.handled to true

  abstract class EventTarget {
    any dispatchEvent(Event event); // O(N) in total number of listeners for this type in the chain
      // sets event.handled to false and event.result to undefined
      // makes a record of the event target chain by calling getEventDispatchChain()
      // invokes all the handlers on the chain in turn
      // returns event.result
    virtual Array<EventTarget> getEventDispatchChain(); // O(1) // returns []
    void addEventListener(String type, EventListener listener); // O(1)
    void removeEventListener(String type, EventListener listener); // O(N) in event listeners with that type
    private Array<String> getRegisteredEventListenerTypes(); // O(N)
    private Array<EventListener> getRegisteredEventListenersForType(String type); // O(N)
  }

  class CustomEventTarget : EventTarget { // implemented in JS
    constructor (); // O(1)
    attribute EventTarget parentNode; // getter O(1), setter O(N) in height of tree, throws if this would make a loop

    virtual Array<EventTarget> getEventDispatchChain(); // O(N) in height of tree // implements EventTarget.getEventDispatchChain()
      // let result = [];
      // let node = this;
      // while (node) {
      //   result.push(node);
      //   node = node.parentNode;
      // }
      // return result;

    // you can inherit from this to make your object into an event target
    // or you can inherit from EventTarget and implement your own getEventDispatchChain()
  }
```
