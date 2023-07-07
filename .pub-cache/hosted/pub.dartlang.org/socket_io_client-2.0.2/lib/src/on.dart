// Copyright (C) 2017 Potix Corporation. All Rights Reserved
// History: 26/04/2017
// Author: jumperchen<jumperchen@potix.com>
import 'package:socket_io_common/src/util/event_emitter.dart';

///
/// Helper for subscriptions.
///
/// @param {Object|EventEmitter} obj with `Emitter` mixin or `EventEmitter`
/// @param {String} event name
/// @param {Function} callback
/// @api public
///
Destroyable on(EventEmitter obj, String ev, EventHandler fn) {
  obj.on(ev, fn);
  return Destroyable(() => obj.off(ev, fn));
}

class Destroyable {
  Function callback;
  Destroyable(this.callback);
  void destroy() => callback();
}
