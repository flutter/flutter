// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';

import 'package:meta/meta.dart';
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

import '../dom.dart';
import 'semantics.dart';

/// The maximum [semanticsActivationAttempts] before we give up waiting for
/// the user to enable semantics.
///
/// This number is arbitrary and can be adjusted if it doesn't work well.
const int kMaxSemanticsActivationAttempts = 20;

/// After an event related to semantics activation has been received, we consume
/// the consecutive events on the engine. Do not send them to the framework.
/// For example when a 'mousedown' targeting a placeholder received following
/// 'mouseup' is also not sent to the framework.
/// Otherwise these events can cause unintended gestures on the framework side.
const Duration _periodToConsumeEvents = Duration(milliseconds: 300);

/// A helper for [EngineSemanticsOwner].
///
/// [SemanticsHelper] prepares and placeholder to enable semantics.
///
/// It decides if an event is purely semantics enabling related or a regular
/// event which should be forwarded to the framework.
///
/// It does this by using a [SemanticsEnabler]. The [SemanticsEnabler]
/// implementation is chosen using form factor type.
///
/// See [DesktopSemanticsEnabler], [MobileSemanticsEnabler].
class SemanticsHelper {
  SemanticsEnabler _semanticsEnabler = ui_web.browser.isDesktop
      ? DesktopSemanticsEnabler()
      : MobileSemanticsEnabler();

  @visibleForTesting
  SemanticsEnabler get semanticsEnabler => _semanticsEnabler;

  @visibleForTesting
  set semanticsEnabler(SemanticsEnabler semanticsEnabler) {
    _semanticsEnabler = semanticsEnabler;
  }

  bool shouldEnableSemantics(DomEvent event) {
    return _semanticsEnabler.shouldEnableSemantics(event);
  }

  /// Notifies that a Flutter view rooted at [viewRoot] was created, so that a
  /// placeholder can be put where this form factor needs it.
  void addPlaceholderForView(DomElement viewRoot) {
    _semanticsEnabler.addPlaceholderForView(viewRoot);
  }

  /// Notifies that the Flutter view rooted at [viewRoot] is going away.
  void removePlaceholderForView(DomElement viewRoot) {
    _semanticsEnabler.removePlaceholderForView(viewRoot);
  }

  void updatePlaceholderLabel(String message) {
    _semanticsEnabler.updatePlaceholderLabel(message);
  }

  /// Stops waiting for the user to enable semantics and removes all
  /// placeholders.
  ///
  /// This is used when semantics is enabled programmatically and therefore the
  /// placeholder is no longer needed.
  void dispose() {
    _semanticsEnabler.dispose();
  }
}

@visibleForTesting
abstract class SemanticsEnabler {
  /// Whether to enable semantics.
  ///
  /// Semantics should be enabled if the web engine is no longer waiting for
  /// extra signals from the user events. See [isWaitingToEnableSemantics].
  ///
  /// Or if the received [DomEvent] is suitable/enough for enabling the
  /// semantics. See [tryEnableSemantics].
  bool shouldEnableSemantics(DomEvent event) {
    // Simply tabbing into the placeholder element should not cause semantics
    // to be enabled. The user should actually click on the placeholder.
    if (event.isA<DomKeyboardEvent>()) {
      event as DomKeyboardEvent;
      if (event.key == 'Tab') {
        return true;
      }
    }

    if (!isWaitingToEnableSemantics) {
      // Forward to framework as normal.
      return true;
    } else {
      return tryEnableSemantics(event);
    }
  }

  /// Attempts to activate semantics.
  ///
  /// Returns true if the `event` is not related to semantics activation and
  /// should be forwarded to the framework.
  bool tryEnableSemantics(DomEvent event);

  /// The placeholders that are currently waiting for the user to enable
  /// accessibility.
  ///
  /// See [addPlaceholderForView] for how many there are and where they live.
  @visibleForTesting
  final List<DomElement> placeholders = <DomElement>[];

  /// Places a placeholder for the Flutter view rooted at [viewRoot].
  ///
  /// Subclasses decide both how many placeholders exist and where they are
  /// attached, because the two form factors need opposite things. See
  /// [DesktopSemanticsEnabler] and [MobileSemanticsEnabler].
  void addPlaceholderForView(DomElement viewRoot);

  /// Removes whatever [addPlaceholderForView] put in place for [viewRoot].
  void removePlaceholderForView(DomElement viewRoot);

