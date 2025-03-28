import 'package:flutter/material.dart';

/// Flutter code sample for [Overlay].

void main() => runApp(const OverlayApp());

class OverlayApp extends StatelessWidget {
  const OverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: OverlayExample());
  }
}

class OverlayExample extends StatefulWidget {
  const OverlayExample({super.key});

  @override
  State<OverlayExample> createState() => _OverlayExampleState();
}

class _OverlayExampleState extends State<OverlayExample> {
  // Add the OverlayEntry to the Overlay.
  // Overlay.of(context, debugRequiredFor: widget).insert(overlayEntry!);

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Overlay(
      initialEntries: [
        OverlayEntry(
          builder:
              (BuildContext context) => Scaffold(
                appBar: AppBar(title: Text('Entry A')),
                body: Ink(child: Container(width: 333, height: 333, color: Colors.red)),
              ),
          opaque: true,
        ),
        OverlayEntry(
          builder:
              (BuildContext context) => Scaffold(
                appBar: AppBar(title: Text('Entry B')),
                body: Ink(child: Container(width: 222, height: 222, color: Colors.blue)),
              ),
          opaque: true,
        ),
      ],
    );
  }
}
