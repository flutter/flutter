import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

class SelectionGestures extends StatefulWidget {
  const SelectionGestures({
    super.key,
    this.manager,
    required this.child,
    required this.gestures,
    this.behavior
  });

  final SelectionGesturesManager? manager;

  final Map<Type, ContextGestureRecognizerFactory> gestures;

  final Widget child;

  final HitTestBehavior? behavior;

  static SelectionGesturesManager of(BuildContext context) {
    assert(context != null);
    final _SelectionGesturesMarker? inherited = context.dependOnInheritedWidgetOfExactType<_SelectionGesturesMarker>();
    assert(() {
      if (inherited == null) {
        throw FlutterError(
            'Unable to find a SelectionGestures widget in the context.\n'
        );
      }
      return true;
    }());
    return inherited!.manager;
  }

  @override
  State<SelectionGestures> createState() => _SelectionGesturesState();
}

class _SelectionGesturesState extends State<SelectionGestures> {
  SelectionGesturesManager? _internalManager;
  SelectionGesturesManager get manager => widget.manager ?? _internalManager!;

  @override
  void initState() {
    super.initState();
    if (widget.manager == null) {
      _internalManager = SelectionGesturesManager();
    }
    manager.gestures = widget.gestures;
  }

  @override
  void dispose() {
    _internalManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SelectionGesturesMarker(
      manager: manager,
      child: widget.child,
    );
  }
}

class SelectionGesturesManager extends ChangeNotifier {
  SelectionGesturesManager({
    Map<Type, ContextGestureRecognizerFactory> gestures = const <Type, ContextGestureRecognizerFactory>{},
  })  : assert(gestures != null),
        _gestures = gestures;
  
  Map<Type, ContextGestureRecognizerFactory> _gestures = <Type, ContextGestureRecognizerFactory>{};
  Map<Type, ContextGestureRecognizerFactory> get gestures => _gestures;
  set gestures(Map<Type, ContextGestureRecognizerFactory> gestures) {
    _gestures = gestures;
  }
 
  @protected
  void handlePointerDown(BuildContext context, PointerDownEvent event, Map<Type, GestureRecognizer> recognizers) {
    for (final GestureRecognizer recognizer in recognizers.values) {
      recognizer.addPointer(event);
    }
  }
}

class _SelectionGesturesMarker extends InheritedNotifier<SelectionGesturesManager> {
  const _SelectionGesturesMarker({
    required SelectionGesturesManager manager,
    required Widget child
  }) : super(notifier: manager, child: child);

  SelectionGesturesManager get manager => super.notifier!;
}

typedef ContextGestureRecognizerFactoryConstructor<T extends GestureRecognizer> = T Function(BuildContext context);

typedef ContextGestureRecognizerFactoryInitializer<T extends GestureRecognizer> = void Function(T instance, BuildContext context);

class ContextGestureRecognizerFactoryWithHandlers<T extends GestureRecognizer> extends ContextGestureRecognizerFactory<T> {
  /// Creates a gesture recognizer factory with the given callbacks.
  ///
  /// The arguments must not be null.
  const ContextGestureRecognizerFactoryWithHandlers(this._constructor, this._initializer)
      : assert(_constructor != null),
        assert(_initializer != null);

  final ContextGestureRecognizerFactoryConstructor<T> _constructor;

  final ContextGestureRecognizerFactoryInitializer<T> _initializer;

  @override
  T constructor(BuildContext context) => _constructor(context);

  @override
  void initializer(T instance, BuildContext context) => _initializer(instance, context);
}

@optionalTypeArgs
abstract class ContextGestureRecognizerFactory<T extends GestureRecognizer> {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const ContextGestureRecognizerFactory();

  /// Must return an instance of T.
  T constructor(BuildContext context);

  /// Must configure the given instance (which will have been created by
  /// `constructor`).
  ///
  /// This normally means setting the callbacks.
  void initializer(T instance, BuildContext context);

  bool _debugAssertTypeMatches(Type type) {
    assert(type == T, 'ContextGestureRecognizerFactory of type $T was used where type $type was specified.');
    return true;
  }
}

/// Custom [SelectionGesturesManager] example, that logs the [PointerEvent]s.
class LoggingSelectionGesturesManager extends SelectionGesturesManager {
  @override
  void handlePointerDown(BuildContext context, PointerDownEvent event, Map<Type, GestureRecognizer> recognizers) {
    for(GestureRecognizer recognizer in recognizers.values) {
      if (recognizer.isPointerAllowed(event)) {
        print('Handled text selection gesture $recognizer $event in $context');
      }
    }
    super.handlePointerDown(context, event, recognizers);
  }
}