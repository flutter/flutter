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

/// A widget with the gesture recognizers used for the default selection
/// behavior in an input field.
///
/// This default behavior can be overridden by placing a [SelectionGestures]
/// widget lower in the widget tree than this. See the [Action] class for an
/// example of remapping an [Intent] to a custom [Action].
///
/// See also:
///
///   * [WidgetsApp], which creates a DefaultSelectionGestures.
class DefaultSelectionGestures extends StatelessWidget {
  /// Creates a [DefaultSelectionGestures] widget that provides the default
  /// gesture recognizer mapping for selection behavior on the current platform.
  const DefaultSelectionGestures({
    super.key,
    required this.child,
  });

  /// {@macro flutter.widgets.ProxyWidget.child}
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
                Actions.invoke(
                  context, 
                  SecondaryTapUpIntent(
                    intents: <Intent>[
                      SelectRangeIntent(cause: SelectionChangedCause.tap, from: details.globalPosition), //if !lastSecondaryTapWasOnSelection || !renderEditable.hasFocus
                      SelectionToolbarControlIntent.hide, //if shouldshowselectiontoolbar, which is set to true by onSecondaryTapDown
                      SelectionToolbarControlIntent.show(position: details.globalPosition), //if shouldshowselectiontoolbar, which is set to true by onSecondaryTapDown
                    ],
                    enabledContext: context,
                  ),
                );
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
                    Actions.invoke(
                      context, 
                      ShiftTapDownIntent(
                        intents: <Intent>[
                          ExpandSelectionToPositionIntent(cause: SelectionChangedCause.tap, position: details.globalPosition),
                          if (tapCount < 2) const KeyboardRequestIntent(),
                          if (tapCount < 2) const UserOnTapCallbackIntent(),
                        ],
                        enabledContext: context,
                      ),
                    );
                  } else {
                    Actions.invoke(
                      context, 
                      TapDownIntent(
                        intents: <Intent>[
                          SelectPositionIntent(cause: SelectionChangedCause.tap, from: details.globalPosition),
                          if (tapCount < 2) const KeyboardRequestIntent(),
                          if (tapCount < 2) const UserOnTapCallbackIntent(),
                        ], 
                        enabledContext: context,
                      ),
                    );
                  }
                }

                if (tapCount == 2) {
                  print('onDoubleTapDown');
                  final bool showToolbar = details.kind == null || details.kind == PointerDeviceKind.touch || details.kind == PointerDeviceKind.stylus;
                  Actions.invoke(
                    context, 
                    DoubleTapDownIntent(
                      intents: <Intent>[
                        SelectRangeIntent(cause: SelectionChangedCause.tap, from: details.globalPosition),
                        if (showToolbar) SelectionToolbarControlIntent.show(position: details.globalPosition)
                      ],
                      enabledContext: context,
                    ),
                  );
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
                    Actions.invoke(
                      context, 
                      ShiftTapUpIntent(
                        intents: <Intent>[
                          ExpandSelectionToPositionIntent(cause: SelectionChangedCause.tap, position: details.globalPosition),
                          const KeyboardRequestIntent(),
                          const UserOnTapCallbackIntent(),
                        ], 
                        enabledContext: context,
                      ),
                    );
                  } else {
                    late final Intent selectionUpdateIntent;
                    switch (details.kind) {
                      case PointerDeviceKind.mouse:
                      case PointerDeviceKind.stylus:
                      case PointerDeviceKind.invertedStylus:
                      // Precise devices should place the cursor at a precise position.
                        selectionUpdateIntent = SelectPositionIntent(cause: SelectionChangedCause.tap, from: details.globalPosition);
                        break;
                      case PointerDeviceKind.touch:
                      case PointerDeviceKind.unknown:
                      default: // ignore: no_default_cases, to allow adding new device types to [PointerDeviceKind]
                      // TODO(moffatman): Remove after landing https://github.com/flutter/flutter/issues/23604
                      // On iOS/iPadOS a touch tap places the cursor at the edge of the word.
                        selectionUpdateIntent = SelectWordEdgeIntent(cause: SelectionChangedCause.tap, position: details.globalPosition);
                        break;
                    }
                    Actions.invoke(
                      context,
                      TapUpIntent(
                        intents: <Intent>[
                          selectionUpdateIntent,
                          const KeyboardRequestIntent(),
                          const UserOnTapCallbackIntent(),
                        ],
                        enabledContext: context,
                      ),
                    );
                  }
                }
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
                  Actions.invoke(
                    context,
                    ShiftTappingOnDragStartIntent(
                      intents: <Intent>[
                        ExpandSelectionToPositionIntent(cause: SelectionChangedCause.drag, position: details.globalPosition),
                        SelectionOnDragStartControlIntent.save,
                        ViewportOffsetOnDragStartControlIntent.save,
                      ],
                      enabledContext: context,
                    ),
                  );
                } else {
                  Actions.invoke(
                    context,
                    DragStartIntent(
                      intents: <Intent>[
                        SelectPositionIntent(cause: SelectionChangedCause.drag, from: details.globalPosition),
                        ViewportOffsetOnDragStartControlIntent.save,
                      ],
                      enabledContext: context,
                    ),
                  );
                }
              }
              ..onUpdate = (DragUpdateDetails updateDetails, DragStartDetails startDetails, bool isShiftTapping) {
                print('onDragUpdate');
                print('isShiftTapping: $isShiftTapping');
                if (!isShiftTapping) {
                  Actions.invoke(
                    context,
                    ShiftTappingOnDragUpdateIntent(
                      intents: <Intent>[
                        SelectDragPositionIntent(cause: SelectionChangedCause.drag, from: startDetails.globalPosition, to: updateDetails.globalPosition),
                      ],
                      enabledContext: context,
                    ),
                  );
                  // Actions.invoke(context, SelectDragPositionIntent(cause: SelectionChangedCause.drag, from: startDetails.globalPosition, to: updateDetails.globalPosition));// ? instead of SelectPositionIntent, could also use SelectPositionIntent and in selectPosition check if _dragStartViewportOffset is null
                  // Actions.invoke(context, SelectPositionIntent(cause: SelectionChangedCause.drag, from: updateDetails));
                  return;
                }
                Actions.invoke(
                  context,
                  DragUpdateIntent(
                    intents: <Intent>[
                      ExtendSelectionToPositionIntent(cause: SelectionChangedCause.drag, position: updateDetails.globalPosition),
                    ],
                    enabledContext: context,
                  ),
                );
                //Actions.invoke(context, ExtendSelectionToPositionIntent(cause: SelectionChangedCause.drag, position: updateDetails.globalPosition)); // remove? or ExtentSelectionToDragPositionIntent?
                // ExpandSelectionToPositionConsideringInversionIntent?

              }
              ..onEnd = (DragEndDetails details, bool isShiftTapping) {
                print('onDragEnd');
                // set shiftTapDragSelection to null in TextField/EditableText through an intent -> action.
                // set dragStartViewportOffset to 0.0 in TextField/EditableText through intent -> action.
                if (isShiftTapping) {
                  Actions.invoke(
                    context,
                    ShiftTappingOnDragEndIntent(
                      intents: <Intent>[
                        SelectionOnDragStartControlIntent.clear,
                        ViewportOffsetOnDragStartControlIntent.clear,
                      ],
                      enabledContext: context,
                    ),
                  );
                  return;
                }
                Actions.invoke(
                  context,
                  DragEndIntent(
                    intents: <Intent>[
                      ViewportOffsetOnDragStartControlIntent.clear,
                    ],
                    enabledContext: context,
                  ),
                );
              };
          }
  );

  static final ContextGestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer> _iOSMacLongPressGestureRecognizer = ContextGestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
          (BuildContext context) => LongPressGestureRecognizer(debugOwner: context, supportedDevices: <PointerDeviceKind>{ PointerDeviceKind.touch }),
          (LongPressGestureRecognizer instance, BuildContext context) {
            instance
              ..onLongPressStart = (LongPressStartDetails details) {
                print('onLongPressStart');
                Actions.invoke(
                  context, 
                  LongPressStartIntent(
                    intents: <Intent>[
                      SelectPositionIntent(cause: SelectionChangedCause.longPress, from: details.globalPosition),
                    ], 
                    enabledContext: context,
                  ),
                );
              }
              ..onLongPressMoveUpdate = (LongPressMoveUpdateDetails details) {
                print('onLongPressMoveUpdate');
                Actions.invoke(
                  context, 
                  LongPressMoveUpdateIntent(
                    intents: <Intent>[
                      SelectPositionIntent(cause: SelectionChangedCause.longPress, from: details.globalPosition),
                    ], 
                    enabledContext: context,
                  ),
                );
              }
              ..onLongPressEnd = (LongPressEndDetails details) {
                print('onLongPressEnd');
                Actions.invoke(
                  context, 
                  LongPressEndIntent(
                    intents: <Intent>[
                      SelectionToolbarControlIntent.show(position: details.globalPosition),
                    ], 
                    enabledContext: context,
                  ),
                );
              };
          }
  );

  static final ContextGestureRecognizerFactoryWithHandlers<ForcePressGestureRecognizer> _iOSMacForcePressGestureRecognizer = ContextGestureRecognizerFactoryWithHandlers<ForcePressGestureRecognizer>(
          (BuildContext context) => ForcePressGestureRecognizer(debugOwner: context),
          (ForcePressGestureRecognizer instance, BuildContext context) {
            instance
              ..onStart = (ForcePressDetails details) {
                print('onStartForcePress');
                Actions.invoke(
                  context, 
                  ForcePressStartIntent(
                    intents: <Intent>[
                      SelectRangeIntent(cause: SelectionChangedCause.forcePress, from: details.globalPosition),
                    ], 
                    enabledContext: context,
                  ),
                );
              }
              ..onEnd = (ForcePressDetails details) {
                print('onEndForcePress');
                Actions.invoke(context, ForcePressEndIntent(
                  intents:
                    <Intent>[
                      SelectRangeIntent(cause: SelectionChangedCause.forcePress, from: details.globalPosition),
                      SelectionToolbarControlIntent.show(position: details.globalPosition),
                    ],
                    enabledContext: context,
                  ),
                );
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
                  Actions.invoke(
                    context, 
                    SecondaryTapUpIntent(
                      intents: <Intent>[
                        SelectPositionIntent(cause: SelectionChangedCause.tap, from: details.globalPosition),
                        SelectionToolbarControlIntent.toggle(position: details.globalPosition),
                      ],
                      enabledContext: context,
                    ),
                  );
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
                    case TargetPlatform.macOS:
                    case TargetPlatform.iOS:
                      // Not for these platforms.
                      break;
                    case TargetPlatform.android:
                    case TargetPlatform.fuchsia:
                      break;
                    case TargetPlatform.linux:
                    case TargetPlatform.windows:
                      if (_isShiftPressed) {
                        Actions.invoke(
                          context, 
                          ShiftTapDownIntent(
                            intents: <Intent>[
                              ExtendSelectionToPositionIntent(cause: SelectionChangedCause.tap, position: details.globalPosition),
                              if (tapCount < 2) const KeyboardRequestIntent(),
                              if (tapCount < 2) const UserOnTapCallbackIntent(),
                            ], 
                            enabledContext: context,
                          ),
                        );
                      } else {
                        Actions.invoke(
                          context, 
                          TapDownIntent(
                            intents: <Intent>[
                              SelectPositionIntent(cause: SelectionChangedCause.tap, from: details.globalPosition),
                              if (tapCount < 2) const KeyboardRequestIntent(),
                              if (tapCount < 2) const UserOnTapCallbackIntent(),
                            ], 
                            enabledContext: context,
                          ),
                        );
                      }
                      break;
                  }

                  if (tapCount == 2) {
                    print('onDoubleTapDown');
                    final bool showToolbar = details.kind == null || details.kind == PointerDeviceKind.touch || details.kind == PointerDeviceKind.stylus;
                    Actions.invoke(
                      context, 
                      DoubleTapDownIntent(
                        intents: <Intent>[
                          SelectRangeIntent(cause: SelectionChangedCause.tap, from: details.globalPosition),
                          if (showToolbar) SelectionToolbarControlIntent.show(position: details.globalPosition)
                        ],
                        enabledContext: context,
                      ),
                    );
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
                        Actions.invoke(
                          context,
                          ShiftTapUpIntent(
                            intents: <Intent>[
                              ExtendSelectionToPositionIntent(cause: SelectionChangedCause.tap, position: details.globalPosition),
                              const KeyboardRequestIntent(),
                              const UserOnTapCallbackIntent(),
                            ],
                            enabledContext: context,
                          ),
                        );
                      } else {
                        Actions.invoke(
                          context,
                          TapUpIntent(
                            intents: <Intent>[
                              SelectPositionIntent(cause: SelectionChangedCause.tap, from: details.globalPosition),
                              const KeyboardRequestIntent(),
                              const UserOnTapCallbackIntent(),
                            ],
                            enabledContext: context,
                          ),
                        );
                      }
                      break;
                    case TargetPlatform.iOS:
                    case TargetPlatform.linux:
                    case TargetPlatform.macOS:
                    case TargetPlatform.windows:
                      break;
                  }
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
                  Actions.invoke(
                    context, 
                    LongPressStartIntent(
                      intents: <Intent>[
                        SelectRangeIntent(cause: SelectionChangedCause.longPress, from: details.globalPosition),
                        const FeedbackRequestIntent(),
                      ], 
                      enabledContext: context,
                    ),
                  );
                }
                ..onLongPressMoveUpdate = (LongPressMoveUpdateDetails details) {
                  print('onLongPressMoveUpdate');
                  Actions.invoke(
                    context, 
                    LongPressMoveUpdateIntent(
                      intents: <Intent>[
                        SelectRangeIntent(cause: SelectionChangedCause.longPress, from: details.globalPosition - details.offsetFromOrigin, to: details.globalPosition),
                      ], 
                      enabledContext: context,
                    ),
                  );
                }
                ..onLongPressEnd = (LongPressEndDetails details) {
                  print('onLongPressEnd');
                  Actions.invoke(
                    context, 
                    LongPressEndIntent(
                      intents: <Intent>[
                        SelectionToolbarControlIntent.show(position: details.globalPosition),
                      ], 
                      enabledContext: context,
                    ),
                  );
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
                Actions.invoke(
                  context,
                  ShiftTappingOnDragStartIntent(
                    intents: <Intent>[
                      ExtendSelectionToPositionIntent(cause: SelectionChangedCause.drag, position: details.globalPosition),
                      SelectionOnDragStartControlIntent.save,
                      ViewportOffsetOnDragStartControlIntent.save,
                    ],
                    enabledContext: context,
                  ),
                );
              } else {
                Actions.invoke(
                  context,
                  DragStartIntent(
                    intents: <Intent>[
                      SelectPositionIntent(cause: SelectionChangedCause.drag, from: details.globalPosition),
                      ViewportOffsetOnDragStartControlIntent.save,
                    ],
                    enabledContext: context,
                  ),
                );
              }
            }
            ..onUpdate = (DragUpdateDetails updateDetails, DragStartDetails startDetails, bool isShiftTapping) {
              print('onDragUpdate');
              print('isShiftTapping: $isShiftTapping');
              if (!isShiftTapping) {
                Actions.invoke(
                  context,
                  ShiftTappingOnDragUpdateIntent(
                    intents: <Intent>[
                      SelectDragPositionIntent(cause: SelectionChangedCause.drag, from: startDetails.globalPosition, to: updateDetails.globalPosition),
                    ],
                    enabledContext: context,
                  ),
                );
                // Actions.invoke(context, SelectDragPositionIntent(cause: SelectionChangedCause.drag, from: startDetails.globalPosition, to: updateDetails.globalPosition));// ? instead of SelectPositionIntent, could also use SelectPositionIntent and in selectPosition check if _dragStartViewportOffset is null
                // Actions.invoke(context, SelectPositionIntent(cause: SelectionChangedCause.drag, from: updateDetails));
                return;
              }
              Actions.invoke(
                context,
                DragUpdateIntent(
                  intents: <Intent>[
                    ExtendSelectionToPositionIntent(cause: SelectionChangedCause.drag, position: updateDetails.globalPosition),
                  ],
                  enabledContext: context,
                ),
              );
            }
            ..onEnd = (DragEndDetails details, bool isShiftTapping) {
              print('onDragEnd');
              // set shiftTapDragSelection to null in TextField/EditableText through an intent -> action.
              // set dragStartViewportOffset to 0.0 in TextField/EditableText through intent -> action.
              if (isShiftTapping) {
                Actions.invoke(
                  context,
                  ShiftTappingOnDragEndIntent(
                    intents: <Intent>[
                      SelectionOnDragStartControlIntent.clear,
                      ViewportOffsetOnDragStartControlIntent.clear,
                    ],
                    enabledContext: context,
                  ),
                );
                return;
              }
              Actions.invoke(
                context,
                DragEndIntent(
                  intents: <Intent>[
                    ViewportOffsetOnDragStartControlIntent.clear,
                  ],
                  enabledContext: context,
                ),
              );
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
    // TODO(Renzo-Olivares): Web gestures differ from default platform behaviors.
    return SelectionGestures(
      // gestures: kIsWeb ? _webGestures : _defaultGestures,
      gestures: _defaultGestures,
      child: child,
    );
  }
}
