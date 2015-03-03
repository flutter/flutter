library item;

import 'dart:sky' as sky;
import 'fn.dart';
import 'widgets.dart';

enum Color { RED, GREEN }

class Item extends Component {

  String label;

  Color _color = Color.GREEN;

  Item({ Object key, this.label }) : super(key: key);

  Node render() {
    return new Container(
      children: [
        new Radio(
          onChanged: changed,
          value: Color.GREEN,
          groupValue: _color
        ),
        new Radio(
          onChanged: changed,
          value: Color.RED,
          groupValue: _color
        ),

        new Text("$label: ${Color.values[_color.index]}")
      ]
    );
  }

  void changed(Object value) {
    setState(() {
      _color = value;
    });
  }
}
