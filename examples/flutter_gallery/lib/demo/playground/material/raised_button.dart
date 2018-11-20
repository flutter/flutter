import 'package:flutter/material.dart';

class MaterialRaisedButtonDemo extends StatefulWidget {
  const MaterialRaisedButtonDemo({Key key}) : super(key: key);

  @override
  _MaterialRaisedButtonDemoState createState() =>
      _MaterialRaisedButtonDemoState();
}

class _MaterialRaisedButtonDemoState extends State<MaterialRaisedButtonDemo> {
  double elevation = 8.0;
  String borderShape = 'rounded';
  Color color = Colors.blue;
  Color splashColor = Colors.lightBlue;

  static const double labelFontSize = 16.0;
  static const double controlHeight = 40.0;
  static const double selectedElevation = 3.0;
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
        style: TextStyle(color: Colors.grey[800], fontFamily: 'Monospace'),
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
          children: children),
    );
  }

  Widget _propertyColumn(String label, Widget widget) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 15.0)
                .copyWith(top: 15.0)
                .copyWith(bottom: 20.0),
            child: Text(
              label,
              style: const TextStyle(
                color: labelColor,
                fontSize: labelFontSize,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: widget,
          ),
        ]);
  }

  ShapeBorder _borderShape(String type, [bool side = true]) {
    ShapeBorder shape;

    BorderSide borderSide = const BorderSide(
      color: Colors.grey,
      width: 2.0,
    );

    borderSide = side ? borderSide : BorderSide.none;

    switch (type) {
      case 'box':
        shape = RoundedRectangleBorder(
            borderRadius: BorderRadius.zero, side: borderSide);
        break;
      case 'rounded':
        shape = RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0), side: borderSide);
        break;
      case 'beveled':
        shape = BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
            side: borderSide.copyWith(width: 1.0));
        break;
      case 'circle':
        shape = CircleBorder(side: borderSide);
        break;
    }
    return shape;
  }

  Widget _shapeButton(String shape) {
    return ButtonTheme(
      minWidth: controlHeight,
      height: controlHeight,
      child: RaisedButton(
        shape: _borderShape(shape),
        color: borderShape == shape ? Colors.blue : Colors.white,
        elevation: borderShape == shape ? selectedElevation : 0.0,
        child: const Text(''),
        onPressed: () {
          setState(() {
            borderShape = shape;
          });
        },
      ),
    );
  }

  Widget _colorButton(Color value) {
    return ButtonTheme(
      minWidth: controlHeight,
      height: controlHeight,
      child: RaisedButton(
        shape: StadiumBorder(
          side: BorderSide(
            color: color == value ? Colors.white : Colors.grey[350],
            width: 2.0,
          ),
        ),
        color: value,
        elevation: color == value ? selectedElevation : 0.0,
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
          divisions: 6,
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
      Container(
        padding: const EdgeInsets.only(left: controlHeight)
            .copyWith(right: controlHeight),
        height: controlHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            _shapeButton('box'),
            _shapeButton('beveled'),
            _shapeButton('rounded'),
            _shapeButton('circle'),
          ],
        ),
      ),
    );
  }

  Widget _colorControl() {
    return _propertyColumn(
      'Color',
      Container(
        padding: const EdgeInsets.only(left: 20.0).copyWith(right: 20.0),
        height: controlHeight,
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _colorButton(Colors.white),
              _colorButton(Colors.orange),
              _colorButton(Colors.cyan[200]),
              _colorButton(Colors.lightBlue[300]),
              _colorButton(Colors.blue),
              _colorButton(Colors.blue[800]),
            ]),
      ),
    );
  }

  Widget _primaryWidget() {
    return Padding(
      padding: const EdgeInsets.only(top: controlHeight)
          .copyWith(bottom: controlHeight),
      child: Center(
        child: ButtonTheme(
          minWidth: 160.0,
          height: 50.0,
          child: RaisedButton(
            padding: const EdgeInsets.all(5.0),
            color: color,
            child: Text(
              'BUTTON',
              style: TextStyle(
                fontSize: 16.0,
                color: color == Colors.white ? Colors.grey[900] : Colors.white,
              ),
            ),
            shape: borderShape == 'circle'
                ? RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0))
                : _borderShape(borderShape, false),
            elevation: elevation,
            splashColor: splashColor,
            onPressed: () {},
          ),
        ),
      ),
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
