import 'package:flutter/material.dart';

/// Flutter code sample for [Overlay].

void main() {
  // debugRepaintRainbowEnabled = true;
  // debugPrintMarkNeedsLayoutStacks = true;
  // debugPrintMarkNeedsPaintStacks = true;
  // debugPrintLayouts = true;
  runApp(const OverlayApp());
}

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
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Overlay(
        initialEntries: [
          OverlayEntry(
            builder: (BuildContext context) {
              return SelectionArea(
                child: Column(
                  children: [
                    // Must be at least two selectable texts
                    Text('rootA'),
                    Text('rootB'),
                  ],
                ),
              );
            },
            opaque: true,
            canSizeOverlay: true,
            maintainState: true,
          ),
          OverlayEntry(
            builder: (BuildContext context) {
              return Text('subA');
            },
            opaque: true,
            canSizeOverlay: true,
            maintainState: true,
          ),
        ],
      ),
    );
  }
}
