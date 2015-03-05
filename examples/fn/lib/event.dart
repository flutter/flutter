// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of fn;

class EventHandler {
  final String type;
  final sky.EventListener listener;

  EventHandler(this.type, this.listener);
}

class EventMap {
  final List<EventHandler> _handlers = new List<EventHandler>();

  void listen(String type, sky.EventListener listener) {
    assert(listener != null);
    _handlers.add(new EventHandler(type, listener));
  }

  void addAll(EventMap events) {
    _handlers.addAll(events._handlers);
  }
}
