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
  /// placeholders are no longer needed.
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

  /// The placeholder each view is using, keyed by the view's root element.
  ///
  /// Views that share a host share one placeholder, so several entries can
  /// point at the same element. See [addPlaceholderForView].
  final Map<DomElement, DomElement> _placeholderByViewRoot = <DomElement, DomElement>{};

  /// The placeholders that are currently waiting for the user to enable
  /// accessibility.
  ///
  /// One per host, so one for the whole page on desktop and one per view on
  /// mobile.
  @visibleForTesting
  Iterable<DomElement> get placeholders => _placeholderByViewRoot.values.toSet();

  /// The element the placeholder for [viewRoot] is prepended to.
  ///
  /// This is the only thing the two form factors disagree on, and they
  /// disagree for a reason. See [DesktopSemanticsEnabler] and
  /// [MobileSemanticsEnabler].
  ///
  /// Returning null means no placeholder can be placed right now.
  DomElement? placeholderHostFor(DomElement viewRoot);

  /// Gives the Flutter view rooted at [viewRoot] a placeholder inside
  /// [placeholderHostFor].
  ///
  /// Views that resolve to the same host share one placeholder, because
  /// enabling semantics is a page-wide setting and a second button would only
  /// add another stop for the assistive technology user to step over. On
  /// desktop every view resolves to the body, so the page gets a single
  /// placeholder no matter how many views it holds.
  ///
  /// On focus the element announces that accessibility can be enabled by
  /// tapping/clicking. (Announcement depends on the assistive technology)
  void addPlaceholderForView(DomElement viewRoot) {
    if (_placeholderByViewRoot.containsKey(viewRoot)) {
      // Already registered, so the view either owns a placeholder or is
      // already sharing one.
      return;
    }
    final DomElement? host = placeholderHostFor(viewRoot);
    if (host == null) {
      return;
    }
    DomElement? placeholder = _placeholderIn(host);
    if (placeholder == null) {
      placeholder = _prepareAccessibilityPlaceholder();
      // First child, so that whatever else the host holds stays on top of it
      // and keeps receiving DOM events, platform views in particular. Pointer
      // events that do land on the placeholder still bubble up to the view
      // root, where [PointerBinding] listens for them.
      host.prepend(placeholder);
    }
    _placeholderByViewRoot[viewRoot] = placeholder;
  }

  /// The placeholder already attached to [host], if there is one.
  DomElement? _placeholderIn(DomElement host) {
    for (final DomElement placeholder in placeholders) {
      if (placeholder.parent == host) {
        return placeholder;
      }
    }
    return null;
  }

  /// Removes the placeholder [addPlaceholderForView] gave [viewRoot], unless
  /// another view is still sharing it.
  void removePlaceholderForView(DomElement viewRoot) {
    final DomElement? placeholder = _placeholderByViewRoot.remove(viewRoot);
    if (placeholder != null && !_placeholderByViewRoot.containsValue(placeholder)) {
      placeholder.remove();
    }
  }

  /// Removes every placeholder, so the engine stops waiting for the user to
  /// enable semantics.
  ///
  /// Separate from [dispose] so that the enabler can retire its placeholders
  /// without destroying itself.
  void removeAllPlaceholders() {
    for (final DomElement placeholder in placeholders) {
      placeholder.remove();
    }
    _placeholderByViewRoot.clear();
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
  bool get isWaitingToEnableSemantics => _placeholderByViewRoot.isNotEmpty;

  /// Releases everything this enabler owns.
  ///
  /// Only the owner of the enabler calls this.
  void dispose() {
    removeAllPlaceholders();
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
  /// Hosts the placeholder in the document body, never inside the view.
  ///
  /// Every view answers with the same host, so the page ends up with one
  /// shared placeholder rather than one per view. Semantics is enabled for the
  /// whole engine at once, so a second button would do nothing new and would
  /// only add another Tab stop ahead of the page content.
  ///
  /// It has to be the first thing the user tabs to, because once browser focus
  /// enters a view, Flutter's own focus traversal can consume Tab and never
  /// hand it back: a `Navigator` not built by `WidgetsApp` traverses with
  /// `TraversalEdgeBehavior.parentScope`, which closed-loops within the view,
  /// reports the key as handled, and the engine then calls `preventDefault`.
  /// Screen reader users in focus mode reach this button by Tab, so nesting it
  /// would put it out of reach.
  ///
  /// Being 1x1 and offscreen it never covers page content, which is why it can
  /// live in the body at all. Compare with [MobileSemanticsEnabler], which has
  /// the opposite constraint.
  ///
  /// See https://github.com/flutter/flutter/issues/152838
  @override
  DomElement? placeholderHostFor(DomElement viewRoot) => domDocument.body;

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
    removeAllPlaceholders();
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

  /// Hosts the placeholder inside the view it belongs to.
  ///
  /// This placeholder fills its host so that touch exploration can find it
  /// anywhere in the app, so hosting it in the document body would put it on
  /// top of the whole page and swallow every tap aimed at the HTML around an
  /// embedded view. Compare with [DesktopSemanticsEnabler], which has the
  /// opposite constraint.
  ///
  /// See https://github.com/flutter/flutter/issues/152838
  @override
  DomElement? placeholderHostFor(DomElement viewRoot) => viewRoot;

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
        removeAllPlaceholders();
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
        semanticsActivationTimer = null;
        removeAllPlaceholders();
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
    semanticsActivationTimer?.cancel();
    semanticsActivationTimer = null;
    super.dispose();
  }
}
