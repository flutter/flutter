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

  static final ContextGestureRecognizerFactoryWithHandlers<SelectionConsecutiveTapGestureRecognizer> _iOSMacTapGestureRecognizer = ContextGestureRecognizerFactoryWithHandlers<SelectionConsecutiveTapGestureRecognizer>(
          (BuildContext context) => SelectionConsecutiveTapGestureRecognizer(debugOwner: context),
          (SelectionConsecutiveTapGestureRecognizer instance, BuildContext context) {
        instance
          ..onSecondaryTapUp = (TapUpDetails details) {
            print('onSecondaryTapUp');
          }
          ..onSecondaryTap = () {
            print('onSecondaryTap');
          }
          ..onSecondaryTapDown = (TapDownDetails details) {
            print('onSecondaryTapDown');
            Actions.invoke(context, SelectRangeIntent(cause: SelectionChangedCause.tap, from: details.globalPosition));
            Actions.invoke(context, SelectionToolbarControlIntent.hide);
            Actions.invoke(context, SelectionToolbarControlIntent.show(position: details.globalPosition));
          }
          ..onTapDown = (TapDownDetails details, int tapCount) {
            print('onTapDown , tapCount  $tapCount');
            Actions.invoke(context, ExpandSelectionToPositionIntent(cause: SelectionChangedCause.tap, position: details.globalPosition, shiftPressed: _isShiftPressed));

            if (tapCount == 2) {
              print('onDoubleTapDown');
              Actions.invoke(context, SelectRangeIntent(cause: SelectionChangedCause.tap, from: details.globalPosition));
            }
          }
          ..onTapUp = (TapUpDetails details, int tapCount) {
            print('onTapUp , tapCount  $tapCount');
            if (tapCount > 1) return;
            Actions.invoke(context, SelectionToolbarControlIntent.hide);
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
            Actions.invoke(context, KeyboardRequestIntent());
            //Actions.invoke(context, UserOnTapCallbackIntent);
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
                Actions.invoke(context, ExtendSelectionToPositionIntent(cause: SelectionChangedCause.drag, position: details.globalPosition, shiftPressed: true));
              }
              ..onEnd = (DragEndDetails details) {
                print('onDragEnd');
              };
          }
  );

  static final ContextGestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer> _iOSMacLongPressGestureRecognizer = ContextGestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
          (BuildContext context) => LongPressGestureRecognizer(debugOwner: context, supportedDevices: <PointerDeviceKind>{ PointerDeviceKind.touch }),
          (LongPressGestureRecognizer instance, BuildContext context) {
        instance
          ..onLongPressStart = (LongPressStartDetails details) {
            print('onLongPressStart');
            Actions.invoke(context, SelectTapPositionIntent(cause: SelectionChangedCause.longPress, from: details.globalPosition));
          }
          ..onLongPressMoveUpdate = (LongPressMoveUpdateDetails details) {
            print('onLongPressMoveUpdate');
            Actions.invoke(context, SelectTapPositionIntent(cause: SelectionChangedCause.longPress, from: details.globalPosition));
          }
          ..onLongPressEnd = (LongPressEndDetails details) {
            print('onLongPressEnd');
            Actions.invoke(context, SelectionToolbarControlIntent.show(position: details.globalPosition));
          };
      }
  );

  static final ContextGestureRecognizerFactoryWithHandlers<ForcePressGestureRecognizer> _iOSMacForcePressGestureRecognizer = ContextGestureRecognizerFactoryWithHandlers<ForcePressGestureRecognizer>(
          (BuildContext context) => ForcePressGestureRecognizer(debugOwner: context),
          (ForcePressGestureRecognizer instance, BuildContext context) {
        instance
          ..onStart = (ForcePressDetails details) {
            print('onStartForcePress');
            Actions.invoke(context, SelectRangeIntent(cause: SelectionChangedCause.forcePress, from: details.globalPosition));
          }
          ..onEnd = (ForcePressDetails details) {
            print('onEndForcePress');
            Actions.invoke(context, SelectRangeIntent(cause: SelectionChangedCause.forcePress, from: details.globalPosition));
            Actions.invoke(context, SelectionToolbarControlIntent.show(position: details.globalPosition));
          };
      }
  );

  static final Map<Type, ContextGestureRecognizerFactory> _commonGestures = {
    TapGestureRecognizer : ContextGestureRecognizerFactoryWithHandlers<SelectionConsecutiveTapGestureRecognizer>(
            (BuildContext context) => SelectionConsecutiveTapGestureRecognizer(debugOwner: context),
            (SelectionConsecutiveTapGestureRecognizer instance, BuildContext context) {
          instance
            ..onSecondaryTapUp = (TapUpDetails details) {
              print('onSecondaryTapUp');
            }
            ..onSecondaryTap = () {
              print('onSecondaryTap');
            }
            ..onSecondaryTapDown = (TapDownDetails details) {
              print('onSecondaryTapDown');
              Actions.invoke(context, SelectTapPositionIntent(cause: SelectionChangedCause.tap, from: details.globalPosition));//if renderEditable doesnt have focus
              Actions.invoke(context, SelectionToolbarControlIntent.toggle);
            }
            ..onTapDown = (TapDownDetails details, int tapCount) {
              print('onTapDown , tapCount  $tapCount');
              Actions.invoke(context, ExtendSelectionToPositionIntent(cause: SelectionChangedCause.tap, position: details.globalPosition, shiftPressed: _isShiftPressed));

              if (tapCount == 2) {
                print('onDoubleTapDown');
                Actions.invoke(context, SelectRangeIntent(cause: SelectionChangedCause.tap, from: details.globalPosition));
              }
            }
            ..onTapUp = (TapUpDetails details, int tapCount) {
              print('onTapUp , tapCount  $tapCount');
              if (tapCount > 1) return;
              Actions.invoke(context, SelectionToolbarControlIntent.hide);
              Actions.invoke(context, SelectTapPositionIntent(cause: SelectionChangedCause.tap, from: details.globalPosition));
              Actions.invoke(context, KeyboardRequestIntent());
              //Actions.invoke(context, UserOnTapCallbackIntent);
            }
            ..onTapCancel = () {
              print('onTapCancel');
            };
        }
    ),
    LongPressGestureRecognizer : ContextGestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
            (BuildContext context) => LongPressGestureRecognizer(debugOwner: context, supportedDevices: <PointerDeviceKind>{ PointerDeviceKind.touch }),
            (LongPressGestureRecognizer instance, BuildContext context) {
          instance
            ..onLongPressStart = (LongPressStartDetails details) {
              print('onLongPressStart');
              Actions.invoke(context, SelectTapPositionIntent(cause: SelectionChangedCause.longPress, from: details.globalPosition));
            }
            ..onLongPressMoveUpdate = (LongPressMoveUpdateDetails details) {
              print('onLongPressMoveUpdate');
              Actions.invoke(context, SelectTapPositionIntent(cause: SelectionChangedCause.longPress, from: details.globalPosition));
            }
            ..onLongPressEnd = (LongPressEndDetails details) {
              print('onLongPressEnd');
              Actions.invoke(context, SelectionToolbarControlIntent.show(position: details.globalPosition));
            };
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
  };

  static final Map<Type, ContextGestureRecognizerFactory> _androidGestures = _commonGestures;
  static final Map<Type, ContextGestureRecognizerFactory> _fuchsiaGestures = _commonGestures;
  static final Map<Type, ContextGestureRecognizerFactory> _iOSGestures = <Type, ContextGestureRecognizerFactory>{
    TapGestureRecognizer : _iOSMacTapGestureRecognizer,
    PanGestureRecognizer : _iOSMacPanGestureRecognizer,
    LongPressGestureRecognizer : _iOSMacLongPressGestureRecognizer,
    ForcePressGestureRecognizer : _iOSMacForcePressGestureRecognizer,
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