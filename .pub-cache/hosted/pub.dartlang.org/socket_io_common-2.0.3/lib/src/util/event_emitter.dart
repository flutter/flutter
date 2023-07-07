/**
 * event_emitter.dart
 *
 * Purpose:
 *
 * Description:
 *
 * History:
 *     11/23/2016, Created by Henri Chen<henrichen@potix.com>
 *
 * Copyright (C) 2016 Potix Corporation. All Rights Reserved.
 */
import 'dart:collection' show HashMap;

/**
 * Handler type for handling the event emitted by an [EventEmitter].
 */
typedef dynamic EventHandler<T>(T data);

/**
 * Handler type for handling the event emitted by an [AnyEventHandler].
 */
typedef dynamic AnyEventHandler<T>(String event, T data);

/**
 * Generic event emitting and handling.
 */
class EventEmitter {
  /**
   * Mapping of events to a list of event handlers
   */
  Map<String, List<EventHandler>> _events =
      new HashMap<String, List<EventHandler>>();

  /**
   * Mapping of events to a list of one-time event handlers
   */
  Map<String, List<EventHandler>> _eventsOnce =
      new HashMap<String, List<EventHandler>>();

  /**
   * List of handlers that listen every event
   */
  List<AnyEventHandler> _eventsAny = [];

  /**
   * Constructor
   */
  EventEmitter();

  /**
   * This function triggers all the handlers currently listening
   * to [event] and passes them [data].
   */
  void emit(String event, [dynamic data]) {
    final list0 = this._events[event];
    // todo: try to optimize this. Maybe remember the off() handlers and remove later?
    // handler might be off() inside handler; make a copy first
    final list = list0 != null ? new List.from(list0) : null;
    list?.forEach((handler) {
      handler(data);
    });

    this._eventsOnce.remove(event)?.forEach((EventHandler handler) {
      handler(data);
    });

    this._eventsAny.forEach((AnyEventHandler handler) {
      handler(event, data);
    });
  }

  /**
   * This function binds the [handler] as a listener to the [event]
   */
  void on(String event, EventHandler handler) {
    this._events.putIfAbsent(event, () => <EventHandler>[]);
    this._events[event]!.add(handler);
  }

  /**
   * This function binds the [handler] as a listener to the first
   * occurrence of the [event]. When [handler] is called once,
   * it is removed.
   */
  void once(String event, EventHandler handler) {
    this._eventsOnce.putIfAbsent(event, () => <EventHandler>[]);
    this._eventsOnce[event]!.add(handler);
  }

  /**
   * This function binds the [handler] as a listener to any event
   */
  void onAny(AnyEventHandler handler) {
    this._eventsAny.add(handler);
  }

  /**
   * This function attempts to unbind the [handler] from the [event]
   */
  void off(String event, [EventHandler? handler]) {
    if (handler != null) {
      this._events[event]?.remove(handler);
      this._eventsOnce[event]?.remove(handler);
      if (this._events[event]?.isEmpty == true) {
        this._events.remove(event);
      }
      if (this._eventsOnce[event]?.isEmpty == true) {
        this._eventsOnce.remove(event);
      }
    } else {
      this._events.remove(event);
      this._eventsOnce.remove(event);
    }
  }

  /**
   * This function attempts to unbind the [handler].
   * If the given [handler] is null, this function unbinds all any event handlers.
   */
  void offAny([AnyEventHandler? handler]) {
    if (handler != null) {
      this._eventsAny.remove(handler);
    } else {
      this._eventsAny.clear();
    }
  }

  /**
   * This function unbinds all the handlers for all the events.
   */
  void clearListeners() {
    this._events = new HashMap<String, List<EventHandler>>();
    this._eventsOnce = new HashMap<String, List<EventHandler>>();
    this._eventsAny.clear();
  }

  /**
   * Returns whether the event has registered.
   */
  bool hasListeners(String event) {
    return this._events[event]?.isNotEmpty == true ||
        this._eventsOnce[event]?.isNotEmpty == true;
  }
}
