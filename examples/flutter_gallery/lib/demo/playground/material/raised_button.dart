import 'package:flutter/material.dart';

class MaterialRaisedButtonDemo extends StatefulWidget {
  const MaterialRaisedButtonDemo({Key key}) : super(key: key);

  @override
  _MaterialRaisedButtonDemoState createState() =>
      _MaterialRaisedButtonDemoState();
}

class _MaterialRaisedButtonDemoState extends State<MaterialRaisedButtonDemo> {
  double elevation = 8.0;
  double borderShape = 8.0;
  Color color = Colors.blue;
  Color splashColor = Colors.lightBlue;

  static const double labelFontSize = 16.0;
  static const double controlHeight = 65.0;
  static const Color labelColor = Colors.blue;
  

  String _code() {
    return """
FlatButton(
  child: Text('Button'),
  color: $color,
  elevation: $elevation,
  splashColor: $splashColor,
),
""";
  }

  // TODO breakout to code panel
  // see TabbedComponentDemoScaffold._showExampleCode
  Widget _codePreview() {
    return Padding(
      padding: const EdgeInsets.all(16.0).copyWith(top: 30.0),
      child: Text(
        _code(),
        style: TextStyle(
          color: Colors.grey[800],
          fontFamily: 'Monospace'
        ),
      ),
    );
  }

  Widget _primaryWidget() {
    return Padding(
      padding: const EdgeInsets.only(top: 19.0).copyWith(bottom: 20.0),
      child: Center(
        child: RaisedButton(
          child: const Text('Button'),
          elevation: elevation,
          splashColor: splashColor,
          color: color,
          onPressed: () {},
        ),
      ),
    );
  }

  Widget _buttonListContainer(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.only(bottom: 5.0),
      height: controlHeight,
      child: ListView(
        padding: const EdgeInsets.all(10.0),
        scrollDirection: Axis.horizontal,
        children: children
      ),
    );
  }

  Widget _rawButton() {
    return RawMaterialButton(
      onPressed: () {
      },
      constraints: const BoxConstraints.tightFor(
        width: 32.0,
        height: 32.0,
      ),
      fillColor: Colors.pink,
      shape: const CircleBorder(
        side: BorderSide(
          color: Colors.grey,
          width: 2.0,
        ),
      ),
      child: Semantics(
        value: '',
        selected: false,
      ),
    );
  }

  Widget _propertyColumn(String label, Widget widget) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 15.0).copyWith(top: 15.0).copyWith(bottom: 20.0),
          child: Text(
            label,
            style: const TextStyle(
              color: labelColor,
              fontSize: labelFontSize,
            ),
          ),
        ),
        widget,
      ]
    );
  }

  Widget _shapeButton(Color value) {
    return RaisedButton(
      shape: const CircleBorder(
        side: BorderSide(
          color: Colors.grey,
          width: 2.0,
        ),
      ),
      color: value,
      child: const Text(''),
      elevation: 0.0,
      onPressed: () {
        setState(() {
          color = value;
        });
      },
    );
  }

  Widget _colorButton(Color value) {
    return ButtonTheme(
      minWidth: controlHeight,
      height: controlHeight,
      child: RaisedButton(
        shape: CircleBorder(
          side: BorderSide(
            color: Colors.grey[350],
            width: 2.0,
          ),
        ),
        color: value,
        elevation: color == value ? 3.0 : 0.0,
        child: const Text(''),
        onPressed: () {
          setState(() {
            color = value;
          });
        },
      ),
    );
  }

  Widget _elevationControl() {
    return _propertyColumn(
      'Elevation',
      Padding(
        padding: const EdgeInsets.only(bottom: 5.0),
        child: Slider(
          value: elevation,
          min: 0.0,
          max: 24.0,
          divisions: 3,
          onChanged: (double value) {
            setState(() {
              elevation = value;
            });
          },
        ),
      ),
    );
  }

  Widget _shapeControl() {
    return _propertyColumn(
      'Shape',
      _buttonListContainer(<Widget>[
        _colorButton(Colors.white),
        _colorButton(Colors.orange),
        _colorButton(Colors.cyan[200]),
        _colorButton(Colors.lightBlue[300]),
      ])
    );
  }

  Widget _colorControl() {
    return _propertyColumn(
      'Color',
      _buttonListContainer(<Widget>[
        _colorButton(Colors.white),
        _colorButton(Colors.orange),
        _colorButton(Colors.cyan[200]),
        _colorButton(Colors.lightBlue[300]),
        _colorButton(Colors.blue),
        _colorButton(Colors.blue[800]),
      ])
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _primaryWidget(),
          const Divider(),
          _elevationControl(),
          _shapeControl(),
          _colorControl(),
          // _codePreview(),
        ],
      ),
    );
  }
}
