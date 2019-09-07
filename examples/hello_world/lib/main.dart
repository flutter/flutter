import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

void main() => runApp(_Home());

class _Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: MaterialStateBuilder(
            builder: (Set<MaterialState> states) {
              final bool pressed = states.contains(MaterialState.pressed);
              final bool hovered = states.contains(MaterialState.hovered);

              return RaisedButton(
                onPressed: () {},
                elevation: pressed ? 10 : 2,
                color: Colors.blue,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: pressed ? Colors.yellow : Colors.white,
                    width: hovered ? 2 : 1,
                  ),
                ),
                child: Text(
                  'Button',
                  style: TextStyle(
                    color: pressed ? Colors.yellow : Colors.white,
                    decoration: hovered ? TextDecoration.underline : null,
                    fontSize: 20.0,
                  ),
                ),
              );
            },
            disabled: false,
          ),
        ),
      ),
    );
  }
}
