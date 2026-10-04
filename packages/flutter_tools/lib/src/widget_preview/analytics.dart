// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:unified_analytics/unified_analytics.dart';

/// Manages analytics reporting for widget preview events sent from the Flutter Tool.
///
/// The generated widget preview scaffold project will also report analytics via DTD.
class WidgetPreviewAnalytics {
  WidgetPreviewAnalytics({required this.analytics});

  final Analytics analytics;

  final _launchTimer = Stopwatch();
  final _reloadTimer = Stopwatch();

  var _launchIncludedProjectGeneration = false;

  /// The analytics workflow for tracking widget previewer timings.
  static const kWorkflow = 'widget-preview';

  /// The analytics event tracking widget previewer launch times.
  static const kLaunchTime = 'launch-time';

  /// The analytics event tracking widget preview reload times.
  static const kPreviewReloadTime = 'preview-reload-time';

  /// The analytics event tracking actual launches of the widget preview environment.
  static const kPreviewerConnected = 'previewer-connected';

  /// Provided as the label to [kLaunchTime] events if the widget preview scaffold project was
  /// generated as part of the widget previewer starting up.
  static const kScaffoldGeneratedLabel = 'scaffold-generated';

  /// Starts the stopwatch tracking the widget previewer launch time.
  void initializeLaunchStopwatch() {
    assert(!_launchTimer.isRunning);
    _launchTimer.start();
  }

  /// Report that the current invocation of the `widget-preview start` command resulted in the
  /// widget preview scaffold project being regenerated.
  void generatedProject() => _launchIncludedProjectGeneration = true;

  /// Send an analytics event reporting how long it took for the widget previewer to start.
  void reportLaunchTiming() {
    assert(_launchTimer.isRunning);
    _launchTimer.stop();
    analytics.send(
      Event.timing(
        workflow: kWorkflow,
        variableName: kLaunchTime,
        elapsedMilliseconds: _launchTimer.elapsedMilliseconds,
        label: _launchIncludedProjectGeneration ? kScaffoldGeneratedLabel : null,
      ),
    );
  }

  /// Send an analytics event reporting that the widget preview environment has loaded successfully.
  void reportPreviewerConnected() {
    analytics.send(
      // TODO(bkonyi): we should add a dedicated event type in unified_analytics, but this
      // works as a temporary solution.
      Event.timing(workflow: kWorkflow, variableName: kPreviewerConnected, elapsedMilliseconds: 0),
    );
  }

  /// Starts the stopwatch tracking the reload times for updated previews.
  ///
  /// This should be invoked when a file system event is detected in the preview detector.
  void startPreviewReloadStopwatch() {
    assert(!_reloadTimer.isRunning);
    _reloadTimer.start();
  }

  /// Send an analytics event reporting how long it took for a widget preview to be reloaded.
  void reportPreviewReloadTiming() {
    // TODO(bkonyi): only report when files are actually reloaded?
    assert(_reloadTimer.isRunning);
    _reloadTimer.stop();
    analytics.send(
      Event.timing(
        workflow: kWorkflow,
        variableName: kPreviewReloadTime,
        elapsedMilliseconds: _reloadTimer.elapsedMilliseconds,
      ),
    );
    _reloadTimer.reset();
  }

  /// Stops the stopwatch tracking reload times for updated previews and resets the clock.
  ///
  /// This should be invoked after a preview reload attempt has been completed, even if a reload
  /// wasn't triggered due to no previews being changed.
  void resetPreviewReloadStopwatch() {
    _reloadTimer
      ..stop()
      ..reset();
  }
}
