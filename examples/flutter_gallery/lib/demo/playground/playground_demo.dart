import 'package:flutter/material.dart';

abstract class PlaygroundDemo extends StatefulWidget {
  final _PlaygroundWidgetState _state = _PlaygroundWidgetState();

  @override
  _PlaygroundWidgetState createState() => _state;

  String tabName();
  Widget previewWidget(BuildContext context);
  Widget configWidget(BuildContext context);
  String code();

  void updateConfiguration(VoidCallback updates) => _state.updateState(updates);
}

class _PlaygroundWidgetState extends State<PlaygroundDemo> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          height: 200.0,
          child: widget.previewWidget(context),
        ),
        const Divider(
          height: 1.0,
        ),
        Expanded(
          child: SingleChildScrollView(
            child: widget.configWidget(context),
          ),
        ),
      ],
    );
  }

  void updateState(VoidCallback stateCallback) => setState(stateCallback);
}
