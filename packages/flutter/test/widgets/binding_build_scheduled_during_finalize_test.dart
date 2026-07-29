// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a build scheduled while BuildOwner.finalizeTree() is unmounting elements '
      'still results in a frame being produced '
      '(regression test for https://github.com/flutter/flutter/issues/189976)', (
    WidgetTester tester,
  ) async {
    late _ProbeElement probe;
    final BuildOwner buildOwner = tester.binding.buildOwner!;

    Widget boot({required bool includeDisposer}) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: <Widget>[
            _ProbeWidget(onElementCreated: (_ProbeElement element) => probe = element),
            if (includeDisposer) _Disposer(probe: () => probe, buildOwner: buildOwner),
          ],
        ),
      );
    }

    await tester.pumpWidget(boot(includeDisposer: true));
    expect(tester.binding.hasScheduledFrame, isFalse);
    final int buildCountBeforeRemoval = probe.buildCount;

    // Removing _Disposer makes its State.dispose() run from inside *this
    // same* frame's BuildOwner.finalizeTree() call - like the real-world
    // State.dispose() -> ChangeNotifier.notifyListeners() -> another
    // widget's setState() repro in #189976 - while
    // SchedulerBinding.instance.schedulerPhase is still
    // SchedulerPhase.persistentCallbacks (see WidgetsBinding.drawFrame()).
    await tester.pumpWidget(boot(includeDisposer: false));

    // Before the fix: WidgetsBinding._handleBuildScheduled() calls
    // ensureVisualUpdate(), which is a documented no-op during
    // SchedulerPhase.persistentCallbacks, and nothing else re-requests a
    // frame afterwards - hasScheduledFrame is stuck at false forever,
    // reproducing the permanent freeze from #189976.
    //
    // After the fix: WidgetsBinding._handleBuildScheduled() also calls
    // scheduleFrame() in that phase, so a genuine follow-up frame is
    // requested.
    final bool didScheduleFrame = tester.binding.hasScheduledFrame;

    // If a frame really was scheduled, drive it now (while the probe is
    // still in the tree) so the best-effort rebuild evidence below is
    // genuine rather than superficial. AutomatedTestWidgetsFlutterBinding
    // .pump() only runs a frame when hasScheduledFrame is true, so this is
    // a harmless no-op pre-fix.
    await tester.pump();
    final int buildCountAfterRecovery = probe.buildCount;

    // Clean up regardless of the outcome above, so a failed assertion below
    // doesn't leak a dirty element into later tests.
    await tester.pumpWidget(const SizedBox());

    expect(didScheduleFrame, isTrue);

    // Best-effort (not required for the regression signal above): confirm
    // the probe was genuinely rebuilt - not just that *a* frame was
    // scheduled - proving BuildOwner's internal flag was reset through the
    // normal code path rather than the recovery being superficial.
    expect(buildCountAfterRecovery, greaterThan(buildCountBeforeRemoval));
  });
}

/// Notifies [_ProbeElement] when it is created, so the test can retain a
/// reference to an element that lives inside the real widget tree (sharing
/// [BuildOwner] and [BuildScope] with [WidgetsBinding.instance.rootElement]) -
/// as opposed to a detached [RootElementMixin] element, which would not be
/// visited by the real `buildScope(rootElement)` call that the fix relies on.
class _ProbeWidget extends Widget {
  const _ProbeWidget({required this.onElementCreated});

  final ValueSetter<_ProbeElement> onElementCreated;

  @override
  Element createElement() => _ProbeElement(this);
}

class _ProbeElement extends ComponentElement {
  _ProbeElement(_ProbeWidget widget) : super(widget) {
    widget.onElementCreated(this);
  }

  int buildCount = 0;

  // Defaults to true so ComponentElement._firstBuild()'s initial
  // rebuild() call (which does not pass force: true) still proceeds.
  bool _forceDirty = true;

  void markProbeDirty() => _forceDirty = true;

  @override
  bool get dirty => _forceDirty || super.dirty;

  // Element.rebuild() gates on the private _dirty field, which only
  // Element.markNeedsBuild() can set - and that path is blocked here by the
  // same debug-only "widget tree was locked" assertion that this whole
  // regression only manifests in release builds without (see the linked
  // issue). Overriding rebuild() lets the test drive a real, virtual-dispatch
  // rebuild (BuildScope._tryRebuild calls element.rebuild()) off of our own
  // dirty tracking instead.
  @override
  void rebuild({bool force = false}) {
    if (!_forceDirty && !force) {
      return;
    }
    _forceDirty = false;
    super.rebuild(force: true);
  }

  @override
  Widget build() {
    buildCount++;
    return const SizedBox.shrink();
  }
}

class _Disposer extends StatefulWidget {
  const _Disposer({required this.probe, required this.buildOwner});

  final _ProbeElement Function() probe;
  final BuildOwner buildOwner;

  @override
  State<_Disposer> createState() => _DisposerState();
}

class _DisposerState extends State<_Disposer> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();

  @override
  void dispose() {
    // Confirms this dispose() is really running from inside
    // BuildOwner.finalizeTree() (see WidgetsBinding.drawFrame()), matching
    // the real-world trigger for #189976 rather than some other phase.
    expect(SchedulerBinding.instance.schedulerPhase, SchedulerPhase.persistentCallbacks);

    final _ProbeElement probe = widget.probe();
    probe.markProbeDirty();

    // WidgetsBinding._handleBuildScheduled() throws a FlutterError in debug
    // builds if debugBuildingDirtyElements is true, which it always is for
    // the whole duration of WidgetsBinding.drawFrame() (including
    // finalizeTree()). That assertion is compiled out in release builds -
    // exactly the configuration this bug only manifests in. Temporarily
    // clear the (test-mutable, see its doc comment) flag to simulate that,
    // mirroring the existing "scheduleBuild while debugBuildingDirtyElements
    // is true" test in framework_test.dart.
    // ignore: invalid_use_of_protected_member
    final bool wasBuildingDirtyElements = WidgetsBinding.instance.debugBuildingDirtyElements;
    // ignore: invalid_use_of_protected_member
    WidgetsBinding.instance.debugBuildingDirtyElements = false;
    try {
      // Call BuildOwner.scheduleBuildFor() directly, rather than through
      // setState()/Element.markNeedsBuild(), to bypass that method's
      // separate (and, for this exact call site, unavoidable-in-debug)
      // assertion that the widget tree isn't locked - which would otherwise
      // report a "setState() or markNeedsBuild() called when widget tree was
      // locked" FlutterError before ever reaching the code under test. In
      // the real repro from #189976 that call comes from a ChangeNotifier
      // listener; here it is simulated directly to isolate the actual bug,
      // which lives entirely in BuildOwner.scheduleBuildFor /
      // WidgetsBinding._handleBuildScheduled / SchedulerBinding.ensureVisualUpdate.
      widget.buildOwner.scheduleBuildFor(probe);
    } finally {
      // ignore: invalid_use_of_protected_member
      WidgetsBinding.instance.debugBuildingDirtyElements = wasBuildingDirtyElements;
    }

    super.dispose();
  }
}
