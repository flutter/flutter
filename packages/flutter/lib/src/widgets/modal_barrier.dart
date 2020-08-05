// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'basic.dart';
import 'container.dart';
import 'debug.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'navigator.dart';
import 'transitions.dart';

/// A widget that prevents the user from interacting with widgets behind itself.
///
/// The modal barrier is the scrim that is rendered behind each route, which
/// generally prevents the user from interacting with the route below the
/// current route, and normally partially obscures such routes.
///
/// For example, when a dialog is on the screen, the page below the dialog is
/// usually darkened by the modal barrier.
///
/// See also:
///
///  * [ModalRoute], which indirectly uses this widget.
///  * [AnimatedModalBarrier], which is similar but takes an animated [color]
///    instead of a single color value.
class ModalBarrier extends StatelessWidget {
  /// Creates a widget that blocks user interaction.
  const ModalBarrier({
    Key key,
    this.color,
    this.dismissible = true,
    this.semanticsLabel,
    this.barrierSemanticsDismissible = true,
  }) : super(key: key);

  /// If non-null, fill the barrier with this color.
  ///
  /// See also:
  ///
  ///  * [ModalRoute.barrierColor], which controls this property for the
  ///    [ModalBarrier] built by [ModalRoute] pages.
  final Color color;

  /// Whether touching the barrier will pop the current route off the [Navigator].
  ///
  /// See also:
  ///
  ///  * [ModalRoute.barrierDismissible], which controls this property for the
  ///    [ModalBarrier] built by [ModalRoute] pages.
  final bool dismissible;

  /// Whether the modal barrier semantics are included in the semantics tree.
  ///
  /// See also:
  ///
  ///  * [ModalRoute.semanticsDismissible], which controls this property for
  ///    the [ModalBarrier] built by [ModalRoute] pages.
  final bool barrierSemanticsDismissible;

