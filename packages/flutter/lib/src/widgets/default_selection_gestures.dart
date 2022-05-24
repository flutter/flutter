import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import 'actions.dart';
import 'framework.dart';
import 'text_editing_intents.dart';
import 'selection_gestures.dart';

class DefaultSelectionGestures extends StatelessWidget {
  const DefaultSelectionGestures({
    super.key,
    required this.child,
  });

  final Widget child;

  static bool get _isShiftPressed {
    return HardwareKeyboard.instance.logicalKeysPressed
        .any(<LogicalKeyboardKey>{
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.shiftRight,
    }.contains);
  }

  static final ContextGestureRecognizerFactoryWithHandlers<TapGestureRecognizer> _iOSMacTapGestureRecognizer = ContextGestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          (BuildContext context) => TapGestureRecognizer(debugOwner: context),
          (TapGestureRecognizer instance, BuildContext context) {
        instance
          ..onSecondaryTapUp = (TapUpDetails details) {
            print('onSecondaryTapUp');
            Actions.invoke(context, SelectRangeIntent(cause: SelectionChangedCause.tap, from: details.globalPosition));
            Actions.invoke(context, SelectionToolbarControlIntent.hide);
            Actions.invoke(context, SelectionToolbarControlIntent.show);
          }
          ..onSecondaryTap = () {
            print('onSecondaryTap');
          }
          ..onSecondaryTapDown = (TapDownDetails details) {
            print('onSecondaryTapDown');
          }
          ..onTapDown = (TapDownDetails details) {
            print('onTapDown');
            Actions.invoke(context, ExpandSelectionToPositionIntent(cause: SelectionChangedCause.tap, position: details.globalPosition, shiftPressed: _isShiftPressed));
          }
          ..onTapUp = (TapUpDetails details) {
            print('onTapUp');
            switch (details.kind) {
              case PointerDeviceKind.mouse:
              case PointerDeviceKind.stylus:
              case PointerDeviceKind.invertedStylus:
              // Precise devices should place the cursor at a precise position.
                Actions.invoke(context, SelectTapPositionIntent(cause: SelectionChangedCause.tap, from: details.globalPosition));
                break;
              case PointerDeviceKind.touch:
              case PointerDeviceKind.unknown:
              default: // ignore: no_default_cases, to allow adding new device types to [PointerDeviceKind]
              // TODO(moffatman): Remove after landing https://github.com/flutter/flutter/issues/23604
              // On macOS/iOS/iPadOS a touch tap places the cursor at the edge
              // of the word.
                Actions.invoke(context, SelectWordEdgeIntent(cause: SelectionChangedCause.tap, position: details.globalPosition));
                break;
            }
          }
          ..onTapCancel = () {
            print('onTapCancel');
          };
      }
  );

  static final ContextGestureRecognizerFactoryWithHandlers<PanGestureRecognizer> _iOSMacPanGestureRecognizer = ContextGestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
          (BuildContext context) => PanGestureRecognizer(debugOwner: context, supportedDevices: <PointerDeviceKind>{ PointerDeviceKind.mouse }),
          (PanGestureRecognizer instance, BuildContext context) {
            instance
              ..dragStartBehavior = DragStartBehavior.down
              ..onStart = (DragStartDetails details) {
                print('onDragStart');
                Actions.invoke(context, ExpandSelectionToPositionIntent(cause: SelectionChangedCause.drag, position: details.globalPosition, shiftPressed: true));
              }
              ..onUpdate = (DragUpdateDetails details) {
                print('onDragUpdate');
                Actions.invoke(context, ExpandSelectionToPositionIntent(cause: SelectionChangedCause.drag, position: details.globalPosition, shiftPressed: true));
              }
              ..onEnd = (DragEndDetails details) {
                print('onDragEnd');
              };
          }
  );

  static final Map<Type, ContextGestureRecognizerFactory> _commonGestures = {
    TapGestureRecognizer : ContextGestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
            (BuildContext context) => TapGestureRecognizer(debugOwner: context),
            (TapGestureRecognizer instance, BuildContext context) {
          instance
            ..onSecondaryTap = () {
            }
            ..onSecondaryTapDown = (TapDownDetails details) {}
            ..onTapDown = (TapDownDetails details) {
              Actions.invoke(context, ExtendSelectionToPositionIntent(cause: SelectionChangedCause.tap, position: details.globalPosition, shiftPressed: _isShiftPressed));
            }
            ..onTapUp = (TapUpDetails details) {

            }
            ..onTapCancel = () {};
        }
    ),
    LongPressGestureRecognizer : ContextGestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
            (BuildContext context) => LongPressGestureRecognizer(debugOwner: context, supportedDevices: <PointerDeviceKind>{ PointerDeviceKind.touch }),
            (LongPressGestureRecognizer instance, BuildContext context) {
          instance
            ..onLongPressStart = (LongPressStartDetails details) {
              // Actions.invoke(
              //   context,
              //   SelectTextAtPositionIntent(
              //
              //     cause: SelectionChangedCause.longpress,
              //   ),
              // );
            }
            ..onLongPressMoveUpdate = (LongPressMoveUpdateDetails details) {}
            ..onLongPressEnd = (LongPressEndDetails details) {};
        }
    ),
    PanGestureRecognizer : ContextGestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
            (BuildContext context) => PanGestureRecognizer(debugOwner: context, supportedDevices: <PointerDeviceKind>{ PointerDeviceKind.mouse }),
            (PanGestureRecognizer instance, BuildContext context) {
          instance
            ..dragStartBehavior = DragStartBehavior.down
            ..onStart = (DragStartDetails details) {}
            ..onUpdate = (DragUpdateDetails details) {}
            ..onEnd = (DragEndDetails details) {};
        }
    ),
    ForcePressGestureRecognizer : ContextGestureRecognizerFactoryWithHandlers<ForcePressGestureRecognizer>(
            (BuildContext context) => ForcePressGestureRecognizer(debugOwner: context),
            (ForcePressGestureRecognizer instance, BuildContext context) {
          instance
            ..onStart = (ForcePressDetails details) {}
            ..onEnd = (ForcePressDetails details) {};
        }
    ),
  };

  static final Map<Type, ContextGestureRecognizerFactory> _androidGestures = _commonGestures;
  static final Map<Type, ContextGestureRecognizerFactory> _fuchsiaGestures = _commonGestures;
  static final Map<Type, ContextGestureRecognizerFactory> _iOSGestures = <Type, ContextGestureRecognizerFactory>{
    TapGestureRecognizer : _iOSMacTapGestureRecognizer,
    PanGestureRecognizer : _iOSMacPanGestureRecognizer,
  };
  static final Map<Type, ContextGestureRecognizerFactory> _linuxGestures = _commonGestures;
  static final Map<Type, ContextGestureRecognizerFactory> _macGestures = _commonGestures;
  static final Map<Type, ContextGestureRecognizerFactory> _windowsGestures = _commonGestures;
  static final Map<Type, ContextGestureRecognizerFactory> _webGestures = _commonGestures;

  static Map<Type, ContextGestureRecognizerFactory> get _defaultGestures {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return _iOSGestures;
      case TargetPlatform.android:
        return _androidGestures;
      case TargetPlatform.fuchsia:
        return _fuchsiaGestures;
      case TargetPlatform.linux:
        return _linuxGestures;
      case TargetPlatform.windows:
        return _windowsGestures;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SelectionGestures(
      gestures: kIsWeb ? _webGestures : _defaultGestures,
      child: child,
    );
  }
}