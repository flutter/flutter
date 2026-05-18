// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/widgets.dart';
///
/// @docImport 'binding.dart';
library;

import 'package:flutter/foundation.dart';

import 'events.dart';

export 'events.dart' show PointerSignalEvent;

/// The callback to register with a [PointerSignalResolver] to express
/// interest in a pointer signal event.
typedef PointerSignalResolvedCallback = void Function(PointerSignalEvent event);

bool _isSameEvent(PointerSignalEvent event1, PointerSignalEvent event2) {
  return (event1.original ?? event1) == (event2.original ?? event2);
}

class _Registration {
  const _Registration({required this.callback, this.key});

  final PointerSignalResolvedCallback callback;
  final Object? key;
}

/// Mediates disputes over which listener should handle pointer signal events
/// when multiple listeners wish to handle those events.
///
/// Pointer signals (such as [PointerScrollEvent]) are immediate, so unlike
/// events that participate in the gesture arena, pointer signals always
/// resolve at the end of event dispatch. Yet if objects interested in handling
/// these signal events were to handle them directly, it would cause issues
/// such as multiple [Scrollable] widgets in the widget hierarchy responding
/// to the same mouse wheel event. Using this class, these events can be
/// dispatched to multiple handlers, each identified by an optional [key].
///
/// To use this class, objects should register their event handler like so:
///
/// ```dart
/// void handleSignalEvent(PointerSignalEvent event) {
///   GestureBinding.instance.pointerSignalResolver.register(event, (PointerSignalEvent event) {
///     // handle the event...
///   });
/// }
/// ```
///
/// When multiple callbacks are registered for the same event, only one per
/// distinct `key` is kept. The deepest widget with a given key receives the
/// event. When callbacks with different keys are registered, the resolver
/// gives priority to the **outermost** (last-registered) key. This ensures
/// that a diagonal trackpad gesture over nested perpendicular scrollables
/// (e.g. a horizontal [CarouselView] inside a vertical [ListView]) scrolls
/// only the outer scrollable, matching user expectations for two-finger
/// diagonal scrolling.
///
/// {@tool dartpad}
/// Here is an example that demonstrates the effect of not using the resolver
/// versus using it.
///
/// When this example is set to _not_ use the resolver, then triggering the
/// mouse wheel over the outer box will cause only the outer box to change
/// color, but triggering the mouse wheel over the inner box will cause _both_
/// the outer and the inner boxes to change color (because they're both
/// receiving the event).
///
/// When this example is set to _use_ the resolver, then only the box located
/// directly under the cursor will change color when the mouse wheel is
/// triggered.
///
/// ** See code in examples/api/lib/gestures/pointer_signal_resolver/pointer_signal_resolver.0.dart **
/// {@end-tool}
class PointerSignalResolver {
  PointerSignalEvent? _currentEvent;
  final List<_Registration> _registrations = <_Registration>[];

  /// Registers interest in handling [event].
  ///
  /// This method may be called multiple times (typically from different parts
  /// of the widget hierarchy) for the same `event`, with different `callback`s,
  /// as the event is being dispatched across the tree. Once the dispatching is
  /// complete, the [GestureBinding] calls [resolve], and callbacks are invoked
  /// with the **outermost** (last-registered) key winning when keys differ.
  ///
  /// An optional [key] can be provided for deduplication. When a registration
  /// with the same `key` already exists, the new registration is ignored. This
  /// allows multiple scrollables on the same axis to be deduplicated (only the
  /// deepest one handles the event) while scrollables on different axes each
  /// receive the event.
  ///
  /// The `callback` is invoked with one argument, the `event`.
  ///
  /// Once the [register] method has been called with a particular `event`, it
  /// must not be called for other `event`s until after [resolve] has been
  /// called. Only one event disambiguation can be in flight at a time. In
  /// normal use this is achieved by only registering callbacks for an event as
  /// it is actively being dispatched (for example, in
  /// [Listener.onPointerSignal]).
  ///
  /// See the documentation for the [PointerSignalResolver] class for an example
  /// of using this method.
  void register(PointerSignalEvent event, PointerSignalResolvedCallback callback, {Object? key}) {
    assert(_currentEvent == null || _isSameEvent(_currentEvent!, event));
    _currentEvent ??= event;
    // Only keep one registration per key (or one key-less registration).
    if (_registrations.any((_Registration r) => r.key == key)) {
      return;
    }
    _registrations.add(_Registration(callback: callback, key: key));
  }

  /// Resolves the event, calling all registered callbacks.
  ///
  /// This is called by the [GestureBinding] after the framework has finished
  /// dispatching the pointer signal event. All callbacks previously registered
  /// via [register] are called in registration order. If at least one callback
  /// was registered, [PointerSignalEvent.respond] is called with
  /// `allowPlatformDefault: false` to prevent the platform from performing
  /// default actions. Otherwise, `respond(true)` is called to allow the
  /// platform default.
  @pragma('vm:notify-debugger-on-exception')
  void resolve(PointerSignalEvent event) {
    if (_registrations.isEmpty) {
      assert(_currentEvent == null);
      _currentEvent = null;
      event.respond(allowPlatformDefault: true);
      return;
    }
    assert(_isSameEvent(_currentEvent!, event));
    final PointerSignalEvent registeredEvent = _currentEvent!;
    final List<_Registration> registrations = List<_Registration>.of(_registrations);
    _registrations.clear();
    _currentEvent = null;
    Object? winningKey;
    for (final _Registration reg in registrations.reversed) {
      if (winningKey != null && reg.key != null && reg.key != winningKey) {
        continue;
      }
      try {
        reg.callback(registeredEvent);
        if (winningKey == null) {
          winningKey = reg.key;
        }
      } catch (exception, stack) {
        InformationCollector? collector;
        assert(() {
          collector = () => <DiagnosticsNode>[
            DiagnosticsProperty<PointerSignalEvent>(
              'Event',
              event,
              style: DiagnosticsTreeStyle.errorProperty,
            ),
          ];
          return true;
        }());
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: exception,
            stack: stack,
            library: 'gesture library',
            context: ErrorDescription('while resolving a PointerSignalEvent'),
            informationCollector: collector,
          ),
        );
      }
    }
    event.respond(allowPlatformDefault: false);
  }
}