  /// Creates a placeholder element and adds it to [placeholders].
  ///
  /// On focus the element announces that accessibility can be enabled by
  /// tapping/clicking. (Announcement depends on the assistive technology)
  ///
  /// Only touches [placeholders]. The caller attaches the element and keeps
  /// its own bookkeeping in sync, so this is for [addPlaceholderForView]
  /// implementations rather than outside callers.
  DomElement addPlaceholder() {
    final DomElement placeholder = _prepareAccessibilityPlaceholder();
    placeholders.add(placeholder);
    return placeholder;
  }

  DomElement _prepareAccessibilityPlaceholder();

  /// Updates the label of every placeholder to the given [message].
  void updatePlaceholderLabel(String message) {
    for (final DomElement placeholder in placeholders) {
      placeholder.setAttribute('aria-label', message);
    }
  }

  /// Whether platform is still considering enabling semantics.
  ///
  /// At this stage a relevant set of events are always assessed to see if
  /// they activate the semantics.
  ///
  /// If not they are sent to framework as normal events.
  bool get isWaitingToEnableSemantics => placeholders.isNotEmpty;

  /// Stops waiting for the user to enable semantics and removes all
  /// placeholders.
  void dispose() {
    for (final DomElement placeholder in placeholders) {
      placeholder.remove();
    }
    placeholders.clear();
  }
}

/// The desktop semantics enabler uses a simpler strategy compared to mobile.
///
/// A placeholder element is created completely outside the view and is not
/// reachable via touch or mouse. Assistive technology can still find it either
/// using keyboard shortcuts or via next/previous touch gesture (for touch
/// screens). This simplification removes the need for pointer event
/// disambiguation or timers. The placeholder simply waits for a click event
/// and enables semantics.
@visibleForTesting
class DesktopSemanticsEnabler extends SemanticsEnabler {
  /// The roots of the views that registered for a placeholder and are still
  /// alive.
  ///
  /// Only used to know when the last one is gone and the shared placeholder
  /// can be dropped. Deliberately survives [dispose]: if semantics is turned
  /// off again and a new view creates another shared placeholder, that
  /// placeholder must outlive the new view for as long as the older views are
  /// around.
  final Set<DomElement> _viewRoots = <DomElement>{};

  /// Adds a single placeholder for the whole page, shared by all views.
  ///
  /// It must *not* go inside the <flutter-view>. It has to be the first thing
  /// the user tabs to, because once browser focus enters a view, Flutter's own
  /// focus traversal can consume Tab and never hand it back: a `Navigator` not
  /// built by `WidgetsApp` traverses with `TraversalEdgeBehavior.parentScope`,
  /// which closed-loops within the view, reports the key as handled, and the
  /// engine then calls `preventDefault`. Screen reader users in focus mode
  /// reach this button by Tab, so nesting it would put it out of reach.
  ///
  /// Being 1x1 and offscreen, it never covers page content, so it does not
  /// need scoping to a view the way
  /// [MobileSemanticsEnabler.addPlaceholderForView] does.
  ///
  /// See https://github.com/flutter/flutter/issues/152838
  @override
  void addPlaceholderForView(DomElement viewRoot) {
    _viewRoots.add(viewRoot);
    if (placeholders.isEmpty) {
      domDocument.body?.prepend(addPlaceholder());
    }
  }

  @override
  void removePlaceholderForView(DomElement viewRoot) {
    final bool wasRegistered = _viewRoots.remove(viewRoot);
    if (wasRegistered && _viewRoots.isEmpty) {
      dispose();
    }
  }

  @override
  bool tryEnableSemantics(DomEvent event) {
    // Semantics may be enabled programmatically. If there's a race between that
    // and the DOM event, we may end up here while there's no longer a placeholder
    // to work with.
    if (!isWaitingToEnableSemantics) {
      return true;
    }

    if (EngineSemantics.instance.semanticsEnabled) {
      // Semantics already enabled, forward to framework as normal.
      return true;
    }

    // In touch screen laptops, the touch is received as a mouse click
    const kInterestingEventTypes = <String>{
      'click',
      'keyup',
      'keydown',
      'mouseup',
      'mousedown',
      'pointerdown',
      'pointerup',
    };

    if (!kInterestingEventTypes.contains(event.type)) {
      // The event is not relevant, forward to framework as normal.
      return true;
    }

    // Check for the event target.
    final bool enableConditionPassed = placeholders.contains(event.target);

    if (!enableConditionPassed) {
      // This was not a semantics activating event; forward as normal.
      return true;
    }

    EngineSemantics.instance.semanticsEnabled = true;
    dispose();
    return false;
  }

