import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;

void main() {
  runApp(const LineMetricsExampleApp());
}

class LineMetricsExampleApp extends StatelessWidget {
  const LineMetricsExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: LineMetricsDemo(),
        ),
      ),
    );
  }
}

class RenderLineMetricsParagraph extends RenderParagraph {
  RenderLineMetricsParagraph(
    super.text, {
    required super.textDirection,
  });

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);

    final List<ui.LineMetrics> lines = computeLineMetrics();
    final Canvas canvas = context.canvas;
    final Paint paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2;

    for (final ui.LineMetrics line in lines) {
      final double y = offset.dy + line.baseline + 2;
      canvas.drawLine(
        Offset(offset.dx, y),
        Offset(offset.dx + line.width, y),
        paint,
      );
    }
  }
}

class LineMetricsDemo extends LeafRenderObjectWidget {
  const LineMetricsDemo({super.key});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderLineMetricsParagraph(
      const TextSpan(
        text: 'This is a multi-line example demonstrating computeLineMetrics on RenderParagraph.',
        style: TextStyle(fontSize: 18, color: Colors.black),
      ),
      textDirection: TextDirection.ltr,
    );
  }
}