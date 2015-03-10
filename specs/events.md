Sky Event Model
===============

```dart
import 'dart:collection';
import 'dart:async';

class ExceptionAndStackTrace<T> {
  const ExceptionAndStackTrace(this.exception, this.stackTrace);
  final T exception;
  final StackTrace stackTrace;
}

class ExceptionListException<T> extends IterableMixin<ExceptionAndStackTrace<T>> implements Exception {
  List<ExceptionAndStackTrace<T>> _exceptions;
  void add(T exception, [StackTrace stackTrace = null]) {
    if (_exceptions == null)
      _exceptions = new List<ExceptionAndStackTrace<T>>();
    _exceptions.add(new ExceptionAndStackTrace<T>(exception, stackTrace));
  }
  int get length => _exceptions == null ? 0 : _exceptions.length;
  Iterator<ExceptionAndStackTrace<T>> get iterator => _exceptions.iterator;
}

typedef bool Filter<T>(T t);
typedef void Handler<T>(T t);

class DispatcherController<T> {
  DispatcherController() : dispatcher = new Dispatcher<T>();
  final Dispatcher<T> dispatcher;
  void add(T data) => dispatcher._add(data);
}

class Dispatcher<T> {
  List<Pair<Handler, ZoneUnaryCallback>> _listeners;
  void listen(Handler<T> handler) {
    // you should not throw out of this handler
    if (_listeners == null)
      _listeners = new List<Pair<Handler, ZoneUnaryCallback>>();
    _listeners.add(new Pair<Handler, ZoneUnaryCallback>(handler, Zone.current.bindUnaryCallback(handler)));
  }
  bool unlisten(Handler<T> handler) {
    if (_listeners == null)
      return false;
    var target = _listeners.lastWhere((v) => v.a == handler, orElse: () => null);
    if (target == null)
      return false;
    _listeners.removeAt(_listeners.lastIndexOf(target));
    return true;
  }
  void _add(T data) {
    if (_listeners == null)
      return;
    ExceptionListException exceptions = new ExceptionListException();
    // we make a copy of the list here so that the listeners can
    // mutate our list without worry
    _listeners.toList().forEach((Pair<Handler, ZoneUnaryCallback> item) {
      try {
        item.b(data);
      } catch (exception, stackTrace) {
        exceptions.add(exception, stackTrace);
      }
    });
    if (exceptions.length > 0)
      throw exceptions;
  }

  Dispatcher<T> where(Filter<T> filter) => new WhereDispatcher<T>(this, filter);

  Dispatcher<T> until(Filter<T> filter) {
    var subdispatcher = new Dispatcher<T>();
    Handler handler;
    handler = (T data) {
      if (filter(data))
        unlisten(handler);
      else
        subdispatcher._add(data);
    };
    listen(handler);
    return subdispatcher;
  }

  Future<T> firstWhere(Filter<T> filter) {
    Completer completer = new Completer();
    Handler handler;
    handler = (T data) {
      if (filter(data)) {
        completer.complete(data);
        unlisten(handler);
      }
    };
    listen(handler);
    return completer.future;
  }
}

class WhereDispatcher<T> extends Dispatcher {
  WhereDispatcher(this.parent, this.filter) : super();
  Dispatcher parent;
  Filter filter;

  void listen(Handler<T> handler) {
    if (_listeners == null || _listeners.length == 0)
      parent.listen(_handler);
    super.listen(handler);
  }
  bool unlisten(Handler<T> handler) {
    var result = super.unlisten(handler);
    if (result && _listeners.length == 0)
      parent.unlisten(_handler);
    return result;
  }
  void _handler(T data) {
    if (filter(data))
      _add(data);
  }
}

abstract class Event<ReturnType> {
  Event() { init(); }
  void init() { }

  bool get bubbles;

  EventTarget _target;
  EventTarget get target => _target;

  EventTarget _currentTarget;
  EventTarget get currentTarget => _currentTarget;

  bool handled; // precise semantics depend on the event type, but in general, set this when you set result
  ReturnType result;

  bool resultIsCompatible(dynamic candidate) => candidate is ReturnType;

  // TODO(ianh): abstract API for doing things at shadow tree boundaries 
  // TODO(ianh): do events get blocked at scope boundaries, e.g. focus events when both sides are in the scope?
  // TODO(ianh): do events get retargetted, e.g. focus when leaving a custom element?
  // e.g. sent from inside a shadow tree, when exiting the shadow tree, focus event should:
  //  - disappear if we're moving from one to another element
  //  - be targetted if it's going to another node in a different scope
}

class EventTarget {
  EventTarget() : _eventsController = new DispatcherController<Event>();

  Dispatcher get events => _eventsController.dispatcher;
  EventTarget get parentNode;

  List<EventTarget> getEventDispatchChain() {
    if (this.parentNode == null) {
      return [this];
    } else {
      var result = this.parentNode.getEventDispatchChain();
      result.insert(0, this);
      return result;
    }
  }

  final DispatcherController _eventsController;

  dynamic dispatchEvent(Event event, { dynamic defaultResult: null }) { // O(N*M) where N is the length of the chain and M is the average number of listeners per link in the chain
    // note: this will throw an ExceptionListException<ExceptionListException> if any of the listeners threw
    assert(event != null); // event must be non-null
    event.handled = false;
    assert(event.resultIsCompatible(defaultResult));
    event.result = defaultResult;
    event._target = this;
    var chain;
    if (event.bubbles)
      chain = this.getEventDispatchChain();
    else
      chain = [this];
    var exceptions = new ExceptionListException<ExceptionListException>();
    for (var link in chain) {
      try {
        link._dispatchEventLocally(event);
      } on ExceptionListException catch (e) {
        exceptions.add(e);
      }
    }
    if (exceptions.length > 0)
      throw exceptions;
    return event.result;
  }

  void _dispatchEventLocally(Event event) {
    event._currentTarget = this;
    _eventsController.add(event);
  }
}
```