  @override
  DomElement _prepareAccessibilityPlaceholder() {
    final DomElement placeholder = createDomElement('flt-semantics-placeholder');

    // Only listen to "click" because other kinds of events are reported via
    // PointerBinding.
    placeholder.addEventListener(
      'click',
      createDomEventListener((DomEvent event) {
        tryEnableSemantics(event);
      }),
      true.toJS,
    );

    // Adding roles to semantics placeholder. 'aria-live' will make sure that
    // the content is announced to the assistive technology user as soon as the
    // page receives focus. 'tabindex' makes sure the button is the first
    // target of tab. 'aria-label' is used to define the placeholder message
    // to the assistive technology user.
    placeholder
      ..setAttribute('role', 'button')
      ..setAttribute('aria-live', 'polite')
      ..setAttribute('tabindex', '0')
      ..setAttribute('aria-label', ui_web.accessibilityPlaceholderMessage);

    // The placeholder sits just outside the viewport so only AT can reach it.
    placeholder.style
      ..position = 'absolute'
      ..left = '-1px'
      ..top = '-1px'
      ..width = '1px'
      ..height = '1px';
    return placeholder;
  }
}

@visibleForTesting
class MobileSemanticsEnabler extends SemanticsEnabler {
  /// We do not immediately enable semantics when the user requests it, but
  /// instead wait for a short period of time before doing it. This is because
  /// the request comes as an event targeted on a placeholder.
  /// This event, depending on the browser, comes as a burst of events.
  /// For example, Safari on IOS sends "touchstart", "touchend", and "click".
  /// So during a short time period we consume all events and prevent forwarding
  /// to the framework. Otherwise, the events will be interpreted twice, once as
  /// a request to activate semantics, and a second time by Flutter's gesture
  /// recognizers.
  @visibleForTesting
  Timer? semanticsActivationTimer;

  /// The number of events we processed that could potentially activate
  /// semantics.
  int semanticsActivationAttempts = 0;

  /// Instructs [tryEnableSemantics] to remove the placeholders.
  ///
  /// For Blink browser engine the placeholders are removed upon any next event.
  ///
  /// For Webkit browser engine the placeholders are removed upon the next
  /// "touchend" event. This is to prevent Safari from swallowing the event
  /// that happens on an element that's being removed. Blink doesn't have
  /// this issue.
  bool _schedulePlaceholderRemoval = false;

  /// The placeholder covering each view, keyed by the view's root element.
  final Map<DomElement, DomElement> _placeholderByViewRoot = <DomElement, DomElement>{};

  /// Adds a placeholder covering just this view.
  ///
  /// One per view, rather than one for the page. This placeholder fills its
  /// offset parent, so a single page-level one would sit on top of the whole
  /// document and swallow every tap aimed at the HTML around an embedded view.
  ///
  /// Do not collapse this into the desktop strategy. The two are deliberately
  /// opposite: see [DesktopSemanticsEnabler.addPlaceholderForView], which must
  /// stay out of the view to remain reachable by keyboard.
  ///
  /// See https://github.com/flutter/flutter/issues/152838
  @override
  void addPlaceholderForView(DomElement viewRoot) {
    if (_placeholderByViewRoot.containsKey(viewRoot)) {
      // Registering twice would strand the first placeholder, tracked and
      // attached, with nothing left holding a reference to it.
      return;
    }
    final DomElement placeholder = addPlaceholder();
    _placeholderByViewRoot[viewRoot] = placeholder;
    // First child, so that the rest of the view stays on top of it and keeps
    // receiving DOM events, platform views in particular. Pointer events that
    // do land on the placeholder still bubble up to the view root, where
    // [PointerBinding] listens for them.
    viewRoot.prepend(placeholder);
  }

  @override
  void removePlaceholderForView(DomElement viewRoot) {
    final DomElement? placeholder = _placeholderByViewRoot.remove(viewRoot);
    if (placeholder != null) {
      placeholders.remove(placeholder);
      placeholder.remove();
    }
  }

