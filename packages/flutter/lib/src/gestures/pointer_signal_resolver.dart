// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'package:flutter/foundation.dart';

import 'events.dart';

/// The callback to register with a [PointerSignalResolver] to express
/// interest in a pointer signal event.
typedef PointerSignalResolvedCallback = void Function(PointerSignalEvent event);

bool _isSameEvent(PointerSignalEvent event1, PointerSignalEvent event2) {
  return (event1.original ?? event1) == (event2.original ?? event2);
}

/// Mediates disputes over which listener should handle pointer signal events
/// when multiple listeners wish to handle those events.
///
/// Pointer signals (such as [PointerScrollEvent]) are immediate, so unlike
/// events that participate in the gesture arena, pointer signals always
/// resolve at the end of event dispatch. Yet if objects interested in handling
/// these signal events were to handle them directly, it would cause issues
/// such as multiple [Scrollable] widgets in the widget hierarchy responding
/// to the same mouse wheel event. Using this class, these events will only
/// be dispatched to the the first registered handler, which will in turn
/// correspond to the widget that's deepest in the widget hierarchy.
///
/// To use this class, objects should register their event handler like so:
///
/// {@tool snippet}
/// ```dart
/// void handleSignalEvent(PointerSignalEvent event) {
///   GestureBinding.instance!.pointerSignalResolver.register(event, (PointerSignalEvent event) {
///     // handle the event...
///   });
/// }
/// ```
/// {@end-tool}
///
/// {@tool dartpad --template=stateful_widget_material}
/// Here is an example that demonstrates the effect of not using the resolver
/// versus using it.
///
/// When this example is set to _not_ use the resolver, then scrolling the
/// mouse wheel over the outer box will cause only the outer box to change
/// color, but scrolling the mouse wheel over inner box will cause _both_ the
/// outer and the inner boxes to change color (because they're both receiving
/// the scroll event).
///
/// When this excample is set to _use_ the resolver, then only the box located
/// directly under the cursor will change color when the mouse wheel is
/// scrolled.
///
/// ```dart imports
/// import 'package:flutter/gestures.dart';
/// ```
///
/// ```dart
/// HSVColor outerColor = const HSVColor.fromAHSV(0.2, 120.0, 1, 1);
/// HSVColor innerColor = const HSVColor.fromAHSV(1, 60.0, 1, 1);
/// bool useResolver = false;
///
/// void rotateOuterColor() {
///   setState(() {
///     outerColor = outerColor.withHue((outerColor.hue + 6) % 360.0);
///   });
/// }
///
/// void rotateInnerColor() {
///   setState(() {
///     innerColor = innerColor.withHue((innerColor.hue + 6) % 360.0);
///   });
/// }
///
/// @override
/// Widget build(BuildContext context) {
///   return Material(
///     child: Stack(
///       fit: StackFit.expand,
///       children: <Widget>[
///         Listener(
///           onPointerSignal: (PointerSignalEvent event) {
///             if (useResolver) {
///               GestureBinding.instance!.pointerSignalResolver.register(event, (PointerSignalEvent event) {
///                 rotateOuterColor();
///               });
///             } else {
///               rotateOuterColor();
///             }
///           },
///           child: DecoratedBox(
///             decoration: BoxDecoration(
///               border: const Border.fromBorderSide(BorderSide()),
///               color: outerColor.toColor(),
///             ),
///             child: FractionallySizedBox(
///               widthFactor: 0.5,
///               heightFactor: 0.5,
///               child: DecoratedBox(
///                 decoration: BoxDecoration(
///                   border: const Border.fromBorderSide(BorderSide()),
///                   color: innerColor.toColor(),
///                 ),
///                 child: Listener(
///                   onPointerSignal: (PointerSignalEvent event) {
///                     if (useResolver) {
///                       GestureBinding.instance!.pointerSignalResolver.register(event, (PointerSignalEvent event) {
///                         rotateInnerColor();
///                       });
///                     } else {
///                       rotateInnerColor();
///                     }
///                   },
///                   child: const AbsorbPointer(),
///                 ),
///               ),
///             ),
///           ),
///         ),
///         Align(
///           alignment: Alignment.topLeft,
///           child: Row(
///             crossAxisAlignment: CrossAxisAlignment.center,
///             children: <Widget>[
///               Switch(
///                 value: useResolver,
///                 onChanged: (bool value) {
///                   setState(() {
///                     useResolver = value;
///                   });
///                 },
///               ),
///               Text(
///                 'Use the PointerSignalResolver?',
///                 style: DefaultTextStyle.of(context).style.copyWith(fontWeight: FontWeight.bold),
///               ),
///             ],
///           ),
///         ),
///       ],
///     ),
///   );
/// }
/// ```
/// {@end-tool}
class PointerSignalResolver {
  PointerSignalResolvedCallback? _firstRegisteredCallback;

  PointerSignalEvent? _currentEvent;

  /// Registers interest in handling [event].
  ///
  /// See the documentation for the [PointerSignalResolver] class on when and
  /// how this method should be used.
  void register(PointerSignalEvent event, PointerSignalResolvedCallback callback) {
    assert(event != null);
    assert(callback != null);
    assert(_currentEvent == null || _isSameEvent(_currentEvent!, event));
    if (_firstRegisteredCallback != null) {
      return;
    }
    _currentEvent = event;
    _firstRegisteredCallback = callback;
  }

  /// Resolves the event, calling the first registered callback if there was
  /// one.
  ///
  /// This is called by the [GestureBinding] after the framework has finished
  /// dispatching the pointer signal event.
  void resolve(PointerSignalEvent event) {
    if (_firstRegisteredCallback == null) {
      assert(_currentEvent == null);
      return;
    }
    assert(_isSameEvent(_currentEvent!, event));
    try {
      _firstRegisteredCallback!(_currentEvent!);
    } catch (exception, stack) {
      InformationCollector? collector;
      assert(() {
        collector = () sync* {
          yield DiagnosticsProperty<PointerSignalEvent>('Event', event, style: DiagnosticsTreeStyle.errorProperty);
        };
        return true;
      }());
      FlutterError.reportError(FlutterErrorDetails(
        exception: exception,
        stack: stack,
        library: 'gesture library',
        context: ErrorDescription('while resolving a PointerSignalEvent'),
        informationCollector: collector
      ));
    }
    _firstRegisteredCallback = null;
    _currentEvent = null;
  }
}
