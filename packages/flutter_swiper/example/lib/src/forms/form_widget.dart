import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class FormWidget extends StatelessWidget {
  final String label;

  final Widget child;

  FormWidget({this.label, this.child});

  @override
  Widget build(BuildContext context) {
    return new Padding(
        padding: new EdgeInsets.all(5.0),
        child: new Row(
          children: <Widget>[
            new Text(label, style: new TextStyle(fontSize: 14.0)),
            new Expanded(
                child:
                    new Align(alignment: Alignment.centerRight, child: child))
          ],
        ));
  }
}

class FormSelect<T> extends StatefulWidget {
  final String placeholder;
  final ValueChanged<T> valueChanged;
  final List<dynamic> values;
  final dynamic value;

  FormSelect({this.placeholder, this.valueChanged, this.value, this.values});

  @override
  State<StatefulWidget> createState() {
    return _FormSelectState();
  }
}

class _FormSelectState extends State<FormSelect> {
  int _selectedIndex = 0;

  @override
  void initState() {
    for (int i = 0, c = widget.values.length; i < c; ++i) {
      if (widget.values[i] == widget.value) {
        _selectedIndex = i;
        break;
      }
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String placeholder = widget.placeholder;
    List<dynamic> values = widget.values;

    return new Container(
      child: new InkWell(
        child: new Text(_selectedIndex < 0
            ? placeholder
            : values[_selectedIndex].toString()),
        onTap: () {
          _selectedIndex = 0;
          showBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return new SizedBox(
                  height: values.length * 30.0 + 200.0,
                  child: new Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      new SizedBox(
                        height: values.length * 30.0 + 70.0,
                        child: new CupertinoPicker(
                          itemExtent: 30.0,
                          children: values.map((dynamic value) {
                            return new Text(value.toString());
                          }).toList(),
                          onSelectedItemChanged: (int index) {
                            _selectedIndex = index;
                          },
                        ),
                      ),
                      new Center(
                        child: new RaisedButton(
                          onPressed: () {
                            if (_selectedIndex >= 0) {
                              widget
                                  .valueChanged(widget.values[_selectedIndex]);
                            }

                            setState(() {});

                            Navigator.of(context).pop();
                          },
                          child: new Text("ok"),
                        ),
                      )
                    ],
                  ),
                );
              });
        },
      ),
    );
  }
}

class NumberPad extends StatelessWidget {
  final num number;
  final num step;
  final num max;
  final num min;
  final ValueChanged<num> onChangeValue;

  NumberPad({this.number, this.step, this.onChangeValue, this.max, this.min});

  void onAdd() {
    onChangeValue(number + step > max ? max : number + step);
  }

  void onSub() {
    onChangeValue(number - step < min ? min : number - step);
  }

  @override
  Widget build(BuildContext context) {
    return new Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        new IconButton(icon: new Icon(Icons.exposure_neg_1), onPressed: onSub),
        new Text(
          number is int ? number.toString() : number.toStringAsFixed(1),
          style: new TextStyle(fontSize: 14.0),
        ),
        new IconButton(icon: new Icon(Icons.exposure_plus_1), onPressed: onAdd)
      ],
    );
  }
}
