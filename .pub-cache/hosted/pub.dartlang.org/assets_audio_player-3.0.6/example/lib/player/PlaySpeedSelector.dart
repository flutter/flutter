import 'package:flutter_neumorphic/flutter_neumorphic.dart';

class PlaySpeedSelector extends StatelessWidget {
  final double playSpeed;
  final Function(double) onChange;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Text(
            'PlaySpeed ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          _button(0.5),
          _button(1.0),
          _button(2.0),
          _button(4.0),
        ],
      ),
    );
  }

  Widget _button(double value) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: NeumorphicRadio(
        groupValue: playSpeed,
        padding: EdgeInsets.all(12.0),
        value: value,
        style: NeumorphicRadioStyle(
          boxShape: NeumorphicBoxShape.circle(),
        ),
        onChanged: (double? v) {
          if (v != null) onChange(v);
        },
        child: Text('x$value'),
      ),
    );
  }

  const PlaySpeedSelector({
    required this.playSpeed,
    required this.onChange,
  });
}
