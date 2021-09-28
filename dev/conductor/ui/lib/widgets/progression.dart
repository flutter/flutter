import 'package:conductor_core/conductor_core.dart';
import 'package:conductor_core/proto.dart' as pb;
import 'package:flutter/material.dart';

class MainProgression extends StatefulWidget {
  const MainProgression({
    Key? key,
    required this.releaseState,
    required this.stateFilePath,
  }) : super(key: key);

  final pb.ConductorState? releaseState;
  final String stateFilePath;

  @override
  _MainProgressionState createState() => _MainProgressionState();
}

class _MainProgressionState extends State<MainProgression> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SelectableText(
          widget.releaseState != null
              ? presentState(widget.releaseState!)
              : 'No persistent state file found at ${widget.stateFilePath}',
        ),
      ],
    );
  }
}
