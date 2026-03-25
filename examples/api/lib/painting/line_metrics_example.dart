import 'package:flutter/material.dart';
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

class LineMetricsDemo extends StatelessWidget {
  const LineMetricsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return LineMetricsBuilder(
      text: "This is a multi-line example demonstrating how computeLineMetrics can be used in Flutter for custom line decorations.",
      style: const TextStyle(fontSize: 18, color: Colors.black),
      maxWidth: 300,
      builder: (context, lines, painter) {
        return CustomPaint(
          size: const Size(300, 200),
          painter: LinePainter(lines, painter),
        );
      },
    );
  }
}

typedef LineMetricsWidgetBuilder = Widget Function(
  BuildContext context,
  List<ui.LineMetrics> lines,
  TextPainter painter,
);

class LineMetricsBuilder extends StatefulWidget {
  final String text;
  final TextStyle style;
  final double maxWidth;
  final LineMetricsWidgetBuilder builder;

  const LineMetricsBuilder({
    super.key,
    required this.text,
    required this.style,
    required this.maxWidth,
    required this.builder,
  });

  @override
  State<LineMetricsBuilder> createState() => _LineMetricsBuilderState();
}

class _LineMetricsBuilderState extends State<LineMetricsBuilder> {
  final TextPainter _painter = TextPainter(
    textDirection: TextDirection.ltr,
  );

  List<ui.LineMetrics> _lines = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _compute();
  }

  @override
  void didUpdateWidget(covariant LineMetricsBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.text != widget.text ||
        oldWidget.style != widget.style ||
        oldWidget.maxWidth != widget.maxWidth) {
      _compute();
    }
  }

  void _compute() {
    _painter.text = TextSpan(
      text: widget.text,
      style: widget.style,
    );

    _painter.layout(maxWidth: widget.maxWidth);
    _lines = _painter.computeLineMetrics();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _lines, _painter);
  }
}

class LinePainter extends CustomPainter {
  final List<ui.LineMetrics> lines;
  final TextPainter painter;

  LinePainter(this.lines, this.painter);

  @override
  void paint(Canvas canvas, Size size) {
    painter.paint(canvas, Offset.zero);

    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2;

    for (final line in lines) {
      final y = line.baseline + 2;

      canvas.drawLine(
        Offset(0, y),
        Offset(line.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}