import 'package:flutter/services.dart';

import 'binding.dart';
import 'framework.dart';
import 'routes.dart';

/// Phases of a predictive-back gesture.
///
/// These phases describe the lifecycle of the platform back gesture as it
/// relates to widgets that want to respond visually.
enum PredictiveBackPhase {
  /// No back gesture is in progress.
  idle,

  /// The back gesture has started
  start,

  /// The gesture is ongoing and progress updates are being delivered.
  update,

  /// The gesture was completed and should be committed (e.g. pop).
  commit,

  /// The gesture was cancelled and should be reverted visually.
  cancel,
}

/// A widget that listens to the platform's predictive-back gesture and rebuilds
/// using a provided transition builder.
///
/// `PredictiveBackGestureBuilder` is a thin helper that registers for predictive
/// back events via the framework binding (it implements
/// [WidgetsBindingObserver]) and calls `transitionBuilder` with the current
/// gesture phase and event data so the subtree can render gesture-driven
/// UI (for example, a preview/transform of the page's content).
///
/// The widget does not itself implement a visual transition — that work is
/// performed by the `transitionBuilder` callback which receives the current
/// `PredictiveBackPhase`, the initial `startBackEvent` and the most recent
/// `currentBackEvent`, as well as the `child` to embed.
class PredictiveBackGestureBuilder extends StatefulWidget {
  /// Creates a predictive-back gesture builder.
  ///
  /// Parameters:
  ///  * [route] — the [ModalRoute] associated with this builder.
  ///  * [transitionBuilder] — builder function that renders the UI for each
  ///    phase and receives `startBackEvent` and [currentBackEvent].
  ///  * [child] — the subtree to be passed to [transitionBuilder].
  ///  * [updateRouteUserGestureProgress] — when `true`, forwards gesture
  ///    progress updates to [route].
  const PredictiveBackGestureBuilder({
    super.key,
    required this.route,
    required this.transitionBuilder,
    required this.child,
    this.updateRouteUserGestureProgress = false,
    this.behavior = PredictiveBackObserverBehavior.updateOnly,
  });

  /// The `ModalRoute` that this builder is associated with.
  ///
  /// If [updateRouteUserGestureProgress] is `true`, gesture progress/cancel/commit
  /// calls will be forwarded to this route.
  final ModalRoute<Object?> route;

  /// Builder called when the gesture phase or events change.
  ///
  /// Parameters passed to the builder:
  ///  * [context] — the build context.
  ///  * [phase]  — the current [PredictiveBackPhase] to indicate idle/start/update/commit/cancel.
  ///  * [startBackEvent] — the [PredictiveBackEvent] when the gesture started (may be null in idle and cancel phases).
  ///  * [currentBackEvent] — the most recent [PredictiveBackEvent] (may be null in idle and cancel phases).
  ///  * [child] — the `child` widget passed to this widget.
  final Widget Function(
    BuildContext context,
    PredictiveBackPhase phase,
    PredictiveBackEvent? startBackEvent,
    PredictiveBackEvent? currentBackEvent,
    Widget child,
  )
  transitionBuilder;

  /// The subtree that will be provided to [transitionBuilder].
  final Widget child;

  /// When true, forwards gesture progress updates to [route].
  final bool updateRouteUserGestureProgress;

  /// Defines the behavior for handling back gesture updates.
  /// [PredictiveBackObserverBehavior.updateOnly] - the observer only receives updates, controlling nothing.
  /// [PredictiveBackObserverBehavior.takeControl] - the observer receives updates andё controls navigation.
  /// [PredictiveBackObserverBehavior.updateIfControlled] - the observer receives updates if there is already an observer that controls navigation.
  final PredictiveBackObserverBehavior behavior;

  @override
  State<PredictiveBackGestureBuilder> createState() => _PredictiveBackGestureBuilderState();
}

class _PredictiveBackGestureBuilderState extends State<PredictiveBackGestureBuilder>
    with WidgetsBindingObserver {
  PredictiveBackPhase get phase => _phase;
  PredictiveBackPhase _phase = PredictiveBackPhase.idle;
  set phase(PredictiveBackPhase phase) {
    if (_phase != phase && mounted) {
      setState(() => _phase = phase);
    }
  }

  PredictiveBackEvent? get startBackEvent => _startBackEvent;
  PredictiveBackEvent? _startBackEvent;
  set startBackEvent(PredictiveBackEvent? startBackEvent) {
    if (_startBackEvent != startBackEvent && mounted) {
      setState(() => _startBackEvent = startBackEvent);
    }
  }

  PredictiveBackEvent? get currentBackEvent => _currentBackEvent;
  PredictiveBackEvent? _currentBackEvent;
  set currentBackEvent(PredictiveBackEvent? currentBackEvent) {
    if (_currentBackEvent != currentBackEvent && mounted) {
      setState(() => _currentBackEvent = currentBackEvent);
    }
  }

  // Begin WidgetsBindingObserver.

  @override
  PredictiveBackObserverBehavior? handleStartBackGesture(PredictiveBackEvent backEvent) {
    if (backEvent.isButtonEvent) {
      return null;
    }

    phase = PredictiveBackPhase.start;
    startBackEvent = currentBackEvent = backEvent;

    if (widget.updateRouteUserGestureProgress) {
      widget.route.handleStartBackGesture(progress: 1 - backEvent.progress);
    }

    return widget.behavior;
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    if (widget.updateRouteUserGestureProgress) {
      widget.route.handleUpdateBackGestureProgress(progress: 1 - backEvent.progress);
    }

    phase = PredictiveBackPhase.update;
    currentBackEvent = backEvent;
  }

  @override
  void handleCancelBackGesture() {
    if (widget.updateRouteUserGestureProgress) {
      widget.route.handleCancelBackGesture();
    }
    phase = PredictiveBackPhase.cancel;
    startBackEvent = currentBackEvent = null;
  }

  @override
  void handleCommitBackGesture() {
    if (widget.updateRouteUserGestureProgress) {
      widget.route.handleCommitBackGesture();
    }
    phase = PredictiveBackPhase.commit;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PredictiveBackPhase effectivePhase = widget.route.popGestureInProgress
        ? phase
        : PredictiveBackPhase.idle;

    return widget.transitionBuilder(
      context,
      effectivePhase,
      startBackEvent,
      currentBackEvent,
      widget.child,
    );
  }
}