  @override
  bool tryEnableSemantics(DomEvent event) {
    // Semantics may be enabled programmatically. If there's a race between that
    // and the DOM event, we may end up here while there's no longer a placeholder
    // to work with.
    if (!isWaitingToEnableSemantics) {
      return true;
    }

    if (_schedulePlaceholderRemoval) {
      // The event type can also be click for VoiceOver.
      final bool removeNow =
          ui_web.browser.browserEngine != ui_web.BrowserEngine.webkit ||
          event.type == 'touchend' ||
          event.type == 'pointerup' ||
          event.type == 'click';
      if (removeNow) {
        dispose();
      }
      return true;
    }

    if (EngineSemantics.instance.semanticsEnabled) {
      // Semantics already enabled, forward to framework as normal.
      return true;
    }

    semanticsActivationAttempts += 1;
    if (semanticsActivationAttempts >= kMaxSemanticsActivationAttempts) {
      // We have received multiple user events, none of which resulted in
      // semantics activation. This is a signal that the user is not interested
      // in semantics, and so we will stop waiting for it.
      _schedulePlaceholderRemoval = true;
      return true;
    }

    // ios-safari browsers which starts sending `pointer` events instead of
    // `touch` events. (Tested with 12.1 which uses touch events vs 13.5
    // which uses pointer events.)
    const kInterestingEventTypes = <String>{
      'click',
      'touchstart',
      'touchend',
      'pointerdown',
      'pointermove',
      'pointerup',
    };

    if (!kInterestingEventTypes.contains(event.type)) {
      // The event is not relevant, forward to framework as normal.
      return true;
    }

    if (semanticsActivationTimer != null) {
      // We are in a waiting period to activate a timer. While the timer is
      // active we should consume events pertaining to semantics activation.
      // Otherwise the event will also be interpreted by the framework and
      // potentially result in activating a gesture in the app.
      return false;
    }

    // Look at where exactly (within 1 pixel) the event landed. If it landed
    // exactly in the middle of a placeholder we interpret it as a signal
    // to enable accessibility. This is because when VoiceOver and TalkBack
    // generate a tap it lands it in the middle of the focused element. This
    // method is a bit flawed in that a user's finger could theoretically land
    // in the middle of the element too. However, the chance of that happening
    // is very small. Even low-end phones typically have >2 million pixels
    // (e.g. Moto G4). It is very unlikely that a user will land their finger
    // exactly in the middle. In the worst case an unlucky user would
    // accidentally enable accessibility and the app will be slightly slower
    // than normal, but the app will continue functioning as normal. Our
    // semantics tree is designed to not interfere with Flutter's gesture
    // detection.
    late final DomPoint activationPoint;

    switch (event.type) {
      case 'click':
        final click = event as DomMouseEvent;
        // Client coordinates, not offset coordinates. The rects below are
        // relative to the viewport, and a placeholder no longer starts at the
        // top-left corner of the page, so the two would not line up.
        activationPoint = click.client;
      case 'touchstart':
      case 'touchend':
        final touchEvent = event as DomTouchEvent;
        activationPoint = touchEvent.changedTouches.first.client;
      case 'pointerdown':
      case 'pointerup':
        final touch = event as DomPointerEvent;
        activationPoint = touch.client;
      default:
        // The event is not relevant, forward to framework as normal.
        return true;
    }

    final bool enableConditionPassed = placeholders.any((DomElement placeholder) {
      final DomRect activatingElementRect = placeholder.getBoundingClientRect();
      final double midX =
          activatingElementRect.left +
          (activatingElementRect.right - activatingElementRect.left) / 2;
      final double midY =
          activatingElementRect.top +
          (activatingElementRect.bottom - activatingElementRect.top) / 2;
      final double deltaX = activationPoint.x.toDouble() - midX;
      final double deltaY = activationPoint.y.toDouble() - midY;
      final double deltaSquared = deltaX * deltaX + deltaY * deltaY;
      return deltaSquared < 1.0;
    });

    if (enableConditionPassed) {
      assert(semanticsActivationTimer == null);
      _schedulePlaceholderRemoval = true;
      semanticsActivationTimer = Timer(_periodToConsumeEvents, () {
        dispose();
        EngineSemantics.instance.semanticsEnabled = true;
      });
      return false;
    }

    // This was not a semantics activating event; forward as normal.
    return true;
  }

  @override
  DomElement _prepareAccessibilityPlaceholder() {
    final DomElement placeholder = createDomElement('flt-semantics-placeholder');

    // Only listen to "click" because other kinds of events are reported via
    // PointerBinding.
    placeholder.addEventListener(
      'click',
      createDomEventListener((DomEvent event) {
        tryEnableSemantics(event);
      }),
      true.toJS,
    );

    placeholder
      ..setAttribute('role', 'button')
      ..setAttribute('aria-label', ui_web.accessibilityPlaceholderMessage);
    // The placeholder covers its view so that the user can find it by touch
    // exploration anywhere in the app. It must not reach beyond the view, or it
    // would swallow taps aimed at the HTML content around it.
    placeholder.style
      ..position = 'absolute'
      ..left = '0'
      ..top = '0'
      ..right = '0'
      ..bottom = '0';

    return placeholder;
  }

  @override
  void dispose() {
    super.dispose();
    _placeholderByViewRoot.clear();
    semanticsActivationTimer?.cancel();
    semanticsActivationTimer = null;
  }
}
