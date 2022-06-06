// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import 'actions.dart';
import 'framework.dart';
import 'selection_gestures.dart';
import 'text_editing_intents.dart';

/// TODO: (Renzo-Olivares) document.
class DefaultSelectionGestures extends StatelessWidget {
  /// TODO: (Renzo-Olivares) document.
  const DefaultSelectionGestures({
    super.key,
    required this.child,
  });

  /// TODO: (Renzo-Olivares) document.
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
                Actions.invoke(context, SelectRangeIntent(cause: SelectionChangedCause.tap, from: details.globalPosition)); //if !lastSecondaryTapWasOnSelection || !renderEditable.hasFocus
                Actions.invoke(context, SelectionToolbarControlIntent.hide); //if shouldshowselectiontoolbar, which is set to true by onSecondaryTapDown
                Actions.invoke(context, SelectionToolbarControlIntent.show(position: details.globalPosition)); //if shouldshowselectiontoolbar, which is set to true by onSecondaryTapDown
              }
              ..onSecondaryTap = () {
                print('onSecondaryTap');
              }
              ..onSecondaryTapDown = (TapDownDetails details) {
                print('onSecondaryTapDown');
              }
              ..onTapDown = (TapDownDetails details, int tapCount) {
                print('onTapDown , tapCount  $tapCount');
                print('isShiftPressed: $_isShiftPressed');

                if (defaultTargetPlatform == TargetPlatform.macOS) {
                  if (_isShiftPressed) {
                    Actions.invoke(context, ExpandSelectionToPositionIntent(cause: SelectionChangedCause.tap, position: details.globalPosition));
                  } else {
                    Actions.invoke(context, SelectPositionIntent(cause: SelectionChangedCause.tap, from: details.globalPosition));
                  }
                }

                if (tapCount == 2) {
                  print('onDoubleTapDown');
                  Actions.invoke(context, SelectRangeIntent(cause: SelectionChangedCause.tap, from: details.globalPosition));
                  if (details.kind == null || details.kind == PointerDeviceKind.touch || details.kind == PointerDeviceKind.stylus) {
                    Actions.invoke(context, SelectionToolbarControlIntent.show(position: details.globalPosition));
                  }
                }
              }
              ..onTapUp = (TapUpDetails details, int tapCount) {
                print('onTapUp , tapCount  $tapCount');
                if (tapCount > 1) {
                  return;
                }
                print('isShiftPressed: $_isShiftPressed');
                Actions.invoke(context, SelectionToolbarControlIntent.hide);
                if (defaultTargetPlatform != TargetPlatform.macOS) {
                  if (_isShiftPressed){
                    Actions.invoke(context, ExpandSelectionToPositionIntent(cause: SelectionChangedCause.tap, position: details.globalPosition));
                  } else {
                    switch (details.kind) {
                      case PointerDeviceKind.mouse:
                      case PointerDeviceKind.stylus:
                      case PointerDeviceKind.invertedStylus:
                      // Precise devices should place the cursor at a precise position.
                        Actions.invoke(context, SelectPositionIntent(cause: SelectionChangedCause.tap, from: details.globalPosition));
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
                }
                Actions.invoke(context, KeyboardRequestIntent());
                Actions.invoke(context, UserOnTapCallbackIntent());
              }
              ..onTapCancel = () {
                print('onTapCancel');
              };
          }
  );

  static final ContextGestureRecognizerFactoryWithHandlers<ShiftAwarePanGestureRecognizer> _iOSMacPanGestureRecognizer = ContextGestureRecognizerFactoryWithHandlers<ShiftAwarePanGestureRecognizer>(
          (BuildContext context) => ShiftAwarePanGestureRecognizer(debugOwner: context, supportedDevices: <PointerDeviceKind>{ PointerDeviceKind.mouse }),
          (ShiftAwarePanGestureRecognizer instance, BuildContext context) {
            instance
              ..dragStartBehavior = DragStartBehavior.down
              ..onDown = (DragDownDetails details, bool isShiftTapping) {
                print('onDown');
                print('isShiftTapping: $isShiftTapping');
              }
              ..onStart = (DragStartDetails details, bool isShiftTapping) {
                print('onDragStart');
                print('isShiftTapping: $isShiftTapping');
                if (isShiftTapping) {
                  Actions.invoke(context, ExpandSelectionToPositionIntent(cause: SelectionChangedCause.drag, position: details.globalPosition));
                  // Save shiftTapDragSelection to TextField/EditableText through an intent -> action?
                  Actions.invoke(context, SelectionOnDragStartControlIntent.save);
                } else {
                  Actions.invoke(context, SelectPositionIntent(cause: SelectionChangedCause.drag, from: details.globalPosition));
                }
                Actions.invoke(context, ViewportOffsetOnDragStartControlIntent.save);
                // Save dragStartViewportOffset to TextField/EditableText through an intent -> action?
              }
              ..onUpdate = (DragUpdateDetails updateDetails, DragStartDetails startDetails, bool isShiftTapping) {
                print('onDragUpdate');
                print('isShiftTapping: $isShiftTapping');
                if (!isShiftTapping) {
                  Actions.invoke(context, SelectDragPositionIntent(cause: SelectionChangedCause.drag, from: startDetails.globalPosition, to: updateDetails.globalPosition));// ? instead of SelectPositionIntent, could also use SelectPositionIntent and in selectPosition check if _dragStartViewportOffset is null
                  // Actions.invoke(context, SelectPositionIntent(cause: SelectionChangedCause.drag, from: updateDetails));
                  return;
                }
                Actions.invoke(context, ExtendSelectionToPositionIntent(cause: SelectionChangedCause.drag, position: updateDetails.globalPosition)); // remove? or ExtentSelectionToDragPositionIntent?
                // ExpandSelectionToPositionConsideringInversionIntent?

              }
              ..onEnd = (DragEndDetails details, bool isShiftTapping) {
                print('onDragEnd');
                // set shiftTapDragSelection to null in TextField/EditableText through an intent -> action.
                // set dragStartViewportOffset to 0.0 in TextField/EditableText through intent -> action.
                if (isShiftTapping) {
                  Actions.invoke(context, SelectionOnDragStartControlIntent.clear);
                }
                Actions.invoke(context, ViewportOffsetOnDragStartControlIntent.clear);
              };
          }
  );

  static final ContextGestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer> _iOSMacLongPressGestureRecognizer = ContextGestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
          (BuildContext context) => LongPressGestureRecognizer(debugOwner: context, supportedDevices: <PointerDeviceKind>{ PointerDeviceKind.touch }),
          (LongPressGestureRecognizer instance, BuildContext context) {
            instance
              ..onLongPressStart = (LongPressStartDetails details) {
                print('onLongPressStart');
                Actions.invoke(context, SelectPositionIntent(cause: SelectionChangedCause.longPress, from: details.globalPosition));
              }
              ..onLongPressMoveUpdate = (LongPressMoveUpdateDetails details) {
                print('onLongPressMoveUpdate');
                Actions.invoke(context, SelectPositionIntent(cause: SelectionChangedCause.longPress, from: details.globalPosition));
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
                  Actions.invoke(context, SelectPositionIntent(cause: SelectionChangedCause.tap, from: details.globalPosition));//if renderEditable doesnt have focus
                  Actions.invoke(context, SelectionToolbarControlIntent.toggle(position: details.globalPosition));
                }
                ..onSecondaryTap = () {
                  print('onSecondaryTap');
                }
                ..onSecondaryTapDown = (TapDownDetails details) {
                  print('onSecondaryTapDown');
                }
                ..onTapDown = (TapDownDetails details, int tapCount) {
                  print('onTapDown , tapCount  $tapCount');
                  switch (defaultTargetPlatform) {
                    case TargetPlatform.android:
                    case TargetPlatform.fuchsia:
                      break;
                    case TargetPlatform.linux:
                    case TargetPlatform.windows:
                      if (_isShiftPressed) {
                        Actions.invoke(context, ExtendSelectionToPositionIntent(cause: SelectionChangedCause.tap, position: details.globalPosition));
                      } else {
                        Actions.invoke(context, SelectPositionIntent(cause: SelectionChangedCause.tap, from: details.globalPosition));
                      }
                      break;
                  }

                  if (tapCount == 2) {
                    print('onDoubleTapDown');
                    Actions.invoke(context, SelectRangeIntent(cause: SelectionChangedCause.tap, from: details.globalPosition));
                    if (details.kind == null || details.kind == PointerDeviceKind.touch || details.kind == PointerDeviceKind.stylus) {
                      Actions.invoke(context, SelectionToolbarControlIntent.show(position: details.globalPosition));
                    }
                  }
                }
                ..onTapUp = (TapUpDetails details, int tapCount) {
                  print('onTapUp , tapCount  $tapCount');
                  if (tapCount > 1) {
                    return;
                  }
                  Actions.invoke(context, SelectionToolbarControlIntent.hide);
                  switch (defaultTargetPlatform) {
                    case TargetPlatform.android:
                    case TargetPlatform.fuchsia:
                      if (_isShiftPressed) {
                        Actions.invoke(context, ExtendSelectionToPositionIntent(cause: SelectionChangedCause.tap, position: details.globalPosition));
                      } else {
                        Actions.invoke(context, SelectPositionIntent(cause: SelectionChangedCause.tap, from: details.globalPosition));
                      }
                      break;
                    case TargetPlatform.linux:
                    case TargetPlatform.windows:
                      break;
                  }
                  Actions.invoke(context, KeyboardRequestIntent());
                  Actions.invoke(context, UserOnTapCallbackIntent());
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
                  Actions.invoke(context, SelectRangeIntent(cause: SelectionChangedCause.longPress, from: details.globalPosition));
                  Actions.invoke(context, FeedbackRequestIntent());
                }
                ..onLongPressMoveUpdate = (LongPressMoveUpdateDetails details) {
                  print('onLongPressMoveUpdate');
                  Actions.invoke(context, SelectRangeIntent(cause: SelectionChangedCause.longPress, from: details.globalPosition - details.offsetFromOrigin, to: details.globalPosition));
                }
                ..onLongPressEnd = (LongPressEndDetails details) {
                  print('onLongPressEnd');
                  Actions.invoke(context, SelectionToolbarControlIntent.show(position: details.globalPosition));
                };
            }
    ),
    ShiftAwarePanGestureRecognizer : ContextGestureRecognizerFactoryWithHandlers<ShiftAwarePanGestureRecognizer>(
            (BuildContext context) => ShiftAwarePanGestureRecognizer(debugOwner: context, supportedDevices: <PointerDeviceKind>{ PointerDeviceKind.mouse }),
            (ShiftAwarePanGestureRecognizer instance, BuildContext context) {
          instance
            ..dragStartBehavior = DragStartBehavior.down
            ..onDown = (DragDownDetails details, bool isShiftTapping) {
              print('onDown');
              print('isShiftTapping: $isShiftTapping');
            }
            ..onStart = (DragStartDetails details, bool isShiftTapping) {
              print('onDragStart');
              print('isShiftTapping: $isShiftTapping');
              if (isShiftTapping) {
                Actions.invoke(context, ExtendSelectionToPositionIntent(cause: SelectionChangedCause.drag, position: details.globalPosition));
                // Save shiftTapDragSelection to TextField/EditableText through an intent -> action?
                Actions.invoke(context, SelectionOnDragStartControlIntent.save);
              } else {
                Actions.invoke(context, SelectPositionIntent(cause: SelectionChangedCause.drag, from: details.globalPosition));
              }
              Actions.invoke(context, ViewportOffsetOnDragStartControlIntent.save);
              // Save dragStartViewportOffset to TextField/EditableText through an intent -> action?
            }
            ..onUpdate = (DragUpdateDetails updateDetails, DragStartDetails startDetails, bool isShiftTapping) {
              print('onDragUpdate');
              print('isShiftTapping: $isShiftTapping');
              if (!isShiftTapping) {
                Actions.invoke(context, SelectDragPositionIntent(cause: SelectionChangedCause.drag, from: startDetails.globalPosition, to: updateDetails.globalPosition));// ? instead of SelectPositionIntent, could also use SelectPositionIntent and in selectPosition check if _dragStartViewportOffset is null
                // Actions.invoke(context, SelectPositionIntent(cause: SelectionChangedCause.drag, from: updateDetails));
                return;
              }
              Actions.invoke(context, ExtendSelectionToPositionIntent(cause: SelectionChangedCause.drag, position: updateDetails.globalPosition));
            }
            ..onEnd = (DragEndDetails details, bool isShiftTapping) {
              print('onDragEnd');
              // set shiftTapDragSelection to null in TextField/EditableText through an intent -> action.
              // set dragStartViewportOffset to 0.0 in TextField/EditableText through intent -> action.
              if (isShiftTapping) {
                Actions.invoke(context, SelectionOnDragStartControlIntent.clear);
              }
              Actions.invoke(context, ViewportOffsetOnDragStartControlIntent.clear);
            };
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
    /// TODO: (Renzo-Olivares) web gestures differ from default platform behaviors.
    return SelectionGestures(
      // gestures: kIsWeb ? _webGestures : _defaultGestures,
      gestures: _defaultGestures,
      child: child,
    );
  }
}