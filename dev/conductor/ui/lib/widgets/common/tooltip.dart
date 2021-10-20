import 'package:flutter/material.dart';

/// Displays detailed info message in a tooltip widget.
class InfoTooltip extends StatelessWidget {
  const InfoTooltip({
    Key? key,
    required this.tooltipName,
    required this.tooltipMessage,
  }) : super(key: key);

  final String tooltipName;
  final String tooltipMessage;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      padding: const EdgeInsets.all(10.0),
      message: tooltipMessage,
      child: Icon(
        Icons.info,
        size: 16.0,
        key: Key('${tooltipName}Tooltip'),
      ),
    );
  }
}
