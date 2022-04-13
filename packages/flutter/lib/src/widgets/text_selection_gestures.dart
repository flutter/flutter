import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

class TextSelectionGestures extends StatefulWidget {
  const TextSelectionGestures({
    Key? key,
    this.manager,
    required this.child,
    required this.gestures,
    this.behavior
  }) : super(key: key);

  TextSelectionGestures.platformDefaults({
    Key? key,
    TextSelectionGesturesManager? manager,
    required Widget child,
  }) : this(
    key: key,
    manager: manager,
    gestures: _defaultGestures,
    child: child,
  );

  final TextSelectionGesturesManager? manager;

  final Map<Type, ContextGestureRecognizerFactory> gestures;

  final Widget child;

  final HitTestBehavior? behavior;

  static TextSelectionGesturesManager of(BuildContext context) {
    assert(context != null);
    final _TextSelectionGesturesMarker? inherited = context.dependOnInheritedWidgetOfExactType<_TextSelectionGesturesMarker>();
    assert(() {
      if (inherited == null) {
        throw FlutterError(
            'Unable to find a TextSelectionGestures widget in the context.\n'
        );
      }
      return true;
    }());
    return inherited!.manager;
  }

  static final Map<Type, ContextGestureRecognizerFactory> _defaultGestures = {
    TapGestureRecognizer : ContextGestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
            (BuildContext context) => TapGestureRecognizer(debugOwner: context),
            (TapGestureRecognizer instance, BuildContext context) {
          instance
            ..onTapDown = (TapDownDetails details) {
              print('default');
              Actions.invoke(context, ExtendSelectionToLastTapDownPositionIntent(lastTapDownPosition: details.globalPosition, cause: SelectionChangedCause.tap));
            };
        }
    )
  };

  @override
  State<TextSelectionGestures> createState() => _TextSelectionGesturesState();
}

class _TextSelectionGesturesState extends State<TextSelectionGestures> {
  TextSelectionGesturesManager? _internalManager;
  TextSelectionGesturesManager get manager => widget.manager ?? _internalManager!;

  @override
  void initState() {
    super.initState();
    if (widget.manager == null) {
      _internalManager = TextSelectionGesturesManager();
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
    return _TextSelectionGesturesMarker(
      manager: manager,
      child: widget.child,
    );
  }
}

class TextSelectionGesturesManager extends ChangeNotifier {
  TextSelectionGesturesManager({
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

class LoggingTextSelectionGesturesManager extends TextSelectionGesturesManager {
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

class _TextSelectionGesturesMarker extends InheritedNotifier<TextSelectionGesturesManager> {
  const _TextSelectionGesturesMarker({
    required TextSelectionGesturesManager manager,
    required Widget child
  }) : super(notifier: manager, child: child);

  TextSelectionGesturesManager get manager => super.notifier!;
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