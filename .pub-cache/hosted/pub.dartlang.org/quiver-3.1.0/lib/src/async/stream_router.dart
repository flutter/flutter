// Copyright 2013 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';

/// Splits a [Stream] of events into multiple Streams based on a set of
/// predicates.
///
/// Using StreamRouter differs from [Stream.where] because events are only sent
/// to one Stream. If more than one predicate matches the event, the event is
/// sent to the stream created by the earlier call to [route]. Events not
/// matched by a call to [route] are sent to the [defaultStream].
///
/// Example:
///
///    import 'dart:html';
///    import 'package:quiver/async.dart';
///
///    var router = StreamRouter(window.onClick);
///    var onRightClick = router.route((e) => e.button == 2);
///    var onAltClick = router.route((e) => e.altKey);
///    var onOtherClick router.defaultStream;
class StreamRouter<T> {
  /// Create a new StreamRouter that listens to the [incoming] stream.
  StreamRouter(Stream<T> incoming) : _incoming = incoming {
    _subscription = _incoming.listen(_handle, onDone: close);
  }

  final Stream<T> _incoming;
  late final StreamSubscription<T> _subscription;

  final List<_Route<T>> _routes = <_Route<T>>[];
  final StreamController<T> _defaultController =
      StreamController<T>.broadcast();

  /// Events that match [predicate] are sent to the stream created by this
  /// method, and not sent to any other router streams.
  Stream<T> route(bool predicate(T event)) {
    var controller = StreamController<T>.broadcast();
    _routes.add(_Route(predicate, controller));
    return controller.stream;
  }

  Stream<T> get defaultStream => _defaultController.stream;

  Future close() {
    return Future.wait(_routes.map((r) => r.controller.close())).then((_) {
      _subscription.cancel();
    });
  }

  void _handle(T event) {
    StreamController<T> controller = _defaultController;
    for (final _Route<T> route in _routes) {
      if (route.predicate(event)) {
        controller = route.controller;
        break;
      }
    }
    controller.add(event);
  }
}

typedef _Predicate<T> = bool Function(T event);

class _Route<T> {
  _Route(this.predicate, this.controller);

  final _Predicate<T> predicate;
  final StreamController<T> controller;
}
