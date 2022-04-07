import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/src/services/text_input.dart';

import 'actions.dart';
import 'basic.dart';
import 'focus_manager.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'text_editing_intents.dart';

/// A duration that controls how often the drag selection update callback is
/// called.
const Duration _kDragSelectionUpdateThrottle = Duration(milliseconds: 50);

class TextSelectionGestures extends StatefulWidget {
  const TextSelectionGestures({
    Key? key,
    this.manager,
    required this.gestures,
    this.behavior,
    required this.child,
  }) : assert(child != null),
        super(key: key);

  const TextSelectionGestures.platformDefaults({
    Key? key,
    required Widget child,
  }) : this(key: key, gestures: _defaultTextSelectionGestures, child: child);

  final TextSelectionGesturesManager? manager;

  final Map<GestureTrigger, Intent> gestures;

  /// How this gesture detector should behave during hit testing.
  ///
  /// This defaults to [HitTestBehavior.deferToChild].
  final HitTestBehavior? behavior;

  /// Child below this widget.
  final Widget child;

  static const Map<GestureTrigger, Intent> _defaultTextSelectionGestures = <GestureTrigger, Intent>{
    GestureTrigger(gesture: 'onTapDown') : ExtendSelectionToLastTapDownPositionIntent(lastTapDownPosition: Offset(4,4), cause: SelectionChangedCause.tap),
    // GestureTrigger(gesture: 'onForcePressStart') : SelectWordsInRangeAndEnableToolbarIntent,
    // GestureTrigger(gesture: 'onForcePressEnd') : SelectWordsInRangeAndShowToolbarIntent,
    // GestureTrigger(gesture: 'onSingleTapUp') : SelectLastTapDownPositionIntent,
    // GestureTrigger(gesture: 'onSingleTapCancel') : DoNothingIntent,
    // GestureTrigger(gesture: 'onSingleLongTapStart') : SelectLastTapDownPositionIntent,
    // GestureTrigger(gesture: 'onSingleLongTapMoveUpdate') : DoNothingIntent, //needs an intent
    // GestureTrigger(gesture: 'onSingleLongTapEnd') : ShowToolbarIntent,
    // GestureTrigger(gesture: 'onSecondaryTap') : SelectWordAtLastTapDownPositionAndShowToolbarIntent,
    // GestureTrigger(gesture: 'onSecondaryTapDown') : SetLastAndSecondaryTapDownPositionAndEnableToolbarIntent,
    // GestureTrigger(gesture: 'onDoubleTapDown') : SelectWordAtLastTapDownPositionAndShowToolbarIntent,
    // GestureTrigger(gesture: 'onDragSelectionStart') : ExtendSelectionToLastTapDownPositionIntent,
    // GestureTrigger(gesture: 'onDragSelectionUpdate') : DoNothingIntent, //needs an intent
    // GestureTrigger(gesture: 'onDragSelectionEnd') : CleanUpShiftTappingStatesIntent,
  };

  @override
  State<StatefulWidget> createState() => _TextSelectionGesturesState();
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
    final Map<Type, GestureRecognizerFactory> gestures = <Type, GestureRecognizerFactory>{};

    gestures[TapGestureRecognizer] = GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          () => TapGestureRecognizer(debugOwner: this),
          (TapGestureRecognizer instance) {
        instance
          ..onSecondaryTap = () { manager.handleGestureTrigger(context, 'onSecondaryTap'); }
          ..onSecondaryTapDown = (TapDownDetails details) { manager.handleGestureTrigger(context, 'onSecondaryTapDown'); }
          ..onTapDown = (TapDownDetails details) { manager.handleGestureTrigger(context, 'onTapDown'); } // with handleGestureTrigger pass the intent. handleGestureTrigger(context, 'onTapDown', ExtendSelectionToLastTapDownPositionIntent(details))???
          ..onTapUp = (TapUpDetails details) { manager.handleGestureTrigger(context, 'onTapUp'); }
          ..onTapCancel = () { manager.handleGestureTrigger(context, 'onTapCancel'); };
      },
    );

    if (manager.gestures['onLongPressStart'] != null ||
        manager.gestures['onLongPressMoveUpdate'] != null ||
        manager.gestures['onLongPressEnd'] != null) {
      gestures[LongPressGestureRecognizer] = GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
            () => LongPressGestureRecognizer(debugOwner: this, supportedDevices: <PointerDeviceKind>{PointerDeviceKind.touch}),
            (LongPressGestureRecognizer instance) {
          instance
            ..onLongPressStart = (LongPressStartDetails details) { manager.handleGestureTrigger(context, 'onLongPressStart'); }
            ..onLongPressMoveUpdate = (LongPressMoveUpdateDetails details) { manager.handleGestureTrigger(context, 'onLongPressMoveUpdate'); }
            ..onLongPressEnd = (LongPressEndDetails details) { manager.handleGestureTrigger(context, 'onLongPressEnd'); };
        },
      );
    }

    if (manager.gestures['onDragStart'] != null ||
        manager.gestures['onDragUpdate'] != null ||
        manager.gestures['onDragEnd'] != null) {
      gestures[PanGestureRecognizer] = GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
            () => PanGestureRecognizer(debugOwner: this, supportedDevices: <PointerDeviceKind>{ PointerDeviceKind.mouse }),
            (PanGestureRecognizer instance) {
          instance
          // Text selection should start from the position of the first pointer
          // down event.
            ..dragStartBehavior = DragStartBehavior.down
            ..onStart = (DragStartDetails details) { manager.handleGestureTrigger(context, 'onDragStart'); }
            ..onUpdate = (DragUpdateDetails details) { manager.handleGestureTrigger(context, 'onDragUpdate'); }
            ..onEnd = (DragEndDetails details) { manager.handleGestureTrigger(context, 'onDragEnd'); };
        },
      );
    }

    if (manager.gestures['onForcePressStart'] != null || manager.gestures['onForcePressEnd'] != null) {
      gestures[ForcePressGestureRecognizer] = GestureRecognizerFactoryWithHandlers<ForcePressGestureRecognizer>(
            () => ForcePressGestureRecognizer(debugOwner: this),
            (ForcePressGestureRecognizer instance) {
          instance
            ..onStart = manager.gestures['onForcePressStart'] != null ? (ForcePressDetails details) { manager.handleGestureTrigger(context, 'onForcePressStart'); }: null
            ..onEnd = manager.gestures['onForcePressEnd'] != null ? (ForcePressDetails details) { manager.handleGestureTrigger(context, 'onForcePressEnd'); } : null;
        },
      );
    }

    return RawGestureDetector(
      gestures: gestures,
      excludeFromSemantics: true,
      behavior: widget.behavior,
      child: widget.child,
    );
  }
}

