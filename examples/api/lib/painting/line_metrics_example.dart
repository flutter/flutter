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
          child: LineMetricsRenderDemo(),
        ),
      ),
    );
  }
}

class LineMetricsRenderDemo extends LeafRenderObjectWidget {
  const LineMetricsRenderDemo({super.key});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderLineMetricsDemo();
  }
}

class RenderLineMetricsDemo extends RenderBox {
  late RenderParagraph _paragraph;

  RenderLineMetricsDemo() {
  _paragraph = RenderParagraph(
    const TextSpan(
      text: 'This is a multi-line example demonstrating computeLineMetrics on RenderParagraph.',
      style: TextStyle(fontSize: 18, color: Colors.black),
    ),
    textDirection: TextDirection.ltr,
  );

  adoptChild(_paragraph); 
}

  @override
  void performLayout() {
    _paragraph.layout(constraints, parentUsesSize: true);
    size = _paragraph.size;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _paragraph.paint(context, offset);

    final List<ui.LineMetrics> lines = _paragraph.computeLineMetrics();

    final Canvas canvas = context.canvas;
    final Paint paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2;

    for (final line in lines) {
      final y = offset.dy + line.baseline + 2;

      canvas.drawLine(
        Offset(offset.dx, y),
        Offset(offset.dx + line.width, y),
        paint,
      );
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _paragraph.attach(owner);
  }

  @override
  void detach() {
    _paragraph.detach();
    super.detach();
  }

  @override
  void redepthChildren() {
    _paragraph.redepthChildren();
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    visitor(_paragraph);
  }
}