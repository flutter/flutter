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
/// ```dart
/// void handleSignalEvent(PointerSignalEvent event) {
///   GestureBinding.instance!.pointerSignalResolver.register(event, (PointerSignalEvent event) {
///     // handle the event...
///   });
/// }
/// ```
///
/// {@tool dartpad --template=stateful_widget_material}
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
/// ```dart imports
/// import 'package:flutter/gestures.dart';
/// ```
///
/// ```dart preamble
/// class ColorChanger extends StatefulWidget {
///   const ColorChanger({
///     Key? key,
///     required this.initialColor,
///     required this.useResolver,
///     this.child,
///   }) : super(key: key);
///
///   final HSVColor initialColor;
///   final bool useResolver;
///   final Widget? child;
///
///   @override
///   _ColorChangerState createState() => _ColorChangerState();
/// }
///
/// class _ColorChangerState extends State<ColorChanger> {
///   late HSVColor color;
///
///   void rotateColor() {
///     setState(() {
///       color = color.withHue((color.hue + 3) % 360.0);
///     });
///   }
///
///   @override
///   void initState() {
///     super.initState();
///     color = widget.initialColor;
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return DecoratedBox(
///       decoration: BoxDecoration(
///         border: const Border.fromBorderSide(BorderSide()),
///         color: color.toColor(),
///       ),
///       child: Listener(
///         onPointerSignal: (PointerSignalEvent event) {
///           if (widget.useResolver) {
///             GestureBinding.instance!.pointerSignalResolver.register(event, (PointerSignalEvent event) {
///               rotateColor();
///             });
///           } else {
///             rotateColor();
///           }
///         },
///         child: Stack(
///           fit: StackFit.expand,
///           children: <Widget>[
///             const AbsorbPointer(),
///             if (widget.child != null) widget.child!,
///           ],
///         ),
///       ),
///     );
///   }
/// }
/// ```
///
/// ```dart
/// bool useResolver = false;
///
/// @override
/// Widget build(BuildContext context) {
///   return Material(
///     child: Stack(
///       fit: StackFit.expand,
///       children: <Widget>[
///         ColorChanger(
///           initialColor: const HSVColor.fromAHSV(0.2, 120.0, 1, 1),
///           useResolver: useResolver,
///           child: FractionallySizedBox(
///             widthFactor: 0.5,
///             heightFactor: 0.5,
///             child: ColorChanger(
///               initialColor: const HSVColor.fromAHSV(1, 60.0, 1, 1),
///               useResolver: useResolver,
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
///               const Text(
///                 'Use the PointerSignalResolver?',
///                 style: TextStyle(fontWeight: FontWeight.bold),
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
        informationCollector: collector,
      ));
    }
    _firstRegisteredCallback = null;
    _currentEvent = null;
  }
}