  /// Semantics label used for the barrier if it is [dismissible].
  ///
  /// The semantics label is read out by accessibility tools (e.g. TalkBack
  /// on Android and VoiceOver on iOS) when the barrier is focused.
  ///
  /// See also:
  ///
  ///  * [ModalRoute.barrierLabel], which controls this property for the
  ///    [ModalBarrier] built by [ModalRoute] pages.
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    assert(!dismissible || semanticsLabel == null || debugCheckHasDirectionality(context));
    bool platformSupportsDismissingBarrier;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        platformSupportsDismissingBarrier = false;
        break;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        platformSupportsDismissingBarrier = true;
        break;
    }
    assert(platformSupportsDismissingBarrier != null);
    final bool semanticsDismissible = dismissible && platformSupportsDismissingBarrier;
    final bool modalBarrierSemanticsDismissible = barrierSemanticsDismissible ?? semanticsDismissible;
    return BlockSemantics(
      child: ExcludeSemantics(
        // On Android, the back button is used to dismiss a modal. On iOS, some
        // modal barriers are not dismissible in accessibility mode.
        excluding: !semanticsDismissible || !modalBarrierSemanticsDismissible,
        child: _ModalBarrierGestureDetector(
          onDismiss: () {
            if (dismissible)
              Navigator.maybePop(context);
            else
              SystemSound.play(SystemSoundType.alert);
          },
          child: Semantics(
            label: semanticsDismissible ? semanticsLabel : null,
            textDirection: semanticsDismissible && semanticsLabel != null ? Directionality.of(context) : null,
            child: MouseRegion(
              cursor: SystemMouseCursors.basic,
              opaque: true,
              child: ConstrainedBox(
                constraints: const BoxConstraints.expand(),
                child: color == null ? null : DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A widget that prevents the user from interacting with widgets behind itself,
/// and can be configured with an animated color value.
///
/// The modal barrier is the scrim that is rendered behind each route, which
/// generally prevents the user from interacting with the route below the
/// current route, and normally partially obscures such routes.
///
/// For example, when a dialog is on the screen, the page below the dialog is
/// usually darkened by the modal barrier.
///
/// This widget is similar to [ModalBarrier] except that it takes an animated
/// [color] instead of a single color.
///
/// See also:
///
///  * [ModalRoute], which uses this widget.
class AnimatedModalBarrier extends AnimatedWidget {
  /// Creates a widget that blocks user interaction.
  const AnimatedModalBarrier({
    Key key,
    Animation<Color> color,
    this.dismissible = true,
    this.semanticsLabel,
    this.barrierSemanticsDismissible,
  }) : super(key: key, listenable: color);

  /// If non-null, fill the barrier with this color.
  ///
  /// See also:
  ///
  ///  * [ModalRoute.barrierColor], which controls this property for the
  ///    [AnimatedModalBarrier] built by [ModalRoute] pages.
  Animation<Color> get color => listenable as Animation<Color>;

  /// Whether touching the barrier will pop the current route off the [Navigator].
  ///
  /// See also:
  ///
  ///  * [ModalRoute.barrierDismissible], which controls this property for the
  ///    [AnimatedModalBarrier] built by [ModalRoute] pages.
  final bool dismissible;

  /// Semantics label used for the barrier if it is [dismissible].
  ///
  /// The semantics label is read out by accessibility tools (e.g. TalkBack
  /// on Android and VoiceOver on iOS) when the barrier is focused.
  /// See also:
  ///
  ///  * [ModalRoute.barrierLabel], which controls this property for the
  ///    [ModalBarrier] built by [ModalRoute] pages.
  final String semanticsLabel;

  /// Whether the modal barrier semantics are included in the semantics tree.
  ///
  /// See also:
  ///
  ///  * [ModalRoute.semanticsDismissible], which controls this property for
  ///    the [ModalBarrier] built by [ModalRoute] pages.
  final bool barrierSemanticsDismissible;

  @override
  Widget build(BuildContext context) {
    return ModalBarrier(
      color: color?.value,
      dismissible: dismissible,
      semanticsLabel: semanticsLabel,
      barrierSemanticsDismissible: barrierSemanticsDismissible,
    );
  }
}

// Recognizes tap down by any pointer button.
//
// It is similar to [TapGestureRecognizer.onTapDown], but accepts any single
// button, which means the gesture also takes parts in gesture arenas.
class _AnyTapGestureRecognizer extends BaseTapGestureRecognizer {
  _AnyTapGestureRecognizer({ Object debugOwner })
    : super(debugOwner: debugOwner);

  VoidCallback onAnyTapUp;

  @protected
  @override
  bool isPointerAllowed(PointerDownEvent event) {
    if (onAnyTapUp == null)
      return false;
    return super.isPointerAllowed(event);
  }

  @protected
  @override
  void handleTapDown({PointerDownEvent down}) {
    // Do nothing.
  }

  @protected
  @override
  void handleTapUp({PointerDownEvent down, PointerUpEvent up}) {
    if (onAnyTapUp != null)
      onAnyTapUp();
  }

  @protected
  @override
  void handleTapCancel({PointerDownEvent down, PointerCancelEvent cancel, String reason}) {
    // Do nothing.
  }

  @override
  String get debugDescription => 'any tap';
}

class _ModalBarrierSemanticsDelegate extends SemanticsGestureDelegate {
  const _ModalBarrierSemanticsDelegate({this.onDismiss});

  final VoidCallback onDismiss;

  @override
  void assignSemantics(RenderSemanticsGestureHandler renderObject) {
    renderObject.onTap = onDismiss;
  }
}


class _AnyTapGestureRecognizerFactory extends GestureRecognizerFactory<_AnyTapGestureRecognizer> {
  const _AnyTapGestureRecognizerFactory({this.onAnyTapUp});

  final VoidCallback onAnyTapUp;

  @override
  _AnyTapGestureRecognizer constructor() => _AnyTapGestureRecognizer();

  @override
  void initializer(_AnyTapGestureRecognizer instance) {
    instance.onAnyTapUp = onAnyTapUp;
  }
}

// A GestureDetector used by ModalBarrier. It only has one callback,
// [onAnyTapDown], which recognizes tap down unconditionally.
class _ModalBarrierGestureDetector extends StatelessWidget {
  const _ModalBarrierGestureDetector({
    Key key,
    @required this.child,
    @required this.onDismiss,
  }) : assert(child != null),
       assert(onDismiss != null),
       super(key: key);

  /// The widget below this widget in the tree.
  /// See [RawGestureDetector.child].
  final Widget child;

  /// Immediately called when an event that should dismiss the modal barrier
  /// has happened.
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final Map<Type, GestureRecognizerFactory> gestures = <Type, GestureRecognizerFactory>{
      _AnyTapGestureRecognizer: _AnyTapGestureRecognizerFactory(onAnyTapUp: onDismiss),
    };

    return RawGestureDetector(
      gestures: gestures,
      behavior: HitTestBehavior.opaque,
      semantics: _ModalBarrierSemanticsDelegate(onDismiss: onDismiss),
      child: child,
    );
  }
}
