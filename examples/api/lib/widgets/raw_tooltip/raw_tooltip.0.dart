import 'package:flutter/material.dart';

/// Flutter code sample for [RawTooltip].

void main() => runApp(const RawTooltipExampleApp());

class RawTooltipExampleApp extends StatelessWidget {
  const RawTooltipExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const RawTooltipSample(title: 'RawTooltip Sample'),
    );
  }
}

class RawTooltipSample extends StatelessWidget {
  const RawTooltipSample({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final GlobalKey<RawTooltipState> rawTooltipKey =
        GlobalKey<RawTooltipState>();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: RawTooltip(
          // Provide a global key with the "RawTooltipState" type to show
          // the rawTooltip manually when trigger mode is set to manual.
          key: rawTooltipKey,
          semanticsTooltip: 'I am a RawToolTip message',
          triggerMode: TooltipTriggerMode.manual,
          tooltipBuilder: (BuildContext context, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: Text('I am a RawToolTip message'),
            );
          },
          child: Container(color: Colors.blue, height: 100, width: 200),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Show RawTooltip programmatically on button tap.
          rawTooltipKey.currentState?.ensureTooltipVisible();
        },
        label: const Text('Show RawTooltip'),
      ),
    );
  }
}
