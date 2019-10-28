// Copyright 2019-present the Flutter authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:math';

import 'package:flutter/material.dart';

import 'package:flutter_gallery/demo/rally/colors.dart';
import 'package:flutter_gallery/demo/rally/data.dart';
import 'package:flutter_gallery/demo/rally/formatters.dart';

/// A colored piece of the [RallyPieChart].
class RallyPieChartSegment {
  const RallyPieChartSegment({ this.color, this.value });

  final Color color;
  final double value;
}

List<RallyPieChartSegment> buildSegmentsFromAccountItems(
    List<AccountData> items) {
  return List<RallyPieChartSegment>.generate(
    items.length,
    (int i) {
      return RallyPieChartSegment(
        color: RallyColors.accountColor(i),
        value: items[i].primaryAmount,
      );
    },
  );
}

List<RallyPieChartSegment> buildSegmentsFromBillItems(List<BillData> items) {
  return List<RallyPieChartSegment>.generate(
    items.length,
    (int i) {
      return RallyPieChartSegment(
        color: RallyColors.billColor(i),
        value: items[i].primaryAmount,
      );
    },
  );
}

List<RallyPieChartSegment> buildSegmentsFromBudgetItems(
    List<BudgetData> items) {
  return List<RallyPieChartSegment>.generate(
    items.length,
    (int i) {
      return RallyPieChartSegment(
        color: RallyColors.budgetColor(i),
        value: items[i].primaryAmount - items[i].amountUsed,
      );
    },
  );
}

/// An animated circular pie chart to represent pieces of a whole, which can
/// have empty space.
class RallyPieChart extends StatefulWidget {
  const RallyPieChart({ this.heroLabel, this.heroAmount, this.wholeAmount, this.segments });

  final String heroLabel;
  final double heroAmount;
  final double wholeAmount;
  final List<RallyPieChartSegment> segments;

  @override
  _RallyPieChartState createState() => _RallyPieChartState();
}

class _RallyPieChartState extends State<RallyPieChart>
    with SingleTickerProviderStateMixin {
  AnimationController controller;
  Animation<double> animation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    animation = CurvedAnimation(
      parent: TweenSequence<double>(<TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0, end: 0),
          weight: 1,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0, end: 1),
          weight: 1.5,
        ),
      ]).animate(controller),
      curve: Curves.decelerate);
    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AnimatedRallyPieChart(
      animation: animation,
      centerLabel: widget.heroLabel,
      centerAmount: widget.heroAmount,
      total: widget.wholeAmount,
      segments: widget.segments,
    );
  }
}

class _AnimatedRallyPieChart extends AnimatedWidget {
  const _AnimatedRallyPieChart({
    Key key,
    this.animation,
    this.centerLabel,
    this.centerAmount,
    this.total,
    this.segments,
  }) : super(key: key, listenable: animation);

  final Animation<double> animation;
  final String centerLabel;
  final double centerAmount;
  final double total;
  final List<RallyPieChartSegment> segments;

  @override
  Widget build(BuildContext context) {
    final TextStyle labelTextStyle = Theme.of(context).textTheme.body1.copyWith(
        fontSize: 14,
        letterSpacing: 0.5,
    );

    return DecoratedBox(
      decoration: _RallyPieChartOutlineDecoration(
        maxFraction: animation.value,
        total: total,
        segments: segments,
      ),
      child: SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                centerLabel,
                style: labelTextStyle,
              ),
              Text(
                usdWithSignFormat.format(centerAmount),
                style: Theme.of(context).textTheme.headline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RallyPieChartOutlineDecoration extends Decoration {
  const _RallyPieChartOutlineDecoration({this.maxFraction, this.total, this.segments});

  final double maxFraction;
  final double total;
  final List<RallyPieChartSegment> segments;

  @override
  BoxPainter createBoxPainter([VoidCallback onChanged]) {
    return _RallyPieChartOutlineBoxPainter(
      maxFraction: maxFraction,
      wholeAmount: total,
      segments: segments,
    );
  }
}

class _RallyPieChartOutlineBoxPainter extends BoxPainter {
  _RallyPieChartOutlineBoxPainter({this.maxFraction, this.wholeAmount, this.segments});

  final double maxFraction;
  final double wholeAmount;
  final List<RallyPieChartSegment> segments;
  static const double wholeRadians = 2 * pi;
  static const double spaceRadians = wholeRadians / 180;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    // Create two padded reacts to draw arcs in: one for colored arcs and one for
    // inner bg arc.
    const double strokeWidth = 4;
    final double outerRadius = min(
      configuration.size.width,
      configuration.size.height,
    ) / 2;
    final Rect outerRect = Rect.fromCircle(
      center: configuration.size.center(Offset.zero),
      radius: outerRadius - strokeWidth * 3,
    );
    final Rect innerRect = Rect.fromCircle(
      center: configuration.size.center(Offset.zero),
      radius: outerRadius - strokeWidth * 4,
    );

    // Paint each arc with spacing.
    double cumulativeSpace = 0;
    double cumulativeTotal = 0;
    for (RallyPieChartSegment segment in segments) {
      final Paint paint = Paint()..color = segment.color;
      final double startAngle = _calculateStartAngle(cumulativeTotal, cumulativeSpace);
      final double sweepAngle = _calculateSweepAngle(segment.value, 0);
      canvas.drawArc(outerRect, startAngle, sweepAngle, true, paint);
      cumulativeTotal += segment.value;
      cumulativeSpace += spaceRadians;
    }

    // Paint any remaining space black (e.g. budget amount remaining).
    final double remaining = wholeAmount - cumulativeTotal;
    if (remaining > 0) {
      final Paint paint = Paint()..color = Colors.black;
      final double startAngle = _calculateStartAngle(cumulativeTotal, spaceRadians * segments.length);
      final double sweepAngle = _calculateSweepAngle(remaining, -spaceRadians);
      canvas.drawArc(outerRect, startAngle, sweepAngle, true, paint);
    }

    // Paint a smaller inner circle to cover the painted arcs, so they are
    // display as segments.
    final Paint bgPaint = Paint()..color = RallyColors.primaryBackground;
    canvas.drawArc(innerRect, 0, 2 * pi, true, bgPaint);
  }

  double _calculateAngle(double amount, double offset) {
    final double wholeMinusSpacesRadians = wholeRadians - (segments.length * spaceRadians);
    return maxFraction * (amount / wholeAmount * wholeMinusSpacesRadians + offset);
  }

  double _calculateStartAngle(double total, double offset) => _calculateAngle(total, offset) - pi / 2;

  double _calculateSweepAngle(double total, double offset) => _calculateAngle(total, offset);
}