class TextSelectionGesturesManager extends ChangeNotifier with Diagnosticable {
  TextSelectionGesturesManager({
    Map<GestureTrigger, Intent> gestures = const <GestureTrigger, Intent>{},
    this.modal = false,
  })  : assert(gestures != null),
        _gestures = gestures;

  final bool modal;

  Map<GestureTrigger, Intent> get gestures => _gestures;
  Map<GestureTrigger, Intent> _gestures = <GestureTrigger, Intent>{};
  set gestures(Map<GestureTrigger, Intent> value) {
    assert(value != null);
    if (!mapEquals<GestureTrigger, Intent>(_gestures, value)) {
      _gestures = value;
      _indexedGesturesCache = null;
      notifyListeners();
    }
  }

  static Map<String?, List<_TriggerIntentPair>> _indexGestures(Map<GestureTrigger, Intent> source) {
    final Map<String?, List<_TriggerIntentPair>> result = <String?, List<_TriggerIntentPair>>{};
    source.forEach((GestureTrigger trigger, Intent intent) {
      // This intermediate variable is necessary to comply with Dart analyzer.
      final String gesture = trigger.gesture;
      result.putIfAbsent(gesture, () => <_TriggerIntentPair>[])
          .add(_TriggerIntentPair(trigger, intent));
    });
    return result;
  }
  Map<String?, List<_TriggerIntentPair>> get _indexedGestures {
    return _indexedGesturesCache ??= _indexGestures(_gestures);
  }
  Map<String?, List<_TriggerIntentPair>>? _indexedGesturesCache;

  Intent? _find(String gestureTrigger) {
    final List<_TriggerIntentPair>? candidatesByKey = _indexedGestures[gestureTrigger];
    final List<_TriggerIntentPair>? candidatesByNull = _indexedGestures[null];
    final List<_TriggerIntentPair> candidates = <_TriggerIntentPair>[
      if (candidatesByKey != null) ...candidatesByKey,
      if (candidatesByNull != null) ...candidatesByNull,
    ];
    for (final _TriggerIntentPair triggerIntent in candidates) {
      return triggerIntent.intent;
    }
    return null;
  }

  @protected
  void handleGestureTrigger(BuildContext context, String gestureTrigger) {
    assert(context != null);
    final Intent? matchedIntent = _find(gestureTrigger);
    if (matchedIntent != null) {
      final BuildContext? primaryContext = primaryFocus?.context;
      if (primaryContext != null) {
        final Action<Intent>? action = Actions.maybeFind<Intent>(
          primaryContext,
          intent: matchedIntent,
        );
        if (action != null && action.isEnabled(matchedIntent)) {
          Actions.of(primaryContext).invokeAction(action, matchedIntent, primaryContext);
        }
      }
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Map<GestureTrigger, Intent>>('gestures', _gestures));
    properties.add(FlagProperty('modal', value: modal, ifTrue: 'modal', defaultValue: false));
  }
}

class GestureTrigger {
  const GestureTrigger({required this.gesture});

  final String gesture;
}

class _TriggerIntentPair with Diagnosticable {
  const _TriggerIntentPair(this.trigger, this.intent);
  final GestureTrigger trigger;
  final Intent intent;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<String>('trigger', trigger.gesture));
    properties.add(DiagnosticsProperty<Intent>('intent', intent));
  }
}