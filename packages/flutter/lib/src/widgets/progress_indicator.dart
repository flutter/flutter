// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/cupertino.dart';
/// @docImport 'package:flutter/material.dart';
/// @docImport 'package:flutter/semantics.dart';
library;

import '../foundation/diagnostics.dart';
import 'basic.dart';
import 'framework.dart';
import 'ticker_provider.dart';

/// A base class for progress indicators.
///
/// See also:
///
///  * [MaterialProgressIndicator], which is a base class for Material Design progress indicators.
///  * [CupertinoProgressIndicator] which is a base class for Cupertino progress indicators.
abstract class ProgressIndicator extends StatefulWidget {
  /// Creates a progress indicator.
  ///
  /// {@template flutter.widget.ProgressIndicator.ProgressIndicator}
  /// The [value] argument can either be null for an indeterminate
  /// progress indicator, or a non-null value between 0.0 and 1.0 for a
  /// determinate progress indicator.
  ///
  /// ## Accessibility
  ///
  /// The [semanticsLabel] can be used to identify the purpose of this progress
  /// bar for screen reading software. The [semanticsValue] property may be used
  /// for determinate progress indicators to indicate how much progress has been made.
  /// {@endtemplate}
  const ProgressIndicator({super.key, this.value, this.semanticsLabel, this.semanticsValue});

  // cupertino.
  /// If non-null, the value of this progress indicator.
  ///
  /// A value of 0.0 means no progress and 1.0 means that progress is complete.
  /// The value will be clamped to be in the range 0.0-1.0.
  ///
  /// If null, this progress indicator is indeterminate, which means the
  /// indicator displays a predetermined animation that does not indicate how
  /// much actual progress is being made.
  final double? value;

  /// {@template flutter.progress_indicator.ProgressIndicator.semanticsLabel}
  /// The [SemanticsProperties.label] for this progress indicator.
  ///
  /// This value indicates the purpose of the progress bar, and will be
  /// read out by screen readers to indicate the purpose of this progress
  /// indicator.
  /// {@endtemplate}
  final String? semanticsLabel;

  /// {@template flutter.progress_indicator.ProgressIndicator.semanticsValue}
  /// The [SemanticsProperties.value] for this progress indicator.
  ///
  /// This will be used in conjunction with the [semanticsLabel] by
  /// screen reading software to identify the widget, and is primarily
  /// intended for use with determinate progress indicators to announce
  /// how far along they are.
  ///
  /// For determinate progress indicators, this will be defaulted to
  /// [ProgressIndicator.value] expressed as a percentage, i.e. `0.1` will
  /// become '10%'.
  /// {@endtemplate}
  final String? semanticsValue;

  /// Returns the color used to paint the progress indicator's value/active
  /// portion.
  @protected
  Color getValueColor(BuildContext context, {Color? defaultColor});

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(PercentProperty('value', value, showName: false, ifNull: '<indeterminate>'));
  }
}

/// A mixin that provides common functionality for progress indicator widgets.
///
/// This mixin encapsulates the animation [controller] management and semantics
/// handling that is shared across different types of progress indicators. It
/// must be used on [State] classes that also mix in
/// [SingleTickerProviderStateMixin].
///
/// See also:
///  * [ProgressIndicator] which is a base class for progress indicators.
///  * [CircularProgressIndicator] which shows progress along a circular arc.
///  * [LinearProgressIndicator] which shows progress along a line.
///  * [CupertinoActivityIndicator] which is an iOS-style activity indicator
///    that spins clockwise.
///  * [CupertinoLinearActivityIndicator] which is an iOS-style linear activity
///    indicator.
mixin ProgressIndicatorMixin<T extends ProgressIndicator>
    on State<T>, SingleTickerProviderStateMixin<T> {
  late AnimationController _controller;

  /// The controller for the progress indicator's animation.
  @protected
  AnimationController get controller => _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: duration, vsync: this);
    if (animating) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == null && !_controller.isAnimating) {
      _controller.repeat();
    } else if (widget.value != null && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Whether the progress indicator is animating.
  @protected
  bool get animating;

  /// The duration of the progress indicator's animation.
  @protected
  Duration get duration;

  /// Builds a semantics wrapper for the progress indicator.
  @protected
  Widget buildSemanticsWrapper({required BuildContext context, required Widget child}) {
    String? expandedSemanticsValue = widget.semanticsValue;
    if (widget.value != null) {
      expandedSemanticsValue ??= '${(widget.value! * 100).round()}%';
    }
    return Semantics(label: widget.semanticsLabel, value: expandedSemanticsValue, child: child);
  }
}
